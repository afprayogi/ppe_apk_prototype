"""
Export best.pt (YOLOv8) ke ONNX dan TFLite
Jalankan: python export_model/export_best.py
"""

from pathlib import Path
from ultralytics import YOLO

MODEL_PATH = Path("assets/models/best.pt")
EXPORT_DIR = Path("export_model/output")
EXPORT_DIR.mkdir(parents=True, exist_ok=True)

IMG_SIZE = 640  # ubah sesuai training (cek di best.pt metadata)


def export_onnx():
    print("\n=== Export ke ONNX ===")
    model = YOLO(MODEL_PATH)
    out = model.export(
        format="onnx",
        imgsz=IMG_SIZE,
        dynamic=False,        # static shape lebih cepat di mobile
        simplify=True,        # simplify graph onnx
        opset=12,             # opset 12 kompatibel luas
        half=False,           # FP16 - set True jika GPU support
    )
    onnx_src = Path(str(MODEL_PATH).replace(".pt", ".onnx"))
    onnx_dst = EXPORT_DIR / "best.onnx"
    if onnx_src.exists():
        onnx_src.rename(onnx_dst)
    print(f"ONNX saved: {onnx_dst}")
    return onnx_dst


def export_tflite():
    print("\n=== Export ke TFLite ===")
    model = YOLO(MODEL_PATH)
    # ultralytics export ke tflite: format="tflite"
    out = model.export(
        format="tflite",
        imgsz=IMG_SIZE,
        int8=False,           # set True untuk INT8 quantization (lebih kecil, sedikit loss akurasi)
        half=False,
    )
    # file tflite biasanya di folder saved_model
    tflite_candidates = list(Path(".").rglob("best_float32.tflite")) + \
                        list(Path(".").rglob("best*.tflite")) + \
                        list(Path("assets/models").rglob("*.tflite"))
    if tflite_candidates:
        tflite_src = tflite_candidates[0]
        tflite_dst = EXPORT_DIR / tflite_src.name
        import shutil
        shutil.copy2(tflite_src, tflite_dst)
        print(f"TFLite saved: {tflite_dst}")
        return tflite_dst
    print(f"TFLite output: {out}")
    return out


if __name__ == "__main__":
    print(f"Model: {MODEL_PATH.resolve()}")

    try:
        onnx_path = export_onnx()
        print(f"\n[OK] ONNX: {onnx_path}")
    except Exception as e:
        print(f"\n[FAIL] ONNX: {e}")

    try:
        tflite_path = export_tflite()
        print(f"\n[OK] TFLite: {tflite_path}")
    except Exception as e:
        print(f"\n[FAIL] TFLite: {e}")

    print("\nDone! Cek folder: export_model/output/")
