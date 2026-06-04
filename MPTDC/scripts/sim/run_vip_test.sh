#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Build and run one VIP scenario on the requested simulator.
# Usage   : bash scripts/sim/run_vip_test.sh <test_name>
#           [--sim verilator|xrun|xcelium|vcs] [--waves] [--seed N]
#           [--func-cov] [--code-cov] [--cov-workdir DIR]
#           [--cov-test-name NAME] [--osc-jitter-sigma ps]
#           [--osc-jitter-bound ps] [--stop-model direct|qualified-ref]
#           [--ref-phase-ps N] [--artifact-dir DIR] [--vip-asserts] [--dry-run]
#           [--fast-tag-encoding raw_lfsr_tag|raw_galois_tag]
#           [--freq-mode nominal|r750_delta5]
# Context : Verilator is intended for smoke runs; xrun/xcelium/VCS enable
#           broader simulator and coverage flows.
# Author  : Karim Sabra
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
SIM="verilator"
TEST_NAME=""
WAVES=0
SEED=""
FUNC_COV=0
CODE_COV=0
OSC_JITTER_SIGMA=""
OSC_JITTER_BOUND=""
NUM_CONV=""
COV_WORKDIR=""
COV_TEST_NAME=""
STOP_MODEL=""
REF_PHASE_PS=""
ARTIFACT_DIR=""
VIP_ASSERTS=0
DRY_RUN=0
FAST_TAG_ENCODING="${MPTDC_FAST_TAG_ENCODING:-raw_lfsr_tag}"
FREQ_MODE="${MPTDC_FREQ_MODE:-nominal}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim)
      SIM="$2"; shift 2 ;;
    --waves)
      WAVES=1; shift ;;
    --seed)
      SEED="$2"; shift 2 ;;
    --func-cov)
      FUNC_COV=1; shift ;;
    --code-cov)
      CODE_COV=1; shift ;;
    --cov-workdir)
      COV_WORKDIR="$2"; shift 2 ;;
    --cov-test-name)
      COV_TEST_NAME="$2"; shift 2 ;;
    --osc-jitter-sigma)
      OSC_JITTER_SIGMA="$2"; shift 2 ;;
    --osc-jitter-bound)
      OSC_JITTER_BOUND="$2"; shift 2 ;;
    --num-conv)
      NUM_CONV="$2"; shift 2 ;;
    --stop-model)
      STOP_MODEL="$2"; shift 2 ;;
    --ref-phase-ps)
      REF_PHASE_PS="$2"; shift 2 ;;
    --artifact-dir)
      ARTIFACT_DIR="$2"; shift 2 ;;
    --vip-asserts)
      VIP_ASSERTS=1; shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --fast-tag-encoding)
      FAST_TAG_ENCODING="$2"; shift 2 ;;
    --freq-mode)
      FREQ_MODE="$2"; shift 2 ;;
    -h|--help)
      cat <<EOF
Usage: $0 <test_name> [--sim verilator|xrun|xcelium|vcs] [--waves] [--seed N]
          [--func-cov] [--code-cov] [--cov-workdir DIR] [--cov-test-name NAME]
          [--osc-jitter-sigma ps] [--osc-jitter-bound ps] [--num-conv N]
          [--stop-model direct|qualified-ref] [--ref-phase-ps N]
          [--artifact-dir DIR] [--vip-asserts] [--dry-run]
          [--fast-tag-encoding raw_lfsr_tag|raw_galois_tag]
          [--freq-mode nominal|r750_delta5]

Notes:
  --func-cov/--code-cov require xrun/xcelium or vcs.
  Verilator is smoke-only and does not validate covergroups.
EOF
      exit 0 ;;
    *)
      if [[ -z "$TEST_NAME" ]]; then
        TEST_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      shift ;;
  esac
done

if [[ -z "$TEST_NAME" ]]; then
  echo "Error: no VIP test name specified" >&2
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

normalize_repo_path() {
  local raw_path="$1"
  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
  else
    printf '%s\n' "$REPO_ROOT/$raw_path"
  fi
}

