# tb/mxu/mxu

`tb_mxu.sv` tests `rtl/mxu/mxu/mxu.sv`. The header lists the reference, assertions, must-hit cases and the exit criterion; each test in the plan is a named task with a one-line pass/fail rule.

Run: `python tb/run.py sim tb_mxu`. Plan: `docs/verification.md`, section 6.2.

Reads `vectors/tile_*.hex` at T = 8.
