#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

RUN_ID=""
GENUS_RUN_ID="${MPTDC_GENUS_RUN_ID:-MPTDC_TC_Closure_Genus}"
GENUS_RUN_DIR="${MPTDC_GENUS_RUN_DIR:-}"
HANDOFF_DIR="${MPTDC_GENUS_HANDOFF_DIR:-}"
MODE="${MPTDC_DIGITAL_SIGNOFF_MODE:-validate_only}"

usage() {
  cat <<'USAGE'
Usage:
  server_run_innovus_mptdc_digital_signoff.sh <RUN_ID> [options]

Options:
  --genus-run-id <id>     Closed Genus run ID used to build the handoff.
  --genus-run-dir <path>  Explicit closed Genus run directory.
  --handoff-dir <path>    Explicit prepared handoff directory.
  --mode <mode>           validate_only, discover_only, or full_signoff.
  -h, --help              Show this help.

full_signoff launches Innovus and requires:
  MPTDC_DIGITAL_SIGNOFF_APPROVED=1

Provisional no-dedicated-core-tap/endcap implementation also requires:
  MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1

This is the digital block signoff entrypoint. It must not be replaced by a
renamed typical-feasibility wrapper.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

lef_macro_name() {
  local lef="$1"
  awk '
    /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
    inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
    inprop {next}
    /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {print $2; exit}
  ' "$lef"
}

lef_macro_size() {
  local lef="$1"
  local macro="${2:-RO_tune6}"
  awk -v target="$macro" '
    /^[[:space:]]*PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=1; next}
    inprop && /^[[:space:]]*END[[:space:]]+PROPERTYDEFINITIONS[[:space:]]*$/ {inprop=0; next}
    inprop {next}
    /^[[:space:]]*MACRO[[:space:]]+[^[:space:];]+[[:space:]]*$/ {
      in_macro = ($2 == target)
      next
    }
    in_macro && /^[[:space:]]*SIZE[[:space:]]+[-+0-9.]+[[:space:]]+BY[[:space:]]+[-+0-9.]+[[:space:]]*;/ {
      print $2, $4
      exit
    }
    in_macro && /^[[:space:]]*END[[:space:]]+[^[:space:];]+[[:space:]]*$/ {
      if ($2 == target) exit
    }
  ' "$lef"
}

