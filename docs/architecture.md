# Architecture

The whole machine in one place: what every block is for, every port, how the blocks connect, and what happens on which cycle. Where this file and `docs/contracts.md` disagree, the contracts win.

## 1. System

A C program on the Cortex-A9 puts three images in DDR. A stock AXI DMA streams them through one custom block, `accel_top`, which holds the 8×8 multiplier array.

Control: the driver writes registers through the PS's GP0 port. Data: activations and weights arrive on `s_axis`, results leave on `m_axis`, and the DMA moves both between the streams and DDR through the HP0 port.

```
              GP0 (AXI4-Lite)                       HP0 (AXI3, 64-bit)
 Cortex-A9 ---------------------> control xbar      DDR3L <------ data xbar <---- DMA memory masters
 driver                           |        |
                                  v        v
                              DMA regs   accel_top.s_axi
          DMA MM2S ---- s_axis ----> accel_top ---- m_axis ----> DMA S2MM
```

| Block | Kind | Role | Hard resources | Built by |
| --- | --- | --- | --- | --- |
| Driver | Bare-metal C | Places images in DDR, writes registers, starts DMA transfers, reads results and counters | CPU | Platform |
| ZYNQ7 PS | Hard block | Cortex-A9, DDR3L controller, the GP0 master port, the HP0 slave port, the clock FCLK_CLK0 | Hard | Platform |
| AXI Interconnect, control | Xilinx IP | Fans GP0 out to the DMA's register port and to `regfile` | LUTs | Platform |
| AXI DMA | Xilinx IP | Reads a DDR range out as a 64-bit stream; writes a 64-bit stream into a DDR range | LUTs | Platform |
| AXI Interconnect, data | Xilinx IP | Merges the DMA's two memory masters into HP0 and converts AXI4 to AXI3 | LUTs | Platform |
| Processor System Reset | Xilinx IP | Makes a synchronous `aresetn` for every block | LUTs | Platform |
| `accel_top` | RTL | Wrapper. Holds the reset register, the stream demux and the bias mux; wires the blocks below together | None | Control |
| `regfile` | RTL | AXI4-Lite registers, the START pulse, the status bits, seven counters | None | Control |
| `ub` | RTL | Unified buffer. Holds `a_img` for the whole layer; one 64-bit read per cycle | 16 BRAM36 | Control |
| `wload` | RTL | Parses `w_img` into parameter sets and weight words; owns the ping-pong state | None | Control |
| `wb_pair` | RTL | Two weight memories. The array reads one while the loader fills the other | 4 BRAM36 | Control |
| `layer_fsm` | RTL | Sequences every tile: read addresses, `in_valid`, `shift_en`, `swap` | None | Control |
| `mxu` | RTL | The 8×8 array and its two skew networks | 64 DSP48E1 | MXU |
| `pe` | RTL | One multiply-accumulate cell; 64 instances inside `mxu` | 1 DSP48E1 each | MXU |
| `res_buf` | RTL | Buffers rows of sums, each with its channel's scale | LUT RAM | Control |
| `epilogue` | RTL | Requantizes INT32 sums to INT8 and packs output words | 2 DSP48E1 | Control |
| `out_fifo` | RTL | Decouples the epilogue from the DMA; drives `m_axis` | 1 BRAM36 | Control |

## 2. Module hierarchy

```
accel_top
├── regfile
├── ub
├── wload
├── wb_pair
├── layer_fsm
├── mxu
│   └── pe × 64
├── res_buf
├── epilogue
└── out_fifo
```

The skew networks and the two epilogue lanes are generate blocks inside their parents, not separate files. The stream demux and the bias mux are a few lines inside `accel_top`.

| Module | File | Instances | Parameters |
| --- | --- | --- | --- |
| `accel_top` | `rtl/ctrl/accel_top/accel_top.sv` | 1 | None |
| `regfile` | `rtl/ctrl/regfile/regfile.sv` | 1 | None |
| `ub` | `rtl/ctrl/ub/ub.sv` | 1 | AW = 13 |
| `wload` | `rtl/ctrl/wload/wload.sv` | 1 | AW = 10 |
| `wb_pair` | `rtl/ctrl/wb_pair/wb_pair.sv` | 1 | AW = 10 |
| `layer_fsm` | `rtl/ctrl/layer_fsm/layer_fsm.sv` | 1 | RD_LAT = 2; FLUSH_LAT and SHIFT_LAT from `mxu_pkg` |
| `mxu` | `rtl/mxu/mxu/mxu.sv` | 1 | T = 8, PIPE = 1 |
| `pe` | `rtl/mxu/pe/pe.sv` | 64 | PIPE |
| `mxu_pkg` | `rtl/mxu/mxu_pkg.sv` | Package | T, PIPE, FLUSH_LAT, SHIFT_LAT |
| `res_buf` | `rtl/ctrl/res_buf/res_buf.sv` | 1 | DEPTH = 16 |
| `epilogue` | `rtl/ctrl/epilogue/epilogue.sv` | 1 | None |
| `out_fifo` | `rtl/ctrl/out_fifo/out_fifo.sv` | 1 | DEPTH = 512 |

## 3. Conventions and constants

