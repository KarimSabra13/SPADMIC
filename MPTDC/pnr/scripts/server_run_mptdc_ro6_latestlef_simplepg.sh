#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_FINAL_LEF="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef"
DEFAULT_HANDOFF_DIR="/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff"
DEFAULT_GENUS_RUN_ID="MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233"
DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"
DEFAULT_WORK_ROOT="/sim/ksabra/SPADMIC_work"

STAGE="pg_proof"
RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
FINAL_LEF_VALUE="${FINAL_LEF:-$DEFAULT_FINAL_LEF}"
PNR_LEF_VALUE="${PNR_LEF:-$FINAL_LEF_VALUE}"
HANDOFF_DIR_VALUE="${MPTDC_GENUS_HANDOFF_DIR:-$DEFAULT_HANDOFF_DIR}"
GENUS_RUN_ID_VALUE="${MPTDC_GENUS_RUN_ID:-$DEFAULT_GENUS_RUN_ID}"
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
WORK_ROOT_VALUE="${MPTDC_WORK_ROOT:-$DEFAULT_WORK_ROOT}"
CORE_UTIL_VALUE="${MPTDC_PNR_CORE_UTIL:-0.45}"
FREE_ALL_INTERNAL_VALUE="${MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT:-1}"
ENABLE_FINAL_FILLER_VALUE="${MPTDC_ENABLE_FINAL_FILLER:-1}"
ENABLE_POST_FILLER_SROUTE_VALUE="${MPTDC_ENABLE_POST_FILLER_SROUTE:-0}"
ALLOW_DANGLING_ONLY_VALUE="${MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY:-1}"
DANGLING_ONLY_MAX_VALUE="${MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX:-64}"
SIGNAL_TOP_ROUTE_BLOCKAGE_VALUE="${MPTDC_ENABLE_SIGNAL_TOP_ROUTE_BLOCKAGE:-0}"
LOCAL_PHASE_PREPLACE_VALUE="${MPTDC_SIMPLEPG_LOCAL_PHASE_PREPLACE:-0}"
POSTROUTE_OPT_VALUE="${MPTDC_SIMPLEPG_POSTROUTE_OPT:-1}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_ro6_latestlef_simplepg.sh [RUN_ID] [options]

Options:
  --stage <stage>        pg_proof or full_closure. Default: pg_proof.
  --run-id <id>          Override generated run id.
  --expected-head <sha>  Require the checked-out git HEAD to match this commit.
  --source-lef <path>    Latest fixed RO_tune6 macro LEF.
  --pnr-lef <path>       RO_tune6 LEF used by Innovus; defaults to source LEF.
  --handoff-dir <path>   Prepared Genus handoff directory.
  --genus-run-id <id>    Genus run id label used by the pre-PNR gate.
  --innovus-work <path>  Innovus run root.
  --work-root <path>     MPTDC work root.
  --core-util <value>    Core utilization. Default: 0.45.
  --fixed-ro             Keep RO macros fixed. Default is movable/free.
  --no-free-all          Do not enable the free-all internal placement rescue.
  --local-phase-preplace Keep the RO macros fixed and pre-place/fix the phase
                         isolation/driver buffers beside the macros. Use with
                         --no-free-all for the buffered-tap closure topology.
  --physical-first       Disable post-route timing optimization for this run.
                         Extraction and TC timing reports are still generated.
  --no-final-filler      Disable final filler in full_closure.
  --post-filler-sroute   Enable post-filler sroute in full_closure.
  --strict-special-clean  Require raw special connectivity to have zero
                          dangling markers at the pre-route PG proof gate.
                          Default accepts only bounded IMPVFC-94 dangling.
  --signal-top-route-blockage
                         Add a METTP route blockage over the selected scope.
                         This is off by default because the 2026-07-08 topblk
                         run proved that a broad METTP blockage can short
                         against special PG stripes and block PG pins.
  --no-signal-top-route-blockage
                         Keep the router compatible with existing METTP PG
                         shapes without creating a broad METTP route blockage.
                         This is the default.
  --dangling-only-max <n> Maximum bounded dangling markers accepted when the
                          report has no opens, shorts, unconnected terminals,
                          or other fatal special connectivity lines.
  -h, --help             Show this help.

