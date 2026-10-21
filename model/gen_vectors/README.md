# model/gen_vectors

Writes every test-vector set under `vectors/`, plus `sw/demo/data/reorder_test.h`, from the golden model. Every bench that reads vectors depends on these files.

```
python -m model.gen_vectors
```

## To implement

The functions in `gen_vectors.py` and the tests in `test_gen_vectors.py`. Expected values always come from `model.golden`, never from a second formula. Use one fixed seed in `main()` so a rerun gives identical files.

## File format

Plain text for `$readmemh`: one value per line, upper-case hex, most significant digit first, no prefix. Mask negative numbers to the field width: `to_hex(-1, 8)` is `FFFFFFFF`, `to_hex(-128, 2)` is `80`.

| File | Lines | Each line |
| --- | --- | --- |
| `tile_<name>_a.hex` | K | Activation word k, 16 digits: byte j = a_words[k, j] |
| `tile_<name>_w.hex` | K | Weight word k, 16 digits: byte c = w_words[k, c] |
| `tile_<name>_bias.hex` | 8 | INT32 bias for channel c, 8 digits |
| `tile_<name>_res.hex` | 8 | `tile()` result row c, 64 digits, lane j = res[c, j] in bits [32j+31 : 32j] |
| `epi_<name>_in.hex` | any | One entry, 70 digits: `{1'b0, last, s[5:0], M0[15:0], row[255:0]}`, sum j in row bits [32j+31 : 32j] |
| `epi_<name>_out.hex` | same | Expected output word, 16 digits: byte j = y for sum j |
| `epi_<name>_cfg.hex` | 3 | z, lo, hi, 2 digits each |
| `layer_<name>_a.hex`, `_w.hex`, `_o.hex` | image length | One image word, 16 digits, from `model.pack` |
| `layer_<name>_cfg.hex` | 6 | M_TILES, K, N_TILES, z, lo, hi, 8 digits each (z, lo, hi masked to 32 bits) |

An epi entry's value is `(last << 278) | (s << 272) | (M0 << 256) | row`, where `row = sum((sum_j & 0xFFFFFFFF) << 32*j)`.

The expected epi word must come from `layer()` itself. One entry is a 1 × 8 layer with zero activations, where the 8 sums enter as the bias: `layer(np.zeros((1, 1), np.int8), np.zeros((1, 8), np.int8), row, np.full(8, M0, np.uint16), np.full(8, s, np.int64), z, lo, hi)[0]`.

## Sets to write

| Set | Contents |
| --- | --- |
| `tile_k1`, `tile_k2`, `tile_k9`, `tile_k300` | Random full-range INT8 including −128, random INT32 bias |
| `tile_corner` | Every operand −128, K = 300 |
| `epi_corners` | Sums at and beyond ±2^24, s = 1 and 47, M0 = 0 and 65,535, exact rounding ties, results clamped on both sides |
| `epi_random` | 1,000 random entries |
| `layer_single` | M = 8, K = 9, N = 8 |
| `layer_mid` | M = 16, K = 64, N = 16 |
| `layer_demo1` | M = 64, K = 784, N = 128. Random until `model/export/mlp_int8.npz` exists; then from the trained model |
| `layer_demo2`, `layer_demo3` | From the trained model, once it exists: 64 × 128 × 64 and 64 × 64 × 16 |
| `layer_rand_00` to `layer_rand_49` | M_T and N_T from 1 to 4, K from 1 to 64 |
| `sw/demo/data/reorder_test.h` | One `o_img` and its `reorder()` as `static const uint64_t` arrays |

Random layers: s from 1 to 47, M0 any 16-bit value, ReLU or no activation at random, and every sum must fit INT32. Choose the shift so outputs land inside [−128, 127] most of the time, or every output clamps and the vectors check little.

## Worked example

A tile with K = 1, a_words = [[1, 2, 3, 4, 5, 6, 7, 8]], w_words = [[1, −1, 0, 0, 0, 0, 0, 2]] and bias8 = [0, 10, 0, 0, 0, 0, 0, −1]:

```
_a.hex     0807060504030201
_w.hex     020000000000FF01
_bias.hex  00000000  0000000A  00000000  00000000  00000000  00000000  00000000  FFFFFFFF   (8 lines)
_res.hex   line 0: 0000000800000007000000060000000500000004000000030000000200000001
           line 1: 0000000200000003000000040000000500000006000000070000000800000009
           lines 2 to 6: 64 zeros
           line 7: 0000000F0000000D0000000B0000000900000007000000050000000300000001
```

Line 1 is channel 1: 10 − a[j] for j = 0 to 7, lane 0 in the lowest digits.

One epi entry with row = [100, −100, 2^24, −2^24 − 5, 0, 1, −1, 3], M0 = 0x8000, s = 16, last = 1 and cfg z = 0, lo = −128, hi = 127:

```
_in.hex    50800000000003FFFFFFFF0000000100000000FEFFFFFB01000000FFFFFF9C00000064
_out.hex   02000100807FCE32
_cfg.hex   00  80  7F   (3 lines)
```

The outputs are [50, −50, 127, −128, 0, 1, 0, 2]. M0 / 2^16 is 0.5, so the value 1 scales to 0.5 and rounds up to 1, −1 scales to −0.5 and rounds up to 0, and 3 scales to 1.5 and rounds to 2. Sums j = 2 and 3 saturate at ±2^24 first, then clamp.

## Tests

Listed in `test_gen_vectors.py`. Run: `pytest model/gen_vectors`.
