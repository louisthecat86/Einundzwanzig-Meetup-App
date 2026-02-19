# 🚀 Schnellstart: APK auf deinem Smartphone

## ✅ **Schritt 1: Android SDK installieren + APK bauen**

Führe **einmalig** aus:

```bash
cd /workspaces/Einundzwanzig-Meetup-App
chmod +x setup-android-and-build.sh
./setup-android-and-build.sh
```

⏱️ **Dauert ca. 10-15 Minuten** (Downloads + Build)

---

## 📱 **Schritt 2: APK auf Smartphone installieren**

### **Option A: USB-Kabel** (für Entwickler)

```bash
# 1. USB-Debugging aktivieren auf Smartphone:
#    Einstellungen → Über das Telefon → 7x auf "Build-Nummer"
#    → Entwickleroptionen → USB-Debugging AN

# 2. Smartphone verbinden

# 3. APK installieren
~/android-sdk/platform-tools/adb install build/app/outputs/flutter-apk/app-release.apk
```

### **Option B: Manueller Download** (EINFACHER!)

1. **APK herunterladen** von:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```

2. **APK auf Smartphone kopieren** (USB, E-Mail, Cloud, WhatsApp)

3. **Auf Smartphone:**
   - Datei-Manager öffnen
   - APK-Datei antippen
   - "Aus dieser Quelle installieren" erlauben
   - INSTALLIEREN klicken

4. **App öffnen** ✅

---

## 🔄 **APK neu bauen** (bei Code-Änderungen)

Falls SDK bereits installiert ist:

```bash
chmod +x build-apk.sh
./build-apk.sh
```

⏱️ **Dauert ca. 2-3 Minuten**

---

## ✅ **Was du testen kannst:**

### Als **Admin**:
1. App öffnen → Profil erstellen
2. "Admin werden" → Passwort:
3. **ADMIN**-Kachel erscheint ✅
4. **NFC Tag beschreiben** (braucht NFC-Karten von Amazon)

### Als **User**:
1. Profil erstellen
2. Home-Meetup wählen
3. **BADGES** → NFC scannen
4. **Badge Wallet** ansehen
5. **Share** → Reputation teilen

---

## 🆘 **Bei Problemen:**

### Problem: "Gradle build failed"

```bash
# Lösung 1: Clean Build
./flutter/bin/flutter clean
./build-apk.sh

# Lösung 2: Gradle Cache löschen
rm -rf ~/.gradle/caches
./build-apk.sh
```

### Problem: "SDK not found"

```bash
# Prüfe ob SDK installiert ist
ls -la ~/android-sdk

# Falls nicht, führe Setup nochmal aus
./setup-android-and-build.sh
```

### Problem: "Installation blocked"

Auf Smartphone:
1. **Einstellungen** → **Sicherheit**
2. **Unbekannte Quellen** aktivieren
3. Oder: **Diese Quelle erlauben** (bei neueren Androids)

### Problem: App crashed beim Start

```bash
# Logs ansehen (wenn per USB verbunden)
~/android-sdk/platform-tools/adb logcat | grep -i flutter
```

---

## 📦 **NFC-Karten kaufen** (für echte Tests)

Für Badge-Sammlung brauchst du NFC-Tags:

- **Amazon**: "NFC Tags NTAG215" (ca. 15€ für 30 Stück)
- **Empfehlung**: NTAG215 oder NTAG216 (größerer Speicher)
- **Mindestens**: 10 Stück für Tests

---

## 🎯 **Nächste Schritte:**

1. ✅ APK installiert
2. ✅ Als Admin einloggen
3. ✅ NFC-Karten kaufen
4. ✅ Badge-Tag beschreiben
5. ✅ Mit zweitem Account Badge sammeln
6. ✅ Reputation teilen testen

**Viel Erfolg! 🚀**
