Epilogue path: res_buf, epilogue and benches

## Goal

Build the result buffer and the requantizing epilogue, with their benches. They turn each 8-row burst of INT32 sums from the array into 8 packed INT8 output words, bit-exact with Contract 1.

## Files

- `rtl/ctrl/res_buf/res_buf.sv`, `tb/ctrl/res_buf/tb_res_buf.sv`
- `rtl/ctrl/epilogue/epilogue.sv`, `tb/ctrl/epilogue/tb_epilogue.sv`
- Synthesis reports next to each block

## Interfaces

- Port lists and behaviour: the header of each `.sv` file, and `docs/architecture.md`, sections 6.9 and 6.10.
- Requantization: `layer()` in Contract 1, `docs/contracts.md`.
- Epilogue vectors `epi_corners` and `epi_random`: format in `docs/verification.md`, section 5, produced by issue 1.

## Done when

Two stages, in this order:

1. `tb_res_buf` prints PASS, and `tb_epilogue` passes its random test on three seeds against the in-bench reference, plus the rate test. SKIP lines removed.
2. `tb_epilogue` also matches every line of `epi_corners` and `epi_random` once issue 1 publishes them.

Both benches cover every test and must-hit case in `docs/verification.md`, sections 6.6 and 6.7. Synthesis: `epilogue` 2 DSP48E1 and no LUT multiplier; `res_buf` no block RAM. Reports committed.

## Out of scope

- `out_fifo` (issue 8) and the FSM flags `rb_discard` and `rb_last` (issue 5); the benches drive those directly.
- Any change to the rounding or saturation rule. That is Contract 1.
