#!/bin/bash
# Schneller APK-Build mit korrektem JAVA_HOME

echo "🚀 Schneller APK-Build..."
echo ""

cd /workspaces/Einundzwanzig-Meetup-App

# 1. JAVA_HOME korrekt setzen
echo "1️⃣ Setze JAVA_HOME..."
if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
    echo "   ✅ JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64"
elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
    echo "   ✅ JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
else
    # Automatisch finden
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
    echo "   ✅ JAVA_HOME=$JAVA_HOME"
fi
echo ""

# 2. ANDROID_HOME setzen
echo "2️⃣ Setze ANDROID_HOME..."
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
echo "   ✅ ANDROID_HOME=$ANDROID_HOME"
echo ""

# 3. Prüfe Versionen
echo "3️⃣ Prüfe Installationen..."
echo "   Java:"
java -version 2>&1 | head -1
echo "   Flutter:"
./flutter/bin/flutter --version | head -1
echo ""

# 4. Build
echo "4️⃣ Baue APK..."
echo ""
./flutter/bin/flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 BUILD ERFOLGREICH!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 APK-Datei:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "💾 Größe: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
    echo ""
    echo "📲 Installation auf Smartphone:"
    echo "   1. APK herunterladen von:"
    echo "      build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "   2. Auf Smartphone kopieren (USB/E-Mail/Cloud)"
    echo ""
    echo "   3. Datei-Manager öffnen → APK antippen → Installieren"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo ""
    echo "❌ BUILD FEHLGESCHLAGEN"
    echo ""
    echo "🔍 Führe Diagnose aus:"
    echo "   ./diagnose.sh"
    echo ""
    exit 1
fi
