# O12C O12B Abs4 Review

REPORT_STATUS=REVIEW_REQUIRED

O12 phase isolation remains the correct direction.  The O12B abs4 evidence shows the direct analog RO load blocker is fixed: all 16 `RO_tune4/S[n]` outputs matched, all 16 raw rows are fanout 1, and the raw RO load is bounded by the RO Liberty shell max-cap of `50.00 fF`.  That is below Edouard's strict D-input budget of `58.72 fF` and below the CN/clock-like estimate of `75.59 fF`.

This is feasibility evidence, not signoff.

## Architecture

Before O12:

```text
RO_tune4/S[n] -> *_phase[n] -> PD / tags / epoch / metadata
```

After O12:

```text
RO_tune4/S[n] -> *_phase_raw[n] -> BUHDX4 phase buffer -> *_phase[n] -> PD / tags / epoch / metadata
```

The important physical change is that the analog RO output now drives only a single local buffer input.  The heavy digital load has moved to `BUHDX4/Q`, where it belongs.

## Raw RO Load Result

- Raw RO rows: 16.
- Matched raw RO rows: 16.
- Raw fanout-1 rows: 16.
- Raw load bound: `<= 50.00 fF`.
- Strict analog budget: `58.72 fF`.
- CN-like budget: `75.59 fF`.
- Strict ratio: `<= 0.85x`.
- CN ratio: `<= 0.66x`.
- Status: `RAW_RO_LOAD_FIXED=YES`.

Do not compare the BUHDX4 output loads below to the analog RO budget.  The analog budget applies to `RO_tune4/S[n]`, not to the inserted digital buffer output.

## Buffer Output Loads

| Family | Tap | Cap fF | Fanout | R ohm |
|---|---:|---:|---:|---:|
| fast | 0 | 682 | 89 | 1007 |
| fast | 1 | 623 | 87 | 849 |
| fast | 2 | 584 | 87 | 778 |
| fast | 3 | 595 | 87 | 801 |
| fast | 4 | 592 | 87 | 794 |
| fast | 5 | 588 | 87 | 773 |
| fast | 6 | 707 | 87 | 1044 |
| fast | 7 | 657 | 87 | 926 |
| slow | 0 | 520 | 73 | 730 |
| slow | 1 | 103 | 8 | 198 |
| slow | 2 | 74 | 8 | 103 |
| slow | 3 | 128 | 9 | 229 |
| slow | 4 | 183 | 9 | 362 |
| slow | 5 | 147 | 9 | 279 |
| slow | 6 | 94 | 8 | 163 |
| slow | 7 | 93 | 8 | 156 |

The fast phase nets are all heavy.  `fast[6]` is the worst measured output load at `707 fF`, followed by `fast[0]` at `682 fF`.  Slow phase load is asymmetric: `slow[0]` is much heavier than `slow[1:7]` because it carries slow epoch and metadata-style loads in addition to phase use.

## Topology

The O12 source topology is one single-stage `BUHDX4` per tap.  O12B abs4 showed `buffer_chain_depth=1`, correct raw input nets, correct buffered output nets, and present A/Q pins.  The blank `cell_sequence` in abs4 was a reporter cell-type extraction issue, not evidence of a physical topology change.

The O12B parser is patched for O12C to report:

- `TOPOLOGY_SHAPE_MATCHED` when the A/Q path and raw/output nets match.
- `CELL_TYPE=BUHDX4` when DB or RTL/filelist fallback identifies the cell.
- `CELL_TYPE_UNRESOLVED_BY_DB` only when the physical shape matches but Innovus cannot expose the lib-cell name.

## Current Unknowns

- BUHDX4 output transition per tap.
- BUHDX4 delay per tap.
- Route length per tap.
- Tap-to-tap mismatch.
- Dynamic power from the phase buffers.
- Placement quality and symmetry.
- Whether fast `0` and `6` need stronger drive.
- Whether slow `0` should be split in a later O13-level RTL/physical change.
- Whether the earlier Innovus 139 was fully eliminated by avoiding unsafe `dbGet` walks.

## Decision

Keep O12 phase isolation.  Do not switch to RTL load reduction now.  O12C should first quantify the corrected reports, audit candidate buffer input caps, and run a placement-constrained BUHDX4 experiment before trying one stronger buffer option.