ensure_output_path() {
  local checked_path="$1"
  case "$checked_path" in
    "$REPO_ROOT"/*) ;;
    /sim/ksabra/*) ;;
    *)
      echo "Error: VIP artifacts must stay inside the repository or /sim/ksabra: $checked_path" >&2
      exit 1
      ;;
  esac
}

require_tool() {
  local tool_name="$1"
  if [[ $DRY_RUN -eq 0 ]] && ! command -v "$tool_name" >/dev/null 2>&1; then
    echo "Error: required tool '$tool_name' not found in PATH" >&2
    exit 1
  fi
}

print_cmd() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
}

run_cmd() {
  if [[ $DRY_RUN -eq 1 ]]; then
    print_cmd "$@"
  else
    "$@"
  fi
}

run_in_dir() {
  local dir="$1"
  shift
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '+ cd %q &&' "$dir"
    printf ' %q' "$@"
    printf '\n'
  else
    (cd "$dir" && "$@")
  fi
}

sanitize_path_token() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_'
}

if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 ]]; then
  if [[ "$SIM" == "verilator" ]]; then
    echo "Error: Verilator smoke does not support --func-cov/--code-cov; use --sim xrun or --sim xcelium on a Cadence machine." >&2
    exit 1
  fi
  if [[ -n "$COV_WORKDIR" ]]; then
    COV_WORKDIR="$(normalize_repo_path "$COV_WORKDIR")"
    ensure_output_path "$COV_WORKDIR"
  fi
else
  if [[ -n "$COV_WORKDIR" || -n "$COV_TEST_NAME" ]]; then
    echo "Error: --cov-workdir/--cov-test-name require --func-cov or --code-cov" >&2
    exit 1
  fi
fi

if [[ "$SIM" == "vcs" && -n "$COV_TEST_NAME" ]]; then
  echo "Error: --cov-test-name is only supported for xrun/xcelium coverage runs" >&2
  exit 1
fi

if [[ -n "$ARTIFACT_DIR" ]]; then
  ARTIFACT_DIR="$(normalize_repo_path "$ARTIFACT_DIR")"
  ensure_output_path "$ARTIFACT_DIR"
  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$ARTIFACT_DIR"
  fi
fi

case "$STOP_MODEL" in
  ""|direct) STOP_MODEL_NUM=0 ;;
  qualified-ref|qualified_ref) STOP_MODEL_NUM=1 ;;
  *)
    echo "Error: --stop-model must be direct or qualified-ref" >&2
    exit 1
    ;;
esac

PLUSARGS=("+MPTDC_TEST=$TEST_NAME")
if [[ -n "$SEED" ]]; then
  PLUSARGS+=("+MPTDC_SEED=$SEED")
fi
if [[ -n "$OSC_JITTER_SIGMA" ]]; then
  PLUSARGS+=("+OSC_JITTER_SIGMA_PS=$OSC_JITTER_SIGMA")
fi
if [[ -n "$OSC_JITTER_BOUND" ]]; then
  PLUSARGS+=("+OSC_JITTER_BOUND_PS=$OSC_JITTER_BOUND")
fi
if [[ -n "$NUM_CONV" ]]; then
  PLUSARGS+=("+MPTDC_NUM_CONV=$NUM_CONV")
fi
PLUSARGS+=("+MPTDC_STOP_MODEL=$STOP_MODEL_NUM")
if [[ -n "$REF_PHASE_PS" ]]; then
  PLUSARGS+=("+MPTDC_REF_PHASE_PS=$REF_PHASE_PS")
fi
if [[ -n "$ARTIFACT_DIR" ]]; then
  PLUSARGS+=("+MPTDC_TXN_LOG_CSV=$ARTIFACT_DIR/transactions.csv")
  PLUSARGS+=("+MPTDC_TXN_LOG_JSONL=$ARTIFACT_DIR/transactions.jsonl")
  PLUSARGS+=("+MPTDC_FAILURE_DIR=$ARTIFACT_DIR")
fi

COMMON_FILES=(
  -f "$REPO_ROOT/rtl/filelist.f"
  -f "$REPO_ROOT/tb/vip/filelist.f"
)

COV_DIR=""
COV_TEST=""
if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 ]]; then
  COV_TEST="${COV_TEST_NAME:-$TEST_NAME}"
fi

TB_BUILD="$BUILD_DIR/vip_${TEST_NAME}_${SIM}_${FAST_TAG_ENCODING}_${FREQ_MODE}"
if [[ -n "$COV_TEST_NAME" ]]; then
  # Parallel xrun campaign jobs must not share one xcelium.d library.
  TB_BUILD+="_$(sanitize_path_token "$COV_TEST_NAME")"
elif [[ -n "$SEED" ]]; then
  TB_BUILD+="_seed_$(sanitize_path_token "$SEED")"
fi

if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 ]]; then
  COV_DIR="${COV_WORKDIR:-$TB_BUILD/cov_work}"
fi

if [[ $DRY_RUN -eq 0 ]]; then
  if [[ "$SIM" == "xrun" || "$SIM" == "xcelium" ]]; then
    rm -rf "$TB_BUILD"
  fi
  mkdir -p "$TB_BUILD"
  export CCACHE_DIR="${CCACHE_DIR:-$BUILD_DIR/ccache}"
  export CCACHE_TEMPDIR="${CCACHE_TEMPDIR:-$BUILD_DIR/ccache/tmp}"
  mkdir -p "$CCACHE_DIR" "$CCACHE_TEMPDIR"
fi

case "$SIM" in
  verilator)
    require_tool verilator
    VERILATOR_FLAGS=(
      --binary
      --timing
      -Wall
      -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC
      -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM
      -Wno-MULTITOP -Wno-SYNCASYNCNET -Wno-UNOPTFLAT -Wno-PINCONNECTEMPTY
      -Wno-VARHIDDEN -Wno-DECLFILENAME
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      --Mdir "$TB_BUILD"
      --top-module mptdc_vip_tb
      -o mptdc_vip_tb
    )
    if [[ $WAVES -eq 1 ]]; then
      VERILATOR_FLAGS+=(--trace --trace-structs)
    fi
    if [[ $VIP_ASSERTS -eq 1 ]]; then
      echo "Note: --vip-asserts is reserved for assertion-capable signoff simulators; Verilator smoke keeps interface assertions disabled."
    fi
    echo "--- Compiling VIP test with Verilator ---"
    run_in_dir "$REPO_ROOT" verilator "${VERILATOR_FLAGS[@]}" "${COMMON_FILES[@]}"
    echo "--- Running VIP test ---"
    run_in_dir "$TB_BUILD" ./mptdc_vip_tb "${PLUSARGS[@]}"
    ;;

  xrun|xcelium)
    require_tool xrun
    XRUN_FLAGS=(
      -64 -sv -access +rwc
      -timescale 1ps/1ps
      -nowarn DLCVAR
      -top mptdc_vip_tb
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      -f "$REPO_ROOT/rtl/filelist.f"
      -f "$REPO_ROOT/tb/vip/filelist.f"
      -xmlibdirname "$TB_BUILD/xcelium.d"
    )
    if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 ]]; then
      XRUN_FLAGS+=(+define+MPTDC_ENABLE_FUNC_COV -coverage all -covoverwrite)
      XRUN_FLAGS+=(-covworkdir "$COV_DIR" -covtest "$COV_TEST")
    fi
    if [[ $VIP_ASSERTS -eq 1 ]]; then
      XRUN_FLAGS+=(+define+MPTDC_ENABLE_VIP_ASSERTS)
    fi
    if [[ $WAVES -eq 1 ]]; then
      WAVE_DB="${ARTIFACT_DIR:-$TB_BUILD}/waves.shm"
      XRUN_FLAGS+=(-input "@database -open waves -into $WAVE_DB -default; probe -create mptdc_vip_tb -all -depth all; run; exit")
    fi
    echo "--- Compiling/running VIP test with xrun ---"
    set +e
    run_in_dir "$REPO_ROOT" xrun "${XRUN_FLAGS[@]}" "${PLUSARGS[@]}"
    XRUN_RC=$?
    set -e
    if [[ $DRY_RUN -eq 0 ]]; then
      rm -rf "$TB_BUILD"
    fi
    exit "$XRUN_RC"
    ;;

  vcs)
    require_tool vcs
    VCS_FLAGS=(
      -full64 -sverilog -timescale=1ps/1ps
      +lint=all
      +define+MPTDC_USE_OSC_MODEL
      "${FAST_TAG_DEFINE_ARGS[@]}"
      "${FREQ_MODE_DEFINE_ARGS[@]}"
      -f "$REPO_ROOT/rtl/filelist.f"
      -f "$REPO_ROOT/tb/vip/filelist.f"
      -top mptdc_vip_tb
      -o "$TB_BUILD/mptdc_vip_tb"
    )
    if [[ $FUNC_COV -eq 1 || $CODE_COV -eq 1 ]]; then
      VCS_FLAGS+=(+define+MPTDC_ENABLE_FUNC_COV -cm line+cond+tgl+fsm+branch)
      VCS_FLAGS+=(-cm_dir "${COV_DIR:-$TB_BUILD/vcs_cov}")
    fi
    if [[ $VIP_ASSERTS -eq 1 ]]; then
      VCS_FLAGS+=(+define+MPTDC_ENABLE_VIP_ASSERTS)
    fi
    echo "--- Compiling VIP test with VCS ---"
    run_in_dir "$REPO_ROOT" vcs "${VCS_FLAGS[@]}"
    echo "--- Running VIP test ---"
    run_cmd "$TB_BUILD/mptdc_vip_tb" "${PLUSARGS[@]}"
    ;;

  *)
    echo "Error: unknown simulator '$SIM' (use verilator, xrun, xcelium, or vcs)" >&2
    exit 1
    ;;
esac
