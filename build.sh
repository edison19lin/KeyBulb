#!/bin/zsh
# 編譯並打包「電火按鍵.app」；加上 install 會裝到 /Applications
#   ./build.sh          只打包到 build/
#   ./build.sh install  打包並安裝
set -euo pipefail
cd "${0:A:h}"

NAME=電火按鍵
APP="build/$NAME.app"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" build/AppIcon.iconset

# 圖示
swift tools/make_icon.swift build/icon.png
for s in 16 32 128 256 512; do
    sips -z $s $s build/icon.png --out build/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
    d=$((s * 2))
    sips -z $d $d build/icon.png --out build/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns build/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

# 程式
swiftc -O -parse-as-library -target arm64-apple-macos13.0 \
    -o "$APP/Contents/MacOS/KeyBulb" Sources/*.swift

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>KeyBulb</string>
    <key>CFBundleDevelopmentRegion</key><string>zh_TW</string>
    <key>CFBundleLocalizations</key><array><string>zh_TW</string><string>en</string></array>
    <key>CFBundleIdentifier</key><string>com.air19.KeyBulbMac</string>
    <key>CFBundleName</key><string>$NAME</string>
    <key>CFBundleDisplayName</key><string>$NAME</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.00</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# 本機使用，ad-hoc 簽名即可
codesign --force --sign - "$APP"
echo "built $APP"

if [[ "${1:-}" == "install" ]]; then
    rm -rf "/Applications/$NAME.app"
    cp -R "$APP" /Applications/
    echo "installed /Applications/$NAME.app"
fi
