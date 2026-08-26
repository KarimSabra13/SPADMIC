#!/usr/bin/env bash
# Shared helpers for MPTDC PVS replay scripts.
set -euo pipefail

mptdc_pvs_script_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

mptdc_pvs_repo_root() {
  local script_dir
  script_dir="$(mptdc_pvs_script_dir)"
  cd "$script_dir/../../.." && pwd
}

mptdc_pvs_die() {
  echo "ERROR: $*" >&2
  exit 1
}

mptdc_pvs_abs_path() {
  local repo_root="$1"
  local path="$2"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$repo_root" "$path" ;;
  esac
}

mptdc_pvs_require_file() {
  local path="$1"
  [[ -f "$path" ]] || mptdc_pvs_die "required file does not exist: $path"
  [[ -s "$path" ]] || mptdc_pvs_die "required file is empty: $path"
}

mptdc_pvs_require_existing_file() {
  local path="$1"
  [[ -f "$path" ]] || mptdc_pvs_die "required file does not exist: $path"
}

mptdc_pvs_require_dir() {
  local path="$1"
  [[ -d "$path" ]] || mptdc_pvs_die "required directory does not exist: $path"
}

mptdc_pvs_check_git_head() {
  local repo_root="$1"
  local expected_head="${2:-}"
  local actual_head

  actual_head="$(git -C "$repo_root" rev-parse HEAD)"
  echo "REPO_ROOT=$repo_root"
  echo "BRANCH=$(git -C "$repo_root" rev-parse --abbrev-ref HEAD)"
  echo "ACTUAL_HEAD=$actual_head"

  if [[ -n "$expected_head" ]]; then
    echo "EXPECTED_HEAD=$expected_head"
    [[ "$actual_head" == "$expected_head" ]] || \
      mptdc_pvs_die "HEAD mismatch: actual=$actual_head expected=$expected_head"
  else
    echo "EXPECTED_HEAD_HINT=$actual_head"
  fi
}

mptdc_pvs_require_clean_tracked_tree() {
  local repo_root="$1"
  local status
  status="$(git -C "$repo_root" status --short --untracked-files=no)"
  if [[ -n "$status" ]]; then
    echo "$status" >&2
    mptdc_pvs_die "tracked working tree is dirty"
  fi
}

mptdc_pvs_sha256() {
  local path="$1"
  mptdc_pvs_require_file "$path"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
    return 0
  fi
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
    return 0
  fi
  mptdc_pvs_die "no SHA-256 tool found for $path"
}

mptdc_pvs_append_hash() {
  local manifest="$1"
  local label="$2"
  local path="$3"
  local digest
  digest="$(mptdc_pvs_sha256 "$path")"
  printf '%s_PATH=%s\n' "$label" "$path" >> "$manifest"
  printf '%s_SHA256=%s\n' "$label" "$digest" >> "$manifest"
}

mptdc_pvs_copy_template_file() {
  local src="$1"
  local dst="$2"
  mptdc_pvs_require_file "$src"
  mkdir -p "$(dirname "$dst")"
  cp -p "$src" "$dst"
}

mptdc_pvs_patch_file_paths() {
  local file="$1"
  shift
  [[ -f "$file" ]] || return 0

  local pair old new
  for pair in "$@"; do
    old="${pair%%=*}"
    new="${pair#*=}"
    [[ -n "$old" ]] || continue
    perl -0pi -e 'BEGIN { $old = shift @ARGV; $new = shift @ARGV } s|\Q$old\E|$new|g' "$old" "$new" "$file"
  done
}

