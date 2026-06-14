import numpy as np, tensorflow as tf
from pathlib import Path
from PIL import Image
import collections

MODEL  = 'assets/models/best.tflite'
CONF   = 0.25
LABELS = ['Gloves','Vest','goggles','helmet','mask','safety_shoe']

interp = tf.lite.Interpreter(model_path=MODEL)
interp.allocate_tensors()
inp_d = interp.get_input_details()[0]
out_d = interp.get_output_details()[0]

base    = Path(r'D:\belajar deeplearning\data baru\test')
img_dir = base / 'images'
lbl_dir = base / 'labels'

pred_counts = collections.Counter()
gt_counts   = collections.Counter()
total       = 0

img_files = list(img_dir.glob('*.jpg')) + list(img_dir.glob('*.jpeg'))
for img_file in img_files[:50]:
    lf = lbl_dir / (img_file.stem + '.txt')
    if lf.exists():
        for line in lf.read_text(errors='ignore').strip().splitlines():
            if line.strip():
                try: gt_counts[int(line.split()[0])] += 1
                except: pass

    img = Image.open(img_file).convert('RGB').resize((640, 640))
    arr = (np.array(img, dtype=np.float32) / 255.0)[np.newaxis]
    interp.set_tensor(inp_d['index'], arr)
    interp.invoke()
    raw = interp.get_tensor(out_d['index'])[0]

    for row in raw:
        conf = float(row[4])
        cls  = int(round(float(row[5])))
        if conf >= CONF and 0 <= cls < len(LABELS):
            pred_counts[cls] += 1
    total += 1

print(f"Diperiksa: {total} gambar test\n")
print(f"{'Label':<15} {'GT':>5} {'Pred':>5} {'Selisih':>8}")
print("-" * 38)
for i, lbl in enumerate(LABELS):
    gt   = gt_counts[i]
    pred = pred_counts[i]
    diff = pred - gt
    note = " <<< OVER" if pred > gt * 2 and pred > 5 else ""
    note = " <<< MISS" if pred < gt // 2 and gt > 5 else note
    print(f"{lbl:<15} {gt:>5} {pred:>5} {diff:>+8}{note}")
