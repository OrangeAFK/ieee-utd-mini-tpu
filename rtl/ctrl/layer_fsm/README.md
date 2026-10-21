# rtl/ctrl/layer_fsm

The sequencer: walks the tiles of a layer, drives the buffer read addresses, `in_valid`, `shift_en`, the bias mux and `swap`.

- `layer_fsm.sv`: the module. Its header comment is the full spec for implementing it.
- Tested by `tb/ctrl/layer_fsm/tb_layer_fsm.sv`: `python tb/run.py sim tb_layer_fsm`.
- Static check: no DSP, no block RAM.
