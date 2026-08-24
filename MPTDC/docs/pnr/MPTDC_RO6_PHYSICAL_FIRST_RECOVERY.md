# MPTDC RO6 Physical-First Recovery

## Starting Point

The design has exactly two buffered debug outputs, `ro_slow_tap0_o` and
`ro_fast_tap0_o`, placed on the south edge on MET3. The last buffered PnR run
reached route with clean regular connectivity but failed with 18 real METTP
shorts. The markers were ordinary raw-phase and oscillator-control wires
crossing `RO_tune6` METTP blockages, not acceptable PG exceptions.

This recovery keeps ordinary and phase routing on MET1 through MET3 while still
allowing special VDD/VSS routing on METTP. It does not reuse the dirty route
checkpoint, hand-patch marker 57556, or stream GDS from a run with shorts.

## Acceptance Order

1. Reuse the latest buffered-tap Genus handoff; do not resynthesize.
2. Run a fresh strict simple-PG proof and require raw special connectivity zero.
3. Run a fresh physical-first PnR and require Innovus DRC, shorts, regular
   connectivity, special connectivity, and unrouted nets all zero.
4. Confirm the router command top layer is MET3 and both tap pins are present.
5. Restore only that clean `04_route.enc.dat` checkpoint and merge the real RO
   OA GDS.
6. Require zero base PVS DRC, zero density-enabled PVS DRC, then explicit LVS
   MATCH on the same hashed inputs.
7. Keep TC setup/hold/DRV separate. Full MMMC, characterized RO timing, PEX,
   IR/EM, and final tapeout remain outside this physical-first gate.

## Strict PG Proof

The commands are foreground-only. They avoid `set -e` and shell-level `exit`,
so a failed guard does not close an interactive SSH session.

```bash
set +e

cd /home/validmgr/ksabra/2026_SPAD/SPADMIC
source /eda/cadence/eda_2023-2024 2>/dev/null

export MPTDC_WORK_ROOT=/sim/ksabra/SPADMIC_work
export MPTDC_GENUS_WORK=$MPTDC_WORK_ROOT/genus
export MPTDC_INNOVUS_WORK=$MPTDC_WORK_ROOT/innovus

git checkout SPADMIC_test
git pull --ff-only origin SPADMIC_test

EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
echo "EXPECTED_HEAD=$EXPECTED_HEAD"

GENUS_DIR="$(ls -td "$MPTDC_GENUS_WORK"/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_* 2>/dev/null | sed -n '1p')"
GENUS_RUN="${GENUS_DIR##*/}"
HANDOFF_ROOT=$MPTDC_WORK_ROOT/handoff/genus_typical_pnrcompat
HANDOFF=$HANDOFF_ROOT/$GENUS_RUN

STOP=0
[ -n "$GENUS_DIR" ] || { echo "STOP: buffered Genus run not found"; STOP=1; }
[ -d "$GENUS_DIR" ] || { echo "STOP: missing Genus directory: $GENUS_DIR"; STOP=1; }

if [ "$STOP" -eq 0 ] && [ ! -d "$HANDOFF" ]; then
  MPTDC_GENUS_HANDOFF_ROOT="$HANDOFF_ROOT" \
  bash MPTDC/syn/scripts/package_genus_typical_handoff.sh "$GENUS_RUN"
  PACKAGE_RC=$?
elif [ "$STOP" -eq 0 ]; then
  PACKAGE_RC=0
else
  PACKAGE_RC=99
fi

if [ "$PACKAGE_RC" -eq 0 ]; then
  bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
    --genus-run-id "$GENUS_RUN" \
    --handoff-dir "$HANDOFF"
  PRE_PNR_RC=$?
else
  PRE_PNR_RC=99
fi

PG_RUN=$(date +%Y%m%d)_mptdc_bufftap0_simplepg_pgproof_$(date +%H%M%S)
PG_DIR=$MPTDC_INNOVUS_WORK/$PG_RUN

if [ "$PRE_PNR_RC" -eq 0 ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
    --run-id "$PG_RUN" \
    --stage pg_proof \
    --expected-head "$EXPECTED_HEAD" \
    --handoff-dir "$HANDOFF" \
    --genus-run-id "$GENUS_RUN" \
    --no-free-all \
    --local-phase-preplace \
    --strict-special-clean \
    --no-signal-top-route-blockage
  PG_RC=$?
else
  PG_RC=99
fi

echo "PACKAGE_RC=$PACKAGE_RC"
echo "PRE_PNR_RC=$PRE_PNR_RC"
echo "PG_RC=$PG_RC"
cat "$PG_DIR/reports/postplace_pre_route_sroute_status.rpt" 2>/dev/null
```

