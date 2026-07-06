#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

DEFAULT_SOURCE_LEF="/group/validmgr/PROJET/Prj_xh018/ksabra/lef/RO_tune6.lef"
DEFAULT_WORK_ROOT="/sim/ksabra/SPADMIC_work"

SOURCE_LEF="${O1_RO_SOURCE_LEF_PATH:-${FINAL_LEF:-$DEFAULT_SOURCE_LEF}}"
WORK_ROOT="${MPTDC_WORK_ROOT:-$DEFAULT_WORK_ROOT}"
RUN_ID="coordinate_proxy_$(date +%Y%m%d_%H%M%S)"
OUT_DIR=""
OUT_LEF=""
SUMMARY=""

usage() {
  cat <<'USAGE'
Usage:
  server_prepare_ro_tune6_coordinate_proxy_lef.sh [options]

Options:
  --source-lef <path>  Real RO_tune6 LEF used as the geometry/pin source.
  --work-root <path>   Work root. Default: $MPTDC_WORK_ROOT or /sim/ksabra/SPADMIC_work.
  --run-id <id>        Label used under <work-root>/lef.
  --out-dir <path>     Output directory. Overrides --work-root/--run-id placement.
  -h, --help           Show this help.

The generated LEF keeps RO_tune6 size/origin and pins, drops vdd!, and removes
OBS. It is a digital coordinate/pin contract only, not final RO layout signoff.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-lef)
      SOURCE_LEF="${2:?missing --source-lef value}"
      shift 2
      ;;
    --work-root)
      WORK_ROOT="${2:?missing --work-root value}"
      shift 2
      ;;
    --run-id)
      RUN_ID="${2:?missing --run-id value}"
      shift 2
      ;;
    --out-dir)
      OUT_DIR="${2:?missing --out-dir value}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$OUT_DIR" ]]; then
  OUT_DIR="$WORK_ROOT/lef/$RUN_ID"
fi

OUT_LEF="$OUT_DIR/RO_tune6_coordinate_proxy.lef"
SUMMARY="$OUT_DIR/RO_tune6_coordinate_proxy.summary.rpt"

test -r "$SOURCE_LEF"

python3 "$SCRIPT_DIR/generate_ro_coordinate_proxy_lef.py" \
  --source-lef "$SOURCE_LEF" \
  --out-lef "$OUT_LEF" \
  --summary "$SUMMARY"

echo "O1_RO_SOURCE_LEF_PATH=$SOURCE_LEF"
echo "O1_RO_LEF_PATH=$OUT_LEF"
echo "RO_COORDINATE_PROXY_SUMMARY=$SUMMARY"
echo "Use with:"
echo "  --source-lef $SOURCE_LEF --pnr-lef $OUT_LEF"
