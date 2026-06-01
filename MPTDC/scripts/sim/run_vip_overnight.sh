#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Unified overnight entrypoint for VIP CDV + characterization.
# Usage   : bash scripts/sim/run_vip_overnight.sh [options]
#           Stage control:
#             --stages LIST         Comma-separated: vip,char,all (default all)
#             --rerun-vip           Force rerun VIP stage even if outputs exist
#             --rerun-char          Force rerun characterization stage if exists
#             --clean               Remove selected stage output dirs before run
#           Common:
#             --sim NAME            xrun|xcelium (default xrun)
#             --jobs N              Parallel jobs (default 32)
#             --out-dir DIR         Root output dir (default results/vip_overnight)
#             --dry-run             Print downstream commands without executing
#             --smoke               Tiny shape-check run for both stages
#             --rebuild             Forward --rebuild to characterization stage
#           VIP CDV tuning:
#             --vip-seed-start N    First VIP seed (default 1000)
#             --vip-seeds N         VIP seeds (default 64)
#             --vip-num-conv N      Override VIP conversions/test (default 0=per-test)
#             --vip-test NAME       Restrict VIP tests (repeatable)
#             --vip-no-rerun        Disable VIP failure rerun with waves
#           Characterization tuning:
#             --char-seeds N        Sweep seeds (default 128)
#             --char-n-conv N       Sweep conversions/seed (default 200000)
#             --char-config NAME    Campaign config (default multihit_15_cal_nominal)
#             --char-out-mode NAME  raw_features (default raw_features;
#                                   legacy full/2 aliases are mapped downstream)
#             --char-nfast-encoding NAME legacy_binary_nfast|raw_lfsr_tag
#             --char-train-seeds N  Calibration training seeds (default 96)
#             --char-val-dir DIR    Held-out validation directory
#             --char-fresh-dir DIR  Fresh validation directory
#             --no-fixed-delay      Skip fixed-delay stage inside characterization
#             --fixed-delay-list L  Delay list (ps CSV)
#             --fixed-delay-seeds N Fixed-delay seeds (default 16)
#             --fixed-delay-n-conv N Fixed-delay conversions/seed (default 10000)
#             --fixed-delay-jobs N  Fixed-delay parallel jobs (default = --jobs)
#             --jitter-sigma N      Jitter sigma override (ps)
#             --jitter-bound N      Jitter bound override (ps)
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
VIP_RUNNER="$REPO_ROOT/ci/run_vip_xcelium_regression.sh"
CHAR_RUNNER="$REPO_ROOT/scripts/sim/run_characterization_baseline.sh"

SIM="xrun"
JOBS=32
OUT_DIR="$REPO_ROOT/results/vip_overnight"
DRY_RUN=0
SMOKE=0
CLEAN=0
REBUILD=0

RUN_VIP=1
RUN_CHAR=1
FORCE_VIP=0
FORCE_CHAR=0

VIP_SEED_START=1000
VIP_SEEDS=64
VIP_NUM_CONV=0
VIP_NO_RERUN=0
VIP_TESTS=()

CHAR_SEEDS=128
CHAR_N_CONV=200000
CHAR_CONFIG="multihit_15_cal_nominal"
CHAR_OUT_MODE="raw_features"
CHAR_NFAST_ENCODING="legacy_binary_nfast"
CHAR_TRAIN_SEEDS=96
CHAR_VAL_DIR=""
CHAR_FRESH_DIR=""
WITH_FIXED_DELAY=1
FIXED_DELAY_LIST="20,50,100,200,500,1000,2000,5000,10000,30000"
FIXED_DELAY_SEEDS=16
FIXED_DELAY_N_CONV=10000
FIXED_DELAY_JOBS=0
JITTER_SIGMA=""
JITTER_BOUND=""

usage() {
  sed -n '2,/^# -----------------------------------------------------------------------------$/{
    /^# -----------------------------------------------------------------------------$/d
    s/^# //p
  }' "$0"
}

print_cmd() {
  local prefix="$1"
  shift
  printf '%s' "$prefix"
  for arg in "$@"; do
    printf ' %q' "$arg"
  done
  printf '\n'
}

