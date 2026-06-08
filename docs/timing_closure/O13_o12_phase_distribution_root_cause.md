# O13 O12 Phase Distribution Root Cause

REPORT_STATUS=REVIEW_REQUIRED

This note records the O12/O12B/O12C result that motivates `O13_PHASE_DISTRIBUTION_TREE_CLEANUP`.  It is feasibility evidence only, not signoff.

## O12 Success

O12 inserted a matched phase-isolation bank:

```text
RO_tune4/S[n]
  -> *_phase_raw[n]
  -> BUHDX4 phase isolation buffer
  -> *_phase[n]
  -> PD matrix / fast tags / slow epoch / metadata
```

The direct analog RO load blocker is fixed:

- Raw RO rows: `16`.
- Matched raw RO rows: `16`.
- Missing raw RO rows: `0`.
- Raw fanout-1 rows: `16`.
- Raw rows with numeric DB cap: `16`.
- Max measured raw RO source load: about `38 fF` at slow `S[0]`.
- Strict analog budget: `58.72 fF`.
- CN/clock-like budget: `75.59 fF`.
- Raw RO budget labels: `16 OK_STRICT`.

Decision label:

```text
RAW_RO_LOAD_FIXED=YES
```

This is real physical progress.  The RO output no longer directly drives the large PD/tag/epoch/metadata fabric.

## Remaining Problem

O12 moved the large digital load to the single `BUHDX4` output.  That is the correct direction, but the single-stage `BUHDX4` is not strong enough to be the final digital phase driver.

Observed O12C/O12B output-load evidence:

| Phase | Fanout | Total cap | Wire cap | Pin cap | Transition | Notes |
|---|---:|---:|---:|---:|---:|---|
| slow[0] | 73 | ~520 fF | ~195 fF | ~325 fF | TBD from final report | uniquely heavy |
| slow[1:7] | 8-9 | ~74-183 fF | lower | lower | TBD | much lighter |
| fast[0] | 89 | ~682 fF | high | high | ~1.005 ns | heavy |
| fast[1:7] | 87 | ~584-707 fF | high | high | ~0.851-1.049 ns | consistently heavy |
| fast[6] | 87 | ~707 fF | high | high | ~1.049 ns | worst observed fast tap |

Do not compare these `BUHDX4/Q` loads to the `58.72 fF` analog budget.  That budget applies to `RO_tune4/S[n]`.  The `BUHDX4/Q` node is a digital driver node and must be judged by transition, delay, mismatch, power, DRV, and timing.

## Slow Phase0 Asymmetry

`slow_phase[0]` remains structurally different from slow taps `1:7`:

- `slow[0]` fanout: `73`.
- `slow[0]` cap: about `520 fF`.
- `slow[0]` load mix includes `64` slow-epoch loads, `1` metadata load, and `8` other loads.
- `slow[1:7]` fanout: `8-9`.
- `slow[1:7]` cap: about `74-183 fF`.

This is a linearity and calibration risk because the PD-facing slow phase0 path can see a very different load and delay than the other slow taps.

The immediate O13 experiment keeps all taps topologically identical.  If slow0 remains a strong outlier after the two-stage driver, the next candidate is a documented split:

```text
slow_phase_raw[0]
  -> BUHDX4 isolation
  -> slow_phase_pd[0] driver for PD matrix
  -> slow_phase_aux0 driver for slow epoch / metadata
```

That split is not silent.  It must preserve packet format and document that calibration absorbs the fixed branch offset.

## O13 Decision

Keep O12 phase isolation and replace the weak final digital drive:

```text
RO_tune4/S[n]
  -> BUHDX4 isolation buffer
  -> BUHDX12 digital driver
  -> phase fabric
```

Reasons:

- `BUHDX4` input keeps raw RO load safely below the analog budget.
- `BUHDX12` is a stronger final driver for the `500-700 fF` digital phase load.
- The topology remains identical for all 16 taps.
- Packet format, `raw_lfsr_tag`, `nfast/nslow` widths, frequency, and PD behavior remain unchanged.
- Added delay is common per tap by construction and must be measured for calibration.

O13 is not signoff.  It is the next physical feasibility step to decide whether a two-stage phase-distribution tree can meet transition, timing, mismatch, placement, and power expectations before characterization is rerun.
