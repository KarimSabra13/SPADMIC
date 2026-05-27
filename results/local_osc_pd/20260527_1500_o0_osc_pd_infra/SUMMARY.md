# Local O0 Oscillator/PD Infrastructure Check

- Run ID: `20260527_1500_o0_osc_pd_infra`
- Branch: `SPADMIC_TOP`
- Base HEAD before O0 commit: `bd812c966ab4004ab5fa98dfc5faed277db51ee4`
- Cadence tools run locally: no
- RTL modified: no

## Checks Run

- `python3 tools/osc/gen_osc_macro_views.py --template tools/osc/oscillator_macro_template.yaml --out-dir MPTDC/syn/macros`
- `python3 -m py_compile tools/osc/gen_osc_macro_views.py tools/timing/analyze_pd_instance_symmetry.py tools/timing/analyze_pd_phase_routes.py tools/timing/analyze_osc_tap_loads.py tools/timing/classify_mptdc_timing_paths.py`
- `bash -n MPTDC/syn/scripts/server_run_genus_osc_pd_signoff.sh MPTDC/pnr/scripts/server_run_innovus_osc_pd_signoff.sh`
- `tclsh` source check for the new O0 Tcl helper scripts
- `python3 tools/timing/classify_mptdc_timing_paths.py results/genus/20260527_1200_h1b_count_eval_split_genus/timing_violations.rpt --out-csv /tmp/o0_class.csv --out-summary /tmp/o0_class.md`

## Result

- Python syntax: PASS
- Shell syntax: PASS
- Tcl parse/source check: PASS
- Timing classifier smoke: PASS, parsed 200 existing H1b timing paths
- Verilator: not run; no RTL changed
- Genus/Innovus/Xcelium: not run locally

## Signoff Status

PROVISIONAL PHYSICAL/TIMING COLLATERAL ONLY.  The O0 scripts still require lab
server Genus/Innovus runs and real analog macro handoff data.
