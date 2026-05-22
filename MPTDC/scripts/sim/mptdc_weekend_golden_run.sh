#!/usr/bin/env bash
# Weekend "golden data" launcher for MPTDC report-grade characterization.
#
# Run from the SPADMIC repo root or from the MPTDC directory on the lab server.
# Heavy outputs are written under /sim/ksabra by default.

set -euo pipefail

RUN_TAG="${RUN_TAG:-mptdc_golden_$(date +%Y%m%d_%H%M%S)}"
OUT_ROOT="${OUT_ROOT:-/sim/ksabra/${RUN_TAG}}"
JOBS="${JOBS:-24}"
SIM="${SIM:-xrun}"

CONFIG="${CONFIG:-multihit_15_cal_nominal}"
OUT_MODE="${OUT_MODE:-raw_features}"

# Current RTL/testbench jitter plusargs are integer ps. 800 fs RMS is therefore
# approximated conservatively as 1 ps RMS with a 3 ps clamp unless set to 0.
JITTER_SIGMA_PS="${JITTER_SIGMA_PS:-1}"
JITTER_BOUND_PS="${JITTER_BOUND_PS:-3}"

# Broad sweep split: train and validation are separate directories so the LUT
# validation is genuinely held out even for more than 30 seeds.
TRAIN_SEEDS="${TRAIN_SEEDS:-128}"
VAL_SEEDS="${VAL_SEEDS:-32}"
N_CONV="${N_CONV:-200000}"
TRAIN_SEED_START="${TRAIN_SEED_START:-0}"
VAL_SEED_START="${VAL_SEED_START:-100000}"

# Fixed-delay data for alias analysis, boundary confidence, and N<=15 averaging.
FIXED_DELAY_SEEDS="${FIXED_DELAY_SEEDS:-24}"
FIXED_DELAY_N_CONV="${FIXED_DELAY_N_CONV:-10000}"
FIXED_DELAY_SEED_START="${FIXED_DELAY_SEED_START:-200000}"
FIXED_DELAY_LIST="${FIXED_DELAY_LIST:-20,50,100,200,500,1000,2000,5000,10000,30000}"

# VIP CDV stress. Run after characterization by default to avoid exceeding the
# 24-job budget. Set RUN_VIP=0 to skip.
RUN_VIP="${RUN_VIP:-1}"
VIP_SEEDS="${VIP_SEEDS:-128}"
VIP_SEED_START="${VIP_SEED_START:-300000}"
VIP_NUM_CONV="${VIP_NUM_CONV:-20000}"

if [[ -d "${MPTDC_ROOT:-}" ]]; then
  cd "$MPTDC_ROOT"
elif [[ -f "scripts/sim/run_campaign.sh" && -f "rtl/pkg/mptdc_pkg.sv" ]]; then
  :
elif [[ -d "MPTDC" && -f "MPTDC/scripts/sim/run_campaign.sh" ]]; then
  cd MPTDC
else
  echo "[ERROR] Run from SPADMIC repo root or set MPTDC_ROOT=/path/to/SPADMIC/MPTDC" >&2
  exit 1
fi

mkdir -p "$OUT_ROOT"/{logs,manifests}

run_logged() {
  local name="$1"
  shift
  local log="$OUT_ROOT/logs/${name}.log"
  echo
  echo "[RUN][$name] log=$log"
  printf '[CMD]' | tee "$log"
  printf ' %q' "$@" | tee -a "$log"
  printf '\n' | tee -a "$log"
  set +e
  "$@" 2>&1 | tee -a "$log"
  local rc="${PIPESTATUS[0]}"
  set -e
  return "$rc"
}

JITTER_ARGS=()
CFG_SUFFIX="${CONFIG}_${OUT_MODE}"
if [[ "$JITTER_SIGMA_PS" != "0" ]]; then
  JITTER_ARGS=(--jitter-sigma "$JITTER_SIGMA_PS" --jitter-bound "$JITTER_BOUND_PS")
  CFG_SUFFIX="${CFG_SUFFIX}_js${JITTER_SIGMA_PS}_jb${JITTER_BOUND_PS}"
