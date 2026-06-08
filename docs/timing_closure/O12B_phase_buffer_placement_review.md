# O12B Phase Buffer Placement Review

Status: `O12B_PHASE_BUFFER_BALANCE_AND_CLEAN_PNR`

This is a feasibility/debug review, not signoff.

## Placement Intent

The phase buffers should sit between the RO macros and the digital fabric:

```text
slow RO -> slow phase buffers -> PD matrix
fast RO -> fast phase buffers -> PD matrix
```

The raw `RO_tune4/S[n]` routes should be short.  The buffered phase nets may
drive the larger downstream fabric, but their route lengths and transition
mismatch must be visible.

## Required Reports

O12B generates:

- `reports/phase_buffer_placement.csv`
- `reports/phase_buffer_placement_summary.md`
- `reports/phase_buffer_route_summary.csv`

The reports must record, when Innovus exposes the attributes:

- buffer coordinates and bounding box;
- RO macro coordinates;
- buffer distance from the corresponding RO macro;
- PD matrix center estimate;
- raw and buffered route lengths;
- route-length mismatch.

## Acceptance Gate

Placement is acceptable for O12B decision quality only if:

- all 16 buffers have numeric locations;
- slow buffers are near the slow RO;
- fast buffers are near the fast RO;
- no buffer is displaced into an unrelated digital region;
- route-length mismatch is small enough to review and calibrate.

If placement or route length is unknown or visibly mismatched, prepare O12C
explicit placement constraints before claiming closure progress.
