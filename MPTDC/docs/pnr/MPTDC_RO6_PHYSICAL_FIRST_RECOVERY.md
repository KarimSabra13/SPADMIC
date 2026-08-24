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

## Step Decisions and Evidence

Every executable step writes an `operator_gate_*.rpt` with either
`DECISION=PASS_CONTINUE` or `DECISION=FAIL_STOP`. Missing fields are failures.
Publish the snapshot even when a step fails; the failed reports and diagnostic
log tails are what make remote analysis possible.

| Step | Required to continue | Snapshot kind |
|---|---|---|
| Pre-PnR | package RC 0, pre-PnR RC 0, `PRE_PNR_GATE=PASS` | `genus` |
| Strict PG proof | wrapper RC 0, sroute PASS, special bad/raw bad/non-RO failures all 0 | `innovus` |
| Physical PnR | wrapper RC 0, router top MET3, route/DRC PASS, every DRC/connectivity/unrouted count 0, exactly two tap0 pins planned south on MET3 | `innovus` |
| PVS preparation | preparation PASS, strict attribution 1, tap contract PASS, tap count 2, hash manifest present | `pvs` |
| Template audit | audit RC 0 and `PVS_TEMPLATE_AUDIT_STATUS=PASS` | `pvs` |
| Base DRC | gate PASS, variant BASE, both report totals 0 | `pvs` |
| Density DRC | gate PASS, variant DENSITY, both report totals 0 | `pvs` |
| LVS | gate RC 0 and explicit `PVS_LVS_STATUS=MATCH` | `pvs` |

The collector copies small text reports, manifests, PVS controls, and filtered
diagnostic tails. It excludes checkpoints, databases, GDS/OAS, and DEF by
default, and skips text files larger than 2 MiB. Do not manually add those
excluded artifacts to Git.

## Recommended Short Server Commands

Use these commands for the next run. They replace the long manual blocks later
in this document. Each driver runs one fresh physical process, evaluates the
authoritative reports, writes an `operator_gate_*.rpt`, and publishes only the
bounded evidence directory. The PVS driver applies the same rule independently
to preparation, template audit, base DRC, density DRC, and LVS.

The many historical untracked files in the server checkout do not block these
commands. The drivers inspect tracked changes with
`git status --short --untracked-files=no`. Do not run `git add -A`, do not clean
the checkout, and do not add the historical untracked files.

### 0. Synchronize Once

```bash
set +e

REPO=/home/validmgr/ksabra/2026_SPAD/SPADMIC
SYNC_RC=99

if [ -d "$REPO/.git" ]; then
  cd "$REPO"
  git checkout SPADMIC_test
  git pull --ff-only origin SPADMIC_test
  SYNC_RC=$?
else
  echo "STOP: repository missing: $REPO"
fi

echo "SYNC_RC=$SYNC_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
echo "TRACKED_STATUS_BEGIN"
git status --short --untracked-files=no 2>/dev/null
echo "TRACKED_STATUS_END"
```

Continue only when `SYNC_RC=0` and there is no line between the two tracked
status markers. The drivers also enforce `SPADMIC_test` and require local HEAD
to match `origin/SPADMIC_test` when no explicit hash is supplied.

### 1. Strict PG Proof

```bash
set +e

bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
  --stage pg-proof \
  --genus-run-id MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623 \
  --handoff-dir /sim/ksabra/SPADMIC_work/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623

PG_DRIVER_RC=$?
echo "PG_DRIVER_RC=$PG_DRIVER_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

Pass requires all of these markers:

```text
CADENCE_ENV_STATUS=PASS
PG_DRIVER_RC=0
DECISION=PASS_CONTINUE
PUBLISH_RC=0
NEXT_STAGE=PHYSICAL_PNR
NEXT_REQUIRED_PG_RUN_ID=<new PG run id>
```

Save the printed `NEXT_REQUIRED_PG_RUN_ID`; it is the only value needed by the
next command. On any other result, stop. If `PUBLISH_RC=0`, send the run id and
printed HEAD so the pushed failure evidence can be reviewed remotely.

`RECOVERY_PREFLIGHT=PASS` alone does not mean Innovus launched. The driver must
next print `CADENCE_ENV_STATUS=PASS`. A missing status means the checkout still
has the older startup bug; `CADENCE_ENV_STATUS=FAIL` means the Cadence site
setup itself failed. In either case, stop before retrying.

### 2. Physical PnR

Replace only `REPLACE_WITH_PG_RUN_ID` with the value printed by step 1.

```bash
set +e

bash MPTDC/pnr/scripts/server_run_mptdc_ro6_recovery_stage.sh \
  --stage physical-pnr \
  --pg-run-id REPLACE_WITH_PG_RUN_ID \
  --genus-run-id MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623 \
  --handoff-dir /sim/ksabra/SPADMIC_work/handoff/genus_typical_pnrcompat/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_155623

