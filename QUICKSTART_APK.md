# Schnellstart: APK auf deinem Smartphone

## Schritt 1: Android SDK installieren + APK bauen

Führe **einmalig** aus:

```bash
cd /workspaces/Einundzwanzig-Meetup-App
chmod +x setup-android-and-build.sh
./setup-android-and-build.sh
```

Dauert ca. 10-15 Minuten (Downloads + Build).

---

## Schritt 2: APK auf Smartphone installieren

### Option A: USB-Kabel (für Entwickler)

```bash
# 1. USB-Debugging aktivieren auf Smartphone:
#    Einstellungen → Über das Telefon → 7x auf "Build-Nummer"
#    → Entwickleroptionen → USB-Debugging AN

# 2. Smartphone verbinden

# 3. APK installieren
~/android-sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option B: Manueller Download

1. APK-Datei kopieren: `build/app/outputs/flutter-apk/app-release.apk`
2. Auf Smartphone übertragen (USB, E-Mail, Cloud, Messenger)
3. Auf Smartphone:
   - Datei-Manager öffnen
   - APK-Datei antippen
   - "Aus dieser Quelle installieren" erlauben
   - INSTALLIEREN klicken
4. App öffnen

---

## APK neu bauen (bei Code-Änderungen)

Falls SDK bereits installiert ist:

```bash
chmod +x build-apk.sh
./build-apk.sh
```

Dauert ca. 2-3 Minuten.

---

## Was du testen kannst

### Als Organisator (Admin):

Der Admin-Status wird **automatisch** über den Trust Score vergeben.
Alternativ kann ein bestehender Admin dich über die Admin-Registry als Seed-Admin aufnehmen.

1. App öffnen, Profil erstellen
2. Badges sammeln (verschiedene Meetups, verschiedene Organisatoren)
3. Sobald Trust-Score-Schwellenwert erreicht → Admin-Kachel erscheint
4. NFC-Tags beschreiben oder Rolling-QR starten

### Als User:

1. Profil erstellen
2. Home-Meetup wählen
3. BADGES → NFC scannen oder QR scannen
4. Badge Wallet ansehen
5. Reputation teilen (QR, Nostr, Text)

---

## Bei Problemen

### Problem: "Gradle build failed"

```bash
# Lösung 1: Clean Build
flutter clean && ./build-apk.sh

# Lösung 2: Gradle Cache löschen
rm -rf ~/.gradle/caches && ./build-apk.sh
```

### Problem: "SDK not found"

```bash
ls -la ~/android-sdk
# Falls nicht vorhanden:
./setup-android-and-build.sh
```

### Problem: "Installation blocked"

Auf Smartphone:
1. Einstellungen → Sicherheit
2. Unbekannte Quellen aktivieren (oder: Diese Quelle erlauben)

### Problem: App crashed beim Start

```bash
~/android-sdk/platform-tools/adb logcat | grep -i flutter
```

---

## NFC-Karten kaufen (für echte Tests)

- **NTAG215** (empfohlen, 492 Bytes, reicht für Kompakt-Payload)
- Amazon: "NFC Tags NTAG215" — ca. 15 EUR für 30 Stück
- Alternativ: NTAG216 (größerer Speicher)

---

## Nächste Schritte

1. APK installiert
2. Profil erstellt, Nostr-Key generiert
3. Home-Meetup gewählt
4. Badges gesammelt
5. Trust Score aufgebaut
6. Reputation geteilt und verifiziert
