set -xeuo pipefail

DGDIR="./bin"
APPDIR="./DuckGameRebuilt.AppDir"

rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/" "$APPDIR/usr/share/metainfo" \
         "$APPDIR/usr/share/icons/hicolor/256x256/apps" \
         "$APPDIR/usr/mono" "$APPDIR/etc"

cp -r "$DGDIR" "$APPDIR/usr/"

cp -a /usr/lib/mono/4.5 "$APPDIR/usr/mono/4.5"
cp -a /usr/lib/mono/gac "$APPDIR/usr/mono/gac"
cp -a /etc/mono "$APPDIR/etc/mono"

cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
# AppRun for Duck Game Rebuilt
APPDIR="${APPDIR:-}"
if [ -z "$APPDIR" ]; then APPDIR="$(dirname "$(readlink -f "$0")")"; fi
GAME="$APPDIR/usr/bin"
MONO="$APPDIR/usr/mono"

# Writable log location — the AppImage payload is read-only when mounted.
LOGDIR="${XDG_DATA_HOME:-$HOME/.local/share}/DuckGameRebuilt"
mkdir -p "$LOGDIR" 2>/dev/null || LOGDIR="$(mktemp -d)"

# The game requires Steam to be running (Steam app id 312530).
if ! pgrep -x steam >/dev/null 2>&1 \
   && ! pgrep -x steamwebhelper >/dev/null 2>&1 \
   && ! pgrep -f com.valvesoftware.Steam >/dev/null 2>&1; then
  echo "Steam is not running - Duck Game Rebuilt needs it. Trying to start Steam..."
  if command -v steam >/dev/null 2>&1; then
    setsid steam >/dev/null 2>&1 &
  elif command -v flatpak >/dev/null 2>&1 \
       && flatpak info com.valvesoftware.Steam >/dev/null 2>&1; then
    setsid flatpak run com.valvesoftware.Steam >/dev/null 2>&1 &
  else
    echo "WARNING: Steam was not found on this system. The game will likely" >&2
    echo "         crash on startup unless you pass -nosteam (offline/lan only)." >&2
  fi
fi

cd "$GAME" || exit 1

# A) Bundled Mono runtime (default) — no system Mono needed,
#    works on immutable distros (Silverblue, SteamOS, NixOS, ...).
if [ -x "$MONO/bin/mono-sgen" ] && [ -d "$MONO/lib/mono/gac" ]; then
  export MONO_GAC_PREFIX="$MONO"
  export MONO_CFG_DIR="$MONO/etc"
  export LD_LIBRARY_PATH="$MONO/lib:$GAME${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  "$MONO/bin/mono-sgen" ./DuckGame.exe "$@" 2>&1 | tee "$LOGDIR/outputlog.txt"
  exit "${PIPESTATUS[0]}"
fi

# B) System Mono fallback.
if command -v mono >/dev/null 2>&1; then
  export LD_LIBRARY_PATH="$GAME${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  mono ./DuckGame.exe "$@" 2>&1 | tee "$LOGDIR/outputlog.txt"
  exit "${PIPESTATUS[0]}"
fi

echo "Duck Game Rebuilt needs the Mono runtime ('mono-complete')."
echo "Install it from https://www.mono-project.com/download/stable/"
echo "or via your distribution's packages, then start the AppImage again."
exit 1
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/DuckGame.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Duck Game Rebuilt
GenericName=Duck Game client
Comment=Duck Game decompiled & rebuilt with added features (requires Steam)
Exec=AppRun
Icon=$APP_ID
Terminal=false
Categories=Game;
EOF

cp "$DGDIR/icon.png" "$APPDIR/duckgamerebuilt.png"
cp "$DGDIR/icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/duckgamerebuilt.png"

chmod a+rX "$APPDIR" -R
chmod a+rx "$APPDIR/AppRun"

curl -fSL --retry 3 -o ./appimagetool.AppImage \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool.AppImage

ARCH=x86_64 "./appimagetool.AppImage" "$APPDIR" ./DuckGameRebuilt.AppImage
