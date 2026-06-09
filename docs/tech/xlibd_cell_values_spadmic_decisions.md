# SPADMIC XLIBD Decision Notes

Status: `REFERENCE_ONLY_NOT_SIGNOFF`

## O13 Phase Buffer Topology

Decision: keep `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric` as the preferred O13 topology.

Reasons:

- `BUHDX4` input cap is `10.56 fF`, well below the strict `58.72 fF` RO analog budget.
- `BUHDX12` input cap is `32.24 fF`, also below the strict budget, but it gives less isolation margin at the RO node.
- `BUHDX2` and `BUHDX3` are useful intermediate-drive buffers, but their extracted timing confirms they are not preferred final drivers for `0.5-0.7 pF` phase outputs.
- `BUHDX4` is too weak as the final phase driver for roughly `0.5-0.7 pF` phase-net loads.
- `BUHDX12` has much better extracted transition behavior around that load range.
- The topology is identical for all taps, so common delay can be calibrated.

If routed O13 still misses final-driver transition, the next candidate is a matched three-stage chain:

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> BUHDX12 -> phase fabric
```

Do not size one tap differently unless a later physical review explicitly approves a calibrated asymmetry.

## RO Load Budgets

Decision: keep Edouard's analog budgets authoritative.

- Strict D-load budget: `58.72 fF`
- CN/clock-like budget: `75.59 fF`
- XLIBD DFF pin caps are useful for reporting equivalents, not for overriding analog RO budgets.

## IO Load Assumptions

Decision: use `DFRRQHDX2 D_CAP = 3.20 fF` as the first provisional block-output load unit.

- `DFRQHDX2 D_CAP = 2.70 fF` is also available as a lighter no-reset DFF reference.
- Default feasibility class: `medium`, equal to 8 D inputs or `25.6 fF`.
- Escalate to `heavy`, equal to 16 D inputs or `51.2 fF`, if the manager/system integration expects stronger local loading.
- Do not treat this as pad-level signoff.

## Reset Recovery

Decision: keep reset recovery/removal/min-pulse checks visible and classified.

The extracted `DFRRQHDX1` and `DFRRQHDX2` recovery, removal, and reset min-pulse constraints are real Liberty checks. `DFRSHDX1` has an `SN` set pin rather than an `RN` reset pin; use it only when set behavior is required. Waive reset/set timing only with protocol proof, for example if oscillators are stopped during clear/release and the waiver is tied to that behavior.

## Scan Cells

Decision: do not use `SDFFQHDX2` or `SDFFQHDX4` for normal synthesis.

Both scan cells are present in the extracted library data but marked `dont_use=true`. Use only after a deliberate DFT/scan strategy is defined.

## Remaining XLIBD Requests

The new extraction covers the previously missing `BUHDX2`, `BUHDX3`, `INHDX0`, `INHDX1`, `EO2HDX0`, `DFRRQHDX1`, `DFRQHDX2`, `DFRHDX1`, and `DFRSHDX1`.

Still useful later:

- `INHDX2`
- `ON22HDX0`
- `ON22HDX1`
- `BUHDX0`
- `BUHDX1`
- dedicated clock buffers/inverters, if the library has them
- integrated clock-gating cells, if later CTS/low-power analysis needs them