is_truthy() {
  case "${1:-0}" in
    1|true|TRUE|yes|YES|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

apply_recovery_defaults() {
  local default_route_repair_commands='{ecoRoute -target} {ecoRoute -fix_drc}'

  export MPTDC_PNR_PD_TILE_CONSTRAINT_MODE="${MPTDC_PNR_PD_TILE_CONSTRAINT_MODE:-none}"
  export MPTDC_PNR_PD_TILE_APPLY_HIER_BOX="${MPTDC_PNR_PD_TILE_APPLY_HIER_BOX:-0}"
  export MPTDC_PNR_PD_TILE_REGION_MARGIN_UM="${MPTDC_PNR_PD_TILE_REGION_MARGIN_UM:-0.0}"
  export MPTDC_PNR_PD_TILE_USE_FENCE="${MPTDC_PNR_PD_TILE_USE_FENCE:-0}"
  export MPTDC_PNR_PD_TILE_PREPLACE_LEAVES="${MPTDC_PNR_PD_TILE_PREPLACE_LEAVES:-0}"
  export MPTDC_PNR_PD_TILE_FIX_LEAVES="${MPTDC_PNR_PD_TILE_FIX_LEAVES:-0}"
  export MPTDC_PD_PHYSICAL_AUDIT_MODE="${MPTDC_PD_PHYSICAL_AUDIT_MODE:-soft_region}"
  export MPTDC_PD_TILE_SOFT_BOX_MARGIN_UM="${MPTDC_PD_TILE_SOFT_BOX_MARGIN_UM:-12.0}"
  export MPTDC_PD_TILE_MAX_OFFSET_UM="${MPTDC_PD_TILE_MAX_OFFSET_UM:-12.0}"
  export MPTDC_PNR_CORE_UTIL="${MPTDC_PNR_CORE_UTIL:-0.55}"
  export MPTDC_PNR_FREE_INTERNAL_PLACEMENT="${MPTDC_PNR_FREE_INTERNAL_PLACEMENT:-0}"
  if is_truthy "$MPTDC_PNR_FREE_INTERNAL_PLACEMENT"; then
    export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE="${MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE:-1}"
    export MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL="${MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL:-0}"
    export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN="${MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN:-0}"
  else
    export MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE="${MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE:-0}"
  fi
  export MPTDC_PNR_FIX_RO_MACROS="${MPTDC_PNR_FIX_RO_MACROS:-0}"
  export MPTDC_PNR_CREATE_RO_HALOS="${MPTDC_PNR_CREATE_RO_HALOS:-0}"
  export MPTDC_PNR_PHASE_BUF_ORIENT="${MPTDC_PNR_PHASE_BUF_ORIENT:-ROW_LEGAL}"
  export MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES="${MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES:-MX R180 MY R0}"
  export MPTDC_RO_PHASE_MIN_CLEARANCE_UM="${MPTDC_RO_PHASE_MIN_CLEARANCE_UM:-10.0}"
  export MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM="${MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM:-16.0}"
  export MPTDC_RO_PHASE_PREPLACE_AUDIT="${MPTDC_RO_PHASE_PREPLACE_AUDIT:-1}"

  export MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN="${MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN:-1}"
  export MPTDC_PNR_FAST_TAG_COLUMN_SIDE="${MPTDC_PNR_FAST_TAG_COLUMN_SIDE:-center}"
  export MPTDC_PNR_ALLOW_FAST_TAG_CENTER_OVER_PD="${MPTDC_PNR_ALLOW_FAST_TAG_CENTER_OVER_PD:-1}"
  export MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE="${MPTDC_PNR_FAST_TAG_COLUMN_PREPLACE:-0}"
  export MPTDC_PNR_FAST_TAG_COLUMN_FIX="${MPTDC_PNR_FAST_TAG_COLUMN_FIX:-0}"
  export MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM="${MPTDC_PNR_FAST_TAG_COLUMN_STRIP_WIDTH_UM:-40.0}"

  export MPTDC_ENABLE_POSTROUTE_OPT="${MPTDC_ENABLE_POSTROUTE_OPT:-1}"
  export MPTDC_ENABLE_TC_CLOSURE="${MPTDC_ENABLE_TC_CLOSURE:-1}"
  export MPTDC_POSTROUTE_SETUP_OPT_PASSES="${MPTDC_POSTROUTE_SETUP_OPT_PASSES:-4}"
  export MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES="${MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES:-4}"
  export MPTDC_POSTROUTE_SETUP_EARLY_STOP="${MPTDC_POSTROUTE_SETUP_EARLY_STOP:-1}"
  export MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD="${MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD:-1}"
  export MPTDC_POSTROUTE_SETUP_STALL_LIMIT="${MPTDC_POSTROUTE_SETUP_STALL_LIMIT:-1}"
  export MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS="${MPTDC_POSTROUTE_SETUP_MIN_IMPROVEMENT_NS:-0.005}"

  export MPTDC_PNR_FAST_TAG_TIMING_FOCUS="${MPTDC_PNR_FAST_TAG_TIMING_FOCUS:-1}"
  export MPTDC_PNR_FAST_TAG_TARGETED_ECO="${MPTDC_PNR_FAST_TAG_TARGETED_ECO:-1}"
  export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2="${MPTDC_PNR_FAST_TAG_ECO_ALLOW_ON22_X2:-1}"
  export MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS="${MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS:-0}"
  export MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES="${MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES:-1}"
  export MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS="${MPTDC_PNR_FAST_TAG_ECO_MAX_UPSIZE_CELLS:-64}"
  export MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT="${MPTDC_PNR_FAST_TAG_ECO_UPSIZE_DRIVE_LIMIT:-4}"
  export MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN="${MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN:-1}"
  export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS="${MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS:-100}"
  export MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS="${MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS:-128}"
  export MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK="${MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK:-0}"
  export MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE="${MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE:-1}"

  export MPTDC_ENABLE_BLOCK_PG_PINS="${MPTDC_ENABLE_BLOCK_PG_PINS:-1}"
  export MPTDC_BLOCK_PG_PIN_LAYER="${MPTDC_BLOCK_PG_PIN_LAYER:-METTP}"
  export MPTDC_BLOCK_PG_PIN_STYLE="${MPTDC_BLOCK_PG_PIN_STYLE:-mesh_lr_vdd_vss}"
  export MPTDC_BLOCK_PG_PIN_WIDTH_UM="${MPTDC_BLOCK_PG_PIN_WIDTH_UM:-4.0}"
  export MPTDC_BLOCK_PG_PIN_DEPTH_UM="${MPTDC_BLOCK_PG_PIN_DEPTH_UM:-28.0}"
  export MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM="${MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM:-8.0}"
  export MPTDC_BLOCK_PG_PIN_CREATE_MODE="${MPTDC_BLOCK_PG_PIN_CREATE_MODE:-geom}"
  export MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK="${MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK:-0}"
  export MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES="${MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES:-0}"
  export MPTDC_BLOCK_PG_STITCH_WIDTH_UM="${MPTDC_BLOCK_PG_STITCH_WIDTH_UM:-2.0}"
  export MPTDC_BLOCK_PG_STITCH_SPACING_UM="${MPTDC_BLOCK_PG_STITCH_SPACING_UM:-2.0}"
  export MPTDC_BLOCK_PG_STITCH_SET_DISTANCE_UM="${MPTDC_BLOCK_PG_STITCH_SET_DISTANCE_UM:-5000.0}"
  export MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS="${MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS:-0}"
  export MPTDC_ENABLE_FINAL_FILLER="${MPTDC_ENABLE_FINAL_FILLER:-0}"
  export MPTDC_ENABLE_POST_FILLER_SROUTE="${MPTDC_ENABLE_POST_FILLER_SROUTE:-0}"
  export MPTDC_ENABLE_PREPLACE_PG_SROUTE="${MPTDC_ENABLE_PREPLACE_PG_SROUTE:-0}"
  export MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG="${MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG:-1}"
  export MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE="${MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE:-1}"
  export MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN="${MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN:-1}"
  export MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN="${MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN:-1}"
  export MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY="${MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY:-0}"
  export MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX="${MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX:-64}"
  export MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE="${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-0}"
  export MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN="${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-0}"
  export MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK="${MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK:-0}"
  export MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS="${MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS:-0}"
  export MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES="${MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES:-0}"
  export MPTDC_SROUTE_CONNECT_STRIPE="${MPTDC_SROUTE_CONNECT_STRIPE:-1}"
  export MPTDC_SROUTE_CORE_PIN_STOP_ROUTE="${MPTDC_SROUTE_CORE_PIN_STOP_ROUTE:-RowEnd}"
  export MPTDC_ENABLE_RO_PG_PROBE="${MPTDC_ENABLE_RO_PG_PROBE:-0}"
  export MPTDC_ENABLE_RO_PG_HOOKUP="${MPTDC_ENABLE_RO_PG_HOOKUP:-1}"
  export MPTDC_REQUIRE_RO_PG_HOOKUP="${MPTDC_REQUIRE_RO_PG_HOOKUP:-1}"
  export MPTDC_ENABLE_RO_PG_MACRO_PATCH="${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-0}"
  export MPTDC_ALLOW_RO_DERIVED_PG_DANGLING="${MPTDC_ALLOW_RO_DERIVED_PG_DANGLING:-0}"
  export MPTDC_RO_PG_HOOKUP_SEARCH_UM="${MPTDC_RO_PG_HOOKUP_SEARCH_UM:-45.0}"
  export MPTDC_RO_PG_HOOKUP_MARGIN_UM="${MPTDC_RO_PG_HOOKUP_MARGIN_UM:-1.0}"
  export MPTDC_RO_PG_HOOKUP_SPACING_UM="${MPTDC_RO_PG_HOOKUP_SPACING_UM:-2.0}"
  export MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM="${MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM:-5000.0}"
  export MPTDC_FILLER_ADD_FILLERS_WITH_DRC="${MPTDC_FILLER_ADD_FILLERS_WITH_DRC:-0}"
  export MPTDC_REQUIRE_DRC_SAFE_FILLER="${MPTDC_REQUIRE_DRC_SAFE_FILLER:-1}"
  export MPTDC_ENABLE_ROUTE_GATE_RECOVERY="${MPTDC_ENABLE_ROUTE_GATE_RECOVERY:-1}"
  export MPTDC_ROUTE_GATE_SROUTE_RECOVERY="${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-0}"
  export MPTDC_ROUTE_REPAIR_COMMANDS="${MPTDC_ROUTE_REPAIR_COMMANDS:-$default_route_repair_commands}"
  export MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE="${MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE:-1}"
  export MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS="${MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS:-2}"
  export MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES="${MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES:-Mar}"
  export MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE="${MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE:-0}"
  export MPTDC_PG_STRATEGY="${MPTDC_PG_STRATEGY:-conservative_ro_hookup}"
}

guard_pg_policy() {
  if is_truthy "${MPTDC_ALLOW_LEGACY_PG_TOPOLOGY:-0}"; then
    export MPTDC_PG_POLICY_GUARD_STATUS=BYPASSED
    return
  fi
  local failures=()
  local pg_strategy="${MPTDC_PG_STRATEGY:-conservative_ro_hookup}"
  if [[ "${MPTDC_BLOCK_PG_PIN_STYLE:-}" != "mesh_lr_vdd_vss" ]]; then
    failures+=("MPTDC_BLOCK_PG_PIN_STYLE=${MPTDC_BLOCK_PG_PIN_STYLE:-unset} expected mesh_lr_vdd_vss")
  fi
  if is_truthy "${MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES:-0}"; then
    failures+=("MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES=1 expected 0")
  fi
  if ! is_truthy "${MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN:-1}"; then
    if ! is_truthy "${MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE:-1}" || ! is_truthy "${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-0}"; then
      failures+=("MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN=${MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN:-unset} requires MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE=1 and MPTDC_ROUTE_GATE_SROUTE_RECOVERY=1")
    fi
  fi
  if is_truthy "${MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS:-0}"; then
    failures+=("MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS=1 expected 0")
  fi
  if [[ "${MPTDC_SROUTE_CORE_PIN_STOP_ROUTE:-}" != "RowEnd" ]]; then
    failures+=("MPTDC_SROUTE_CORE_PIN_STOP_ROUTE=${MPTDC_SROUTE_CORE_PIN_STOP_ROUTE:-unset} expected RowEnd")
  fi

  case "$pg_strategy" in
    manual_ro_pg_core_sroute)
      if is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=1 expected 0 for manual_ro_pg_core_sroute")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_PROBE=${MPTDC_ENABLE_RO_PG_PROBE:-unset} expected 1 for manual_ro_pg_core_sroute")
      fi
      if is_truthy "${MPTDC_ENABLE_RO_PG_HOOKUP:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_HOOKUP=${MPTDC_ENABLE_RO_PG_HOOKUP:-unset} expected 0 for manual_ro_pg_core_sroute")
      fi
      if is_truthy "${MPTDC_REQUIRE_RO_PG_HOOKUP:-0}"; then
        failures+=("MPTDC_REQUIRE_RO_PG_HOOKUP=${MPTDC_REQUIRE_RO_PG_HOOKUP:-unset} expected 0 for manual_ro_pg_core_sroute")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_MACRO_PATCH=${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-unset} expected 1 for manual_ro_pg_core_sroute")
      fi
      if is_truthy "${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-0}"; then
        failures+=("MPTDC_ROUTE_GATE_SROUTE_RECOVERY=${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-unset} expected 0 for manual_ro_pg_core_sroute")
      fi
      ;;
    innovus_sroute_golden_ro)
      if ! is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-unset} expected 1 for innovus_sroute_golden_ro")
      fi
      if ! is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-unset} expected 1 for innovus_sroute_golden_ro")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_PROBE=${MPTDC_ENABLE_RO_PG_PROBE:-unset} expected 1 for innovus_sroute_golden_ro")
      fi
      if is_truthy "${MPTDC_ENABLE_RO_PG_HOOKUP:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_HOOKUP=${MPTDC_ENABLE_RO_PG_HOOKUP:-unset} expected 0 for innovus_sroute_golden_ro")
      fi
      if is_truthy "${MPTDC_REQUIRE_RO_PG_HOOKUP:-0}"; then
        failures+=("MPTDC_REQUIRE_RO_PG_HOOKUP=${MPTDC_REQUIRE_RO_PG_HOOKUP:-unset} expected 0 for innovus_sroute_golden_ro")
      fi
      if is_truthy "${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-0}"; then
        failures+=("MPTDC_ROUTE_GATE_SROUTE_RECOVERY=${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-unset} expected 0 for innovus_sroute_golden_ro")
      fi
      ;;
    conservative_ro_hookup_blockpin_probe)
      if ! is_truthy "${MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN:-1}"; then
        failures+=("MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN=${MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY:-0}"; then
        failures+=("MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY=${MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_PROBE=${MPTDC_ENABLE_RO_PG_PROBE:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_HOOKUP:-1}"; then
        failures+=("MPTDC_ENABLE_RO_PG_HOOKUP=${MPTDC_ENABLE_RO_PG_HOOKUP:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if ! is_truthy "${MPTDC_REQUIRE_RO_PG_HOOKUP:-1}"; then
        failures+=("MPTDC_REQUIRE_RO_PG_HOOKUP=${MPTDC_REQUIRE_RO_PG_HOOKUP:-unset} expected 1 for conservative_ro_hookup_blockpin_probe")
      fi
      if is_truthy "${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-0}"; then
        failures+=("MPTDC_ENABLE_RO_PG_MACRO_PATCH=${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-unset} expected 0 for conservative_ro_hookup_blockpin_probe")
      fi
      if is_truthy "${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-0}"; then
        failures+=("MPTDC_ROUTE_GATE_SROUTE_RECOVERY=${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-unset} expected 0 for conservative_ro_hookup_blockpin_probe")
      fi
      ;;
    conservative_ro_hookup)
      if is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE=1 expected 0")
      fi
      if is_truthy "${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-0}"; then
        failures+=("MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN=1 expected 0")
      fi
      if ! is_truthy "${MPTDC_ENABLE_RO_PG_HOOKUP:-1}"; then
        failures+=("MPTDC_ENABLE_RO_PG_HOOKUP=${MPTDC_ENABLE_RO_PG_HOOKUP:-unset} expected 1")
      fi
      if ! is_truthy "${MPTDC_REQUIRE_RO_PG_HOOKUP:-1}"; then
        failures+=("MPTDC_REQUIRE_RO_PG_HOOKUP=${MPTDC_REQUIRE_RO_PG_HOOKUP:-unset} expected 1")
      fi
      ;;
    *)
      failures+=("MPTDC_PG_STRATEGY=$pg_strategy unsupported")
      ;;
  esac

  if ((${#failures[@]} > 0)); then
    {
      echo "ERROR: stale or unsafe PG topology environment detected."
      printf 'ERROR: %s\n' "${failures[@]}"
      echo "ERROR: unset the stale MPTDC_* variables or set MPTDC_ALLOW_LEGACY_PG_TOPOLOGY=1 only for explicit debug bypass."
    } | tee -a "$RUN_LOG"
    exit 4
  fi
  export MPTDC_PG_POLICY_GUARD_STATUS=PASS
}

export_ro_lef_size() {
  local lef="$1"
  local macro="$2"
  local width=""
  local height=""

  read -r width height < <(lef_macro_size "$lef" "$macro" 2>/dev/null || true)
  if [[ -z "$width" || -z "$height" ]]; then
    echo "ERROR: could not parse SIZE for MACRO $macro in O1_RO_LEF_PATH=$lef" | tee -a "$RUN_LOG"
    exit 3
  fi
  export MPTDC_PNR_OSC_WIDTH_UM="$width"
  export MPTDC_PNR_OSC_HEIGHT_UM="$height"
}

resolve_ro_handoff() {
  local env_file="${MPTDC_RO_HANDOFF_ENV:-$MPTDC_DIR/analog_handoff/real_ro_tune6_layout.env}"
  local default_ro_lef="${O1_RO_DEFAULT_LEF:-/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef}"
  local default_ro_lib="$MPTDC_DIR/syn/macros/RO_tune6_real_layout_shell.lib"
  local expected_ro_macro="${O1_RO_CELL_NAME:-RO_tune6}"
  local explicit_use_real_ro_abstract="${O1_USE_REAL_RO_ABSTRACT:-}"
  local explicit_ro_cell_name="${O1_RO_CELL_NAME:-}"
  local explicit_ro_source_lef_path="${O1_RO_SOURCE_LEF_PATH:-}"
  local explicit_ro_lef_path="${O1_RO_LEF_PATH:-}"
  local explicit_ro_liberty_path="${O1_RO_LIBERTY_PATH:-}"
  local override_fields=()
  local candidate_order=()
  local candidate=""
  local macro=""

  if [[ -f "$env_file" ]]; then
    # shellcheck disable=SC1090
    source "$env_file"
    export MPTDC_RO_HANDOFF_ENV_SOURCED="$env_file"
  else
    export MPTDC_RO_HANDOFF_ENV_SOURCED="missing:$env_file"
  fi

  if [[ -n "$explicit_use_real_ro_abstract" ]]; then
    export O1_USE_REAL_RO_ABSTRACT="$explicit_use_real_ro_abstract"
    override_fields+=("O1_USE_REAL_RO_ABSTRACT")
  fi
  if [[ -n "$explicit_ro_cell_name" ]]; then
    export O1_RO_CELL_NAME="$explicit_ro_cell_name"
    override_fields+=("O1_RO_CELL_NAME")
  fi
  if [[ -n "$explicit_ro_source_lef_path" ]]; then
    export O1_RO_SOURCE_LEF_PATH="$explicit_ro_source_lef_path"
    override_fields+=("O1_RO_SOURCE_LEF_PATH")
  fi
  if [[ -n "$explicit_ro_lef_path" ]]; then
    export O1_RO_LEF_PATH="$explicit_ro_lef_path"
    override_fields+=("O1_RO_LEF_PATH")
  fi
  if [[ -n "$explicit_ro_liberty_path" ]]; then
    export O1_RO_LIBERTY_PATH="$explicit_ro_liberty_path"
    override_fields+=("O1_RO_LIBERTY_PATH")
  fi
  if ((${#override_fields[@]} > 0)); then
    export MPTDC_RO_HANDOFF_OVERRIDE_STATUS="preserved:${override_fields[*]}"
  else
    export MPTDC_RO_HANDOFF_OVERRIDE_STATUS="none"
  fi

  export O1_USE_REAL_RO_ABSTRACT="${O1_USE_REAL_RO_ABSTRACT:-1}"
  export O1_RO_CELL_NAME="${O1_RO_CELL_NAME:-$expected_ro_macro}"
  export O1_RO_LIBERTY_PATH="${O1_RO_LIBERTY_PATH:-$default_ro_lib}"

  if [[ -z "${O1_RO_LEF_PATH:-}" ]]; then
    if [[ -n "$explicit_ro_source_lef_path" ]]; then
      candidate_order=("${O1_RO_SOURCE_LEF_PATH:-}" "$default_ro_lef")
    else
      candidate_order=("$default_ro_lef" "${O1_RO_SOURCE_LEF_PATH:-}")
    fi
    for candidate in "${candidate_order[@]}"; do
      [[ -n "$candidate" && -f "$candidate" ]] || continue
      macro="$(lef_macro_name "$candidate" 2>/dev/null || true)"
      if [[ "$macro" == "$O1_RO_CELL_NAME" ]]; then
        export O1_RO_LEF_PATH="$candidate"
        break
      fi
    done
  fi
}

infer_xh018_stack_from_techlef() {
  local lef="${1:-}"
  local base
  base="$(basename "$lef" 2>/dev/null || true)"
  case "$base" in
    *xx31*) echo xx31 ;;
    *xx33*) echo xx33 ;;
    *xx41*) echo xx41 ;;
    *xx43*) echo xx43 ;;
    *xx51*) echo xx51 ;;
    *) echo "" ;;
  esac
}

