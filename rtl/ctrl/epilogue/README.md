# rtl/ctrl/epilogue

Requantization: INT32 sums to INT8 outputs by Contract 1, two lanes, packed 8 to a word, 4 cycles per row.

- `epilogue.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/epilogue/tb_epilogue.sv`: `python tb/run.py sim tb_epilogue`.
- Static check: 2 DSP48E1.
