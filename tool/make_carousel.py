"""Builds the LinkedIn carousel (PNG slides + one PDF) from docs/screenshots.

  python tool/make_carousel.py
Output: docs/linkedin/slide-*.png and docs/linkedin/GearGuard-carousel.pdf
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
SHOTS = ROOT / 'docs' / 'screenshots'
OUT = ROOT / 'docs' / 'linkedin'
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1080, 1350
BG, INK, MUTED = (11, 17, 32), (241, 245, 249), (148, 163, 184)
ORANGE, AMBER, GREEN, RED = (255, 107, 0), (255, 179, 0), (16, 185, 129), (239, 68, 68)
FONTS = Path('C:/Windows/Fonts')


def font(size, bold=False):
    for name in (('segoeuib.ttf' if bold else 'segoeui.ttf'), ('arialbd.ttf' if bold else 'arial.ttf')):
        p = FONTS / name
        if p.exists():
            return ImageFont.truetype(str(p), size)
    return ImageFont.load_default()


def canvas():
    im = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, W, 10], fill=ORANGE)
    return im, d


def footer(d, n, total):
    d.text((60, H - 70), 'GearGuard · PPE compliance', font=font(28), fill=MUTED)
    d.text((W - 60, H - 70), f'{n}/{total}', font=font(28), fill=MUTED, anchor='ra')


def wrap(d, text, f, width):
    lines, cur = [], ''
    for w in text.split():
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=f) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def shot_slide(title, sub, img_name):
    im, d = canvas()
    d.text((60, 70), title, font=font(60, True), fill=INK)
    y = 160
    for line in wrap(d, sub, font(34), W - 120):
        d.text((60, y), line, font=font(34), fill=MUTED)
        y += 46
    s = Image.open(SHOTS / img_name).convert('RGB')
    th = H - y - 130
    tw = int(s.width * th / s.height)
    s = s.resize((tw, th), Image.LANCZOS)
    mask = Image.new('L', s.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, tw, th], radius=44, fill=255)
    px = (W - tw) // 2
    im.paste(s, (px, y + 20), mask)
    return im


def stats_slide():
    im, d = canvas()
    d.text((60, 70), 'Verified, not just built', font=font(62, True), fill=INK)
    rows = [('38', 'automated tests pass', GREEN), ('75.1%', 'line coverage', GREEN),
            ('20/20', 'accessibility checks (3 failed first, then fixed)', GREEN),
            ('11/11', 'validation photos: expected PPE class found', AMBER),
            ('~80 ms', 'per frame, YOLO TFLite on a desktop CPU', AMBER)]
    y = 230
    for big, small, c in rows:
        d.text((60, y), big, font=font(92, True), fill=c)
        d.text((60, y + 105), small, font=font(32), fill=MUTED)
        y += 200
    footer(d, 6, 8)
    return im


def honest_slide():
    im, d = canvas()
    d.text((60, 70), 'What the tests found', font=font(62, True), fill=INK)
    d.text((60, 165), 'Honest results, including weaknesses', font=font(34), fill=MUTED)
    items = [('Occlusion', '25% patch over the image → only 5/11 detected', RED),
             ('Colour bias', 'plain orange patch → false "Vest" at 0.81', RED),
             ('Threshold', 'letterbox keeps 11/11 up to τ = 0.7; app resize drops at 0.6', AMBER),
             ('Robust to', 'darkening · JPEG · ±15° rotation · noise · 4× downscale', GREEN)]
    y = 270
    for head, body, c in items:
        d.rounded_rectangle([60, y, W - 60, y + 190], radius=28, fill=(22, 34, 58))
        d.rectangle([60, y + 24, 72, y + 166], fill=c)
        d.text((110, y + 26), head, font=font(44, True), fill=INK)
        yy = y + 90
        for line in wrap(d, body, font(32), W - 260):
            d.text((110, yy), line, font=font(32), fill=MUTED)
            yy += 42
        y += 220
    d.text((60, y + 10), 'Not claimed: accuracy (mAP) or usability. Both still to do.', font=font(30, True), fill=AMBER)
    footer(d, 7, 8)
    return im


def cover():
    im, d = canvas()
    logo = Image.open(ROOT / 'assets' / 'brand' / 'app_icon.png').convert('RGBA').resize((300, 300), Image.LANCZOS)
    im.paste(logo, (60, 200), logo)
    d.text((60, 560), 'GearGuard', font=font(130, True), fill=INK)
    d.text((60, 720), 'PPE compliance scanning,', font=font(58), fill=MUTED)
    d.text((60, 790), 'attendance & audit reports', font=font(58), fill=MUTED)
    d.text((60, 940), 'Flutter · flutter_bloc · YOLO-ready', font=font(38, True), fill=ORANGE)
    d.text((60, 1010), 'Preprint + open source', font=font(38), fill=MUTED)
    footer(d, 1, 8)
    return im


def cta():
    im, d = canvas()
    d.text((60, 120), 'Code & paper', font=font(76, True), fill=INK)
    for i, (a, b) in enumerate([('GitHub', 'github.com/afprayogi/ppe_apk_prototype  (branch main)'),
                                ('Paper', 'docs/paper: English + Bahasa Indonesia PDF'),
                                ('Study kit', 'SUS questionnaire (EN/ID) + scoring script')]):
        y = 300 + i * 200
        d.text((60, y), a, font=font(48, True), fill=ORANGE)
        for j, line in enumerate(wrap(d, b, font(34), W - 120)):
            d.text((60, y + 70 + j * 44), line, font=font(34), fill=MUTED)
    d.text((60, 990), 'Feedback welcome — especially from K3 / safety officers.', font=font(36, True), fill=INK)
    footer(d, 8, 8)
    return im


def main():
    slides = [
        cover(),
        shot_slide('Today at a glance', 'Live compliance ring, check-ins, violations and a 7-day trend.', '02-dashboard.png'),
        shot_slide('Scan with confidence scores', 'Per-item checklist and bounding boxes. Demo detector in the app; real YOLO model tested separately.', '04-scan-result.png'),
        shot_slide('Attendance with PPE status', 'Violations first; one tap to scan whoever has not checked in.', '05-attendance.png'),
        shot_slide('Team ranking & archive', 'Rank by compliance, filter scans, export PDF reports.', '06-team-ranking.png'),
        stats_slide(),
        honest_slide(),
        cta(),
    ]
    for i, im in enumerate(slides, 1):
        if i in (2, 3, 4, 5):
            ImageDraw.Draw(im).text((60, H - 70), 'GearGuard · PPE compliance', font=font(28), fill=MUTED)
            ImageDraw.Draw(im).text((W - 60, H - 70), f'{i}/8', font=font(28), fill=MUTED, anchor='ra')
        im.save(OUT / f'slide-{i}.png')
    slides[0].save(OUT / 'GearGuard-carousel.pdf', save_all=True, append_images=slides[1:], resolution=150)
    print('ok', len(slides))


if __name__ == '__main__':
    main()
