"""Extra detector experiments on the 11 validation photos (author's model).

  E1  confidence-threshold sweep      (hit rate vs tau)
  E2  robustness to perturbations     (brightness, blur, JPEG, rotation, noise, occlusion, downscale)
  E3  negative images                 (false positives on non-PPE images)
  E4  latency vs. CPU threads

Usage: python experiments.py MODEL.tflite IMAGES_DIR OUT_DIR
Everything is seeded; results go to OUT_DIR/experiments.json and experiments.md.
"""
import io
import json
import random
import statistics
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageEnhance, ImageFilter

sys.path.insert(0, str(Path(__file__).parent))
import eval_yolo_tflite as ev  # noqa: E402

SEED = 7


def load(model, threads):
    it = ev.Interpreter(model_path=str(model), num_threads=threads)
    it.allocate_tensors()
    return it, it.get_input_details()[0], it.get_output_details()[0]


def run(it, inp, outp, img, mode='letterbox'):
    x, tf_ = ev.preprocess(img, mode)
    it.set_tensor(inp['index'], x)
    it.invoke()
    return it.get_tensor(outp['index'])[0], tf_


def detections(it, inp, outp, img, thr, mode='letterbox'):
    out, tf_ = run(it, inp, outp, img, mode)
    old = ev.CONF_THR
    ev.CONF_THR = thr
    try:
        return ev.decode(out, *img.size, tf_)
    finally:
        ev.CONF_THR = old


def perturbations(seed=SEED):
    rnd = random.Random(seed)

    def bright(f):
        return lambda im: ImageEnhance.Brightness(im).enhance(f)

    def blur(r):
        return lambda im: im.filter(ImageFilter.GaussianBlur(r))

    def jpeg(q):
        def f(im):
            b = io.BytesIO(); im.save(b, 'JPEG', quality=q); b.seek(0)
            return Image.open(b).convert('RGB')
        return f

    def rot(a):
        return lambda im: im.rotate(a, expand=True, fillcolor=(114, 114, 114))

    def noise(s):
        def f(im):
            a = np.asarray(im, np.float32)
            g = np.random.default_rng(seed).normal(0, s * 255, a.shape)
            return Image.fromarray(np.clip(a + g, 0, 255).astype('uint8'))
        return f

    def occlude(frac):
        def f(im):
            w, h = im.size
            ow, oh = int(w * frac ** .5), int(h * frac ** .5)
            x, y = rnd.randint(0, w - ow), rnd.randint(0, h - oh)
            im = im.copy(); ImageDraw.Draw(im).rectangle([x, y, x + ow, y + oh], fill=(90, 90, 90))
            return im
        return f

    def down(s):
        return lambda im: im.resize((max(32, int(im.width * s)), max(32, int(im.height * s)))).resize(im.size)

    return {
        'original': lambda im: im,
        'dark x0.4': bright(0.4), 'bright x1.8': bright(1.8),
        'blur r=3': blur(3), 'blur r=8': blur(8),
        'JPEG q=20': jpeg(20), 'noise sigma=0.08': noise(0.08),
        'rotate +15 deg': rot(15), 'rotate -15 deg': rot(-15),
        'occlusion 25%': occlude(0.25), 'downscale x0.25': down(0.25),
    }


def negatives():
    imgs = []
    try:
        from sklearn.datasets import load_sample_images
        for name, im in zip(load_sample_images().filenames, load_sample_images().images):
            imgs.append((f'sklearn:{Path(name).name}', Image.fromarray(im)))
    except Exception:  # sklearn optional
        pass
    rng = np.random.default_rng(SEED)
    for i in range(6):
        c = tuple(int(v) for v in rng.integers(0, 255, 3))
        imgs.append((f'solid{i}', Image.new('RGB', (640, 640), c)))
    for i in range(6):
        imgs.append((f'noise{i}', Image.fromarray(rng.integers(0, 255, (640, 640, 3), dtype=np.uint8))))
    g = np.tile(np.linspace(0, 255, 640, dtype=np.uint8), (640, 1))
    imgs.append(('gradient', Image.fromarray(np.stack([g, g[::-1], g], -1))))
    return imgs


