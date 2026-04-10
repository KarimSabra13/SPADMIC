#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — IMC Coverage Merge & Report
# Usage: bash scripts/sim/report_coverage.sh [--workdir <path>] [--report <path>]
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

COV_WORKDIR="${1:-$REPO_ROOT/build/coverage}"
REPORT_DIR="${2:-$REPO_ROOT/build/coverage_report}"

mkdir -p "$REPORT_DIR"

echo "═══════════════════════════════════════════════════════"
echo "  SPADMIC TOP — Coverage Merge & Report"
echo "═══════════════════════════════════════════════════════"
echo "  Workdir: $COV_WORKDIR"
echo "  Report:  $REPORT_DIR"

# Build IMC command file
CMD_FILE="$REPORT_DIR/imc_merge.tcl"
cat > "$CMD_FILE" <<EOF
// Auto-generated IMC merge script
merge $COV_WORKDIR/* -overwrite -out $REPORT_DIR/merged_cov
load $REPORT_DIR/merged_cov
report_metrics -out $REPORT_DIR/report -detail -kind aggregate -overwrite
report_metrics -out $REPORT_DIR/summary.txt -kind aggregate -overwrite
EOF

echo "Running IMC merge..."
imc -init "$CMD_FILE" -nocopyright 2>&1 | tee "$REPORT_DIR/imc.log"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Coverage report written to: $REPORT_DIR"
echo "═══════════════════════════════════════════════════════"

# Print summary if available
if [[ -f "$REPORT_DIR/summary.txt" ]]; then
  echo ""
  cat "$REPORT_DIR/summary.txt"
fi
