# Contracts

These five contracts are the only coupling between the parts of the design. A module that meets its contract will integrate with the rest. A change to anything in this file goes through the lead as its own pull request.

| Contract | Governs | Written by | Used by |
| --- | --- | --- | --- |
| 1. Golden model | Every numerical result and every test vector | Model | Everyone |
| 2. Tensor layout | The three DDR images of a layer | Model, with the lead | Platform, Control |
| 3. Streams | Data from the DMA into `accel_top` and back | Control | Platform |
| 4. MXU interface | The ports between the array and the logic around it | MXU | Control |
| 5. Register map | What the driver writes and reads | Control | Platform |

## Conventions and limits

| Item | Definition |
| --- | --- |
| Array side | T = 8 in hardware, 4 in fast simulation. Everything below is written for 8. |
| Word | 64 bits = 8 bytes. Byte b is bits [8b+7 : 8b]. Byte 0 sits at the lowest DDR address. |
| Numbers | Two's complement, little-endian. Activations, weights and outputs are INT8. Sums are INT32. |
| Layer shape | C[M×N] = A[M×K] · W[K×N] + bias. M rows (batch or pixels), K inputs, N output channels. |
| Tiles | M_T = M / 8 and N_T = N / 8. |
| Limits | 1 ≤ K ≤ 1,024. M_T · K ≤ 8,192. M and N are multiples of 8. |
| Padding | Extra rows of A are zero. Extra channels have zero weights, zero bias, M0 = 0 and s = 1. |
| Index names | `mt`, `nt` and `k` are the tile and input indices. `j` is a row inside a tile, 0 to 7. `c` is a channel inside a tile, 0 to 7. |
| Clock and reset | One clock, `clk`. Synchronous active-high `rst` inside `accel_top`, derived from `aresetn`. |

Repository layout. Every block has its own folder.

```
rtl/mxu/<block>/       the array: pe, mxu; mxu_pkg.sv sits in rtl/mxu/
rtl/ctrl/<block>/      everything around the array
tb/common/<component>/ shared bench components; tb_pkg.sv sits in tb/common/
tb/mxu/<block>/        one bench per array block
tb/ctrl/<block>/       one bench per control block
model/<package>/       Python: golden model, packers, vector generator, training, export
vectors/               generated hex files, never hand-edited
sw/                    bare-metal driver and demo app
hw/                    Vivado block-design scripts and constraints
```

## Contract 1: the golden model

This function is the definition of a correct layer. Hardware, driver and testbenches are right exactly when they match it bit for bit. It lives in `model/golden/golden.py`.

```python
import numpy as np

def layer(A, W, bias, M0, s, z, lo, hi):
    # A: int8 [M,K]    W: int8 [K,N]    bias: int32 [N]
    # M0: uint16 [N]   s: int [N], 1..47
    # z, lo, hi: int8 scalars (output zero point, clamp bounds)
    acc = A.astype(np.int64) @ W.astype(np.int64) + bias     # must fit int32
    acc = np.clip(acc, -2**24, 2**24 - 1)                     # sat25
    r   = (acc * M0.astype(np.int64) + (1 << (s - 1))) >> s   # per channel, floor
    return np.clip(z + r, lo, hi).astype(np.int8)
```

- The shift is arithmetic and floors, so ties round toward plus infinity.
- The exporter must assert that every sum fits INT32. The hardware keeps the low 32 bits of a 48-bit sum and does not check.
- ReLU is `lo = z`. No activation is `lo = -128`, `hi = 127`.

The array alone is defined by one tile, with no requantization:

```python
def tile(a_words, w_words, bias8):
    # a_words: int8 [K,8], a_words[k,j] = activation for row j
    # w_words: int8 [K,8], w_words[k,c] = weight for channel c
    # bias8:   int32 [8]
    # returns  int32 [8,8], res[c,j] = bias8[c] + sum_k a_words[k,j] * w_words[k,c]
    res = w_words.astype(np.int64).T @ a_words.astype(np.int64) + bias8[:, None]
    return res.astype(np.int32)
```

## Contract 2: tensor layout in DDR

Each layer uses three images. An image is one contiguous array of 64-bit words, 64-byte aligned.

| Image | Length in words | Word index | What that word holds |
| --- | --- | --- | --- |
| `a_img`, activations | M_T · K | mt·K + k | byte j = A[8·mt + j, k] |
| `w_img`, parameters | N_T · (K + 8) | nt·(K + 8) + c | parameter word for channel 8·nt + c |
| `w_img`, weights | same image | nt·(K + 8) + 8 + k | byte c = W[k, 8·nt + c] |
| `o_img`, outputs | M_T · N | (nt·M_T + mt)·8 + c | byte j = y[8·mt + j, 8·nt + c] |

Parameter word:

| Bits | Field | Type |
| --- | --- | --- |
| 31:0 | bias | INT32 |
| 47:32 | M0, the requantization multiplier | unsigned 16-bit |
| 53:48 | s, the requantization shift | 1 to 47 |
| 63:54 | reserved | zero |