to_abs() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s\n' "$REPO_ROOT/$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --smoke) SMOKE=1; shift ;;
    --clean) CLEAN=1; shift ;;
    --rebuild) REBUILD=1; shift ;;

    --stages)
      RUN_VIP=0
      RUN_CHAR=0
      IFS=',' read -r -a stages <<< "$2"
      for st in "${stages[@]}"; do
        case "$st" in
          all) RUN_VIP=1; RUN_CHAR=1 ;;
          vip) RUN_VIP=1 ;;
          char) RUN_CHAR=1 ;;
          *) echo "Error: unknown stage '$st' in --stages" >&2; exit 1 ;;
        esac
      done
      shift 2
      ;;
    --rerun-vip) FORCE_VIP=1; shift ;;
    --rerun-char) FORCE_CHAR=1; shift ;;

    --vip-seed-start) VIP_SEED_START="$2"; shift 2 ;;
    --vip-seeds) VIP_SEEDS="$2"; shift 2 ;;
    --vip-num-conv) VIP_NUM_CONV="$2"; shift 2 ;;
    --vip-test) VIP_TESTS+=("$2"); shift 2 ;;
    --vip-no-rerun) VIP_NO_RERUN=1; shift ;;

    --char-seeds) CHAR_SEEDS="$2"; shift 2 ;;
    --char-n-conv) CHAR_N_CONV="$2"; shift 2 ;;
    --char-config) CHAR_CONFIG="$2"; shift 2 ;;
    --char-out-mode) CHAR_OUT_MODE="$2"; shift 2 ;;
    --char-nfast-encoding) CHAR_NFAST_ENCODING="$2"; shift 2 ;;
    --char-train-seeds) CHAR_TRAIN_SEEDS="$2"; shift 2 ;;
    --char-val-dir) CHAR_VAL_DIR="$2"; shift 2 ;;
    --char-fresh-dir) CHAR_FRESH_DIR="$2"; shift 2 ;;
    --no-fixed-delay) WITH_FIXED_DELAY=0; shift ;;
    --fixed-delay-list) FIXED_DELAY_LIST="$2"; shift 2 ;;
    --fixed-delay-seeds) FIXED_DELAY_SEEDS="$2"; shift 2 ;;
    --fixed-delay-n-conv) FIXED_DELAY_N_CONV="$2"; shift 2 ;;
    --fixed-delay-jobs) FIXED_DELAY_JOBS="$2"; shift 2 ;;
    --jitter-sigma) JITTER_SIGMA="$2"; shift 2 ;;
    --jitter-bound) JITTER_BOUND="$2"; shift 2 ;;

    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

case "$SIM" in
  xrun|xcelium) ;;
  *) echo "Error: --sim must be xrun or xcelium" >&2; exit 1 ;;
esac

if [[ -n "$JITTER_SIGMA" && -z "$JITTER_BOUND" ]]; then
  echo "Error: --jitter-sigma requires --jitter-bound" >&2
  exit 1
fi
if [[ -z "$JITTER_SIGMA" && -n "$JITTER_BOUND" ]]; then
  echo "Error: --jitter-bound requires --jitter-sigma" >&2
  exit 1
fi
case "$CHAR_NFAST_ENCODING" in
  legacy_binary_nfast|raw_lfsr_tag) ;;
  *)
    echo "Error: --char-nfast-encoding must be legacy_binary_nfast or raw_lfsr_tag" >&2
    exit 1
    ;;
esac

OUT_DIR="$(to_abs "$OUT_DIR")"
if [[ -n "$CHAR_VAL_DIR" ]]; then
  CHAR_VAL_DIR="$(to_abs "$CHAR_VAL_DIR")"
fi
if [[ -n "$CHAR_FRESH_DIR" ]]; then
  CHAR_FRESH_DIR="$(to_abs "$CHAR_FRESH_DIR")"
fi
if (( FIXED_DELAY_JOBS == 0 )); then
  FIXED_DELAY_JOBS="$JOBS"
fi

if (( SMOKE )); then
  VIP_SEEDS=1
  VIP_NUM_CONV=100
  CHAR_SEEDS=1
  CHAR_N_CONV=200
  CHAR_TRAIN_SEEDS=1
  FIXED_DELAY_SEEDS=1
  FIXED_DELAY_N_CONV=200
  FIXED_DELAY_JOBS=1
fi

VIP_OUT="$OUT_DIR/vip"
CHAR_OUT="$OUT_DIR/characterization"
MANIFEST="$OUT_DIR/overnight_manifest.json"
mkdir -p "$OUT_DIR"

vip_completed() {
  [[ -f "$VIP_OUT/vip_summary.json" ]]
}

char_completed() {
  [[ -f "$CHAR_OUT/characterization_manifest.json" ]]
}

VIP_STATUS="not-selected"
CHAR_STATUS="not-selected"

