#!/usr/bin/env bash
# Audit XH018 row-infrastructure cells without launching Innovus.
#
# This script is intentionally read-only. It separates core-row candidates from
# IO-ring fillers/corners so pad cells are not accidentally promoted into
# standard-cell tap/endcap policy.

set -euo pipefail

PDK_ROOT="${PDK_ROOT:-/eda/pdk/xfab/xh018}"
STDCELL_LEF="${MPTDC_STDCELL_LEF:-/eda/pdk/xfab/xh018/diglibs/D_CELLS_JIHD/v6_0/LEF/v6_0_0/xh018_D_CELLS_JIHD.lef}"
OUT_DIR="${OUT_DIR:-/tmp}"
RUN_TAG="${MPTDC_ROW_AUDIT_TAG:-$(date +%Y%m%d_%H%M%S)}"

mkdir -p "$OUT_DIR"

LEF_LIST="$OUT_DIR/xh018_all_lefs_${RUN_TAG}.txt"
ROW_TSV="$OUT_DIR/mptdc_xh018_row_physical_candidates_${RUN_TAG}.tsv"
PG_RPT="$OUT_DIR/mptdc_xh018_stdcell_pg_${RUN_TAG}.rpt"
HASH_RPT="$OUT_DIR/mptdc_xh018_row_infra_hashes_${RUN_TAG}.rpt"
SUMMARY="$OUT_DIR/mptdc_xh018_row_infra_summary_${RUN_TAG}.rpt"

if [[ ! -d "$PDK_ROOT" ]]; then
  echo "ROW_AUDIT_STATUS=FAIL"
  echo "ROW_AUDIT_ERROR=PDK_ROOT_NOT_FOUND:$PDK_ROOT"
  exit 1
fi

if [[ ! -f "$STDCELL_LEF" ]]; then
  echo "ROW_AUDIT_STATUS=FAIL"
  echo "ROW_AUDIT_ERROR=STDCELL_LEF_NOT_FOUND:$STDCELL_LEF"
  exit 1
fi

find "$PDK_ROOT" -type f -iname "*.lef" | sort > "$LEF_LIST"

while IFS= read -r lef; do
  awk -v file="$lef" '
    /^[[:space:]]*MACRO[[:space:]]+/ {
      macro=$2
      class=""
      site=""
      size=""
    }
    /^[[:space:]]*CLASS[[:space:]]+/ {
      class=$2
    }
    /^[[:space:]]*SITE[[:space:]]+/ {
      site=$2
    }
    /^[[:space:]]*SIZE[[:space:]]+/ {
      size=$2 " " $3 " " $4
    }
    /^[[:space:]]*END[[:space:]]+/ && macro != "" && $2 == macro {
      low=tolower(macro " " class " " site)
      if (low ~ /(tap|well|substrate|sub|endcap|boundary|bound|edge|corner|feed|fill|filler)/) {
        scope="UNKNOWN"
        if (tolower(file) ~ /\/io_cells_/ || tolower(site) ~ /^io_/ || class == "PAD") {
          scope="IO"
        } else if (tolower(file) ~ /\/d_cells_/ || tolower(site) ~ /^core/ || class == "CORE") {
          scope="CORE"
        }
        print macro "\tclass=" class "\tsite=" site "\tsize=" size "\tscope=" scope "\t" file
      }
      macro=""
    }
  ' "$lef"
done < "$LEF_LIST" | sort -u > "$ROW_TSV"

awk '
  function emit(pin, use, macro) {
    key=use "\t" pin
    counts[key]++
    if (!(key in first_macro)) {
      first_macro[key]=macro
    }
  }
  /^[[:space:]]*MACRO[[:space:]]+/ {
    macro=$2
    pin=""
    next
  }
  macro != "" && /^[[:space:]]*PIN[[:space:]]+/ {
    pin=$2
    next
  }
  macro != "" && pin != "" && /^[[:space:]]*USE[[:space:]]+POWER[[:space:]]*;/ {
    emit(pin, "POWER", macro)
    next
  }
  macro != "" && pin != "" && /^[[:space:]]*USE[[:space:]]+GROUND[[:space:]]*;/ {
    emit(pin, "GROUND", macro)
    next
  }
  macro != "" && pin != "" && /^[[:space:]]*END[[:space:]]+/ && $2 == pin {
    pin=""
    next
  }
  macro != "" && /^[[:space:]]*END[[:space:]]+/ && $2 == macro {
    macro=""
    pin=""
    next
  }
  END {
    for (key in counts) {
      split(key, parts, "\t")
      print parts[1] "\t" parts[2] "\tcount=" counts[key] "\tfirst_macro=" first_macro[key]
    }
  }
