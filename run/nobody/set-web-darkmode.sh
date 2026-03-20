#!/usr/bin/env bash
set -euo pipefail

# Set WEB_DARKMODE=true to enable, anything else disables
ENABLE="${WEB_DARKMODE:-false}"

GRID_FILE="/opt/fs25/game/Farming Simulator 2025/web_data/css/grid.css"
MAIN_FILE="/opt/fs25/game/Farming Simulator 2025/web_data/css/main.css"

GRID_IMPORT='@import url("https://cdn.jsdelivr.net/gh/yellowfromseegg/FS25-Webinterface-DarkMode@main/dark-theme-grid.css");'
MAIN_IMPORT='@import url("https://cdn.jsdelivr.net/gh/yellowfromseegg/FS25-Webinterface-DarkMode@main/dark-theme-main.css");'

# Markers to remove exactly what we added
GRID_BEGIN='/* WEB_DARKMODE_BEGIN grid */'
GRID_END='/* WEB_DARKMODE_END grid */'
MAIN_BEGIN='/* WEB_DARKMODE_BEGIN main */'
MAIN_END='/* WEB_DARKMODE_END main */'

is_true() {
  case "${1,,}" in
    1|true|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

add_block() {
  local file="$1" begin="$2" line="$3" end="$4"
  if grep -qF "$begin" "$file"; then
    echo "Already patched: $file"
    return 0
  fi
  tmp="$(mktemp)"
  {
    echo "$begin"
    echo "$line"
    echo "$end"
    cat "$file"
  } > "$tmp"
  cat "$tmp" > "$file"
  rm -f "$tmp"
  echo "Patched: $file"
}

remove_block() {
  local file="$1" begin="$2" end="$3"

  if ! grep -qF "$begin" "$file"; then
    echo "Nothing to remove: $file"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"

  awk -v b="$begin" -v e="$end" '
    { line=$0; sub(/\r$/, "", line) }   # tolerate CRLF files
    line==b { skipping=1; next }
    line==e { skipping=0; next }
    !skipping { print $0 }
  ' "$file" > "$tmp"

  cat "$tmp" > "$file"
  rm -f "$tmp"

  echo "darkmode added to: $file"
}


# Basic sanity
[[ -f "$GRID_FILE" ]] || { echo "Missing $GRID_FILE"; exit 1; }
[[ -f "$MAIN_FILE" ]] || { echo "Missing $MAIN_FILE"; exit 1; }

if is_true "$ENABLE"; then
  add_block "$GRID_FILE" "$GRID_BEGIN" "$GRID_IMPORT" "$GRID_END"
  add_block "$MAIN_FILE" "$MAIN_BEGIN" "$MAIN_IMPORT" "$MAIN_END"
else
  remove_block "$GRID_FILE" "$GRID_BEGIN" "$GRID_END"
  remove_block "$MAIN_FILE" "$MAIN_BEGIN" "$MAIN_END"
fi