if (( RUN_VIP )); then
  if (( CLEAN )) && (( ! DRY_RUN )); then
    rm -rf "$VIP_OUT"
  fi
  if (( FORCE_VIP == 0 )) && (( CLEAN == 0 )) && vip_completed; then
    echo "[OVERNIGHT] VIP stage: existing summary found, skipping ($VIP_OUT)"
    VIP_STATUS="skipped-existing"
  else
    vip_cmd=(
      bash "$VIP_RUNNER"
      --sim "$SIM"
      --jobs "$JOBS"
      --seed-start "$VIP_SEED_START"
      --seeds "$VIP_SEEDS"
      --out-dir "$VIP_OUT"
    )
    if [[ "$VIP_NUM_CONV" != "0" ]]; then
      vip_cmd+=(--num-conv "$VIP_NUM_CONV")
    fi
    if (( VIP_NO_RERUN )); then
      vip_cmd+=(--no-rerun)
    fi
    if (( DRY_RUN )); then
      vip_cmd+=(--dry-run)
    fi
    if (( CLEAN )); then
      vip_cmd+=(--clean)
    fi
    if (( ${#VIP_TESTS[@]} > 0 )); then
      vip_cmd+=("${VIP_TESTS[@]}")
    fi
    print_cmd "[RUN][VIP]" "${vip_cmd[@]}"
    "${vip_cmd[@]}"
    VIP_STATUS="completed"
  fi
fi

if (( RUN_CHAR )); then
  if (( CLEAN )) && (( ! DRY_RUN )); then
    rm -rf "$CHAR_OUT"
  fi
  if (( FORCE_CHAR == 0 )) && (( CLEAN == 0 )) && char_completed; then
    echo "[OVERNIGHT] Characterization stage: existing manifest found, skipping ($CHAR_OUT)"
    CHAR_STATUS="skipped-existing"
  else
    char_cmd=(
      bash "$CHAR_RUNNER"
      --sim "$SIM"
      --jobs "$JOBS"
      --seeds "$CHAR_SEEDS"
      --n-conv "$CHAR_N_CONV"
      --config "$CHAR_CONFIG"
      --out-mode "$CHAR_OUT_MODE"
      --nfast-encoding "$CHAR_NFAST_ENCODING"
      --out-dir "$CHAR_OUT"
      --analyze
      --calibrate
      --train-seeds "$CHAR_TRAIN_SEEDS"
    )
    if (( WITH_FIXED_DELAY )); then
      char_cmd+=(--with-fixed-delay --fixed-delay-list "$FIXED_DELAY_LIST")
      char_cmd+=(--fixed-delay-seeds "$FIXED_DELAY_SEEDS")
      char_cmd+=(--fixed-delay-n-conv "$FIXED_DELAY_N_CONV")
      char_cmd+=(--fixed-delay-jobs "$FIXED_DELAY_JOBS")
    fi
    if [[ -n "$CHAR_VAL_DIR" ]]; then
      char_cmd+=(--val-dir "$CHAR_VAL_DIR")
    fi
    if [[ -n "$CHAR_FRESH_DIR" ]]; then
      char_cmd+=(--fresh-dir "$CHAR_FRESH_DIR")
    fi
    if [[ -n "$JITTER_SIGMA" ]]; then
      char_cmd+=(--jitter-sigma "$JITTER_SIGMA" --jitter-bound "$JITTER_BOUND")
    fi
    if (( REBUILD )); then
      char_cmd+=(--rebuild)
    fi
    if (( DRY_RUN )); then
      char_cmd+=(--dry-run)
    fi
    print_cmd "[RUN][CHAR]" "${char_cmd[@]}"
    "${char_cmd[@]}"
    CHAR_STATUS="completed"
  fi
fi

VIP_STATUS="$VIP_STATUS" \
CHAR_STATUS="$CHAR_STATUS" \
SIM="$SIM" \
JOBS="$JOBS" \
OUT_DIR="$OUT_DIR" \
VIP_OUT="$VIP_OUT" \
CHAR_OUT="$CHAR_OUT" \
CHAR_NFAST_ENCODING="$CHAR_NFAST_ENCODING" \
python3 - "$MANIFEST" <<'PY'
import json
import os
import sys
from pathlib import Path

manifest = Path(sys.argv[1])
data = {
    "name": "mptdc-vip-overnight",
    "vip_status": os.environ["VIP_STATUS"],
    "char_status": os.environ["CHAR_STATUS"],
    "sim": os.environ["SIM"],
    "jobs": int(os.environ["JOBS"]),
    "out_dir": os.environ["OUT_DIR"],
    "vip_out": os.environ["VIP_OUT"],
    "char_out": os.environ["CHAR_OUT"],
    "char_nfast_encoding": os.environ["CHAR_NFAST_ENCODING"],
}
manifest.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
print(f"[OVERNIGHT] Manifest: {manifest}")
PY

echo "[OVERNIGHT] Done."
