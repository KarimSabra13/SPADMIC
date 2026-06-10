# MPTDC Floorplan Plan

Status: `PLANNED_AFTER_GENUS_REVIEW`

## Goals

- Preserve a symmetric 8x8 PD matrix.
- Keep slow and fast phase distribution balanced enough for calibration.
- Protect the raw RO outputs from excessive direct capacitive load.
- Keep the BUHDX4 isolation cells close to the RO outputs.
- Keep the BUHDX12 final phase drivers close to the phase fabric they drive.

## Proposed Placement

- Slow `RO_tune4`: one side of the PD matrix.
- Fast `RO_tune4`: opposite side of the PD matrix.
- PD matrix: regular 8x8 grid.
- Slow phase buffers: matched per-tap chain from slow RO to PD rows.
- Fast phase buffers: matched per-tap chain from fast RO to PD columns.
- Digital control/readout: outside the matched PD/phase region.

## Protected Topology

```text
RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric
```

Do not size individual taps asymmetrically without a reviewed calibration reason.

## Checks

- raw RO pin capacitance is within the strict analog load budget
- phase-buffer output load is reported per tap
- route mismatch is reported per slow/fast tap
- PD row/column symmetry is reported
- no CTS buffers are inserted on RO or phase clocks