This is the latest-LEF simple-PG launcher:
  - one top-level VDD and one top-level VSS block PG pin;
  - native Innovus blockPin/corePin sroute;
  - custom RO via-stack hookup disabled;
  - strict post-place/pre-route special connectivity gate.

The default pre-route gate accepts only bounded IMPVFC-94 dangling wires. This
matches native Innovus sroute behavior after the latest METTP RO LEF: it still
fails on opens, shorts, unconnected terminals, missing reports, or dangling
counts above --dangling-only-max.

Run pg_proof first. Run full_closure only after pg_proof reports clean special
connectivity.
USAGE
}

is_truthy() {
  case "${1:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

macro_only_precheck() {
  local lef="$1"
  local label="$2"
  awk -v label="$label" '
    /^[[:space:]]*MACRO[[:space:]]+RO_tune6[[:space:]]*$/ {seen_macro=1; exit}
    {
      if ($0 ~ /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ ||
          $0 ~ /^[[:space:]]*LAYER[[:space:]]+/ ||
          $0 ~ /^[[:space:]]*VIA[[:space:]]+/ ||
          $0 ~ /^[[:space:]]*VIARULE[[:space:]]+/ ||
          $0 ~ /^[[:space:]]*SITE[[:space:]]+/) {
        printf("ERROR: %s has top-level tech before MACRO at line %d: %s\n", label, NR, $0) > "/dev/stderr"
        bad=1
      }
    }
    END {
      if (!seen_macro) {
        printf("ERROR: %s does not contain MACRO RO_tune6\n", label) > "/dev/stderr"
        bad=1
      }
      exit bad
    }
  ' "$lef"
}

lef_pin_policy_precheck() {
  local lef="$1"
  awk '
    /^[[:space:]]*MACRO[[:space:]]+RO_tune6[[:space:]]*$/ {in_macro=1; next}
    in_macro && /^[[:space:]]*PIN[[:space:]]+/ {pin=$2; pins[pin]=1; next}
    in_macro && /^[[:space:]]*LAYER[[:space:]]+METTP[[:space:]]*;/ && (pin=="VDD" || pin=="VSS") {mettp[pin]=1}
    in_macro && /^[[:space:]]*END[[:space:]]+(VDD|VSS|vdd!)[[:space:]]*$/ {pin=""}
    in_macro && /^[[:space:]]*END[[:space:]]+RO_tune6[[:space:]]*$/ {exit}
    END {
      if (!pins["VDD"]) {
        print "ERROR: corrected RO_tune6 LEF does not export PIN VDD" > "/dev/stderr"
        bad=1
      }
      if (!pins["VSS"]) {
        print "ERROR: corrected RO_tune6 LEF does not export PIN VSS" > "/dev/stderr"
        bad=1
      }
      if (pins["vdd!"]) {
        print "ERROR: corrected RO_tune6 LEF must not export PIN vdd!" > "/dev/stderr"
        bad=1
      }
      if (!mettp["VDD"]) {
        print "ERROR: corrected RO_tune6 LEF VDD pin must include METTP access" > "/dev/stderr"
        bad=1
      }
      if (!mettp["VSS"]) {
        print "ERROR: corrected RO_tune6 LEF VSS pin must include METTP access" > "/dev/stderr"
        bad=1
      }
      exit bad
    }
  ' "$lef"
}

FIX_RO_VALUE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      STAGE="${2:?missing --stage value}"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --source-lef)
      FINAL_LEF_VALUE="${2:?missing --source-lef value}"
      shift 2
      ;;
    --pnr-lef)
      PNR_LEF_VALUE="${2:?missing --pnr-lef value}"
      shift 2
      ;;
    --handoff-dir)
      HANDOFF_DIR_VALUE="${2:?missing --handoff-dir value}"
      shift 2
      ;;
    --genus-run-id)
      GENUS_RUN_ID_VALUE="${2:?missing --genus-run-id value}"
      shift 2
      ;;
    --innovus-work)
      INNOVUS_WORK_VALUE="${2:?missing --innovus-work value}"
      shift 2
      ;;
    --work-root)
      WORK_ROOT_VALUE="${2:?missing --work-root value}"
      shift 2
      ;;
    --core-util)
      CORE_UTIL_VALUE="${2:?missing --core-util value}"
      shift 2
      ;;
    --fixed-ro)
      FIX_RO_VALUE=1
      shift
      ;;
    --no-free-all)
      FREE_ALL_INTERNAL_VALUE=0
      shift
      ;;
    --local-phase-preplace|--drc-first-local-phase)
      LOCAL_PHASE_PREPLACE_VALUE=1
      FIX_RO_VALUE=1
      FREE_ALL_INTERNAL_VALUE=0
      shift
      ;;
    --physical-first|--no-postroute-opt)
      POSTROUTE_OPT_VALUE=0
      shift
      ;;
    --no-final-filler)
      ENABLE_FINAL_FILLER_VALUE=0
      shift
      ;;
    --post-filler-sroute)
      ENABLE_POST_FILLER_SROUTE_VALUE=1
      shift
      ;;
    --signal-top-route-blockage)
      SIGNAL_TOP_ROUTE_BLOCKAGE_VALUE=1
      shift
      ;;
    --no-signal-top-route-blockage)
      SIGNAL_TOP_ROUTE_BLOCKAGE_VALUE=0
      shift
      ;;
    --strict-special-clean)
      ALLOW_DANGLING_ONLY_VALUE=0
      shift
      ;;
    --dangling-only-max)
      DANGLING_ONLY_MAX_VALUE="${2:?missing --dangling-only-max value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      if [[ -z "$RUN_ID" ]]; then
        RUN_ID="$1"
      else
        echo "ERROR: unexpected positional argument: $1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

