# tb/ctrl/epilogue

`tb_epilogue.sv` tests `rtl/ctrl/epilogue/epilogue.sv`. The header lists the reference, assertions, must-hit cases and the exit criterion; each test in the plan is a named task with a one-line pass/fail rule.

Run: `python tb/run.py sim tb_epilogue`. Plan: `docs/verification.md`, section 6.7.

Reads `vectors/epi_*.hex` once they exist; until then it runs against its in-bench reference.
