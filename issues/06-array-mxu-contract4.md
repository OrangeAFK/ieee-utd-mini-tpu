Array: add the finished mxu and check it against Contract 4

## Goal

Replace the `pe` and `mxu` stubs with the finished array, prove it meets Contract 4 exactly, and confirm the timing constants everyone else reads from `mxu_pkg`. Write the Contract 4 checker the other benches reuse.

## Files

- `rtl/mxu/pe/pe.sv`, `rtl/mxu/mxu/mxu.sv`, `rtl/mxu/mxu_pkg.sv`
- `tb/mxu/pe/tb_pe.sv`, `tb/mxu/mxu/tb_mxu.sv`
- `tb/common/mxu_check/mxu_check.sv`
- `hw/mxu_ooc.tcl`, `docs/mxu_report.md`

## Interfaces

- Contract 4, `docs/contracts.md`: ports, function and timing rules. Port names and widths in the stubs are fixed.
- Structure, wiring rules and reference timing: `docs/architecture.md`, sections 6.7 and 6.8.
- Tile vectors `tile_*`: issue 1. Until they exist, compute expected results in the bench with `tile()`.

## Done when

- `tb_pe` prints PASS for PIPE = 0 and 1, and `tb_mxu` for T = 4 and 8 crossed with PIPE = 0 and 1, in CI with the SKIP lines removed, covering every test and must-hit case in `docs/verification.md`, sections 6.1 and 6.2.
- `tb_mxu` test 7 measures FLUSH_LAT and SHIFT_LAT, and `mxu_pkg.sv` holds exactly those values.
- `mxu_check` catches a shift one cycle early.
- `pe` alone: 1 DSP48E1, 0 CARRY4. `mxu` at T = 8: 64 DSP48E1, no CARRY4 inside any `pe`, timing met at 8.000 ns. `docs/mxu_report.md` gives LUTs, flip-flops and worst slack for PIPE = 1 and PIPE = 0, and whether the P chain used the dedicated DSP cascade.
- If the finished array cannot meet Contract 4, raise it with the lead before anything else builds on it.

## Out of scope

- The memories, the FSM, requantization and anything AXI.
