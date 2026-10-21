# tb/ctrl/wload

`tb_wload.sv` tests `rtl/ctrl/wload/wload.sv`. The header lists the reference, assertions, must-hit cases and the exit criterion; each test in the plan is a named task with a one-line pass/fail rule.

Run: `python tb/run.py sim tb_wload`. Plan: `docs/verification.md`, section 6.4.

It instantiates `wb_pair` too and reads weights back through it.
