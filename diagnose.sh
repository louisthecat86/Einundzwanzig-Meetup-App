#!/bin/bash
# Diagnose-Skript für APK-Build-Probleme

echo "🔍 DIAGNOSE: Android APK Build"
echo "================================"
echo ""

cd /workspaces/Einundzwanzig-Meetup-App

# 1. Prüfe Android SDK
echo "1️⃣ Prüfe Android SDK..."
if [ -d "$HOME/android-sdk" ]; then
    echo "   ✅ SDK gefunden: $HOME/android-sdk"
    export ANDROID_HOME=$HOME/android-sdk
else
    echo "   ❌ SDK NICHT gefunden unter $HOME/android-sdk"
    echo "   → Führe aus: ./setup-android-and-build.sh"
    exit 1
fi
echo ""

# 2. Prüfe Java
echo "2️⃣ Prüfe Java JDK..."
if command -v java &> /dev/null; then
    java -version 2>&1 | head -1
    echo "   ✅ Java installiert"
else
    echo "   ❌ Java NICHT installiert"
    echo "   → Installiere: sudo apt-get install openjdk-17-jdk"
    exit 1
fi
echo ""

# 3. Prüfe Flutter
echo "3️⃣ Prüfe Flutter..."
if [ -f "./flutter/bin/flutter" ]; then
    echo "   ✅ Flutter gefunden"
    ./flutter/bin/flutter --version | head -1
else
    echo "   ❌ Flutter NICHT gefunden"
    exit 1
fi
echo ""

# 4. Prüfe local.properties
echo "4️⃣ Prüfe android/local.properties..."
if [ -f "android/local.properties" ]; then
    echo "   ✅ Datei existiert"
    echo "   Inhalt:"
    cat android/local.properties | sed 's/^/   /'
else
    echo "   ❌ Datei fehlt"
    echo "   → Erstelle Datei..."
    cat > android/local.properties << EOF
sdk.dir=$HOME/android-sdk
flutter.sdk=/workspaces/Einundzwanzig-Meetup-App/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF
    echo "   ✅ Datei erstellt"
fi
echo ""

# 5. Prüfe SDK-Komponenten
echo "5️⃣ Prüfe installierte SDK-Komponenten..."
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

if [ -f "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo "   Installierte Pakete:"
    $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --list_installed --sdk_root=$ANDROID_HOME 2>/dev/null | grep -E "platforms|build-tools|platform-tools" | sed 's/^/   /'
else
    echo "   ⚠️  sdkmanager nicht gefunden"
fi
echo ""

# 6. Test-Build mit detaillierter Ausgabe
echo "6️⃣ Starte Test-Build (mit verbose)..."
echo "   Dies kann 1-2 Minuten dauern..."
echo ""

export PATH=$PATH:$ANDROID_HOME/platform-tools

./flutter/bin/flutter clean
./flutter/bin/flutter build apk --release --verbose 2>&1 | tee build-log.txt

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 BUILD ERFOLGREICH!"
    echo ""
    echo "📦 APK-Datei:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
else
    echo ""
    echo "❌ BUILD FEHLGESCHLAGEN"
    echo ""
    echo "📋 Letzte 50 Zeilen des Logs:"
    tail -50 build-log.txt
    echo ""
    echo "📄 Vollständiges Log: build-log.txt"
    echo ""
    echo "🔧 Häufige Probleme:"
    echo "   1. Gradle Cache löschen: rm -rf ~/.gradle/caches"
    echo "   2. Android SDK neu installieren: ./setup-android-and-build.sh"
    echo "   3. Build-Ordner löschen: ./flutter/bin/flutter clean"
    echo ""
fi
