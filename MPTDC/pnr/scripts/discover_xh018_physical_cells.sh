#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNR_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MPTDC_DIR="$(cd "$PNR_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MPTDC_DIR/.." && pwd)"

OUT=""
LEF_FILES=()
LIB_FILES=()
SEARCH_ROOTS=()
COMPACT=0

usage() {
  cat <<'USAGE'
Usage:
  discover_xh018_physical_cells.sh [options]

Options:
  --lef <file>       Add a LEF file to scan. Repeatable.
  --lib <file>       Add a Liberty file to scan. Repeatable.
  --root <dir>       Add a directory to search for *.lef/*.lib. Repeatable.
  --out <file>       Write a Tcl candidate file.
  --compact          Print a short console report; full details remain in Tcl.
  -h, --help         Show this help.

The script only reports candidates found in real LEF/Liberty inputs. It does
not invent or hard-code XH018 tap, endcap, filler, antenna, decap, or tie names.
USAGE
}

abs_path() {
  local path="$1"
  case "$path" in
    /*) printf '%s\n' "$path" ;;
    *) printf '%s/%s\n' "$REPO_ROOT" "$path" ;;
  esac
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lef)
      LEF_FILES+=("$(abs_path "${2:?missing --lef value}")")
      shift 2
      ;;
    --lib)
      LIB_FILES+=("$(abs_path "${2:?missing --lib value}")")
      shift 2
      ;;
    --root)
      SEARCH_ROOTS+=("$(abs_path "${2:?missing --root value}")")
      shift 2
      ;;
    --out)
      OUT="$(abs_path "${2:?missing --out value}")"
      shift 2
      ;;
    --compact)
      COMPACT=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      echo "ERROR: unexpected argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

for env_name in MPTDC_XH018_ROOT MPTDC_TECH_ROOT MPTDC_PDK_ROOT XFAB_PDK_ROOT PDK_ROOT; do
  if [[ -n "${!env_name:-}" && -d "${!env_name}" ]]; then
    SEARCH_ROOTS+=("${!env_name}")
  fi
done

if [[ "${#SEARCH_ROOTS[@]}" -gt 0 ]]; then
  while IFS= read -r file; do LEF_FILES+=("$file"); done < <(
    find "${SEARCH_ROOTS[@]}" -type f \( -iname '*.lef' -o -iname '*.tlef' \) 2>/dev/null | sort -u
  )
  while IFS= read -r file; do LIB_FILES+=("$file"); done < <(
    find "${SEARCH_ROOTS[@]}" -type f \( -iname '*.lib' -o -iname '*.lib.gz' \) 2>/dev/null | sort -u
  )
fi

if [[ "${#LEF_FILES[@]}" -eq 0 && "${#LIB_FILES[@]}" -eq 0 ]]; then
  echo "ERROR: no LEF/Liberty inputs found. Pass --lef/--lib/--root or set a PDK root environment variable." >&2
  exit 3
fi

TMP_NAMES="$(mktemp)"
TMP_LEF_NAMES="$(mktemp)"
TMP_LIB_NAMES="$(mktemp)"
TMP_HASHES="$(mktemp)"
trap 'rm -f "$TMP_NAMES" "$TMP_LEF_NAMES" "$TMP_LIB_NAMES" "$TMP_HASHES"' EXIT

hash_inputs() {
  {
    for file in "${LEF_FILES[@]}"; do
      [[ -f "$file" ]] && sha256sum "$file"
    done
    for file in "${LIB_FILES[@]}"; do
      [[ -f "$file" ]] && sha256sum "$file"
    done
  } | sort -u > "$TMP_HASHES"
}

if [[ "${#LEF_FILES[@]}" -gt 0 ]]; then
  awk '
    /^[[:space:]]*MACRO[[:space:]]+/ {print $2}
  ' "${LEF_FILES[@]}" | sort -u > "$TMP_LEF_NAMES"
  cat "$TMP_LEF_NAMES" >> "$TMP_NAMES"
fi

if [[ "${#LIB_FILES[@]}" -gt 0 ]]; then
  for lib in "${LIB_FILES[@]}"; do
    if [[ "$lib" == *.gz ]]; then
      gzip -cd "$lib"
    else
      sed -n '1,$p' "$lib"
    fi
  done | awk '
    /^[[:space:]]*cell[[:space:]]*\(/ {
      line=$0
      sub(/^[^(]*\(/, "", line)
      sub(/\).*/, "", line)
      gsub(/[[:space:]"]/, "", line)
      if (line != "") print line
    }
  ' | sort -u > "$TMP_LIB_NAMES"
  cat "$TMP_LIB_NAMES" >> "$TMP_NAMES"
fi

sort -u "$TMP_NAMES" -o "$TMP_NAMES"
hash_inputs

classify() {
  local pattern="$1"
  awk -v pat="$pattern" '
    {
      low=tolower($0)
      if (low ~ pat) print $0
    }
  ' "$TMP_NAMES" | paste -sd' ' -
}

classify_exact_or_prefix() {
  local pattern="$1"
  awk -v pat="$pattern" '
    {
      if ($0 ~ pat) print $0
    }
  ' "$TMP_NAMES" | paste -sd' ' -
}

classify_intersection() {
  local pattern="$1"
  awk -v pat="$pattern" '
    FNR==NR {
      if ($0 ~ pat) lef[$0]=1
      next
    }
    ($0 ~ pat) && ($0 in lef) {print $0}
  ' "$TMP_LEF_NAMES" "$TMP_LIB_NAMES" | paste -sd' ' -
}

TAP="$(classify '(^|_)(tap|welltap|wtap)')"
ENDCAP="$(classify '(endcap|^end|_end)')"
FILLER="$(classify '(fill|filler)')"
DECAP="$(classify '(decap|dcap)')"
ANTENNA="$(classify '(antenna|ant)')"
TIE_HIGH="$(classify '(tiehi|tieh|tie1|tie_high|tieone|logic1)')"
TIE_LOW="$(classify '(tielo|tiel|tie0|tie_low|tiezero|logic0)')"
CTS_BUFFERS="$(classify '(clk.*buf|buf.*clk|^ct.*buf|^ck.*buf|clock.*buffer)')"
CTS_INVERTERS="$(classify '(clk.*inv|inv.*clk|^ct.*inv|^ck.*inv|clock.*invert|^in.*jihd|^in.*hd)')"
JIHD_PHASE_X4="$(classify_intersection '^(BUJIHDX4|BU.*JIHD.*X4)$')"
JIHD_PHASE_X12="$(classify_intersection '^(BUJIHDX12|BU.*JIHD.*X12)$')"
HD_PHASE_X4="$(classify_intersection '^BUHDX4$')"
HD_PHASE_X12="$(classify_intersection '^BUHDX12$')"
JIHD_BUFFERS="$(classify_exact_or_prefix '(^BUJIHD|JIHD.*BUF|BUF.*JIHD)')"

PHASE_ISO_RECOMMENDED=""
PHASE_FINAL_RECOMMENDED=""
PHASE_POLICY_RECOMMENDED="UNRESOLVED_REVIEW_REQUIRED"
if [[ " $JIHD_PHASE_X4 " == *" BUJIHDX4 "* && " $JIHD_PHASE_X12 " == *" BUJIHDX12 "* ]]; then
  PHASE_ISO_RECOMMENDED="BUJIHDX4"
  PHASE_FINAL_RECOMMENDED="BUJIHDX12"
  PHASE_POLICY_RECOMMENDED="PREFER_UNIFORM_JIHD_AFTER_FRESH_GENUS_RERUN"
elif [[ " $HD_PHASE_X4 " == *" BUHDX4 "* && " $HD_PHASE_X12 " == *" BUHDX12 "* ]]; then
  PHASE_ISO_RECOMMENDED="BUHDX4"
  PHASE_FINAL_RECOMMENDED="BUHDX12"
  PHASE_POLICY_RECOMMENDED="FALLBACK_MIXED_OR_LEGACY_PHASE_TOPOLOGY_REVIEW"
fi

missing_required_candidates() {
  local missing=()
  [[ -z "$TAP" ]] && missing+=("tap")
  [[ -z "$ENDCAP" ]] && missing+=("endcap")
  [[ -z "$FILLER" ]] && missing+=("filler")
  [[ -z "$DECAP" ]] && missing+=("decap")
  [[ -z "$ANTENNA" ]] && missing+=("antenna")
  [[ -z "$TIE_HIGH" ]] && missing+=("tie_high")
  [[ -z "$TIE_LOW" ]] && missing+=("tie_low")
  [[ -z "$CTS_BUFFERS" ]] && missing+=("cts_buffers")
  [[ -z "$CTS_INVERTERS" ]] && missing+=("cts_inverters")
  [[ -z "$PHASE_ISO_RECOMMENDED" ]] && missing+=("phase_iso_buffer")
  [[ -z "$PHASE_FINAL_RECOMMENDED" ]] && missing+=("phase_final_buffer")
  printf '%s\n' "${missing[*]:-none}"
}

emit_report() {
  echo "# XH018 physical-cell candidate discovery"
  echo "status=UNCONFIRMED_CANDIDATES"
  echo "lef_count=${#LEF_FILES[@]}"
  echo "lib_count=${#LIB_FILES[@]}"
  if [[ "$COMPACT" != "1" ]]; then
    echo "lef_files=${LEF_FILES[*]:-}"
    echo "lib_files=${LIB_FILES[*]:-}"
    echo "source_hashes_begin"
    sed 's/^/  /' "$TMP_HASHES"
    echo "source_hashes_end"
  fi
  echo "tap_candidates=${TAP:-}"
  echo "endcap_candidates=${ENDCAP:-}"
  echo "filler_candidates=${FILLER:-}"
  echo "decap_candidates=${DECAP:-}"
  echo "antenna_candidates=${ANTENNA:-}"
  echo "tie_high_candidates=${TIE_HIGH:-}"
  echo "tie_low_candidates=${TIE_LOW:-}"
  echo "cts_buffer_candidates=${CTS_BUFFERS:-}"
  echo "cts_inverter_candidates=${CTS_INVERTERS:-}"
  echo "jihd_phase_x4_candidates=${JIHD_PHASE_X4:-}"
  echo "jihd_phase_x12_candidates=${JIHD_PHASE_X12:-}"
  echo "hd_phase_x4_candidates=${HD_PHASE_X4:-}"
  echo "hd_phase_x12_candidates=${HD_PHASE_X12:-}"
  echo "jihd_buffer_candidates=${JIHD_BUFFERS:-}"
  echo "phase_iso_recommended=${PHASE_ISO_RECOMMENDED:-}"
  echo "phase_final_recommended=${PHASE_FINAL_RECOMMENDED:-}"
  echo "phase_buffer_policy_recommended=${PHASE_POLICY_RECOMMENDED:-}"
  echo "missing_required_candidates=$(missing_required_candidates)"
  if [[ "$COMPACT" == "1" ]]; then
    echo "full_candidate_tcl=${OUT:-not_requested}"
  fi
}

emit_tcl() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  {
    echo "# Generated by discover_xh018_physical_cells.sh"
    echo "# Review before changing confirmed to 1 or selecting insertion cells."
    echo "global mptdc_xh018_cells"
    echo "array set mptdc_xh018_cells {"
    echo "    status              UNCONFIRMED_CANDIDATES"
    echo "    confirmed           0"
    echo "    tap                 {}"
    echo "    endcap_left         {}"
    echo "    endcap_right        {}"
    echo "    filler              {}"
    echo "    decap               {}"
    echo "    antenna             {}"
    echo "    tie_high            {}"
    echo "    tie_low             {}"
    echo "    cts_buffers         {}"
    echo "    cts_inverters       {}"
    echo "    phase_iso_buffer    {${PHASE_ISO_RECOMMENDED:-}}"
    echo "    phase_final_buffer  {${PHASE_FINAL_RECOMMENDED:-}}"
    echo "    phase_buffer_policy {${PHASE_POLICY_RECOMMENDED:-}}"
    echo "    stdcell_site        {}"
    echo "    stdcell_pg_power    {}"
    echo "    stdcell_pg_ground   {}"
    echo "    source              {discover_xh018_physical_cells.sh}"
    echo "    source_hashes       {"
    sed 's/^/        /' "$TMP_HASHES"
    echo "    }"
    echo "    tap_candidates      {${TAP:-}}"
    echo "    endcap_candidates   {${ENDCAP:-}}"
    echo "    filler_candidates   {${FILLER:-}}"
    echo "    decap_candidates    {${DECAP:-}}"
    echo "    antenna_candidates  {${ANTENNA:-}}"
    echo "    tie_high_candidates {${TIE_HIGH:-}}"
    echo "    tie_low_candidates  {${TIE_LOW:-}}"
    echo "    cts_buffer_candidates {${CTS_BUFFERS:-}}"
    echo "    cts_inverter_candidates {${CTS_INVERTERS:-}}"
    echo "    jihd_phase_x4_candidates {${JIHD_PHASE_X4:-}}"
    echo "    jihd_phase_x12_candidates {${JIHD_PHASE_X12:-}}"
    echo "    hd_phase_x4_candidates {${HD_PHASE_X4:-}}"
    echo "    hd_phase_x12_candidates {${HD_PHASE_X12:-}}"
    echo "    jihd_buffer_candidates {${JIHD_BUFFERS:-}}"
    echo "    missing_required_candidates {$(missing_required_candidates)}"
    echo "}"
  } > "$path"
}

emit_report
if [[ -n "$OUT" ]]; then
  emit_tcl "$OUT"
  echo "wrote_tcl=$OUT"
fi
