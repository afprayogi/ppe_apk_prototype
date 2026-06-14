"""
Export best.pt ke ONNX + TFLite menggunakan venv310 (ultralytics 8.4+).
Jalankan: export_model\venv310\Scripts\python.exe export_model\export_venv310.py
"""

from pathlib import Path

MODEL_PATH = Path("assets/models/best.pt")
OUTPUT_DIR = Path("export_model/output_v2")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

IMG_SIZE = 640


def export_onnx():
    from ultralytics import YOLO
    print("\n=== Export ONNX ===")
    model = YOLO(MODEL_PATH)
    model.export(format="onnx", imgsz=IMG_SIZE, simplify=True, opset=12, dynamic=False)
    src = Path(str(MODEL_PATH).replace(".pt", ".onnx"))
    dst = OUTPUT_DIR / "best.onnx"
    if src.exists():
        import shutil; shutil.copy2(src, dst)
    print(f"[OK] ONNX: {dst}")
    return dst


def export_tflite_fp32():
    from ultralytics import YOLO
    print("\n=== Export TFLite FP32 ===")
    model = YOLO(MODEL_PATH)
    model.export(format="tflite", imgsz=IMG_SIZE, half=False, int8=False)
    candidates = list(Path("assets/models").rglob("*float32*.tflite")) + \
                 list(Path("assets/models").rglob("best_saved_model/*.tflite"))
    if candidates:
        import shutil
        dst = OUTPUT_DIR / "best_fp32.tflite"
        shutil.copy2(candidates[0], dst)
        print(f"[OK] TFLite FP32: {dst}  ({dst.stat().st_size/1024/1024:.1f} MB)")
        return dst
    print("[WARN] TFLite fp32 file not found, check assets/models folder")


def export_tflite_fp16():
    from ultralytics import YOLO
    import tensorflow as tf
    print("\n=== Export TFLite FP16 dari SavedModel ===")
    saved = list(Path("assets/models").rglob("best_saved_model"))
    if not saved:
        print("SavedModel tidak ada, skip FP16")
        return
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved[0]))
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.target_spec.supported_types = [tf.float16]
    data = converter.convert()
    dst = OUTPUT_DIR / "best_fp16.tflite"
    dst.write_bytes(data)
    print(f"[OK] TFLite FP16: {dst}  ({dst.stat().st_size/1024/1024:.1f} MB)")
    return dst


if __name__ == "__main__":
    import ultralytics, tensorflow
    print(f"ultralytics: {ultralytics.__version__}  |  tensorflow: {tensorflow.__version__}")
    print(f"Model: {MODEL_PATH.resolve()}")

    export_onnx()
    export_tflite_fp32()
    export_tflite_fp16()

    print("\n=== Output files ===")
    for f in sorted(OUTPUT_DIR.iterdir()):
        if f.is_file():
            print(f"  {f.name}  ({f.stat().st_size/1024/1024:.1f} MB)")
