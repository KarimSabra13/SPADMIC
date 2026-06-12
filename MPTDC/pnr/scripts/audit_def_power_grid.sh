#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <route-or-place.def>" >&2
  exit 2
fi

DEF_PATH="$1"
if [[ ! -f "$DEF_PATH" ]]; then
  echo "POWER_DEF_STATUS=FAIL"
  echo "reason=missing_def"
  echo "path=$DEF_PATH"
  exit 1
fi

awk '
function finish_entry(   is_vdd,is_vss,has_geom) {
  if (entry == "") {
    return
  }
  entries++
  is_vdd = (entry ~ /^[[:space:]]*-[[:space:]]+VDD[[:space:]]/)
  is_vss = (entry ~ /^[[:space:]]*-[[:space:]]+VSS[[:space:]]/)
  has_geom = (entry ~ /\+ (ROUTED|FIXED|COVER|SHAPE)[[:space:]]+/)
  if (is_vdd) {
    vdd++
    if (has_geom) {
      vdd_geom++
    }
  }
  if (is_vss) {
    vss++
    if (has_geom) {
      vss_geom++
    }
  }
  if (has_geom) {
    geom++
  }
  entry = ""
}

BEGIN {
  in_special = 0
  declared = "UNKNOWN"
  entries = vdd = vss = geom = vdd_geom = vss_geom = 0
  entry = ""
}

/^SPECIALNETS[[:space:]]+[0-9]+[[:space:]]*;/ {
  in_special = 1
  declared = $2
  next
}

in_special && /^END[[:space:]]+SPECIALNETS/ {
  finish_entry()
  in_special = 0
  next
}

in_special && /^[[:space:]]*-[[:space:]]/ {
  finish_entry()
  entry = $0
  if ($0 ~ /;/) {
    finish_entry()
  }
  next
}

in_special && entry != "" {
  entry = entry " " $0
  if ($0 ~ /;/) {
    finish_entry()
  }
}

END {
  status = (vdd > 0 && vss > 0 && vdd_geom > 0 && vss_geom > 0) ? "PASS" : "FAIL"
  print "POWER_DEF_STATUS=" status
  print "specialnets_declared=" declared
  print "specialnet_entries=" entries
  print "vdd_entries=" vdd
  print "vss_entries=" vss
  print "specialnets_with_geometry=" geom
  print "vdd_entries_with_geometry=" vdd_geom
  print "vss_entries_with_geometry=" vss_geom
}
' "$DEF_PATH"
