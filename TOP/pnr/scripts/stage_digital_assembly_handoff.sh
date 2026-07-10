#!/usr/bin/env bash
# Stage a phase-suffixed OA/GDS assembly and stable logical source top.
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ASSEMBLY_RUN_ROOT="${1:-}"
PHASE_GDS="${2:-}"
PHASE_TOP="${3:-spadmic_digital_assembly_v1_p00_tx}"
VERSION="${4:-assembly_p00_$(date +%Y%m%d_%H%M%S)}"
HANDOFF_ROOT="${SPADMIC_INNOVUS_HANDOFF_ROOT:-/sim/ksabra/SPADMIC_work/handoff/innovus}"

if [[ -z "$ASSEMBLY_RUN_ROOT" || -z "$PHASE_GDS" ]]; then
  echo "Usage: $0 <assembly-Innovus-run-root> <phase-OA-GDS> [phase-top] [version]" >&2
  exit 2
fi
SOURCE="$ASSEMBLY_RUN_ROOT/outputs/spadmic_digital_assembly_v1_p00_tx.pg.v"
DEF="$ASSEMBLY_RUN_ROOT/outputs/spadmic_digital_assembly_v1_p00_tx.def"
LEF="$ASSEMBLY_RUN_ROOT/outputs/spadmic_digital_assembly_v1_p00_tx.lef"
for file in "$SOURCE" "$DEF" "$LEF" "$PHASE_GDS"; do
  [[ -s "$file" ]] || { echo "ERROR: missing assembly handoff file: $file" >&2; exit 6; }
done

ARGS=(--kind assembly --name "$PHASE_TOP" --version "$VERSION"
  --source-root "$ASSEMBLY_RUN_ROOT" --gds "$PHASE_GDS" --layout-top "$PHASE_TOP"
  --netlist "$SOURCE" --source-top spadmic_digital_assembly_v1
  --lef "$LEF" --def-file "$DEF" --handoff-root "$HANDOFF_ROOT" --repo-root "$REPO_ROOT")
for report in "$ASSEMBLY_RUN_ROOT"/reports/*.rpt; do
  [[ -s "$report" ]] && ARGS+=(--report "$report")
done
for log in "$ASSEMBLY_RUN_ROOT"/logs/innovus.log "$ASSEMBLY_RUN_ROOT"/logs/innovus.stdout.log; do
  [[ -s "$log" ]] && ARGS+=(--log "$log")
done
python3 "$SCRIPT_DIR/stage_innovus_handoff.py" "${ARGS[@]}"
RC=$?
echo "ASSEMBLY_STAGE_RC=$RC"
[[ "$RC" -eq 0 ]] || exit "$RC"
ASSEMBLY_PACKAGE="$HANDOFF_ROOT/assemblies/$PHASE_TOP/$VERSION"
python3 "$SCRIPT_DIR/audit_innovus_handoff.py" "$ASSEMBLY_PACKAGE"
AUDIT_RC=$?
echo "ASSEMBLY_AUDIT_RC=$AUDIT_RC"
echo "ASSEMBLY_PACKAGE=$ASSEMBLY_PACKAGE"
exit "$AUDIT_RC"
