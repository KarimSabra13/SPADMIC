#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : Final report-grade MPTDC server flow: VIP, characterization,
#           focused DNL/boundary collection, extraction, and publication plots.
# Usage   : bash scripts/sim/run_report_flow.sh [options]
#           --sim NAME              xrun|xcelium (default xrun)
#           --jobs N                Parallel jobs (default 24)
#           --out-dir DIR           Output root (default /sim/ksabra/mptdc_final_characterization)
#           --smoke                 Small shape-validation run
#           --clean                 Clean selected output roots before running
#           --rebuild               Rebuild simulator binaries/libraries
#           --dry-run               Print commands without executing
#           --skip-vip              Do not run VIP CDV
#           --skip-char             Do not run baseline characterization
#           --skip-focused          Do not run focused code-density/boundary stage
#           --skip-plots            Do not generate final report figures
#           --char-seeds N          Baseline characterization seeds (default 32)
#           --char-n-conv N         Baseline conversions/seed (default 100000)
#           --char-train-seeds N    Calibration training seeds (default 24)
#           --focused-seeds N       Focused stage seeds (default 8)
#           --focused-code-n-conv N Focused code-density conversions/seed (default 100000)
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SIM="xrun"
JOBS=24
OUT_DIR="/sim/ksabra/mptdc_final_characterization"
SMOKE=0
CLEAN=0
REBUILD=0
DRY_RUN=0

RUN_VIP=1
RUN_CHAR=1
RUN_FOCUSED=1
RUN_PLOTS=1

CHAR_SEEDS=32
CHAR_N_CONV=100000
CHAR_TRAIN_SEEDS=24
CHAR_OUT_MODE="raw_features"
FIXED_DELAY_SEEDS=6
FIXED_DELAY_N_CONV=5000
FOCUSED_SEEDS=8
FOCUSED_CODE_N_CONV=100000

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

run_cmd() {
  print_cmd "[RUN]" "$@"
  if (( DRY_RUN )); then
    return 0
  fi
  "$@"
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
    --smoke) SMOKE=1; shift ;;
    --clean) CLEAN=1; shift ;;
    --rebuild) REBUILD=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --skip-vip) RUN_VIP=0; shift ;;
    --skip-char) RUN_CHAR=0; shift ;;
    --skip-focused) RUN_FOCUSED=0; shift ;;
    --skip-plots) RUN_PLOTS=0; shift ;;
    --char-seeds) CHAR_SEEDS="$2"; shift 2 ;;
    --char-n-conv) CHAR_N_CONV="$2"; shift 2 ;;
    --char-train-seeds) CHAR_TRAIN_SEEDS="$2"; shift 2 ;;
    --char-out-mode) CHAR_OUT_MODE="$2"; shift 2 ;;
    --fixed-delay-seeds) FIXED_DELAY_SEEDS="$2"; shift 2 ;;
    --fixed-delay-n-conv) FIXED_DELAY_N_CONV="$2"; shift 2 ;;
    --focused-seeds) FOCUSED_SEEDS="$2"; shift 2 ;;
    --focused-code-n-conv) FOCUSED_CODE_N_CONV="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; exit 1 ;;
  esac
done

case "$SIM" in
  xrun|xcelium) ;;
  *) echo "[ERROR] --sim must be xrun or xcelium" >&2; exit 1 ;;
esac

OUT_DIR="$(to_abs "$OUT_DIR")"
OVERNIGHT_DIR="$OUT_DIR/overnight"
FOCUSED_DIR="$OUT_DIR/focused"
PLOTS_DIR="$OUT_DIR/report"

if (( ! DRY_RUN )); then
  mkdir -p "$OUT_DIR"
fi
cd "$REPO_ROOT"

VIP_OVERNIGHT_STAGES=()
if (( RUN_VIP )); then
  VIP_OVERNIGHT_STAGES+=(vip)
