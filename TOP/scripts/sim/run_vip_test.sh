#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Single VIP Test Runner
# Usage: bash scripts/sim/run_vip_test.sh <test_name> [options]
#
# Options:
#   --sim <xrun|verilator>   xrun executes tests, verilator does lint-only compile
#   --seed <N>               Random seed (default: 1)
#   --func-cov               Enable functional coverage
#   --code-cov               Enable code coverage
#   --waves                  Enable waveform capture
#   --cov-workdir <dir>      Coverage workdir
#   --cov-test-name <name>   Coverage test name
#   --num-conv <N>           Override num conversions
#   --num-phases <N>         Override num phases
#   --max-hits <N>           Override max_hits
#   --out-mode <N>           Override output mode
#   --drv-mode <I2C|CSR>     Override driver mode
#   --profile <name>         Override mission profile
#   --timeout <ns>           Override timeout
#   --random-legal-only <0|1>  Keep random legal/coherent (default from test)
#   --rand-w-tdc <N>         Random phase weight: TDC
#   --rand-w-pos <N>         Random phase weight: position
#   --rand-w-switch <N>      Random phase weight: mode switch
#   --rand-w-bp <N>          Random phase weight: BP compatibility
#   --rand-w-corr <N>        Random phase weight: correlated event
#   --gui                    Open SimVision after run
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TOP_ROOT="$REPO_ROOT"
MPTDC_ROOT="$(cd "$REPO_ROOT/../MPTDC" 2>/dev/null && pwd || echo "$REPO_ROOT/../MPTDC")"

# Defaults
SIM="xrun"
TEST_NAME="${1:?Usage: run_vip_test.sh <test_name> [options]}"
SEED=1
FUNC_COV=0
CODE_COV=0
WAVES=0
COV_WORKDIR="$TOP_ROOT/build/coverage"
COV_TEST_NAME="$TEST_NAME"
NUM_CONV=""
NUM_PHASES=""
MAX_HITS=""
OUT_MODE=""
DRV_MODE=""
PROFILE=""
TIMEOUT=""
RANDOM_LEGAL_ONLY=""
RAND_W_TDC=""
RAND_W_POS=""
RAND_W_SWITCH=""
RAND_W_BP=""
RAND_W_CORR=""
GUI=0

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)        SIM="$2"; shift 2 ;;
    --seed)       SEED="$2"; shift 2 ;;
    --func-cov)   FUNC_COV=1; shift ;;
    --code-cov)   CODE_COV=1; shift ;;
    --waves)      WAVES=1; shift ;;
    --cov-workdir)    COV_WORKDIR="$2"; shift 2 ;;
    --cov-test-name)  COV_TEST_NAME="$2"; shift 2 ;;
    --num-conv)   NUM_CONV="$2"; shift 2 ;;
    --num-phases) NUM_PHASES="$2"; shift 2 ;;
    --max-hits)   MAX_HITS="$2"; shift 2 ;;
    --out-mode)   OUT_MODE="$2"; shift 2 ;;
    --drv-mode)   DRV_MODE="$2"; shift 2 ;;
    --profile)    PROFILE="$2"; shift 2 ;;
    --timeout)    TIMEOUT="$2"; shift 2 ;;
    --random-legal-only) RANDOM_LEGAL_ONLY="$2"; shift 2 ;;
    --rand-w-tdc) RAND_W_TDC="$2"; shift 2 ;;
    --rand-w-pos) RAND_W_POS="$2"; shift 2 ;;
    --rand-w-switch) RAND_W_SWITCH="$2"; shift 2 ;;
    --rand-w-bp) RAND_W_BP="$2"; shift 2 ;;
    --rand-w-corr) RAND_W_CORR="$2"; shift 2 ;;
    --gui)        GUI=1; shift ;;
    *)            echo "Unknown option: $1"; exit 1 ;;
  esac
done

BUILD_DIR="$TOP_ROOT/build/vip/${TEST_NAME}_s${SEED}"
mkdir -p "$BUILD_DIR"
XRUN_XMLIBDIR="$BUILD_DIR/xcelium_${SEED}_$$.d"

# ── Resolve filelists to absolute paths ────────────────────────
source "$SCRIPT_DIR/resolve_flist.sh"
resolve_flist "$MPTDC_ROOT"      "$MPTDC_ROOT/rtl/filelist.f"    "$BUILD_DIR/mptdc.f"
resolve_flist "$TOP_ROOT"        "$TOP_ROOT/filelist.f"          "$BUILD_DIR/top.f"
resolve_flist "$TOP_ROOT/tb/vip" "$TOP_ROOT/tb/vip/filelist.f"   "$BUILD_DIR/vip.f"

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC VIP Test: $TEST_NAME (seed=$SEED)"
echo "═══════════════════════════════════════════════════════"

