import numpy as np, tensorflow as tf
from pathlib import Path
from PIL import Image

MODEL  = 'assets/models/best.tflite'
LABELS = ['Gloves','Vest','goggles','helmet','mask','safety_shoe']

interp = tf.lite.Interpreter(model_path=MODEL)
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out = interp.get_output_details()[0]

# Test semua gambar validasi, print RAW output col5 (cls) supaya tau nilai aslinya
print("=== RAW OUTPUT MODEL (col4=conf, col5=cls_raw) ===")
for img_path in sorted(Path('assets/validasi').glob('*.jpeg')) + sorted(Path('assets/validasi').glob('*.jpg')):
    img = Image.open(img_path).convert('RGB').resize((640,640), Image.BILINEAR)
    arr = (np.array(img, dtype=np.float32)/255.0)[np.newaxis]
    interp.set_tensor(inp['index'], arr)
    interp.invoke()
    raw = interp.get_tensor(out['index'])[0]

    # Ambil 5 baris conf tertinggi
    top = sorted(raw, key=lambda r: r[4], reverse=True)[:5]
    print(f"\n{img_path.name}:")
    print(f"  {'conf':>6}  {'cls_raw':>8}  {'cls_int':>7}  {'label'}")
    for r in top:
        if r[4] < 0.01: break
        cls_raw = float(r[5])
        cls_int = int(round(cls_raw))
        lbl = LABELS[cls_int] if 0<=cls_int<6 else f'OUT({cls_int})'
        print(f"  {r[4]:6.3f}  {cls_raw:8.4f}  {cls_int:7d}  {lbl}")
