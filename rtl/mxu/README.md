# rtl/mxu

The 8×8 output-stationary array.

- `mxu_pkg.sv`: T, PIPE, FLUSH_LAT, SHIFT_LAT. Everything else reads timing from here.
- `pe/`: one multiply-accumulate cell, one DSP48E1.
- `mxu/`: 64 `pe` instances and the two skew networks.

Spec: `docs/contracts.md` Contract 4, `docs/architecture.md` sections 6.7 and 6.8. Benches in `tb/mxu/`.
