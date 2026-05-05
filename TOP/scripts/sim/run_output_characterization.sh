#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Output/Position Characterization Runner
#
# Builds and runs tb_spadmic_output_characterization. The bench emits
# machine-readable "[CHAR] key=value" lines for presentation and datasheet
# collateral.
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROJECT_ROOT="$(cd "$TOP_ROOT/.." && pwd)"
MPTDC_ROOT="$PROJECT_ROOT/MPTDC"
BUILD_ROOT="$TOP_ROOT/build/characterization"
TB_NAME="tb_spadmic_output_characterization"
SIM="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sim) SIM="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

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
XCELIUM_DIR="$BUILD_ROOT/xcelium_${TB_NAME}_$$.d"

if [[ "$SIM" == "auto" ]]; then
  if command -v verilator >/dev/null 2>&1; then
    SIM="verilator"
  elif command -v xrun >/dev/null 2>&1; then
    SIM="xrun"
  else
    echo "ERROR: neither verilator nor xrun is available on this host" >&2
    exit 1
  fi
fi

cd "$PROJECT_ROOT"

if [[ "$SIM" == "verilator" ]]; then
  rm -rf "$MDIR"
  verilator --binary --timing "${VERILATOR_WARNINGS[@]}" \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    "$TOP_ROOT/tb/$TB_NAME.sv" \
    --top-module "$TB_NAME" \
    --Mdir "$MDIR"

  "$MDIR/V$TB_NAME" | tee "$LOG_PATH"
elif [[ "$SIM" == "xrun" ]]; then
  rm -rf "$XCELIUM_DIR"
  xrun -64 -sv -access +rwc \
    -timescale 1ps/1ps \
    -nowarn DLCVAR \
    +define+MPTDC_USE_OSC_MODEL \
    "${MPTDC_FILES[@]}" \
    "${TOP_FILES[@]}" \
    "$TOP_ROOT/tb/$TB_NAME.sv" \
    -top "$TB_NAME" \
    -xmlibdirname "$XCELIUM_DIR" \
    2>&1 | tee "$LOG_PATH"
else
  echo "ERROR: unsupported simulator '$SIM' (expected auto, verilator, or xrun)" >&2
  exit 1
fi

if ! grep -q "\\[CHAR\\] result.fail_count=0" "$LOG_PATH"; then
  echo "ERROR: characterization bench reported failures" >&2
  exit 1
fi

echo
echo "[CHAR] Simulator: $SIM"
echo "[CHAR] Log written to $LOG_PATH"
