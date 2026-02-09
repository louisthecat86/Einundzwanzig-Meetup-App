# 🏆 Einundzwanzig Meetup App

**Die dezentrale Reputations-App für die Bitcoin-Community**

Eine Flutter-basierte Cross-Platform App (Web, Android, iOS) zum Sammeln von Meetup-Badges via NFC und Aufbau einer verifizierbaren Reputation.

![Version](https://img.shields.io/badge/version-1.0.0-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.38.9-blue)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Inhaltsverzeichnis

- [Überblick](#überblick)
- [Features](#features)
- [Wie funktioniert es?](#wie-funktioniert-es)
- [Installation](#installation)
- [App bauen](#app-bauen)
- [Benutzung](#benutzung)
- [Badge-Verifizierung](#badge-verifizierung)
- [Architektur](#architektur)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

---

## 🎯 Überblick

Die **Einundzwanzig Meetup App** löst das Problem der fehlenden Reputation in der dezentralen Bitcoin-Community. Sie ermöglicht es Nutzern:

- **Badges zu sammeln** durch physische Teilnahme an Meetups (via NFC)
- **Reputation aufzubauen** als Nachweis der Community-Aktivität
- **Vertrauen zu schaffen** bei P2P-Trades (z.B. auf satoshikleinanzeigen.space)
- **Identitäten zu verifizieren** ohne KYC oder zentrale Instanzen

### Warum ist das wichtig?

Bei dezentralen Plattformen wie **satoshikleinanzeigen.space** fehlt oft das Vertrauen:
- ❌ Kein Bewertungssystem wie bei eBay
- ❌ Keine zentrale Instanz zur Identitätsprüfung
- ❌ Schwer zu erkennen, wer seriös ist

**Mit dieser App:**
- ✅ Zeige, dass du bei 5+ Meetups warst
- ✅ Beweise deine Community-Aktivität
- ✅ Baue Vertrauen durch physische Meetup-Teilnahme auf
- ✅ Alles lokal gespeichert, keine zentrale Datenbank

---

## ✨ Features

### 🎫 Badge System
- **NFC-basiert**: Scanne NFC-Tags bei Meetups
- **Blockchain-Zeitstempel**: Jedes Badge mit Bitcoin-Blockhöhe
- **Lokal gespeichert**: Deine Daten bleiben auf deinem Gerät
- **Verifizierbar**: Hash-basierte Integritätsprüfung

### 👥 Zwei User-Flows

#### User-Flow (Badge-Sammler):
1. Erstelle dein Profil (Nickname, optional Nostr npub)
2. Wähle dein Home-Meetup
3. Scanne NFC-Tags bei Meetups → Erhalte Badges
4. Teile deine Reputation (QR-Code, JSON, Social Media)

#### Admin-Flow (Meetup-Organisator):
1. Logge dich als Admin ein (Passwort: `#21AdminTag21#`)
2. Erstelle NFC-Tags für dein Meetup
3. Verifiziere Teilnehmer-Identitäten
4. Verwalte dein Meetup

### 📱 Plattformen
- **Web**: PWA, läuft im Browser
- **Android**: Native App mit echtem NFC
- **iOS**: Native App mit echtem NFC

### 🔐 Sicherheit & Datenschutz
- Keine Cloud, alles lokal (SharedPreferences/localStorage)
- Optional: Nostr-Integration für dezentrale Identität
- Pseudonym: Nur Nickname + npub, kein Realname erforderlich
- Session-Persistenz: Bleibe eingeloggt auch nach Wochen

### 🌐 Live-Daten
- Integration mit [portal.einundzwanzig.space](https://portal.einundzwanzig.space)
- Echtzeit-Meetup-Daten (Standorte, Links, Events)
- Aktuelle Bitcoin-Blockhöhe (Mempool.space API)

### 📊 Reputation teilen
- **QR-Code**: Zeige deine Badges als scannbaren Code
- **Text**: Teile auf Social Media
- **JSON**: Export mit Checksumme zur Verifizierung
- **Badge-Verifier**: Standalone-Tool zur Überprüfung

---

## 🔧 Wie funktioniert es?

### Badge-Sammlung

```
1. Admin erstellt NFC-Tag:
   Tag enthält: Meetup-Name, Datum, ID
   
2. User scannt Tag:
   App liest Daten + holt aktuelle Blockhöhe
   
3. Badge wird erstellt:
   {
     "meetup": "München",
     "date": "2026-01-15",
     "block": 875432,
     "hash": "a3f9b2c1e5d4f8a2"
   }
   
4. Badge wird lokal gespeichert:
   SharedPreferences (Mobile) / localStorage (Web)
```

### Reputation-Verifizierung

```
1. User exportiert Badges als JSON
2. JSON enthält Checksumme aller Badges
3. Andere kopieren JSON in badge-verifier.html
4. Tool zeigt:
   ✅ Checksum verifiziert
   📊 5 Badges, 3 Meetups besucht
   📍 München, Berlin, Hamburg
```

### Hash-Berechnung

Jedes Badge hat einen eindeutigen Hash:

```dart
Hash = SHA256(badge_id + meetup + datum + block).substring(0, 16)
```

Beispiel: `a3f9b2c1e5d4f8a2`

---

## 🚀 Installation

### Voraussetzungen

- **Flutter SDK** 3.38.9 oder höher
- **Dart** 3.10.8 oder höher
- Für Android: Android SDK
- Für iOS: Xcode (nur auf macOS)

### Dependencies installieren

```bash
cd Einundzwanzig-Meetup-App
./flutter/bin/flutter pub get
```

### Installierte Packages

- `http`: API-Calls zu portal.einundzwanzig.space
- `nfc_manager`: NFC-Lesen/Schreiben (Mobile)
- `shared_preferences`: Lokale Datenspeicherung
- `crypto`: Hash-Berechnung für Badges
- `share_plus`: Social Media Sharing
- `qr_flutter`: QR-Code-Generierung

---

## 🏗️ App bauen

### Web (PWA)

```bash
./flutter/bin/flutter build web --release
```

Ausgabe: `build/web/`

Testen:
```bash
cd build/web
python3 -m http.server 8080
# Öffne http://localhost:8080
```

### Android (APK)

```bash
./flutter/bin/flutter build apk --release
```

Ausgabe: `build/app/outputs/flutter-apk/app-release.apk`

Installation auf Gerät:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### iOS (IPA)

```bash
./flutter/bin/flutter build ios --release
```

Erfordert:
- macOS mit Xcode
- Apple Developer Account für Signierung

---

## 📱 Benutzung

### Als User (Badge-Sammler)

#### 1. Erste Einrichtung
1. Öffne die App
2. Gib deinen **Nickname** ein (z.B. "Satoshi")
3. Optional: Füge deinen **Nostr npub** hinzu
4. Wähle dein **Home-Meetup** aus der Liste

#### 2. Meetup besuchen & Badge sammeln
1. Gehe zu einem Einundzwanzig Meetup
2. Dashboard → **"BADGES"** → Scanne NFC-Tag
3. Badge wird automatisch gespeichert
4. Siehst du im **Badge Wallet**

#### 3. Reputation teilen
- **Dashboard** → **Badge Wallet** → **Share-Button** (oben rechts)
- Wähle eine Option:
  - **QR-Code anzeigen**: Zum Scannen vor Ort
  - **Als Text teilen**: Für Social Media
  - **Als JSON exportieren**: Für technische Verifizierung

#### 4. Meetup-Details ansehen
- **Dashboard** → **TERMINE** → Tap auf Meetup
- Siehst du: Logo, Beschreibung, Links, Telegram, Website

### Als Admin (Meetup-Organisator)

#### 1. Admin-Login
1. Öffne die App
2. Erstelle Profil wie gewohnt
3. Wenn du NICHT als admin verifiziert wirst → Tippe auf "Admin werden"
4. Gib Passwort ein: `#21AdminTag21#`
5. Du siehst jetzt die **ADMIN**-Kachel

#### 2. NFC-Tags erstellen
1. Dashboard → **ADMIN**
2. Wähle **"NFC Tag beschreiben"**
3. Wähle zwischen:
   - **Badge Tag**: Für Teilnehmer zum Sammeln
   - **Verify Tag**: Für Identitätsverifizierung
4. Halte NFC-Karte an dein Gerät
5. Tag ist beschrieben!

#### 3. Teilnehmer verifizieren
1. Dashboard → **ADMIN** → **"Identitäten verifizieren"**
2. Teilnehmer scannt NFC-Tag
3. Du bestätigst seine Identität
4. Er ist jetzt verifiziert ✅

---

## 🔍 Badge-Verifizierung

### Für Verkäufer (z.B. satoshikleinanzeigen.space)

**Reputation in Inserat zeigen:**

1. Öffne **Badge Wallet** → **Share** → **"QR-Code anzeigen"**
2. Mache Screenshot vom QR-Code
3. Füge Screenshot ins Inserat ein
4. Schreibe: "Verifiziere meine Reputation: [Link zum Verifier]"

**Oder als Text:**

1. **Badge Wallet** → **Share** → **"Als Text teilen"**
2. Text wird kopiert:
   ```
   🏆 MEINE EINUNDZWANZIG REPUTATION
   
   Total Badges: 5
   Meetups besucht: 3
   
   📍 München (15.1.2026)
   📍 Berlin (22.1.2026)
   📍 Hamburg (29.1.2026)
   ```
3. In Inserat-Beschreibung einfügen

### Für Käufer (Reputation prüfen)

**Option 1: QR-Code scannen**
1. Scanne QR-Code vom Verkäufer
2. Siehst du direkt: "Badges: 5, Meetups: 3"

**Option 2: JSON verifizieren**
1. Öffne: [`badge-verifier.html`](badge-verifier.html)
2. Kopiere JSON vom Verkäufer
3. Füge in Textfeld ein → Klick "Verifizieren"
4. Tool zeigt:
   - ✅ **Checksum verifiziert** (nicht manipuliert)
   - **Badge-Liste** mit allen Meetups
   - **Hashes** zur Integritätsprüfung

### Badge Verifier Tool

Das Tool ist eine **standalone HTML-Datei**, die jeder nutzen kann:

**Lokal öffnen:**
```bash
open badge-verifier.html
```

**Als Webseite hosten:**
- Einfach auf GitHub Pages, IPFS oder eigenen Server hochladen
- Keine Backend-Infrastruktur nötig
- 100% client-side JavaScript

**Verwendung:**
1. JSON aus App kopieren (Badge Wallet → Share → JSON)
2. In Verifier einfügen
3. Klick auf "Verifizieren"
4. Ergebnis zeigt alle Badges + Checksum-Status

---

## 🏛️ Architektur

### Ordnerstruktur

```
lib/
├── main.dart              # App-Entry + Session Management
├── theme.dart             # Material Design 3 Theme
├── models/
│   ├── user.dart          # UserProfile (mit SharedPreferences)
│   ├── meetup.dart        # Meetup-Datenmodell
│   └── badge.dart         # MeetupBadge + Reputation-Export
├── screens/
│   ├── intro.dart         # Onboarding
│   ├── verification_gate.dart  # Admin-Passwort-Check
│   ├── dashboard.dart     # Hauptbildschirm
│   ├── badge_wallet.dart  # Badge-Übersicht
│   ├── badge_details.dart # Einzelnes Badge
│   ├── reputation_qr.dart # QR-Code-Anzeige
│   ├── events.dart        # Meetup-Liste
│   ├── meetup_details.dart # Meetup-Informationen
│   ├── meetup_selection.dart # Home-Meetup wählen
│   ├── meetup_verification.dart # NFC-Scanner
│   ├── nfc_writer.dart    # NFC-Tag beschreiben (Admin)
│   ├── admin_panel.dart   # Admin-Dashboard
│   └── profile_edit.dart  # Profil bearbeiten
└── services/
    └── meetup_service.dart # API-Integration
```

### Datenpersistenz

**SharedPreferences (Mobile) / localStorage (Web):**

```dart
// User-Daten
'nickname': String
'telegramHandle': String
'nostrNpub': String
'homeMeetupId': String
'isAdmin': bool
'isAdminVerified': bool

// Badges
'badges': List<String> (JSON-Array)
```

**Session Management:**

```dart
// main.dart → SplashScreen
1. App startet → Lade UserProfile
2. Wenn nickname leer → IntroScreen
3. Wenn isAdminVerified → DashboardScreen
4. Sonst → VerificationGateScreen
```

### API-Integration

**Meetup-Daten:**
- Endpoint: `https://portal.einundzwanzig.space/api/meetups`
- Felder: name, country, city, telegram, logo, website, nostr, lat/lng

**Blockhöhe:**
- Endpoint: `https://mempool.space/api/blocks/tip/height`
- Für Badge-Zeitstempel

### NFC-Handling

**Web (Simuliert):**
```dart
// Zeigt Input-Dialog für manuelle Tag-Eingabe
Future<void> simulateNFCRead() {
  showDialog(...);
}
```

**Mobile (Echt):**
```dart
import 'package:nfc_manager/nfc_manager.dart';

NfcManager.instance.startSession(
  onDiscovered: (NfcTag tag) async {
    final ndef = Ndef.from(tag);
    final message = await ndef.read();
    // Parse Meetup-Daten
  }
);
```

---

## 🗺️ Roadmap

### v1.0 (Aktuell) ✅
- [x] User & Admin Flows
- [x] NFC Badge-Sammlung
- [x] Reputation-Export
- [x] QR-Code-Sharing
- [x] Badge Verifier Tool
- [x] Live API-Integration
- [x] Session-Persistenz

### v2.0 (Geplant)
- [ ] **Nostr-Integration**: Badges als signed Events
- [ ] **Admin-Signaturen**: Meetup-Admins signieren Badges
- [ ] **Web-Verifier mit QR-Scanner**: Kamera-basierte Verifizierung
- [ ] **Badge-NFTs**: Optional als ordinals/RGB
- [ ] **Multi-Language**: EN, ES, FR
- [ ] **Dark/Light Theme Toggle**

### v3.0 (Vision)
- [ ] **Reputation-Score**: Algorithmus basierend auf Badges
- [ ] **Badge Marketplace**: Seltene Badges handeln
- [ ] **Lightning-Integration**: Sats für Badges
- [ ] **Meetup-Voting**: Community entscheidet über neue Features

---

## 🤝 Contributing

Contributions sind willkommen! Bitte:

1. Fork das Repository
2. Erstelle einen Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit deine Änderungen (`git commit -m 'Add AmazingFeature'`)
4. Push zum Branch (`git push origin feature/AmazingFeature`)
5. Öffne einen Pull Request

### Development Setup

```bash
# Clone Repository
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App

# Dependencies installieren
./flutter/bin/flutter pub get

# App im Debug-Modus starten
./flutter/bin/flutter run -d chrome  # Web
./flutter/bin/flutter run            # Connected Device
```

---

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) Datei

---

## 🙏 Credits

- **Einundzwanzig Network**: [einundzwanzig.space](https://einundzwanzig.space)
- **API**: [portal.einundzwanzig.space](https://portal.einundzwanzig.space)
- **Flutter**: Google
- **Bitcoin**: Satoshi Nakamoto

---

## 📞 Support & Kontakt

- **GitHub Issues**: [Bug Reports & Feature Requests](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/issues)
- **Telegram**: @einundzwanzig
- **Nostr**: npub1einundzwanzig...

---

## 🌟 Zeige deine Unterstützung

Wenn dir die App gefällt:
- ⭐ Gib dem Repo einen Star
- 🐛 Melde Bugs
- 💡 Schlage Features vor
- 📱 Nutze die App bei Meetups!

---

**Made with 🧡 for the Bitcoin Community**
