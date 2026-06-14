"""
Export TFLite langsung dari best.onnx pakai onnx2tf (bypass ultralytics + tflite_support).
Jalankan setelah export_best.py berhasil buat best.onnx.
"""

from pathlib import Path
import tensorflow as tf

ONNX_PATH = Path("export_model/output/best.onnx")
EXPORT_DIR = Path("export_model/output")
SAVED_MODEL_DIR = EXPORT_DIR / "best_saved_model"


def onnx_to_tflite():
    import onnx2tf

    print(f"Input ONNX: {ONNX_PATH.resolve()}")
    print("Step 1: Convert ONNX -> SavedModel via onnx2tf...")

    onnx2tf.convert(
        input_onnx_file_path=str(ONNX_PATH),
        output_folder_path=str(SAVED_MODEL_DIR),
        non_verbose=True,
        # Disable NMS output adjustment agar shape sesuai YOLOv8
        disable_group_convolution=True,
    )
    print(f"SavedModel: {SAVED_MODEL_DIR}")

    print("Step 2: SavedModel -> TFLite FP32...")
    converter = tf.lite.TFLiteConverter.from_saved_model(str(SAVED_MODEL_DIR))
    tflite_fp32 = converter.convert()
    out_fp32 = EXPORT_DIR / "best_fp32.tflite"
    out_fp32.write_bytes(tflite_fp32)
    print(f"[OK] TFLite FP32: {out_fp32}  ({out_fp32.stat().st_size / 1024 / 1024:.1f} MB)")

    print("Step 3: SavedModel -> TFLite FP16 (lebih kecil)...")
    converter2 = tf.lite.TFLiteConverter.from_saved_model(str(SAVED_MODEL_DIR))
    converter2.optimizations = [tf.lite.Optimize.DEFAULT]
    converter2.target_spec.supported_types = [tf.float16]
    tflite_fp16 = converter2.convert()
    out_fp16 = EXPORT_DIR / "best_fp16.tflite"
    out_fp16.write_bytes(tflite_fp16)
    print(f"[OK] TFLite FP16: {out_fp16}  ({out_fp16.stat().st_size / 1024 / 1024:.1f} MB)")

    return out_fp32, out_fp16


if __name__ == "__main__":
    if not ONNX_PATH.exists():
        print(f"[ERR] {ONNX_PATH} tidak ada. Jalankan dulu: python export_model/export_best.py")
        exit(1)

    try:
        fp32, fp16 = onnx_to_tflite()
        print(f"\nDone! Output:")
        for f in sorted(EXPORT_DIR.iterdir()):
            if f.is_file():
                print(f"  {f.name}  ({f.stat().st_size / 1024 / 1024:.1f} MB)")
    except Exception as e:
        import traceback
        traceback.print_exc()
