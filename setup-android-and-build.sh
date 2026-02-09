#!/bin/bash
# Android SDK Setup für APK-Build im Dev-Container

set -e  # Bei Fehler abbrechen

echo "🔧 Installiere Android SDK..."

# 1. Java JDK installieren (falls nicht vorhanden)
echo "📦 Prüfe Java JDK..."
if ! command -v java &> /dev/null; then
    echo "Installiere OpenJDK 17..."
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk
fi

java -version

# 2. Android Command Line Tools herunterladen
echo "📥 Lade Android SDK Command Line Tools..."
cd ~
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdtools.zip

# 3. SDK entpacken und einrichten
echo "📂 Richte SDK-Struktur ein..."
mkdir -p ~/android-sdk/cmdline-tools
unzip -q cmdtools.zip -d ~/android-sdk/cmdline-tools
mv ~/android-sdk/cmdline-tools/cmdline-tools ~/android-sdk/cmdline-tools/latest

# 4. Umgebungsvariablen setzen
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 5. SDK-Komponenten installieren
echo "⚙️ Installiere Android SDK-Komponenten..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "ndk;25.1.8937393"

# 6. Lizenzen akzeptieren
echo "📜 Akzeptiere Android SDK Lizenzen..."
yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses

# 7. Umgebungsvariablen permanent setzen
echo "💾 Setze permanente Umgebungsvariablen..."

# JAVA_HOME korrekt ermitteln
if [ -d "/usr/lib/jvm/java-17-openjdk-amd64" ]; then
    JAVA_HOME_PATH=/usr/lib/jvm/java-17-openjdk-amd64
elif [ -d "/usr/lib/jvm/java-11-openjdk-amd64" ]; then
    JAVA_HOME_PATH=/usr/lib/jvm/java-11-openjdk-amd64
else
    JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which java))))
fi

cat >> ~/.bashrc << EOF

# Android SDK
export ANDROID_HOME=~/android-sdk
export PATH=\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=\$PATH:\$ANDROID_HOME/platform-tools
export JAVA_HOME=$JAVA_HOME_PATH
EOF

# Sofort verfügbar machen
export JAVA_HOME=$JAVA_HOME_PATH
export ANDROID_HOME=~/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

# 8. local.properties für Flutter erstellen
echo "📝 Erstelle local.properties..."
cat > /workspaces/Einundzwanzig-Meetup-App/android/local.properties << EOF
sdk.dir=$HOME/android-sdk
flutter.sdk=/workspaces/Einundzwanzig-Meetup-App/flutter
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF

echo ""
echo "✅ Android SDK erfolgreich installiert!"
echo ""
echo "📱 Starte APK-Build..."
echo ""

# 9. Zurück zum Projekt-Verzeichnis
cd /workspaces/Einundzwanzig-Meetup-App

# 10. APK bauen
./flutter/bin/flutter build apk --release

echo ""
echo "🎉 APK-Build erfolgreich!"
echo ""
echo "📦 APK-Datei:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
echo ""
echo "💾 Größe: $(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)"
echo ""
echo "📲 Nächste Schritte:"
echo "  1. APK herunterladen: build/app/outputs/flutter-apk/app-release.apk"
echo "  2. Auf Smartphone übertragen"
echo "  3. Installation erlauben (Einstellungen → Sicherheit)"
echo "  4. APK öffnen und installieren"
echo ""
