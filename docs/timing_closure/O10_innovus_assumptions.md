# O10 Innovus Assumptions

## Status

O10 is a first Innovus typical feasibility and visualization run.

Labels:

- `O10_INNOVUS_TYPICAL_FEASIBILITY`
- `NOT_MMMC_SIGNOFF`
- `NOT_FINAL_SIGNOFF`
- `NOT_TAPEOUT_READY`

## Inputs

- Branch: `SPADMIC_localtag`.
- Starting local HEAD: `1ee8e7101a7f263998b63cc736dfa38018e4e4ba`.
- Genus source run: `results/genus_osc_pd/20260604_o9_final_typical_r750_delta5`.
- Netlist: `mptdc_top_asic.postsyn.v` from the O9 result directory.
- Post-synth SDC: `mptdc_top_asic.postsyn.sdc` from the O9 result directory.
- O9 overlay: `MPTDC/syn/inputs/mptdc_osc_typical_r750_delta5.sdc`.
- RO_tune4 LEF: `results/osc_pd/20260528_o1_export_ro_tune4_lef/real_abstract_lef/RO_tune4_real_abstract.lef`.
- RO_tune4 Liberty shell: `MPTDC/syn/macros/RO_tune4_real_abstract_shell.lib`.
- Standard-cell Liberty: XFAB D_CELLS_HD typical 1.8 V / 25 C.

## Physical Defaults

- Core utilization: `0.60`.
- Placement max density: `0.70`.
- Signal route range: MET1 through MET3.
- Phase route exception: report/review possible METTP use, but do not claim matched phase-route signoff.
- RO macro halo: 10 um.
- PD-to-RO gap: 20 um.
- PD matrix nominal region: 300 um x 300 um unless O10 sizing logic scales it.
- Backend digital island: right side of core.

## RO_tune4 Physical Contract

From the committed LEF:

- Macro: `RO_tune4`.
- Size: `176.675 BY 67.17` um.
- Symmetry: `X Y R90`.
- Phase pins: `S[0:7]`, MET2.
- Power pins: `VDD`, `VSS`, `vdd!`.

Assumptions:

- Slow and fast macros use the same `RO_tune4`.
- `vdd!` is connected to `VDD`.
- RO macros share the standard `VDD/VSS` rails for first feasibility.
- No separate analog supply grid is implemented in O10.

## Timing Defaults

- Slow period: 1.430 ns.
- Fast period: 1.333 ns.
- Slow tap step: 0.079 ns.
- Fast tap step: 0.074 ns.
- RO setup uncertainty: 0.010 ns.
- RO hold uncertainty: 0.005 ns.
- `clk_sys`: 6.250 ns.
- MMMC: disabled for first feasibility; use typical-only analysis.

## Risk Notes

- O9 Genus is near clean, not clean: WNS -1.6 ps, TNS -11.2 ps, 7 setup paths.
- O9 characterization detailed compact metrics are not committed locally, so `O9_CHARACTERIZATION_PASS` is not claimed.
- RO_tune4 Liberty remains a shell; macro internal timing/electrical behavior is not signoff.
- Screenshot-derived oscillator model remains provisional.