## Physical-First PnR

Continue in the same shell. The full route is a new Innovus process.

```bash
set +e

PG_RAW_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=//p' "$PG_DIR/reports/postplace_pre_route_sroute_status.rpt" 2>/dev/null | tail -1)"
PG_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=//p' "$PG_DIR/reports/postplace_pre_route_sroute_status.rpt" 2>/dev/null | tail -1)"

PNR_RUN=$(date +%Y%m%d)_mptdc_bufftap0_mettpfix_physical_$(date +%H%M%S)
PNR_DIR=$MPTDC_INNOVUS_WORK/$PNR_RUN

if [ "$PG_RC" -eq 0 ] && [ "$PG_RAW_BAD" = "0" ] && [ "$PG_BAD" = "0" ]; then
  bash MPTDC/pnr/scripts/server_run_mptdc_ro6_latestlef_simplepg.sh \
    --run-id "$PNR_RUN" \
    --stage full_closure \
    --expected-head "$EXPECTED_HEAD" \
    --handoff-dir "$HANDOFF" \
    --genus-run-id "$GENUS_RUN" \
    --no-free-all \
    --local-phase-preplace \
    --physical-first \
    --strict-special-clean \
    --post-filler-sroute \
    --no-signal-top-route-blockage
  PNR_RC=$?
else
  echo "STOP: strict PG proof did not pass; full route not launched"
  PNR_RC=99
fi

echo "PNR_RC=$PNR_RC"
echo "PNR_DIR=$PNR_DIR"

echo "===== route-layer intent ====="
grep -E '^(signal_top_layer|promote_signal_top_to_effective_floor|router_command_top_layer|keep_router_top_at_effective_floor)=' \
  "$PNR_DIR/reports/route_layer_intent.rpt" 2>/dev/null

echo "===== route status ====="
grep -E '^(ROUTE_STATUS|INNOVUS_VERIFY_DRC_STATUS|GEOMETRY_DRC_VIOLATIONS|SHORTS|REGULAR_NET_CONNECTIVITY_BAD|SPECIAL_NET_CONNECTIVITY_BAD|SPECIAL_NET_CONNECTIVITY_RAW_BAD|SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES|UNROUTED_NETS)=' \
  "$PNR_DIR/reports/route_status.rpt" 2>/dev/null

echo "===== TC timing and DRV ====="
cat "$PNR_DIR/reports/extracted_timing_status.rpt" 2>/dev/null
cat "$PNR_DIR/reports/drv_status.rpt" 2>/dev/null

echo "===== two buffered tap pins ====="
grep -nE 'ro_(slow|fast)_tap0_o' "$PNR_DIR/def/04_route.def" 2>/dev/null
```

Do not proceed unless `router_command_top_layer=MET3`, `ROUTE_STATUS=PASS`, all
DRC/connectivity counts above are zero, and the two tap names are present.

## PVS DRC and LVS

The historical `RO_GDS` below is the known real-OA export. Replace it if the
`RO_tune6` OA layout has changed. Never substitute the provisional no-RO top
GDS or a LEF-derived proxy.

