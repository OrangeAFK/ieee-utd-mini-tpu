Golden model and test vectors

## Goal

Make the golden model's self-tests real, implement the packers and the vector generator, and commit every vector set the benches read. Every other part of the project checks itself against these files, so the first sets are needed before anything else.

## Files

- `model/golden/test_golden.py` (`golden.py` is already complete)
- `model/pack/pack.py`, `model/pack/test_pack.py`
- `model/gen_vectors/gen_vectors.py`, `model/gen_vectors/test_gen_vectors.py`
- `vectors/*.hex`
- `sw/demo/data/reorder_test.h`

## Interfaces

- Contract 1 (golden model) and Contract 2 (tensor layout), `docs/contracts.md`.
- Vector file formats and the list of sets: `model/gen_vectors/README.md` and `docs/verification.md`, section 5.
- Function signatures: `model/pack/README.md`, `model/gen_vectors/README.md`.

## Done when

- `pytest model/golden model/pack model/gen_vectors` passes in CI with the skip lines removed.
- These sets are committed under `vectors/`: `tile_k1`, `tile_k2`, `tile_k9`, `tile_k300`, `tile_corner`, `epi_corners`, `epi_random`, `layer_single`, `layer_mid`, `layer_demo1` (random weights for now), `layer_rand_00` to `layer_rand_49`.
- `sw/demo/data/reorder_test.h` is committed.
- Order of delivery: tile and epi sets, `layer_single` and `layer_mid` first; demo and random layers after.

## Out of scope

- Changing `layer()` or `tile()`. That is a contract change and goes through the lead.
- Training and export (issue 2). `layer_demo2` and `layer_demo3` come from there.
- C headers for the demo app and the UART checker.
