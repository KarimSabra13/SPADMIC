#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_FINAL_LEF="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef"
DEFAULT_PNR_LEF="/sim/ksabra/SPADMIC_work/lef/RO_tune6_pnr_pin_access_macro_only_20260630_mptdc_ro_lef_access_patch_real_lef_nofiller_v2_20260630_174804.lef"
DEFAULT_HANDOFF_DIR="/sim/ksabra/SPADMIC_work/handoff/genus_typical/MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233_handoff"
DEFAULT_GENUS_RUN_ID="MPTDC_TC_Closure_Genus_RO6_xx31_20260629_1233"
DEFAULT_INNOVUS_WORK="/sim/ksabra/SPADMIC_work/innovus"
DEFAULT_WORK_ROOT="/sim/ksabra/SPADMIC_work"

RUN_ID=""
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
FINAL_LEF_VALUE="${FINAL_LEF:-$DEFAULT_FINAL_LEF}"
PNR_LEF_VALUE="${PNR_LEF:-$DEFAULT_PNR_LEF}"
HANDOFF_DIR_VALUE="${MPTDC_GENUS_HANDOFF_DIR:-$DEFAULT_HANDOFF_DIR}"
GENUS_RUN_ID_VALUE="${MPTDC_GENUS_RUN_ID:-$DEFAULT_GENUS_RUN_ID}"
INNOVUS_WORK_VALUE="${MPTDC_INNOVUS_WORK:-$DEFAULT_INNOVUS_WORK}"
WORK_ROOT_VALUE="${MPTDC_WORK_ROOT:-$DEFAULT_WORK_ROOT}"
CLEAR_STALE_ENV_VALUE="${MPTDC_CLEAR_STALE_ENV:-1}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler.sh [RUN_ID] [options]

Options:
  --run-id <id>          Override the generated run id.
  --expected-head <sha>  Require the repository HEAD to match this commit.
  --source-lef <path>    Golden RO_tune6 macro-only LEF.
  --pnr-lef <path>       PnR access-patched RO_tune6 LEF.
  --handoff-dir <path>   Prepared Genus handoff directory.
  --genus-run-id <id>    Genus run id label used by the pre-PNR gate.
  --innovus-work <path>  Innovus run root.
  --work-root <path>     MPTDC work root.
  --no-clear-env         Do not clear stale MPTDC_* and O1_* exports first.
  -h, --help             Show this help.

This is a foreground TC-only full-closure attempt. It enables strict PG, CTS,
route, bounded Mar-only DRC continuation, post-route timing optimization, and
final filler cleanup. It is not MMMC or foundry DRC/LVS signoff.
USAGE
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

while [[ $# -gt 0 ]]; do
  case "$1" in
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
    --no-clear-env)
      CLEAR_STALE_ENV_VALUE=0
      shift
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

RUN_ID="${RUN_ID:-20260630_mptdc_tc_fullclosure_ro_pnr_pg_timing_filler_$(date +%H%M%S)}"
RUN_DIR="$INNOVUS_WORK_VALUE/$RUN_ID"

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
  echo "ERROR: tracked working tree is dirty. Commit or restore tracked edits before this closure run." >&2
  git status --short --untracked-files=no >&2
  exit 3
fi

test -r "$FINAL_LEF_VALUE"
test -r "$PNR_LEF_VALUE"
test -d "$HANDOFF_DIR_VALUE"
test -r "$REPO_ROOT/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib"
macro_only_precheck "$FINAL_LEF_VALUE" "source LEF"
macro_only_precheck "$PNR_LEF_VALUE" "PnR LEF"

if [[ "$CLEAR_STALE_ENV_VALUE" == "1" ]]; then
  while IFS='=' read -r name _; do
    case "$name" in
      MPTDC_*|O1_*) unset "$name" ;;
    esac
  done < <(env)
fi

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
export MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=0

export O1_USE_REAL_RO_ABSTRACT=1
export O1_RO_CELL_NAME=RO_tune6
export O1_RO_SOURCE_LEF_PATH="$FINAL_LEF_VALUE"
export O1_RO_LEF_PATH="$PNR_LEF_VALUE"
export O1_RO_LIBERTY_PATH="$REPO_ROOT/MPTDC/syn/macros/RO_tune6_real_layout_shell.lib"

export MPTDC_PNR_CORE_UTIL=0.55
export MPTDC_PNR_PD_TILE_CONSTRAINT_MODE=none
export MPTDC_PNR_PD_TILE_APPLY_HIER_BOX=0
export MPTDC_PNR_PD_TILE_REGION_MARGIN_UM=0.0
export MPTDC_PNR_PD_TILE_USE_FENCE=0
export MPTDC_PNR_PD_TILE_PREPLACE_LEAVES=0
export MPTDC_PNR_PD_TILE_FIX_LEAVES=0
export MPTDC_PD_PHYSICAL_AUDIT_MODE=soft_region
export MPTDC_PNR_FIX_RO_MACROS=0
export MPTDC_PNR_CREATE_RO_HALOS=0
export MPTDC_PNR_PHASE_BUF_ORIENT=ROW_LEGAL
export MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES="MX R180 MY R0"
export MPTDC_RO_PHASE_MIN_CLEARANCE_UM=10.0
export MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM=16.0
export MPTDC_RO_PHASE_PREPLACE_AUDIT=1
export MPTDC_RO_PHASE_FAIL_ON_GLOBAL_CHECKPLACE_OVERLAP=0

