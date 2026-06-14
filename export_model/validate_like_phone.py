"""
Simulasi inference seperti di HP:
- Load best.tflite dari assets
- Jalankan pada gambar validasi
- Tampilkan bounding box + label seperti Flutter
"""

import numpy as np
import tensorflow as tf
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import json

# ── Config (sama persis dengan yolo_service.dart) ────────────────────────────
MODEL_PATH  = Path("assets/models/best.tflite")
LABELS      = ['Gloves', 'Vest', 'goggles', 'helmet', 'mask', 'safety_shoe']
CONF_THR    = 0.25
IOU_THR     = 0.45
IMGSZ       = 640
OUT_DIR     = Path("export_model/validasi_output")
OUT_DIR.mkdir(exist_ok=True)

# Warna per class
COLORS = [
    (255,  99,  71),  # Gloves      - tomato
    ( 50, 205,  50),  # Vest        - lime green
    ( 30, 144, 255),  # goggles     - dodger blue
    (255, 215,   0),  # helmet      - gold
    (238, 130, 238),  # mask        - violet
    (255, 165,   0),  # safety_shoe - orange
]

# ── Load TFLite ───────────────────────────────────────────────────────────────
print(f"Load model: {MODEL_PATH}")
interp = tf.lite.Interpreter(model_path=str(MODEL_PATH))
interp.allocate_tensors()
inp_det = interp.get_input_details()[0]
out_det = interp.get_output_details()[0]
print(f"  Input : {inp_det['shape']}  dtype={inp_det['dtype']}")
print(f"  Output: {out_det['shape']}  dtype={out_det['dtype']}")

out_shape = out_det['shape']  # [1, nDet, 6] atau [1, rows, anchors]
is_post_nms = out_shape[-1] == 6 and out_shape[1] <= 500
print(f"  Format: {'postNMS [nDet×6]' if is_post_nms else 'rawYOLO'}")


# ── Preprocess ────────────────────────────────────────────────────────────────
def preprocess(img_path):
    img = Image.open(img_path).convert("RGB")
    orig_w, orig_h = img.size
    resized = img.resize((IMGSZ, IMGSZ), Image.BILINEAR)
    arr = np.array(resized, dtype=np.float32) / 255.0   # HWC [640,640,3]
    return arr[np.newaxis], img, orig_w, orig_h          # BHWC [1,640,640,3]


# ── Inference ─────────────────────────────────────────────────────────────────
def run_inference(inp_arr):
    interp.set_tensor(inp_det['index'], inp_arr)
    interp.invoke()
    return interp.get_tensor(out_det['index'])[0]   # hilangkan batch dim


# ── Parse output [nDet, 6]: x1,y1,x2,y2,conf,cls ────────────────────────────
def parse_post_nms(flat, img_w, img_h):
    results = []
    ndet = flat.shape[0]
    for i in range(ndet):
        row  = flat[i]
        conf = float(row[4])
        cls  = int(round(float(row[5])))
        if conf < CONF_THR or cls >= len(LABELS):
            continue
        # coords normalized 0..1
        x1, y1, x2, y2 = float(row[0]), float(row[1]), float(row[2]), float(row[3])
        # kalau koordinat pixel (>1.5), normalisasi dulu
        if x2 > 1.5:
            x1 /= IMGSZ; y1 /= IMGSZ; x2 /= IMGSZ; y2 /= IMGSZ
        results.append({
            'label': LABELS[cls],
            'cls'  : cls,
            'conf' : conf,
            'x1'   : x1, 'y1': y1, 'x2': x2, 'y2': y2,
        })
    return results


# ── Parse raw YOLOv8 [rows, anchors] ─────────────────────────────────────────
def parse_raw_yolo(flat, img_w, img_h):
    # flat shape: [10, 8400] → rows=10, anchors=8400
    rows, anchors = flat.shape
    num_cls = rows - 4
    results = []
    for a in range(anchors):
        best_cls, best_conf = 0, 0.0
        for c in range(num_cls):
            s = flat[4 + c, a]
            if s > best_conf:
                best_conf = s; best_cls = c
        if best_conf < CONF_THR or best_cls >= len(LABELS):
            continue
        cx = flat[0, a]; cy = flat[1, a]
        w  = flat[2, a]; h  = flat[3, a]
        x1 = (cx - w/2) / IMGSZ; y1 = (cy - h/2) / IMGSZ
        x2 = (cx + w/2) / IMGSZ; y2 = (cy + h/2) / IMGSZ
        results.append({
            'label': LABELS[best_cls], 'cls': best_cls,
            'conf': best_conf,
            'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2,
        })
    # NMS manual
    return nms(results)