```bash
set +e

SOURCE_CKPT=$PNR_DIR/checkpoints/04_route.enc.dat
RO_GDS=/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608/merge_libs/RO_tune6_from_OA.gds
PVS_RUN_ID=${PNR_RUN}_realro_pvs
PVS_DIR=$MPTDC_INNOVUS_WORK/$PVS_RUN_ID

ROUTE_PASS="$(sed -n 's/^ROUTE_STATUS=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
DRC_PASS="$(sed -n 's/^INNOVUS_VERIFY_DRC_STATUS=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
GEOMETRY_DRC="$(sed -n 's/^GEOMETRY_DRC_VIOLATIONS=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
SHORTS="$(sed -n 's/^SHORTS=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
REGULAR_BAD="$(sed -n 's/^REGULAR_NET_CONNECTIVITY_BAD=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
SPECIAL_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_BAD=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
SPECIAL_RAW_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_RAW_BAD=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
SPECIAL_NON_RO_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
UNROUTED="$(sed -n 's/^UNROUTED_NETS=//p' "$PNR_DIR/reports/route_status.rpt" 2>/dev/null | tail -1)"
ROUTER_TOP="$(sed -n 's/^router_command_top_layer=//p' "$PNR_DIR/reports/route_layer_intent.rpt" 2>/dev/null | tail -1)"

if [ "$PNR_RC" -eq 0 ] && \
   [ "$ROUTE_PASS" = "PASS" ] && \
   [ "$DRC_PASS" = "PASS" ] && \
   [ "$GEOMETRY_DRC" = "0" ] && \
   [ "$SHORTS" = "0" ] && \
   [ "$REGULAR_BAD" = "0" ] && \
   [ "$SPECIAL_BAD" = "0" ] && \
   [ "$SPECIAL_RAW_BAD" = "0" ] && \
   [ "$SPECIAL_NON_RO_BAD" = "0" ] && \
   [ "$UNROUTED" = "0" ] && \
   [ "$ROUTER_TOP" = "MET3" ] && \
   [ -d "$SOURCE_CKPT" ] && \
   [ -s "$RO_GDS" ]; then
  sha256sum "$RO_GDS"
  MPTDC/scripts/pvs/00_prepare_pvs_inputs_from_checkpoint.sh \
    --checkpoint "$SOURCE_CKPT" \
    --run-id "$PVS_RUN_ID" \
    --ro-gds "$RO_GDS" \
    --strict-attribution \
    --expected-head "$EXPECTED_HEAD"
  PREP_RC=$?
else
  echo "STOP: clean PnR checkpoint or real RO GDS missing"
  PREP_RC=99
fi

if [ "$PREP_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
    --result-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  AUDIT_RC=$?
else
  AUDIT_RC=99
fi

if [ "$AUDIT_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant base \
    --expected-head "$EXPECTED_HEAD"
  DRC_BASE_RC=$?
else
  DRC_BASE_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant density \
    --expected-head "$EXPECTED_HEAD"
  DRC_DENSITY_RC=$?
else
  DRC_DENSITY_RC=99
fi

if [ "$DRC_BASE_RC" -eq 0 ] && [ "$DRC_DENSITY_RC" -eq 0 ]; then
  MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD"
  LVS_RC=$?
else
  LVS_RC=99
fi

echo "PREP_RC=$PREP_RC"
echo "AUDIT_RC=$AUDIT_RC"
echo "DRC_BASE_RC=$DRC_BASE_RC"
echo "DRC_DENSITY_RC=$DRC_DENSITY_RC"
echo "LVS_RC=$LVS_RC"

cat "$PVS_DIR/reports/tap_pin_contract.rpt" 2>/dev/null
cat "$PVS_DIR/manifests/pvs_input_hashes.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_base_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_density_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_lvs_status.rpt" 2>/dev/null
```

No downstream GDS package is accepted if any gate is missing or nonzero. Even
when all physical-first gates pass, label the result TC-only and not final
tapeout signoff.