export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN=1
export MPTDC_PNR_FAST_TAG_COLUMN_BITS=ALL
export MPTDC_PNR_FAST_TAG_COLUMN_SIDE=center
export MPTDC_PNR_ALLOW_FAST_TAG_CENTER_OVER_PD=1
export MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE=0
export MPTDC_PNR_FAST_TAG_COLUMN_FIX=0
export MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM=40.0
export MPTDC_PNR_FAST_TAG_TIMING_FOCUS=1
export MPTDC_PNR_FAST_TAG_TARGETED_ECO=1
export MPTDC_PNR_FAST_TAG_CRITICAL_RANGE_NS=0.080
export MPTDC_PNR_FAST_TAG_MAX_TRANSITION_NS=0.350
export MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS=96
export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS=150
export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS=160
export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2=1
export MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES=1
export MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN=1
export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE=1

export MPTDC_RUN_CLK_SYS_CTS=1
export MPTDC_ENABLE_POSTROUTE_OPT=1
export MPTDC_ENABLE_TC_CLOSURE=1
export MPTDC_POSTROUTE_SETUP_OPT_PASSES=10
export MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES=10
export MPTDC_POSTROUTE_SETUP_TARGET_SLACK_NS=0.200
export MPTDC_POSTROUTE_SETUP_EARLY_STOP=0
export MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD=1
export MPTDC_POSTROUTE_SETUP_STALL_LIMIT=3
export MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS=0.002
export MPTDC_POSTROUTE_HOLD_OPT_PASSES=3
export MPTDC_POSTROUTE_HOLD_OPT_MAX_PASSES=3
export MPTDC_POSTROUTE_HOLD_TARGET_SLACK_NS=0.050
export MPTDC_SKIP_VERBOSE_DRV_ALL_VIOLATORS=1
export MPTDC_DB_DISPLAY_LIMIT=50000

export MPTDC_ENABLE_BLOCK_PG_PINS=1
export MPTDC_BLOCK_PG_PIN_LAYER=METTP
export MPTDC_BLOCK_PG_PIN_STYLE=mesh_lr_vdd_vss
export MPTDC_BLOCK_PG_PIN_WIDTH_UM=4.0
export MPTDC_BLOCK_PG_PIN_DEPTH_UM=28.0
export MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM=8.0
export MPTDC_BLOCK_PG_PIN_CREATE_MODE=geom
export MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK=0
export MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=0
export MPTDC_ENABLE_PREPLACE_PG_SROUTE=0
export MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE=1
export MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=0
export MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN=1
export MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=0
export MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=0
export MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK=0
export MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS=0
export MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES=0
export MPTDC_SROUTE_CONNECT_STRIPE=1
export MPTDC_SROUTE_CORE_PIN_STOP_ROUTE=RowEnd
export MPTDC_ENABLE_RO_PG_PROBE=1
export MPTDC_ENABLE_RO_PG_HOOKUP=1
export MPTDC_REQUIRE_RO_PG_HOOKUP=1
export MPTDC_RO_PG_HOOKUP_SEARCH_UM=45.0
export MPTDC_RO_PG_HOOKUP_MARGIN_UM=1.0
export MPTDC_RO_PG_HOOKUP_SPACING_UM=2.0
export MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM=5000.0
export MPTDC_ROUTE_GATE_SROUTE_RECOVERY=1

export MPTDC_ENABLE_FINAL_FILLER=1
export MPTDC_ENABLE_POST_FILLER_SROUTE=1
export MPTDC_FILLER_ADD_FILLERS_WITH_DRC=0
export MPTDC_REQUIRE_DRC_SAFE_FILLER=1

export MPTDC_ENABLE_ROUTE_GATE_RECOVERY=1
export MPTDC_ROUTE_REPAIR_COMMANDS="{ecoRoute -target} {ecoRoute -fix_drc}"
export MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE=1
export MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES=Mar
export MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS=5

export MPTDC_PHASE_RC_ACCEPT_ASYMMETRY=1
export MPTDC_PHASE_RC_ACCEPT_SCOPE=TC_ONLY_O13_OWNER_REVIEW
export MPTDC_PHASE_RC_ACCEPT_REASON=owner_accepted_phase_rc_asymmetry_for_tc_only_fullclosure_20260630

echo "RUN_ID=$RUN_ID"
echo "RUN_DIR=$RUN_DIR"
echo "FINAL_LEF=$FINAL_LEF_VALUE"
echo "PNR_LEF=$PNR_LEF_VALUE"
echo "MPTDC_GENUS_HANDOFF_DIR=$MPTDC_GENUS_HANDOFF_DIR"
echo "MPTDC_GENUS_RUN_ID=$MPTDC_GENUS_RUN_ID"
echo "Starting foreground Innovus full_signoff run..."

exec bash "$SCRIPT_DIR/server_run_innovus_mptdc_digital_signoff.sh" \
  "$RUN_ID" \
  --mode full_signoff \
  --genus-run-id "$MPTDC_GENUS_RUN_ID" \
  --handoff-dir "$MPTDC_GENUS_HANDOFF_DIR"
