Shared bench components and out_fifo

## Goal

Build the bench components every other testbench uses, and the output FIFO that drives `m_axis`, tested with them.

## Files

- `tb/common/axis_src/axis_src.sv`, `tb/common/axis_sink/axis_sink.sv`
- `tb/common/axis_check/axis_check.sv`, `tb/common/axil_master/axil_master.sv`, `tb/common/tb_pkg.sv`
- `rtl/ctrl/out_fifo/out_fifo.sv`, `tb/ctrl/out_fifo/tb_out_fifo.sv`

## Interfaces

- Each component's ports, tasks and behaviour: its header comment, and `docs/verification.md`, section 4.
- Streams: Contract 3, `docs/contracts.md`. Register master: Contract 5.
- `out_fifo`: the header of `out_fifo.sv` and `docs/architecture.md`, section 6.11.

## Done when

Two stages, in this order:

1. `axis_src` and `axis_sink` work, since the buffer and FSM benches need them first. Show them passing words through with gaps on both sides.
2. `tb_pkg`, `axis_check`, `axil_master`, `out_fifo` and `tb_out_fifo` are done: `tb_out_fifo` prints PASS in CI with the SKIP line removed, covering every test and must-hit case in `docs/verification.md`, section 6.8, with `axis_check` on `m_axis`. A deliberate protocol violation makes `axis_check` fail. `out_fifo` synthesized alone shows 1 RAMB36E1.

## Out of scope

- `mxu_check` (issue 6).
- `regfile` and its bench, which will use `axil_master`.
