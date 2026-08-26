#!/usr/bin/env bash
# Replay a GUI-generated PVS DRC run on a new merged GDS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$SCRIPT_DIR/lib_pvs_common.sh"

REPO_ROOT="$(mptdc_pvs_repo_root)"
DEFAULT_OLD_BASE="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608"
OLD_BASE="${MPTDC_PVS_OLD_BASE:-$DEFAULT_OLD_BASE}"
OLD_DRC_RUN="${MPTDC_PVS_DRC_TEMPLATE:-$OLD_BASE/pvs_drc/mptdc_axis_core_merged}"
NEW_BASE=""
NEW_DRC_RUN=""
NEW_GDS=""
OLD_GDS="${MPTDC_PVS_OLD_GDS:-$OLD_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
VARIANT="${MPTDC_PVS_DRC_VARIANT:-base}"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  02_replay_pvs_drc_from_template.sh --prepared-dir <dir> [options]

Options:
  --prepared-dir <dir>      Directory from 00_prepare_pvs_inputs_from_checkpoint.sh.
  --new-gds <path>          Override merged GDS path.
  --template-run <dir>      Old GUI-generated DRC run directory.
  --old-base <dir>          Old dryGDS base path to replace.
  --old-gds <path>          Old GDS path to replace.
  --new-run-dir <dir>       Explicit new PVS DRC run directory.
  --variant <base|density>  Required rule-deck variant label. Default: base.
  --expected-head <sha>     Require repository HEAD to match this commit.
  --dry-run                 Patch and audit templates without launching run.pvs.
  -h, --help                Show this help.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prepared-dir)
      NEW_BASE="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --prepared-dir value}")"
      shift 2
      ;;
    --new-gds)
      NEW_GDS="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-gds value}")"
      shift 2
      ;;
    --template-run)
      OLD_DRC_RUN="${2:?missing --template-run value}"
      shift 2
      ;;
    --old-base)
      OLD_BASE="${2:?missing --old-base value}"
      shift 2
      ;;
    --old-gds)
      OLD_GDS="${2:?missing --old-gds value}"
      shift 2
      ;;
    --new-run-dir)
      NEW_DRC_RUN="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-run-dir value}")"
      shift 2
      ;;
    --variant)
      VARIANT="${2:?missing --variant value}"
      shift 2
      ;;
    --expected-head)
      EXPECTED_HEAD_VALUE="${2:?missing --expected-head value}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
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

[[ -n "$NEW_BASE" ]] || { usage >&2; mptdc_pvs_die "--prepared-dir is required"; }
case "$VARIANT" in
  base|density) ;;
  *) mptdc_pvs_die "--variant must be base or density" ;;
esac
NEW_GDS="${NEW_GDS:-$NEW_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
NEW_DRC_RUN="${NEW_DRC_RUN:-$NEW_BASE/pvs_drc/mptdc_axis_core_merged_${VARIANT}_script}"

cd "$REPO_ROOT"
mptdc_pvs_check_git_head "$REPO_ROOT" "$EXPECTED_HEAD_VALUE"
mptdc_pvs_require_clean_tracked_tree "$REPO_ROOT"
mptdc_pvs_require_dir "$NEW_BASE"
mptdc_pvs_require_file "$NEW_GDS"
for f in "$OLD_DRC_RUN/run.pvs" "$OLD_DRC_RUN/pvsdrcctl" "$OLD_DRC_RUN/.config.rul" "$OLD_DRC_RUN/.technology.rul"; do
  mptdc_pvs_require_existing_file "$f"
done
if grep -q -- '-cell_tree' "$OLD_DRC_RUN/run.pvs"; then
  mptdc_pvs_require_existing_file "$OLD_DRC_RUN/cell_tree.txt"
fi

if [[ -e "$NEW_DRC_RUN" ]]; then
  mptdc_pvs_die "new DRC run directory already exists: $NEW_DRC_RUN"
fi

mkdir -p "$NEW_DRC_RUN" "$NEW_BASE/reports" "$NEW_BASE/manifests"
cp -p "$OLD_DRC_RUN/run.pvs" "$NEW_DRC_RUN/run.pvs"
cp -p "$OLD_DRC_RUN/pvsdrcctl" "$NEW_DRC_RUN/pvsdrcctl"
cp -p "$OLD_DRC_RUN/.config.rul" "$NEW_DRC_RUN/.config.rul"
cp -p "$OLD_DRC_RUN/.technology.rul" "$NEW_DRC_RUN/.technology.rul"
[[ -f "$OLD_DRC_RUN/cell_tree.txt" ]] && cp -p "$OLD_DRC_RUN/cell_tree.txt" "$NEW_DRC_RUN/cell_tree.txt"
[[ -f "$OLD_DRC_RUN/.preset.autosave" ]] && cp -p "$OLD_DRC_RUN/.preset.autosave" "$NEW_DRC_RUN/.preset.autosave"

PATCH_FILES=("$NEW_DRC_RUN/run.pvs" "$NEW_DRC_RUN/pvsdrcctl" "$NEW_DRC_RUN/.config.rul" "$NEW_DRC_RUN/.technology.rul")
[[ -f "$NEW_DRC_RUN/cell_tree.txt" ]] && PATCH_FILES+=("$NEW_DRC_RUN/cell_tree.txt")
[[ -f "$NEW_DRC_RUN/.preset.autosave" ]] && PATCH_FILES+=("$NEW_DRC_RUN/.preset.autosave")

