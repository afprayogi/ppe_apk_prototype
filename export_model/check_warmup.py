import numpy as np, tensorflow as tf

interp = tf.lite.Interpreter(model_path='assets/models/best.tflite')
interp.allocate_tensors()
inp = interp.get_input_details()[0]
out = interp.get_output_details()[0]

# Simulasi warmup Flutter: input semua 0.0
arr = np.zeros((1,640,640,3), dtype=np.float32)
interp.set_tensor(inp['index'], arr)
interp.invoke()
raw = interp.get_tensor(out['index'])[0]

print("=== WARMUP OUTPUT (input zeros) - rows non-zero ===")
print(f"{'i':>4}  {'col4':>8}  {'col5':>8}  col4isInt?  col5isProb?  swapVote?")
for i,r in enumerate(raw):
    col4,col5 = float(r[4]),float(r[5])
    if col4 < 0.01 and col5 < 0.01: continue
    c4int = abs(col4-round(col4))<0.01 and 0<=col4<6
    c5prob = 0.0<=col5<=1.0
    vote = c4int and c5prob
    print(f"{i:>4}  {col4:>8.4f}  {col5:>8.4f}  {str(c4int):>10}  {str(c5prob):>11}  {str(vote):>9}")
    if i > 20: print("..."); break
