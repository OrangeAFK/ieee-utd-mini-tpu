# rtl

Synthesizable SystemVerilog. `mxu/` is the array; `ctrl/` is everything around it. One folder per block, one module per file, named after the folder.

Every file opens with a header: what the block does, its ports, the behaviour to implement, timing, resource target, the bench that must pass, and the spec section. Lint: `python tb/run.py lint`.
