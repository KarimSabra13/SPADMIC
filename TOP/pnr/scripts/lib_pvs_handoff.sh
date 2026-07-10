#!/usr/bin/env bash
# Shared guards for block/assembly PVS template replay.

spadmic_pvs_die() {
  echo "ERROR: $*" >&2
  exit 1
}

spadmic_pvs_require_file() {
  local path="$1"
  [[ -f "$path" && -s "$path" ]] || spadmic_pvs_die "missing or empty file: $path"
}

spadmic_pvs_require_dir() {
  local path="$1"
  [[ -d "$path" ]] || spadmic_pvs_die "missing directory: $path"
}

spadmic_pvs_binary() {
  local binary="${SPADMIC_CADENCE_PVS_BIN:-/eda/cadence/2023-24/RHELx86/PVS_22.22.000/bin/pvs}"
  [[ "$binary" == /eda/cadence/*/pvs ]] || spadmic_pvs_die "non-Cadence PVS binary rejected: $binary"
  [[ -x "$binary" ]] || spadmic_pvs_die "Cadence PVS binary not executable: $binary"
  printf '%s\n' "$binary"
}

spadmic_pvs_manifest_value() {
  local package="$1"
  local key="$2"
  python3 - "$package/manifests/package.json" "$key" <<'PY'
import json
import sys

value = json.load(open(sys.argv[1]))
for part in sys.argv[2].split('.'):
    value = value[part]
print(value)
PY
}

spadmic_pvs_check_head() {
  local repo="$1"
  local expected="${EXPECTED_HEAD:-}"
  local actual
  actual="$(git -C "$repo" rev-parse HEAD)"
  echo "ACTUAL_HEAD=$actual"
  echo "EXPECTED_HEAD=${expected:-$actual}"
  if [[ -n "$expected" && "$actual" != "$expected" ]]; then
    spadmic_pvs_die "HEAD mismatch: actual=$actual expected=$expected"
  fi
}

spadmic_pvs_hash_run() {
  local run_dir="$1"
  find "$run_dir" -type f \
    ! -path '*/REPORTDB/*' \
    ! -path '*.pvstdb/*' \
    ! -name SHA256SUMS -print0 \
    | sort -z | xargs -0 sha256sum >"$run_dir/SHA256SUMS"
}

spadmic_pvs_require_external_references() {
  local report="$1"
  spadmic_pvs_require_file "$report"
  if grep -q '^MISSING=' "$report"; then
    grep '^MISSING=' "$report" >&2
    spadmic_pvs_die "patched PVS template has missing external references"
  fi
}