configure_xh018_stack() {
  local pdk="${MPTDC_PDK_ROOT:-${PDK_ROOT:-}}"
  if [[ -z "$pdk" ]]; then
    if [[ -d /eda/pdk/xfab/xh018 ]]; then
      pdk=/eda/pdk/xfab/xh018
    elif [[ -d /data/pdk/xfab/xh018 ]]; then
      pdk=/data/pdk/xfab/xh018
    else
      pdk=/eda/pdk/xfab/xh018
    fi
  fi
  export PDK_ROOT="$pdk"

  local allow_stack_file_overrides="${MPTDC_ALLOW_EXPLICIT_STACK_FILE_OVERRIDES:-0}"
  local inferred_stack=""
  if [[ "$allow_stack_file_overrides" == "1" && -n "${TECHNOLOGY_LEF:-}" ]]; then
    inferred_stack="$(infer_xh018_stack_from_techlef "$TECHNOLOGY_LEF")"
  fi

  local stack="${MPTDC_XH018_STACK:-$inferred_stack}"
  stack="${stack:-xx31}"
  stack="${stack,,}"

  local tech_lef=""
  local captbl_stem=""
  local qrc_family=""
  local route_layers=""
  local signal_top=""
  local floor_top="METTP"
  case "$stack" in
    xx31|1131|xh018_1131|xh018_xx31|1p3m)
      stack=xx31
      tech_lef="$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx31_HD_MET3_METMID.lef"
      captbl_stem="xh018_xx31_MET3_METMID"
      qrc_family="XH018_1131"
      route_layers="MET1 MET2 MET3 METTP"
      signal_top="MET3"
      ;;
    xx33|1133|xh018_1133|xh018_xx33)
      stack=xx33
      tech_lef="$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx33_HD_MET3_METMID_METTHK.lef"
      captbl_stem="xh018_xx33_MET3_METMID_METTHK"
      qrc_family="XH018_1133"
      route_layers="MET1 MET2 MET3 METTP METTHK"
      signal_top="MET3"
      ;;
    xx41|1141|xh018_1141|xh018_xx41|1p4m)
      stack=xx41
      tech_lef="$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx41_HD_MET4_METMID.lef"
      captbl_stem="xh018_xx41_MET4_METMID"
      qrc_family="XH018_1141"
      route_layers="MET1 MET2 MET3 MET4 METTP"
      signal_top="MET4"
      ;;
    xx43|1143|xh018_1143|xh018_xx43)
      stack=xx43
      tech_lef="$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx43_HD_MET4_METMID_METTHK.lef"
      captbl_stem="xh018_xx43_MET4_METMID_METTHK"
      qrc_family="XH018_1143"
      route_layers="MET1 MET2 MET3 MET4 METTP METTHK"
      signal_top="MET4"
      ;;
    xx51|1151|xh018_1151|xh018_xx51|1p5m)
      stack=xx51
      tech_lef="$PDK_ROOT/cadence/v9_0/techLEF/v9_0_1/xh018_xx51_HD_MET5_METMID.lef"
      captbl_stem="xh018_xx51_MET5_METMID"
      qrc_family="XH018_1151"
      route_layers="MET1 MET2 MET3 MET4 MET5 METTP"
      signal_top="MET5"
      ;;
    *)
      echo "ERROR: unsupported MPTDC_XH018_STACK=$stack; use xx31, xx33, xx41, xx43, or xx51" | tee -a "$RUN_LOG"
      exit 3
      ;;
  esac

  export MPTDC_XH018_STACK="$stack"
  if [[ "$allow_stack_file_overrides" == "1" ]]; then
    export TECHNOLOGY_LEF="${TECHNOLOGY_LEF:-$tech_lef}"
  else
    if [[ -n "${TECHNOLOGY_LEF:-}" && "$TECHNOLOGY_LEF" != "$tech_lef" ]]; then
      echo "INFO: overriding TECHNOLOGY_LEF from $TECHNOLOGY_LEF to stack-owned $tech_lef" | tee -a "$RUN_LOG"
    fi
    export TECHNOLOGY_LEF="$tech_lef"
  fi
  inferred_stack="$(infer_xh018_stack_from_techlef "$TECHNOLOGY_LEF")"
  if [[ -n "$inferred_stack" && "$inferred_stack" != "$stack" ]]; then
    echo "ERROR: TECHNOLOGY_LEF=$TECHNOLOGY_LEF implies $inferred_stack but MPTDC_XH018_STACK=$stack" | tee -a "$RUN_LOG"
    exit 3
  fi

  if [[ "$allow_stack_file_overrides" == "1" ]]; then
    export CAPTABLE_DIR="${CAPTABLE_DIR:-$PDK_ROOT/cadence/v9_0/capTbl/v9_0_1}"
    export CAPTABLE_BC="${CAPTABLE_BC:-$CAPTABLE_DIR/${captbl_stem}_min.capTbl}"
    export CAPTABLE_TC="${CAPTABLE_TC:-$CAPTABLE_DIR/${captbl_stem}_typ.capTbl}"
    export CAPTABLE_WC="${CAPTABLE_WC:-$CAPTABLE_DIR/${captbl_stem}_max.capTbl}"
    export QRC_ROOT="${QRC_ROOT:-$PDK_ROOT/cadence/v10_1/QRC_pvs/v10_1_1/$qrc_family}"
    export QRCTECH_BC="${QRCTECH_BC:-$QRC_ROOT/QRC-Min/qrcTechFile}"
    export QRCTECH_TC="${QRCTECH_TC:-$QRC_ROOT/QRC-Typ/qrcTechFile}"
    export QRCTECH_WC="${QRCTECH_WC:-$QRC_ROOT/QRC-Max/qrcTechFile}"
    export MPTDC_PNR_METAL_STACK="${MPTDC_PNR_METAL_STACK:-$stack}"
    export MPTDC_PNR_ROUTE_LAYER_NAMES="${MPTDC_PNR_ROUTE_LAYER_NAMES:-$route_layers}"
    export MPTDC_PNR_SIGNAL_TOP_LAYER="${MPTDC_PNR_SIGNAL_TOP_LAYER:-$signal_top}"
    export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-$floor_top}"
    export MPTDC_PNR_POWER_LAYER="${MPTDC_PNR_POWER_LAYER:-$floor_top}"
    export MPTDC_PNR_PHASE_TOP_LAYER="${MPTDC_PNR_PHASE_TOP_LAYER:-$floor_top}"
  else
    export CAPTABLE_DIR="$PDK_ROOT/cadence/v9_0/capTbl/v9_0_1"
    export CAPTABLE_BC="$CAPTABLE_DIR/${captbl_stem}_min.capTbl"
    export CAPTABLE_TC="$CAPTABLE_DIR/${captbl_stem}_typ.capTbl"
    export CAPTABLE_WC="$CAPTABLE_DIR/${captbl_stem}_max.capTbl"
    export QRC_ROOT="$PDK_ROOT/cadence/v10_1/QRC_pvs/v10_1_1/$qrc_family"
    export QRCTECH_BC="$QRC_ROOT/QRC-Min/qrcTechFile"
    export QRCTECH_TC="$QRC_ROOT/QRC-Typ/qrcTechFile"
    export QRCTECH_WC="$QRC_ROOT/QRC-Max/qrcTechFile"
    export MPTDC_PNR_METAL_STACK="$stack"
    export MPTDC_PNR_ROUTE_LAYER_NAMES="$route_layers"
    export MPTDC_PNR_SIGNAL_TOP_LAYER="$signal_top"
    export MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER="$floor_top"
    export MPTDC_PNR_POWER_LAYER="$floor_top"
    export MPTDC_PNR_PHASE_TOP_LAYER="$floor_top"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --genus-run-id)
      GENUS_RUN_ID="${2:?missing --genus-run-id value}"
      shift 2
      ;;
    --genus-run-dir)
      GENUS_RUN_DIR="$(abs_path "${2:?missing --genus-run-dir value}")"
      shift 2
      ;;
    --handoff-dir)
      HANDOFF_DIR="$(abs_path "${2:?missing --handoff-dir value}")"
      shift 2
      ;;
    --mode)
      MODE="${2:?missing --mode value}"
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

