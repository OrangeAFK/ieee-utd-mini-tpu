# model/pack

Converts between NumPy tensors and the three 64-bit DDR images of Contract 2 (`docs/contracts.md`). Every other tool reads and writes images through these four functions.

```python
from model.pack import pack_acts, pack_weights, unpack_out, reorder
```

## To implement

All four functions in `pack.py`, and the three tests in `test_pack.py`. Assert `sys.byteorder == 'little'` once at import, since the packers view int8 arrays as uint64.

| Function | In | Out | Rule |
| --- | --- | --- | --- |
| `pack_acts(A)` | int8 [M, K], M a multiple of 8 | uint64 [M_T·K] | word mt·K + k, byte j = A[8·mt + j, k] |
| `pack_weights(W, bias, M0, s)` | int8 [K, N], int32 [N], uint16 [N], int [N] | uint64 [N_T·(K + 8)] | per nt: 8 parameter words, then K weight words |
| `unpack_out(o_img, M, N)` | uint64 [M_T·N] | int8 [M, N] | word (nt·M_T + mt)·8 + c, byte j = y[8·mt + j, 8·nt + c] |
| `reorder(o_img, m_tiles, n_tiles)` | uint64 [M_T·N] | uint64 [M_T·N] | `a_next[mt*N + 8*nt + c] = o_img[(nt*M_T + mt)*8 + c]`, N = 8·n_tiles |

- Byte b of a word is bits [8b+7 : 8b]. Byte 0 is the lowest address.
- Parameter word for channel n = 8·nt + c, at index nt·(K + 8) + c: `(bias & 0xFFFFFFFF) | (M0 << 32) | (s << 48)`. Bits 63:54 are zero.
- Weight word k of block nt, at index nt·(K + 8) + 8 + k: byte c = W[k, 8·nt + c].
- `reorder` moves whole words and touches no byte. It is the same rule as the driver's `tpu_reorder`.

## Worked example

M = 8, K = 2, N = 8, with A[j, k] = 16·j + k, W[0, c] = c + 1, W[1, c] = −(c + 1), bias = [−1, 0, 1, 2, 3, 4, 5, 6], M0 = 0x8000 and s = 20 for every channel, and y[j, c] = 8·j + c.

```
pack_acts(A)       = [0x7060504030201000, 0x7161514131211101]
pack_weights(...)  = [0x00148000FFFFFFFF, 0x0014800000000000, 0x0014800000000001,
                      0x0014800000000002, 0x0014800000000003, 0x0014800000000004,
                      0x0014800000000005, 0x0014800000000006,
                      0x0807060504030201, 0xF8F9FAFBFCFDFEFF]
o_img for y        = [0x3830282018100800, 0x3931292119110901, 0x3A322A221A120A02,
                      0x3B332B231B130B03, 0x3C342C241C140C04, 0x3D352D251D150D05,
                      0x3E362E261E160E06, 0x3F372F271F170F07]
unpack_out(o_img, 8, 8) == y
```

Word 0 of `a_img` is column k = 0 of A, row 0 in the low byte. Word c of `o_img` is channel c for rows 0 to 7.

## Tests

- `test_round_trip_all_images`: random shapes; pack then unpack gives back A, W, bias, M0, s and y.
- `test_chaining_rule`: for a random layer, `reorder(o_img)` equals `pack_acts(unpack_out(o_img))`.
- `test_contract2_worked_example`: the words above, exactly.

Run: `pytest model/pack`.