| Symbol | Value | Meaning |
| --- | --- | --- |
| T | 8 | Side of the array. 4 in fast simulation |
| PIPE | 1 | 1: operands pass PE to PE through registers, with skewed inputs. 0: operands broadcast |
| RD_LAT | 2 | Cycles from a read address to data, for `ub` and `wb_pair` alike |
| FLUSH_LAT | 17 | Cycles after the last `in_valid` before `shift_en` may rise. 2·(T − 1)·PIPE + 3 |
| SHIFT_LAT | 0 | Cycles from `shift_en` rising to the first `res_valid` |
| Word | 64 bits | 8 bytes. Byte b is bits [8b+7 : 8b]. Byte 0 is the lowest DDR address |
| M, K, N | Per layer | Rows of A, inputs, output channels. C[M×N] = A[M×K] · W[K×N] + bias |
| M_T, N_T | M / 8, N / 8 | Tile counts. M and N are padded to multiples of 8 |
| `mt`, `nt`, `k` | Counters | Tile row index, tile channel index, input index |
| `j`, `c` | 0 to 7 | Row inside a tile; channel inside a tile |
| Limits |  | 1 ≤ K ≤ 1,024 and M_T · K ≤ 8,192 |

- **Clock.** One clock, `clk`, which is FCLK_CLK0 from the PS: 100 MHz for bring-up, 125 MHz at the end. Every flip-flop in the design uses it.
- **Reset.** `accel_top` registers `rst = ~aresetn | soft_reset` and feeds it, synchronous and active-high, to every block except `regfile`. `regfile` resets on `aresetn` only, so a soft reset does not wipe the configuration.
- **Numbers.** Two's complement, little-endian. Activations, weights and outputs are INT8; sums are INT32 on every interface and 48 bits inside the DSPs.
- **Handshakes.** Streams use valid and ready: a word moves on a cycle where both are high. Everything else is a plain level or a one-cycle pulse, as each port table says.
- **No multipliers outside the array and the epilogue.** All 66 DSPs are spoken for. Addresses are built with counters and adders, never with a product.
- **Per-channel buses.** `cur_bias`, `nxt_bias`, `cur_m0` and `cur_sh` are packed arrays `logic [7:0][W-1:0]`; element `[c]` belongs to channel c.

## 4. Data formats

The machine moves three kinds of image, all made of 64-bit words, and keeps one wider entry internally.

| Image | Direction | Length in words | Order |
| --- | --- | --- | --- |
| `a_img` | DDR to `ub`, once per layer | M_T · K | For each `mt`: words k = 0 to K − 1 |
| `w_img` | DDR to `wload`, paced through the layer | N_T · (K + 8) | For each `nt`: 8 parameter words, then K weight words |
| `o_img` | `out_fifo` to DDR | M_T · N | For each `nt`, for each `mt`: 8 words, channel c = 0 to 7 |

```
a_img word   [63:56] A[8mt+7,k] ... [15:8] A[8mt+1,k]  [7:0] A[8mt+0,k]
w_img param  [63:54] 0   [53:48] s   [47:32] M0   [31:0] bias            (channel 8nt+c)
w_img weight [63:56] W[k,8nt+7] ... [7:0] W[k,8nt+0]
o_img word   [63:56] y[8mt+7,8nt+c] ... [7:0] y[8mt+0,8nt+c]
res_buf entry (279 bits) {last, sh[5:0], m0[15:0], row[255:0]}, row lane j = bits [32j+31:32j]
```

- A layer's output becomes the next layer's input by moving whole words: `a_next[mt*N + 8*nt + c] = o_img[(nt*M_T + mt)*8 + c]`.
- Sums are 48 bits inside each DSP. The low 32 bits leave on `res_row`; the exporter guarantees they fit.
- Padded rows of A are zero. Padded channels have zero weights, zero bias, M0 = 0 and s = 1.

## 5. Inside accel_top

`accel_top` has no behaviour of its own beyond a reset register and two small muxes. The rest is wiring. This table is the complete list of nets between blocks.

