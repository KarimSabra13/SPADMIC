#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP -- TX egress fixed-leaf assembly planning wrapper
# =============================================================================
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_tx_egress_leaf_assembly_plan.sh <tx_leaf_manifest.csv> [RUN_ID]

The manifest is the CSV produced after validating the four clean TX leaf
abstracts. This wrapper generates a deterministic fixed-leaf assembly planning
package. It does not run Innovus top assembly, PG hookup, PVS, LVS, PEX, or
MMMC.
USAGE
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

MANIFEST="$1"
RUN_ID="${2:-tx_egress_leaf_assembly_plan_$(date +%Y%m%d_%H%M)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
OUT_DIR="$WORK_ROOT/assembly/$RUN_ID"

if [ ! -s "$MANIFEST" ]; then
  echo "ERROR: manifest missing or empty: $MANIFEST" >&2
  exit 2
fi

if [ -e "$OUT_DIR" ]; then
  echo "ERROR: output directory already exists: $OUT_DIR" >&2
  exit 2
fi

mkdir -p "$OUT_DIR"

python3 "$SCRIPT_DIR/gen_tx_egress_leaf_assembly_plan.py" \
  --manifest "$MANIFEST" \
  --out-dir "$OUT_DIR" \
  --repo-root "$REPO_ROOT"
rc=$?

echo "ASSEMBLY_PLAN_RC=$rc"
echo "ASSEMBLY_PLAN_RUN_ID=$RUN_ID"
echo "ASSEMBLY_PLAN_ROOT=$OUT_DIR"

if [ -f "$OUT_DIR/tx_egress_leaf_assembly_status.rpt" ]; then
  echo "ASSEMBLY_PLAN_STATUS=$OUT_DIR/tx_egress_leaf_assembly_status.rpt"
fi

exit "$rc"
