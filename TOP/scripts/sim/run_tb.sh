#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Single Directed Bench Runner (Xcelium)
# Usage: bash scripts/sim/run_tb.sh <tb_name> [--sim xrun|verilator] [--waves]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MPTDC_ROOT="$(cd "$REPO_ROOT/../MPTDC" 2>/dev/null && pwd || echo "$REPO_ROOT/../MPTDC")"
POSITION_TB_ROOT="$REPO_ROOT/../position/tb"
ARB_TB_ROOT="$REPO_ROOT/../arb/tb"

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
for dir in "$REPO_ROOT/tb" "$REPO_ROOT/tb/unit" "$REPO_ROOT/tb/int" "$POSITION_TB_ROOT" "$ARB_TB_ROOT"; do
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
export CCACHE_DIR="$BUILD_DIR/ccache"
mkdir -p "$CCACHE_DIR"

# ── Resolve filelists to absolute paths ────────────────────────
source "$SCRIPT_DIR/resolve_flist.sh"
resolve_flist "$MPTDC_ROOT" "$MPTDC_ROOT/rtl/filelist.f" "$BUILD_DIR/mptdc.f"
resolve_flist "$REPO_ROOT"  "$REPO_ROOT/filelist.f"      "$BUILD_DIR/top.f"

echo "═══════════════════════════════════════════════════════"
echo "  Directed Bench: $TB_NAME"
echo "═══════════════════════════════════════════════════════"

if [[ "$SIM" == "xrun" ]]; then
  # Detect if the TB imports mptdc_tb_pkg and add it to compile
  MPTDC_TB_PKG="$MPTDC_ROOT/tb/common/mptdc_tb_pkg.sv"
  EXTRA_PKG_ARGS=()
  if grep -q 'mptdc_tb_pkg' "$TB_FILE" && [[ -f "$MPTDC_TB_PKG" ]]; then
    EXTRA_PKG_ARGS=("$MPTDC_TB_PKG")
  fi

  XRUN_ARGS=(
    -64 -sv -access +rwc
    -timescale 1ps/1ps
    -nowarn DLCVAR
    +define+MPTDC_USE_OSC_MODEL
    -f "$BUILD_DIR/mptdc.f"
    -f "$BUILD_DIR/top.f"
    "${EXTRA_PKG_ARGS[@]}"
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
elif [[ "$SIM" == "verilator" ]]; then
  mapfile -t MPTDC_FILES < "$BUILD_DIR/mptdc.f"
  mapfile -t TOP_FILES < "$BUILD_DIR/top.f"
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
    -Wno-INITIALDLY
    -Wno-COMBDLY
    -Wno-PINCONNECTEMPTY
    -Wno-SYNCASYNCNET
    -Wno-UNOPTFLAT
  )
  rm -rf "$BUILD_DIR/obj_$TB_NAME"
  verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    "$TB_FILE" \
    --top-module "$TB_NAME" \
    --Mdir "$BUILD_DIR/obj_$TB_NAME" \
    2>&1 | tee "$BUILD_DIR/build.log"
  RC=${PIPESTATUS[0]}
  if [[ $RC -eq 0 ]]; then
    "$BUILD_DIR/obj_$TB_NAME/V$TB_NAME" 2>&1 | tee "$BUILD_DIR/run.log"
    RC=${PIPESTATUS[0]}
  else
    cp "$BUILD_DIR/build.log" "$BUILD_DIR/run.log"
  fi
else
  echo "ERROR: unsupported simulator '$SIM' (expected xrun or verilator)"
  exit 1
fi

if grep -qE "(PASS|All tests passed)" "$BUILD_DIR/run.log" && [[ $RC -eq 0 ]]; then
  echo "═══ RESULT: PASS ═══"
  exit 0
else
  echo "═══ RESULT: FAIL (rc=$RC) ═══"
  exit 1
fi