| Net | Width | Driven by | Read by | Meaning |
| --- | --- | --- | --- | --- |
| `rst` | 1 | `accel_top` | All but `regfile` | Registered `~aresetn \| soft_reset` |
| `start` | 1 | `regfile` | `layer_fsm`, `wload` | One-cycle pulse on a legal START write |
| `soft_reset` | 1 | `regfile` | `accel_top` | One-cycle pulse |
| `dest` | 1 | `regfile` | demux | 0: stream to `ub`. 1: stream to `wload` |
| `ub_wr_rst` | 1 | `regfile` | `ub` | Pulse; zeroes the write pointer |
| `m_tiles`, `k`, `n_tiles` | 16, 11, 16 | `regfile` | `layer_fsm`, `wload` | Layer shape, held stable while BUSY |
| `qz`, `qlo`, `qhi` | 8 each | `regfile` | `epilogue` | Output zero point and clamp bounds |
| `ub_wr_valid` | 1 | demux | `ub` | `s_axis_tvalid & ~dest` |
| `wl_valid` | 1 | demux | `wload` | `s_axis_tvalid & dest` |
| `wl_ready` | 1 | `wload` | demux | Loader can take a word |
| `s_axis_tready` | 1 | demux | DMA | `dest ? wl_ready : 1` |
| `ub_rd_addr` | 13 | `layer_fsm` | `ub` | `ub_base + k` |
| `a_word` | 64 | `ub` | `mxu` | Activation word, RD_LAT after its address |
| `wb_rd_addr` | 10 | `layer_fsm` | `wb_pair` | `k` |
| `w_word` | 64 | `wb_pair` | `mxu` | Weight word, RD_LAT after its address |
| `wb_we`, `wb_waddr`, `wb_wdata` | 1, 10, 64 | `wload` | `wb_pair` | Write into the idle half |
| `active` | 1 | `wload` | `wb_pair` | Half the array reads; writes go to the other |
| `swap` | 1 | `layer_fsm` | `wload` | Pulse; flips `active`, clears `nxt_valid` |
| `nxt_valid` | 1 | `wload` | `layer_fsm` | Idle half and NEXT parameters hold a full block |
| `cur_bias`, `nxt_bias` | 8 × 32 each | `wload` | bias mux | Biases of the CURRENT and NEXT blocks |
| `cur_m0`, `cur_sh` | 8 × 16, 8 × 6 | `wload` | `res_buf` | Scales of the CURRENT block |
| `bias_sel`, `shift_idx` | 2, 3 | `layer_fsm` | bias mux | Source and channel c. `bias_sel`: 0 CURRENT, 1 NEXT, 2 or 3 zero |
| `bias_in` | 32 | bias mux | `mxu` | Bias for channel c of the next tile |
| `in_valid` | 1 | `layer_fsm` | `mxu`, `regfile` | Words are valid; also counts CNT_ACC |
| `shift_en` | 1 | `layer_fsm` | `mxu`, `regfile` | 8-cycle drain; also counts CNT_SHIFT |
| `res_valid`, `res_row` | 1, 256 | `mxu` | `res_buf` | One row of sums per cycle, channel 0 first |
| `rb_discard` | 1 | `layer_fsm` | `res_buf` | High for the preload burst; rows are dropped |
| `rb_last` | 1 | `layer_fsm` | `res_buf` | High for the final tile's burst |
| `can_take_tile` | 1 | `res_buf` | `layer_fsm` | At least 8 entries free |
| `rb_valid`, `rb_row`, `rb_m0`, `rb_sh`, `rb_last_o` | 1, 256, 16, 6, 1 | `res_buf` | `epilogue` | Head entry |
| `rb_pop` | 1 | `epilogue` | `res_buf` | Head entry consumed |
| `ep_valid`, `ep_word`, `ep_last` | 1, 64, 1 | `epilogue` | `out_fifo` | One packed output word |
| `of_ready` | 1 | `out_fifo` | `epilogue` | FIFO not full |
| `last_sent` | 1 | `out_fifo` | `layer_fsm` | The `tlast` word was accepted by the DMA |
| `busy`, `done_set`, `err_set`, `fsm_state` | 1, 1, 1, 8 | `layer_fsm` | `regfile` | Status |
| `ev_wait_wb`, `ev_wait_out`, `ev_tile` | 1 each | `layer_fsm` | `regfile` | Counter enables |
| `ev_out_word` | 1 | `out_fifo` | `regfile` | A word left on `m_axis` |

## 6. Block reference

One entry per RTL block, in the order data meets them. Port directions are from the block's own point of view. `clk` and `rst` are left out of the tables; every block has both, except `regfile`, which has `aresetn` in place of `rst`.

### 6.1 accel_top

The only custom block in the Vivado design. It exposes one register port and two streams, and wires the nine blocks inside it together.

| Port | Dir | Width | Connects to | Meaning |
| --- | --- | --- | --- | --- |
| `clk` | in | 1 | FCLK_CLK0 | The one clock |
| `aresetn` | in | 1 | Processor System Reset | Active-low reset, synchronous to `clk` |
| `s_axi_aw*`, `s_axi_w*`, `s_axi_b*` | in/out | 8-bit address, 32-bit data | Control interconnect | AXI4-Lite write channels |
| `s_axi_ar*`, `s_axi_r*` | in/out | 8-bit address, 32-bit data | Control interconnect | AXI4-Lite read channels |
| `s_axis_tdata` | in | 64 | DMA, MM2S | Activation or weight-stream word |
| `s_axis_tvalid`, `s_axis_tready` | in, out | 1, 1 | DMA, MM2S | Handshake |
| `s_axis_tlast`, `s_axis_tkeep` | in | 1, 8 | DMA, MM2S | Ignored |
| `m_axis_tdata` | out | 64 | DMA, S2MM | Output word |
| `m_axis_tvalid`, `m_axis_tready` | out, in | 1, 1 | DMA, S2MM | Handshake |
| `m_axis_tlast`, `m_axis_tkeep` | out | 1, 8 | DMA, S2MM | `tlast` on the layer's final word; `tkeep` is always 0xFF |

The AXI4-Lite port has `awaddr[7:0]`, `awvalid`, `awready`, `wdata[31:0]`, `wstrb[3:0]`, `wvalid`, `wready`, `bresp[1:0]`, `bvalid`, `bready`, `araddr[7:0]`, `arvalid`, `arready`, `rdata[31:0]`, `rresp[1:0]`, `rvalid`, `rready`, all prefixed `s_axi_`.

Logic it contains itself:

- Reset register: `rst <= ~aresetn | soft_reset`.
- Stream demux: `ub_wr_valid = s_axis_tvalid & ~dest`, `wl_valid = s_axis_tvalid & dest`, `s_axis_tready = dest ? wl_ready : 1`.
- Bias mux: `bias_in` is `cur_bias[shift_idx]`, `nxt_bias[shift_idx]` or zero, chosen by `bias_sel`.

### 6.2 regfile

