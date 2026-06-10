# O12C Phase Buffer Placement Plan

REPORT_STATUS=REVIEW_REQUIRED

O12C should make the phase buffer bank physically intentional instead of relying on default placement.

## Placement Concept

```text
slow RO -> slow phase buffer row -> PD matrix
fast RO -> fast phase buffer row -> PD matrix
```

Rules:

- Place all 8 slow phase buffers in tap order.
- Place all 8 fast phase buffers in tap order.
- Keep each buffer close to the corresponding RO macro output side.
- Use identical orientation if possible.
- Keep raw RO-to-buffer input routes short and balanced.
- Balance buffer output routes as much as practical.
- Avoid placing phase buffers in unrelated backend logic regions.

## Constraint Hook

Use:

```text
MPTDC/pnr/scripts/innovus_o12c_phase_buffer_place.tcl
```

Required environment variables before applying the hook:

- `MPTDC_O12C_SLOW_BUF_X`
- `MPTDC_O12C_SLOW_BUF_Y`
- `MPTDC_O12C_FAST_BUF_X`
- `MPTDC_O12C_FAST_BUF_Y`

Optional:

- `MPTDC_O12C_PHASE_BUF_PITCH_UM`
- `MPTDC_O12C_PHASE_BUF_ORIENT`

The first O12C placement run should be `buhdx4_place`, not a stronger-cell run.  Keep topology constant while evaluating placement and matching.

## Required Metrics

- Raw route length max/min.
- Output route length max/min.
- Raw-to-buffer distance max/min.
- Buffer-to-PD distance max/min.
- Tap-to-tap mismatch.
- `fast[0]` and `fast[6]` compared to other fast taps.
- `slow[0]` compared to `slow[1:7]`.

If placement extraction remains unavailable from Innovus DB attributes, keep using `report_property` reports and add a targeted `report_property [get_cells ...]` parser.