if [[ "$SIM" == "xrun" ]]; then
  # ── Build xrun command ───────────────────────────────────────
  XRUN_ARGS=(
    -64 -sv -access +rwc
    -timescale 1ps/1ps
    -nowarn DLCVAR
    -svseed "$SEED"
    +define+MPTDC_USE_OSC_MODEL
    "+incdir+$TOP_ROOT/tb/vip"
    -f "$BUILD_DIR/mptdc.f"
    -f "$BUILD_DIR/top.f"
    -f "$BUILD_DIR/vip.f"
    -top spadmic_vip_tb
    -xmlibdirname "$XRUN_XMLIBDIR"
    "+SPADMIC_TEST=$TEST_NAME"
    "+SPADMIC_SEED=$SEED"
  )

  # Plusargs
  [[ -n "$NUM_CONV" ]]   && XRUN_ARGS+=("+SPADMIC_NUM_CONV=$NUM_CONV")
  [[ -n "$NUM_PHASES" ]] && XRUN_ARGS+=("+SPADMIC_NUM_PHASES=$NUM_PHASES")
  [[ -n "$MAX_HITS" ]]   && XRUN_ARGS+=("+SPADMIC_MAX_HITS=$MAX_HITS")
  [[ -n "$OUT_MODE" ]]   && XRUN_ARGS+=("+SPADMIC_OUT_MODE=$OUT_MODE")
  [[ -n "$DRV_MODE" ]]   && XRUN_ARGS+=("+SPADMIC_DRV_MODE=$DRV_MODE")
  [[ -n "$PROFILE" ]]    && XRUN_ARGS+=("+SPADMIC_PROFILE=$PROFILE")
  [[ -n "$TIMEOUT" ]]    && XRUN_ARGS+=("+SPADMIC_TIMEOUT=$TIMEOUT")
  [[ -n "$RANDOM_LEGAL_ONLY" ]] && XRUN_ARGS+=("+SPADMIC_RANDOM_LEGAL_ONLY=$RANDOM_LEGAL_ONLY")
  [[ -n "$RAND_W_TDC" ]]        && XRUN_ARGS+=("+SPADMIC_RAND_W_TDC=$RAND_W_TDC")
  [[ -n "$RAND_W_POS" ]]        && XRUN_ARGS+=("+SPADMIC_RAND_W_POS=$RAND_W_POS")
  [[ -n "$RAND_W_SWITCH" ]]     && XRUN_ARGS+=("+SPADMIC_RAND_W_SWITCH=$RAND_W_SWITCH")
  [[ -n "$RAND_W_BP" ]]         && XRUN_ARGS+=("+SPADMIC_RAND_W_BP=$RAND_W_BP")
  [[ -n "$RAND_W_CORR" ]]       && XRUN_ARGS+=("+SPADMIC_RAND_W_CORR=$RAND_W_CORR")

  # Coverage
  if [[ $FUNC_COV -eq 1 ]]; then
    XRUN_ARGS+=("+define+SPADMIC_ENABLE_FUNC_COV")
  fi
  if [[ $CODE_COV -eq 1 || $FUNC_COV -eq 1 ]]; then
    mkdir -p "$COV_WORKDIR"
    XRUN_ARGS+=(
      -coverage all -covoverwrite
      -covworkdir "$COV_WORKDIR"
      -covtest "$COV_TEST_NAME"
    )
  fi

  # Waveform
  if [[ $WAVES -eq 1 ]]; then
    mkdir -p "$BUILD_DIR/waves"
    XRUN_ARGS+=(
      -input "@database -open waves -into $BUILD_DIR/waves/waves.shm -default"
      -input "@probe -create spadmic_vip_tb -all -depth all"
      -input "@run"
      -input "@exit"
    )
  fi

  # GUI
  if [[ $GUI -eq 1 ]]; then
    XRUN_ARGS+=(-gui)
  fi

  echo "Running: xrun ${XRUN_ARGS[*]}"
  cd "$BUILD_DIR"
  xrun "${XRUN_ARGS[@]}" 2>&1 | tee "$BUILD_DIR/run.log"
  RC=${PIPESTATUS[0]}
elif [[ "$SIM" == "verilator" ]]; then
  if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 || $WAVES -eq 1 || $GUI -eq 1 ]]; then
    echo "Verilator mode only supports lint-only compile (no coverage/gui/waves)." >&2
    exit 1
  fi

  VERILATOR_ARGS=(
    --lint-only
    --timing
    -Wall
    -Wno-fatal
    +define+MPTDC_USE_OSC_MODEL
    "+incdir+$TOP_ROOT/tb/vip"
    -f "$BUILD_DIR/mptdc.f"
    -f "$BUILD_DIR/top.f"
    -f "$BUILD_DIR/vip.f"
    --top-module spadmic_vip_tb
  )

  echo "Running: verilator ${VERILATOR_ARGS[*]}"
  cd "$TOP_ROOT"
  verilator "${VERILATOR_ARGS[@]}" 2>&1 | tee "$BUILD_DIR/run.log"
  RC=${PIPESTATUS[0]}
else
  echo "Unsupported simulator: $SIM" >&2
  exit 1
fi

# ── Result ─────────────────────────────────────────────────────
if [[ "$SIM" == "verilator" && $RC -eq 0 ]] && ! grep -q "^%Error" "$BUILD_DIR/run.log"; then
  echo "═══ RESULT: PASS (verilator lint) ═══"
  exit 0
elif grep -q "PASS" "$BUILD_DIR/run.log" && [[ $RC -eq 0 ]]; then
  echo "═══ RESULT: PASS ═══"
  exit 0
else
  echo "═══ RESULT: FAIL (rc=$RC) ═══"
  exit 1
fi
