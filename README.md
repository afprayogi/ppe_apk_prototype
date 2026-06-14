# VivatPass — PPE Safety Detection App

Aplikasi Flutter untuk deteksi Alat Pelindung Diri (APD) secara real-time menggunakan kamera dan model YOLO, dilengkapi manajemen karyawan, absensi, serta ekspor laporan PDF.

---

## Download Model (Wajib)

> File model tidak disertakan dalam repo karena ukurannya besar (~18 MB).  
> **Unduh dari [GitHub Releases](https://github.com/afprayogi/ppe_apk_prototype/releases/latest)** lalu tempatkan sesuai tabel di bawah:

| File | Lokasi di Repo |
|---|---|
| `best.tflite` | `assets/models/best.tflite` |
| `best.onnx` | `android/app/src/main/assets/best.onnx` |

```bash
# Setelah download, salin file secara manual ke path di atas
# lalu jalankan:
flutter pub get
flutter run
```

---

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| Deteksi APD | Scan real-time via kamera menggunakan model YOLO (native Kotlin) |
| Manajemen Karyawan | Registrasi, riwayat, dan ranking kepatuhan APD |
| Absensi | Rekap kehadiran dengan grafik & tab personalia |
| Arsip | Riwayat hasil deteksi tersimpan lokal (SQLite) |
| Ekspor PDF | Cetak laporan langsung dari aplikasi |
| Pengaturan | Konfigurasi threshold, notifikasi, dan preferensi lainnya |

---

## Cara Menjalankan

```bash
# 1. Clone repo
git clone https://github.com/afprayogi/ppe_apk_prototype.git
cd ppe_apk_prototype

# 2. Download file model dari Releases dan letakkan:
#    - best.tflite  → assets/models/best.tflite
#    - best.onnx    → android/app/src/main/assets/best.onnx

# 3. Install dependencies
flutter pub get

# 4. Jalankan di perangkat/emulator Android
flutter run

# 5. Build APK release
flutter build apk --release
```

> **Catatan:** Deteksi YOLO memerlukan perangkat Android fisik (native Kotlin). Emulator mungkin tidak mendukung inferensi model.

---

## Struktur Folder

```
lib/
├── main.dart
├── app.dart
├── constants/          # Konstanta global
├── core/
│   ├── database/       # SQLite (helper, DAO deteksi/karyawan/settings)
│   └── services/       # YOLO, PDF, image storage, settings
├── features/
│   ├── absensi/        # Layar absensi + tab grafik & personalia
│   ├── archive/        # Arsip deteksi
│   ├── employee/       # Riwayat karyawan
│   ├── home/           # Dashboard utama + widget
│   ├── rank/           # Ranking kepatuhan
│   ├── register/       # Registrasi karyawan
│   ├── scanner/        # Scanner, detail & hasil deteksi
│   ├── settings/       # Pengaturan aplikasi
│   ├── splash/         # Splash screen
│   └── train/          # Training/validasi model
├── models/             # DetectionModel, EmployeeModel
├── providers/          # Riverpod providers
├── theme/              # Warna, teks, tema global
└── widgets/            # Widget reusable (bottom nav, card, dll)

assets/
├── fonts/              # Poppins (400–900)
├── images/             # Logo & gambar statis
├── models/             # labels.txt (best.tflite diunduh dari Releases)
└── validasi/           # Data validasi model
```

---

## Tech Stack

- **Framework:** Flutter 3 + Dart ^3.5
- **State Management:** Riverpod (hooks_riverpod + riverpod_generator)
- **Database:** SQLite via `sqflite`
- **AI / Deteksi:** Ultralytics YOLO — native Kotlin via `MethodChannel`
- **Grafik:** fl_chart
- **PDF:** pdf + printing
- **Kamera:** camera + image_picker
- **Font:** Poppins (bundled)

---

## Requirements

- Flutter SDK ≥ 3.5
- Android SDK (target API 24+)
- Izin: Kamera, Penyimpanan

---

## Lisensi

Proyek ini bersifat privat (`publish_to: none`). Dibuat untuk keperluan akademik.