The software's only window into the accelerator. It holds the layer configuration, turns a START write into a pulse, reports status, and counts events.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `aresetn` | in | 1 | Its only reset; `rst` does not reach it |
| `s_axi_*` | in/out | AXI4-Lite | Single-beat reads and writes, always OKAY |
| `start` | out | 1 | Pulse when CTRL.START is written, BUSY is low and the shape is legal |
| `soft_reset` | out | 1 | Pulse when CTRL.SOFT_RESET is written |
| `dest` | out | 1 | Level, CTRL.DEST |
| `ub_wr_rst` | out | 1 | Pulse when CTRL.UB_WR_RST is written |
| `m_tiles`, `k`, `n_tiles` | out | 16, 11, 16 | Layer shape registers |
| `qz`, `qlo`, `qhi` | out | 8 each | QPARAM fields |
| `busy`, `fsm_state` | in | 1, 8 | Shown in STATUS |
| `done_set`, `err_set` | in | 1, 1 | Pulses that set STATUS.DONE and STATUS.ERROR |
| `in_valid`, `shift_en` | in | 1, 1 | Count CNT_ACC and CNT_SHIFT |
| `ev_wait_wb`, `ev_wait_out`, `ev_tile`, `ev_out_word` | in | 1 each | Count the other four event counters |

State: the registers of Contract 5, the sticky DONE and ERROR bits, and seven 32-bit counters.

- A START write is refused, and ERROR is set, if K is 0, K is above 1,024, or M_TILES or N_TILES is 0. It does not check M_TILES · K, because that needs a multiplier; the FSM flags an overflow at run time and the driver checks the product first.
- A START write while `busy` is high is ignored: no pulse, no change to ERROR.
- A legal START clears DONE, ERROR and every counter.
- CNT_CYCLES counts every cycle with `busy` high. Each other counter adds one per cycle its enable is high.
- CAPS is constant: T and PIPE from `mxu_pkg`, 13, 10, and version 1.
- Every register resets to zero. CTRL reads as zero. Unused offsets read as zero and ignore writes. `wstrb` is ignored; every write is a full word.

### 6.3 ub, the unified buffer

Holds the whole activation image for the layer and returns one 64-bit word per cycle to the array.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `wr_rst` | in | 1 | Zero the write pointer |
| `wr_valid` | in | 1 | Store `wr_data` at the write pointer, then add one |
| `wr_data` | in | 64 | `s_axis_tdata` |
| `rd_addr` | in | 13 | Word address |
| `rd_data` | out | 64 | `a_word`. Valid RD_LAT = 2 cycles after `rd_addr` |

State: a memory of 8,192 × 64 bits and a 14-bit write pointer.

Writes arrive only before START, in `a_img` order, so word mt·K + k lands at address mt·K + k. Reads arrive only while BUSY. The two never overlap, so no read-during-write case exists.

Infer a simple dual-port RAM with a registered read and an output register. Vivado should report 16 RAMB36E1.

### 6.4 wload, the weight loader

Reads the weight stream. For each block it stores 8 parameter words in registers and K weight words in the idle half of `wb_pair`, then waits to be swapped in. It owns the ping-pong state.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `start` | in | 1 | Begin a layer: `blocks_left` = `n_tiles` |
| `k`, `n_tiles` | in | 11, 16 | Layer shape |
| `s_valid`, `s_data` | in | 1, 64 | `wl_valid` and `s_axis_tdata` |
| `s_ready` | out | 1 | `wl_ready`. High only while taking a block |
| `swap` | in | 1 | Pulse from `layer_fsm` |
| `active` | out | 1 | The half the array reads |
| `nxt_valid` | out | 1 | A complete block is waiting in the idle half |
| `wb_we`, `wb_waddr`, `wb_wdata` | out | 1, 10, 64 | Write port of `wb_pair`, into half `~active` |
| `cur_bias`, `nxt_bias` | out | 8 × 32 each | Biases from set `active` and set `~active` |
| `cur_m0`, `cur_sh` | out | 8 × 16, 8 × 6 | Scales from set `active` |

State: loader state, a word counter, `blocks_left`, `active`, `nxt_valid`, and two parameter sets of 8 × (32 + 16 + 6) bits.

| Loader state | Does | Leaves when |
| --- | --- | --- |
| L_IDLE | `s_ready` = 0 | `start`: go to L_PARAM |
| L_PARAM | `s_ready` = 1. Word c fills set `~active`: bias = bits 31:0, m0 = bits 47:32, sh = bits 53:48 | 8 words taken: go to L_WGT |
| L_WGT | `s_ready` = 1. Word k is written to the idle half at address k | K words taken: `nxt_valid` = 1, `blocks_left` − 1, go to L_HOLD |
| L_HOLD | `s_ready` = 0 | `swap`: flip `active`, clear `nxt_valid`. L_PARAM if `blocks_left` > 0, else L_IDLE |

`s_ready` drops whenever a block is waiting, so the DMA stalls until the array has moved on. The stream never needs a length, and the driver sends the whole `w_img` as one transfer.

### 6.5 wb_pair, the weight block pair

Two identical memories. The array reads one for every tile of the current `nt`; the loader fills the other for the next `nt`.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `we`, `waddr`, `wdata` | in | 1, 10, 64 | Write into half `~active` |
| `active` | in | 1 | Selects the half for reads |
| `raddr` | in | 10 | `wb_rd_addr`, which is k |
| `rdata` | out | 64 | `w_word`. Valid RD_LAT = 2 cycles after `raddr`, same as `ub` |

State: two memories of 1,024 × 64 bits, 4 RAMB36E1 in all.

`active` only changes in the FSM's SWAP state, when no read is in flight, so the output mux needs no special care.

### 6.6 layer_fsm

