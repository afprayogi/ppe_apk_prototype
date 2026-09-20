# LinkedIn post drafts

Tip: on LinkedIn, upload the PDF as a *document* (the + → Add a document) so it shows as a swipeable carousel in the post.

Attach: `docs/screenshots/02-dashboard.png`, `04-scan-result.png`,
`05-attendance.png`, `07-archive.png` (carousel), or a screen recording.

---

## Bahasa Indonesia

Saya merombak total prototipe aplikasi deteksi APD (PPE) saya menjadi **GearGuard**, aplikasi Flutter untuk memastikan setiap pekerja memakai perlengkapan keselamatan sebelum masuk area kerja. 🦺

Yang saya bangun:
✅ Scan APD dengan skor keyakinan per item (helm, rompi, sarung tangan, sepatu)
✅ Absensi harian + status kepatuhan
✅ Ranking kepatuhan tim & riwayat per pekerja
✅ Arsip scan dan ekspor laporan PDF untuk audit K3
✅ Tema terang/gelap, desain sistem sendiri

Di balik layar: arsitektur berlapis dengan flutter_bloc, dan satu interface `PpeDetector` sehingga model YOLO asli bisa dipasang tanpa mengubah UI.

Catatan jujur: versi saat ini memakai detektor simulasi untuk demo alur. Integrasi model sungguhan dan uji pengguna adalah tahap berikutnya (sedang saya siapkan sebagai paper).

Kode & dokumentasi: <link GitHub>
📄 Draf paper (ID): docs/paper/GearGuard-paper-id.pdf
📄 Paper draft (EN): docs/paper/GearGuard-paper-en.pdf

#Flutter #Dart #K3 #KeselamatanKerja #MobileDevelopment #ComputerVision #Portfolio

---

## English

I rebuilt my PPE-detection prototype into **GearGuard**, a Flutter app that checks workers for required safety equipment before they enter a work area.

• Per-item confidence for helmet, vest, gloves, boots
• Daily attendance with compliance status
• Team ranking and per-worker history
• Scan archive + PDF audit reports
• Light/dark themes, custom design system

Under the hood: layered architecture with flutter_bloc and a single `PpeDetector` interface, so a real YOLO model can be plugged in without touching the UI.

Honest note: the current build uses a simulated detector to demo the workflow. Real model integration and a usability study are next — I'm preparing them as a paper.

Code: <GitHub link>
📄 Paper draft (EN): docs/paper/GearGuard-paper-en.pdf
📄 Draf paper (ID): docs/paper/GearGuard-paper-id.pdf

#Flutter #Dart #OccupationalSafety #MobileDev #ComputerVision #Portfolio
