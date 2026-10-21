# rtl/mxu/mxu

The T×T array: activations run down columns, weights along rows in reversed channel order, sums chain down columns during a shift. Ports are exactly Contract 4.

- `mxu.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/mxu/mxu/tb_mxu.sv`: `python tb/run.py sim tb_mxu`.
- Static check: 64 DSP48E1 at T = 8, timing met at 8 ns, for PIPE = 0 and 1. Report in `docs/mxu_report.md`.
