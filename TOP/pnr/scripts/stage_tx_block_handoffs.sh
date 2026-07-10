#!/usr/bin/env bash
# Stage the canonical corrected packet core and PG-complete strip as two versions.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PACKET_SOURCE_ROOT="${1:-}"
PACKET_CANONICAL_GDS="${2:-}"
PACKET_AUDIT_ROOT="${3:-}"
STRIP_PG_ROOT="${4:-}"
VERSION="${5:-tx_blocks_$(date +%Y%m%d_%H%M%S)}"
HANDOFF_ROOT="${SPADMIC_INNOVUS_HANDOFF_ROOT:-/sim/ksabra/SPADMIC_work/handoff/innovus}"

if [[ -z "$PACKET_SOURCE_ROOT" || -z "$PACKET_CANONICAL_GDS" || -z "$PACKET_AUDIT_ROOT" || -z "$STRIP_PG_ROOT" ]]; then
  cat >&2 <<'EOF'
Usage: stage_tx_block_handoffs.sh <packet-old-Innovus-block-root> \
  <canonical-fixed-packet-GDS> <packet-canonical-audit-root> \
  <strip-PG-patch-run-root> [version]

The packet GDS must have layout top spadmic_tx_packet_core, not the historical
spadmic_tx_packet_core_HV name. The fixed geometry is promoted manually in OA
before this staging command.
EOF
  exit 2
fi
if [[ ! -d "$PACKET_AUDIT_ROOT" ]]; then
  echo "ERROR: packet canonical audit root missing: $PACKET_AUDIT_ROOT" >&2
  exit 6
fi

first_file() {
  local pattern="$1"
  shift
  local root file
  for root in "$@"; do
    file="$(find "$root" -maxdepth 1 -type f -name "$pattern" -print -quit 2>/dev/null)"
    if [[ -n "$file" ]]; then
      printf '%s\n' "$file"
      return 0
    fi
  done
  return 1
}

PACKET_OUTPUTS="$PACKET_SOURCE_ROOT/outputs"
STRIP_OUTPUTS="$STRIP_PG_ROOT/outputs"
PACKET_LEF="$(first_file 'tx_packet_core.abstract.lef' "$PACKET_OUTPUTS")"
PACKET_DEF="$(first_file 'tx_packet_core.def' "$PACKET_OUTPUTS")"
PACKET_NETLIST="$(first_file 'tx_packet_core.routed.pg.v' "$PACKET_OUTPUTS")"
STRIP_LEF="$(first_file 'tx_ddr_strip.abstract.lef' "$STRIP_OUTPUTS")"
STRIP_DEF="$(first_file 'tx_ddr_strip.def' "$STRIP_OUTPUTS")"
STRIP_GDS="$(first_file 'tx_ddr_strip.gds' "$STRIP_OUTPUTS")"
STRIP_NETLIST="$(first_file 'tx_ddr_strip.routed.pg.v' "$STRIP_OUTPUTS")"

for file in "$PACKET_CANONICAL_GDS" "$PACKET_LEF" "$PACKET_DEF" "$PACKET_NETLIST" \
            "$STRIP_LEF" "$STRIP_DEF" "$STRIP_GDS" "$STRIP_NETLIST"; do
  if [[ ! -s "$file" ]]; then
    echo "ERROR: required TX handoff file missing: $file" >&2
    exit 6
  fi
done

PACKET_ARGS=(--kind block --name spadmic_tx_packet_core --version "$VERSION"
  --source-root "$PACKET_SOURCE_ROOT" --gds "$PACKET_CANONICAL_GDS"
  --layout-top spadmic_tx_packet_core --netlist "$PACKET_NETLIST"
  --source-top spadmic_tx_packet_core --lef "$PACKET_LEF" --def-file "$PACKET_DEF"
  --handoff-root "$HANDOFF_ROOT" --repo-root "$REPO_ROOT" --copy-shared-pdk)
for report in "$PACKET_SOURCE_ROOT"/reports/*.rpt; do
  [[ -s "$report" ]] && PACKET_ARGS+=(--report "$report")
done
for report in "$PACKET_AUDIT_ROOT"/reports/*.rpt; do
  [[ -s "$report" ]] && PACKET_ARGS+=(--report "$report")
done
for log in "$PACKET_AUDIT_ROOT"/logs/* "$PACKET_SOURCE_ROOT"/logs/innovus.log; do
  [[ -s "$log" ]] && PACKET_ARGS+=(--log "$log")
done
python3 "$SCRIPT_DIR/stage_innovus_handoff.py" "${PACKET_ARGS[@]}"
PACKET_RC=$?
echo "PACKET_STAGE_RC=$PACKET_RC"
[[ "$PACKET_RC" -eq 0 ]] || exit "$PACKET_RC"
PACKET_PACKAGE="$HANDOFF_ROOT/blocks/spadmic_tx_packet_core/$VERSION"
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$PACKET_PACKAGE"
PACKET_AUDIT_RC=$?
echo "PACKET_AUDIT_RC=$PACKET_AUDIT_RC"
[[ "$PACKET_AUDIT_RC" -eq 0 ]] || exit "$PACKET_AUDIT_RC"

STRIP_ARGS=(--kind block --name spadmic_tx_ddr_strip --version "$VERSION"
  --source-root "$STRIP_PG_ROOT" --gds "$STRIP_GDS"
  --layout-top spadmic_tx_ddr_strip --netlist "$STRIP_NETLIST"
  --source-top spadmic_tx_ddr_strip --lef "$STRIP_LEF" --def-file "$STRIP_DEF"
  --handoff-root "$HANDOFF_ROOT" --repo-root "$REPO_ROOT")
for report in "$STRIP_PG_ROOT"/reports/*.rpt; do
  [[ -s "$report" ]] && STRIP_ARGS+=(--report "$report")
done
for log in "$STRIP_PG_ROOT"/logs/innovus.log "$STRIP_PG_ROOT"/logs/innovus.stdout.log; do
  [[ -s "$log" ]] && STRIP_ARGS+=(--log "$log")
done
python3 "$SCRIPT_DIR/stage_innovus_handoff.py" "${STRIP_ARGS[@]}"
STRIP_RC=$?
echo "STRIP_STAGE_RC=$STRIP_RC"
[[ "$STRIP_RC" -eq 0 ]] || exit "$STRIP_RC"
STRIP_PACKAGE="$HANDOFF_ROOT/blocks/spadmic_tx_ddr_strip/$VERSION"
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$STRIP_PACKAGE"
STRIP_AUDIT_RC=$?
echo "STRIP_AUDIT_RC=$STRIP_AUDIT_RC"
[[ "$STRIP_AUDIT_RC" -eq 0 ]] || exit "$STRIP_AUDIT_RC"

echo "PACKET_PACKAGE=$PACKET_PACKAGE"
echo "STRIP_PACKAGE=$STRIP_PACKAGE"
echo "TX_HANDOFF_STAGE_STATUS=PASS"