PNR_DRIVER_RC=$?
echo "PNR_DRIVER_RC=$PNR_DRIVER_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

Pass requires:

```text
CADENCE_ENV_STATUS=PASS
PNR_DRIVER_RC=0
DECISION=PASS_CONTINUE
PUBLISH_RC=0
NEXT_STAGE=PVS
NEXT_REQUIRED_PNR_RUN_ID=<new physical PnR run id>
```

The driver independently requires router top `MET3`, zero Innovus DRC and
shorts, zero regular and special connectivity debt, zero unrouted nets, and
exactly the two south-edge MET3 buffered tap pins. It publishes a failed route
as evidence but never promotes it to PVS.

### 3. PVS Preparation, DRC, and LVS

Replace only `REPLACE_WITH_PNR_RUN_ID` with the value printed by step 2. The RO
GDS path below is the known real-OA export; stop and replace it if the OA layout
has changed since that export.

```bash
set +e

bash MPTDC/scripts/pvs/server_run_mptdc_ro6_recovery_pvs.sh \
  --pnr-run-id REPLACE_WITH_PNR_RUN_ID \
  --ro-gds /sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608/merge_libs/RO_tune6_from_OA.gds

PVS_DRIVER_RC=$?
echo "PVS_DRIVER_RC=$PVS_DRIVER_RC"
echo "HEAD=$(git rev-parse HEAD 2>/dev/null)"
```

The command stops at the first failed PVS gate. Full success requires:

```text
CADENCE_ENV_STATUS=PASS
PVS_DRIVER_RC=0
PVS_RECOVERY_STATUS=PASS
PVS_PREPARATION=PASS
PVS_TEMPLATE_AUDIT=PASS
PVS_DRC_BASE=PASS
PVS_DRC_DENSITY=PASS
PVS_LVS=MATCH
DECISION=PASS_CONTINUE
PUBLISH_RC=0
```

### What to Send After Each Command

Do not paste full Innovus or PVS logs into chat. Send only:

```text
STEP=<PG, PHYSICAL_PNR, or PVS>
RUN_ID=<NEXT_REQUIRED_*_RUN_ID or PVS_RUN_ID>
DRIVER_RC=<printed driver RC>
DECISION=<printed decision>
PUBLISH_RC=<printed publish RC, when present>
HEAD=<printed repository HEAD>
```

When publication succeeds, the pushed snapshot contains all authoritative
small reports and manifests plus filtered diagnostic log tails. The local GDS,
DEF, checkpoints, databases, and oversized full logs remain under `/sim`; they
are intentionally not pushed to Git. If publication itself fails, stop and send
the final `EVIDENCE_*` lines so the existing snapshot can be recovered without
rerunning the EDA stage.

The detailed blocks below remain as manual debugging reference. Do not mix
their shell variables with the short driver commands during a normal run.

### Reuse an Already Collected Snapshot

If collection succeeded but commit or push failed, do not recollect or rerun the
EDA step. After pulling any publisher fix, reuse the existing snapshot:

```bash
set +e

SNAPSHOT_KIND=genus
SNAPSHOT_ID=REPLACE_WITH_EXISTING_SNAPSHOT_DIRECTORY_NAME
SOURCE_DIR=REPLACE_WITH_ORIGINAL_HANDOFF_OR_RESULT_DIRECTORY
STEP_LABEL=PRE_PNR
SNAPSHOT_REL=MPTDC/docs/server_snapshots/$SNAPSHOT_KIND/$SNAPSHOT_ID

git restore --staged "$SNAPSHOT_REL" 2>/dev/null
git pull --ff-only origin SPADMIC_test

MPTDC_SNAPSHOT_REUSE_EXISTING=1 \
bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
  "$SNAPSHOT_KIND" "$SNAPSHOT_ID" "$SOURCE_DIR" "$STEP_LABEL"
RECOVERY_PUBLISH_RC=$?
EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"

echo "RECOVERY_PUBLISH_RC=$RECOVERY_PUBLISH_RC"
echo "NEXT_EXPECTED_HEAD=$EXPECTED_HEAD"
```

Generated reports are committed verbatim. Trailing whitespace in a Cadence
report is not a publication failure and is not altered.

## Strict PG Proof

The commands are foreground-only. They avoid `set -e` and shell-level `exit`,
so a failed guard does not close an interactive SSH session. Run all Bash
blocks below in the same SSH shell; the evidence helper and guarded state carry
forward between blocks.

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

TRACKED_STATUS="$(git status --short --untracked-files=no 2>/dev/null)"
if [ -n "$TRACKED_STATUS" ]; then
  echo "$TRACKED_STATUS"
  echo "STOP: tracked working tree is dirty"
