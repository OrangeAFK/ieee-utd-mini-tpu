# tb/ctrl/accel_top

`tb_accel_top.sv` tests `rtl/ctrl/accel_top/accel_top.sv`. The header lists the reference, assertions, must-hit cases and the exit criterion; each test in the plan is a named task with a one-line pass/fail rule.

Run: `python tb/run.py sim tb_accel_top`. Plan: `docs/verification.md`, section 6.11.

Reads `vectors/layer_*.hex`. Runs with the real `mxu`.
