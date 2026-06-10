# MPTDC Final Branch Review

Status: `SPADMIC_FINAL_PRE_GENUS_RUN`

Labels:

- `TYPICAL_ONLY_TAPEOUT_PACKAGE`
- `NOT_MMMC_SIGNOFF`
- `FINAL_SIGNOFF=NO`

## Checkout

- Branch: `SPADMIC_FINAL`
- Reviewed HEAD: `69d6537da351b5a16d99014a240d359d0e8c882b`
- Remote status at review time: `origin/SPADMIC_FINAL` up to date

## Repository Policy Audit

| Item | Status | Evidence |
|---|---|---|
| Stable MPTDC README | PASS | `MPTDC/README.md` |
| Standard generated-output root | PASS | `work/README.md` |
| Generated outputs ignored | PASS | top-level `.gitignore` and `MPTDC/.gitignore` |
| Active Genus wrapper | PASS | `MPTDC/syn/scripts/server_run_genus_mptdc_typical.sh` |
| Active Innovus wrapper | PASS_FOR_FEASIBILITY_ONLY | `MPTDC/pnr/scripts/server_run_innovus_mptdc_feasibility.sh` |
| Stable synthesis SDC aliases | PASS | `MPTDC/syn/inputs/mptdc_*.sdc` stable aliases |
| RO_tune4 macro abstracts | PASS | `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib` and related abstracts |
| XLIBD reference/config | PASS | `MPTDC/tech/xlibd/` and `MPTDC/pnr/config/xlibd_spadmic_typical_cell_values.tcl` |
| Active RTL files | PASS | `MPTDC/rtl/` remains present and unchanged in this hardening pass |
| Generated results tracked | PASS | generated result roots are not tracked; only `work/README.md` is tracked under generated roots |
| Local source-tree generated outputs | REVIEW | ignored legacy local directories still exist on this workstation under `results/` and `MPTDC/syn/{outputs,reports,logs,work}` |

The ignored local generated directories are analysis evidence only. They must not
be committed, and the hardened Genus wrapper now writes new output directly
under `work/genus/<RUN_ID>/`.

## Current Genus Evidence

The latest local compatibility evidence is validate-only. It confirms wrapper
input selection but does not prove timing closure because Genus was not launched:

- Run: `20260609_o13_abs5_source_fix_validate_only`
- Result: `validate_only`
- SDC command failure count: `0`
- Clock counts, PD endpoint counts, timing, and DRV: not proven in validate-only

The latest full local Genus package on disk is the R750_delta5 historical run:

- Run: `20260604_o9_final_typical_r750_delta5`
- Genus exit: `0`
- RO_tune4 count: `2`
- mptdc_osc_stub residue count: `0`
- raw RO clocks found in report: `16`
- Timing classification unknowns: `0`
- QoR: `clk_osc_fast` WNS about `-1.6 ps`, TNS about `-11.2 ps`, `7` violating paths
- DRV: max capacitance clean, max fanout clean, max transition violation total `1120`
- Worst real path family: fast-tag to PD timestamp capture

This historical run is useful for risk framing only. The next run must use the
stable `MPTDC_GENUS_TYPICAL` wrapper and the exact PD Vernier exception model.

## XLIBD Timing Reference

XLIBD values are `REFERENCE_ONLY_NOT_TIMING_ENGINE`.

Useful typical reference values:

- strict analog RO D-load budget: `58.72 fF`
- CN-like analog RO estimate: `75.59 fF`
- `BUHDX4` input cap: `10.56 fF`
- `BUHDX12` input cap: `32.24 fF`
- `BUHDX12` transition at about `0.6058 pF`: rise `0.3080 ns`, fall `0.2295 ns`
- `BUHDX12` transition at about `1.2106 pF`: rise `0.5955 ns`, fall `0.4391 ns`

Interpretation: keep `RO_tune4/S[n] -> BUHDX4 -> BUHDX12 -> phase fabric`.
Do not use XLIBD values to override Liberty, waive timing, or claim signoff.

## Genus Gate Before Innovus

Do not run Innovus implementation until the stable Genus run produces a reviewed
`work/genus/<RUN_ID>/final_typical_genus_readiness.md`.

The run must report either:

- `GENUS_TYPICAL_CLOSED`
- `GENUS_TYPICAL_REVIEW_REQUIRED`

Only `GENUS_TYPICAL_CLOSED` allows the implementation plan to start without a
targeted timing review.
