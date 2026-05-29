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

if npm exec --yes tauri -- --version >/dev/null 2>&1; then
  echo "[mptdc_gui] Tauri détecté, lancement du build desktop"
  npm exec --yes tauri -- build
else
  echo "[mptdc_gui] Tauri CLI non disponible."
  echo "[mptdc_gui] Installer/configurer Tauri puis relancer ce script pour produire l'application desktop."
  echo "[mptdc_gui] Le build web statique est disponible dans tools/mptdc_gui/frontend/dist."
fi