case "$MODE" in
  validate_only|discover_only|full_signoff) ;;
  *)
    echo "ERROR: unsupported MPTDC_DIGITAL_SIGNOFF_MODE=$MODE" >&2
    exit 2
    ;;
esac

RUN_ID="${RUN_ID:-${MPTDC_INNOVUS_RUN_ID:-MPTDC_TC_Closure_Innovus}}"
MPTDC_WORK_ROOT="$(abs_path "${MPTDC_WORK_ROOT:-work}")"
MPTDC_INNOVUS_WORK="$(abs_path "${MPTDC_INNOVUS_WORK:-$MPTDC_WORK_ROOT/innovus}")"
RESULT_DIR="$MPTDC_INNOVUS_WORK/$RUN_ID"
LOG_DIR="$RESULT_DIR/logs"
REPORT_DIR="$RESULT_DIR/reports"
MANIFEST_DIR="$RESULT_DIR/manifests"
mkdir -p "$LOG_DIR" "$REPORT_DIR" "$MANIFEST_DIR"
RUN_LOG="$LOG_DIR/digital_signoff_wrapper.log"

resolve_ro_handoff
configure_xh018_stack
export MPTDC_CLOSURE_SCOPE="${MPTDC_CLOSURE_SCOPE:-TC_ONLY}"
export MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-0}"
apply_recovery_defaults
guard_pg_policy