mptdc_pvs_rewrite_drc_density_control() {
  local control="$1"
  local variant="$2"
  local replacement
  local joined_count density_count popping_count
  local define_count undefine_count
  local popping_before popping_after

  mptdc_pvs_require_file "$control"
  case "$variant" in
    base) replacement="#UNDEFINE DENSITY" ;;
    density) replacement="#DEFINE DENSITY" ;;
    *) mptdc_pvs_die "DRC variant must be base or density: $variant" ;;
  esac

  joined_count="$(grep -Ec '#(UN)?DEFINE[[:space:]]+[[:alnum:]_]+.*#(UN)?DEFINE[[:space:]]+' "$control" || true)"
  [[ "$joined_count" -eq 0 ]] || \
    mptdc_pvs_die "joined configurator directives found in $control"

  density_count="$(grep -Ec '^[[:space:]]*#(UN)?DEFINE[[:space:]]+DENSITY[[:space:]]*$' "$control" || true)"
  [[ "$density_count" -eq 1 ]] || \
    mptdc_pvs_die "expected exactly one DENSITY control in $control"

  popping_count="$(grep -Ec '^[[:space:]]*#(UN)?DEFINE[[:space:]]+POPPING[[:space:]]*$' "$control" || true)"
  [[ "$popping_count" -eq 1 ]] || \
    mptdc_pvs_die "expected exactly one POPPING control in $control"
  popping_before="$(grep -E '^[[:space:]]*#(UN)?DEFINE[[:space:]]+POPPING[[:space:]]*$' "$control" | tr -d '\r')"

  # Match horizontal whitespace only so the record terminator is never consumed.
  perl -pi -e '
    BEGIN { $replacement = shift @ARGV }
    s/^([ \t]*)#(?:UN)?DEFINE[ \t]+DENSITY[ \t]*(\r?)$/${1}${replacement}${2}/
  ' "$replacement" "$control"

  define_count="$(grep -Ec '^[[:space:]]*#DEFINE[[:space:]]+DENSITY[[:space:]]*$' "$control" || true)"
  undefine_count="$(grep -Ec '^[[:space:]]*#UNDEFINE[[:space:]]+DENSITY[[:space:]]*$' "$control" || true)"
  if [[ "$variant" == "base" ]]; then
    [[ "$define_count" -eq 0 && "$undefine_count" -eq 1 ]] || \
      mptdc_pvs_die "base DRC control rewrite did not produce exactly one #UNDEFINE DENSITY"
  else
    [[ "$define_count" -eq 1 && "$undefine_count" -eq 0 ]] || \
      mptdc_pvs_die "density DRC control rewrite did not produce exactly one #DEFINE DENSITY"
  fi

  joined_count="$(grep -Ec '#(UN)?DEFINE[[:space:]]+[[:alnum:]_]+.*#(UN)?DEFINE[[:space:]]+' "$control" || true)"
  [[ "$joined_count" -eq 0 ]] || \
    mptdc_pvs_die "joined configurator directives remain after rewrite in $control"
  popping_after="$(grep -E '^[[:space:]]*#(UN)?DEFINE[[:space:]]+POPPING[[:space:]]*$' "$control" | tr -d '\r')"
  [[ "$popping_after" == "$popping_before" ]] || \
    mptdc_pvs_die "POPPING control changed during DENSITY rewrite in $control"

  echo "PVS_DRC_CONTROL_REWRITE_STATUS=PASS"
  echo "PVS_DRC_CONTROL_VARIANT=$variant"
  echo "PVS_DRC_DENSITY_CONTROL=$replacement"
  echo "PVS_DRC_POPPING_CONTROL=$popping_after"
  echo "PVS_DRC_JOINED_DIRECTIVE_COUNT=$joined_count"
}

mptdc_pvs_streamout_map_binding_mode() {
  local template="$1"
  local selected_map="$2"

  [[ -f "$template" && -n "$selected_map" ]] || return 2
  grep -Fq -- '-mapFile' "$template" || return 1

  if perl -0 -e '
    my ($map, $file) = @ARGV;
    open my $fh, "<", $file or exit 2;
    local $/;
    my $text = <$fh>;
    my $quoted = quotemeta($map);
    exit($text =~ /-mapFile\s+(?:\{|\")?$quoted(?:\}|\")?(?=\s|\\|;|\]|$)/s ? 0 : 1);
  ' "$selected_map" "$template"; then
    echo "LITERAL_SELECTED_MAP"
    return 0
  fi

  if grep -Eq '\$(::)?env\(STREAM_MAP\)|\$\{(::)?env\(STREAM_MAP\)\}' "$template"; then
    echo "ENV_SELECTED_MAP"
    return 0
  fi

  return 1
}

mptdc_pvs_fail_if_contains_old_path() {
  local label="$1"
  local old_path="$2"
  shift 2
  [[ -n "$old_path" ]] || return 0

  local file
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    if grep -Fq "$old_path" "$file"; then
      echo "Found stale $label path in $file:" >&2
      grep -Fn "$old_path" "$file" | head -20 >&2 || true
      mptdc_pvs_die "stale $label path remains after template patching"
    fi
  done
}

mptdc_pvs_report_tool_path() {
  local tool="$1"
  local path
  path="$(type -P "$tool" 2>/dev/null || true)"
  if [[ -z "$path" ]]; then
    echo "${tool}=MISSING"
    return 0
  fi
  echo "${tool}=$path"
  "$path" -version 2>&1 | sed -n '1,20p' || true
}

mptdc_pvs_forbid_bare_linux_lvm_pvs() {
  local path
  path="$(type -P pvs 2>/dev/null || true)"
  if [[ "$path" == "/usr/sbin/pvs" ]]; then
    mptdc_pvs_die "bare pvs resolves to /usr/sbin/pvs; source Cadence env or prepend a Cadence PVS/Pegasus bin directory"
  fi
}

mptdc_pvs_prepend_known_cadence_bins() {
  local candidates=()
  if [[ -n "${MPTDC_PVS_CADENCE_BIN:-}" ]]; then
    candidates+=("$MPTDC_PVS_CADENCE_BIN")
  fi
  candidates+=(
    "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin"
    "/eda/cadence/2023-24/RHELx86/PVS_22.22.000/tools/bin"
    "/eda/cadence/2023-24/RHELx86/PEGASUS_23.11.000/bin"
  )

  local dir
  for dir in "${candidates[@]}"; do
    if [[ -d "$dir" && ( -x "$dir/pvs" || -x "$dir/pegasus" ) ]]; then
      PATH="$dir:$PATH"
    fi
  done
  export PATH
}

mptdc_pvs_write_manifest_header() {
  local path="$1"
  local title="$2"
  mkdir -p "$(dirname "$path")"
  {
    echo "# $title"
    echo "date: $(date -Iseconds)"
    echo "host: $(hostname 2>/dev/null || echo unknown)"
    echo "user: ${USER:-unknown}"
  } > "$path"
}