The sequencer. It walks the tiles of a layer, issues one read address per cycle to both buffers, tells the array when words are valid and when to shift, and decides when to swap weight blocks.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `start` | in | 1 | Begin a layer |
| `m_tiles`, `k`, `n_tiles` | in | 16, 11, 16 | Layer shape |
| `nxt_valid` | in | 1 | From `wload` |
| `can_take_tile` | in | 1 | From `res_buf` |
| `last_sent` | in | 1 | From `out_fifo` |
| `ub_rd_addr` | out | 13 | `ub_base + k` |
| `wb_rd_addr` | out | 10 | `k` |
| `in_valid` | out | 1 | The read enable delayed by RD_LAT, so it lands with the data |
| `shift_en` | out | 1 | High for 8 cycles in PRELOAD and SHIFT |
| `bias_sel`, `shift_idx` | out | 2, 3 | Bias source and channel c during a shift |
| `swap` | out | 1 | Pulse in SWAP |
| `rb_discard`, `rb_last` | out | 1, 1 | Flags for the burst now leaving the array |
| `busy`, `done_set`, `err_set`, `fsm_state` | out | 1, 1, 1, 8 | Status to `regfile` |
| `ev_wait_wb`, `ev_wait_out`, `ev_tile` | out | 1 each | Counter enables |

State: the state register; counters `nt`, `mt`, `k`; `ub_base` (14 bits); a small counter for FLUSH and for the 8 shift cycles; a first-block flag.

| State | Code | Each cycle | Leaves when, and where to |
| --- | --- | --- | --- |
| IDLE | 0 | `busy` = 0 | `start`: clear `nt`, `mt`, `ub_base`; go to WAIT_BLK |
| WAIT_BLK | 1 | `ev_wait_wb` = 1 | `nxt_valid`: go to SWAP |
| SWAP | 2 | `swap` = 1 | After 1 cycle: PRELOAD for the first block, ACC for later ones |
| PRELOAD | 3 | `shift_en` = 1, `rb_discard` = 1, bias from CURRENT | After 8 cycles: go to ACC |
| ACC | 4 | Read `ub` at `ub_base + k` and `wb_pair` at `k`; `k` + 1 | K reads issued: go to FLUSH |
| FLUSH | 5 | Idle | FLUSH_LAT cycles after the last `in_valid`: go to HOLD |
| HOLD | 6 | `ev_wait_out` or `ev_wait_wb` = 1 | `can_take_tile`, and `nxt_valid` too if this is the last `mt` of a non-final `nt`: go to SHIFT |
| SHIFT | 7 | `shift_en` = 1; `shift_idx` counts 0 to 7; `rb_last` = 1 on the final tile | After 8 cycles: see the exit rule |
| DRAIN | 8 | Idle | `last_sent`: `done_set` = 1, go to IDLE |

`fsm_state` carries the code in the second column; it shows in STATUS[15:8].

- **Bias rule in SHIFT.** The shift loads the bias of the tile that runs next. Not the last `mt`: CURRENT. Last `mt` of a non-final `nt`: NEXT. Final tile: zero.
- **Exit rule from SHIFT.** Not the last `mt`: `mt` + 1, `ub_base` + K, go to ACC. Last `mt` of a non-final `nt`: `nt` + 1, `mt` = 0, `ub_base` = 0, go to SWAP. Final tile: go to DRAIN.
- **Rows leaving at a block boundary.** The bias comes from NEXT, but the `m0` and `sh` stored with the rows leaving come from CURRENT. `res_buf` reads `cur_m0` and `cur_sh` during the burst, before the swap.
- **Counter enables.** In HOLD, `ev_wait_out` is high while `can_take_tile` is low, and `ev_wait_wb` is high while the FSM needs `nxt_valid` and it is low. `ev_tile` is high on the last cycle of each SHIFT burst, never for PRELOAD.
- **Overflow.** If `ub_base` + K would pass 8,192, pulse `err_set`. The layer's results are then invalid.
- **Honour the constants.** FLUSH_LAT and SHIFT_LAT come from `mxu_pkg`, RD_LAT from the buffers. None is hard-coded.

The 12 transitions: IDLE→WAIT_BLK, WAIT_BLK→SWAP, SWAP→PRELOAD, SWAP→ACC, PRELOAD→ACC, ACC→FLUSH, FLUSH→HOLD, HOLD→SHIFT, SHIFT→ACC, SHIFT→SWAP, SHIFT→DRAIN, DRAIN→IDLE.

The whole controller is this loop:

```
for nt in 0 .. N_T-1:
    wait for the block; swap it in
    for mt in 0 .. M_T-1:
        for k in 0 .. K-1:
            a_word <- ub[mt*K + k]
            w_word <- wb[k]
        flush; shift 8 rows out to res_buf -> epilogue -> out_fifo
```

### 6.7 mxu, the matrix unit

Computes one 8×8 tile of sums. It takes K pairs of words, one activation word and one weight word per cycle, and accumulates 64 dot products in place. On a shift it hands the 64 sums out, 8 per cycle, and takes in the next tile's biases.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `in_valid` | in | 1 | `a_word` and `w_word` are word k of the current tile |
| `a_word` | in | 64 | Byte j = activation for tile row j. Treated as zero when `in_valid` is low |
| `w_word` | in | 64 | Byte c = weight for channel c |
| `shift_en` | in | 1 | High for exactly 8 consecutive cycles |
| `bias_in` | in | 32 | On the c-th shift cycle: bias for channel c of the next tile |
| `res_valid` | out | 1 | High for exactly 8 cycles per shift burst |
| `res_row` | out | 256 | On the c-th valid cycle, bits [32j+31 : 32j] = sum for row j, channel c |

