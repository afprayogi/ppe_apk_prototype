# LinkedIn — siap posting

**Lampiran yang disarankan (pilih satu):**
1. **Dokumen/carousel:** `docs/linkedin/GearGuard-carousel.pdf` (8 slide, 1080×1350) — di LinkedIn pilih *+ → Add a document*.
2. Atau gambar: `docs/linkedin/slide-1.png … slide-8.png` (maks. 9 gambar).
3. Paper (opsional, unggah di komentar atau sebagai dokumen kedua):
   `docs/paper/GearGuard-paper-id.pdf` dan `GearGuard-paper-en.pdf`.

**Tautan untuk dipasang di post / komentar pertama:**
- Kode: https://github.com/afprayogi/ppe_apk_prototype/tree/main
- Paper (ID): https://github.com/afprayogi/ppe_apk_prototype/blob/main/docs/paper/GearGuard-paper-id.pdf
- Paper (EN): https://github.com/afprayogi/ppe_apk_prototype/blob/main/docs/paper/GearGuard-paper-en.pdf

> Tip: LinkedIn menekan jangkauan post yang berisi tautan luar. Taruh tautan di **komentar pertama**, dan tulis "link di komentar" di post.

---

## Bahasa Indonesia

Saya merombak total prototipe deteksi APD (PPE) saya menjadi **GearGuard** 🦺 — aplikasi Flutter yang memastikan setiap pekerja memakai perlengkapan keselamatan sebelum masuk area kerja.

Yang ada di dalamnya:
✅ Scan APD dengan skor keyakinan per item + kotak deteksi
✅ Absensi harian dengan status kepatuhan
✅ Ranking tim, arsip scan, dan laporan PDF untuk audit K3
✅ Tema terang/gelap dengan design system sendiri

Yang saya kerjakan di belakang layar, dan hasilnya jujur:
📊 38 tes otomatis lolos, cakupan kode 75,1%
♿ 20 pemeriksaan aksesibilitas — 3 sempat GAGAL (kontras teks 2,13:1), lalu saya perbaiki
🎯 Model YOLO saya mendeteksi kelas yang diharapkan di 11/11 foto validasi, ±80 ms/frame di CPU desktop
⚠️ Tapi juga menemukan kelemahan: tertutup 25% saja hanya 5/11 yang terdeteksi, dan bidang oranye polos dikira "rompi"

Semua saya tulis di paper (Indonesia + Inggris). Catatan penting: paper ini pracetak, belum ditelaah sejawat, dan belum mengklaim akurasi (mAP) maupun kebergunaan — uji pengguna adalah langkah berikutnya.

Kode, paper, dan kit uji SUS: link di komentar 👇
Masukan dari rekan K3 / safety sangat saya tunggu!

#Flutter #Dart #K3 #KeselamatanKerja #ComputerVision #YOLO #MobileDevelopment #OpenSource

---

## English

I rebuilt my PPE-detection prototype into **GearGuard** 🦺 — a Flutter app that checks workers for required safety equipment before they enter a work area.

What it does:
✅ PPE scan with per-item confidence and bounding boxes
✅ Daily attendance with compliance status
✅ Team ranking, scan archive and PDF audit reports
✅ Light/dark themes on a custom design system

What I verified — including the unflattering parts:
📊 38 automated tests pass, 75.1% line coverage
♿ 20 accessibility checks — 3 FAILED at first (text contrast as low as 2.13:1); fixed
🎯 My YOLO model found the expected class in 11/11 validation photos, ~80 ms/frame on a desktop CPU
⚠️ It also has weaknesses: with a 25% occlusion patch only 5/11 were detected, and a plain orange patch was labelled "Vest"

Everything is written up in a short paper (English + Bahasa Indonesia). Important caveat: it's a preprint, not peer reviewed, and it makes no accuracy (mAP) or usability claim yet — a user study is next.

Code, paper and the SUS study kit: link in the comments 👇
Feedback from safety / EHS folks very welcome!

#Flutter #Dart #OccupationalSafety #ComputerVision #YOLO #MobileDev #OpenSource

---

## Komentar pertama / First comment

🔗 Code: https://github.com/afprayogi/ppe_apk_prototype/tree/main
📄 Paper (ID): https://github.com/afprayogi/ppe_apk_prototype/blob/main/docs/paper/GearGuard-paper-id.pdf
📄 Paper (EN): https://github.com/afprayogi/ppe_apk_prototype/blob/main/docs/paper/GearGuard-paper-en.pdf
