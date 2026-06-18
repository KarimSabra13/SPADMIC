#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Compatibility alias for existing automation.
bash "$SCRIPT_DIR/run_genus_axis_core_typical_closed.sh" "$@"