fi

CHAR_ROOT="$OUT_ROOT/characterization"
TRAIN_CAMPAIGN="$CHAR_ROOT/train_campaign"
VAL_CAMPAIGN="$CHAR_ROOT/validation_campaign"
TRAIN_CFG_DIR="$TRAIN_CAMPAIGN/$CFG_SUFFIX"
VAL_CFG_DIR="$VAL_CAMPAIGN/$CFG_SUFFIX"
SWEEP_ANALYSIS_TRAIN="$CHAR_ROOT/analysis/train_sweep"
SWEEP_ANALYSIS_VAL="$CHAR_ROOT/analysis/validation_sweep"
CAL_DIR="$CHAR_ROOT/analysis/calibration_stop_disc"
FIXED_DIR="$CHAR_ROOT/fixed_delay"
ALIAS_DIR="$FIXED_DIR/analysis/raw_aliases"
VIP_DIR="$OUT_ROOT/vip_cdv"

cat > "$OUT_ROOT/manifests/run_config.env" <<EOF
RUN_TAG=$RUN_TAG
OUT_ROOT=$OUT_ROOT
JOBS=$JOBS
SIM=$SIM
CONFIG=$CONFIG
OUT_MODE=$OUT_MODE
CFG_SUFFIX=$CFG_SUFFIX
JITTER_SIGMA_PS=$JITTER_SIGMA_PS
JITTER_BOUND_PS=$JITTER_BOUND_PS
TRAIN_SEEDS=$TRAIN_SEEDS
VAL_SEEDS=$VAL_SEEDS
N_CONV=$N_CONV
FIXED_DELAY_SEEDS=$FIXED_DELAY_SEEDS
FIXED_DELAY_N_CONV=$FIXED_DELAY_N_CONV
FIXED_DELAY_LIST=$FIXED_DELAY_LIST
RUN_VIP=$RUN_VIP
VIP_SEEDS=$VIP_SEEDS
VIP_NUM_CONV=$VIP_NUM_CONV
GIT_HEAD=$(git rev-parse HEAD 2>/dev/null || echo unknown)
EOF

echo "[INFO] Output root: $OUT_ROOT"
echo "[INFO] Config dir suffix: $CFG_SUFFIX"
echo "[INFO] xrun path: $(command -v xrun || echo 'xrun-not-found')"
echo "[INFO] git head: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"

run_logged smoke_shape \
  bash scripts/sim/run_characterization_baseline.sh \
    --sim "$SIM" \
    --jobs 4 \
    --smoke \
    --out-mode "$OUT_MODE" \
    --out-dir "$OUT_ROOT/smoke_characterization" \
    --analyze \
    --with-fixed-delay \
    "${JITTER_ARGS[@]}"

run_logged train_campaign \
  bash scripts/sim/run_campaign.sh \
    --sim "$SIM" \
    --jobs "$JOBS" \
    --seeds "$TRAIN_SEEDS" \
    --n-conv "$N_CONV" \
    --delay-min 20 \
    --delay-max 30000 \
    --seed-start "$TRAIN_SEED_START" \
    --configs "$CONFIG" \
    --out-mode "$OUT_MODE" \
    --out-dir "$TRAIN_CAMPAIGN" \
    --rebuild \
    "${JITTER_ARGS[@]}"

run_logged validation_campaign \
  bash scripts/sim/run_campaign.sh \
    --sim "$SIM" \
    --jobs "$JOBS" \
    --seeds "$VAL_SEEDS" \
    --n-conv "$N_CONV" \
    --delay-min 20 \
    --delay-max 30000 \
    --seed-start "$VAL_SEED_START" \
    --configs "$CONFIG" \
    --out-mode "$OUT_MODE" \
    --out-dir "$VAL_CAMPAIGN" \
    "${JITTER_ARGS[@]}"

