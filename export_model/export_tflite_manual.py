"""
Export TFLite manual dari SavedModel yang sudah dibuat ultralytics.
Bypass tflite_support dengan TF Lite Converter langsung.
"""

import os
import shutil
from pathlib import Path
import numpy as np

MODEL_PT = Path("assets/models/best.pt")
EXPORT_DIR = Path("export_model/output")
EXPORT_DIR.mkdir(parents=True, exist_ok=True)


def export_saved_model_then_tflite():
    """Export PT -> SavedModel -> TFLite tanpa tflite_support"""
    from ultralytics import YOLO
    import tensorflow as tf

    print("Step 1: Export ke TensorFlow SavedModel...")
    model = YOLO(MODEL_PT)
    # export ke saved_model dulu
    model.export(format="saved_model", imgsz=640, half=False)

    # cari folder saved_model
    saved_model_dirs = list(Path("assets/models").rglob("saved_model"))
    if not saved_model_dirs:
        saved_model_dirs = list(Path(".").rglob("best_saved_model"))
    if not saved_model_dirs:
        raise FileNotFoundError("saved_model folder tidak ditemukan")

    saved_model_dir = saved_model_dirs[0]
    print(f"SavedModel: {saved_model_dir}")

    print("Step 2: Konversi SavedModel -> TFLite FP32...")
    converter = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_dir))
    converter.optimizations = []
    tflite_model = converter.convert()

    out_fp32 = EXPORT_DIR / "best_fp32.tflite"
    out_fp32.write_bytes(tflite_model)
    print(f"[OK] TFLite FP32: {out_fp32} ({out_fp32.stat().st_size / 1024 / 1024:.1f} MB)")

    print("Step 3: Konversi SavedModel -> TFLite FP16...")
    converter2 = tf.lite.TFLiteConverter.from_saved_model(str(saved_model_dir))
    converter2.optimizations = [tf.lite.Optimize.DEFAULT]
    converter2.target_spec.supported_types = [tf.float16]
    tflite_fp16 = converter2.convert()

    out_fp16 = EXPORT_DIR / "best_fp16.tflite"
    out_fp16.write_bytes(tflite_fp16)
    print(f"[OK] TFLite FP16: {out_fp16} ({out_fp16.stat().st_size / 1024 / 1024:.1f} MB)")

    return out_fp32, out_fp16


if __name__ == "__main__":
    try:
        fp32, fp16 = export_saved_model_then_tflite()
        print(f"\nDone! Output di: {EXPORT_DIR.resolve()}")
        for f in EXPORT_DIR.iterdir():
            print(f"  {f.name}  ({f.stat().st_size / 1024 / 1024:.1f} MB)")
    except Exception as e:
        import traceback
        print(f"\n[FAIL] {e}")
        traceback.print_exc()
