# 🏆 Einundzwanzig Meetup App

**Die dezentrale Reputations-App für die deutschsprachige Bitcoin-Community**

Eine Flutter-basierte App für Android zum Sammeln von Meetup-Badges via NFC und Aufbau einer verifizierbaren Reputation – ohne Server, ohne Cloud, ohne KYC.

![Version](https://img.shields.io/badge/version-1.0.0-orange)
![Flutter](https://img.shields.io/badge/Flutter-3.38+-blue)
![Dart](https://img.shields.io/badge/Dart-3.10+-blue)
![Kotlin](https://img.shields.io/badge/Kotlin-2.2.20-purple)
![NFC](https://img.shields.io/badge/nfc__manager-4.1.1-green)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Inhaltsverzeichnis

- [Überblick](#-überblick)
- [Features](#-features)
- [Wie funktioniert es?](#-wie-funktioniert-es)
- [Badge-Design](#-badge-design)
- [Installation & Build](#-installation--build)
- [Benutzung](#-benutzung)
- [Sicherheit](#-sicherheit)
- [Architektur](#-architektur)
- [API-Integration](#-api-integration)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)

---

## 🎯 Überblick

Die **Einundzwanzig Meetup App** löst das Problem der fehlenden Reputation in der dezentralen Bitcoin-Community. Bei Peer-to-Peer-Plattformen wie **satoshikleinanzeigen.space** gibt es kein Bewertungssystem und keine zentrale Identitätsprüfung – man weiß nicht, ob jemand vertrauenswürdig ist.

Diese App ändert das:

- **Badges sammeln** durch physische Teilnahme an Meetups (via NFC-Tags)
- **Reputation aufbauen** als kryptografisch nachweisbare Community-Aktivität
- **Vertrauen schaffen** bei P2P-Trades, ohne KYC oder zentrale Instanzen
- **Self-Sovereign** – alle Daten liegen lokal auf deinem Gerät

### Warum ist das wichtig?

Wer bei 10+ Meetups physisch vor Ort war und das nachweisen kann, ist mit hoher Wahrscheinlichkeit kein Scammer. Die App macht genau diesen Nachweis möglich – dezentral, pseudonym und verifizierbar.

---

## ✨ Features

### 🎫 NFC Badge-System
- **NFC-Tag scannen** → Badge mit Meetup-Name, Datum und aktueller Bitcoin-Blockhöhe wird erstellt
- **Kryptografische Signatur** – jeder Badge wird mit SHA-256 HMAC signiert (App-Secret + Meetup-ID + Timestamp + Blockhöhe)
- **Duplikat-Schutz** – gleicher Badge kann nicht zweimal gescannt werden
- **Offline-fähig** – Badges werden lokal in SharedPreferences gespeichert

### 🎨 Generative Art Badges
Jeder Badge bekommt ein **einzigartiges, algorithmisch generiertes Hintergrundmuster** – basierend auf dem SHA-256 Hash aus Meetup-Name und Blockhöhe. Kein Badge sieht aus wie ein anderer. Das Muster besteht aus geometrischen Formen (Kreise, Rauten, Hexagone, Linien) in warmen Bitcoin-Orange-Tönen.

### 📊 Badge Wallet
- **Übersichtliches Grid-Layout** mit 2 Spalten (Normal) oder 3 Spalten (Kompakt)
- **Automatischer Kompakt-Modus** ab 7+ Badges für bessere Übersicht
- **Dynamische Schriftgröße** – lange Meetup-Namen werden automatisch kleiner dargestellt
- **Blockhöhe auf jedem Badge** – z.B. „₿ Block 885.432"
- **Badge-Zähler** in der Titelleiste: „BADGE WALLET (12)"

### 📱 Dashboard
- Persönliche Begrüßung mit Nickname
- Home-Meetup-Karte mit Direkt-Link zum Kalender
- Schnellzugriff auf: Badge-Scanner, Wallet, Termine, Profil, Reputation, Admin-Panel
- Badge-Zähler in Echtzeit

### 📅 Kalender & Events
- **Live-Daten** vom Einundzwanzig Portal (ICS-Kalender-Feed)
- **Suchfunktion** – filtern nach Stadt, Name oder Stichwort
- **Detail-Ansicht** mit Beschreibung, Ort und Uhrzeit
- **Meetup-Details** mit Telegram-Link, Twitter/X, Nostr-npub und Google Maps Route

### 👤 Profil-System
- Nickname (Pflichtfeld), optionaler Realname
- Social-Links: Nostr npub, Telegram, Twitter/X
- Home-Meetup auswählen (aus 200+ Meetups)
- Verifizierungsstatus (Admin-bestätigt oder NFC-verifiziert)

### 🔐 Verifizierung (Zwei Wege)
1. **NFC-Tag scannen** – ein Admin hält dir seinen Verifizierungs-Tag hin, du scannst ihn → verifiziert
2. **Admin-Login** – Organisatoren können sich mit dem Passwort direkt freischalten (Passwort ist nur als SHA-256 Hash im Code gespeichert, nicht im Klartext)

### 🛡️ Admin-Panel (für Meetup-Organisatoren)
- **Meetup-Badge-Tag erstellen** – NFC-Tag beschreiben, den Teilnehmer scannen können
- **Verifizierungs-Tag erstellen** – NFC-Tag für die Identitätsbestätigung neuer Nutzer
- Zugang nur für verifizierte Admins

### 📤 Reputation teilen
- **QR-Code** – zeige deine Badges als scannbaren Code (mit qr_flutter)
- **Text-Export** – formatierte Zusammenfassung für Social Media oder Messenger
- **JSON-Export** – maschinenlesbar mit SHA-256 Checksumme zur Verifizierung
- **Badge-Verifier** – standalone HTML-Tool (`badge-verifier.html`) zur Überprüfung

### 💾 Backup & Restore
- **Backup erstellen** – exportiert Profil + alle Badges als JSON-Datei
- **Backup laden** – auf dem Intro-Screen kann ein bestehendes Backup eingespielt werden
- Dateiname mit Datum: `21_backup_2026-02-11.json`
- Share-Sheet: per Signal, Telegram, E-Mail, in Dateien speichern, etc.

---

## 🔧 Wie funktioniert es?

### Badge-Lebenszyklus

```
┌─────────────────────────────────────────────────────────┐
│  1. ADMIN ERSTELLT TAG                                  │
│     Admin-Panel → "Meetup Tag erstellen"                │
│     → NFC-Tag wird beschrieben mit:                     │
│       Meetup-ID, Name, Land, Typ, Timestamp,            │
│       Blockhöhe, SHA-256 Signatur                       │
├─────────────────────────────────────────────────────────┤
│  2. USER SCANNT TAG                                     │
│     Dashboard → "Badges" → Handy an Tag halten          │
│     → App liest NDEF-Daten                              │
│     → Signatur wird geprüft (BadgeSecurity.verify)      │
│     → Aktuelle Blockhöhe wird von mempool.space geholt  │
├─────────────────────────────────────────────────────────┤
│  3. BADGE WIRD ERSTELLT                                 │
│     MeetupBadge {                                       │
│       id: "muc_1707661234",                             │
│       meetupName: "München, DE",                        │
│       date: 2026-02-11,                                 │
│       blockHeight: 885432,                              │
│       hash: "a3f9b2c1e5d4f8a2"                         │
│     }                                                   │
├─────────────────────────────────────────────────────────┤
│  4. BADGE WIRD GESPEICHERT                              │
│     → SharedPreferences (lokal auf dem Gerät)           │
│     → Generative Art wird aus Hash berechnet            │
│     → Badge erscheint im Wallet                         │
└─────────────────────────────────────────────────────────┘
```

### Signatur & Verifizierung

Jedes NFC-Tag enthält eine kryptografische Signatur:

```
Signatur = SHA-256(meetup_id | timestamp | block_height | APP_SECRET)
```

Beim Scannen berechnet die App die Signatur neu und vergleicht sie. Nur Tags, die mit dem korrekten App-Secret erstellt wurden, werden akzeptiert. Ohne Zugang zum Quellcode kann niemand gültige Tags fälschen.

### Badge-Hash

Jedes Badge hat einen eindeutigen Fingerabdruck:

```
Hash = SHA-256(id + meetupName + date + blockHeight).substring(0, 16)
```

Dieser Hash fließt in den JSON-Export und die QR-Codes ein und ermöglicht die Verifizierung der Integrität.

---

## 🎨 Badge-Design

### Generative Art

Jeder Badge generiert sein einzigartiges Muster durch einen `CustomPainter`, der den SHA-256 Hash als Seed verwendet:

- **32 Bytes** des Hashes steuern Position, Größe, Form und Farbe
- **Formen:** Kreise, Rauten, Hexagone, diagonale Linien
- **Farbpalette:** Warme Bitcoin-Orange-Töne (Amber, Gold, Kupfer)
- **Grid-Overlay:** Feines Raster für technischen Look
- **Gradient:** Dunkler Verlauf am unteren Rand für Textlesbarkeit

Zwei Badges vom selben Meetup aber mit unterschiedlicher Blockhöhe sehen komplett anders aus – jeder Badge ist ein Unikat.

### Badge-Informationen

Jeder Badge zeigt:
- ✅ Verified-Icon + fortlaufende Nummer (#1, #2, ...)
- 📍 Meetup-Name + Land (z.B. „MÜNCHEN, DE")
- 📅 Datum (z.B. „11.2.2026")
- ₿ Bitcoin-Blockhöhe (z.B. „Block 885.432")

---

## 🚀 Installation & Build

### Voraussetzungen

| Komponente | Version |
|---|---|
| Flutter SDK | ≥ 3.38.x |
| Dart SDK | ≥ 3.10.8 |
| Kotlin | 2.2.20 |
| Android SDK | compileSdk 36, minSdk 23, targetSdk 36 |
| Gradle | 8.11.1 |

### Dependencies

```yaml
dependencies:
  http: ^1.6.0              # API-Calls (Portal, Mempool)
  nfc_manager: ^4.1.1       # NFC-Lesen/Schreiben
  nfc_manager_ndef: ^1.0.1  # NDEF-Nachrichten (v4 Package-Split)
  shared_preferences: ^2.5.4 # Lokale Datenspeicherung
  crypto: ^3.0.6            # SHA-256 Hashing
  share_plus: ^10.1.4       # Teilen-Funktion
  qr_flutter: ^4.1.0        # QR-Code-Generierung
  file_picker: ^8.0.0       # Backup-Datei auswählen
  path_provider: ^2.1.2     # Temp-Verzeichnis für Backup
  intl: ^0.19.0             # Datums-Formatierung
  icalendar_parser: ^2.0.0  # Kalender-Feed parsen
  url_launcher: ^6.2.5      # Links öffnen (Telegram, Maps)
```

### Build APK

```bash
# 1. Dependencies installieren
flutter pub get

# 2. Release-APK bauen
flutter build apk --release

# 3. APK installieren
adb install build/app/outputs/flutter-apk/app-release.apk
```

Die APK liegt nach dem Build unter:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Hinweis zu NFC

Die App nutzt `nfc_manager` v4.1.1, das ab Kotlin 2.2.x einen Package-Split erfordert:
- `nfc_manager` – Basis-Funktionalität (Tag-Discovery, Availability-Check)
- `nfc_manager_ndef` – NDEF-Nachrichten lesen/schreiben
- `nfc_manager_android` – Android-spezifisch: `NdefFormatableAndroid` für neue Tags

---

## 📱 Benutzung

### Als Teilnehmer (Badge-Sammler)

**Ersteinrichtung:**
1. App öffnen → Nickname eingeben
2. Optional: Nostr npub, Telegram, Twitter/X hinzufügen
3. Home-Meetup aus der Liste wählen
4. Admin-Tag scannen oder von Admin verifizieren lassen → Dashboard

**Badge sammeln:**
1. Dashboard → **BADGES** tippen
2. Smartphone an den NFC-Tag des Meetups halten
3. Badge wird automatisch erstellt und gespeichert
4. Im **WALLET** sichtbar mit einzigartigem Generative Art Hintergrund

**Reputation teilen:**
1. Dashboard → **WALLET** → Share-Icon (oben rechts)
2. Wähle: QR-Code, Text-Export oder JSON-Export
3. Oder: Dashboard → **REPUTATION** → QR-Code direkt anzeigen

**Backup erstellen:**
1. Dashboard → Zahnrad (Settings) → **Backup erstellen**
2. JSON-Datei wird per Share-Sheet geteilt
3. In Dateien speichern, per Signal senden, etc.

**Backup laden:**
1. Intro-Screen → **BACKUP LADEN**
2. JSON-Datei auswählen → Profil + Badges werden wiederhergestellt

### Als Organisator (Admin)

**Admin werden:**
1. Profil erstellen wie gewohnt
2. Beim Verifizierungs-Gate → „Ich bin Organisator / Admin"
3. Admin-Passwort eingeben (wird gegen SHA-256 Hash geprüft)
4. → Dashboard mit **ADMIN**-Kachel

**NFC-Tags erstellen:**
1. Dashboard → **ADMIN**
2. **Meetup Tag erstellen** – Tag für Teilnehmer-Badges
3. **Verifizierungs-Tag erstellen** – Tag für Identitätsbestätigung
4. NFC-Karte/-Sticker an Smartphone halten → beschrieben

---

## 🔐 Sicherheit

### Passwort-Schutz

Das Admin-Passwort steht **nicht** im Klartext im Code. Stattdessen wird nur der SHA-256 Hash gespeichert:

```dart
// Nur der Hash ist im Code – das Passwort selbst ist nirgends zu finden
static const String _adminPasswordHash = "5d3e17aa...";

// Bei Login: Eingabe hashen und mit gespeichertem Hash vergleichen
final inputHash = sha256(utf8.encode(eingabe)).toString();
if (inputHash == _adminPasswordHash) { /* Zugang */ }
```

Selbst bei Dekompilierung der APK ist das Passwort nicht direkt sichtbar.

### Badge-Signatur

Jedes NFC-Tag wird mit einem HMAC-ähnlichen Verfahren signiert:

```
signature = SHA-256(meetup_id | timestamp | block_height | APP_SECRET)
```

Ohne Kenntnis des `APP_SECRET` können keine gültigen Tags erstellt werden. Beim Scannen wird die Signatur verifiziert – manipulierte Tags werden abgelehnt.

### Datenschutz

- **Lokal gespeichert** – keine Cloud, kein Server, keine Datenbank
- **Pseudonym** – nur Nickname + optionaler Nostr npub, kein Realname erforderlich
- **Self-Sovereign** – du kontrollierst deine Daten komplett
- **Selektives Teilen** – du entscheidest, was du exportierst

---

## 🏛️ Architektur

### Projektstruktur

```
lib/
├── main.dart                     # App-Entry, Session-Check, Routing
├── theme.dart                    # Material Design 3 Theme (Dark Mode)
│
├── models/
│   ├── user.dart                 # UserProfile (SharedPreferences)
│   ├── meetup.dart               # Meetup-Datenmodell
│   ├── badge.dart                # MeetupBadge + Reputation-Export + Hashing
│   └── calendar_event.dart       # Kalender-Event (ICS-Parsing)
│
├── screens/
│   ├── intro.dart                # Onboarding + Backup-Restore
│   ├── verification_gate.dart    # NFC-Verifizierung oder Admin-Login
│   ├── dashboard.dart            # Hauptbildschirm mit Grid-Tiles
│   ├── profile_edit.dart         # Profil bearbeiten
│   ├── profile_review.dart       # Profil-Zusammenfassung
│   ├── meetup_selection.dart     # Home-Meetup wählen (mit Suche)
│   ├── meetup_verification.dart  # NFC-Scanner (Lesen & Verifizieren)
│   ├── nfc_writer.dart           # NFC-Tag beschreiben (Admin)
│   ├── admin_panel.dart          # Admin-Dashboard
│   ├── badge_wallet.dart         # Badge-Übersicht (Generative Art)
│   ├── badge_details.dart        # Einzelnes Badge im Detail
│   ├── reputation_qr.dart        # QR-Code-Anzeige
│   ├── calendar_screen.dart      # Kalender mit Suche
│   ├── events.dart               # Meetup-Liste (aus API)
│   └── meetup_details.dart       # Meetup-Info (Termine, Links, Map)
│
└── services/
    ├── meetup_service.dart        # API: portal.einundzwanzig.space
    ├── meetup_calendar_service.dart # ICS-Feed: Kalender
    ├── mempool.dart               # API: mempool.space (Blockhöhe)
    ├── badge_security.dart        # SHA-256 Signierung & Verifizierung
    └── backup_service.dart        # JSON Backup/Restore
```

### Datenfluss

```
Portal API ──→ MeetupService ──→ Meetup-Liste, Kalender-Events
                                       │
Mempool API ──→ MempoolService ──→ Blockhöhe für Badges
                                       │
NFC-Tag ──→ MeetupVerification ──→ BadgeSecurity.verify()
                                       │
                                 MeetupBadge ──→ SharedPreferences
                                       │
                              BadgeWalletScreen ──→ GenerativeArt
                                       │
                              ReputationQR ──→ QR-Code / JSON / Text
```

### Session-Management

```
App Start
  │
  ├─ Nickname leer? ──→ IntroScreen
  │
  ├─ Admin-verifiziert? ──→ DashboardScreen
  │
  └─ Sonst ──→ VerificationGateScreen
```

---

## 🌐 API-Integration

### Meetup-Daten

```
GET https://portal.einundzwanzig.space/api/meetups
```

Liefert 200+ Meetups mit: `name`, `city`, `country`, `url` (Telegram), `latitude`, `longitude`, `twitter_username`, `nostr`, `website`, `logo`, `next_event`.

### Kalender-Feed

```
GET https://portal.einundzwanzig.space/stream-calendar
```

ICS-Format, wird mit `icalendar_parser` geparst. Enthält alle kommenden Meetup-Termine im DACH-Raum und darüber hinaus.

### Bitcoin-Blockhöhe

```
GET https://mempool.space/api/blocks/tip/height
```

Gibt die aktuelle Blockhöhe als Integer zurück (z.B. `885432`). Wird beim Badge-Erstellen und Badge-Scannen als unveränderlicher Zeitstempel verwendet.

---

## 🗺️ Roadmap

### v1.0 (Aktuell) ✅
- [x] NFC Badge-Sammlung mit Signatur-Verifizierung
- [x] Generative Art Badge-Hintergründe
- [x] Kompakt-Ansicht für viele Badges
- [x] Admin-Passwort als SHA-256 Hash (kein Klartext)
- [x] Backup & Restore (JSON-Export/Import)
- [x] Live-Kalender vom Einundzwanzig Portal
- [x] QR-Code, Text- und JSON-Reputation-Export
- [x] Badge-Verifier (standalone HTML-Tool)
- [x] Profil mit Nostr, Telegram, Twitter/X
- [x] 200+ Meetups aus der Portal-API
- [x] Bitcoin-Blockhöhe als Zeitstempel

### v2.0 (Geplant)
- [ ] **Nostr-Integration** – Badges als signierte Nostr-Events
- [ ] **Admin-Signaturen** – Meetup-Admins signieren Badges mit ihrem Nostr-Key
- [ ] **Kamera-Scanner** – QR-basierte Verifizierung als Backup zu NFC
- [ ] **iOS-Build** – optimierte iOS-Version mit CoreNFC
- [ ] **Web-PWA** – abgespeckte Version ohne NFC zum Anzeigen der Reputation
- [ ] **Multi-Language** – EN, ES, FR

### v3.0 (Vision)
- [ ] **Reputation-Score** – gewichteter Algorithmus (Regelmäßigkeit, Diversität, Alter)
- [ ] **Lightning-Integration** – Sats empfangen/senden bei Meetups
- [ ] **Dezentraler Badge-Verifier** – Verifizierung über Nostr-Relays
- [ ] **Badge-Rarity** – seltene Event-Badges (Konferenzen, Jubiläen)

---

## 🤝 Contributing

Contributions sind willkommen!

```bash
# 1. Fork & Clone
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App

# 2. Dependencies
flutter pub get

# 3. Auf Gerät testen (NFC braucht echtes Android-Gerät)
flutter run

# 4. Release-APK bauen
flutter build apk --release
```

### Branch-Strategie
1. Fork das Repository
2. Feature-Branch erstellen: `git checkout -b feature/mein-feature`
3. Committen: `git commit -m 'Add: Mein neues Feature'`
4. Pushen: `git push origin feature/mein-feature`
5. Pull Request öffnen

---

## 📄 Lizenz

MIT License – siehe [LICENSE](LICENSE)

---

## 🙏 Credits

- **Einundzwanzig Community** – [einundzwanzig.space](https://einundzwanzig.space)
- **Portal-API** – [portal.einundzwanzig.space](https://portal.einundzwanzig.space)
- **Blockhöhe** – [mempool.space](https://mempool.space)
- **Flutter** – Google
- **Bitcoin** – Satoshi Nakamoto

---

## 📞 Support

- **GitHub Issues**: [Bug Reports & Feature Requests](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/issues)
- **Telegram**: Einundzwanzig Community Gruppen
- **Nostr**: Einundzwanzig Relays

---

**Made with 🧡 for the Bitcoin Community**

**Tick Tock, Next Block.**