' "$STDCELL_LEF" | sort > "$PG_RPT"

candidate_lefs="$(mktemp "${TMPDIR:-/tmp}/mptdc_xh018_row_lefs.XXXXXX")"
awk -F'\t' '{print $6}' "$ROW_TSV" | sort -u > "$candidate_lefs"
{
  sha256sum "$STDCELL_LEF"
  xargs -r sha256sum < "$candidate_lefs"
} | sort -u > "$HASH_RPT"
rm -f "$candidate_lefs"

core_tap_count="$(awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(tap|welltap|wtap|well|substrate|sub)/ {n++} END {print n+0}' "$ROW_TSV")"
core_endcap_count="$(awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(endcap|boundary|bound|edge|corner|^end)/ {n++} END {print n+0}' "$ROW_TSV")"
core_filler_count="$(awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(feed|fill|filler)/ {n++} END {print n+0}' "$ROW_TSV")"
io_endcap_count="$(awk -F'\t' '$5=="scope=IO" && tolower($1 " " $2 " " $3) ~ /(endcap|boundary|bound|edge|corner|^end)/ {n++} END {print n+0}' "$ROW_TSV")"

power_pins="$(awk -F'\t' '$1=="POWER" {print $2}' "$PG_RPT" | sort -u | paste -sd' ' -)"
ground_pins="$(awk -F'\t' '$1=="GROUND" {print $2}' "$PG_RPT" | sort -u | paste -sd' ' -)"

recommended_fillers="$(
  awk -F'\t' '
    $5=="scope=CORE" && $3=="site=core_jihd" && $1 ~ /^FEED/ {
      width=$4
      sub(/^size=/, "", width)
      split(width, parts, " ")
      print parts[1] "\t" $1
    }
  ' "$ROW_TSV" | sort -k1,1nr -k2,2 | awk '{print $2}' | paste -sd' ' -
)"

missing=()
[[ "$core_tap_count" == "0" ]] && missing+=("tap")
[[ "$core_endcap_count" == "0" ]] && missing+=("endcap")
[[ "$core_filler_count" == "0" ]] && missing+=("filler")
[[ -z "$power_pins" ]] && missing+=("stdcell_pg_power")
[[ -z "$ground_pins" ]] && missing+=("stdcell_pg_ground")

status="PASS"
if ((${#missing[@]} > 0)); then
  status="REVIEW_REQUIRED"
fi

{
  echo "ROW_AUDIT_STATUS=$status"
  echo "PDK_ROOT=$PDK_ROOT"
  echo "STDCELL_LEF=$STDCELL_LEF"
  echo "LEF_COUNT=$(wc -l < "$LEF_LIST")"
  echo "CORE_TAP_COUNT=$core_tap_count"
  echo "CORE_ENDCAP_COUNT=$core_endcap_count"
  echo "CORE_FILLER_COUNT=$core_filler_count"
  echo "IO_ENDCAP_COUNT=$io_endcap_count"
  echo "STDCELL_POWER_PINS=${power_pins:-}"
  echo "STDCELL_GROUND_PINS=${ground_pins:-}"
  echo "RECOMMENDED_JIHD_FILLERS=${recommended_fillers:-}"
  echo "MISSING_ROW_CLASSES=${missing[*]:-none}"
  echo "ROW_CANDIDATES_TSV=$ROW_TSV"
  echo "STDCELL_PG_RPT=$PG_RPT"
  echo "SOURCE_HASHES_RPT=$HASH_RPT"
  echo
  echo "# Core tap candidates"
  awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(tap|welltap|wtap|well|substrate|sub)/ {print}' "$ROW_TSV" | head -80
  echo
  echo "# Core endcap candidates"
  awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(endcap|boundary|bound|edge|corner|^end)/ {print}' "$ROW_TSV" | head -80
  echo
  echo "# Core filler/feed candidates"
  awk -F'\t' '$5=="scope=CORE" && tolower($1 " " $2 " " $3) ~ /(feed|fill|filler)/ {print}' "$ROW_TSV" | head -80
  echo
  echo "# IO endcap candidates, not core-row candidates"
  awk -F'\t' '$5=="scope=IO" && tolower($1 " " $2 " " $3) ~ /(endcap|boundary|bound|edge|corner|^end)/ {print}' "$ROW_TSV" | head -80
} | tee "$SUMMARY"
