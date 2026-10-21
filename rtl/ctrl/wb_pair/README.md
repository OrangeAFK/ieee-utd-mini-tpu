# rtl/ctrl/wb_pair

Weight block pair: two 1,024 × 64-bit memories. Reads use half `active`, writes go to the other.

- `wb_pair.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/wb_pair/tb_wb_pair.sv`: `python tb/run.py sim tb_wb_pair`.
- Also exercised by `tb/ctrl/wload/tb_wload.sv`.
- Static check: 4 RAMB36E1.
