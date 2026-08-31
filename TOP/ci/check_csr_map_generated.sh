#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOP_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$TOP_ROOT/.." && pwd)"

cd "$REPO_ROOT"
python3 TOP/scripts/generate_csr_map.py --check
python3 -c 'from pathlib import Path; path = Path("TOP/sw/python/spadmic_csr_map.py"); compile(path.read_text(encoding="ascii"), str(path), "exec")'

if command -v cc >/dev/null 2>&1; then
  printf '%s\n' \
    '#include "TOP/sw/include/spadmic_csr.h"' \
    'int main(void) { return (int)SPADMIC_CSR_ABI_VERSION_VALUE; }' |
    cc -x c -std=c11 -Wall -Wextra -Werror -I. -fsyntax-only -
fi
