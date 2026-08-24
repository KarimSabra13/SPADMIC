#!/usr/bin/env bash
# Replay a GUI-generated PVS LVS run on a new merged GDS and filtered source.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=MPTDC/scripts/pvs/lib_pvs_common.sh
source "$SCRIPT_DIR/lib_pvs_common.sh"

REPO_ROOT="$(mptdc_pvs_repo_root)"
DEFAULT_OLD_BASE="/sim/ksabra/SPADMIC_work/innovus/20260701_mptdc_211109_falsepath_nfast_risk_235618/drygds_oa_20260702_001608"
OLD_BASE="${MPTDC_PVS_OLD_BASE:-$DEFAULT_OLD_BASE}"
OLD_LVS_RUN="${MPTDC_PVS_LVS_TEMPLATE:-$OLD_BASE/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_findshorts}"
OLD_GDS="${MPTDC_PVS_OLD_GDS:-$OLD_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
OLD_SRC="${MPTDC_PVS_OLD_LVS_SOURCE:-$OLD_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR.v}"
OLD_HCELL="${MPTDC_PVS_OLD_HCELL:-$OLD_BASE/outputs/pvs_hcell_ro6.txt}"
DEFAULT_DCELL_CDL="/data/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/gds_cdl/v6_0_0/cdl/xh018_D_CELLS_JIHD.cdl"

NEW_BASE=""
NEW_LVS_RUN=""
NEW_GDS=""
NEW_SRC=""
NEW_HCELL=""
DCELL_CDL="${MPTDC_PVS_DCELL_CDL:-$DEFAULT_DCELL_CDL}"
EXPECTED_HEAD_VALUE="${EXPECTED_HEAD:-}"
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  03_replay_pvs_lvs_from_template.sh --prepared-dir <dir> [options]

Options:
  --prepared-dir <dir>      Directory from 00_prepare_pvs_inputs_from_checkpoint.sh.
  --template-run <dir>      Old GUI-generated LVS run directory.
  --new-gds <path>          Override merged GDS path.
  --new-source <path>       Override filtered LVS Verilog source.
  --new-hcell <path>        Override HCell file.
  --dcell-cdl <path>        D_CELLS CDL path.
  --old-base <dir>          Old dryGDS base path to replace.
  --old-gds <path>          Old GDS path to replace.
  --old-source <path>       Old source path to replace.
  --old-hcell <path>        Old HCell path to replace.
  --new-run-dir <dir>       Explicit new PVS LVS run directory.
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
    --template-run)
      OLD_LVS_RUN="${2:?missing --template-run value}"
      shift 2
      ;;
    --new-gds)
      NEW_GDS="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-gds value}")"
      shift 2
      ;;
    --new-source)
      NEW_SRC="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-source value}")"
      shift 2
      ;;
    --new-hcell)
      NEW_HCELL="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-hcell value}")"
      shift 2
      ;;
    --dcell-cdl)
      DCELL_CDL="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --dcell-cdl value}")"
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
    --old-source)
      OLD_SRC="${2:?missing --old-source value}"
      shift 2
      ;;
    --old-hcell)
      OLD_HCELL="${2:?missing --old-hcell value}"
      shift 2
      ;;
    --new-run-dir)
      NEW_LVS_RUN="$(mptdc_pvs_abs_path "$REPO_ROOT" "${2:?missing --new-run-dir value}")"
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
NEW_GDS="${NEW_GDS:-$NEW_BASE/outputs/mptdc_axis_core_merged_stdcell_ro6.gds}"
NEW_SRC="${NEW_SRC:-$NEW_BASE/outputs/mptdc_axis_core_pnr_lvs_with_pg_NO_DCELL_MODULES_RO6_PINFIX_NOATTR_CLEAN.v}"
NEW_HCELL="${NEW_HCELL:-$NEW_BASE/outputs/pvs_hcell_ro6.txt}"
NEW_LVS_RUN="${NEW_LVS_RUN:-$NEW_BASE/pvs_lvs/mptdc_axis_core_merged_pg_nonphys_dcells_cdl_ro6_pinfix_noattr_clean_findshorts_script}"

