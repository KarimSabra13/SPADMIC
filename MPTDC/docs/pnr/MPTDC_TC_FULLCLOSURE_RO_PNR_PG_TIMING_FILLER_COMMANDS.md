# MPTDC TC Full-Closure RO PnR PG Timing Filler Commands

This is the next attempt after the RO_tune6 PnR access LEF removed the RO-local
route shorts. It is a TC-only physical closure attempt with strict PG, CTS,
route, post-route timing optimization, bounded Mar-only DRC continuation, and
final filler cleanup. It is not MMMC or foundry DRC/LVS signoff.

## Server Launch

Run foreground only:

```bash
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source .venv/bin/activate

git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test
export EXPECTED_HEAD="$(git rev-parse HEAD)"

export FINAL_LEF=/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef
export PNR_LEF=/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_macro_only_20260630_mptdc_ro_lef_access_patch_real_lef_nofiller_v2_20260630_174804.lef
export MPTDC_GENUS_HANDOFF_DIR=/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff
export MPTDC_GENUS_RUN_ID=MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233

bash MPTDC/pnr/scripts/server_run_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler.sh
```

The launcher prints `RUN_DIR=...` before Innovus starts. Keep that path for
inspection.

## Post-Run Inspection

After the run exits, inspect it with:

```bash
export RUN_DIR=/sim/ksabra/SPADMIC_work/innovus/<printed-run-id>

bash MPTDC/pnr/scripts/server_inspect_mptdc_tc_fullclosure.sh "$RUN_DIR"
```

The most important first checks are:

```bash
sed -n '1,220p' "$RUN_DIR/reports/route_status.rpt"
sed -n '1,220p' "$RUN_DIR/reports/pg_postroute_connectivity_status.rpt"
sed -n '1,260p' "$RUN_DIR/reports/postplace_pre_route_sroute_status.rpt"
sed -n '1,260p' "$RUN_DIR/reports/postroute_opt_status.rpt"
sed -n '1,220p' "$RUN_DIR/reports/extracted_timing_status.rpt"
sed -n '1,220p' "$RUN_DIR/reports/digital_pnr_signoff_status.rpt"
```

Expected improvement versus the focused no-filler run:

- `SHORTS=0` remains true.
- `ROUTE_DRC_REVIEW_CLASS_STATUS=PASS` is allowed only for `Mar`, capped at 5.
- `SPECIAL_CONNECTIVITY_BAD=0` after strict PG and postroute rechecks.
- `SETUP_STATUS_TC` and `TC_HOLD_STATUS` come from extracted post-route timing.
- `MPTDC_TC_PNR_CLOSURE=PASS` only if placement, PG, CTS, route, extraction, DRV,
  and TC setup/hold all close under the TC-only contract.
