#!/bin/bash
# Build and install the Structure Preview Quick Look extension (.pdb / .cif).
#
# Needs only the Xcode command-line tools (clang, codesign); no Xcode project.
# Builds in $TMPDIR, because codesign rejects the extended attributes that the
# Google Drive folder adds, then installs to ~/Applications and registers the
# extension with Quick Look.
#
#   ./build.sh            build + install
#   ./build.sh --no-install
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/src"
BUILD="${TMPDIR:-/tmp}/structure_preview_build"
APP="$BUILD/Structure Preview.app"
EXT="$APP/Contents/PlugIns/StructurePreviewExtension.appex"
INSTALL_DIR="$HOME/Applications"
INSTALLED="$INSTALL_DIR/Structure Preview.app"
EXT_ID="com.grix.structurepreview.extension"
TARGET="$(uname -m)-apple-macos12.0"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

rm -rf "$BUILD"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" \
         "$EXT/Contents/MacOS" "$EXT/Contents/Resources"

# viewer.html with 3Dmol inlined at the /*__3DMOL__*/ line, so a preview reads
# one file and makes no network requests.
MARK='^\/\*__3DMOL__\*\/$'
{
  sed "/$MARK/,\$d" "$SRC/viewer.html"
  cat "$SRC/Resources/3Dmol-min.js"
  sed "1,/$MARK/d" "$SRC/viewer.html"
} > "$EXT/Contents/Resources/viewer.html"
cp "$EXT/Contents/Resources/viewer.html" "$APP/Contents/Resources/viewer.html"

cp "$SRC/Extension-Info.plist" "$EXT/Contents/Info.plist"
cp "$SRC/App-Info.plist" "$APP/Contents/Info.plist"

# Objective-C rather than Swift: clang needs no Swift modules, which the
# command-line tools' SDK/compiler pairing can't always build.
CFLAGS=(-O2 -fobjc-arc -target "$TARGET" -Wall)

echo "compiling extension"
clang "${CFLAGS[@]}" -fapplication-extension \
  -Wl,-e,_NSExtensionMain -Wl,-application_extension \
  -framework Cocoa -framework Quartz -framework WebKit \
  "$SRC/PreviewViewController.m" "$SRC/ViewerPage.m" \
  -o "$EXT/Contents/MacOS/StructurePreviewExtension"

echo "compiling host app"
clang "${CFLAGS[@]}" -framework Cocoa \
  "$SRC/main.m" "$SRC/ViewerPage.m" \
  -o "$APP/Contents/MacOS/StructurePreview"

echo "signing (ad hoc)"
codesign --force --sign - --timestamp=none --entitlements "$SRC/Extension.entitlements" "$EXT"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --strict "$APP"

[[ "${1:-}" == "--no-install" ]] && { echo "built $APP"; exit 0; }

echo "installing to $INSTALLED"
pkill -f StructurePreviewExtension 2>/dev/null || true
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALLED"
ditto "$APP" "$INSTALLED"
"$LSREGISTER" -f -R -trusted "$INSTALLED"
pluginkit -a "$INSTALLED/Contents/PlugIns/StructurePreviewExtension.appex"
pluginkit -e use -i "$EXT_ID"
qlmanage -r >/dev/null 2>&1
qlmanage -r cache >/dev/null 2>&1
echo "done. Select a .pdb or .cif in Finder and press Space."
