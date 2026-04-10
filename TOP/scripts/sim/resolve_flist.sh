#!/usr/bin/env bash
# =============================================================================
# SPADMIC TOP — Shared helpers for simulation scripts
# Source this file: source "$SCRIPT_DIR/resolve_flist.sh"
# =============================================================================

# resolve_flist ROOT FILELIST OUTPUT
#   Reads FILELIST, strips comments/blanks, prepends ROOT/ to each path,
#   writes the result to OUTPUT.  This makes relative-path filelists work
#   regardless of the xrun invocation directory.
resolve_flist() {
  local root="$1" flist="$2" out="$3"
  if [[ ! -f "$flist" ]]; then
    echo "ERROR: filelist not found: $flist" >&2
    return 1
  fi
  # Strip comment lines (// ...) and blank lines, prepend root
  sed -e '/^[[:space:]]*$/d' \
      -e '/^[[:space:]]*\/\//d' \
      -e "s|^[[:space:]]*|${root}/|" \
      "$flist" > "$out"
}
