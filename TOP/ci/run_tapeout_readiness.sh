#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Tapeout Readiness Gate
#
# This gate is intentionally stricter than a smoke test and more portable than
# the Xcelium-only full regression.  It always runs Verilator lint/unit coverage
# for the active TOP RTL, and it also runs the maintained Xcelium regressions
# when xrun is available on the host.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$PROJECT_ROOT/MPTDC"
BUILD_ROOT="$TOP_ROOT/build/tapeout_readiness"

mkdir -p "$BUILD_ROOT"

PASS=0
FAIL=0
SKIP=0
FAILED_LIST=()
SKIPPED_LIST=()

run_step() {
  local name="$1"
  shift

  echo ""
  echo "─── $name ─────────────────────────────────────────"
  if "$@"; then
    PASS=$((PASS + 1))
    echo "  PASS: $name"
  else
    FAIL=$((FAIL + 1))
    FAILED_LIST+=("$name")
    echo "  FAIL: $name"
  fi
}

skip_step() {
  local name="$1"
  local reason="$2"
  SKIP=$((SKIP + 1))
  SKIPPED_LIST+=("$name ($reason)")
  echo ""
  echo "─── $name ─────────────────────────────────────────"
  echo "  SKIP: $reason"
}

read_flist() {
  local root="$1"
  local flist="$2"
  sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' "$flist" | sed "s#^#$root/#"
}

mapfile -t MPTDC_FILES < <(read_flist "$MPTDC_ROOT" "$MPTDC_ROOT/rtl/filelist.f")
mapfile -t TOP_FILES   < <(read_flist "$TOP_ROOT"   "$TOP_ROOT/filelist.f")

VERILATOR_WARNINGS=(
  -Wall
  -Wno-fatal
  -Wno-UNUSEDSIGNAL
  -Wno-UNDRIVEN
  -Wno-DECLFILENAME
  -Wno-WIDTHEXPAND
  -Wno-WIDTHTRUNC
  -Wno-UNUSEDPARAM
  -Wno-PINMISSING
  -Wno-UNUSEDGENVAR
  -Wno-CASEINCOMPLETE
  -Wno-LATCH
  -Wno-REALCVT
  -Wno-INITIALDLY
  -Wno-COMBDLY
  -Wno-PINCONNECTEMPTY
  -Wno-SYNCASYNCNET
  -Wno-UNOPTFLAT
)

run_verilator_top_lint() {
  cd "$PROJECT_ROOT" || return 1
  verilator --lint-only --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    --top-module spadmic_top_v1
}

run_verilator_tb() {
  local tb="$1"
  local mdir="$BUILD_ROOT/obj_$tb"

  rm -rf "$mdir"
  cd "$PROJECT_ROOT" || return 1
  verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    "$TOP_ROOT/tb/$tb.sv" \
    --top-module "$tb" \
    --Mdir "$mdir" || return 1

  "$mdir/V$tb"
}

run_vip_feature_suite() {
  local tests=(
    ctrl_reject
    reset_recovery
    bp_stress
    i2c_end_to_end
    tdc_modes
    pos_clusters
  )

  for test in "${tests[@]}"; do
    bash "$TOP_ROOT/scripts/sim/run_vip_test.sh" "$test" || return 1
  done
}

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Tapeout Readiness Gate"
echo "  TOP_ROOT:     $TOP_ROOT"
echo "  MPTDC_ROOT:   $MPTDC_ROOT"
echo "  BUILD_ROOT:   $BUILD_ROOT"
echo "═══════════════════════════════════════════════════════"

run_step "Verilator full TOP lint" run_verilator_top_lint

VERILATOR_TBS=(
  tb_spadmic_correlated_tx_unit
  tb_spadmic_i2c_control_plane_unit
  tb_spadmic_top_sequencer_unit
  tb_spadmic_stress_csr
  tb_spadmic_stress_position
  tb_spadmic_ddr_tx_unit
)

for tb in "${VERILATOR_TBS[@]}"; do
  run_step "Verilator unit: $tb" run_verilator_tb "$tb"
done

if command -v xrun >/dev/null 2>&1; then
  run_step "Xcelium TOP smoke" bash "$TOP_ROOT/ci/run_smoke.sh"
  run_step "Xcelium directed regression" bash "$TOP_ROOT/ci/run_directed_regression.sh"
  run_step "Xcelium VIP smoke" bash "$TOP_ROOT/ci/run_vip_smoke.sh"
  run_step "Xcelium VIP feature suite" run_vip_feature_suite
else
  skip_step "Xcelium TOP smoke" "xrun not found"
  skip_step "Xcelium directed regression" "xrun not found"
  skip_step "Xcelium VIP smoke" "xrun not found"
  skip_step "Xcelium VIP feature suite" "xrun not found"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  TAPEOUT READINESS: $PASS pass, $FAIL fail, $SKIP skipped"
if [[ $FAIL -gt 0 ]]; then
  echo "  Failed: ${FAILED_LIST[*]}"
fi
if [[ $SKIP -gt 0 ]]; then
  echo "  Skipped: ${SKIPPED_LIST[*]}"
fi
echo "═══════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
