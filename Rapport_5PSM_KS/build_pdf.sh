#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORT_DIR="$SCRIPT_DIR"
MAIN_TEX="$REPORT_DIR/main.tex"
BUILD_DIR="$REPORT_DIR/build"
DIST_DIR="$REPORT_DIR/dist"
MAIN_NAME="main"
FINAL_PDF="$DIST_DIR/rapport_5psm.pdf"
LOG_FILE="$BUILD_DIR/${MAIN_NAME}.log"

AUTO_INSTALL=1
OPEN_PDF=0
CLEAN_ONLY=0

usage() {
  cat <<'EOF'
Usage: ./build_pdf.sh [options]

Options:
  --no-install   Do not try to install missing LaTeX dependencies
  --open         Open the generated PDF after a successful build
  --clean        Remove build and dist directories, then exit
  -h, --help     Show this help

Behavior:
  - checks required tools and LaTeX packages
  - installs missing dependencies on Debian/Ubuntu via sudo apt-get
  - compiles the report with pdflatex + biber + pdflatex + pdflatex
  - writes intermediate files to ./build/
  - copies the final PDF to ./dist/rapport_5psm.pdf
EOF
}

while (($#)); do
  case "$1" in
    --no-install)
      AUTO_INSTALL=0
      ;;
    --open)
      OPEN_PDF=1
      ;;
    --clean)
      CLEAN_ONLY=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ ! -f "$MAIN_TEX" ]]; then
  echo "Error: main.tex not found in $REPORT_DIR" >&2
  exit 1
fi

if (( CLEAN_ONLY )); then
  rm -rf "$BUILD_DIR" "$DIST_DIR"
  echo "Removed $BUILD_DIR and $DIST_DIR"
  exit 0
fi

mkdir -p "$BUILD_DIR" "$DIST_DIR"

trap 'status=$?; echo; echo "Build failed."; [[ -f "$LOG_FILE" ]] && { echo "Log: $LOG_FILE"; echo "--- Last log lines ---"; tail -n 40 "$LOG_FILE"; }; exit $status' ERR

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

have_tex_file() {
  kpsewhich "$1" >/dev/null 2>&1
}

declare -A REQUIRED_APT_PACKAGES=()

require_cmd() {
  local cmd="$1"
  local apt_pkg="$2"
  if ! have_cmd "$cmd"; then
    REQUIRED_APT_PACKAGES["$apt_pkg"]=1
  fi
}

require_tex_file() {
  local tex_file="$1"
  local apt_pkg="$2"
  if ! have_tex_file "$tex_file"; then
    REQUIRED_APT_PACKAGES["$apt_pkg"]=1
  fi
}

require_cmd pdflatex texlive-latex-base
require_cmd biber biber
require_tex_file french.ldf texlive-lang-french
require_tex_file biblatex.sty texlive-bibtex-extra
require_tex_file ieee.bbx texlive-bibtex-extra
require_tex_file siunitx.sty texlive-science

if (( ${#REQUIRED_APT_PACKAGES[@]} > 0 )); then
  mapfile -t MISSING_PACKAGES < <(printf '%s\n' "${!REQUIRED_APT_PACKAGES[@]}" | sort)
  echo "Missing LaTeX dependencies detected:"
  printf '  - %s\n' "${MISSING_PACKAGES[@]}"

  if (( AUTO_INSTALL )); then
    if ! have_cmd sudo || ! have_cmd apt-get; then
      echo
      echo "Cannot auto-install dependencies because sudo or apt-get is unavailable." >&2
      echo "Please install manually, then rerun this script." >&2
      exit 1
    fi

    echo
    echo "Installing missing packages with sudo apt-get..."
    sudo apt-get update
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
  else
    echo
    echo "Install them manually with:"
    echo "  sudo apt-get update && sudo apt-get install -y ${MISSING_PACKAGES[*]}"
    exit 1
  fi
fi

echo "Starting LaTeX build..."

PDFLATEX_FLAGS=(
  -interaction=nonstopmode
  -file-line-error
  -halt-on-error
  -synctex=1
  -output-directory="$BUILD_DIR"
)

cd "$REPORT_DIR"

pdflatex "${PDFLATEX_FLAGS[@]}" "$MAIN_TEX"
biber --input-directory "$BUILD_DIR" --output-directory "$BUILD_DIR" "$MAIN_NAME"
pdflatex "${PDFLATEX_FLAGS[@]}" "$MAIN_TEX"
pdflatex "${PDFLATEX_FLAGS[@]}" "$MAIN_TEX"

install -m 644 "$BUILD_DIR/${MAIN_NAME}.pdf" "$FINAL_PDF"

echo
echo "Build succeeded."
echo "PDF : $FINAL_PDF"
echo "Log : $LOG_FILE"

if (( OPEN_PDF )); then
  if have_cmd xdg-open; then
    xdg-open "$FINAL_PDF" >/dev/null 2>&1 &
  else
    echo "xdg-open not found; PDF was not opened automatically."
  fi
fi
