#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if ! command -v pyinstaller >/dev/null 2>&1; then
  echo "pyinstaller not found on PATH. Install it in your local Python environment first." >&2
  exit 1
fi

python tools/mptdc_gui/rtl_parser.py
python tools/mptdc_gui/diagram_generator.py

pyinstaller \
  --onefile \
  --name mptdc_gui \
  --add-data "tools/mptdc_gui/architecture_db.json;tools/mptdc_gui" \
  --add-data "tools/mptdc_gui/presentation_steps.json;tools/mptdc_gui" \
  --add-data "tools/mptdc_gui/assets;tools/mptdc_gui/assets" \
  --add-data "tools/mptdc_gui/exports;tools/mptdc_gui/exports" \
  --add-data "tools/mptdc_gui/ANALYSIS_REPORT.md;tools/mptdc_gui" \
  tools/mptdc_gui/app.py

echo "Built dist/mptdc_gui"
