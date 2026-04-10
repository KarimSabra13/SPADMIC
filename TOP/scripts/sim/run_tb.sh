#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Single Directed Bench Runner (Xcelium)
# Usage: bash scripts/sim/run_tb.sh <tb_name> [--sim xrun|verilator] [--waves]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MPTDC_ROOT="$(cd "$REPO_ROOT/../MPTDC" 2>/dev/null && pwd || echo "$REPO_ROOT/../MPTDC")"

TB_NAME="${1:?Usage: run_tb.sh <tb_name> [options]}"
SIM="xrun"
WAVES=0
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)   SIM="$2"; shift 2 ;;
    --waves) WAVES=1; shift ;;
    *)       echo "Unknown option: $1"; exit 1 ;;
  esac
done

# Find testbench file
TB_FILE=""
for dir in "$REPO_ROOT/tb" "$REPO_ROOT/tb/unit" "$REPO_ROOT/tb/int"; do
  if [[ -f "$dir/${TB_NAME}.sv" ]]; then
    TB_FILE="$dir/${TB_NAME}.sv"
    break
  fi
done
if [[ -z "$TB_FILE" ]]; then
  echo "ERROR: Cannot find ${TB_NAME}.sv in tb/, tb/unit/, or tb/int/"
  exit 1
fi

BUILD_DIR="$REPO_ROOT/build/directed/$TB_NAME"
mkdir -p "$BUILD_DIR"

echo "═══════════════════════════════════════════════════════"
echo "  Directed Bench: $TB_NAME"
echo "═══════════════════════════════════════════════════════"

if [[ "$SIM" == "xrun" ]]; then
  XRUN_ARGS=(
    -64 -sv -access +rwc
    -timescale 1ps/1ps
    -nowarn DLCVAR
    +define+MPTDC_USE_OSC_MODEL
    -f "$MPTDC_ROOT/rtl/filelist.f"
    -f "$REPO_ROOT/filelist.f"
    "$TB_FILE"
    -top "$TB_NAME"
    -xmlibdirname "$BUILD_DIR/xcelium.d"
  )

  if [[ $WAVES -eq 1 ]]; then
    mkdir -p "$BUILD_DIR/waves"
    XRUN_ARGS+=(
      -input "@database -open waves -into $BUILD_DIR/waves/waves.shm -default"
      -input "@probe -create $TB_NAME -all -depth all"
      -input "@run"
      -input "@exit"
    )
  fi

  cd "$BUILD_DIR"
  xrun "${XRUN_ARGS[@]}" 2>&1 | tee "$BUILD_DIR/run.log"
  RC=${PIPESTATUS[0]}
else
  echo "ERROR: Only xrun is supported by this runner"
  exit 1
fi

if grep -qE "(PASS|All tests passed)" "$BUILD_DIR/run.log" && [[ $RC -eq 0 ]]; then
  echo "═══ RESULT: PASS ═══"
  exit 0
else
  echo "═══ RESULT: FAIL (rc=$RC) ═══"
  exit 1
fi