cd "$REPO_ROOT"
mptdc_pvs_check_git_head "$REPO_ROOT" "$EXPECTED_HEAD_VALUE"
mptdc_pvs_require_clean_tracked_tree "$REPO_ROOT"
mptdc_pvs_require_dir "$NEW_BASE"
mptdc_pvs_require_file "$NEW_GDS"
mptdc_pvs_require_file "$NEW_SRC"
mptdc_pvs_require_file "$NEW_HCELL"
mptdc_pvs_require_file "$DCELL_CDL"
for f in "$OLD_LVS_RUN/run.pvs" "$OLD_LVS_RUN/.config.rul" "$OLD_LVS_RUN/.technology.rul" "$OLD_LVS_RUN/pvslvsctl"; do
  mptdc_pvs_require_existing_file "$f"
done
if grep -q -- '-cell_tree' "$OLD_LVS_RUN/run.pvs"; then
  mptdc_pvs_require_existing_file "$OLD_LVS_RUN/cell_tree.txt"
fi

if [[ -e "$NEW_LVS_RUN" ]]; then
  mptdc_pvs_die "new LVS run directory already exists: $NEW_LVS_RUN"
fi

mkdir -p "$NEW_LVS_RUN" "$NEW_BASE/reports" "$NEW_BASE/manifests"
cp -p "$OLD_LVS_RUN/run.pvs" "$NEW_LVS_RUN/run.pvs"
cp -p "$OLD_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/pvslvsctl"
cp -p "$OLD_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.config.rul"
cp -p "$OLD_LVS_RUN/.technology.rul" "$NEW_LVS_RUN/.technology.rul"
[[ -f "$OLD_LVS_RUN/cell_tree.txt" ]] && cp -p "$OLD_LVS_RUN/cell_tree.txt" "$NEW_LVS_RUN/cell_tree.txt"
[[ -f "$OLD_LVS_RUN/.preset.autosave" ]] && cp -p "$OLD_LVS_RUN/.preset.autosave" "$NEW_LVS_RUN/.preset.autosave"

PATCH_FILES=("$NEW_LVS_RUN/run.pvs" "$NEW_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.technology.rul")
[[ -f "$NEW_LVS_RUN/cell_tree.txt" ]] && PATCH_FILES+=("$NEW_LVS_RUN/cell_tree.txt")
[[ -f "$NEW_LVS_RUN/.preset.autosave" ]] && PATCH_FILES+=("$NEW_LVS_RUN/.preset.autosave")

for f in "${PATCH_FILES[@]}"; do
  mptdc_pvs_patch_file_paths "$f" \
    "$OLD_GDS=$NEW_GDS" \
    "$OLD_SRC=$NEW_SRC" \
    "$OLD_HCELL=$NEW_HCELL" \
    "$OLD_LVS_RUN=$NEW_LVS_RUN" \
    "$OLD_BASE=$NEW_BASE" \
    "$DEFAULT_DCELL_CDL=$DCELL_CDL"
done

mptdc_pvs_fail_if_contains_old_path "LVS template run" "$OLD_LVS_RUN" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old base" "$OLD_BASE" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old GDS" "$OLD_GDS" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old source" "$OLD_SRC" "${PATCH_FILES[@]}"
mptdc_pvs_fail_if_contains_old_path "LVS old HCell" "$OLD_HCELL" "${PATCH_FILES[@]}"
chmod +x "$NEW_LVS_RUN/run.pvs"

{
  echo "# MPTDC PVS LVS Replay Manifest"
  echo "date: $(date -Iseconds)"
  echo "old_lvs_run: $OLD_LVS_RUN"
  echo "new_lvs_run: $NEW_LVS_RUN"
  echo "old_base: $OLD_BASE"
  echo "new_base: $NEW_BASE"
  echo "new_gds: $NEW_GDS"
  echo "new_source: $NEW_SRC"
  echo "new_hcell: $NEW_HCELL"
  echo "dcell_cdl: $DCELL_CDL"
  echo "dry_run: $DRY_RUN"
} | tee "$NEW_BASE/manifests/pvs_lvs_replay_manifest.txt"

