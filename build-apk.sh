#!/bin/bash
# Schneller APK-Build (wenn Android SDK bereits installiert ist)

set -e

echo "📱 Starte APK-Build..."
echo ""

cd /workspaces/Einundzwanzig-Meetup-App

# Umgebungsvariablen setzen (falls nicht gesetzt)
export ANDROID_HOME=${ANDROID_HOME:-$HOME/android-sdk}
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# Prüfe ob Android SDK existiert
if [ ! -d "$ANDROID_HOME" ]; then
    echo "❌ Android SDK nicht gefunden unter: $ANDROID_HOME"
    echo ""
    echo "Führe zuerst das Setup aus:"
    echo "  ./setup-android-and-build.sh"
    exit 1
fi

echo "✅ Android SDK gefunden: $ANDROID_HOME"
echo ""

# Update local.properties falls nötig
cat > android/local.properties << EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=/workspaces/Einundzwanzig-Meetup-App/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF

# Clean build (optional, aber hilft bei Problemen)
echo "🧹 Bereinige alten Build..."
./flutter/bin/flutter clean

echo ""
echo "🔨 Baue APK..."
./flutter/bin/flutter build apk --release

echo ""
echo "🎉 Build erfolgreich!"
echo ""
echo "📦 APK-Datei:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""
echo "💾 Größe: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
echo ""
echo "📲 APK herunterladen und auf Smartphone installieren:"
echo "   build/app/outputs/flutter-apk/app-release.apk"
echo ""
