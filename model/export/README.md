# model/export

Turns the float MLP from `model/train` into what `layer()` takes for each of the three layers: W, bias, M0, s, z, lo, hi. Measures the golden-model accuracy and writes the report. NumPy only.

```
python -m model.export
```

Reads `build/mlp_float.npz`. Writes `model/export/mlp_int8.npz` (committed; `model/gen_vectors` builds the demo vector sets from it) and `docs/model_report.md`.

## The network

| Layer | M | K | N | Activation | `a_img` words | `w_img` words | `o_img` words |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 64 | 784 | 128 | ReLU | 6,272 | 12,672 | 1,024 |
| 2 | 64 | 128 | 64 | ReLU | 1,024 | 1,088 | 512 |
| 3 | 64 | 64 | 16, of which 10 are real | none | 512 | 144 | 128 |

64 images per run form A for layer 1. Each layer's output is the next layer's input.

## To implement

The functions in `export.py` and the tests in `test_export.py`. Write each float layer as `real_out = sum_k real_w · real_a + real_b`, with `real_a = s_a · (a − zp_a)`, `real_w[k, n] = s_w[n] · W[k, n]` and `real_out = s_o · (y − z)`. All of a, zp_a, y and z are signed INT8. Then:

```
bias[n]  = round(real_b[n] / (s_a * s_w[n])) - zp_a * sum_k W[k, n]
scale[n] = s_a * s_w[n] / s_o
s[n], M0[n]:  M0[n] = round(scale[n] * 2**s[n]),  chosen so 2**15 <= M0[n] < 2**16
z  = output zero point
lo = z for ReLU, otherwise -128
hi = 127
```

- Network input: raw pixel − 128, with s_a = 1/255 and zp_a = −128. Layer 2's s_a and zp_a are layer 1's s_o and z, and so on.
- Weights: per-channel symmetric in [−127, 127], `s_w[n] = max_k |w[k, n]| / 127`. The hardware accepts −128, but [−127, 127] keeps sums smaller.
- Output scale and zero point: from the float output range over `calib_x`, run with `float_forward`.
- If a scale is so small that s would pass 47, use s = 47 and accept a smaller M0. s is at least 1.
- Over the calibration set, assert every sum fits INT32, and warn if any reaches ±2^24, because sat25 clips it.
- Padded channels (layer 3, channels 10 to 15) get zero weights, zero bias, M0 = 0 and s = 1.
- If a tool gives unsigned 8-bit activations, subtract 128 from the values and from both zero points first.
- `golden_accuracy`: all 10,000 test images through `run_network` in batches of 64. Pad the last partial batch with zero rows and ignore them. Take the argmax over channels 0 to 9 only.
- `mlp_int8.npz` keys: `W1, bias1, M01, s1` and so on for layers 1 to 3, `z`, `lo`, `hi` as length-3 arrays, plus `batch_x` int8 [64, 784] and `batch_y` [64], the first 64 test images.
- Report: float accuracy and golden accuracy side by side over the 10,000 test images, and the largest |sum| seen per layer.

## Worked examples

```
choose_m0_s([0.0123])   -> M0 = [51590], s = [22]     51590 / 2**22 = 0.0123000145
choose_m0_s([0.5])      -> M0 = [32768], s = [16]
choose_m0_s([3e-12])    -> M0 = [422],   s = [47]     capped; M0 below 2**15

quantize_weights([[ 0.50, -0.02],
                  [-0.25,  0.01],
                  [ 0.10,  0.04]])
  -> W   = [[127, -64], [-64, 32], [25, 127]]
     s_w = [0.003937, 0.000315]                      (0.5 / 127, 0.04 / 127)

fold_bias(real_b = [0.1, -0.05], s_a = 1/255, s_w as above, zp_a = -128, W as above)
  -> [17741, -28321]                                 6477 + 128 * 88,  -40481 + 128 * 95

output_qparams(-1.0, 3.0) -> s_o = 4 / 255 = 0.015686, z = -64
```

Done when `docs/model_report.md` shows both accuracies and the largest sum per layer, `mlp_int8.npz` is committed, and `layer_demo1` to `layer_demo3` are regenerated from it.

Run the tests: `pytest model/export`.
