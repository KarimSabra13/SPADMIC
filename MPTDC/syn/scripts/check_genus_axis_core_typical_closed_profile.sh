#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROFILE="$SCRIPT_DIR/profiles/genus_axis_core_typical_closed.sh"
CANONICAL_WRAPPER="$SCRIPT_DIR/run_genus_axis_core_typical_closed.sh"

# shellcheck source=profiles/genus_axis_core_typical_closed.sh
source "$PROFILE"

fail() {
  echo "PROFILE_CHECK=FAIL" >&2
  echo "ERROR: $*" >&2
  exit 1
}

assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"
  [[ "$actual" == "$expected" ]] || fail "$label expected '$expected', got '$actual'"
}

for script in \
  "$PROFILE" \
  "$CANONICAL_WRAPPER" \
  "$SCRIPT_DIR/server_run_genus_mptdc_axis_core_timing_close.sh" \
  "$SCRIPT_DIR/server_run_genus_mptdc_typical.sh" \
  "$SCRIPT_DIR/server_run_genus_mptdc_timing_closure.sh" \
  "$SCRIPT_DIR/server_run_genus_mptdc_final_typical.sh"; do
  [[ -f "$script" ]] || fail "missing script: $script"
  bash -n "$script" || fail "bash syntax check failed: $script"
done

mptdc_genus_axis_core_typical_closed_apply "$SYN_DIR"

assert_eq "profile id" "axis_core_typical_closed_on22_x1" "$MPTDC_GENUS_BASELINE_PROFILE_ID"
assert_eq "signoff boundary" "TYPICAL_ONLY_NOT_MMMC" "$MPTDC_SIGNOFF_BOUNDARY"
assert_eq "optimization profile" "timing_ultra" "$MPTDC_GENUS_CLOSURE_PROFILE"
assert_eq "drain RTL policy" "STRIDE2" "$MPTDC_OPT_MODE"
assert_eq "standard-cell family" "JIHD" "$MPTDC_STDCELL_FAMILY"
assert_eq "fast-tag source remap policy" "0" "$MPTDC_GENUS_BASELINE_FAST_TAG_SOURCE_CELL_REMAP_ENABLED"
assert_eq "fast-tag source remap disable" "1" "$MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL_DISABLE"
[[ ! -v MPTDC_FAST_TAG_REPAIR_EXACT_SOURCE_CELL ]] || fail "disabled source remap left an exact source cell set"
assert_eq "repair8 fast-tag stage" "1" "$MPTDC_GENUS_REPAIR_FAST_TAG_PD"
assert_eq "repair8 exact source-drive stage" "1" "$MPTDC_GENUS_REPAIR4_EXACT_FAST_TAG_SOURCE_DRIVE"
assert_eq "repair8 exact close stage" "1" "$MPTDC_GENUS_REPAIR5_EXACT_FAST_TAG_CLOSE"
assert_eq "fast-tag C-to-D budget" "1.333" "$MPTDC_FAST_TAG_REPAIR_EXACT_MAX_DELAY_NS"
assert_eq "tight fast-tag budget guard" "0" "$MPTDC_ALLOW_TIGHT_FAST_TAG_MAX_DELAY"
assert_eq "broad PD repair" "0" "$MPTDC_GENUS_REPAIR_PD_HIT_TO_NFAST_LOCAL"
assert_eq "broad PD max delay" "0" "$MPTDC_PD_HIT_TO_NFAST_MAX_DELAY_NS"
assert_eq "broad PD max transition" "0" "$MPTDC_PD_HIT_TO_NFAST_MAX_TRANSITION_NS"
assert_eq "scoped ON22 repair" "1" "$MPTDC_GENUS_REPAIR_PD_LOCAL_ON22"
assert_eq "ON22 source" "ON22JIHDX0" "$MPTDC_PD_LOCAL_ON22_SOURCE_CELL"
assert_eq "ON22 requested targets" "ON22JIHDX1 ON22JIHDX2" "$MPTDC_PD_LOCAL_ON22_TARGET_CELLS"
assert_eq "ON22 X2 guard" "0" "$MPTDC_PD_LOCAL_ON22_ALLOW_X2"
assert_eq "ON22 expected effective target" "ON22JIHDX1" "$MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_EFFECTIVE_TARGET"
effective_target=""
for target in $MPTDC_PD_LOCAL_ON22_TARGET_CELLS; do
  if [[ "$target" == "ON22JIHDX2" && "$MPTDC_PD_LOCAL_ON22_ALLOW_X2" != "1" ]]; then
    continue
  fi
  effective_target="$target"
  break
done
assert_eq "ON22 computed effective target" "$MPTDC_GENUS_BASELINE_PD_LOCAL_EXPECTED_EFFECTIVE_TARGET" "$effective_target"
assert_eq "ON22 endpoint count" "448" "$MPTDC_PD_LOCAL_ON22_EXPECTED_ENDPOINTS"
assert_eq "ON22 driver count policy" "AUTO" "$MPTDC_PD_LOCAL_ON22_EXPECTED_DRIVERS"
assert_eq "ON22 cell count policy" "AUTO" "$MPTDC_PD_LOCAL_ON22_EXPECTED_CELLS"
assert_eq "ON22 discovery" "TIMING_REPORT" "$MPTDC_PD_LOCAL_ON22_DISCOVERY_MODE"
assert_eq "ON22 timing path limit" "1000" "$MPTDC_PD_LOCAL_ON22_TIMING_MAX_PATHS"
assert_eq "ON22 apply resize" "1" "$MPTDC_PD_LOCAL_ON22_APPLY_REPAIR"

[[ "$O13_FILELIST_PATH" == "$SYN_DIR/filelist_axis_core_typical_closed.f" ]] || fail "canonical filelist path mismatch"
[[ "$O13_SDC_PATH" == "$SYN_DIR/inputs/mptdc_axis_core_typical_closed.sdc" ]] || fail "canonical SDC path mismatch"

if grep -Eq 'MPTDC_PD_LOCAL_ON22_|MPTDC_FAST_TAG_REPAIR_|MPTDC_GENUS_REPAIR_PD_' "$CANONICAL_WRAPPER"; then
  fail "canonical wrapper contains backend timing knobs; keep them in the profile adapter"
fi

# Confirm in a fresh shell that one legacy timing override is rejected before
# the profile exports any backend variables of its own.
if bash -c '
  set -euo pipefail
  source "$1"
  export MPTDC_PD_LOCAL_ON22_ALLOW_X2=1
  mptdc_genus_axis_core_typical_closed_reject_external_policy >/dev/null 2>&1
' _ "$PROFILE"; then
  fail "legacy environment override was not rejected"
fi

echo "PROFILE_CHECK=PASS"
echo "PROFILE_ID=$MPTDC_GENUS_BASELINE_PROFILE_ID"
echo "PROFILE_BASELINE_COMMIT=$MPTDC_GENUS_BASELINE_SOURCE_COMMIT"
echo "PROFILE_BASELINE_RUN=$MPTDC_GENUS_BASELINE_SOURCE_RUN"
