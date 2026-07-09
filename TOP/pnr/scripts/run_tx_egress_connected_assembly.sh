#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP -- TX egress connected fixed-leaf assembly package
# =============================================================================
set -uo pipefail

usage() {
  cat <<'USAGE'
Usage:
  TOP/pnr/scripts/run_tx_egress_connected_assembly.sh <ASSEMBLY_PLAN_ROOT> <ASSEMBLY_SMOKE_ROOT> [RUN_ID]

This generates the connected fixed-leaf TX assembly package. It preserves the
small spadmic_tx_egress_core glue logic and treats the four validated TX leaves
as black boxes for the next Genus glue-synthesis and Innovus fixed-leaf import
gate. It does not run Genus, route, PG hookup, PVS/LVS/PEX, MMMC, or signoff.
USAGE
}

if [ "$#" -lt 2 ] || [ "$#" -gt 3 ]; then
  usage >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TOP_ROOT="$(cd "$PNR_ROOT/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

PLAN_ROOT="$1"
SMOKE_ROOT="$2"
RUN_ID="${3:-tx_egress_connected_assembly_$(date +%Y%m%d_%H%M)}"
WORK_ROOT="${SPADMIC_WORK_ROOT:-/sim/ksabra/SPADMIC_work}"
OUT_DIR="$WORK_ROOT/assembly/$RUN_ID"

if [ ! -s "$PLAN_ROOT/tx_egress_leaf_assembly_status.rpt" ]; then
  echo "ERROR: assembly plan status missing: $PLAN_ROOT/tx_egress_leaf_assembly_status.rpt" >&2
  echo "CONNECTED_ASSEMBLY_RC=2"
  echo "CONNECTED_ASSEMBLY_ROOT=$OUT_DIR"
  exit 2
fi

if [ ! -s "$SMOKE_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" ]; then
  echo "ERROR: assembly smoke status missing: $SMOKE_ROOT/reports/tx_egress_leaf_assembly_smoke_status.rpt" >&2
  echo "CONNECTED_ASSEMBLY_RC=2"
  echo "CONNECTED_ASSEMBLY_ROOT=$OUT_DIR"
  exit 2
fi

if [ -e "$OUT_DIR" ]; then
  echo "ERROR: output directory already exists: $OUT_DIR" >&2
  echo "CONNECTED_ASSEMBLY_RC=2"
  echo "CONNECTED_ASSEMBLY_ROOT=$OUT_DIR"
  exit 2
fi

mkdir -p "$OUT_DIR"

python3 "$SCRIPT_DIR/gen_tx_egress_connected_assembly.py" \
  --repo-root "$REPO_ROOT" \
  --plan-root "$PLAN_ROOT" \
  --smoke-root "$SMOKE_ROOT" \
  --out-dir "$OUT_DIR"
gen_rc=$?

status_file="$OUT_DIR/tx_egress_leaf_connected_assembly_status.rpt"
if [ -s "$status_file" ]; then
  result="$(awk -F= '$1=="RESULT"{print $2}' "$status_file" | tail -1)"
  status="$(awk -F= '$1=="STATUS"{print $2}' "$status_file" | tail -1)"
else
  result="FAILED_BEFORE_STATUS"
  status="FAIL"
fi

{
  echo "# TX Egress Connected Fixed-Leaf Assembly"
  echo
  echo "- Run ID: \`$RUN_ID\`"
  echo "- Output root: \`$OUT_DIR\`"
  echo "- Plan root: \`$PLAN_ROOT\`"
  echo "- Smoke root: \`$SMOKE_ROOT\`"
  echo "- Repo head: \`$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)\`"
  echo "- Generator return code: \`$gen_rc\`"
  echo "- Status: \`${status:-UNKNOWN}\`"
  echo "- Result: \`${result:-UNKNOWN}\`"
  echo
  echo "This is a connected assembly package only. Genus glue synthesis, Innovus route,"
  echo "PG hookup, PVS, LVS, PEX, MMMC, and signoff remain later gates."
} > "$OUT_DIR/SUMMARY.md"

cat "$OUT_DIR/SUMMARY.md"

echo "CONNECTED_ASSEMBLY_RC=$gen_rc"
echo "CONNECTED_ASSEMBLY_RUN_ID=$RUN_ID"
echo "CONNECTED_ASSEMBLY_ROOT=$OUT_DIR"
if [ -s "$status_file" ]; then
  echo "CONNECTED_ASSEMBLY_STATUS=$status_file"
fi

exit "$gen_rc"
