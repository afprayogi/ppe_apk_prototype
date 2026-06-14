import numpy as np, tensorflow as tf, collections
from pathlib import Path
from PIL import Image

MODEL  = 'assets/models/best.tflite'
LABELS = ['Gloves','Vest','goggles','helmet','mask','safety_shoe']
CONF   = 0.25

interp = tf.lite.Interpreter(model_path=MODEL)
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out = interp.get_output_details()[0]

print('=== INFO MODEL ===')
print(f'Input  shape : {inp["shape"]}  dtype={inp["dtype"]}')
print(f'Output shape : {out["shape"]}  dtype={out["dtype"]}')
print(f'Input  quant : {inp["quantization"]}')
print(f'Output quant : {out["quantization"]}')
print(f'Format       : postNMS [nDet x 6] = [x1,y1,x2,y2,conf,cls]')

# Sanity check - gambar abu-abu
blank = np.full((1,640,640,3), 0.5, dtype=np.float32)
interp.set_tensor(inp['index'], blank)
interp.invoke()
r = interp.get_tensor(out['index'])[0]
nonzero = sum(1 for row in r if row[4] > 0.01)
print(f'\n=== SANITY CHECK (input abu-abu, harusnya 0 deteksi) ===')
print(f'Deteksi pada input kosong : {nonzero}')

# Validasi pada gambar nyata dengan LETTERBOX
val_dir = Path('assets/validasi')
pred_per_cls = collections.Counter()
conf_per_cls = collections.defaultdict(list)
total = 0

print(f'\n=== PER GAMBAR ===')
for img_path in sorted(val_dir.glob('*.*')):
    if img_path.suffix.lower() not in ['.jpg','.jpeg','.png']: continue
    img = Image.open(img_path).convert('RGB')
    W, H = img.size
    scale = min(640/W, 640/H)
    nW, nH = int(W*scale), int(H*scale)
    padX, padY = (640-nW)//2, (640-nH)//2
    canvas = Image.new('RGB', (640,640), (128,128,128))
    canvas.paste(img.resize((nW,nH), Image.BILINEAR), (padX,padY))
    arr = (np.array(canvas, dtype=np.float32)/255.0)[np.newaxis]
    interp.set_tensor(inp['index'], arr)
    interp.invoke()
    raw = interp.get_tensor(out['index'])[0]
    dets = []
    for row in raw:
        c = float(row[4]); cls = int(round(float(row[5])))
        if c >= CONF and 0 <= cls < len(LABELS):
            pred_per_cls[cls] += 1
            conf_per_cls[cls].append(c)
            dets.append(f'{LABELS[cls]}:{c:.2f}')
    det_str = ', '.join(dets) if dets else 'TIDAK ADA'
    print(f'  {img_path.name:30s}: {det_str}')
    total += 1

print(f'\n=== STATISTIK ({total} gambar) ===')
print(f'{"Label":<15} {"N":>4} {"AvgConf":>8} {"MaxConf":>8}')
print('-'*38)
for i, lbl in enumerate(LABELS):
    n   = pred_per_cls[i]
    avg = np.mean(conf_per_cls[i]) if conf_per_cls[i] else 0
    mx  = max(conf_per_cls[i]) if conf_per_cls[i] else 0
    bar = '*' * n
    print(f'{lbl:<15} {n:>4} {avg:>8.3f} {mx:>8.3f}  {bar}')

# Cek bias: coba gambar stretch vs letterbox pada satu gambar
print('\n=== STRETCH vs LETTERBOX ===')
helm = list(val_dir.glob('helm*'))[0]
img  = Image.open(helm).convert('RGB')
W, H = img.size

# Stretch
arr_s = (np.array(img.resize((640,640),Image.BILINEAR),dtype=np.float32)/255.0)[np.newaxis]
interp.set_tensor(inp['index'], arr_s); interp.invoke()
r_s = interp.get_tensor(out['index'])[0]
d_s = [(LABELS[int(round(float(r[5])))], float(r[4])) for r in r_s if r[4]>=CONF and int(round(float(r[5])))<6]

# Letterbox
scale = min(640/W,640/H); nW,nH = int(W*scale),int(H*scale)
pX,pY = (640-nW)//2,(640-nH)//2
cv = Image.new('RGB',(640,640),(128,128,128))
cv.paste(img.resize((nW,nH),Image.BILINEAR),(pX,pY))
arr_l = (np.array(cv,dtype=np.float32)/255.0)[np.newaxis]
interp.set_tensor(inp['index'], arr_l); interp.invoke()
r_l = interp.get_tensor(out['index'])[0]
d_l = [(LABELS[int(round(float(r[5])))], float(r[4])) for r in r_l if r[4]>=CONF and int(round(float(r[5])))<6]

print(f'  {helm.name} ({W}x{H})')
print(f'  Stretch  : {d_s if d_s else "tidak ada"}')
print(f'  Letterbox: {d_l if d_l else "tidak ada"}')