fi
if (( RUN_CHAR )); then
  VIP_OVERNIGHT_STAGES+=(char)
fi

if (( ${#VIP_OVERNIGHT_STAGES[@]} )); then
  stage_csv="$(IFS=,; echo "${VIP_OVERNIGHT_STAGES[*]}")"
  cmd=(
    bash "$REPO_ROOT/scripts/sim/run_vip_overnight.sh"
    --sim "$SIM"
    --jobs "$JOBS"
    --stages "$stage_csv"
    --out-dir "$OVERNIGHT_DIR"
    --char-seeds "$CHAR_SEEDS"
    --char-n-conv "$CHAR_N_CONV"
    --char-train-seeds "$CHAR_TRAIN_SEEDS"
    --char-out-mode "$CHAR_OUT_MODE"
    --fixed-delay-seeds "$FIXED_DELAY_SEEDS"
    --fixed-delay-n-conv "$FIXED_DELAY_N_CONV"
    --fixed-delay-jobs "$JOBS"
  )
  if (( SMOKE )); then cmd+=(--smoke); fi
  if (( CLEAN )); then cmd+=(--clean); fi
  if (( REBUILD )); then cmd+=(--rebuild); fi
  run_cmd "${cmd[@]}"
fi

if (( RUN_FOCUSED )); then
  cmd=(
    bash "$REPO_ROOT/scripts/sim/run_characterization_overnight.sh"
    --sim "$SIM"
    --jobs "$JOBS"
    --seed-start 0
    --seeds "$FOCUSED_SEEDS"
    --code-n-conv "$FOCUSED_CODE_N_CONV"
    --stages code_density,boundary
    --out-dir "$FOCUSED_DIR"
    --analyze
  )
  if (( SMOKE )); then cmd+=(--smoke); fi
  if (( REBUILD )); then cmd+=(--rebuild); fi
  if (( DRY_RUN )); then cmd+=(--dry-run); fi
  run_cmd "${cmd[@]}"

  if (( ! DRY_RUN )); then
    run_cmd python3 "$REPO_ROOT/scripts/analysis/analyze_tdc_linearity.py" \
      --root "$FOCUSED_DIR" \
      --output-dir "$FOCUSED_DIR/analysis/linearity"
  else
    print_cmd "[DRY-RUN]" python3 "$REPO_ROOT/scripts/analysis/analyze_tdc_linearity.py" \
      --root "$FOCUSED_DIR" \
      --output-dir "$FOCUSED_DIR/analysis/linearity"
  fi
fi

if (( RUN_PLOTS )); then
  cmd=(
    python3 "$REPO_ROOT/scripts/analysis/generate_report_plots.py"
    --char-root "$OVERNIGHT_DIR/characterization"
    --focused-root "$FOCUSED_DIR"
    --output-dir "$PLOTS_DIR"
  )
  if (( DRY_RUN )); then
    print_cmd "[DRY-RUN]" "${cmd[@]}"
  else
    run_cmd "${cmd[@]}"
  fi
fi

if (( ! DRY_RUN )); then
  python3 - "$OUT_DIR" "$OVERNIGHT_DIR" "$FOCUSED_DIR" "$PLOTS_DIR" <<'PY'
import json
import sys
from pathlib import Path

root, overnight, focused, plots = map(Path, sys.argv[1:])
manifest = {
    "name": "mptdc-final-report-flow",
    "root": str(root),
    "overnight": str(overnight),
    "vip_summary": str(overnight / "vip" / "vip_summary.json"),
    "characterization_manifest": str(overnight / "characterization" / "characterization_manifest.json"),
    "focused_manifest": str(focused / "characterization_manifest.json"),
    "report_plot_manifest": str(plots / "report_plot_manifest.json"),
}
(root / "final_flow_manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
print(json.dumps(manifest, indent=2))
PY
fi

echo "[REPORT-FLOW] Done: $OUT_DIR"
