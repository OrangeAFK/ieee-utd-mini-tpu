Buffers: ub, wload, wb_pair and benches

## Goal

Build the activation buffer, the weight loader and the weight block pair, with their benches. Together they turn the input stream into one activation word and one weight word per cycle for the array.

## Files

- `rtl/ctrl/ub/ub.sv`, `tb/ctrl/ub/tb_ub.sv`
- `rtl/ctrl/wload/wload.sv`, `tb/ctrl/wload/tb_wload.sv`
- `rtl/ctrl/wb_pair/wb_pair.sv`, `tb/ctrl/wb_pair/tb_wb_pair.sv`
- Synthesis reports next to each block

## Interfaces

- Port lists and behaviour: the header of each `.sv` file, and `docs/architecture.md`, sections 6.3 to 6.5.
- Read latency RD_LAT = 2 for both `ub` and `wb_pair`, so `a_word` and `w_word` stay aligned.
- `w_img` layout and the parameter word: Contract 2, `docs/contracts.md`.
- Stream source for the benches: `tb/common/axis_src` (issue 8).

## Done when

- `tb_ub`, `tb_wload` and `tb_wb_pair` print PASS in CI with the SKIP lines removed, covering every test and must-hit case in `docs/verification.md`, sections 6.3 to 6.5.
- Every assertion in `tb_wload` has fired at least once.
- Synthesized alone: `ub` 16 RAMB36E1, `wb_pair` 4 RAMB36E1, no LUT RAM. Reports committed.

## Out of scope

- The stream demux and the top-level wiring, in `accel_top`.
- `out_fifo` (issue 8).
- The read-address sequencing, which is `layer_fsm` (issue 5).
