#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTOR="$(cd "$SCRIPT_DIR/.." && pwd)/collect_mptdc_server_snapshot.sh"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

SRC="$TMP_ROOT/source"
SNAPSHOT_ROOT="$TMP_ROOT/snapshots"
SNAPSHOT="$SNAPSHOT_ROOT/pvs/fixture_pvs"

mkdir -p \
  "$SRC/reports" \
  "$SRC/manifests" \
  "$SRC/outputs" \
  "$SRC/pvs_drc/run_base" \
  "$SRC/pvs_lvs/run_lvs"

printf 'STATUS=PASS\n' > "$SRC/reports/operator_gate_fixture.rpt"
printf 'STRICT_ATTRIBUTION=1\n' > "$SRC/manifests/pvs_input_hashes.rpt"
dd if=/dev/zero of="$SRC/reports/oversized.rpt" bs=2048 count=1 status=none
printf 'binary layout placeholder\n' > "$SRC/outputs/layout.gds"
printf 'pvs -drc run control\n' > "$SRC/pvs_drc/run_base/run.pvs"
printf 'drc control\n' > "$SRC/pvs_drc/run_base/pvsdrcctl"
printf 'INFO starting\nERROR fixture failure\nordinary noise\n' \
  > "$SRC/pvs_drc/run_base/pvs_replay.stdout"
printf 'pvs -lvs run control\n' > "$SRC/pvs_lvs/run_lvs/run.pvs"
printf 'lvs control\n' > "$SRC/pvs_lvs/run_lvs/pvslvsctl"
printf 'Final comparison: MATCH\n' > "$SRC/pvs_lvs/run_lvs/PIPO1.OUT"
printf 'INFO LVS started\nPASS LVS complete\n' > "$SRC/pvs_lvs/run_lvs/PIPO1.LOG"

MPTDC_SNAPSHOT_ROOT="$SNAPSHOT_ROOT" \
MPTDC_SNAPSHOT_SOURCE_DIR="$SRC" \
MPTDC_SNAPSHOT_MAX_TEXT_BYTES=1024 \
bash "$COLLECTOR" pvs fixture_pvs > "$TMP_ROOT/collector.stdout"

test -s "$SNAPSHOT/reports/operator_gate_fixture.rpt"
test -s "$SNAPSHOT/manifests/pvs_input_hashes.rpt"
test -s "$SNAPSHOT/pvs_drc/run_base/run.pvs"
test -s "$SNAPSHOT/pvs_drc/run_base/pvsdrcctl"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/pvslvsctl"
test -s "$SNAPSHOT/pvs_drc/run_base/pvs_replay.stdout.messages.tail"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.OUT"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.OUT.messages.tail"
test -s "$SNAPSHOT/pvs_lvs/run_lvs/PIPO1.LOG.messages.tail"
test ! -e "$SNAPSHOT/reports/oversized.rpt"
test ! -e "$SNAPSHOT/outputs/layout.gds"
grep -Fq 'oversized.rpt' "$SNAPSHOT/README.md"
grep -Fq 'ERROR fixture failure' \
  "$SNAPSHOT/pvs_drc/run_base/pvs_replay.stdout.messages.tail"

set +e
MPTDC_SNAPSHOT_ROOT="$SNAPSHOT_ROOT" \
MPTDC_SNAPSHOT_SOURCE_DIR="$SRC" \
MPTDC_SNAPSHOT_MAX_TEXT_BYTES=0 \
bash "$COLLECTOR" pvs invalid_limit > "$TMP_ROOT/invalid.stdout" 2>&1
INVALID_RC=$?
set -e
test "$INVALID_RC" -eq 2

echo "PASS: collect_mptdc_server_snapshot"
