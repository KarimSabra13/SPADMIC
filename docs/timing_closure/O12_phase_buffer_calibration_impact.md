# O12 Phase Buffer Calibration Impact

Status: `O12_PHASE_ISOLATION_BUFFER_EXPERIMENT`

This is a calibration-impact note, not characterization evidence and not
signoff.

## Functional Boundary

O12 does not intentionally change:

- packet format;
- `raw_lfsr_tag` semantics;
- `nslow` width;
- `nfast` width;
- R750 delta5 mode;
- PD functional behavior.

The simulation version of `mptdc_phase_buffer_bank` is assign-only, so RTL
behavior remains bit-identical unless synthesis physical delays are considered.

## Physical Impact

O12 adds one BUHDX4 phase-isolation buffer per tap:

```text
RO_tune4/S[n] -> BUHDX4 -> digital phase net
```

This improves raw RO load, but it adds insertion delay between the analog phase
source and the digital phase fabric.

Calibration can absorb this delay only if it is:

- stable;
- common or smoothly varying by tap;
- monotonic enough for Vernier phase interpretation;
- small enough that tap spacing and linearity are not destroyed.

## Adoption Gate

Before O12 can be adopted:

- O12B must quantify load, placement, delay, route length, and mismatch.
- O12C may be needed to constrain placement and matching.
- Xcelium/analog characterization must be rerun after the physical topology is
  chosen.

Do not claim precision, linearity, or calibration preservation until
characterization confirms it.
