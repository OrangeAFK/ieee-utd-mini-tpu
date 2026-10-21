## What changed

Issue:

## Evidence

Bench or test output (the PASS line and the cover-counter printout):

```
```

Static check, if this PR finishes a block (DSP, RAMB36E1, CARRY4 counts, timing):

## Checklist

- [ ] The SKIP line is removed from every bench or test this PR makes real
- [ ] `python tb/run.py lint` is clean
- [ ] No port list, width or register bit changed, or the lead approved the contract change
- [ ] Nothing in `vectors/` edited by hand
- [ ] Synthesis report committed next to the block, if this PR finishes one
