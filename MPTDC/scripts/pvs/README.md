# MPTDC PVS Replay Flow

This directory contains reproducible wrappers for the MPTDC dryGDS/PVS DRC/LVS
debug path. The scripts intentionally replay GUI-generated `run.pvs` templates
instead of guessing low-level PVS command-line syntax.

## Source Checkpoint

For the current four-marker route issue, use the untouched route checkpoint:

```sh
export EXPECTED_HEAD=761cae1e1115479169f62ce021de4ad1b322abca
export FAILED_RUN_ID=20260707_mptdc_tc_ro6_coordproxy_free_digital_strict_130549
export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus
export SOURCE_CKPT=$MPTDC_INNOVUS_WORK/$FAILED_RUN_ID/checkpoints/04_route_failed.enc.dat
```

Do not use the manual MET1 patch checkpoint as a PVS source. That checkpoint has
real shorts and dangling-wire failures.

## Typical Server Sequence

```sh
cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024
source .venv/bin/activate 2>/dev/null || true

git checkout SPADMIC_test
git pull --ff-only
test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"

export PVS_RUN_ID=${FAILED_RUN_ID}_pvs_drc_reality_$(date +%Y%m%d_%H%M%S)

MPTDC/scripts/pvs/00_prepare_pvs_inputs_from_checkpoint.sh \
  --checkpoint "$SOURCE_CKPT" \
  --run-id "$PVS_RUN_ID" \
  --expected-head "$EXPECTED_HEAD"

export PVS_DIR="$MPTDC_INNOVUS_WORK/$PVS_RUN_ID"

MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
  --result-dir "$PVS_DIR" \
  --expected-head "$EXPECTED_HEAD"

MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
  --prepared-dir "$PVS_DIR" \
  --expected-head "$EXPECTED_HEAD"

sed -n '1,220p' "$PVS_DIR/reports/pvs_drc_status.rpt"
sed -n '1,260p' "$PVS_DIR/reports/pvs_drc_vs_innovus_mar4.rpt"
sed -n '1,260p' "$PVS_DIR/reports/pvs_drc_result_scan.txt"
```

Run LVS only after the DRC result is understood:

```sh
MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
  --prepared-dir "$PVS_DIR" \
  --expected-head "$EXPECTED_HEAD"

sed -n '1,220p' "$PVS_DIR/reports/pvs_lvs_status.rpt"
sed -n '1,320p' "$PVS_DIR/reports/pvs_lvs_result_scan.txt"
sed -n '1,120p' "$PVS_DIR/reports/pvs_lvs_SHORTSDB_rule_id.txt"
```

## Gates

- `PVS_REPRODUCES_INNOVUS_MAR4=YES`: fix the route/pin-access/root cause
  upstream. Do not hand-draw patch metal.
- `PVS_REPRODUCES_INNOVUS_MAR4=NO`: preserve the Innovus/PVS mismatch evidence
  and decide LVS continuation separately.
- Any PVS DRC/LVS fatal, missing GDS/source/HCell, stale old template path, or
  `/usr/sbin/pvs` path issue is a hard stop.

Final tapeout remains `NO` until PVS DRC/LVS, Innovus DRC/connectivity, timing,
and other deferred physical gates are independently clean.