def nms(boxes):
    boxes.sort(key=lambda b: b['conf'], reverse=True)
    kept, used = [], [False]*len(boxes)
    for i, a in enumerate(boxes):
        if used[i]: continue
        kept.append(a)
        for j in range(i+1, len(boxes)):
            if not used[j] and a['label'] == boxes[j]['label']:
                if iou(a, boxes[j]) > IOU_THR:
                    used[j] = True
    return kept

def iou(a, b):
    ix1 = max(a['x1'], b['x1']); iy1 = max(a['y1'], b['y1'])
    ix2 = min(a['x2'], b['x2']); iy2 = min(a['y2'], b['y2'])
    inter = max(0, ix2-ix1) * max(0, iy2-iy1)
    ua = (a['x2']-a['x1'])*(a['y2']-a['y1'])
    ub = (b['x2']-b['x1'])*(b['y2']-b['y1'])
    return inter / (ua + ub - inter + 1e-6)


# ── Draw hasil ────────────────────────────────────────────────────────────────
def draw_results(img, detections, orig_w, orig_h, fname):
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("arial.ttf", 18)
        font_sm = ImageFont.truetype("arial.ttf", 14)
    except:
        font = font_sm = ImageFont.load_default()

    for det in detections:
        c = det['cls']
        color = COLORS[c % len(COLORS)]
        x1 = int(det['x1'] * orig_w); y1 = int(det['y1'] * orig_h)
        x2 = int(det['x2'] * orig_w); y2 = int(det['y2'] * orig_h)
        draw.rectangle([x1, y1, x2, y2], outline=color, width=3)
        label = f"{det['label']} {det['conf']:.2f}"
        draw.rectangle([x1, y1-22, x1+len(label)*10, y1], fill=color)
        draw.text((x1+2, y1-20), label, fill='white', font=font_sm)

    out_path = OUT_DIR / fname
    img.save(out_path)
    return out_path


# ── Main: jalankan semua gambar validasi ─────────────────────────────────────
val_images = list(Path("assets/validasi").glob("*.jpg")) + \
             list(Path("assets/validasi").glob("*.jpeg")) + \
             list(Path("assets/validasi").glob("*.png"))

print(f"\nDitemukan {len(val_images)} gambar validasi\n")
summary = []

for img_path in val_images:
    inp_arr, orig_img, orig_w, orig_h = preprocess(img_path)
    raw = run_inference(inp_arr)

    if is_post_nms:
        dets = parse_post_nms(raw, orig_w, orig_h)
    else:
        dets = parse_raw_yolo(raw, orig_w, orig_h)

    out_img  = orig_img.copy()
    out_file = draw_results(out_img, dets, orig_w, orig_h, img_path.name)

    det_str = ', '.join(f"{d['label']}({d['conf']:.2f})" for d in dets) or 'tidak ada deteksi'
    print(f"  {img_path.name:30s} -> {det_str}")
    summary.append({'file': img_path.name, 'detections': dets})

# ── Simpan summary JSON ───────────────────────────────────────────────────────
summary_path = OUT_DIR / "summary.json"
with open(summary_path, 'w') as f:
    json.dump(summary, f, indent=2)

print(f"\nOutput disimpan di: {OUT_DIR.resolve()}")
print(f"Summary: {summary_path}")

# ── Statistik per class ───────────────────────────────────────────────────────
cls_counts = {l: 0 for l in LABELS}
cls_confs  = {l: [] for l in LABELS}
for s in summary:
    for d in s['detections']:
        cls_counts[d['label']] += 1
        cls_confs[d['label']].append(d['conf'])

print("\n=== Statistik Deteksi ===")
for lbl in LABELS:
    cnt = cls_counts[lbl]
    avg = np.mean(cls_confs[lbl]) if cls_confs[lbl] else 0
    bar = '█' * cnt
    print(f"  {lbl:15s}: {cnt:3d}x  avg_conf={avg:.2f}  {bar}")