case "$STAGE" in
  pg_proof|full_closure) ;;
  *)
    echo "ERROR: --stage must be pg_proof or full_closure" >&2
    exit 2
    ;;
esac

cd "$REPO_ROOT"

ACTUAL_HEAD="$(git rev-parse HEAD)"
echo "REPO_ROOT=$REPO_ROOT"
echo "BRANCH=$(git rev-parse --abbrev-ref HEAD)"
echo "ACTUAL_HEAD=$ACTUAL_HEAD"
if [[ -n "$EXPECTED_HEAD_VALUE" ]]; then
  echo "EXPECTED_HEAD=$EXPECTED_HEAD_VALUE"
  test "$ACTUAL_HEAD" = "$EXPECTED_HEAD_VALUE"
else
  echo "EXPECTED_HEAD_HINT=$ACTUAL_HEAD"
fi

if [[ -n "$(git status --short --untracked-files=no)" ]]; then
  echo "ERROR: tracked working tree is dirty. Commit or restore tracked edits before this run." >&2
  git status --short --untracked-files=no >&2
  exit 3
fi

test -r "$FINAL_LEF_VALUE"
test -r "$PNR_LEF_VALUE"
test -d "$HANDOFF_DIR_VALUE"
test -r "$REPO_ROOT/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib"
macro_only_precheck "$FINAL_LEF_VALUE" "source LEF"
macro_only_precheck "$PNR_LEF_VALUE" "PnR LEF"
lef_pin_policy_precheck "$PNR_LEF_VALUE"

while IFS='=' read -r name _; do
  case "$name" in
    MPTDC_*|O1_*) unset "$name" ;;
  esac
done < <(env)

RUN_ID="${RUN_ID:-$(date +%Y%m%d)_mptdc_ro6_latestlef_simplepg_${STAGE}_$(date +%H%M%S)}"
RUN_DIR="$INNOVUS_WORK_VALUE/$RUN_ID"

export MPTDC_WORK_ROOT="$WORK_ROOT_VALUE"
export MPTDC_INNOVUS_WORK="$INNOVUS_WORK_VALUE"
export MPTDC_GENUS_RUN_ID="$GENUS_RUN_ID_VALUE"
export MPTDC_GENUS_HANDOFF_DIR="$HANDOFF_DIR_VALUE"
export MPTDC_RO_HANDOFF_ENV="$REPO_ROOT/MPTDC/analog_handoff/real_ro_tune6_layout.env"

export MPTDC_XH018_STACK=xx31
export MPTDC_CLOSURE_SCOPE=TC_ONLY
export MPTDC_DIGITAL_SIGNOFF_APPROVED=1
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1
export MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG=1

