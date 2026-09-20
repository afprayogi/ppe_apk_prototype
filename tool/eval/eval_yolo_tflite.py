"""Smoke-test the author's YOLOv8 TFLite model on the 11 validation photos.

This is a *qualitative, small-scale* check, not a benchmark:
  * labels are weak - the expected class is derived from the file name
    ("helm*" -> helmet, "vest*" -> Vest, "Sepatu*" -> safety_shoe);
  * there are no ground-truth boxes, so mAP cannot be computed;
  * latency is measured on the machine running this script (desktop CPU).

Usage:
  python eval_yolo_tflite.py MODEL.tflite IMAGES_DIR OUT_DIR
Writes OUT_DIR/results.json, OUT_DIR/summary.md and annotated images.
"""
import json
import platform
import statistics
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

try:
    from ai_edge_litert.interpreter import Interpreter
except ImportError:  # pragma: no cover
    import tensorflow as tf
    Interpreter = tf.lite.Interpreter

LABELS = ['Gloves', 'Vest', 'goggles', 'helmet', 'mask', 'safety_shoe']
CONF_THR = 0.25   # same as the app (yolo_service.dart)
IOU_THR = 0.45
IMGSZ = 640
EXPECT = {'helm': 'helmet', 'vest': 'Vest', 'sepatu': 'safety_shoe'}


def expected_class(name):
    low = name.lower()
    for key, cls in EXPECT.items():
        if low.startswith(key):
            return cls
    return None


def preprocess(img, mode):
    w, h = img.size
    if mode == 'resize':                      # what the app does
        arr = np.asarray(img.resize((IMGSZ, IMGSZ), Image.BILINEAR), np.float32) / 255
        return arr[None], (IMGSZ / w, IMGSZ / h, 0, 0)
    scale = min(IMGSZ / w, IMGSZ / h)          # standard Ultralytics letterbox
    nw, nh = round(w * scale), round(h * scale)
    canvas = Image.new('RGB', (IMGSZ, IMGSZ), (114, 114, 114))
    px, py = (IMGSZ - nw) // 2, (IMGSZ - nh) // 2
    canvas.paste(img.resize((nw, nh), Image.BILINEAR), (px, py))
    return np.asarray(canvas, np.float32)[None] / 255, (scale, scale, px, py)


def iou(a, b):
    x1, y1 = max(a[0], b[0]), max(a[1], b[1])
    x2, y2 = min(a[2], b[2]), min(a[3], b[3])
    inter = max(0, x2 - x1) * max(0, y2 - y1)
    ua = (a[2] - a[0]) * (a[3] - a[1]) + (b[2] - b[0]) * (b[3] - b[1]) - inter
    return inter / ua if ua > 0 else 0


def decode(out, orig_w, orig_h, tf_):
    """out: [10, 8400] = xywh + 6 class scores (raw YOLOv8 export)."""
    sx, sy, px, py = tf_
    boxes, scores = out[:4].T, out[4:].T
    norm = boxes.max() <= 1.5                  # coordinates may be 0..1
    dets = []
    cls = scores.argmax(1)
    conf = scores.max(1)
    for i in np.where(conf >= CONF_THR)[0]:
        cx, cy, bw, bh = boxes[i] * (IMGSZ if norm else 1)
        x1, y1, x2, y2 = cx - bw / 2, cy - bh / 2, cx + bw / 2, cy + bh / 2
        x1, x2 = (x1 - px) / sx, (x2 - px) / sx
        y1, y2 = (y1 - py) / sy, (y2 - py) / sy
        dets.append((float(conf[i]), int(cls[i]),
                     [max(0, x1), max(0, y1), min(orig_w, x2), min(orig_h, y2)]))
    dets.sort(key=lambda d: -d[0])
    keep = []
    for d in dets:                              # class-wise NMS
        if all(k[1] != d[1] or iou(k[2], d[2]) < IOU_THR for k in keep):
            keep.append(d)
    return keep


