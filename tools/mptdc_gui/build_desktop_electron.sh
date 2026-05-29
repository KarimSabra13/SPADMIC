#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRONTEND_DIR="$ROOT_DIR/tools/mptdc_gui/frontend"

echo "[mptdc_gui] Régénération architecture_db.json"
python "$ROOT_DIR/tools/mptdc_gui/rtl_parser.py" --validate-ports

echo "[mptdc_gui] Build web React/Vite"
cd "$FRONTEND_DIR"
npm install
npm run build

if npm exec --yes electron -- --version >/dev/null 2>&1; then
  echo "[mptdc_gui] Electron est disponible."
  echo "[mptdc_gui] Ajouter un main Electron ou electron-builder pour empaqueter frontend/dist."
else
  echo "[mptdc_gui] Electron non disponible."
  echo "[mptdc_gui] Le build web statique est prêt dans tools/mptdc_gui/frontend/dist."
fi
