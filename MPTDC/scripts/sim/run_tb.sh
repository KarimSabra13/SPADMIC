#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Build and run one unit or integration SystemVerilog testbench.
# Usage   : bash scripts/sim/run_tb.sh <tb_name>
#           [--sim verilator|xcelium|vcs] [--waves] [--seed N]
#           [--fast-tag-encoding raw_lfsr_tag|raw_galois_tag]
#           [--freq-mode nominal|r750_delta5]
#           [--mptdc-opt-mode BASELINE|SAFE_TEARDOWN|ROW_SKIP|STRIDE2|CLEAR_EARLY]
#           [--scratch-root DIR]
# Context : Primary filelist-driven runner for benches under tb/unit and
#           tb/int.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../mptdc_flow_common.sh
source "$REPO_ROOT/scripts/mptdc_flow_common.sh"
RTL_DIR="$REPO_ROOT/rtl"
TB_DIR="$REPO_ROOT/tb"
MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
case "$MPTDC_WORK_ROOT" in
  /*) ;;
  *) MPTDC_WORK_ROOT="$(cd "$REPO_ROOT/.." && pwd)/$MPTDC_WORK_ROOT" ;;
esac
BUILD_DIR="$MPTDC_WORK_ROOT/scratch/sim"
SCRATCH_ROOT="${MPTDC_SIM_SCRATCH_ROOT:-}"

# Defaults
SIM="verilator"
WAVES=0
SEED=""
TB_NAME=""
FAST_TAG_ENCODING="${MPTDC_FAST_TAG_ENCODING:-raw_lfsr_tag}"
FREQ_MODE="${MPTDC_FREQ_MODE:-nominal}"
OPT_MODE="${MPTDC_OPT_MODE:-STRIDE2}"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)     SIM="$2"; shift 2 ;;
    --waves)   WAVES=1; shift ;;
    --seed)    SEED="$2"; shift 2 ;;
    --fast-tag-encoding) FAST_TAG_ENCODING="$2"; shift 2 ;;
    --freq-mode) FREQ_MODE="$2"; shift 2 ;;
    --mptdc-opt-mode|--opt-mode) OPT_MODE="$2"; shift 2 ;;
    --scratch-root) SCRATCH_ROOT="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 <tb_name> [--sim verilator|xcelium|vcs] [--waves] [--seed N] [--fast-tag-encoding raw_lfsr_tag|raw_galois_tag] [--freq-mode nominal|r750_delta5] [--mptdc-opt-mode BASELINE|SAFE_TEARDOWN|ROW_SKIP|STRIDE2|CLEAR_EARLY] [--scratch-root DIR]"
      exit 0
      ;;
    *)
      if [[ -z "$TB_NAME" ]]; then
        TB_NAME="$1"
      else
        echo "Error: unexpected argument '$1'" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$TB_NAME" ]]; then
  echo "Error: no testbench name specified" >&2
  echo "Usage: $0 <tb_name> [--sim verilator|xcelium|vcs] [--waves] [--seed N]"
  exit 1
fi

case "$FAST_TAG_ENCODING" in
  raw_lfsr_tag) FAST_TAG_DEFINE_ARGS=() ;;
  raw_galois_tag) FAST_TAG_DEFINE_ARGS=(+define+MPTDC_FAST_TAG_GALOIS) ;;
  *)
    echo "Error: --fast-tag-encoding must be raw_lfsr_tag or raw_galois_tag" >&2
    exit 1
    ;;
esac

case "$FREQ_MODE" in
  nominal) FREQ_MODE_DEFINE_ARGS=() ;;
  r750_delta5) FREQ_MODE_DEFINE_ARGS=(+define+MPTDC_FREQ_R750_DELTA5) ;;
  *)
    echo "Error: --freq-mode must be nominal or r750_delta5" >&2
    exit 1
    ;;
esac

OPT_MODE_DEFINE_TEXT="$(mptdc_common_opt_mode_define_args "$OPT_MODE")"
OPT_MODE_DEFINE_ARGS=()
if [[ -n "$OPT_MODE_DEFINE_TEXT" ]]; then
  mapfile -t OPT_MODE_DEFINE_ARGS <<< "$OPT_MODE_DEFINE_TEXT"
fi
OPT_MODE_DEFINE_CSV="$(mptdc_common_opt_mode_define_csv "$OPT_MODE")"

if [[ -n "$SCRATCH_ROOT" ]]; then
  case "$SCRATCH_ROOT" in
    /*) ;;
    *) SCRATCH_ROOT="$REPO_ROOT/$SCRATCH_ROOT" ;;
  esac
  BUILD_DIR="$SCRATCH_ROOT"
fi

# Find TB file
TB_FILE=""
for dir in "$TB_DIR/unit" "$TB_DIR/int"; do
  if [[ -f "$dir/${TB_NAME}.sv" ]]; then
    TB_FILE="$dir/${TB_NAME}.sv"
    break
  fi
done

if [[ -z "$TB_FILE" ]]; then
  echo "Error: testbench '$TB_NAME' not found in $TB_DIR/{unit,int}/" >&2
  exit 1
fi

# Collect RTL sources from filelist
RTL_FILES=()
while IFS= read -r line; do
  # Skip comments and empty lines
  line="${line%%//*}"  # strip inline comments
  line="${line#"${line%%[![:space:]]*}"}"  # trim leading whitespace
  [[ -z "$line" ]] && continue
  RTL_FILES+=("$RTL_DIR/../$line")
done < "$RTL_DIR/filelist.f"

# TB common files
TB_COMMON=(
  "$TB_DIR/common/mptdc_tb_pkg.sv"
  "$TB_DIR/common/mptdc_char_tb_pkg.sv"
  "$TB_DIR/common/mptdc_raw_monitor.sv"
)

# Build directory
TB_BUILD="$BUILD_DIR/${TB_NAME}_${FAST_TAG_ENCODING}_${FREQ_MODE}_${OPT_MODE}"
mkdir -p "$TB_BUILD"

# Keep ccache writes inside the build tree unless the caller already chose a
# location. This matters in sandboxed local runs where ~/.cache may be read-only.
export CCACHE_DIR="${CCACHE_DIR:-$BUILD_DIR/ccache}"
export CCACHE_TEMPDIR="${CCACHE_TEMPDIR:-$BUILD_DIR/ccache/tmp}"
mkdir -p "$CCACHE_DIR" "$CCACHE_TEMPDIR"

echo "=== MPTDC v2.7 TB Runner ==="
echo "  Testbench: $TB_NAME"
echo "  Simulator: $SIM"
echo "  Fast tag encoding: $FAST_TAG_ENCODING"
echo "  Frequency mode: $FREQ_MODE"
echo "  MPTDC opt mode: $OPT_MODE"
echo "  MPTDC opt defines: ${OPT_MODE_DEFINE_CSV:-none}"
echo "  Build dir: $TB_BUILD"
echo ""

# Plusargs common to all simulators (seed handled per-sim below)
PLUSARGS=()

case "$SIM" in
  verilator)
    VERILATOR_FLAGS=(
      --binary
      --timing
      -Wall
      -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC
      -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
      -Wno-MULTITOP -Wno-SYNCASYNCNET -Wno-UNOPTFLAT -Wno-PINCONNECTEMPTY
      -Wno-VARHIDDEN
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      "${OPT_MODE_DEFINE_ARGS[@]}"
      --Mdir "$TB_BUILD"
      --top-module "$TB_NAME"
      -o "$TB_NAME"
    )

    if [[ $WAVES -eq 1 ]]; then
      VERILATOR_FLAGS+=(--trace --trace-structs)
    fi

    echo "--- Compiling with Verilator ---"
    verilator "${VERILATOR_FLAGS[@]}" \
      "${RTL_FILES[@]}" "${TB_COMMON[@]}" "$TB_FILE" 2>&1

    echo ""
    echo "--- Running simulation ---"
    if [[ -n "$SEED" ]]; then
      PLUSARGS+=("+verilator+seed+$SEED")
    fi

    cd "$TB_BUILD"
    ./"$TB_NAME" "${PLUSARGS[@]}" 2>&1
    SIM_RC=$?

    if [[ $SIM_RC -eq 0 ]]; then
      echo ""
      echo "=== SIMULATION PASSED ==="
    else
      echo ""
      echo "=== SIMULATION FAILED (rc=$SIM_RC) ==="
      exit $SIM_RC
    fi
    ;;

  xcelium)
    echo "--- Compiling with Xcelium ---"
    XRUN_FLAGS=(
      -64
      -sv
      -access +rwc
      -timescale 1ps/1ps
      -nowarn DLCVAR
      -top "$TB_NAME"
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      "${OPT_MODE_DEFINE_ARGS[@]}"
    )

    if [[ -n "$SEED" ]]; then
      XRUN_FLAGS+=(-svseed "$SEED")
    fi

    if [[ $WAVES -eq 1 ]]; then
      XRUN_FLAGS+=(-input "@database -open waves -into $TB_BUILD/waves.shm -default @probe -create $TB_NAME -all -depth all @run @exit")
    fi

    cd "$TB_BUILD"
    xrun "${XRUN_FLAGS[@]}" \
      "${RTL_FILES[@]}" "${TB_COMMON[@]}" "$TB_FILE" "${PLUSARGS[@]}" 2>&1
    ;;

  vcs)
    echo "--- Compiling with VCS ---"
    VCS_FLAGS=(
      -full64
      -sverilog
      -timescale=1ps/1ps
      +lint=all
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      "${OPT_MODE_DEFINE_ARGS[@]}"
      -top "$TB_NAME"
      -o "$TB_BUILD/$TB_NAME"
    )

    if [[ -n "$SEED" ]]; then
      VCS_FLAGS+=("+ntb_random_seed=$SEED")
    fi

    vcs "${VCS_FLAGS[@]}" \
      "${RTL_FILES[@]}" "${TB_COMMON[@]}" "$TB_FILE" 2>&1
    echo ""
    echo "--- Running simulation ---"
    "$TB_BUILD/$TB_NAME" "${PLUSARGS[@]}" 2>&1
    ;;

  *)
    echo "Error: unknown simulator '$SIM' (use verilator, xcelium, or vcs)" >&2
    exit 1
    ;;
esac