At T = 4, `a_word` and `w_word` are 32 bits, `res_row` is 128 bits, and a burst is 4 cycles.

Function: after a shift burst that loaded `bias8` and K valid words, the next burst returns `res[c][j] = bias8[c] + sum over k of a[k][j] · w[k][c]`.

Structure:

1. **Activations run down columns.** Byte j of `a_word`, forced to zero when `in_valid` is low, is delayed j·PIPE cycles and drives `a_in` of PE(0, j). `a_out` of PE(r, j) drives `a_in` of PE(r+1, j).
2. **Weights run along rows, in reversed channel order.** Row r carries channel c = T − 1 − r. Byte c of `w_word` is delayed r·PIPE cycles and drives `w_in` of PE(r, 0). `w_out` of PE(r, j) drives `w_in` of PE(r, j+1).
3. **Sums chain down columns.** `c_in` of PE(0, j) is `bias_in` sign-extended to 48 bits, the same for every column. `c_in` of PE(r, j) is `p` of PE(r−1, j).
4. **Shift and results.** `shift` of every PE is `shift_en`. `res_valid` is `shift_en`. Bits [32j+31 : 32j] of `res_row` are `p[31:0]` of PE(T−1, j).

The reversal in step 2 puts channel 0 in the bottom row. During a shift the bottom row leaves first, and the first bias pushed in ends up in the bottom row, so `res_row` and `bias_in` both run in channel order 0 to 7 and nothing outside the array needs to know. The reversal applies to the weight byte and to its delay: byte c goes to row T − 1 − c with a delay of (T − 1 − c)·PIPE.

Timing of the reference design, T = 8 and PIPE = 1:

| Event, for a word accepted at cycle t | Cycle |
| --- | --- |
| Its bytes meet at PE(r, j) | t + r + j |
| The product is inside `p` of PE(r, j) | from t + r + j + 3 |
| Every PE has it | from t + 17, which is FLUSH_LAT |
| `shift_en` may rise | t + 17 or later, t being the tile's last word |
| `in_valid` may resume | The cycle after `shift_en` falls |

With PIPE = 0 every PE sees the word at cycle t and FLUSH_LAT is 3.

Resources: 64 DSP48E1, no block RAM.

### 6.8 pe, the processing element

One multiply-accumulate cell. It multiplies the two bytes passing through and adds the product to its own sum, or, in shift mode, copies the sum of the cell above.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `a_in` | in | 8, signed | Activation from above |
| `w_in` | in | 8, signed | Weight from the left |
| `a_out` | out | 8 | To the PE below: `a_in` delayed one cycle (PIPE = 1) or `a_in` itself (PIPE = 0) |
| `w_out` | out | 8 | To the PE on the right, same rule |
| `c_in` | in | 48, signed | `p` of the PE above, or the sign-extended bias |
| `shift` | in | 1 | 0: accumulate. 1: `p` takes `c_in` |
| `p` | out | 48, signed | The running sum |

Reference datapath:

```systemverilog
always_ff @(posedge clk) begin
  a_r <= a_in;                    // DSP A register
  w_r <= w_in;                    // DSP B register
  m_r <= a_r * w_r;               // DSP M register, signed 16-bit product
  if (rst)        p <= '0;
  else if (shift) p <= c_in;      // OPMODE 0110000: Z = C
  else            p <= p + m_r;   // OPMODE 0100101: Z = P, X and Y = M
end
```

Operands on the inputs in cycle t are inside `p` from cycle t + 3. Exactly one DSP48E1 with its A, B, M and P registers on, ALUMODE 0000, and no carry chain in fabric. If Vivado builds the adder in LUTs, put `(* use_dsp = "yes" *)` on the module; if that fails, instantiate `DSP48E1` with the two OPMODEs above. Reset only `p`; the other registers flush themselves with zeros during idle cycles.

### 6.9 res_buf, the result buffer

Catches the 8 rows of a shift burst and holds them until the epilogue is ready, each row stored with the scale of its channel.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `res_valid`, `res_row` | in | 1, 256 | A row of 8 sums from `mxu` |
| `rb_discard` | in | 1 | Drop this burst (the preload) |
| `rb_last` | in | 1 | This burst is the layer's final tile |
| `cur_m0`, `cur_sh` | in | 8 × 16, 8 × 6 | Scales of the CURRENT block |
| `can_take_tile` | out | 1 | At least 8 entries are free |
| `rb_valid` | out | 1 | A head entry is present |
| `rb_row`, `rb_m0`, `rb_sh`, `rb_last_o` | out | 256, 16, 6, 1 | The head entry |
| `rb_pop` | in | 1 | Head entry consumed |

State: a 16 × 279-bit FIFO in LUT RAM, read and write pointers, a fill count, and a 3-bit burst index c.

- c counts `res_valid` cycles from 0 to 7, including discarded bursts.
- When `res_valid` is high and `rb_discard` is low, push `{rb_last & (c == 7), cur_sh[c], cur_m0[c], res_row}`.
- The scale is captured at push time because `wload` may overwrite that parameter set before the epilogue reads the row.
- The `last` bit marks the layer's final row, so nothing downstream needs to count words or multiply M_TILES by N_TILES.

### 6.10 epilogue

