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

cp "$DGDIR/AppRun" $APPDIR
cp "$DGDIR/duckgame.desktop" $APPDIR

cp "$DGDIR/icon.png" "$APPDIR/duckgamerebuilt.png"
cp "$DGDIR/icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/duckgamerebuilt.png"

chmod a+rX "$APPDIR" -R
chmod a+rx "$APPDIR/AppRun"

curl -fSL --retry 3 -o ./appimagetool.AppImage \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x ./appimagetool.AppImage

ARCH=x86_64 "./appimagetool.AppImage" "$APPDIR" ./DuckGameRebuilt.AppImage