if [[ "$MODE" != "discover_only" && -n "${O1_RO_LEF_PATH:-}" && -f "${O1_RO_LEF_PATH:-}" ]]; then
  export_ro_lef_size "$O1_RO_LEF_PATH" "${O1_RO_CELL_NAME:-RO_tune6}"
fi

{
  echo "# MPTDC Digital Block Signoff Wrapper"
  echo "Author: Karim Sabra"
  echo "date: $(date -Iseconds)"
  echo "repo: $REPO_ROOT"
  echo "branch: $(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  echo "head: $(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  echo "mode: $MODE"
  echo "run_id: $RUN_ID"
  echo "result_dir: $RESULT_DIR"
  echo "genus_run_id: ${GENUS_RUN_ID:-unset}"
  echo "genus_run_dir: ${GENUS_RUN_DIR:-unset}"
  echo "handoff_dir: ${HANDOFF_DIR:-unset}"
  echo "row_infra_policy: NO_DEDICATED_CORE_TAP_ENDCAP_PENDING_DRC_LVS"
  echo "allow_no_core_tap_endcap_policy: ${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-0}"
  echo "closure_scope: $MPTDC_CLOSURE_SCOPE"
  echo "xh018_stack: ${MPTDC_XH018_STACK:-unset}"
  echo "technology_lef: ${TECHNOLOGY_LEF:-unset}"
  echo "captable_bc: ${CAPTABLE_BC:-unset}"
  echo "captable_tc: ${CAPTABLE_TC:-unset}"
  echo "captable_wc: ${CAPTABLE_WC:-unset}"
  echo "qrc_root: ${QRC_ROOT:-unset}"
  echo "route_layers: ${MPTDC_PNR_ROUTE_LAYER_NAMES:-unset}"
  echo "signal_top_layer: ${MPTDC_PNR_SIGNAL_TOP_LAYER:-unset}"
  echo "effective_top_floor_layer: ${MPTDC_PNR_EFFECTIVE_TOP_FLOOR_LAYER:-unset}"
  echo "ro_handoff_env: ${MPTDC_RO_HANDOFF_ENV_SOURCED:-unset}"
  echo "ro_handoff_override_status: ${MPTDC_RO_HANDOFF_OVERRIDE_STATUS:-unset}"
  echo "O1_USE_REAL_RO_ABSTRACT: ${O1_USE_REAL_RO_ABSTRACT:-unset}"
  echo "O1_RO_CELL_NAME: ${O1_RO_CELL_NAME:-unset}"
  echo "O1_RO_LEF_PATH: ${O1_RO_LEF_PATH:-unset}"
  echo "O1_RO_LEF_MACRO: $(if [[ -n "${O1_RO_LEF_PATH:-}" && -f "${O1_RO_LEF_PATH:-}" ]]; then lef_macro_name "$O1_RO_LEF_PATH" 2>/dev/null || true; else echo unset; fi)"
  echo "MPTDC_PNR_OSC_WIDTH_UM: ${MPTDC_PNR_OSC_WIDTH_UM:-unset}"
  echo "MPTDC_PNR_OSC_HEIGHT_UM: ${MPTDC_PNR_OSC_HEIGHT_UM:-unset}"
  echo "O1_RO_LIBERTY_PATH: ${O1_RO_LIBERTY_PATH:-unset}"
  echo "pd_tile_constraint_mode: ${MPTDC_PNR_PD_TILE_CONSTRAINT_MODE:-unset}"
  echo "pd_tile_apply_hier_box: ${MPTDC_PNR_PD_TILE_APPLY_HIER_BOX:-unset}"
  echo "pd_tile_region_margin_um: ${MPTDC_PNR_PD_TILE_REGION_MARGIN_UM:-unset}"
  echo "pd_physical_audit_mode: ${MPTDC_PD_PHYSICAL_AUDIT_MODE:-unset}"
  echo "pnr_core_util: ${MPTDC_PNR_CORE_UTIL:-unset}"
  echo "free_internal_placement: ${MPTDC_PNR_FREE_INTERNAL_PLACEMENT:-unset}"
  echo "skip_phase_buffer_preplace: ${MPTDC_PNR_SKIP_PHASE_BUFFER_PREPLACE:-unset}"
  echo "fix_ro_macros: ${MPTDC_PNR_FIX_RO_MACROS:-unset}"
  echo "create_ro_halos: ${MPTDC_PNR_CREATE_RO_HALOS:-unset}"
  echo "phase_buf_orient: ${MPTDC_PNR_PHASE_BUF_ORIENT:-unset}"
  echo "row_legal_orient_candidates: ${MPTDC_PNR_ROW_LEGAL_ORIENT_CANDIDATES:-unset}"
  echo "ro_phase_min_clearance_um: ${MPTDC_RO_PHASE_MIN_CLEARANCE_UM:-unset}"
  echo "ro_phase_origin_clearance_um: ${MPTDC_RO_PHASE_ORIGIN_CLEARANCE_UM:-unset}"
  echo "ro_phase_preplace_audit: ${MPTDC_RO_PHASE_PREPLACE_AUDIT:-unset}"
  echo "ro_phase_postplace_audit_fatal: ${MPTDC_RO_PHASE_POSTPLACE_AUDIT_FATAL:-unset}"
  echo "place_fast_tags_by_column: ${MPTDC_PNR_PLACE_FAST_TAGS_BY_COLUMN:-unset}"
  echo "fast_tag_column_side: ${MPTDC_PNR_FAST_TAG_COLUMN_SIDE:-unset}"
  echo "postroute_setup_passes: ${MPTDC_POSTROUTE_SETUP_OPT_PASSES:-unset}"
  echo "postroute_setup_max_passes: ${MPTDC_POSTROUTE_SETUP_OPT_MAX_PASSES:-unset}"
  echo "postroute_setup_plateau_guard: ${MPTDC_POSTROUTE_SETUP_PLATEAU_GUARD:-unset}"
  echo "fast_tag_targeted_eco: ${MPTDC_PNR_FAST_TAG_TARGETED_ECO:-unset}"
  echo "fast_tag_eco_protect_endpoint_flops: ${MPTDC_PNR_FAST_TAG_ECO_PROTECT_ENDPOINT_FLOPS:-unset}"
  echo "fast_tag_eco_upsize_small_gates: ${MPTDC_PNR_FAST_TAG_ECO_UPSIZE_SMALL_GATES:-unset}"
  echo "fast_tag_eco_path_driven: ${MPTDC_PNR_FAST_TAG_ECO_PATH_DRIVEN:-unset}"
  echo "fast_tag_eco_path_max_paths: ${MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_PATHS:-unset}"
  echo "fast_tag_eco_path_max_cells: ${MPTDC_PNR_FAST_TAG_ECO_PATH_MAX_CELLS:-unset}"
  echo "fast_tag_eco_name_fallback: ${MPTDC_PNR_FAST_TAG_ECO_NAME_FALLBACK:-unset}"
  echo "fast_tag_eco_allow_endpoint_flop_resize: ${MPTDC_PNR_FAST_TAG_ECO_ALLOW_ENDPOINT_FLOP_RESIZE:-unset}"
  echo "block_pg_pins: ${MPTDC_ENABLE_BLOCK_PG_PINS:-unset}"
  echo "block_pg_pin_layer: ${MPTDC_BLOCK_PG_PIN_LAYER:-unset}"
  echo "block_pg_pin_style: ${MPTDC_BLOCK_PG_PIN_STYLE:-unset}"
  echo "block_pg_pin_width_um: ${MPTDC_BLOCK_PG_PIN_WIDTH_UM:-unset}"
  echo "block_pg_pin_depth_um: ${MPTDC_BLOCK_PG_PIN_DEPTH_UM:-unset}"
  echo "block_pg_pin_outside_overlap_um: ${MPTDC_BLOCK_PG_PIN_OUTSIDE_OVERLAP_UM:-unset}"
  echo "block_pg_pin_create_mode: ${MPTDC_BLOCK_PG_PIN_CREATE_MODE:-unset}"
  echo "block_pg_pin_editpin_fallback: ${MPTDC_BLOCK_PG_PIN_EDITPIN_FALLBACK:-unset}"
  echo "pg_policy_guard: ${MPTDC_PG_POLICY_GUARD_STATUS:-unset}"
  echo "allow_legacy_pg_topology: ${MPTDC_ALLOW_LEGACY_PG_TOPOLOGY:-0}"
  echo "block_pg_stitch_stripes: ${MPTDC_ENABLE_BLOCK_PG_STITCH_STRIPES:-unset}"
  echo "block_pg_stitch_width_um: ${MPTDC_BLOCK_PG_STITCH_WIDTH_UM:-unset}"
  echo "block_pg_stitch_spacing_um: ${MPTDC_BLOCK_PG_STITCH_SPACING_UM:-unset}"
  echo "block_pg_stitch_set_distance_um: ${MPTDC_BLOCK_PG_STITCH_SET_DISTANCE_UM:-unset}"
  echo "block_pg_stitch_number_of_sets: ${MPTDC_BLOCK_PG_STITCH_NUMBER_OF_SETS:-unset}"
  echo "final_filler: ${MPTDC_ENABLE_FINAL_FILLER:-unset}"
  echo "post_filler_sroute: ${MPTDC_ENABLE_POST_FILLER_SROUTE:-unset}"
  echo "post_filler_sroute_required_bypass: ${MPTDC_BYPASS_POST_FILLER_SROUTE_REQUIRED:-0}"
  echo "preplace_pg_sroute: ${MPTDC_ENABLE_PREPLACE_PG_SROUTE:-unset}"
  echo "allow_provisional_preplace_pg: ${MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG:-unset}"
  echo "postplace_pre_route_sroute: ${MPTDC_ENABLE_POSTPLACE_PRE_ROUTE_SROUTE:-unset}"
  echo "postplace_pre_route_sroute_require_clean: ${MPTDC_REQUIRE_POSTPLACE_PRE_ROUTE_SROUTE_CLEAN:-unset}"
  echo "postplace_pre_route_accept_pg_verify_clean: ${MPTDC_POSTPLACE_PRE_ROUTE_ACCEPT_PG_VERIFY_CLEAN:-unset}"
  echo "postplace_pre_route_allow_dangling_only: ${MPTDC_POSTPLACE_PRE_ROUTE_ALLOW_DANGLING_ONLY:-unset}"
  echo "postplace_pre_route_dangling_only_max: ${MPTDC_POSTPLACE_PRE_ROUTE_DANGLING_ONLY_MAX:-unset}"
  echo "postplace_sroute_candidate_probe: ${MPTDC_ENABLE_POSTPLACE_SROUTE_CANDIDATE_PROBE:-unset}"
  echo "postplace_sroute_blockpin: ${MPTDC_ENABLE_POSTPLACE_SROUTE_BLOCKPIN:-unset}"
  echo "sroute_padpin_fallback: ${MPTDC_ENABLE_SROUTE_PADPIN_FALLBACK:-unset}"
  echo "sroute_mode_experiments: ${MPTDC_ENABLE_SROUTE_MODE_EXPERIMENTS:-unset}"
  echo "sroute_preserve_existing_routes: ${MPTDC_SROUTE_PRESERVE_EXISTING_ROUTES:-unset}"
  echo "sroute_connect_stripe: ${MPTDC_SROUTE_CONNECT_STRIPE:-unset}"
  echo "sroute_via_connect_to_shape: ${MPTDC_SROUTE_VIA_CONNECT_TO_SHAPE:-unset}"
  echo "sroute_target_search_distance_um: ${MPTDC_SROUTE_TARGET_SEARCH_DISTANCE_UM:-unset}"
  echo "sroute_core_pin_stop_route: ${MPTDC_SROUTE_CORE_PIN_STOP_ROUTE:-unset}"
  echo "ro_pg_probe: ${MPTDC_ENABLE_RO_PG_PROBE:-unset}"
  echo "ro_pg_hookup: ${MPTDC_ENABLE_RO_PG_HOOKUP:-unset}"
  echo "ro_pg_hookup_required: ${MPTDC_REQUIRE_RO_PG_HOOKUP:-unset}"
  echo "ro_pg_macro_patch: ${MPTDC_ENABLE_RO_PG_MACRO_PATCH:-unset}"
  echo "allow_ro_derived_pg_dangling: ${MPTDC_ALLOW_RO_DERIVED_PG_DANGLING:-unset}"
  echo "ro_pg_hookup_search_um: ${MPTDC_RO_PG_HOOKUP_SEARCH_UM:-unset}"
  echo "ro_pg_hookup_margin_um: ${MPTDC_RO_PG_HOOKUP_MARGIN_UM:-unset}"
  echo "ro_pg_hookup_spacing_um: ${MPTDC_RO_PG_HOOKUP_SPACING_UM:-unset}"
  echo "ro_pg_hookup_set_distance_um: ${MPTDC_RO_PG_HOOKUP_SET_DISTANCE_UM:-unset}"
  echo "db_display_limit: ${MPTDC_DB_DISPLAY_LIMIT:-unset}"
  echo "route_gate_sroute_recovery: ${MPTDC_ROUTE_GATE_SROUTE_RECOVERY:-unset}"
  echo "filler_add_fillers_with_drc: ${MPTDC_FILLER_ADD_FILLERS_WITH_DRC:-unset}"
  echo "require_drc_safe_filler: ${MPTDC_REQUIRE_DRC_SAFE_FILLER:-unset}"
  echo "route_repair_commands: ${MPTDC_ROUTE_REPAIR_COMMANDS:-unset}"
  echo "route_drc_review_continue: ${MPTDC_ALLOW_ROUTE_DRC_REVIEW_CONTINUE:-unset}"
  echo "route_drc_review_max_violations: ${MPTDC_ROUTE_DRC_REVIEW_MAX_VIOLATIONS:-unset}"
  echo "route_drc_review_allowed_classes: ${MPTDC_ROUTE_DRC_REVIEW_ALLOWED_CLASSES:-unset}"
  echo "dirty_route_timing_continue: ${MPTDC_ALLOW_DIRTY_ROUTE_TIMING_CONTINUE:-unset}"
  echo "labels: MPTDC_TC_PNR_CLOSURE DIGITAL_PNR_SIGNOFF_FLOW TC_ONLY NOT_MMMC_SIGNOFF READY_FOR_TAPEOUT_NO"
  echo
  echo "git status --short --untracked-files=no:"
  git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null || true
} | tee "$MANIFEST_DIR/run_manifest.txt" | tee "$RUN_LOG"

if [[ "$MODE" != "discover_only" && -n "$(git -C "$REPO_ROOT" status --short --untracked-files=no 2>/dev/null)" ]]; then
  echo "ERROR: tracked working tree must be clean before digital signoff launch." | tee -a "$RUN_LOG"
  exit 3
fi

if [[ "$MODE" != "discover_only" ]]; then
  if [[ "${MPTDC_CLOSURE_SCOPE:-}" != "TC_ONLY" ]]; then
    echo "ERROR: today's digital PNR closure wrapper requires MPTDC_CLOSURE_SCOPE=TC_ONLY." | tee -a "$RUN_LOG"
    exit 3
  fi
  if [[ "${O1_USE_REAL_RO_ABSTRACT:-0}" != "1" ]]; then
    echo "ERROR: O1_USE_REAL_RO_ABSTRACT=1 is required for TC-only physical closure." | tee -a "$RUN_LOG"
    exit 3
  fi
  if [[ -z "${O1_RO_LEF_PATH:-}" || ! -f "${O1_RO_LEF_PATH:-}" ]]; then
    echo "ERROR: O1_RO_LEF_PATH is not a readable canonical RO_tune6 LEF: ${O1_RO_LEF_PATH:-unset}" | tee -a "$RUN_LOG"
    exit 3
  fi
  if [[ "$(lef_macro_name "$O1_RO_LEF_PATH" 2>/dev/null || true)" != "${O1_RO_CELL_NAME:-RO_tune6}" ]]; then
    echo "ERROR: O1_RO_LEF_PATH macro is not exactly ${O1_RO_CELL_NAME:-RO_tune6}: $O1_RO_LEF_PATH" | tee -a "$RUN_LOG"
    exit 3
  fi
  export_ro_lef_size "$O1_RO_LEF_PATH" "${O1_RO_CELL_NAME:-RO_tune6}"
  {
    echo "MPTDC_PNR_OSC_WIDTH_UM=$MPTDC_PNR_OSC_WIDTH_UM"
    echo "MPTDC_PNR_OSC_HEIGHT_UM=$MPTDC_PNR_OSC_HEIGHT_UM"
    echo "MPTDC_RO_LEF_SIZE_STATUS=PASS"
  } | tee -a "$MANIFEST_DIR/run_manifest.txt" | tee -a "$RUN_LOG"
  if [[ -z "${O1_RO_LIBERTY_PATH:-}" || ! -f "${O1_RO_LIBERTY_PATH:-}" ]]; then
    echo "ERROR: O1_RO_LIBERTY_PATH is not readable: ${O1_RO_LIBERTY_PATH:-unset}" | tee -a "$RUN_LOG"
    exit 3
  fi
fi

report_tool_version() {
  local tool="$1"
  local path=""

  echo "===== $tool ====="
  path="$(type -P "$tool" 2>/dev/null || true)"
  if [[ -z "$path" ]]; then
    echo "MISSING"
    return 0
  fi

  if [[ "$tool" == "pvs" && "$path" == "/usr/sbin/pvs" ]]; then
    echo "NON_CADENCE_PVS_PATH=$path"
    echo "CADENCE_PVS_STATUS=MISSING_OR_NOT_IN_PATH"
    return 0
  fi

  echo "$path"
  case "$tool" in
    calibre)
      "$path" -version 2>&1 | head -40 || true
      ;;
    *)
      "$path" -version 2>&1 | head -40 || true
      ;;
  esac
}

