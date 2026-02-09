#!/bin/bash
# Fix-Skript für häufige APK-Build-Probleme

echo "🔧 Behebe bekannte Build-Probleme..."
echo ""

cd /workspaces/Einundzwanzig-Meetup-App

# 1. Flutter Clean
echo "1️⃣ Bereinige Flutter-Build..."
./flutter/bin/flutter clean
echo "   ✅ Flutter clean abgeschlossen"
echo ""

# 2. Gradle Cache löschen
echo "2️⃣ Lösche Gradle Cache..."
rm -rf ~/.gradle/caches
rm -rf ~/.gradle/daemon
rm -rf android/.gradle
rm -rf android/app/.gradle
echo "   ✅ Gradle Cache gelöscht"
echo ""

# 3. Korrigiere local.properties
echo "3️⃣ Aktualisiere local.properties..."
export ANDROID_HOME=${ANDROID_HOME:-$HOME/android-sdk}
cat > android/local.properties << EOF
sdk.dir=$ANDROID_HOME
flutter.sdk=/workspaces/Einundzwanzig-Meetup-App/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF
echo "   ✅ local.properties aktualisiert"
echo ""

# 4. Prüfe build.gradle.kts
echo "4️⃣ Prüfe build.gradle.kts..."
if grep -q "flutter.minSdkVersion" android/app/build.gradle.kts; then
    echo "   ⚠️  Korrigiere minSdkVersion..."
    sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 21/g' android/app/build.gradle.kts
    echo "   ✅ minSdkVersion korrigiert"
else
    echo "   ✅ build.gradle.kts ist korrekt"
fi
echo ""

# 5. Setze Umgebungsvariablen
echo "5️⃣ Setze Umgebungsvariablen..."
export ANDROID_HOME=${ANDROID_HOME:-$HOME/android-sdk}
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# JAVA_HOME korrekt setzen
if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
    export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
else
    # Automatisch finden
    export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
fi

echo "   ANDROID_HOME=$ANDROID_HOME"
echo "   JAVA_HOME=$JAVA_HOME"
echo ""

# 6. Pub get
echo "6️⃣ Aktualisiere Flutter Dependencies..."
./flutter/bin/flutter pub get
echo "   ✅ Dependencies aktualisiert"
echo ""

# 7. Starte Build
echo "7️⃣ Starte APK-Build..."
echo ""
./flutter/bin/flutter build apk --release

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 BUILD ERFOLGREICH!"
    echo ""
    echo "📦 APK-Datei:"
    ls -lh build/app/outputs/flutter-apk/app-release.apk
    echo ""
    echo "💾 Größe: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
    echo ""
else
    echo ""
    echo "❌ BUILD FEHLGESCHLAGEN"
    echo ""
    echo "📋 Führe aus für detaillierte Diagnose:"
    echo "   ./diagnose.sh"
    echo ""
fi