Turns INT32 sums into INT8 outputs and packs 8 of them into one 64-bit word.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `rb_valid`, `rb_row`, `rb_m0`, `rb_sh`, `rb_last_o` | in | 1, 256, 16, 6, 1 | Head entry of `res_buf` |
| `rb_pop` | out | 1 | Pulse when the entry's last pair has been taken |
| `qz`, `qlo`, `qhi` | in | 8 each, signed | Output zero point and clamp bounds |
| `ep_valid`, `ep_word`, `ep_last` | out | 1, 64, 1 | A packed word for `out_fifo` |
| `of_ready` | in | 1 | `out_fifo` can take a word |

State: a 2-bit step counter, pipeline registers for two lanes, an 8-byte assembly register, and 2 DSP48E1.

Each entry takes 4 steps. On step t, lane 0 processes sum j = 2t and lane 1 processes j = 2t + 1. Per lane:

1. x = sat25(sum): clamp to [−2^24, 2^24 − 1].
2. In the DSP: P = x × m0 + (1 << (sh − 1)), with A = x, B = `{2'b00, m0}`, C = the rounding constant.
3. r = P >>> sh, an arithmetic shift.
4. y = clamp(qz + r, qlo, qhi), compared at full width, then truncated to 8 bits.

Byte j of `ep_word` is y for sum j. `ep_last` copies the entry's `last` bit. The whole pipeline stalls while `of_ready` is low.

Pipeline depth is free. The rate is fixed at 4 cycles per row, 32 per tile, which keeps pace with the array for K of about 10 or more. Below that the FSM waits in HOLD.

### 6.11 out_fifo

Decouples the epilogue from the DMA and produces the output stream.

| Port | Dir | Width | Meaning |
| --- | --- | --- | --- |
| `ep_valid`, `ep_word`, `ep_last` | in | 1, 64, 1 | Word to store |
| `of_ready` | out | 1 | Not full |
| `m_axis_tdata`, `m_axis_tlast` | out | 64, 1 | Head word and its `last` bit |
| `m_axis_tvalid`, `m_axis_tready` | out, in | 1, 1 | Handshake with the DMA |
| `last_sent` | out | 1 | Pulse when the `tlast` word is accepted |
| `ev_out_word` | out | 1 | High on every accepted word; counts CNT_OUT_WORDS |

State: a 512 × 65-bit first-word-fall-through FIFO, 1 RAMB36E1.

## 7. Stock Xilinx IP

Five instances surround `accel_top` in the block design. None is modified.

| Instance | Job | Ports that matter | Settings |
| --- | --- | --- | --- |
| ZYNQ7 Processing System | The CPU, the DDR3L controller and the clock | M_AXI_GP0: control master. S_AXI_HP0: 64-bit slave into DDR. FCLK_CLK0, FCLK_RESET0_N | Cora Z7-07S board preset. FCLK_CLK0 at 100 MHz, later 125 MHz |
| Processor System Reset | Turns FCLK_RESET0_N into synchronous resets | `peripheral_aresetn` to `accel_top` and the DMA; `interconnect_aresetn` to both interconnects | Defaults |
| AXI Interconnect, control | One master in, two out | From GP0. To the DMA's S_AXI_LITE and to `accel_top`'s `s_axi` | AXI Interconnect, not SmartConnect |
| AXI DMA | Reads a DDR range out as a stream and writes a stream into a DDR range | S_AXI_LITE: its registers. M_AXIS_MM2S to `s_axis`. S_AXIS_S2MM from `m_axis`. M_AXI_MM2S and M_AXI_S2MM: memory masters | Simple mode, scatter-gather off. 64-bit memory and stream data. Max burst 16. 23-bit length register. Unaligned transfers off |
| AXI Interconnect, data | Two masters in, one out | From the DMA's two memory masters. To S_AXI_HP0 | Converts AXI4 to the PS port's AXI3 |

The address editor assigns `accel_top` and the DMA each a range on GP0, and maps the full DDR range for both DMA masters. Software takes all three from `xparameters.h`. Target part: `xc7z007sclg400-1`.

## 8. Timing

### One tile, at the array's ports

Reference design, K words:

| Cycles | `in_valid` | `shift_en` | What happens |
| --- | --- | --- | --- |
| 0 to K − 1 | 1 | 0 | Words 0 to K − 1 enter |
| K to K + 15 | 0 | 0 | Products finish rippling through; inputs are zeros |
| K + 16 to K + 23 | 0 | 1 | Channels 0 to 7 leave on `res_row`; the next bias enters |
| K + 24 | 1 | 0 | Word 0 of the next tile |

- The shift burst is the only time sums leave the array, and the only time biases enter.
- The minimum tile period is K + FLUSH_LAT + 7 cycles: K + 24 here. The FSM adds a few cycles per tile for read latency and for its HOLD state.
- Gaps in `in_valid` during the accumulate phase are legal and only stretch it.

### One layer, across the system

| Step | Who | Action |
| --- | --- | --- |
| 1 | Driver | Flush the data cache over `a_img` |
| 2 | Driver | Write CTRL with UB_WR_RST = 1 and DEST = 0 |
| 3 | Driver, DMA | Send `a_img` on MM2S; wait until the channel is idle |
| 4 | Driver | Write M_TILES, K, N_TILES and QPARAM; flush the cache over `w_img` and `o_img` |
| 5 | Driver, DMA | Arm S2MM on `o_img` for M_T · N words |
| 6 | Driver | Write CTRL with DEST = 1 |
| 7 | Driver, DMA | Start MM2S on `w_img` for N_T · (K + 8) words |
| 8 | Driver | Write CTRL with DEST = 1 and START = 1 |
| 9 | `accel_top` | Runs every tile; the weight stream stalls and resumes on its own at each block swap |
| 10 | `accel_top`, DMA | The word with `tlast` is accepted on `m_axis` |
| 11 | Driver | STATUS.DONE reads 1; poll both DMA channels until idle |
| 12 | Driver | Invalidate the cache over `o_img`; read the counters |