{
  for t in innovus genus tempus quantus qrc voltus pvs pegasus calibre xrun verilator; do
    report_tool_version "$t"
  done
} > "$MANIFEST_DIR/tool_versions.rpt"

GATE_ARGS=()
if [[ -n "$GENUS_RUN_ID" ]]; then GATE_ARGS+=(--genus-run-id "$GENUS_RUN_ID"); fi
if [[ -n "$GENUS_RUN_DIR" ]]; then GATE_ARGS+=(--genus-run-dir "$GENUS_RUN_DIR"); fi
if [[ -n "$HANDOFF_DIR" ]]; then GATE_ARGS+=(--handoff-dir "$HANDOFF_DIR"); fi

if [[ "${#GATE_ARGS[@]}" -gt 0 ]]; then
  "$SCRIPT_DIR/check_mptdc_pre_pnr_gate.sh" "${GATE_ARGS[@]}" | tee "$REPORT_DIR/pre_pnr_gate.rpt" | tee -a "$RUN_LOG"
  if ! grep -q '^PRE_PNR_GATE=PASS$' "$REPORT_DIR/pre_pnr_gate.rpt"; then
    echo "ERROR: pre-PNR gate failed." | tee -a "$RUN_LOG"
    exit 4
  fi
else
  if [[ "$MODE" == "discover_only" ]]; then
    echo "INFO: no Genus handoff source passed; discover_only only inspects technology inputs." | tee -a "$RUN_LOG"
  else
    echo "WARN: no Genus handoff source passed; validate_only will not prove netlist handoff." | tee -a "$RUN_LOG"
  fi
