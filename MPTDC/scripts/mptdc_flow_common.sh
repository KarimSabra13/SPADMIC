#!/usr/bin/env bash
# Shared helpers for stable MPTDC flow wrappers.

mptdc_common_repo_root() {
  local start_dir="$1"
  local root
  root="$(git -C "$start_dir" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$root" ]]; then
    printf '%s\n' "$root"
    return 0
  fi
  (cd "$start_dir" && pwd)
}

mptdc_common_abs_path() {
  local repo_root="$1"
  local path="$2"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$repo_root" "$path" ;;
  esac
}

mptdc_common_init_work_roots() {
  local repo_root="$1"
  MPTDC_WORK_ROOT="${MPTDC_WORK_ROOT:-work}"
  MPTDC_WORK_ROOT="$(mptdc_common_abs_path "$repo_root" "$MPTDC_WORK_ROOT")"
  export MPTDC_WORK_ROOT

  MPTDC_GENUS_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_GENUS_WORK:-$MPTDC_WORK_ROOT/genus}")"
  MPTDC_INNOVUS_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_INNOVUS_WORK:-$MPTDC_WORK_ROOT/innovus}")"
  MPTDC_XCELIUM_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_XCELIUM_WORK:-$MPTDC_WORK_ROOT/xcelium}")"
  MPTDC_VERILATOR_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_VERILATOR_WORK:-$MPTDC_WORK_ROOT/verilator}")"
  MPTDC_CHARACTERIZATION_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_CHARACTERIZATION_WORK:-$MPTDC_WORK_ROOT/characterization}")"
  MPTDC_CALIBRATION_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_CALIBRATION_WORK:-$MPTDC_WORK_ROOT/calibration}")"
  MPTDC_EVIDENCE_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_EVIDENCE_WORK:-$MPTDC_WORK_ROOT/evidence}")"
  MPTDC_LOG_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_LOG_WORK:-$MPTDC_WORK_ROOT/logs}")"
  MPTDC_SCRATCH_WORK="$(mptdc_common_abs_path "$repo_root" "${MPTDC_SCRATCH_WORK:-$MPTDC_WORK_ROOT/scratch}")"
  export MPTDC_GENUS_WORK MPTDC_INNOVUS_WORK MPTDC_XCELIUM_WORK MPTDC_VERILATOR_WORK
  export MPTDC_CHARACTERIZATION_WORK MPTDC_CALIBRATION_WORK MPTDC_EVIDENCE_WORK
  export MPTDC_LOG_WORK MPTDC_SCRATCH_WORK
}

mptdc_common_require_clean_tracked() {
  local repo_root="$1"
  if [[ "${MPTDC_ALLOW_DIRTY:-0}" == "1" ]]; then
    return 0
  fi
  local dirty
  dirty="$(git -C "$repo_root" status --short --untracked-files=no 2>/dev/null || true)"
  if [[ -n "$dirty" ]]; then
    echo "ERROR: tracked working tree is dirty. Set MPTDC_ALLOW_DIRTY=1 to override." >&2
    echo "$dirty" >&2
    return 2
  fi
}

mptdc_common_require_file() {
  local label="$1"
  local path="$2"
  if [[ ! -f "$path" ]]; then
    echo "ERROR: missing $label: $path" >&2
    return 2
  fi
}

mptdc_common_print_run_header() {
  local title="$1"
  local repo_root="$2"
  local run_id="$3"
  local run_dir="$4"
  local legacy_trace="$5"
  echo "# $title"
  echo "RUN_ID=$run_id"
  echo "RUN_DIR=$run_dir"
  echo "GIT_HEAD=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null || true)"
  echo "GIT_BRANCH=$(git -C "$repo_root" branch --show-current 2>/dev/null || true)"
  echo "FINAL_SIGNOFF=NO"
  echo "LEGACY_TRACE=$legacy_trace"
}

mptdc_common_opt_mode_define_names() {
  local mode="${1:-STRIDE2}"
  case "$mode" in
    BASELINE)
      return 0
      ;;
    SAFE_TEARDOWN)
      printf '%s\n' MPTDC_SAFE_TEARDOWN
      ;;
    ROW_SKIP)
      printf '%s\n' MPTDC_SAFE_TEARDOWN MPTDC_DRAIN_ROW_SKIP
      ;;
    STRIDE2)
      printf '%s\n' MPTDC_SAFE_TEARDOWN MPTDC_DRAIN_ROW_SKIP MPTDC_DRAIN_SCAN_STRIDE2
      ;;
    CLEAR_EARLY)
      printf '%s\n' MPTDC_SAFE_TEARDOWN MPTDC_DRAIN_ROW_SKIP MPTDC_DRAIN_SCAN_STRIDE2 MPTDC_PD_CLEAR_EARLY
      ;;
    CAPTURE_CLEAR_EXPERIMENTAL)
      echo "ERROR: CAPTURE_CLEAR_EXPERIMENTAL is documented but not implemented in this branch yet." >&2
      return 2
      ;;
    *)
      echo "ERROR: unsupported MPTDC_OPT_MODE=$mode" >&2
      echo "Supported: BASELINE SAFE_TEARDOWN ROW_SKIP STRIDE2 CLEAR_EARLY" >&2
      return 2
      ;;
  esac
}

mptdc_common_opt_mode_define_args() {
  local mode="${1:-STRIDE2}"
  local names
  if ! names="$(mptdc_common_opt_mode_define_names "$mode")"; then
    return 2
  fi
  local name
  while IFS= read -r name; do
    [[ -n "$name" ]] && printf '+define+%s\n' "$name"
  done <<< "$names"
  return 0
}

mptdc_common_opt_mode_define_csv() {
  local mode="${1:-STRIDE2}"
  local names
  if ! names="$(mptdc_common_opt_mode_define_names "$mode")"; then
    return 2
  fi
  local name
  local joined=""
  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    if [[ -n "$joined" ]]; then
      joined+=","
    fi
    joined+="$name"
  done <<< "$names"
  printf '%s\n' "$joined"
  return 0
}
