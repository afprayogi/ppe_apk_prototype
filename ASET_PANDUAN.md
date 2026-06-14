# 📁 Panduan Lokasi Aset VivatPass

---

## ❓ Kenapa bukan langsung best.pt?

File `.pt` adalah format checkpoint Python/PyTorch — membutuhkan Python runtime
untuk dibaca. Android tidak punya Python, sehingga **tidak bisa membaca `.pt` langsung**.

Solusinya: export ke **ONNX** (satu langkah, satu perintah, akurasi IDENTIK dengan `.pt`).

```
best.pt  ──(yolo export)──►  best.onnx  ──►  taruh di Android assets
   ↑                              ↑
format Python              format universal,
(tidak jalan di Android)   jalan di mana saja
```

---

## 🤖 Model AI — CARA PAKAI best.pt

### Langkah 1: Export dari Python (sekali saja)

```bash
# Di komputer Anda yang punya best.pt:
pip install ultralytics

yolo export model=best.pt format=onnx imgsz=640 opset=12
```

Hasil: **`best.onnx`** (di folder yang sama dengan best.pt)

### Langkah 2: Taruh file model

```
android/app/src/main/assets/
└── best.onnx     ← taruh di sini (buat folder jika belum ada)
```

### Langkah 3: Jalankan app

```bash
flutter run
```

Selesai! Tidak ada langkah lain. ONNX Runtime di Android membaca `best.onnx`
dengan preprocessing yang identik dengan Python Ultralytics.

---

## 🖼️ Gambar & Logo

### Logo Splash Screen
```
assets/images/
└── logo.png          ← ganti file ini untuk ubah logo
                         ukuran: 512×512 px, PNG transparan
```

Untuk menampilkan di splash, edit `lib/features/splash/splash_screen.dart`:
```dart
// Cari blok "Barcode lines" dan ganti seluruh Container-nya dengan:
Image.asset('assets/images/logo.png', width: 180.w)
```

### Gambar Mascot di Home Header
```
assets/images/
└── worker.png        ← gambar pekerja berseragam APD (opsional)
                         ukuran: 200×200 px
```

Edit `lib/features/home/widgets/home_header_card.dart`:
```dart
// Cari Icon(Icons.engineering ...) dan ganti dengan:
Image.asset('assets/images/worker.png', fit: BoxFit.contain)
```

### App Icon (ikon di launcher Android)
```
android/app/src/main/res/
├── mipmap-hdpi/ic_launcher.png     (72×72 px)
├── mipmap-mdpi/ic_launcher.png     (48×48 px)
├── mipmap-xhdpi/ic_launcher.png    (96×96 px)
├── mipmap-xxhdpi/ic_launcher.png   (144×144 px)
└── mipmap-xxxhdpi/ic_launcher.png  (192×192 px)
```

> Cara mudah generate semua ukuran sekaligus:
> Upload logo ke https://www.appicon.co/ → download → replace semua file di atas

---

## 📂 Peta Lengkap Aset

```
vivatpass/
├── assets/
│   ├── images/
│   │   ├── logo.png          ← GANTI → logo splash screen
│   │   └── worker.png        ← GANTI → mascot di home (opsional)
│   └── models/
│       └── labels.txt        ← label class (sudah ada, sesuaikan jika perlu)
│
└── android/app/src/main/
    ├── assets/
    │   └── best.onnx         ← TARUH model AI di sini (hasil export dari best.pt)
    └── res/
        └── mipmap-*/
            └── ic_launcher.png  ← GANTI → app icon Android
```

---

## 🏷️ Sesuaikan Label Class

Jika model Anda punya class berbeda, edit baris `LABELS` di:
```
android/app/src/main/kotlin/com/example/vivatpass/YoloDetector.kt
```

```kotlin
val LABELS = arrayOf(
    "person",
    "PPE_Helmet",
    "PPE_Vest",
    // ... sesuaikan dengan class model Anda
)
```

Urutan harus persis sama dengan saat training.