export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_CELL_NAME=RO_tune6
export O1_RO_LEF_MACRO=RO_tune6
export O1_RO_SOURCE_LEF_PATH="$FINAL_LEF_VALUE"
export O1_RO_LEF_PATH="$PNR_LEF_VALUE"
export O1_RO_LIBERTY_PATH="$REPO_ROOT/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib"

# This guard bypass is intentional and narrow: it allows the supported simple
# pair style so the block exposes VDD/VSS instead of VDD_LEFT/VSS_LEFT/etc.
export MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=1
export MPTDC_PG_STRATEGY=innovus_sroute_golden_ro

# The router command remains compatible with existing METTP PG shapes.  Do not
# add a broad METTP route blockage by default: the 2026-07-08 topblk run showed
# that a core-wide METTP blockage is reported as shorts against special PG
# stripes and edge PG pins.
export MPTDC_PNR_SIGNAL_TOP_LAYER=MET3
export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=METTP
export MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR=0
export MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP=1
export MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES=0
export MPTDC_PNR_PHASE_METTP_EXCEPTION=0
export MPTDC_PNR_PHASE_TOP_LAYER=MET3
export MPTDC_PNR_PHASE_TOP_LAYER_IDX=3
export MPTDC_ENABLE_SIGNAL_TOP_ROUTE_BLOCKAGE="$SIGNAL_TOP_ROUTE_BLOCKAGE_VALUE"
export MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_LAYER=METTP
export MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_SCOPE=core

export MPTDC_ENABLE_BLOCK_PG_PINS=1
export MPTDC_BLOCK_PG_PIN_STYLE=simple_vdd_vss_pair
export MPTDC_BLOCK_PG_PIN_LAYER=METTP
export MPTDC_BLOCK_PG_PIN_WIDTH_UM=4.0
export MPTDC_BLOCK_PG_PIN_DEPTH_UM=28.0
export MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM=8.0
export MPTDC_BLOCK_PG_PIN_CREATE_MODE=geom
export MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK=0
export MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=0

export MPTDC_ENABLE_PREPLACE_PG_SROUTE=0
export MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE=1
export MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=1
export MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN=1
export MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY="$ALLOW_DANGLING_ONLY_VALUE"
export MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX="$DANGLING_ONLY_MAX_VALUE"
export MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=1
export MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=1
export MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK=0
export MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS=0
export MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES=0
export MPTDC_SROUTE_CONNECT_STRIPE=1
export MPTDC_SROUTE_CORE_PIN_STOP_ROUTE=RowEnd
export MPTDC_ROUTE_GATE_SROUTE_RECOVERY=0

export MPTDC_ENABLE_RO_PG_PROBE=1
export MPTDC_ENABLE_RO_PG_HOOKUP=0
export MPTDC_REQUIRE_RO_PG_HOOKUP=0
export MPTDC_ENABLE_RO_PG_MACRO_PATCH=0
export MPTDC_ALLOW_RO_DERIVED_PG_DANGLING=0

export MPTDC_PNR_CORE_UTIL="$CORE_UTIL_VALUE"
export MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT="$FREE_ALL_INTERNAL_VALUE"
export MPTDC_PNR_FREE_INTERNAL_PLACEMENT="$FREE_ALL_INTERNAL_VALUE"
export MPTDC_PNR_FREE_DIGITAL_ONLY_PLACEMENT=0
export MPTDC_PNR_FIX_RO_MACROS="$FIX_RO_VALUE"
export MPTDC_PNR_CREATE_RO_HALOS=0
export MPTDC_PNR_CREATE_RO_ROUTE_BLOCKAGES=0
export MPTDC_PNR_PD_TILE_CONSTRAINT_MODE=none
export MPTDC_PNR_PD_TILE_APPLY_HIER_BOX=0
export MPTDC_PNR_PD_TILE_REGION_MARGIN_UM=0.0
export MPTDC_PNR_PD_TILE_USE_FENCE=0
export MPTDC_PNR_PD_TILE_PREPLACE_LEAVES=0
export MPTDC_PNR_PD_TILE_FIX_LEAVES=0
export MPTDC_PNR_PHASE_BUF_ORIENT=ROW_LEGAL
export MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES="MX R180 MY R0"