- Chaining layers: the next layer's K equals this layer's N, and `a_next[mt*N + 8*nt + c] = o_img[(nt*M_T + mt)*8 + c]`. Whole words move; no byte is touched.
- Worked example with M = 8, K = 2, N = 8. `a_img` has 2 words: word 0 is A[0..7, 0] and word 1 is A[0..7, 1]. `w_img` has 10 words: 8 parameter words, then W[0, 0..7] and W[1, 0..7]. `o_img` has 8 words: word c is y[0..7, c].

## Contract 3: streams

Both streams are AXI4-Stream, 64 bits wide: `tdata[63:0]`, `tvalid`, `tready`, `tlast`, and `tkeep = 8'hFF`. A word moves on a cycle where `tvalid` and `tready` are both high.

| Stream | Direction | Carries | Flow control |
| --- | --- | --- | --- |
| `s_axis` | DMA to `accel_top` | `a_img` when CTRL.DEST = 0, `w_img` when CTRL.DEST = 1 | DEST = 0: always ready; words land at a write pointer that CTRL.UB_WR_RST zeroes. DEST = 1: ready only after START, and low whenever the idle weight half is full. Input `tlast` is ignored. |
| `m_axis` | `accel_top` to DMA | `o_img`, in index order | `tlast` is high on the final word, index M_T·N − 1. `tvalid` holds until `tready`. |

Two rules for the driver: never send activations while STATUS.BUSY is set, and arm the DMA write channel before START.

## Contract 4: MXU interface

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `clk`, `rst` | in | 1 | Clock; synchronous active-high reset that zeroes every sum |
| `in_valid` | in | 1 | `a_word` and `w_word` are word k of the current tile |
| `a_word` | in | 64 | Byte j = activation for tile row j. Treated as zero when `in_valid` is low |
| `w_word` | in | 64 | Byte c = weight for channel c |
| `shift_en` | in | 1 | High for exactly 8 consecutive cycles. Drains the sums and loads the next bias |
| `bias_in` | in | 32 | On the c-th cycle of `shift_en`: bias for channel c of the next tile |
| `res_valid` | out | 1 | High for exactly 8 cycles per shift burst |
| `res_row` | out | 256 | On the c-th valid cycle, bits [32j+31 : 32j] = INT32 sum for row j, channel c |

Function: after a shift burst that loaded `bias8`, and K words with `in_valid`, the next shift burst returns exactly `tile(a_words, w_words, bias8)` from Contract 1, channel 0 first.

Timing rules:

1. The controller never raises `in_valid` during a shift burst.
2. The controller raises `shift_en` no earlier than FLUSH_LAT cycles after the last `in_valid`.
3. `in_valid` may resume on the cycle after `shift_en` falls.
4. The MXU starts its `res_valid` burst exactly SHIFT_LAT cycles after `shift_en` rises.
5. The MXU exports T, PIPE, FLUSH_LAT and SHIFT_LAT as constants in `mxu_pkg.sv`. The reference design has FLUSH_LAT = 17 and SHIFT_LAT = 0 at T = 8 with pipelining on.

One tile therefore takes at least K + FLUSH_LAT + 7 cycles: K + 24 in the reference design.

## Contract 5: register map

AXI4-Lite, 32-bit data. The base address comes from Vivado's address editor; software reads it from `xparameters.h`.

| Offset | Name | Access | Bits |
| --- | --- | --- | --- |
| 0x00 | CTRL | write | 0 START (self-clearing). 1 SOFT_RESET (self-clearing). 2 DEST: 0 sends `s_axis` to the unified buffer, 1 to the weight loader. 3 UB_WR_RST (self-clearing) |
| 0x04 | STATUS | read | 0 BUSY. 1 DONE, sticky, cleared by START. 2 ERROR. 15:8 FSM state for debug |
| 0x08 | M_TILES | read/write | 15:0 = M / 8 |
| 0x0C | K | read/write | 10:0 = K, 1 to 1,024 |
| 0x10 | N_TILES | read/write | 15:0 = N / 8 |
| 0x14 | QPARAM | read/write | 7:0 z. 15:8 lo. 23:16 hi. All INT8 |
| 0x18 | CAPS | read | 7:0 T. 15:8 log2 of unified-buffer words (13). 23:16 log2 of weight-half words (10). 24 PIPE. 31:28 version |
| 0x20 | CNT_CYCLES | read | Cycles with BUSY high |
| 0x24 | CNT_ACC | read | Cycles with `in_valid` high |
| 0x28 | CNT_SHIFT | read | Cycles with `shift_en` high |
| 0x2C | CNT_WAIT_WB | read | Cycles stalled waiting for a weight block |
| 0x30 | CNT_WAIT_OUT | read | Cycles stalled waiting for result-buffer or output space |
| 0x34 | CNT_TILES | read | Tiles completed |
| 0x38 | CNT_OUT_WORDS | read | Words sent on `m_axis` |

Counters are 32-bit and clear on START. ERROR is set by an illegal shape at START (K outside 1 to 1,024, or a tile count of 0) or by a unified-buffer address overflow during the run. MAC count is 64 × CNT_ACC; utilization is CNT_ACC / CNT_CYCLES.
