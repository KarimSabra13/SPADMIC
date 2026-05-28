# O1 Local Prep Checks

Run ID: `20260528_o1_prep_checks`
Branch: `SPADMIC_TOP`
HEAD at check time: `523dcb9dfd1d1b7a085b76a9c6b6d95d2582831b`

No Cadence tools were run locally.

## Checks

- `bash -n` on O1 locator/export/Genus/Innovus/Xcelium wrapper scripts: PASS
- `python3 -m py_compile` on existing O0/O1 parser/generator tools: PASS
- `git diff --check -- MPTDC docs/timing_closure tools`: PASS
- `tclsh` source smoke for `mptdc_freq_modes.defines` plus `mptdc_osc_pd_r800.sdc` with dummy design variables: PASS
- timing-path classifier smoke on O0 Genus `timing_violations.rpt`: PASS

## Notes

- Verilator was not run because no RTL behavior or packet schema changed.
- The R800 collateral changes STA/PnR timing variables only and is not calibration-safe until analog tune data is supplied.
- O1A wrappers are intentionally strict: they require real RO_tune4 LEF and block if the post-synthesis netlist does not bind to `RO_tune4`.
- Follow-up update: `server_export_ro_tune4_lef.sh` now uses `/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune4.lef` as the primary source LEF and can create a documented `RO_tune4` LEF-name alias from an internal `RO4_TUNE` macro name.