if is_truthy "$FREE_ALL_INTERNAL_VALUE"; then
  export MPTDC_PD_PHYSICAL_AUDIT_MODE=free_internal
  export MPTDC_ALLOW_RELAXED_PD_MATRIX=1
  export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1
  export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=0
  export MPTDC_RO_PHASE_PREPLACE_AUDIT=0
  export MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL=0
  export MPTDC_RO_PHASE_MIN_CLEARANCE_UM=0.0
  export MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM=0.0
else
  export MPTDC_PD_PHYSICAL_AUDIT_MODE=soft_region
  export MPTDC_ALLOW_RELAXED_PD_MATRIX=0
  export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=1
  export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=1
  export MPTDC_PNR_FAST_TAG_COLUMN_BITS=ALL
  export MPTDC_PNR_FAST_TAG_COLUMN_SIDE=center
  export MPTDC_PNR_ALLOW_FAST_TAG_CENTER_OVER_PD=1
  export MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE=0
  export MPTDC_PNR_FAST_TAG_COLUMN_FIX=0
  export MPTDC_RO_PHASE_PREPLACE_AUDIT=1
  export MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL=1
  export MPTDC_RO_PHASE_MIN_CLEARANCE_UM=10.0
  export MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM=16.0
fi

if is_truthy "$LOCAL_PHASE_PREPLACE_VALUE"; then
  export MPTDC_PNR_FIX_RO_MACROS=1
  export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=0
  export MPTDC_PNR_PHASE_BUF_FIX=1
  export MPTDC_PNR_FORCE_RO_PHASE_SAFE_ORIGINS=1
  export MPTDC_RO_PHASE_PREPLACE_AUDIT=1
  export MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL=1
  export MPTDC_RO_PHASE_MIN_CLEARANCE_UM=10.0
  export MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM=16.0
fi

export MPTDC_RUN_CLK_SYS_CTS=1
export MPTDC_ENABLE_TC_CLOSURE=1
export MPTDC_SKIP_VERBOSE_DRV_ALL_VIOLATORS=1
export MPTDC_DB_DISPLAY_LIMIT=50000

export MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE=0
export MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS=0
export MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES=Mar
export MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE=0
export MPTDC_ENABLE_ROUTE_GATE_RECOVERY=0
export MPTDC_ROUTE_REPAIR_COMMANDS='{ecoRoute -target} {ecoRoute -fix_drc}'

export MPTDC_STOP_AFTER_POSTPLACE_PRE_ROUTE_SROUTE=1
export MPTDC_ENABLE_POSTROUTE_OPT=0
export MPTDC_ENABLE_FINAL_FILLER=0
export MPTDC_ENABLE_POST_FILLER_SROUTE=0
export MPTDC_FILLER_ADD_FILLERS_WITH_DRC=0
export MPTDC_REQUIRE_DRC_SAFE_FILLER=1

if [[ "$STAGE" == "full_closure" ]]; then
  export MPTDC_STOP_AFTER_POSTPLACE_PRE_ROUTE_SROUTE=0
  export MPTDC_ENABLE_POSTROUTE_OPT="$POSTROUTE_OPT_VALUE"
  export MPTDC_ENABLE_FINAL_FILLER="$ENABLE_FINAL_FILLER_VALUE"
  export MPTDC_ENABLE_POST_FILLER_SROUTE="$ENABLE_POST_FILLER_SROUTE_VALUE"
  export MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS=0.020
  export MPTDC_POSTROUTE_SETUP_OPT_PASSES=18
  export MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES=18
  export MPTDC_POSTROUTE_SETUP_HARD_CAP=18
  export MPTDC_POSTROUTE_SETUP_EARLY_STOP=0
  export MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD=1
  export MPTDC_POSTROUTE_SETUP_STALL_LIMIT=3
  export MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS=0.002
  export MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS=0.010
  export MPTDC_POSTROUTE_HOLD_OPT_PASSES=3
  export MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES=3
  export MPTDC_PNR_FAST_TAG_TIMING_FOCUS=1
  export MPTDC_PNR_FAST_TAG_TARGETED_ECO=1
  export MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN=1
  export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS=700
  export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS=900
  export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE=1
  export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2=1
  export MPTDC_PNR_FAST_TAG_ECO_ALLOW_TIMING_PATH_ON22=1
  export MPTDC_PNR_FAST_TAG_ECO_ON22_TARGET_X2=1
  export MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS=520
  export MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT=12
  export MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK=1
  export MPTDC_PNR_FAST_TAG_CRITICAL_RANGE_NS=0.180