fi

mptdc_publish_snapshot() {
  local snapshot_kind="$1"
  local snapshot_id="$2"
  local source_dir="$3"
  local step_label="$4"
  MPTDC_SNAPSHOT_MAX_TEXT_BYTES=2097152 \
  bash MPTDC/ci/publish_mptdc_server_snapshot.sh \
    "$snapshot_kind" "$snapshot_id" "$source_dir" "$step_label"
  local publish_rc=$?
  EXPECTED_HEAD="$(git rev-parse HEAD 2>/dev/null)"
  return "$publish_rc"
}

GENUS_DIR="$(ls -td "$MPTDC_GENUS_WORK"/MPTDC_TC_BufferedROTap0Pins_Genus_20260709_* 2>/dev/null | sed -n '1p')"
GENUS_RUN="${GENUS_DIR##*/}"
HANDOFF_ROOT=$MPTDC_WORK_ROOT/handoff/genus_typical_pnrcompat
HANDOFF=$HANDOFF_ROOT/$GENUS_RUN

STOP=0
[ -z "$TRACKED_STATUS" ] || STOP=1
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
  mkdir -p "$HANDOFF/reports"
  PRE_PNR_REPORT="$HANDOFF/reports/pre_pnr_gate_recheck.rpt"
  bash MPTDC/pnr/scripts/check_mptdc_pre_pnr_gate.sh \
    --genus-run-id "$GENUS_RUN" \
    --handoff-dir "$HANDOFF" \
    2>&1 | tee "$PRE_PNR_REPORT"
  PRE_PNR_RC=${PIPESTATUS[0]}
else
  PRE_PNR_REPORT="$HANDOFF/reports/pre_pnr_gate_recheck.rpt"
  PRE_PNR_RC=99
fi

PRE_PNR_STATUS="$(sed -n 's/^PRE_PNR_GATE=//p' "$PRE_PNR_REPORT" 2>/dev/null | tail -1)"
if [ "$PACKAGE_RC" -eq 0 ] && \
   [ "$PRE_PNR_RC" -eq 0 ] && \
   [ "$PRE_PNR_STATUS" = "PASS" ]; then
  PRE_PNR_DECISION=PASS_CONTINUE
else
  PRE_PNR_DECISION=FAIL_STOP
fi

if [ -d "$HANDOFF" ]; then
  mkdir -p "$HANDOFF/reports"
  {
    echo "STEP=PRE_PNR"
    echo "PACKAGE_RC=$PACKAGE_RC"
    echo "PRE_PNR_RC=$PRE_PNR_RC"
    echo "PRE_PNR_GATE=$PRE_PNR_STATUS"
    echo "DECISION=$PRE_PNR_DECISION"
  } | tee "$HANDOFF/reports/operator_gate_pre_pnr.rpt"
  PRE_PNR_SNAPSHOT_ID="${GENUS_RUN}_prepnr_$(date +%Y%m%d_%H%M%S)"
  mptdc_publish_snapshot genus "$PRE_PNR_SNAPSHOT_ID" "$HANDOFF" "PRE_PNR"
  PRE_PNR_PUBLISH_RC=$?
else
  echo "STOP: no handoff directory exists for evidence collection"
  PRE_PNR_PUBLISH_RC=99
fi

PG_RUN=$(date +%Y%m%d)_mptdc_bufftap0_simplepg_pgproof_$(date +%H%M%S)
PG_DIR=$MPTDC_INNOVUS_WORK/$PG_RUN

if [ "$PRE_PNR_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PRE_PNR_PUBLISH_RC" -eq 0 ]; then
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
echo "PRE_PNR_DECISION=$PRE_PNR_DECISION"
echo "PRE_PNR_PUBLISH_RC=$PRE_PNR_PUBLISH_RC"
echo "PG_RC=$PG_RC"
cat "$PG_DIR/reports/postplace_pre_route_sroute_status.rpt" 2>/dev/null

PG_STATUS_REPORT="$PG_DIR/reports/postplace_pre_route_sroute_status.rpt"
PG_SROUTE_STATUS="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SROUTE_STATUS=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_RAW_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"
PG_NON_RO_BAD="$(sed -n 's/^POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=//p' "$PG_STATUS_REPORT" 2>/dev/null | tail -1)"

if [ "$PG_RC" -eq 0 ] && \
   [ "$PG_SROUTE_STATUS" = "PASS" ] && \
   [ "$PG_RAW_BAD" = "0" ] && \
   [ "$PG_BAD" = "0" ] && \
   [ "$PG_NON_RO_BAD" = "0" ]; then
  PG_DECISION=PASS_CONTINUE
else
  PG_DECISION=FAIL_STOP
fi

