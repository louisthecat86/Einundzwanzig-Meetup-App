# Android APK Build-Anleitung

Diese Anleitung zeigt dir Schritt-für-Schritt, wie du die Einundzwanzig Meetup App als APK baust und auf deinem Android-Handy installierst.

## Voraussetzungen

### 1. Flutter SDK
Flutter wird für den Build benötigt. Installationsanweisungen: https://flutter.dev/docs/get-started/install

### 2. Android SDK
Falls noch nicht installiert:
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install android-sdk

# Oder Android Studio installieren (empfohlen)
# Download: https://developer.android.com/studio
```

### 3. Java Development Kit (JDK)
```bash
# Prüfen ob installiert
java -version

# Falls nicht installiert (Ubuntu/Debian)
sudo apt-get install openjdk-17-jdk
```

---

## Schritt 1: Dependencies installieren

```bash
# Im Projekt-Verzeichnis
cd /workspaces/Einundzwanzig-Meetup-App

# Flutter Dependencies installieren
./flutter/bin/flutter pub get
```

Erwartete Ausgabe:
```
Running "flutter pub get" in Einundzwanzig-Meetup-App...
Resolving dependencies...
+ cupertino_icons 1.0.8
+ http 1.6.0
+ nfc_manager 4.1.1
+ shared_preferences 2.5.4
+ crypto 3.0.6
+ share_plus 10.1.4
+ qr_flutter 4.1.0
...
Changed 45 dependencies!
```

---

## Schritt 2: APK bauen

### Option A: Release APK (empfohlen für Handy)

```bash
./flutter/bin/flutter build apk --release
```

**Build dauert ca. 2-5 Minuten**

Erwartete Ausgabe:
```
Building with sound null safety
Running Gradle task 'assembleRelease'...
✓ Built build/app/outputs/flutter-apk/app-release.apk (18.5MB)
```

### Option B: Debug APK (für Entwicklung)

```bash
./flutter/bin/flutter build apk --debug
```

Schneller, aber größere Datei + Debug-Informationen.

---

## Schritt 3: APK auf Handy installieren

### Methode 1: USB-Kabel (adb)

```bash
# 1. USB-Debugging auf Handy aktivieren:
#    Einstellungen → Über das Telefon → 7x auf "Build-Nummer" tippen
#    → Entwickleroptionen → USB-Debugging aktivieren

# 2. Handy per USB verbinden

# 3. Prüfen ob Gerät erkannt wird
adb devices

# Sollte zeigen:
# List of devices attached
# ABC123XYZ   device

# 4. APK installieren
adb install build/app/outputs/flutter-apk/app-release.apk

# Bei Fehlern (bereits installiert):
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Methode 2: Direkter Download (über Web)

```bash
# 1. APK auf Webserver kopieren
cp build/app/outputs/flutter-apk/app-release.apk ~/public_html/einundzwanzig.apk

# 2. Auf Handy Browser öffnen und herunterladen
# Beispiel: http://your-server.com/einundzwanzig.apk

# 3. Installation erlauben:
#    Einstellungen → Sicherheit → "Unbekannte Quellen" aktivieren
#    (oder bei neueren Androids: pro App erlauben)

# 4. Datei öffnen → Installieren
```

### Methode 3: Google Drive / Dropbox

```bash
# 1. APK zu Google Drive hochladen

# 2. Auf Handy: Drive-App öffnen → APK herunterladen

# 3. Installieren (wie bei Methode 2)
```

---

## Schritt 4: App testen

Nach Installation öffne die App:

### Test-Checkliste:

#### Basis-Funktionen
- [ ] App öffnet ohne Crash
- [ ] Intro-Screen wird angezeigt
- [ ] Profil erstellen (Nickname eingeben)
- [ ] Dashboard lädt

#### NFC-Funktionen (benötigt NFC-Handy)
- [ ] "BADGES" Kachel öffnen
- [ ] NFC-Scanner aktiviert sich
- [ ] NFC-Karte wird erkannt

#### Admin-Funktionen
Der Admin-Status wird automatisch über den Trust Score vergeben
(oder über Seed-Admin-Eintrag in der Admin-Registry).
- [ ] Badges sammeln (verschiedene Meetups + Organisatoren)
- [ ] Trust Score erreicht Promotion-Schwellenwert
- [ ] Admin-Kachel erscheint auf Dashboard
- [ ] "NFC Tag beschreiben" öffnet sich
- [ ] NFC-Tag kann beschrieben werden

#### Badge-Sammlung
- [ ] Badge-Wallet öffnen
- [ ] Share-Button funktioniert
- [ ] QR-Code wird angezeigt
- [ ] Text wird in Zwischenablage kopiert