def main(model, images, out_dir):
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    it = Interpreter(model_path=str(model), num_threads=4)
    it.allocate_tensors()
    inp, outp = it.get_input_details()[0], it.get_output_details()[0]

    rows, lat = [], []
    files = sorted(Path(images).glob('*.jp*g'))
    for mode in ('resize', 'letterbox'):
        for f in files:
            img = Image.open(f).convert('RGB')
            x, tf_ = preprocess(img, mode)
            t0 = time.perf_counter()
            it.set_tensor(inp['index'], x)
            it.invoke()
            out = it.get_tensor(outp['index'])[0]
            ms = (time.perf_counter() - t0) * 1000
            if mode == 'resize':
                lat.append(ms)
            dets = decode(out, *img.size, tf_)
            exp = expected_class(f.name)
            hit = [d for d in dets if LABELS[d[1]] == exp]
            rows.append({
                'image': f.name, 'preprocess': mode, 'expected': exp,
                'hit': bool(hit), 'best_expected_conf': round(hit[0][0], 3) if hit else None,
                'n_detections': len(dets),
                'detections': [{'class': LABELS[d[1]], 'conf': round(d[0], 3),
                                'box': [round(v) for v in d[2]]} for d in dets],
            })
            if mode == 'resize':
                d = ImageDraw.Draw(img)
                for c, k, b in dets:
                    d.rectangle(b, outline=(255, 107, 0), width=4)
                    d.text((b[0] + 4, b[1] + 4), f'{LABELS[k]} {c:.2f}', fill=(255, 255, 255))
                img.save(out_dir / f'annotated_{f.stem}.jpg')

    # latency: warm-up then 30 timed runs on the first image
    img = Image.open(files[0]).convert('RGB')
    x, _ = preprocess(img, 'resize')
    for _ in range(3):
        it.set_tensor(inp['index'], x); it.invoke()
    times = []
    for _ in range(30):
        t0 = time.perf_counter()
        it.set_tensor(inp['index'], x); it.invoke()
        times.append((time.perf_counter() - t0) * 1000)

    def rate(mode):
        r = [x for x in rows if x['preprocess'] == mode]
        return sum(x['hit'] for x in r), len(r)

    summary = {
        'model': Path(model).name, 'model_bytes': Path(model).stat().st_size,
        'input_shape': inp['shape'].tolist(), 'output_shape': outp['shape'].tolist(),
        'conf_thr': CONF_THR, 'iou_thr': IOU_THR,
        'images': len(files),
        'hit_resize': rate('resize'), 'hit_letterbox': rate('letterbox'),
        'latency_ms_mean': round(statistics.mean(times), 1),
        'latency_ms_median': round(statistics.median(times), 1),
        'latency_ms_p95': round(sorted(times)[int(0.95 * len(times)) - 1], 1),
        'machine': f'{platform.processor() or platform.machine()} / {platform.system()} '
                   f'{platform.release()} / Python {platform.python_version()}',
    }
    (out_dir / 'results.json').write_text(
        json.dumps({'summary': summary, 'rows': rows}, indent=2), encoding='utf8')

    lines = ['| Image | Expected | Hit (app resize) | Conf | Hit (letterbox) | Conf | Detections (resize) |',
             '|---|---|---|---|---|---|---|']
    by = {(r['image'], r['preprocess']): r for r in rows}
    for f in files:
        a, b = by[(f.name, 'resize')], by[(f.name, 'letterbox')]
        det = ', '.join(f"{d['class']} {d['conf']:.2f}" for d in a['detections']) or '-'
        lines.append(f"| {f.name} | {a['expected']} | {'yes' if a['hit'] else 'no'} | "
                     f"{a['best_expected_conf'] or '-'} | {'yes' if b['hit'] else 'no'} | "
                     f"{b['best_expected_conf'] or '-'} | {det} |")
    (out_dir / 'summary.md').write_text('\n'.join(lines) + '\n', encoding='utf8')
    print(json.dumps(summary, indent=2))
    print('\n'.join(lines))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
