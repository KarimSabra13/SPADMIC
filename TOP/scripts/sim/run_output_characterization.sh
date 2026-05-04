#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Output/Position Characterization Runner
#
# Builds and runs tb_spadmic_output_characterization with Verilator. The bench
# emits machine-readable "[CHAR] key=value" lines for presentation and datasheet
# collateral.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$PROJECT_ROOT/MPTDC"
BUILD_ROOT="$TOP_ROOT/build/characterization"
TB_NAME="tb_spadmic_output_characterization"

mkdir -p "$BUILD_ROOT"

read_flist() {
  local root="$1"
  local flist="$2"
  sed -e 's,//.*$,,' -e '/^[[:space:]]*$/d' "$flist" | sed "s#^#$root/#"
}

mapfile -t MPTDC_FILES < <(read_flist "$MPTDC_ROOT" "$MPTDC_ROOT/rtl/filelist.f")
mapfile -t TOP_FILES   < <(read_flist "$TOP_ROOT"   "$TOP_ROOT/filelist.f")

VERILATOR_WARNINGS=(
  -Wall
  -Wno-fatal
  -Wno-UNUSEDSIGNAL
  -Wno-UNDRIVEN
  -Wno-DECLFILENAME
  -Wno-WIDTHEXPAND
  -Wno-WIDTHTRUNC
  -Wno-UNUSEDPARAM
  -Wno-PINMISSING
  -Wno-UNUSEDGENVAR
  -Wno-CASEINCOMPLETE
  -Wno-LATCH
  -Wno-REALCVT
  -Wno-INITIALDLY
  -Wno-COMBDLY
  -Wno-PINCONNECTEMPTY
  -Wno-SYNCASYNCNET
  -Wno-UNOPTFLAT
)

MDIR="$BUILD_ROOT/obj_$TB_NAME"
LOG_PATH="$BUILD_ROOT/$TB_NAME.log"

rm -rf "$MDIR"
cd "$PROJECT_ROOT"

verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
  +define+MPTDC_USE_OSC_MODEL \
  "${MPTDC_FILES[@]}" \
  "${TOP_FILES[@]}" \
  "$TOP_ROOT/tb/$TB_NAME.sv" \
  --top-module "$TB_NAME" \
  --Mdir "$MDIR"

"$MDIR/V$TB_NAME" | tee "$LOG_PATH"

echo
echo "[CHAR] Log written to $LOG_PATH"