def main(model, images, out_dir):
    out_dir = Path(out_dir); out_dir.mkdir(parents=True, exist_ok=True)
    files = sorted(Path(images).glob('*.jp*g'))
    photos = [(f.name, Image.open(f).convert('RGB'), ev.expected_class(f.name)) for f in files]
    it, inp, outp = load(model, 4)
    res = {}

    # E1 threshold sweep
    taus = [0.25, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]
    e1 = {}
    for mode in ('resize', 'letterbox'):
        e1[mode] = {}
        for t in taus:
            hits = 0
            for _, im, exp in photos:
                d = detections(it, inp, outp, im, t, mode)
                hits += any(ev.LABELS[k] == exp for _, k, _ in d)
            e1[mode][str(t)] = hits
    res['E1_threshold_sweep_hits_of_11'] = e1

    # E2 perturbations (letterbox, tau=0.25) - hit and mean conf of expected class
    e2 = {}
    for name, fn in perturbations().items():
        hits, confs, wrong = 0, [], 0
        for _, im, exp in photos:
            d = detections(it, inp, outp, fn(im), 0.25)
            m = [c for c, k, _ in d if ev.LABELS[k] == exp]
            hits += bool(m)
            confs.append(max(m) if m else 0.0)
            wrong += sum(1 for _, k, _ in d if ev.LABELS[k] != exp)
        e2[name] = {'hits': hits, 'mean_conf': round(statistics.mean(confs), 3), 'wrong_class_boxes': wrong}
    res['E2_perturbations'] = e2

    # E3 negatives
    neg = negatives()
    fp_by_tau = {}
    for t in (0.25, 0.5, 0.7):
        fp_imgs, fp_boxes = 0, 0
        for _, im in neg:
            d = detections(it, inp, outp, im, t)
            fp_imgs += bool(d); fp_boxes += len(d)
        fp_by_tau[str(t)] = {'images_with_detection': fp_imgs, 'boxes': fp_boxes}
    res['E3_negatives'] = {'n_images': len(neg), 'sources': sorted({n.split(':')[0].rstrip('0123456789') for n, _ in neg}),
                           'false_positives': fp_by_tau}

    # E4 latency vs threads
    e4 = {}
    im = photos[0][1]
    for th in (1, 2, 4, 8):
        it2, i2, o2 = load(model, th)
        for _ in range(3):
            run(it2, i2, o2, im)
        ts = []
        for _ in range(50):
            t0 = time.perf_counter(); run(it2, i2, o2, im); ts.append((time.perf_counter() - t0) * 1000)
        e4[str(th)] = {'mean_ms': round(statistics.mean(ts), 1), 'p95_ms': round(sorted(ts)[47], 1)}
    res['E4_latency_by_threads'] = e4

    (out_dir / 'experiments.json').write_text(json.dumps(res, indent=2), encoding='utf8')
    md = ['## E1 - hits (of 11) vs confidence threshold', '| tau | ' + ' | '.join(map(str, taus)) + ' |',
          '|---|' + '---|' * len(taus)]
    for mode in e1:
        md.append(f'| {mode} | ' + ' | '.join(str(e1[mode][str(t)]) for t in taus) + ' |')
    md += ['', '## E2 - perturbations (letterbox, tau 0.25)', '| perturbation | hits/11 | mean conf | wrong-class boxes |', '|---|---|---|---|']
    md += [f'| {k} | {v["hits"]} | {v["mean_conf"]} | {v["wrong_class_boxes"]} |' for k, v in e2.items()]
    md += ['', f'## E3 - negatives ({len(neg)} images)', '| tau | images with a detection | boxes |', '|---|---|---|']
    md += [f'| {t} | {v["images_with_detection"]} | {v["boxes"]} |' for t, v in fp_by_tau.items()]
    md += ['', '## E4 - latency vs threads', '| threads | mean ms | p95 ms |', '|---|---|---|']
    md += [f'| {t} | {v["mean_ms"]} | {v["p95_ms"]} |' for t, v in e4.items()]
    (out_dir / 'experiments.md').write_text('\n'.join(md) + '\n', encoding='utf8')
    print('\n'.join(md))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