mapfile -t OLD_LAYOUT_PATHS < <(
  sed -nE 's/^[[:space:]]*layout_path[[:space:]]+"([^"]+)".*/\1/p' "$OLD_DRC_RUN/pvsdrcctl"
)
[[ "${#OLD_LAYOUT_PATHS[@]}" -eq 1 ]] || \
  mptdc_pvs_die "expected exactly one layout_path in $OLD_DRC_RUN/pvsdrcctl"
OLD_LAYOUT_PATH="${OLD_LAYOUT_PATHS[0]}"

for f in "${PATCH_FILES[@]}"; do
  mptdc_pvs_patch_file_paths "$f" \
    "$OLD_LAYOUT_PATH=$NEW_GDS" \
    "$OLD_GDS=$NEW_GDS" \
    "$OLD_DRC_RUN=$NEW_DRC_RUN" \
    "$OLD_BASE=$NEW_BASE"
done

DENSITY_CONTROL_COUNT="$(grep -Ec '^[[:space:]]*#(UN)?DEFINE[[:space:]]+DENSITY[[:space:]]*$' "$NEW_DRC_RUN/pvsdrcctl" || true)"
[[ "$DENSITY_CONTROL_COUNT" -eq 1 ]] || \
  mptdc_pvs_die "expected exactly one DENSITY control in $NEW_DRC_RUN/pvsdrcctl"
if [[ "$VARIANT" == "density" ]]; then
  perl -pi -e 's/^(\s*)#(?:UN)?DEFINE\s+DENSITY\s*$/${1}#DEFINE DENSITY/' "$NEW_DRC_RUN/pvsdrcctl"
else
  perl -pi -e 's/^(\s*)#(?:UN)?DEFINE\s+DENSITY\s*$/${1}#UNDEFINE DENSITY/' "$NEW_DRC_RUN/pvsdrcctl"
fi

mptdc_pvs_fail_if_contains_old_path "DRC template run" "$OLD_DRC_RUN" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "DRC old base" "$OLD_BASE" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "DRC old GDS" "$OLD_GDS" "${PATCH_FILES[@]}"
chmod +x "$NEW_DRC_RUN/run.pvs"

{
  echo "# MPTDC PVS DRC Replay Manifest"
  echo "date: $(date -Iseconds)"
  echo "old_drc_run: $OLD_DRC_RUN"
  echo "new_drc_run: $NEW_DRC_RUN"
  echo "old_base: $OLD_BASE"
  echo "new_base: $NEW_BASE"
  echo "old_gds: $OLD_GDS"
  echo "new_gds: $NEW_GDS"
  echo "variant: $VARIANT"
  echo "dry_run: $DRY_RUN"
} | tee "$NEW_BASE/manifests/pvs_drc_${VARIANT}_replay_manifest.txt"

{
  echo "===== Patched run.pvs ====="
  sed -n '1,180p' "$NEW_DRC_RUN/run.pvs"
  echo
  echo "===== Patched DRC config scan ====="
  grep -RniE 'mptdc_axis_core_merged_stdcell_ro6|xh018_DRC|metalswitch|DENSITY|DRC|drc|rulesFile|GDS|gds' \
    "$NEW_DRC_RUN/run.pvs" "$NEW_DRC_RUN/pvsdrcctl" "$NEW_DRC_RUN/.config.rul" "$NEW_DRC_RUN/.technology.rul" | sed -n '1,360p' || true
} | tee "$NEW_BASE/reports/pvs_drc_${VARIANT}_replay_preflight.rpt"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "PVS_DRC_REPLAY_STATUS=DRY_RUN_READY" | tee "$NEW_BASE/reports/pvs_drc_${VARIANT}_status.rpt"
  exit 0
fi

mptdc_pvs_prepend_known_cadence_bins
mptdc_pvs_forbid_bare_linux_lvm_pvs
set +e
(
  cd "$NEW_DRC_RUN"
  bash ./run.pvs
) 2>&1 | tee "$NEW_DRC_RUN/pvs_drc_replay.stdout"
PVS_RC=${PIPESTATUS[0]}
set -e
echo "PVS_DRC_RC=$PVS_RC" | tee "$NEW_BASE/reports/pvs_drc_${VARIANT}_tool_status.rpt"

grep -RIna --binary-files=without-match \
  --exclude='*.rdb' \
  --exclude='*.ecdb' \
  --exclude-dir='REPORTDB' \
  -E 'Run Result|Finished|Total DRC Results|RuleCheck|fatal|error|warning|violation|MET1|m1|area|AREA' \
  "$NEW_DRC_RUN" | head -2000 | tee "$NEW_BASE/reports/pvs_drc_${VARIANT}_result_scan.txt" || true

HASH_MANIFEST="$NEW_BASE/manifests/pvs_input_hashes.rpt"
GATE_REPORT="$NEW_BASE/reports/pvs_drc_${VARIANT}_status.rpt"
RULE_REPORT="$NEW_BASE/reports/pvs_drc_${VARIANT}_nonzero_rules.tsv"
set +e
python3 "$SCRIPT_DIR/05_gate_pvs_drc.py" \
  --run-dir "$NEW_DRC_RUN" \
  --tool-rc "$PVS_RC" \
  --variant "$VARIANT" \
  --expected-top mptdc_axis_core \
  --hash-manifest "$HASH_MANIFEST" \
  --out "$GATE_REPORT" \
  --rules-out "$RULE_REPORT"
GATE_RC=$?
set -e

if [[ "$VARIANT" == "base" ]]; then
  cp -p "$GATE_REPORT" "$NEW_BASE/reports/pvs_drc_status.rpt"
fi

if [[ "$PVS_RC" -ne 0 ]]; then
  exit "$PVS_RC"
fi
exit "$GATE_RC"
