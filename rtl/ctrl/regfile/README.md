# rtl/ctrl/regfile

Register file: the AXI4-Lite slave of Contract 5, the START pulse, status bits and seven counters.

- `regfile.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/regfile/tb_regfile.sv`: `python tb/run.py sim tb_regfile`.
- Static check: no DSP, no block RAM.
