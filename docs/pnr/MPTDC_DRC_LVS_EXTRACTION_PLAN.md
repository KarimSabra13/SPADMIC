# MPTDC DRC LVS Extraction Plan

Status: `TYPICAL_ONLY`, `NOT_MMMC_SIGNOFF`, `NOT_FINAL_SILICON_SIGNOFF`

## DRC

The prototype must report route DRC and any available implementation DRC. A
clean implementation DRC is not equivalent to foundry signoff DRC.

## LVS

LVS is blocked until the final macro delivery model is decided for `RO_tune4`
and the top-level MPTDC instance boundary is frozen. The prototype should still
record the expected netlist, macro views, and power nets used for LVS.

## Extraction

Extraction is required before internal signoff on raw RO load and phase-route
balance. Until extracted RC is reviewed, load reports are implementation
evidence, not silicon signoff evidence.

## Required Artifacts

- DRC summary
- LVS setup manifest
- extraction setup manifest
- cap table or extraction corner manifest
- raw RO output load after extraction
- phase-buffer output load after extraction