run_logged analyze_train \
  python3 scripts/analysis/analyze_campaign.py \
    --campaign-dir "$TRAIN_CAMPAIGN" \
    --output-dir "$SWEEP_ANALYSIS_TRAIN" \
    --config-filter "${CONFIG}*"

run_logged analyze_validation \
  python3 scripts/analysis/analyze_campaign.py \
    --campaign-dir "$VAL_CAMPAIGN" \
    --output-dir "$SWEEP_ANALYSIS_VAL" \
    --config-filter "${CONFIG}*"

run_logged fine_grid \
  python3 scripts/calibration/analyze_fine_grid.py \
    --output "$CHAR_ROOT/analysis/fine_grid_analysis.pdf"

run_logged calibrate_stop_disc \
  python3 scripts/calibration/calibrate_6d_lut.py \
    --train-dir "$TRAIN_CFG_DIR" \
    --val-dir "$VAL_CFG_DIR" \
    --fresh-dir "$VAL_CFG_DIR" \
    --out-dir "$CAL_DIR" \
    --train-seeds "$TRAIN_SEEDS"

run_logged fixed_delay \
  bash scripts/sim/run_fixed_delay_campaign.sh \
    --sim "$SIM" \
    --jobs "$JOBS" \
    --seeds "$FIXED_DELAY_SEEDS" \
    --n-conv "$FIXED_DELAY_N_CONV" \
    --seed-start "$FIXED_DELAY_SEED_START" \
    --configs "$CONFIG" \
    --out-mode "$OUT_MODE" \
    --delay-list "$FIXED_DELAY_LIST" \
    --out-dir "$FIXED_DIR" \
    --analyze \
    "${JITTER_ARGS[@]}"

run_logged alias_all_rows \
  python3 scripts/analysis/analyze_raw_aliases.py \
    --campaign-dir "$FIXED_DIR" \
    --config-filter "${CONFIG}_${OUT_MODE}*" \
    --out-dir "$ALIAS_DIR/all_rows"

run_logged alias_core_only \
  python3 scripts/analysis/analyze_raw_aliases.py \
    --campaign-dir "$FIXED_DIR" \
    --config-filter "${CONFIG}_${OUT_MODE}*" \
    --core-only \
    --out-dir "$ALIAS_DIR/core_nslow_gt_0"

run_logged alias_noncore_only \
  python3 scripts/analysis/analyze_raw_aliases.py \
    --campaign-dir "$FIXED_DIR" \
    --config-filter "${CONFIG}_${OUT_MODE}*" \
    --noncore-only \
    --out-dir "$ALIAS_DIR/noncore_nslow_eq_0"

if [[ "$RUN_VIP" != "0" ]]; then
  run_logged vip_cdv \
    bash ci/run_vip_xcelium_regression.sh \
      --sim "$SIM" \
      --jobs "$JOBS" \
      --seed-start "$VIP_SEED_START" \
      --seeds "$VIP_SEEDS" \
      --num-conv "$VIP_NUM_CONV" \
      --out-dir "$VIP_DIR" \
      --clean
fi

python3 - "$OUT_ROOT" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
summary = {
    "out_root": str(root),
    "calibration_report": str(root / "characterization/analysis/calibration_stop_disc/calibration_report.json"),
    "fixed_delay_analysis": str(root / "characterization/fixed_delay/analysis"),
    "alias_all_rows": str(root / "characterization/fixed_delay/analysis/raw_aliases/all_rows"),
    "alias_core_only": str(root / "characterization/fixed_delay/analysis/raw_aliases/core_nslow_gt_0"),
    "alias_noncore_only": str(root / "characterization/fixed_delay/analysis/raw_aliases/noncore_nslow_eq_0"),
    "vip_summary": str(root / "vip_cdv/vip_summary.json"),
}
(root / "manifests/final_paths.json").write_text(json.dumps(summary, indent=2) + "\n")
print(json.dumps(summary, indent=2))
PY

echo
echo "[DONE] Weekend golden run finished."
echo "[DONE] Outputs: $OUT_ROOT"