- Steps 1 to 3 load the activations. They happen once per layer and do not overlap compute.
- Steps 5 and 7 may come before START, because `accel_top` holds `s_axis_tready` low for weights until START and the DMA waits.
- DONE rises only after the word carrying `tlast` has been accepted by the DMA, so step 11 also means the output buffer is complete.

### Minimum cycles per layer

A layer is M_T · N_T tiles of at least K + 24 cycles each.

| Demo layer | M × K × N | Tiles | K + 24 | Cycles |
| --- | --- | --- | --- | --- |
| 1 | 64 × 784 × 128 | 128 | 808 | 103,424 |
| 2 | 64 × 128 × 64 | 64 | 152 | 9,728 |
| 3 | 64 × 64 × 16 | 16 | 88 | 1,408 |

## 9. Driver

The whole API, in `sw/tpu/tpu.h`:

```c
typedef struct {
    uint16_t m_tiles;     /* M / 8        */
    uint16_t k;           /* 1 .. 1024    */
    uint16_t n_tiles;     /* N / 8        */
    int8_t   z, lo, hi;   /* output zero point, clamp bounds */
} tpu_layer_t;

typedef struct {
    uint32_t cycles, acc, shift, wait_wb, wait_out, tiles, out_words;
} tpu_counters_t;

int  tpu_init(void);   /* DMA init, read CAPS, check T == 8 */
int  tpu_load_acts(const uint64_t *a_img, uint32_t words);
int  tpu_run_layer(const tpu_layer_t *L, const uint64_t *w_img, uint64_t *o_img);
void tpu_reorder(const uint64_t *o_img, uint64_t *a_next,
                 uint32_t m_tiles, uint32_t n_tiles);
void tpu_read_counters(tpu_counters_t *c);
```

`tpu_load_acts`:

1. `Xil_DCacheFlushRange` over `a_img`, `words * 8` bytes.
2. Write CTRL with UB_WR_RST set and DEST = 0.
3. `XAxiDma_SimpleTransfer(&dma, (UINTPTR)a_img, words * 8, XAXIDMA_DMA_TO_DEVICE)`.
4. Poll `XAxiDma_Busy(&dma, XAXIDMA_DMA_TO_DEVICE)` until it clears.

`tpu_run_layer`:

1. Check that m_tiles · k is at most 8,192, because the hardware does not. Then write M_TILES, K, N_TILES and QPARAM.
2. Compute `w_words = n_tiles * (k + 8)` and `o_words = m_tiles * n_tiles * 8`. Flush the cache over both buffers.
3. Arm the receive: `XAxiDma_SimpleTransfer` on `o_img`, `o_words * 8` bytes, `XAXIDMA_DEVICE_TO_DMA`.
4. Write CTRL with DEST = 1. Start the send: `XAxiDma_SimpleTransfer` on `w_img`, `w_words * 8` bytes, `XAXIDMA_DMA_TO_DEVICE`.
5. Write CTRL with DEST = 1 and START = 1.
6. Poll STATUS.DONE with a timeout, then poll both DMA channels until idle.
7. `Xil_DCacheInvalidateRange` over `o_img`.
8. Return nonzero on STATUS.ERROR or timeout, and print the DMA status registers.

`tpu_reorder` is Contract 2's chaining rule: with N = 8 · `n_tiles`, copy `o_img[(nt*m_tiles + mt)*8 + c]` to `a_next[mt*N + 8*nt + c]`.

Rules:

- Declare every DMA buffer `static uint64_t buf[...] __attribute__((aligned(64)))`. The cache line is 32 bytes; 64-byte alignment keeps whole lines to one buffer.
- Flush before the DMA reads memory the CPU wrote. Invalidate after the DMA wrote memory the CPU will read.
- START and UB_WR_RST clear themselves, but DEST is a level. Include the DEST value you want in every CTRL write.
- Arm the receive before the send. The receive ends on `tlast`, not on the armed length.
- Simple-mode lengths must be nonzero and below 2^23 bytes.
- Time a layer with `XTime_GetTime` around `tpu_run_layer`, and also read CNT_CYCLES. Report both; the difference is software and DMA overhead.

The demo app runs the three layers of the demo model: load activations, run, reorder, repeat. It then prints the last `o_img` as one 16-hex-digit word per line, followed by timings and counters.

## 10. Resource targets

| Block | DSP48E1 | RAMB36E1 |
| --- | --- | --- |
| `mxu` | 64 | 0 |
| `ub` | 0 | 16 |
| `wload` and `wb_pair` | 0 | 4 |
| `res_buf` and `epilogue` | 2 | 0 |
| `out_fifo` | 0 | 1 |
| `layer_fsm` and `regfile` | 0 | 0 |
| `accel_top` total | 66 of 66 | 21 of 50 |

Peak compute is 64 MAC per cycle: 6.4 GMAC/s at 100 MHz, 8.0 GMAC/s at 125 MHz. Inside a layer the array runs at peak × K / (K + 24).
