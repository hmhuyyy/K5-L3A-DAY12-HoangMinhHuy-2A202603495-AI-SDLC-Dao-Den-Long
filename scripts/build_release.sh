#!/usr/bin/env bash
# build_release.sh — Packages a runnable release archive for Dao Den Long v1.0.0.
# If Godot export templates are installed, exports a standalone desktop binary;
# always creates a self-contained runnable source bundle in dist/DaoDenLong-v1.0.0-source.zip.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
mkdir -p "$DIST"

echo "[1/2] Creating clean runnable source archive via git archive..."
git -C "$ROOT" archive --format=zip --output="$DIST/DaoDenLong-v1.0.0-source.zip" HEAD
echo "Created: $DIST/DaoDenLong-v1.0.0-source.zip"

GODOT="${GODOT_BIN:-C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe}"
TEMPLATES_DIR="$HOME/AppData/Roaming/Godot/export_templates/4.7.2.stable"
if [ -d "$TEMPLATES_DIR" ]; then
  echo "[2/2] Export templates detected at $TEMPLATES_DIR — exporting Windows Desktop build..."
  "$GODOT" --headless --path "$ROOT" --export-release "Windows Desktop" "$DIST/DaoDenLong.exe"
else
  echo "[2/2] Note: Godot 4.7.2 export templates not installed at $TEMPLATES_DIR."
  echo "      The game runs directly from source with: godot --path ."
fi
