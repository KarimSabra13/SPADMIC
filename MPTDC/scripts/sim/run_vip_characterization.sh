#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Purpose : VIP train/validation characterization orchestration.
# Usage   : bash scripts/sim/run_vip_characterization.sh [options]
# Notes   : Builds on the maintained characterization benches, but emits an
#           explicit train/validation manifest for the 6D LUT calibration flow.
# -----------------------------------------------------------------------------

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="$REPO_ROOT/results/vip_characterization"
SIM="verilator"
JOBS=12
TRAIN_SEEDS=16
VALID_SEEDS=8
SEED_START=2000
SMOKE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    --jobs) JOBS="$2"; shift 2 ;;
    --train-seeds) TRAIN_SEEDS="$2"; shift 2 ;;
    --valid-seeds) VALID_SEEDS="$2"; shift 2 ;;
    --seed-start) SEED_START="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --smoke) SMOKE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,/^# -----------------------------------------------------------------------------$/{
        /^# -----------------------------------------------------------------------------$/d
        s/^# //p
      }' "$0"
      exit 0
      ;;
    *) echo "Error: unknown option '$1'" >&2; exit 1 ;;
  esac
done

case "$OUT_DIR" in
  /*) ;;
  *) OUT_DIR="$REPO_ROOT/$OUT_DIR" ;;
esac

if (( SMOKE )); then
  TRAIN_SEEDS=1
  VALID_SEEDS=1
fi

TRAIN_DIR="$OUT_DIR/train"
VALID_DIR="$OUT_DIR/validate"
mkdir -p "$OUT_DIR"

common_args=(--jobs "$JOBS" --stages code_density,boundary,deadtime,throughput)
if (( SMOKE )); then
  common_args+=(--smoke)
fi
if (( DRY_RUN )); then
  common_args+=(--dry-run)
fi

if [[ "$SIM" == "xrun" || "$SIM" == "xcelium" ]]; then
  campaign_common=(--sim xrun --jobs "$JOBS" --configs multihit_15_cal_nominal --out-mode full)
  if (( SMOKE )); then
    campaign_common+=(--smoke)
  fi
  if (( DRY_RUN )); then
    campaign_common+=(--dry-run)
  fi

  echo "[VIP-CHAR] Xcelium training campaign"
  bash "$REPO_ROOT/scripts/sim/run_campaign.sh" \
    "${campaign_common[@]}" \
    --seed-start "$SEED_START" \
    --seeds "$TRAIN_SEEDS" \
    --out-dir "$TRAIN_DIR"

  echo "[VIP-CHAR] Xcelium validation campaign"
  bash "$REPO_ROOT/scripts/sim/run_campaign.sh" \
    "${campaign_common[@]}" \
    --seed-start "$((SEED_START + TRAIN_SEEDS))" \
    --seeds "$VALID_SEEDS" \
    --out-dir "$VALID_DIR"
else
  echo "[VIP-CHAR] Verilator training dataset"
  bash "$REPO_ROOT/scripts/sim/run_characterization_overnight.sh" \
    "${common_args[@]}" \
    --seed-start "$SEED_START" \
    --seeds "$TRAIN_SEEDS" \
    --out-dir "$TRAIN_DIR"

  echo "[VIP-CHAR] Verilator validation dataset"
  bash "$REPO_ROOT/scripts/sim/run_characterization_overnight.sh" \
    "${common_args[@]}" \
    --seed-start "$((SEED_START + TRAIN_SEEDS))" \
    --seeds "$VALID_SEEDS" \
    --out-dir "$VALID_DIR"
fi

if (( ! DRY_RUN )); then
  python3 - "$OUT_DIR" "$TRAIN_SEEDS" "$VALID_SEEDS" "$SEED_START" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
data = {
    "schema_version": 1,
    "name": "mptdc-vip-characterization",
    "train": {"root": str(root / "train"), "seeds": int(sys.argv[2])},
    "validate": {"root": str(root / "validate"), "seeds": int(sys.argv[3])},
    "seed_start": int(sys.argv[4]),
    "split_policy": "disjoint-seeds",
}
(root / "vip_characterization_manifest.json").write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
fi

echo "[VIP-CHAR] Done: $OUT_DIR"
