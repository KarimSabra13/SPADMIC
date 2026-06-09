# SPADMIC XLIBD Usage Rules

Status: `REFERENCE_ONLY_NOT_TIMING_ENGINE`

Use the XLIBD extraction as an engineering reference for SPADMIC decisions. Do not replace Liberty timing, Genus optimization, or Innovus timing with this table.

## Allowed Uses

- Explain RO load budgets in fF and DFF-equivalent load counts.
- Justify phase buffer topology choices before running expensive PNR experiments.
- Define provisional block-level IO load assumptions.
- Document reset recovery, removal, and min-pulse checks.
- Document scan-cell policy.
- Add report columns that make Innovus/Genus results easier to interpret.

## Not Allowed

- Do not relax Liberty max capacitance from this file.
- Do not modify RTL based only on this file.
- Do not change packet format, frequency, `nfast`, `nslow`, or `raw_lfsr_tag`.
- Do not broad false-path reset or CDC paths because a single extracted value is large.
- Do not claim signoff from this file.

## Config Layer

The selected values used by report scripts live in:

- [xlibd_spadmic_typical_cell_values.tcl](../../MPTDC/pnr/config/xlibd_spadmic_typical_cell_values.tcl)

The large raw extraction stays in:

- [xlibd_cell_values_spadmic_with_sdffq4.txt](../../MPTDC/tech/xlibd/xlibd_cell_values_spadmic_with_sdffq4.txt)

Report scripts should source the compact Tcl config and should not duplicate large tables.

## IO Load Classes

The provisional IO model uses `DFRRQHDX2 D_CAP = 3.20 fF`.

| Class | Equivalent D inputs | Load fF | Load pF |
|---|---:|---:|---:|
| `light` | 4 | 12.8 | 0.0128 |
| `medium` | 8 | 25.6 | 0.0256 |
| `heavy` | 16 | 51.2 | 0.0512 |
| `very_heavy` | 32 | 102.4 | 0.1024 |

For first block-level Innovus feasibility, use `medium` unless the integration expectation requires `heavy`. This is not a pad-level signoff load.

## Reporting Expectations

XLIBD-aware reports should include:

- Actual cap in fF.
- Ratio to strict RO budget and CN-like budget.
- Equivalent `DFRRQHDX2` D, C, and RN input counts.
- Driver cell type and XLIBD driver limits where known.
- Clear labels separating raw RO source load from final digital phase-driver output load.

## Relationship To O13 abs3

O13 abs3 clock/CDC repair remains the next gating Genus step. XLIBD documentation should not delay that run and should not change the O13 abs3 SDC.