fi

if [[ "$MODE" == "discover_only" ]]; then
  PDK_ROOT="${MPTDC_PDK_ROOT:-${PDK_ROOT:-}}"
  if [[ -z "$PDK_ROOT" ]]; then
    if [[ -d /eda/pdk/xfab/xh018 ]]; then
      PDK_ROOT=/eda/pdk/xfab/xh018
    elif [[ -d /data/pdk/xfab/xh018 ]]; then
      PDK_ROOT=/data/pdk/xfab/xh018
    else
      PDK_ROOT=/eda/pdk/xfab/xh018
    fi
  fi
  DISCOVERY_SCOPE="${MPTDC_DISCOVERY_SCOPE:-JIHD_ONLY}"
  SC_ROOT="${SC_ROOT:-$PDK_ROOT/diglibs/D_CELLS_JIHD/v6_0}"
  STD_LEF="${MPTDC_STDCELL_LEF:-}"
  if [[ -z "$STD_LEF" ]]; then
    for candidate in \
      "$SC_ROOT/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef" \
      "$SC_ROOT/LEF/v6_0_0/xh018/xh018_D_CELLS_JIHD.lef"; do
      if [[ -f "$candidate" ]]; then
        STD_LEF="$candidate"
        break
      fi
    done
  fi
  if [[ -z "$STD_LEF" || ! -f "$STD_LEF" ]]; then
    echo "ERROR: JIHD standard-cell LEF not found under SC_ROOT=$SC_ROOT" | tee -a "$RUN_LOG"
    exit 6
  fi

  DISCOVERY_ARGS=(--lef "$STD_LEF" --compact --out "$REPORT_DIR/xh018_cells_candidates.tcl")
  case "$DISCOVERY_SCOPE" in
    JIHD_ONLY|jihd|jihd_only)
      DISCOVERY_SCOPE="JIHD_ONLY"
      ;;
    ALL_PDK|all_pdk|pdk|mixed)
      DISCOVERY_SCOPE="ALL_PDK"
      DISCOVERY_ARGS+=(--root "$PDK_ROOT")
      ;;
    *)
      echo "ERROR: unsupported MPTDC_DISCOVERY_SCOPE=$DISCOVERY_SCOPE; use JIHD_ONLY or ALL_PDK" | tee -a "$RUN_LOG"
      exit 6
      ;;
  esac
  if [[ -d "$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range" ]]; then
    while IFS= read -r lib; do
      DISCOVERY_ARGS+=(--lib "$lib")
    done < <(
      find "$SC_ROOT/liberty_LPMOS/v6_0_0/PVT_1_80V_range" -maxdepth 1 -type f -name 'D_CELLS_JIHD_LPMOS_*.lib' | sort
    )
  elif [[ -n "${MPTDC_STDCELL_TC_LIB:-}" && -f "$MPTDC_STDCELL_TC_LIB" ]]; then
    DISCOVERY_ARGS+=(--lib "$MPTDC_STDCELL_TC_LIB")
  fi

  echo "DISCOVERY_LIBRARY=JIHD" | tee -a "$RUN_LOG"
  echo "DISCOVERY_SCOPE=$DISCOVERY_SCOPE" | tee -a "$RUN_LOG"
  echo "DISCOVERY_SC_ROOT=$SC_ROOT" | tee -a "$RUN_LOG"
  echo "DISCOVERY_STDCELL_LEF=$STD_LEF" | tee -a "$RUN_LOG"
  "$SCRIPT_DIR/discover_xh018_physical_cells.sh" \
    "${DISCOVERY_ARGS[@]}" \
    | tee "$REPORT_DIR/xh018_cells_candidates.rpt" | tee -a "$RUN_LOG"
  exit 0