#### Daten-Persistenz
- [ ] App schließen
- [ ] App neu öffnen
- [ ] Bist du noch eingeloggt?
- [ ] Badges noch vorhanden?

---

## Fehlersuche

### Problem: "flutter: command not found"

```bash
# Absoluten Pfad verwenden
/workspaces/Einundzwanzig-Meetup-App/flutter/bin/flutter --version

# Oder zu PATH hinzufügen
export PATH="$PATH:/workspaces/Einundzwanzig-Meetup-App/flutter/bin"
```

### Problem: "Gradle build failed"

```bash
# Android Licenses akzeptieren
./flutter/bin/flutter doctor --android-licenses

# Drücke y für alle Lizenzen
```

### Problem: "SDK location not found"

Erstelle/Bearbeite: `android/local.properties`
```properties
sdk.dir=/home/USERNAME/Android/Sdk
```

Ersetze mit deinem echten Android SDK Pfad:
```bash
# Finde SDK Pfad
~/Android/Sdk  # Standard bei Android Studio
```

### Problem: APK-Installation schlägt fehl

```bash
# App vorher deinstallieren
adb uninstall com.example.einundzwanzig_meetup_app

# Dann neu installieren
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Problem: App crashed beim Öffnen

```bash
# Logs ansehen
adb logcat | grep Flutter

# Oder in Android Studio: Logcat öffnen
```

---

## Build-Optimierungen

### Kleinere APK-Größe

```bash
# Split APKs nach Architektur
./flutter/bin/flutter build apk --split-per-abi

# Erstellt 3 APKs:
# - app-armeabi-v7a-release.apk  (32-bit ARM)
# - app-arm64-v8a-release.apk    (64-bit ARM)
# - app-x86_64-release.apk       (64-bit x86)

# Installiere nur die für dein Handy passende
```

### Obfuscation (Code-Verschleierung)

```bash
./flutter/bin/flutter build apk --obfuscate --split-debug-info=build/debug-info
```

---

## Nächste Schritte nach Installation

### 1. Profil + Nostr-Key
1. App öffnen
2. Profil erstellen (Nickname)
3. Nostr-Key wird automatisch generiert (oder bestehenden nsec importieren)
4. Home-Meetup wählen

### 2. Badges sammeln
1. Dashboard → BADGES
2. NFC-Tag oder Rolling-QR eines Organisators scannen
3. Badge erscheint im Wallet
4. Claim-Binding wird automatisch erstellt

### 3. Admin werden (kryptographisch)
Der Admin-Status wird **automatisch** vergeben, sobald der Trust Score
den Promotion-Schwellenwert erreicht (abhängig von der Bootstrap-Phase).
Alternativ: Aufnahme als Seed-Admin durch bestehenden Admin.

### 4. NFC-Tags beschreiben (als Admin)
- Benötigt: NFC-fähiges Android-Handy + NTAG215 Tags
- Dashboard → ADMIN → Session starten → "NFC Tag beschreiben"
- Halte NFC-Karte an Handy-Rückseite

### 5. Reputation teilen
1. Dashboard → Reputation-QR
2. QR vorzeigen oder als Nostr-Event publizieren
3. Gegenüber scannt und verifiziert

---

## Signierte APK (für Play Store)

Falls du die App später im Play Store veröffentlichen möchtest:

```bash
# 1. Keystore erstellen
keytool -genkey -v -keystore ~/einundzwanzig-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias einundzwanzig

# 2. android/key.properties erstellen
storePassword=DEIN_PASSWORD
keyPassword=DEIN_PASSWORD
keyAlias=einundzwanzig
storeFile=/home/user/einundzwanzig-key.jks

# 3. Signierte APK bauen
./flutter/bin/flutter build apk --release
```

---

## Hilfe & Support

Bei Problemen:

1. **Flutter Doctor ausführen**:
   ```bash
   ./flutter/bin/flutter doctor -v
   ```

2. **GitHub Issue öffnen**:
   https://github.com/louisthecat86/Einundzwanzig-Meetup-App/issues

3. **Logs sammeln**:
   ```bash
   ./flutter/bin/flutter build apk --release -v > build.log 2>&1
   ```

---

## Erfolg!

Wenn die APK läuft:
- Du hast eine voll funktionsfähige Android-App
- Du kannst Badges sammeln und Reputation aufbauen
- Du kannst NFC-Tags und Rolling-QRs als Admin erstellen
- Du kannst Reputation teilen und verifizieren
- Du kannst verschlüsselte Backups erstellen und wiederherstellen
