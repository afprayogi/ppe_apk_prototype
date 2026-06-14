from pathlib import Path
import collections
from PIL import Image

base  = Path(r'D:\belajar deeplearning\data baru')
names = {0:'Gloves',1:'Vest',2:'goggles',3:'helmet',4:'mask',5:'safety_shoe'}
split_counts = {s: collections.Counter() for s in ['train','valid','test']}
img_sizes = []

for split in ['train','valid','test']:
    lbl_dir = base/split/'labels'
    img_dir = base/split/'images'
    if not lbl_dir.exists(): continue
    for f in lbl_dir.glob('*.txt'):
        for line in f.read_text(errors='ignore').strip().splitlines():
            if line.strip():
                try: split_counts[split][int(line.split()[0])] += 1
                except: pass
    for p in list(img_dir.glob('*.jpg'))[:3]:
        try: img_sizes.append((split, Image.open(p).size))
        except: pass

print('=== DISTRIBUSI DATA ===')
header = f'{"Label":<15} {"train":>6} {"valid":>6} {"test":>6} {"TOTAL":>6}'
print(header)
print('-'*45)
for i, n in names.items():
    tr = split_counts['train'][i]
    vl = split_counts['valid'][i]
    te = split_counts['test'][i]
    tot = tr+vl+te
    flag = ' <<< SEDIKIT' if tot < 100 else ''
    print(f'{n:<15} {tr:>6} {vl:>6} {te:>6} {tot:>6}{flag}')

tr_tot = sum(split_counts['train'].values())
vl_tot = sum(split_counts['valid'].values())
te_tot = sum(split_counts['test'].values())
print(f'{"TOTAL":<15} {tr_tot:>6} {vl_tot:>6} {te_tot:>6} {tr_tot+vl_tot+te_tot:>6}')

print('\n=== UKURAN GAMBAR ===')
for split, size in img_sizes:
    print(f'  [{split}] {size[0]}x{size[1]}')

# Hitung rasio train:val:test
total = tr_tot+vl_tot+te_tot
print(f'\n=== SPLIT RATIO ===')
print(f'  Train : {tr_tot} ({100*tr_tot//total}%)')
print(f'  Valid : {vl_tot} ({100*vl_tot//total}%)')
print(f'  Test  : {te_tot} ({100*te_tot//total}%)')