fi

if command -v tclsh >/dev/null 2>&1; then
  set +e
  (
    cd "$REPO_ROOT"
    MPTDC_REPO_ROOT="$REPO_ROOT" \
    MPTDC_SIGNOFF_RESULT_DIR="$RESULT_DIR" \
    MPTDC_SIGNOFF_GENUS_RUN_ID="$GENUS_RUN_ID" \
    MPTDC_SIGNOFF_GENUS_RUN_DIR="$GENUS_RUN_DIR" \
    MPTDC_SIGNOFF_HANDOFF_DIR="$HANDOFF_DIR" \
    MPTDC_CLOSURE_SCOPE="$MPTDC_CLOSURE_SCOPE" \
    MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="$MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY" \
    O1_USE_REAL_RO_ABSTRACT="${O1_USE_REAL_RO_ABSTRACT:-1}" \
    O1_RO_LEF_PATH="${O1_RO_LEF_PATH:-}" \
    O1_RO_LIBERTY_PATH="${O1_RO_LIBERTY_PATH:-}" \
    MPTDC_DIGITAL_SIGNOFF_SOURCE_ONLY=1 \
      tclsh MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl
  ) 2>&1 | tee "$REPORT_DIR/source_check.rpt" | tee -a "$RUN_LOG"
  source_rc=${PIPESTATUS[0]}
  set -e
else
  echo "ERROR: tclsh is required for source validation." | tee -a "$RUN_LOG"
  exit 127
fi

if [[ "$source_rc" != "0" ]]; then
  echo "ERROR: digital signoff source check failed. Review $REPORT_DIR/source_check.rpt" | tee -a "$RUN_LOG"
  exit "$source_rc"
fi

if [[ "$MODE" == "validate_only" ]]; then
  echo "MPTDC_DIGITAL_SIGNOFF_MODE=validate_only: source gates passed; Innovus not launched." | tee -a "$RUN_LOG"
  exit 0
fi

if [[ "${MPTDC_DIGITAL_SIGNOFF_APPROVED:-0}" != "1" ]]; then
  echo "ERROR: full_signoff launches Innovus. Set MPTDC_DIGITAL_SIGNOFF_APPROVED=1 after review." | tee -a "$RUN_LOG"
  exit 5
fi

if [[ "${MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY:-0}" != "1" ]]; then
  echo "ERROR: provisional implementation requires MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY=1." | tee -a "$RUN_LOG"
  echo "This does not allow final PASS; it records ROW_INFRA_STATUS=PROVISIONAL." | tee -a "$RUN_LOG"
  exit 5
fi

if ! command -v innovus >/dev/null 2>&1; then
  echo "ERROR: innovus not found in PATH; run this on the lab server." | tee -a "$RUN_LOG"
  exit 127
fi

set +e
(
  cd "$REPO_ROOT"
  MPTDC_REPO_ROOT="$REPO_ROOT" \
  MPTDC_SIGNOFF_RESULT_DIR="$RESULT_DIR" \
  MPTDC_SIGNOFF_GENUS_RUN_ID="$GENUS_RUN_ID" \
  MPTDC_SIGNOFF_GENUS_RUN_DIR="$GENUS_RUN_DIR" \
  MPTDC_SIGNOFF_HANDOFF_DIR="$HANDOFF_DIR" \
  MPTDC_CLOSURE_SCOPE="$MPTDC_CLOSURE_SCOPE" \
  MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY="$MPTDC_ALLOW_NO_CORE_TAP_ENDCAP_POLICY" \
  MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG="${MPTDC_ALLOW_PROVISIONAL_PREPLACE_PG:-1}" \
  MPTDC_CTS_CLK_SYS_MAX_ROOT_FANOUT="${MPTDC_CTS_CLK_SYS_MAX_ROOT_FANOUT:-100}" \
  MPTDC_STDCELL_FAMILY="${MPTDC_STDCELL_FAMILY:-JIHD}" \
  MPTDC_STDCELL_SITE="${MPTDC_STDCELL_SITE:-core_jihd}" \
  O1_USE_REAL_RO_ABSTRACT="${O1_USE_REAL_RO_ABSTRACT:-1}" \
  O1_RO_LEF_PATH="${O1_RO_LEF_PATH:-}" \
  O1_RO_LIBERTY_PATH="${O1_RO_LIBERTY_PATH:-}" \
    innovus -nowin -init MPTDC/pnr/scripts/innovus_mptdc_digital_signoff.tcl \
      -log "$LOG_DIR/innovus_mptdc_digital_signoff.log"
) 2>&1 | tee -a "$RUN_LOG"
innovus_rc=${PIPESTATUS[0]}
set -e

fatal_audit="$REPORT_DIR/innovus_fatal_message_audit.rpt"
fatal_pattern='TECHLIB-702|TECHLIB-704|IMPDB-2504|IMPECO-560|IMPOPT-3115|IMPDB-1221|IMPCCOPT-4255'
fatal_found=0
: > "$fatal_audit"
for log_file in "$RUN_LOG" "$LOG_DIR/innovus_mptdc_digital_signoff.log"; do
  if [[ -f "$log_file" ]]; then
    if grep -E "$fatal_pattern" "$log_file" >> "$fatal_audit"; then
      fatal_found=1
    fi
  fi
done
if [[ "$fatal_found" == "1" ]]; then
  echo "ERROR: fatal Innovus message audit failed. Review $fatal_audit" | tee -a "$RUN_LOG"
  exit 6
fi
{
  echo "INNOVUS_FATAL_MESSAGE_AUDIT=PASS"
  echo "REQUIRED_ABSENT_MESSAGES=$fatal_pattern"
} > "$fatal_audit"

if [[ "$innovus_rc" != "0" ]]; then
  echo "ERROR: Innovus exited with code $innovus_rc." | tee -a "$RUN_LOG"
  exit "$innovus_rc"
fi