if [ -d "$PG_DIR" ]; then
  mkdir -p "$PG_DIR/reports"
  {
    echo "STEP=STRICT_PG_PROOF"
    echo "PG_RC=$PG_RC"
    echo "POSTPLACE_PRE_ROUTE_SROUTE_STATUS=$PG_SROUTE_STATUS"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_BAD=$PG_BAD"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_RAW_BAD=$PG_RAW_BAD"
    echo "POSTPLACE_PRE_ROUTE_SPECIAL_CONNECTIVITY_NON_RO_FAILURES=$PG_NON_RO_BAD"
    echo "DECISION=$PG_DECISION"
  } | tee "$PG_DIR/reports/operator_gate_pg_proof.rpt"
  mptdc_publish_snapshot innovus "$PG_RUN" "$PG_DIR" "STRICT_PG_PROOF"
  PG_PUBLISH_RC=$?
else
  PG_PUBLISH_RC=99
fi

echo "PG_DECISION=$PG_DECISION"
echo "PG_PUBLISH_RC=$PG_PUBLISH_RC"
```

## Physical-First PnR

Continue in the same shell. The full route is a new Innovus process.

```bash
set +e

PNR_RUN=$(date +%Y%m%d)_mptdc_bufftap0_mettpfix_physical_$(date +%H%M%S)
PNR_DIR=$MPTDC_INNOVUS_WORK/$PNR_RUN

if [ "$PG_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PG_PUBLISH_RC" -eq 0 ]; then
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