{
  echo "===== Patched run.pvs ====="
  sed -n '1,180p' "$NEW_LVS_RUN/run.pvs"
  echo
  echo "===== Patched LVS config scan ====="
  grep -RniE 'mptdc_axis_core_merged_stdcell_ro6|NO_DCELL|RO6|RO_tune6|xh018_D_CELLS|LVS_FIND_SHORTS|VDD|VSS|hcell|HCell|SOURCE|source|verilog|cdl|CDL' \
    "$NEW_LVS_RUN/run.pvs" "$NEW_LVS_RUN/pvslvsctl" "$NEW_LVS_RUN/.config.rul" "$NEW_LVS_RUN/.technology.rul" | sed -n '1,420p' || true
} | tee "$NEW_BASE/reports/pvs_lvs_replay_preflight.rpt"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "PVS_LVS_REPLAY_STATUS=DRY_RUN_READY" | tee "$NEW_BASE/reports/pvs_lvs_status.rpt"
  exit 0
fi

for variant in base density; do
  drc_status="$NEW_BASE/reports/pvs_drc_${variant}_status.rpt"
  mptdc_pvs_require_file "$drc_status"
  grep -qx 'PVS_DRC_STATUS=PASS' "$drc_status" || \
    mptdc_pvs_die "LVS blocked because $variant DRC is not PASS: $drc_status"
done

mptdc_pvs_prepend_known_cadence_bins
mptdc_pvs_forbid_bare_linux_lvm_pvs
set +e
(
  cd "$NEW_LVS_RUN"
  bash ./run.pvs
) 2>&1 | tee "$NEW_LVS_RUN/pvs_lvs_replay.stdout"
PVS_RC=${PIPESTATUS[0]}
set -e
echo "PVS_LVS_RC=$PVS_RC" | tee "$NEW_BASE/reports/pvs_lvs_tool_status.rpt"

grep -RIna --binary-files=without-match \
  --exclude='*.rdb' \
  --exclude='*.ecdb' \
  --exclude='netlistLAYOUT' \
  --exclude='netlistSOURCE' \
  --exclude-dir='REPORTDB' \
  -E 'LVS_FIND_SHORTS|Run Result|Run Summary|short|SHORT|Different labels|VDD_LEFT|VDD_RIGHT|VSS_LEFT|VSS_RIGHT|inputting verilog|inputting.*cdl|RO_tune6|mismatch|match|abort|fatal|error|truncated' \
  "$NEW_LVS_RUN" | head -2000 | tee "$NEW_BASE/reports/pvs_lvs_result_scan.txt" || true

find "$NEW_LVS_RUN" -path '*/SHORTSDB/rule.id' -type f -exec cat {} \; \
  | tee "$NEW_BASE/reports/pvs_lvs_SHORTSDB_rule_id.txt" || true

HASH_MANIFEST="$NEW_BASE/manifests/pvs_input_hashes.rpt"
GATE_REPORT="$NEW_BASE/reports/pvs_lvs_status.rpt"
INVENTORY="$NEW_BASE/reports/pvs_lvs_evidence_inventory.tsv"
set +e
python3 "$SCRIPT_DIR/06_gate_pvs_lvs.py" \
  --run-dir "$NEW_LVS_RUN" \
  --tool-rc "$PVS_RC" \
  --gds "$NEW_GDS" \
  --source "$NEW_SRC" \
  --cdl "$DCELL_CDL" \
  --hcell "$NEW_HCELL" \
  --hash-manifest "$HASH_MANIFEST" \
  --layout-top mptdc_axis_core \
  --source-top mptdc_axis_core \
  --out "$GATE_REPORT" \
  --inventory "$INVENTORY"
GATE_RC=$?
set -e

if [[ "$PVS_RC" -ne 0 ]]; then
  exit "$PVS_RC"
fi
exit "$GATE_RC"
