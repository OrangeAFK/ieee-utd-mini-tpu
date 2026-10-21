# rtl/mxu/pe

One multiply-accumulate cell: a signed 8×8 product added to a 48-bit sum, or the sum of the cell above copied in during a shift. Must map to exactly one DSP48E1.

- `pe.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/mxu/pe/tb_pe.sv`: `python tb/run.py sim tb_pe`.
- Static check: out-of-context synthesis, 1 DSP48E1 and 0 CARRY4. Commit the report here.