ROUTE_REPORT="$PNR_DIR/reports/route_status.rpt"
ROUTE_INTENT_REPORT="$PNR_DIR/reports/route_layer_intent.rpt"
IO_PIN_SUMMARY="$PNR_DIR/reports/io_pin_placement_summary.md"
IO_PIN_CSV="$PNR_DIR/reports/io_pin_placement.csv"
ROUTE_PASS="$(sed -n 's/^ROUTE_STATUS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
DRC_PASS="$(sed -n 's/^INNOVUS_VERIFY_DRC_STATUS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
GEOMETRY_DRC="$(sed -n 's/^GEOMETRY_DRC_VIOLATIONS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SHORTS="$(sed -n 's/^SHORTS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
REGULAR_BAD="$(sed -n 's/^REGULAR_NET_CONNECTIVITY_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_RAW_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_RAW_BAD=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
SPECIAL_NON_RO_BAD="$(sed -n 's/^SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
UNROUTED="$(sed -n 's/^UNROUTED_NETS=//p' "$ROUTE_REPORT" 2>/dev/null | tail -1)"
ROUTER_TOP="$(sed -n 's/^router_command_top_layer=//p' "$ROUTE_INTENT_REPORT" 2>/dev/null | tail -1)"
IO_PIN_STATUS="$(sed -n 's/^REPORT_STATUS=//p' "$IO_PIN_SUMMARY" 2>/dev/null | tail -1)"
TAP_SLOW_SOUTH_PLAN_COUNT="$(awk -F, '$1 == "\"ro_slow_tap0_o\"" && $3 == "SOUTH" && $4 == "MET3" && $5 == "REQUESTED" {count++} END {print count + 0}' "$IO_PIN_CSV" 2>/dev/null)"
TAP_FAST_SOUTH_PLAN_COUNT="$(awk -F, '$1 == "\"ro_fast_tap0_o\"" && $3 == "SOUTH" && $4 == "MET3" && $5 == "REQUESTED" {count++} END {print count + 0}' "$IO_PIN_CSV" 2>/dev/null)"

ROUTE_DEF=""
for candidate in \
  "$PNR_DIR/def/04_route.def" \
  "$PNR_DIR/def/04_route_failed.def"
do
  if [ -s "$candidate" ]; then
    ROUTE_DEF="$candidate"
    break
  fi
done

TAP_SLOW_COUNT=0
TAP_FAST_COUNT=0
TAP_TOTAL_COUNT=0
if [ -n "$ROUTE_DEF" ]; then
  TAP_SLOW_COUNT="$(awk -v wanted=ro_slow_tap0_o '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 == wanted {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
  TAP_FAST_COUNT="$(awk -v wanted=ro_fast_tap0_o '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 == wanted {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
  TAP_TOTAL_COUNT="$(awk '
    /^PINS[[:space:]]/ {in_pins=1; next}
    /^END PINS/ {in_pins=0}
    in_pins && /^-[[:space:]]/ && $2 ~ /^ro_(slow|fast)_tap[0-9]+_o$/ {count++}
    END {print count + 0}
  ' "$ROUTE_DEF")"
fi

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
   [ "$IO_PIN_STATUS" = "OK" ] && \
   [ "$TAP_SLOW_SOUTH_PLAN_COUNT" = "1" ] && \
   [ "$TAP_FAST_SOUTH_PLAN_COUNT" = "1" ] && \
   [ "$TAP_SLOW_COUNT" = "1" ] && \
   [ "$TAP_FAST_COUNT" = "1" ] && \
   [ "$TAP_TOTAL_COUNT" = "2" ]; then
  PNR_DECISION=PASS_CONTINUE
else
  PNR_DECISION=FAIL_STOP
fi

if [ -d "$PNR_DIR" ]; then
  mkdir -p "$PNR_DIR/reports"
  {
    echo "ROUTE_DEF=$ROUTE_DEF"
    echo "ro_slow_tap0_o_COUNT=$TAP_SLOW_COUNT"
    echo "ro_fast_tap0_o_COUNT=$TAP_FAST_COUNT"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_TOTAL_COUNT"
    if [ -n "$ROUTE_DEF" ]; then
      awk '
        /^PINS[[:space:]]/ {in_pins=1; next}
        /^END PINS/ {in_pins=0}
        in_pins && /^-[[:space:]]/ {
          if (active) {print record}
          active=($2 == "ro_slow_tap0_o" || $2 == "ro_fast_tap0_o")
          record=$0
          next
        }
        in_pins && active {record=record " " $0}
        END {if (active) print record}
      ' "$ROUTE_DEF"
    fi
  } > "$PNR_DIR/reports/tap_pin_def_excerpt.rpt"

  {
    echo "STEP=PHYSICAL_PNR"
    echo "PNR_RC=$PNR_RC"
    echo "ROUTE_STATUS=$ROUTE_PASS"
    echo "INNOVUS_VERIFY_DRC_STATUS=$DRC_PASS"
    echo "GEOMETRY_DRC_VIOLATIONS=$GEOMETRY_DRC"
    echo "SHORTS=$SHORTS"
    echo "REGULAR_NET_CONNECTIVITY_BAD=$REGULAR_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_BAD=$SPECIAL_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_RAW_BAD=$SPECIAL_RAW_BAD"
    echo "SPECIAL_NET_CONNECTIVITY_NON_RO_FAILURES=$SPECIAL_NON_RO_BAD"
    echo "UNROUTED_NETS=$UNROUTED"
    echo "router_command_top_layer=$ROUTER_TOP"
    echo "IO_PIN_PLACEMENT_STATUS=$IO_PIN_STATUS"
    echo "ro_slow_tap0_o_SOUTH_MET3_PLAN_COUNT=$TAP_SLOW_SOUTH_PLAN_COUNT"
    echo "ro_fast_tap0_o_SOUTH_MET3_PLAN_COUNT=$TAP_FAST_SOUTH_PLAN_COUNT"
    echo "ro_slow_tap0_o_COUNT=$TAP_SLOW_COUNT"
    echo "ro_fast_tap0_o_COUNT=$TAP_FAST_COUNT"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_TOTAL_COUNT"
    echo "DECISION=$PNR_DECISION"
  } | tee "$PNR_DIR/reports/operator_gate_physical_pnr.rpt"

  mptdc_publish_snapshot innovus "$PNR_RUN" "$PNR_DIR" "PHYSICAL_PNR"
  PNR_PUBLISH_RC=$?
else
  PNR_PUBLISH_RC=99
fi

echo "PNR_RC=$PNR_RC"
echo "PNR_DIR=$PNR_DIR"
echo "PNR_DECISION=$PNR_DECISION"
echo "PNR_PUBLISH_RC=$PNR_PUBLISH_RC"

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
cat "$PNR_DIR/reports/tap_pin_def_excerpt.rpt" 2>/dev/null
```

Continue only when `PNR_DECISION=PASS_CONTINUE` and `PNR_PUBLISH_RC=0`.
TC timing and DRV remain separate evidence and do not turn a dirty physical
result into a pass.

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

if [ "$PNR_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PNR_PUBLISH_RC" -eq 0 ] && \
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

PREP_REPORT="$PVS_DIR/reports/pvs_prepared_inputs.rpt"
TAP_REPORT="$PVS_DIR/reports/tap_pin_contract.rpt"
HASH_REPORT="$PVS_DIR/manifests/pvs_input_hashes.rpt"
PREP_STATUS="$(sed -n 's/^PVS_PREP_INPUT_STATUS=//p' "$PREP_REPORT" 2>/dev/null | tail -1)"
TAP_STATUS="$(sed -n 's/^TAP_PIN_CONTRACT_STATUS=//p' "$TAP_REPORT" 2>/dev/null | tail -1)"
TAP_COUNT="$(sed -n 's/^RO_TAP_OBSERVABILITY_PIN_COUNT=//p' "$TAP_REPORT" 2>/dev/null | tail -1)"
STRICT_ATTRIBUTION="$(sed -n 's/^STRICT_ATTRIBUTION=//p' "$HASH_REPORT" 2>/dev/null | tail -1)"
if [ -s "$HASH_REPORT" ]; then
  HASH_MANIFEST_PRESENT=1
else
  HASH_MANIFEST_PRESENT=0
fi

if [ "$PREP_RC" -eq 0 ] && \
   [ "$PREP_STATUS" = "PASS" ] && \
   [ "$TAP_STATUS" = "PASS" ] && \
   [ "$TAP_COUNT" = "2" ] && \
   [ "$STRICT_ATTRIBUTION" = "1" ] && \
   [ "$HASH_MANIFEST_PRESENT" = "1" ]; then
  PREP_DECISION=PASS_CONTINUE
else
  PREP_DECISION=FAIL_STOP
fi

PREP_SNAPSHOT_ID="${PVS_RUN_ID}_01_prepare"
if [ -d "$PVS_DIR" ]; then
  mkdir -p "$PVS_DIR/reports"
  {
    echo "STEP=PVS_PREPARATION"
    echo "PREP_RC=$PREP_RC"
    echo "PVS_PREP_INPUT_STATUS=$PREP_STATUS"
    echo "TAP_PIN_CONTRACT_STATUS=$TAP_STATUS"
    echo "RO_TAP_OBSERVABILITY_PIN_COUNT=$TAP_COUNT"
    echo "STRICT_ATTRIBUTION=$STRICT_ATTRIBUTION"
    echo "HASH_MANIFEST_PRESENT=$HASH_MANIFEST_PRESENT"
    echo "DECISION=$PREP_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_prepare.rpt"
  mptdc_publish_snapshot pvs "$PREP_SNAPSHOT_ID" "$PVS_DIR" "PVS_PREPARATION"
  PREP_PUBLISH_RC=$?
else
  PREP_PUBLISH_RC=99
fi

AUDIT_LAUNCHED=0
if [ "$PREP_DECISION" = "PASS_CONTINUE" ] && \
   [ "$PREP_PUBLISH_RC" -eq 0 ]; then
  AUDIT_LAUNCHED=1
  MPTDC/scripts/pvs/01_audit_pvs_templates.sh \
    --result-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_template_audit.log"
  AUDIT_RC=${PIPESTATUS[0]}
else
  AUDIT_RC=99
fi

AUDIT_STATUS="$(sed -n 's/^PVS_TEMPLATE_AUDIT_STATUS=//p' "$PVS_DIR/manifests/pvs_template_audit.status" 2>/dev/null | tail -1)"
if [ "$AUDIT_LAUNCHED" -eq 1 ] && \
   [ "$AUDIT_RC" -eq 0 ] && \
   [ "$AUDIT_STATUS" = "PASS" ]; then
  AUDIT_DECISION=PASS_CONTINUE
else
  AUDIT_DECISION=FAIL_STOP
fi

AUDIT_SNAPSHOT_ID="${PVS_RUN_ID}_02_template_audit"
if [ "$AUDIT_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_TEMPLATE_AUDIT"
    echo "AUDIT_RC=$AUDIT_RC"
    echo "PVS_TEMPLATE_AUDIT_STATUS=$AUDIT_STATUS"
    echo "DECISION=$AUDIT_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_template_audit.rpt"
  mptdc_publish_snapshot pvs "$AUDIT_SNAPSHOT_ID" "$PVS_DIR" "PVS_TEMPLATE_AUDIT"
  AUDIT_PUBLISH_RC=$?
else
  AUDIT_PUBLISH_RC=99
fi

DRC_BASE_LAUNCHED=0
if [ "$AUDIT_DECISION" = "PASS_CONTINUE" ] && \
   [ "$AUDIT_PUBLISH_RC" -eq 0 ]; then
  DRC_BASE_LAUNCHED=1
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant base \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_drc_base.log"
  DRC_BASE_RC=${PIPESTATUS[0]}
else
  DRC_BASE_RC=99
fi

DRC_BASE_REPORT="$PVS_DIR/reports/pvs_drc_base_status.rpt"
DRC_BASE_STATUS="$(sed -n 's/^STATUS=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_GATE="$(sed -n 's/^PVS_DRC_STATUS=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_VARIANT="$(sed -n 's/^PVS_DRC_VARIANT=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_PRIMARY="$(sed -n 's/^DRC_TOTAL_PRIMARY=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
DRC_BASE_EXPANDED="$(sed -n 's/^DRC_TOTAL_EXPANDED=//p' "$DRC_BASE_REPORT" 2>/dev/null | tail -1)"
if [ "$DRC_BASE_LAUNCHED" -eq 1 ] && \
   [ "$DRC_BASE_RC" -eq 0 ] && \
   [ "$DRC_BASE_STATUS" = "PASS" ] && \
   [ "$DRC_BASE_GATE" = "PASS" ] && \
   [ "$DRC_BASE_VARIANT" = "BASE" ] && \
   [ "$DRC_BASE_PRIMARY" = "0" ] && \
   [ "$DRC_BASE_EXPANDED" = "0" ]; then
  DRC_BASE_DECISION=PASS_CONTINUE
else
  DRC_BASE_DECISION=FAIL_STOP
fi

DRC_BASE_SNAPSHOT_ID="${PVS_RUN_ID}_03_drc_base"
if [ "$DRC_BASE_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_DRC_BASE"
    echo "DRC_BASE_RC=$DRC_BASE_RC"
    echo "STATUS=$DRC_BASE_STATUS"
    echo "PVS_DRC_STATUS=$DRC_BASE_GATE"
    echo "PVS_DRC_VARIANT=$DRC_BASE_VARIANT"
    echo "DRC_TOTAL_PRIMARY=$DRC_BASE_PRIMARY"
    echo "DRC_TOTAL_EXPANDED=$DRC_BASE_EXPANDED"
    echo "DECISION=$DRC_BASE_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_drc_base.rpt"
  mptdc_publish_snapshot pvs "$DRC_BASE_SNAPSHOT_ID" "$PVS_DIR" "PVS_DRC_BASE"
  DRC_BASE_PUBLISH_RC=$?
else
  DRC_BASE_PUBLISH_RC=99
fi

DRC_DENSITY_LAUNCHED=0
if [ "$DRC_BASE_DECISION" = "PASS_CONTINUE" ] && \
   [ "$DRC_BASE_PUBLISH_RC" -eq 0 ]; then
  DRC_DENSITY_LAUNCHED=1
  MPTDC/scripts/pvs/02_replay_pvs_drc_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --variant density \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_drc_density.log"
  DRC_DENSITY_RC=${PIPESTATUS[0]}
else
  DRC_DENSITY_RC=99
fi

DRC_DENSITY_REPORT="$PVS_DIR/reports/pvs_drc_density_status.rpt"
DRC_DENSITY_STATUS="$(sed -n 's/^STATUS=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_GATE="$(sed -n 's/^PVS_DRC_STATUS=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_VARIANT="$(sed -n 's/^PVS_DRC_VARIANT=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_PRIMARY="$(sed -n 's/^DRC_TOTAL_PRIMARY=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
DRC_DENSITY_EXPANDED="$(sed -n 's/^DRC_TOTAL_EXPANDED=//p' "$DRC_DENSITY_REPORT" 2>/dev/null | tail -1)"
if [ "$DRC_DENSITY_LAUNCHED" -eq 1 ] && \
   [ "$DRC_DENSITY_RC" -eq 0 ] && \
   [ "$DRC_DENSITY_STATUS" = "PASS" ] && \
   [ "$DRC_DENSITY_GATE" = "PASS" ] && \
   [ "$DRC_DENSITY_VARIANT" = "DENSITY" ] && \
   [ "$DRC_DENSITY_PRIMARY" = "0" ] && \
   [ "$DRC_DENSITY_EXPANDED" = "0" ]; then
  DRC_DENSITY_DECISION=PASS_CONTINUE
else
  DRC_DENSITY_DECISION=FAIL_STOP
fi

DRC_DENSITY_SNAPSHOT_ID="${PVS_RUN_ID}_04_drc_density"
if [ "$DRC_DENSITY_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_DRC_DENSITY"
    echo "DRC_DENSITY_RC=$DRC_DENSITY_RC"
    echo "STATUS=$DRC_DENSITY_STATUS"
    echo "PVS_DRC_STATUS=$DRC_DENSITY_GATE"
    echo "PVS_DRC_VARIANT=$DRC_DENSITY_VARIANT"
    echo "DRC_TOTAL_PRIMARY=$DRC_DENSITY_PRIMARY"
    echo "DRC_TOTAL_EXPANDED=$DRC_DENSITY_EXPANDED"
    echo "DECISION=$DRC_DENSITY_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_drc_density.rpt"
  mptdc_publish_snapshot pvs "$DRC_DENSITY_SNAPSHOT_ID" "$PVS_DIR" "PVS_DRC_DENSITY"
  DRC_DENSITY_PUBLISH_RC=$?
else
  DRC_DENSITY_PUBLISH_RC=99
fi

LVS_LAUNCHED=0
if [ "$DRC_DENSITY_DECISION" = "PASS_CONTINUE" ] && \
   [ "$DRC_DENSITY_PUBLISH_RC" -eq 0 ]; then
  LVS_LAUNCHED=1
  MPTDC/scripts/pvs/03_replay_pvs_lvs_from_template.sh \
    --prepared-dir "$PVS_DIR" \
    --expected-head "$EXPECTED_HEAD" \
    2>&1 | tee "$PVS_DIR/logs/operator_lvs.log"
  LVS_RC=${PIPESTATUS[0]}
else
  LVS_RC=99
fi

LVS_REPORT="$PVS_DIR/reports/pvs_lvs_status.rpt"
LVS_STATUS="$(sed -n 's/^STATUS=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
LVS_GATE="$(sed -n 's/^PVS_LVS_STATUS=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
LVS_TOOL_RC="$(sed -n 's/^PVS_RC=//p' "$LVS_REPORT" 2>/dev/null | tail -1)"
if [ "$LVS_LAUNCHED" -eq 1 ] && \
   [ "$LVS_RC" -eq 0 ] && \
   [ "$LVS_STATUS" = "PASS" ] && \
   [ "$LVS_GATE" = "MATCH" ] && \
   [ "$LVS_TOOL_RC" = "0" ]; then
  LVS_DECISION=PASS_CONTINUE
else
  LVS_DECISION=FAIL_STOP
fi

LVS_SNAPSHOT_ID="${PVS_RUN_ID}_05_lvs"
if [ "$LVS_LAUNCHED" -eq 1 ]; then
  {
    echo "STEP=PVS_LVS"
    echo "LVS_RC=$LVS_RC"
    echo "STATUS=$LVS_STATUS"
    echo "PVS_LVS_STATUS=$LVS_GATE"
    echo "PVS_RC=$LVS_TOOL_RC"
    echo "DECISION=$LVS_DECISION"
  } | tee "$PVS_DIR/reports/operator_gate_pvs_lvs.rpt"
  mptdc_publish_snapshot pvs "$LVS_SNAPSHOT_ID" "$PVS_DIR" "PVS_LVS"
  LVS_PUBLISH_RC=$?
else
  LVS_PUBLISH_RC=99
fi

echo "PREP_RC=$PREP_RC"
echo "PREP_DECISION=$PREP_DECISION"
echo "PREP_PUBLISH_RC=$PREP_PUBLISH_RC"
echo "AUDIT_RC=$AUDIT_RC"
echo "AUDIT_DECISION=$AUDIT_DECISION"
echo "AUDIT_PUBLISH_RC=$AUDIT_PUBLISH_RC"
echo "DRC_BASE_RC=$DRC_BASE_RC"
echo "DRC_BASE_DECISION=$DRC_BASE_DECISION"
echo "DRC_BASE_PUBLISH_RC=$DRC_BASE_PUBLISH_RC"
echo "DRC_DENSITY_RC=$DRC_DENSITY_RC"
echo "DRC_DENSITY_DECISION=$DRC_DENSITY_DECISION"
echo "DRC_DENSITY_PUBLISH_RC=$DRC_DENSITY_PUBLISH_RC"
echo "LVS_RC=$LVS_RC"
echo "LVS_DECISION=$LVS_DECISION"
echo "LVS_PUBLISH_RC=$LVS_PUBLISH_RC"

cat "$PVS_DIR/reports/tap_pin_contract.rpt" 2>/dev/null
cat "$PVS_DIR/manifests/pvs_input_hashes.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_base_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_drc_density_status.rpt" 2>/dev/null
cat "$PVS_DIR/reports/pvs_lvs_status.rpt" 2>/dev/null
```

## What to Send for Review

Do not paste full Innovus or PVS logs into chat. After a step returns, send only
the five lines below, using the values printed by that step:

```text
STEP=STRICT_PG_PROOF
DECISION=PASS_CONTINUE
EVIDENCE_ID=20260824_mptdc_bufftap0_simplepg_pgproof_123456
EVIDENCE_COMMIT=<commit printed by mptdc_publish_snapshot>
EVIDENCE_PUSH_RC=0
```

Use the matching step name and decision for pre-PnR, physical PnR, preparation,
template audit, base DRC, density DRC, or LVS. `EVIDENCE_PUSH_RC=0` means the
text evidence is on `origin/SPADMIC_test` and can be pulled for detailed review.
The snapshot contains the operator gate, status reports, manifests, small PVS
controls, and diagnostic log tails.

- Continue only when both `DECISION=PASS_CONTINUE` and the matching
  `*_PUBLISH_RC=0` are printed.
- On `DECISION=FAIL_STOP`, let the failed snapshot push complete, send the five
  lines above, and do not launch the next command.
- On a nonzero publish RC, stop and paste the final `EVIDENCE_*` lines because
  the reports are not yet available remotely.
- Never run `git add .`; the helper stages and commits only its one snapshot
  directory and updates `EXPECTED_HEAD` for the next guarded command.

No downstream GDS package is accepted if any gate is missing or nonzero. Even
when all physical-first gates pass, label the result TC-only and not final
tapeout signoff.
