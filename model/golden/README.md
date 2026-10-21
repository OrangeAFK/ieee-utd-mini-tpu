# model/golden

`golden.py` holds `layer()` and `tile()`, Contract 1 in `docs/contracts.md`. They are written in full and are the reference for every numerical result in the project. Changing them is a contract change and goes through the lead.

```python
from model.golden import layer, tile
```

To implement: the two tests in `test_golden.py`. Delete the `pytestmark` skip line when they are real.

- `test_layer_matches_loop_model`: write the layer as three nested Python loops over int values (sum, sat25, `(acc * M0 + 2**(s-1)) >> s` with Python's floor shift, clamp) and compare with `layer()` on 1,000 random small shapes. Force -128 and 127 into A, W, z, lo and hi in every case.
- `test_tiles_then_requant_match_layer`: for every (mt, nt), call `tile()` on `A[8mt:8mt+8, :].T` and `W[:, 8nt:8nt+8]` with that block's bias, then apply sat25, the rounding shift and the clamp. Reassemble and compare with `layer()`.

Pitfalls: cast INT8 to int64 before any arithmetic, since NumPy wraps INT8 silently. Python's `round()` rounds ties to even and disagrees with the hardware. Pass `s` as int64.

Run: `pytest model/golden`.
