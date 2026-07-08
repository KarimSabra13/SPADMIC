#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Tapeout Readiness Gate
#
# This gate is intentionally stricter than a smoke test and more portable than
# the Xcelium-only full regression.  It runs Verilator lint/unit coverage when
# Verilator is available, and it also runs the maintained Xcelium regressions
# when xrun is available on the host.
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$PROJECT_ROOT/MPTDC"
BUILD_ROOT="$TOP_ROOT/build/tapeout_readiness"

mkdir -p "$BUILD_ROOT"
export CCACHE_DIR="$BUILD_ROOT/ccache"
mkdir -p "$CCACHE_DIR"

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
  local top_module="$1"
  cd "$PROJECT_ROOT" || return 1
  verilator --lint-only --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    --top-module "$top_module"
}

run_verilator_tb() {
  local tb="$1"
  local mdir="$BUILD_ROOT/obj_$tb"
  local tb_file=""

  for dir in "$TOP_ROOT/tb" "$PROJECT_ROOT/position/tb" "$PROJECT_ROOT/arb/tb"; do
    if [[ -f "$dir/$tb.sv" ]]; then
      tb_file="$dir/$tb.sv"
      break
    fi
  done
  [[ -n "$tb_file" ]] || return 1

  rm -rf "$mdir"
  cd "$PROJECT_ROOT" || return 1
  verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    "$tb_file" \
    --top-module "$tb" \
    --Mdir "$mdir" || return 1

  "$mdir/V$tb"
}

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Tapeout Readiness Gate"
echo "  TOP_ROOT:     $TOP_ROOT"
echo "  MPTDC_ROOT:   $MPTDC_ROOT"
echo "  BUILD_ROOT:   $BUILD_ROOT"
echo "═══════════════════════════════════════════════════════"

VERILATOR_TBS=(
  tb_spadmic_arb_modes
  tb_spadmic_arb_stress
  tb_spadmic_i2c_control_plane_unit
  tb_spadmic_i2c_matrix_top_16b_unit
  tb_spadmic_matrix_or_tree_unit
  tb_spadmic_matrix_snapshot_frontend_unit
  tb_spadmic_matrix_reset_ctrl_unit
  tb_spadmic_event_coordinator_modes_unit
  tb_spadmic_position_snapshot_packetizer_unit
  tb_spadmic_position_modes_unit
  tb_spadmic_position_snapshot_cluster_unit
  tb_spadmic_event_bundle_tx_unit
  tb_spadmic_ddr16_tx_pairer_unit
  tb_spadmic_ddrs2_adapter_unit
  tb_spadmic_output_fifo_unit
  tb_spadmic_output_fifo_ddr_marker_unit
  tb_spadmic_matrix_cfg_ctrl_unit
  tb_spadmic_matrix_cfg_cout_readback_unit
  tb_spadmic_matrix_top_csr_unit
  tb_spadmic_matrix_top_csr_16b_unit
  tb_spadmic_top_matrix_v1_shell_unit
  tb_spadmic_top_matrix_v1_both_full_unit
  tb_spadmic_top_matrix_v1_skew_campaign
  tb_spadmic_top_output_pressure_unit
  tb_spadmic_top_output_fifo_pressure_integration_unit
  tb_spadmic_top_reset_during_event_unit
  tb_spadmic_top_reset_during_matrix_cfg_unit
  tb_spadmic_top_mode_transition_unit
  tb_spadmic_top_sequencer_unit
  tb_spadmic_stress_csr
  tb_spadmic_stress_position
  tb_spadmic_ddr_tx_unit
)

if command -v verilator >/dev/null 2>&1; then
  run_step "Verilator legacy TOP lint" run_verilator_top_lint spadmic_top_v1
  run_step "Verilator matrix TOP lint" run_verilator_top_lint spadmic_top_matrix_v1
  for tb in "${VERILATOR_TBS[@]}"; do
    run_step "Verilator unit: $tb" run_verilator_tb "$tb"
  done
else
  skip_step "Verilator full TOP lint" "verilator not found"
  for tb in "${VERILATOR_TBS[@]}"; do
    skip_step "Verilator unit: $tb" "verilator not found"
  done
fi

if command -v xrun >/dev/null 2>&1; then
  run_step "Xcelium TOP smoke" bash "$TOP_ROOT/ci/run_smoke.sh"
  run_step "Xcelium directed regression" bash "$TOP_ROOT/ci/run_directed_regression.sh"
else
  skip_step "Xcelium TOP smoke" "xrun not found"
  skip_step "Xcelium directed regression" "xrun not found"
fi
skip_step "Xcelium VIP smoke" "retired standalone VIP"
skip_step "Xcelium VIP feature suite" "retired standalone VIP"

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
