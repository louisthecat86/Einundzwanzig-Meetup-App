# ⚡ Einundzwanzig Meetup App

**Kryptographisch verifizierbare Reputation für die Bitcoin-Community — ohne Server, ohne KYC, ohne Vertrauen.**

Eine Flutter-App die Meetup-Teilnahme über NFC-Tags und QR-Codes erfasst, jeden Badge mit einer Schnorr-Signatur versiegelt und daraus einen Trust Score berechnet — alles lokal auf dem Gerät, alles verifizierbar, alles Open Source.

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Nostr](https://img.shields.io/badge/Nostr-NIP--01%20%7C%20BIP--340-purple)](https://github.com/nostr-protocol/nips)

---

## Das Problem

Du willst Bitcoin P2P kaufen oder verkaufen — auf [satoshikleinanzeigen.space](https://satoshikleinanzeigen.space), in einer Telegram-Gruppe oder bei einem Meetup. Aber woher weißt du, dass dein Gegenüber kein Scammer ist?

- Zentrale Bewertungssysteme (eBay, Amazon) funktionieren nur mit einer zentralen Instanz
- KYC-Verifizierung widerspricht dem Grundgedanken von Bitcoin
- Pseudonyme Identitäten sind leicht zu faken
- "Vertraue mir" reicht nicht

**Die Lösung:** Physische Anwesenheit bei Bitcoin-Meetups als Vertrauensbeweis — kryptographisch gesichert, dezentral gespeichert, von jedem verifizierbar.

---

## Wie es funktioniert

### Die Idee in 30 Sekunden

Ein Meetup-Organisator legt einen NFC-Tag oder einen QR-Code auf den Tisch. Jeder Teilnehmer scannt ihn mit der App und erhält ein **Badge** — ein kryptographisch signiertes Zertifikat das beweist: "Diese Person war am 15. Januar 2026 beim Einundzwanzig Meetup in ... , bei Bitcoin-Block 879.432."

Dieses Badge kann nicht gefälscht werden, weil es eine **Schnorr-Signatur** (BIP-340) des Organisators enthält. Es kann nicht kopiert werden, weil der NFC-Tag nur vor Ort lesbar ist und der QR-Code sich alle 10 Sekunden ändert. Und es braucht keinen Server, weil alles lokal auf dem Gerät gespeichert wird.

Nach ein paar Meetups hat der Nutzer eine verifizierbare Reputation: "5 Badges, 3 verschiedene Meetups, 2 verschiedene Organisatoren, seit 4 Monaten aktiv." Das zeigt er per QR-Code bei einem P2P-Trade — und sein Gegenüber kann die Echtheit in Sekunden prüfen.

### Die kryptographische Kette

```
┌─────────────────────────────────────────────────────────────┐
│  ORGANISATOR (hat Nostr-Keypair)                            │
│                                                             │
│  1. Erstellt Badge-Daten:                                   │
│     { meetup: "aschaffenburg-de", block: 879432, ... }      │
│                                                             │
│  2. Erstellt Nostr-Event (Kind 21000):                      │
│     event_id = SHA-256([0, pubkey, created_at, 21000,       │
│                         tags, content])                     │
│                                                             │
│  3. Signiert mit Schnorr (BIP-340):                         │
│     sig = schnorr_sign(privkey, event_id)                   │
│                                                             │
│  4. Schreibt auf NFC-Tag / zeigt als Rolling QR:            │
│     { v:2, t:"B", m:"aschaffenburg-de", b:879432,          │
│       x:1739927280, c:1739905680,                           │
│       p:"64hex_pubkey", s:"128hex_sig" }                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼  Teilnehmer scannt
┌─────────────────────────────────────────────────────────────┐
│  TEILNEHMER (App)                                           │
│                                                             │
│  1. Liest Payload (NFC oder QR)                             │
│                                                             │
│  2. Prüft Ablauf: now > x? → "Abgelaufen"                  │
│                                                             │
│  3. Prüft Rolling Nonce (nur bei QR):                       │
│     Zeitschritt aktuell? (±10 Sekunden Toleranz)            │
│                                                             │
│  4. Rekonstruiert Nostr-Event aus Payload                   │
│     → SHA-256 → event_id                                    │
│                                                             │
│  5. Schnorr-Verifikation: verify(pubkey, event_id, sig)    │
│     → true = Badge ist echt, Signatur vom Organisator       │
│                                                             │
│  6. Badge wird lokal gespeichert (SharedPreferences)        │
└─────────────────────────────────────────────────────────────┘
```

Jedes Badge enthält einen **Bitcoin-Block-Height** als Zeitstempel. Das ist kein Zufall — der Block-Height ist ein öffentlich verifizierbarer, unmanipulierbarer Zeitbeweis. Block 879.432 wurde an einem bestimmten Tag gemined, und das kann jeder auf [mempool.space](https://mempool.space) oder in der eignen Node nachprüfen.

---

## Features

### 🏷️ Badge-System mit Schnorr-Signaturen

Jedes Badge ist ein vollständiges Nostr-Event (Kind 21000), signiert mit dem Schnorr-Algorithmus nach BIP-340. Die Signatur beweist kryptographisch, welcher Organisator das Badge erstellt hat — ohne dass ein Server dazwischen steht.

**Zwei Wege zum Badge:**

| Methode | Anti-Screenshot | Offline | Tag-Kosten |
|---------|:-:|:-:|:-:|
| **NFC-Tag** (NTAG215) | ✅ Physisch vor Ort | ✅ Kein Internet nötig | ~0,50€ |
| **Rolling QR** | ✅ Ändert sich alle 10s | ❌ Braucht Internet | Kostenlos |

### 📊 Trust Score

Ein lokaler Algorithmus berechnet aus den gesammelten Badges einen Vertrauenswert. Der Score berücksichtigt:

- **Diversität** — Verschiedene Meetups zählen mehr als immer das gleiche
- **Verschiedene Organisatoren** — Badges von unterschiedlichen Signern sind wertvoller
- **Alter** — Ein Account der seit 6 Monaten aktiv ist, hat mehr Gewicht
- **Time Decay** — Alte Badges verlieren langsam an Wert (Halbwertszeit 26 Wochen)
- **Frequency Cap** — Maximal 2 Badges pro Woche zählen (gegen Farming)

Der Score ist bewusst lokal berechenbar — verschiedene Apps können verschiedene Gewichtungen nutzen. Es gibt keinen "offiziellen" Score, nur einen Algorithmus den jeder forken und anpassen kann.

### 🔐 Admin-System via Nostr

Kein Passwort, kein zentraler Server. Organisatoren werden über ein signiertes Nostr-Event (Kind 30078) verwaltet:

1. Ein **Super-Admin** publiziert eine Admin-Liste als Nostr-Event auf Relays
2. Die App lädt diese Liste und prüft die Schnorr-Signatur
3. Wer auf der Liste steht, kann NFC-Tags beschreiben und QR-Codes generieren
4. Die Liste wird lokal gecacht (offline-fähig) und im Hintergrund aktualisiert

Keine Datenbank, keine API, keine Accounts. Nur kryptographische Signaturen auf öffentlichen Relays.

### 📱 Rolling QR mit Session-Persistenz

Der Rolling QR löst ein praktisches Problem: Wie verhindert man, dass jemand ein Foto vom QR-Code macht und es an einen Freund zu Hause schickt?

**Lösung:** Der QR-Code ändert sich alle 10 Sekunden. Jeder Code enthält eine HMAC-Nonce die vom Scanner auf Aktualität geprüft wird. Ein Screenshot ist nach 10 Sekunden wertlos.

Gleichzeitig bleibt die **Session** für 6 Stunden aktiv — auch wenn der Organisator die App schließt und wieder öffnet. Der Session-Seed wird in SharedPreferences gespeichert und daraus werden die Rolling Nonces deterministisch abgeleitet.

### 🌐 Weitere Features

- **Reputation teilen** per QR-Code, Text oder JSON-Export mit Checksumme
- **Meetup-Radar** mit Live-Daten von portal.einundzwanzig.space
- **Backup & Restore** — komplettes Profil, Badges und Nostr-Keys sichern
- **Badge Verifier** — standalone HTML-Tool zur externen Verifizierung
- **Kalender-Integration** mit Einundzwanzig-Meetup-Terminen

---

## Architektur

### Ordnerstruktur

```
lib/
├── main.dart                       # App-Entry, Session-Check, Routing
├── theme.dart                      # Material Design 3 (Dark Theme, Orange Akzent)
│
├── models/
│   ├── user.dart                   # Profil (Nickname, npub, Home-Meetup)
│   ├── badge.dart                  # MeetupBadge + Reputation-Export
│   ├── meetup.dart                 # Meetup-Daten (Stadt, Land, Telegram, Coords)
│   └── calendar_event.dart         # Kalender-Events
│
├── screens/
│   ├── intro.dart                  # Onboarding (Name, npub, Home-Meetup)
│   ├── dashboard.dart              # Hauptscreen mit Feature-Kacheln
│   ├── meetup_verification.dart    # NFC-Scan + QR-Scan für Badge-Empfang
│   ├── nfc_writer.dart             # NFC-Tag beschreiben (Admin)
│   ├── rolling_qr_screen.dart      # Rolling QR anzeigen (Admin)
│   ├── admin_panel.dart            # Admin-Dashboard
│   ├── admin_management.dart       # Admin-Liste verwalten (Super-Admin)
│   ├── badge_wallet.dart           # Alle gesammelten Badges
│   ├── badge_details.dart          # Einzelnes Badge mit Crypto-Details
│   ├── reputation_qr.dart          # Reputation als QR teilen
│   ├── qr_scanner.dart             # Universeller QR-Scanner
│   ├── radar.dart                  # Meetup-Karte
│   ├── events.dart                 # Meetup-Liste
│   ├── meetup_details.dart         # Meetup-Infos (Logo, Links, Telegram)
│   ├── profile_edit.dart           # Profil bearbeiten + Nostr-Key Management
│   └── calendar_screen.dart        # Meetup-Kalender
│
└── services/
    ├── badge_security.dart         # Schnorr-Sign/Verify, Legacy-Compat
    ├── rolling_qr_service.dart     # HMAC-Nonce, Session-Management
    ├── trust_score_service.dart    # Lokale Trust-Score-Berechnung
    ├── admin_registry.dart         # Nostr-basierte Admin-Verwaltung
    ├── nostr_service.dart          # Keypair-Generierung, Nip19, Relay
    ├── meetup_service.dart         # API zu portal.einundzwanzig.space
    ├── mempool.dart                # Block-Height von mempool.space
    └── backup_service.dart         # JSON-Export/Import
```

### Datenfluss

```
                    portal.einundzwanzig.space
                              │
                    Meetup-Liste (JSON API)
                              │
                              ▼
┌──────────────────────────────────────────────┐
│                    APP                        │
│                                              │
│   SharedPreferences                          │
│   ├── User Profile (nickname, npub, ...)     │
│   ├── Badges (signierte JSON-Objekte)        │
│   ├── Nostr Keys (nsec, npub, priv_hex)      │
│   ├── Admin Registry Cache                   │
│   └── Rolling QR Session                     │
│                                              │
│   Nostr Relays ◄──── Admin-Liste (Kind 30078)│
│   mempool.space ◄── Block Height             │
└──────────────────────────────────────────────┘
          │                         │
     NFC (NDEF)              QR (Rolling)
          │                         │
          ▼                         ▼
    NTAG215 Tag              Bildschirm
    (492 Bytes)             (alle 10 Sek)
```

### Kryptographie

| Komponente | Algorithmus | Zweck |
|------------|-------------|-------|
| Badge-Signatur | Schnorr / BIP-340 | Beweis dass Organisator X dieses Badge erstellt hat |
| Event-ID | SHA-256 | Eindeutige Identifikation des Nostr-Events |
| Rolling Nonce | HMAC-SHA256 | Anti-Screenshot (Freshness-Check) |
| Session Seed | SHA-256 | Deterministische Nonce-Ableitung über 6h |
| Legacy Sig | HMAC-SHA256 | Rückwärtskompatibilität mit v1-Tags |
| Trust Score Hash | SHA-256 | Checksumme für Reputation-Export |
| Admin Registry | Schnorr / BIP-340 | Admin-Liste ist ein signiertes Nostr-Event |

---

## Installation

### Voraussetzungen

- **Flutter SDK** ≥ 3.38
- **Dart** ≥ 3.7
- Android SDK (für Android-Build)
- Xcode (für iOS, nur auf macOS)

### Setup

```bash
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App
git checkout Nostr-Trustless

flutter pub get
flutter run            # Am verbundenen Gerät
flutter run -d chrome  # Im Browser (NFC simuliert)
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release  # Erfordert Xcode + Apple Dev Account
```

Die fertige APK liegt unter `build/app/outputs/flutter-apk/app-release.apk`.

### Abhängigkeiten

| Package | Zweck |
|---------|-------|
| `nostr` | Nostr-Events, Schnorr-Signaturen (BIP-340) |
| `nfc_manager` + `nfc_manager_ndef` | NFC lesen/schreiben (NDEF) |
| `mobile_scanner` | QR-Code Scanner (Kamera) |
| `qr_flutter` | QR-Code Generator |
| `crypto` | SHA-256, HMAC für Hashes und Nonces |
| `bip340` / `bech32` | Kryptographische Primitives |
| `shared_preferences` | Lokale Datenspeicherung |
| `http` | API-Calls (Meetups, Block Height) |
| `share_plus` | Social Sharing |

---

## Benutzung

### Als Teilnehmer

1. **App öffnen** → Nickname eingeben → optional Nostr-Key generieren oder importieren
2. **Home-Meetup wählen** (z.B. "Aschaffenburg, DE")
3. **Zum Meetup gehen** → Dashboard → "BADGES"
4. **NFC-Tag scannen** oder **QR-Code scannen** → Badge wird verifiziert und gespeichert
5. **Reputation teilen** → Badge Wallet → Share → QR-Code / Text / JSON

### Als Organisator

1. **Nostr-Key einrichten** (Profil → "Nostr Key generieren")
2. **Admin werden** — der Super-Admin trägt deinen npub in die Admin-Liste ein und publiziert sie auf Nostr-Relays
3. **NFC-Tag beschreiben** — Admin-Panel → "NFC Tag beschreiben" → NTAG215 an Handy halten
4. **Oder Rolling QR starten** — Admin-Panel → "QR-Code" → Session starten (6h gültig)
5. **Auf den Tisch legen** — Teilnehmer scannen selbstständig

### Als Super-Admin

1. **nsec eingeben** im Profil (der npub der im Build als `SUPER_ADMIN_NPUB` gesetzt ist)
2. **Admin-Panel** → "Admin-Verwaltung"
3. **Admins hinzufügen** — npub + Meetup-Name eingeben
4. **Liste publizieren** — Signiertes Event wird an Nostr-Relays gesendet
5. Alle Apps weltweit laden die aktualisierte Liste beim nächsten Start

---

## NFC-Tag Spezifikationen

### Empfohlener Tag: NTAG215

| Eigenschaft | Wert |
|-------------|------|
| Speicher | 504 Bytes total, 492 Bytes nutzbar |
| Schreibzyklen | Unbegrenzt |
| NFC Forum | Type 2 Tag |
| Kompatibilität | Android + iOS |
| Kosten | ~0,30–0,80€ pro Tag |
| Wiederverwendbar | Ja, bei jedem Meetup überschreibbar |

### Payload-Format (v2 Compact)

```json
{
  "v": 2,
  "t": "B",
  "m": "aschaffenburg-de",
  "b": 879432,
  "x": 1739927280,
  "c": 1739905680,
  "p": "a1b2c3...64_hex_zeichen...d4e5f6",
  "s": "f6e5d4...128_hex_zeichen...c3b2a1"
}
```

| Feld | Bedeutung | Größe |
|------|-----------|-------|
| `v` | Version (2) | 1B |
| `t` | Typ: "B" = Badge | 1B |
| `m` | Meetup-ID mit Land | ~20B |
| `b` | Bitcoin Block Height | ~7B |
| `x` | Ablauf (Unix, +6h) | 10B |
| `c` | Erstellt (Unix, für Event-Rekonstruktion) | 10B |
| `p` | Admin Pubkey (Hex) | 64B |
| `s` | Schnorr-Signatur (Hex) | 128B |

**Gesamtgröße: ~285 Bytes** → passt auf NTAG215 mit 207 Bytes Reserve.

---

## Trust Score

### Berechnung

Der Trust Score wird rein lokal berechnet. Es gibt keinen zentralen Server der Scores vergibt.

```
Trust Score = Σ (Badge Value × Gewichtung)

Badge Value = BaseValue (1.0)
            × Diversity Bonus (verschiedene Meetups)
            × Quality Bonus (verschiedene Organisatoren)
            × Time Decay (Halbwertszeit 26 Wochen)
```

### Schwellenwerte

| Kriterium | Minimum |
|-----------|---------|
| Trust Score | ≥ 15.0 |
| Badges gesamt | ≥ 5 |
| Verschiedene Meetups | ≥ 3 |
| Verschiedene Organisatoren | ≥ 2 |
| Account-Alter | ≥ 60 Tage |

Wer alle Kriterien erfüllt, erreicht den Status **"Tag-Ersteller"** und könnte theoretisch selbst Meetup-Tags schreiben — ein organisches Wachstum des Netzwerks ohne zentrale Freischaltung.

### Forking ist erwünscht

Der Trust Score ist bewusst konfigurierbar. Die `TrustConfig`-Klasse enthält alle Parameter:

```dart
class TrustConfig {
  static const double promotionThreshold = 15.0;
  static const int minBadges = 5;
  static const int minUniqueMeetups = 3;
  static const double halfLifeWeeks = 26.0;
  static const int maxBadgesPerWeek = 2;
  // ...
}
```

Andere Communities können diese Werte forken und anpassen — strengere Schwellenwerte für High-Stakes-Trading, lockerere für Community-Events.

---

## Badge Verifier

Die Datei `badge-verifier.html` ist ein standalone Verifizierungs-Tool:

1. Nutzer exportiert seine Badges als JSON (Badge Wallet → Share → JSON)
2. JSON wird in den Verifier eingefügt
3. Tool prüft: Checksumme, Badge-Hashes, Anzahl, Meetup-Vielfalt
4. Ergebnis: ✅ Verifiziert oder ❌ Manipuliert

Das Tool ist eine einzelne HTML-Datei, braucht keinen Server, und kann auf GitHub Pages, IPFS oder einer eigenen Domain gehostet werden.

---

## Sicherheitsmodell

### Was diese App garantiert

- **Fälschungssicherheit** — Badges können nicht ohne den privaten Schlüssel des Organisators erstellt werden (Schnorr/BIP-340)
- **Kein Single Point of Failure** — Kein Server, keine Datenbank, keine API die ausfallen oder zensiert werden kann
- **Physische Anwesenheit** — NFC-Tags erfordern physische Nähe (~4cm), Rolling QR ändert sich alle 10s
- **Transparenz** — Jede Signatur kann unabhängig verifiziert werden, der Code ist Open Source

### Was diese App nicht garantiert

- **Identität** — Die App beweist Meetup-Teilnahme, nicht Identität. Ein Nutzer ist pseudonym (Nickname + optional Nostr npub)
- **Einmaligkeit** — Theoretisch könnte jemand zwei Handys vor den NFC-Tag halten. Das ist ein soziales Problem, kein technisches
- **Offline-Verifizierung anderer** — Um die Signatur eines anderen zu prüfen, braucht man dessen Pubkey (im Badge enthalten) und die Schnorr-Bibliothek

### Bedrohungsmodelle

| Angriff | Schutz |
|---------|--------|
| Badge fälschen | Schnorr-Signatur → braucht Organisator-Privkey |
| QR-Screenshot weiterleiten | Rolling Nonce → nach 10s ungültig |
| NFC-Tag klonen | Tag kann nur vor Ort gelesen werden (~4cm) |
| Abgelaufene Badges nutzen | 6-Stunden-Ablauf im Payload |
| Admin impersonieren | Admin-Liste ist signiertes Nostr-Event |
| Badge-Daten manipulieren | SHA-256 Event-ID → jede Änderung bricht die Signatur |

---

## Technische Details

### Nostr-Integration

Die App nutzt das Nostr-Protokoll (NIP-01) für zwei Zwecke:

1. **Badge-Signaturen** — Kind 21000 Events mit Schnorr-Signatur
2. **Admin-Verwaltung** — Kind 30078 (Parameterized Replaceable Event) mit der Admin-Liste

Nostr-Relays dienen nur als Transport — die Daten sind selbst-verifizierend. Wenn alle Relays offline gehen, funktioniert die App mit dem lokalen Cache weiter.

### API-Endpunkte

| Dienst | URL | Zweck |
|--------|-----|-------|
| Meetup-Daten | `portal.einundzwanzig.space/api/meetups` | Meetup-Liste, Standorte, Links |
| Block Height | `mempool.space/api/blocks/tip/height` | Bitcoin-Zeitstempel für Badges |
| Nostr Relays | `relay.damus.io`, `nos.lol`, `relay.nostr.band` | Admin-Liste laden/publizieren |

### Datenspeicherung

Alle Daten liegen in `SharedPreferences` (Android/iOS) bzw. `localStorage` (Web):

```
User:    nickname, npub, homeMeetupId, isAdmin, isAdminVerified
Keys:    nostr_nsec_key, nostr_npub_key, nostr_priv_hex
Badges:  List<JSON> mit signierter Badge-Daten
Admin:   admin_registry_cache (JSON), admin_registry_timestamp
Session: rqr_session_seed, rqr_session_start, rqr_session_expires
```

Es gibt keine Cloud-Synchronisation, keinen Account und kein Login. Die Daten leben auf dem Gerät. Backup/Restore ist über JSON-Export möglich.

---

## Roadmap

### ✅ Implementiert

- Nostr-Keypair-Generierung und -Import (nsec/npub)
- Schnorr-Signaturen für Badges (BIP-340 via Nostr Kind 21000)
- NFC-Tag lesen und beschreiben (NTAG215)
- Rolling QR mit HMAC-Nonce (10s Intervall)
- Admin-System über signierte Nostr-Events
- Trust Score mit Diversity, Decay, Quality
- Badge Wallet mit Crypto-Details
- Reputation teilen (QR, Text, JSON)
- Meetup-Radar mit Live-API
- Backup & Restore
- Kompaktes NFC-Format (285 Bytes, passt auf NTAG215)
- 6-Stunden-Ablauf für Badges
- Session-persistenter Rolling QR (überlebt App-Neustart)
- Vollständige Signatur-Speicherung im Badge-Model
- Echte Schnorr-Verifikation im QR-Scanner (aktuell Fallback)

---

## Entwicklung

### Projekt klonen und starten

```bash
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App
git checkout Nostr-Trustless
flutter pub get
flutter run
```

### Tests

```bash
flutter test
flutter analyze
```

### APK bauen (lokal)

```bash
flutter build apk --release
```

### APK bauen (CI/CD)

GitHub Actions baut automatisch bei Push auf `main`. Die APK wird als Artifact hochgeladen.

---

## Contributing

Contributions sind willkommen. Besonders gesucht:

- **iOS-Tester** — NFC-Verhalten auf iPhone testen
- **Nostr-Entwickler** — Badge-Events als publishbare Nostr-Events
- **UI/UX** — Onboarding-Flow verbessern
- **Übersetzungen** — Deutsch → Englisch, Spanisch
- **Security Review** — Kryptographische Kette prüfen

### Workflow

1. Fork → Feature-Branch → Pull Request
2. Beschreibe was du geändert hast und warum
3. Tests sollten durchlaufen

---

## FAQ

**Brauche ich einen Nostr-Account?**
Nein. Die App generiert automatisch ein Keypair. Du kannst aber einen bestehenden nsec importieren.

**Was passiert wenn ich mein Handy verliere?**
Deine Badges sind weg, es sei denn du hast ein Backup gemacht (Profil → Backup). Das ist gewollt — es gibt keinen zentralen Server der deine Daten hat.

**Kann der Organisator sehen wer Badges gesammelt hat?**
Nein. Der NFC-Tag/QR-Code sendet Daten an den Scanner — es gibt keine Rückmeldung an den Organisator. Die App ist nicht tracking.

**Funktioniert das auch ohne Internet?**
NFC-Tags können offline gescannt werden. Der Rolling QR braucht einmalig Internet für die Block-Height. Die Admin-Liste wird lokal gecacht.

**Warum nicht einfach eine zentrale Datenbank?**
Weil das dem Grundgedanken widerspricht. Eine zentrale Datenbank kann zensiert, gehackt oder abgeschaltet werden. Schnorr-Signaturen funktionieren auch in 20 Jahren noch — ohne dass jemand einen Server bezahlen muss.

**Kann ich die App für meine eigene Community nutzen?**
Ja, MIT-Lizenz. Fork das Repo, passe die Meetup-API und den Trust Score an, fertig.

---

## Lizenz

MIT — siehe [LICENSE](LICENSE)

---

## Credits

- **[Einundzwanzig](https://einundzwanzig.space)** — Die deutschsprachige Bitcoin-Community
- **[portal.einundzwanzig.space](https://portal.einundzwanzig.space)** — Meetup-Daten-API
- **[mempool.space](https://mempool.space)** — Bitcoin Block Explorer API
- **[Nostr Protocol](https://github.com/nostr-protocol/nips)** — Dezentrales Messaging
- **[Flutter](https://flutter.dev)** — Cross-Platform Framework

---

**Made with 🧡 for the Bitcoin Community**