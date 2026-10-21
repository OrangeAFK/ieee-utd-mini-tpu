Layer FSM and its bench

## Goal

Build the sequencer that walks every tile of a layer, and test it alone against a schedule model before it meets the rest of the design.

## Files

- `rtl/ctrl/layer_fsm/layer_fsm.sv`
- `tb/ctrl/layer_fsm/tb_layer_fsm.sv`

## Interfaces

- Port list, the nine states with their codes, the bias rule and the exit rule: the header of `layer_fsm.sv` and `docs/architecture.md`, section 6.6.
- Contract 4 timing: `docs/contracts.md`. FLUSH_LAT and SHIFT_LAT come from `rtl/mxu/mxu_pkg.sv`; RD_LAT = 2 from the buffers. None is a literal in the RTL.
- `tb/common/mxu_check` watches the FSM's `in_valid` and `shift_en` (issue 6).

## Done when

- `tb_layer_fsm` prints PASS in CI with the SKIP line removed, covering every test and must-hit case in `docs/verification.md`, section 6.10.
- The cover counters for all 12 transitions are nonzero.
- Synthesized alone: no DSP and no block RAM.

## Out of scope

- The buffers, the array and the epilogue; the bench models them.
- `accel_top` integration.