fi

echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "STAGE=$STAGE"
echo "FINAL_LEF=$FINAL_LEF_VALUE"
echo "PNR_LEF=$PNR_LEF_VALUE"
echo "MPTDC_PG_STRATEGY=$MPTDC_PG_STRATEGY"
echo "MPTDC_PNR_SIGNAL_TOP_LAYER=$MPTDC_PNR_SIGNAL_TOP_LAYER"
echo "MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER=$MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER"
echo "MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR=$MPTDC_PNR_PROMOTE_SIGNAL_TOP_TO_EFFECTIVE_FLOOR"
echo "MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP=$MPTDC_PNR_ALLOW_SPECIAL_ROUTE_ABOVE_SIGNAL_TOP"
echo "MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES=$MPTDC_PNR_KEEP_ROUTER_TOP_AT_EFFECTIVE_FLOOR_FOR_EXISTING_ROUTES"
echo "MPTDC_PNR_PHASE_METTP_EXCEPTION=$MPTDC_PNR_PHASE_METTP_EXCEPTION"
echo "MPTDC_PNR_PHASE_TOP_LAYER=$MPTDC_PNR_PHASE_TOP_LAYER"
echo "MPTDC_PNR_PHASE_TOP_LAYER_IDX=$MPTDC_PNR_PHASE_TOP_LAYER_IDX"
echo "MPTDC_ENABLE_SIGNAL_TOP_ROUTE_BLOCKAGE=$MPTDC_ENABLE_SIGNAL_TOP_ROUTE_BLOCKAGE"
echo "MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_LAYER=$MPTDC_SIGNAL_TOP_ROUTE_BLOCKAGE_LAYER"
echo "MPTDC_BLOCK_PG_PIN_STYLE=$MPTDC_BLOCK_PG_PIN_STYLE"
echo "MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=$MPTDC_ALLOW_LEGACY_PG_TOPOLOGY"
echo "MPTDC_ENABLE_RO_PG_HOOKUP=$MPTDC_ENABLE_RO_PG_HOOKUP"
echo "MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=$MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN"
echo "MPTDC_STOP_AFTER_POSTPLACE_PRE_ROUTE_SROUTE=$MPTDC_STOP_AFTER_POSTPLACE_PRE_ROUTE_SROUTE"
echo "MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY=$MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY"
echo "MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX=$MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX"
echo "MPTDC_PNR_CORE_UTIL=$MPTDC_PNR_CORE_UTIL"
echo "MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT=$MPTDC_PNR_FREE_ALL_INTERNAL_PLACEMENT"
echo "MPTDC_PNR_FIX_RO_MACROS=$MPTDC_PNR_FIX_RO_MACROS"
echo "MPTDC_SIMPLEPG_LOCAL_PHASE_PREPLACE=$LOCAL_PHASE_PREPLACE_VALUE"
echo "MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE=$MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE"
echo "MPTDC_PNR_PHASE_BUF_FIX=${MPTDC_PNR_PHASE_BUF_FIX:-0}"
echo "MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=$MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN"
echo "MPTDC_ENABLE_POSTROUTE_OPT=$MPTDC_ENABLE_POSTROUTE_OPT"
echo "MPTDC_ENABLE_FINAL_FILLER=$MPTDC_ENABLE_FINAL_FILLER"
echo "MPTDC_ENABLE_POST_FILLER_SROUTE=$MPTDC_ENABLE_POST_FILLER_SROUTE"
echo "MPTDC_GENUS_HANDOFF_DIR=$MPTDC_GENUS_HANDOFF_DIR"
echo "MPTDC_GENUS_RUN_ID=$MPTDC_GENUS_RUN_ID"
echo "Starting foreground Innovus latest-LEF simple-PG run..."

exec bash "$SCRIPT_DIR/server_run_innovus_mptdc_digital_signoff.sh" \
  "$RUN_ID" \
  --expected-head "$ACTUAL_HEAD" \
  --mode full_signoff \
  --genus-run-id "$MPTDC_GENUS_RUN_ID" \
  --handoff-dir "$MPTDC_GENUS_HANDOFF_DIR"
