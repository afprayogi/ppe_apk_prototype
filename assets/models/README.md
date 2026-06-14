# Model Placement

Taruh file model TFLite Anda di folder ini:

```
assets/models/
├── ppe_detector.tflite   ← File model utama (wajib)
└── labels.txt            ← Sudah ada, sesuaikan dengan label model Anda
```

## Format model yang didukung

- **YOLOv8** (direkomendasikan) — output shape `[1, num_anchors, 6+]`
- **SSD MobileNet** — output `[1, N, 4]` + `[1, N, classes]`

## Cara export model YOLOv8 ke TFLite

```bash
yolo export model=ppe_best.pt format=tflite imgsz=640
```

File `.tflite` hasil export letakkan di folder ini dengan nama `ppe_detector.tflite`.

## Jika format output model berbeda

Edit fungsi `_parseOutput()` di `lib/core/services/tflite_service.dart` 
sesuai dengan output tensor model Anda.
