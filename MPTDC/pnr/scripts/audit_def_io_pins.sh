#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <route-or-place.def>" >&2
  exit 2
fi

DEF_PATH="$1"
if [[ ! -f "$DEF_PATH" ]]; then
  echo "PIN_DEF_STATUS=FAIL"
  echo "reason=missing_def"
  echo "path=$DEF_PATH"
  exit 1
fi

awk '
function finish_entry(   has_layer,has_place,name) {
  if (entry == "") {
    return
  }
  entries++
  has_layer = (entry ~ /\+ LAYER[[:space:]]+/)
  has_place = (entry ~ /\+ (FIXED|PLACED)[[:space:]]+\(/)
  if (entry ~ /\+ FIXED[[:space:]]+\(/) {
    fixed++
  }
  if (entry ~ /\+ PLACED[[:space:]]+\(/) {
    placed++
  }
  if (has_layer) {
    with_layer++
  }
  if (!has_layer || !has_place) {
    missing++
    if (missing <= 40) {
      name = entry
      sub(/^[[:space:]]*-[[:space:]]*/, "", name)
      sub(/[[:space:]].*$/, "", name)
      missing_names = missing_names name "\n"
    }
  }
  entry = ""
}

BEGIN {
  in_pins = 0
  declared = "UNKNOWN"
  entries = fixed = placed = with_layer = missing = 0
  entry = ""
  missing_names = ""
}

/^PINS[[:space:]]+[0-9]+[[:space:]]*;/ {
  in_pins = 1
  declared = $2
  next
}

in_pins && /^END[[:space:]]+PINS/ {
  finish_entry()
  in_pins = 0
  next
}

in_pins && /^[[:space:]]*-[[:space:]]/ {
  finish_entry()
  entry = $0
  if ($0 ~ /;/) {
    finish_entry()
  }
  next
}

in_pins && entry != "" {
  entry = entry " " $0
  if ($0 ~ /;/) {
    finish_entry()
  }
}

END {
  status = (declared != "UNKNOWN" && entries == declared && missing == 0) ? "PASS" : "FAIL"
  print "PIN_DEF_STATUS=" status
  print "declared_pins=" declared
  print "pin_entries=" entries
  print "fixed_pins=" fixed
  print "placed_pins=" placed
  print "pins_with_layer=" with_layer
  print "pins_missing_layer_or_placement=" missing
  if (missing > 0) {
    print ""
    print "First missing/unplaced pins:"
    printf "%s", missing_names
  }
}
' "$DEF_PATH"
