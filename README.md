# ⚡ Einundzwanzig Meetup App

**Kryptographisch verifizierbare Reputation für die Bitcoin-Community — ohne Server, ohne KYC, ohne Vertrauen.**

Eine Flutter-App, die Meetup-Teilnahme über NFC-Tags und QR-Codes erfasst, jeden Badge mit einer Schnorr-Signatur versiegelt und daraus einen Trust Score berechnet — alles lokal auf dem Gerät, alles verifizierbar, alles Open Source.

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

```text
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
│     { v:2, t:"B", m:"aschaffenburg-de", b:879432,           │
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
│  2. Prüft Ablauf: now > x? → "Abgelaufen"                   │
│                                                             │
│  3. Prüft Rolling Nonce (nur bei QR):                       │
│     Zeitschritt aktuell? (±10 Sekunden Toleranz)            │
│                                                             │
│  4. Rekonstruiert Nostr-Event aus Payload                   │
│     → SHA-256 → event_id                                    │
│                                                             │
│  5. Schnorr-Verifikation: verify(pubkey, event_id, sig)     │
│     → true = Badge ist echt, Signatur vom Organisator       │
│                                                             │
│  6. Badge wird lokal gespeichert (SharedPreferences)        │
└─────────────────────────────────────────────────────────────┘

Jedes Badge enthält einen Bitcoin-Block-Height als Zeitstempel. Das ist kein Zufall — der Block-Height ist ein öffentlich verifizierbarer, unmanipulierbarer Zeitbeweis. Block 879.432 wurde an einem bestimmten Tag gemined, und das kann jeder auf mempool.space oder in der eigenen Node nachprüfen.

Features

🏷️ Badge-System mit Schnorr-Signaturen

Jedes Badge ist ein vollständiges Nostr-Event (Kind 21000), signiert mit dem Schnorr-Algorithmus nach BIP-340. Die Signatur beweist kryptographisch, welcher Organisator das Badge erstellt hat — ohne dass ein Server dazwischen steht.

Zwei Wege zum Badge:
Methode	          Anti-Screenshot	           Offline	                 Tag-Kosten
NFC-Tag (NTAG215) ✅ Physisch vor Ort	       ✅ Kein Internet nötig	   ~0,50€
Rolling QR	      ✅ Ändert sich alle 10s	   ❌ Braucht Internet	     Kostenlos

📊 Trust Score

Ein lokaler Algorithmus berechnet aus den gesammelten Badges einen Vertrauenswert. Der Score berücksichtigt:

    Diversität — Verschiedene Meetups zählen mehr als immer das gleiche

    Verschiedene Organisatoren — Badges von unterschiedlichen Signern sind wertvoller

    Alter — Ein Account, der seit 6 Monaten aktiv ist, hat mehr Gewicht

    Time Decay — Alte Badges verlieren langsam an Wert (Halbwertszeit 26 Wochen)

    Frequency Cap — Maximal 2 Badges pro Woche zählen (gegen Farming)

Der Score ist bewusst lokal berechenbar — verschiedene Apps können verschiedene Gewichtungen nutzen. Es gibt keinen "offiziellen" Score, nur einen Algorithmus, den jeder forken und anpassen kann.

🔐 Dezentrales Web of Trust (Admin-System)

Kein zentraler Server, keine statische Datenbank. Organisatoren werden über kryptographische Vertrauensketten via Nostr (Kind 30078) verwaltet. Die App durchläuft dabei autonome Phasen:

    Bootstrap-Phase: Zu Beginn existiert ein hartcodierter Super-Admin (Entwickler), der die ersten "Seed-Organisatoren" delegiert, um das Netzwerk zu starten.

    Der "Bootstrap-Sunset": Sobald das Netzwerk eine kritische Masse an verifizierten Organisatoren erreicht hat (z.B. 20 Admins), löst die App lokal den "Sunset" aus. Der Super-Admin verliert ab diesem Moment dauerhaft seinen zentralen Sonderstatus.

    Peer-to-Peer Vouching (Ritterschlag): Ab dem Sunset wächst das Netzwerk autonom. Etablierte Organisatoren können das Vertrauen an neue Co-Admins weitergeben. Sie scannen den npub (QR-Code) des neuen Organisators und veröffentlichen eine kryptografische Bürgschaft auf den Nostr-Relays. Das Netzwerk verifiziert diese Delegationen rekursiv.

📱 Rolling QR mit Session-Persistenz

Der Rolling QR löst ein praktisches Problem: Wie verhindert man, dass jemand ein Foto vom QR-Code macht und es an einen Freund zu Hause schickt?

Lösung: Der QR-Code ändert sich alle 10 Sekunden. Jeder Code enthält eine HMAC-Nonce, die vom Scanner auf Aktualität geprüft wird. Ein Screenshot ist nach 10 Sekunden wertlos.
Gleichzeitig bleibt die Session für 6 Stunden aktiv — auch wenn der Organisator die App schließt und wieder öffnet. Der Session-Seed wird in SharedPreferences gespeichert und daraus werden die Rolling Nonces deterministisch abgeleitet.

🌐 Weitere Features

    Hochsichere Backups (AES-GCM): Komplettes Profil, Badges und private Nostr-Keys (nsec) werden exportiert. Die .21bkp-Datei wird zwingend mit einem User-Passwort AES-256-GCM verschlüsselt. Ohne Passwort kein Restore!

    Reputation teilen per QR-Code, Text oder JSON-Export mit Checksumme

    Meetup-Radar mit Live-Daten von portal.einundzwanzig.space

    Badge Verifier — standalone HTML-Tool zur externen Verifizierung

    Kalender-Integration mit Einundzwanzig-Meetup-Terminen

Architektur
Ordnerstruktur
Plaintext

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
│   ├── admin_management.dart       # Web of Trust & P2P Vouching (Ritterschlag)
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
    ├── admin_registry.dart         # Nostr Web of Trust (Sunset & P2P Fetching)
    ├── nostr_service.dart          # Keypair-Generierung, Nip19, Relay
    ├── meetup_service.dart         # API zu portal.einundzwanzig.space
    ├── mempool.dart                # Block-Height von mempool.space
    └── backup_service.dart         # AES-GCM verschlüsselter JSON-Export/Import

Datenfluss
Plaintext

                    portal.einundzwanzig.space
                              │
                    Meetup-Liste (JSON API)
                              │
                              ▼
┌──────────────────────────────────────────────┐
│                    APP                       │
│                                              │
│   SharedPreferences                          │
│   ├── User Profile (nickname, npub, ...)     │
│   ├── Badges (signierte JSON-Objekte)        │
│   ├── Nostr Keys (AES-gesichert im OS)       │
│   ├── Admin Registry Cache (WoT)             │
│   ├── Bootstrap Sunset Flag                  │
│   └── Rolling QR Session                     │
│                                              │
│   Nostr Relays ◄──── Web of Trust (Kind 30078)
│   mempool.space ◄── Block Height             │
└──────────────────────────────────────────────┘
          │                         │
     NFC (NDEF)                QR (Rolling)
          │                         │
          ▼                         ▼
    NTAG215 Tag              Bildschirm
    (492 Bytes)             (alle 10 Sek)

Kryptographie
Komponente	Algorithmus	Zweck
Badge-Signatur	Schnorr / BIP-340	Beweis, dass Organisator X dieses Badge erstellt hat
Event-ID	SHA-256	Eindeutige Identifikation des Nostr-Events
Rolling Nonce	HMAC-SHA256	Anti-Screenshot (Freshness-Check)
Backups	AES-256 GCM	Sichere Verwahrung von nsec und Profildaten
Trust Score Hash	SHA-256	Checksumme für Reputation-Export
Admin Registry	Schnorr / BIP-340	Vouchings/Delegationen sind signierte Nostr-Events
Installation
Voraussetzungen

    Flutter SDK ≥ 3.38

    Dart ≥ 3.7

    Android SDK (für Android-Build)

    Xcode (für iOS, nur auf macOS)

Setup
Bash

git clone [https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git](https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git)
cd Einundzwanzig-Meetup-App
git checkout main

flutter pub get
flutter run            # Am verbundenen Gerät
flutter run -d chrome  # Im Browser (NFC simuliert)

Build
Bash

# Android APK
flutter build apk --release

# iOS
flutter build ios --release  # Erfordert Xcode + Apple Dev Account

Die fertige APK liegt unter build/app/outputs/flutter-apk/app-release.apk.
Abhängigkeiten
Package	Zweck
nostr	Nostr-Events, Schnorr-Signaturen (BIP-340)
nfc_manager + nfc_manager_ndef	NFC lesen/schreiben (NDEF)
mobile_scanner	QR-Code Scanner (Kamera)
qr_flutter	QR-Code Generator
crypto	SHA-256, HMAC für Hashes und Nonces
encrypt	AES-GCM Verschlüsselung für Backups
flutter_secure_storage	Sichere Key-Verwahrung (Android Keystore / iOS Keychain)
shared_preferences	Lokale Datenspeicherung
http	API-Calls (Meetups, Block Height)
Benutzung
Als Teilnehmer

    App öffnen → Nickname eingeben → Nostr-Key wird automatisch im Hintergrund generiert.

    Home-Meetup wählen (z.B. "Aschaffenburg, DE").

    Zum Meetup gehen → Dashboard → "BADGE SCANNEN".

    NFC-Tag scannen oder QR-Code scannen → Badge wird kryptografisch verifiziert und gespeichert.

    Reputation teilen → Badge Wallet → Share → QR-Code / Text / JSON.

Als etablierter Organisator (Web of Trust)

    Nostr-Key einrichten (Profil → "Nostr Key generieren/importieren").

    Admin werden — Ein bereits etablierter Admin muss sich für dich verbürgen (Ritterschlag).

    Co-Admins rittern — Admin-Panel → "Mein Web of Trust" → npub des neuen Organisators scannen und Delegation signiert an Nostr senden.

    NFC-Tag beschreiben — Admin-Panel → "NFC Tag beschreiben" → NTAG215 an Handy halten.

    Oder Rolling QR starten — Admin-Panel → "QR-Code" → Session starten (6h gültig).

NFC-Tag Spezifikationen
Empfohlener Tag: NTAG215
Eigenschaft	Wert
Speicher	504 Bytes total, 492 Bytes nutzbar
Schreibzyklen	Unbegrenzt
NFC Forum	Type 2 Tag
Kompatibilität	Android + iOS
Kosten	~0,30–0,80€ pro Tag
Wiederverwendbar	Ja, bei jedem Meetup überschreibbar
Payload-Format (v2 Compact)
JSON

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

(Gesamtgröße: ~285 Bytes → passt auf NTAG215 mit 207 Bytes Reserve)
Trust Score
Berechnung

Der Trust Score wird rein lokal berechnet. Es gibt keinen zentralen Server der Scores vergibt.
Plaintext

Trust Score = Σ (Badge Value × Gewichtung)

Badge Value = BaseValue (1.0)
            × Diversity Bonus (verschiedene Meetups)
            × Quality Bonus (verschiedene Organisatoren)
            × Time Decay (Halbwertszeit 26 Wochen)

Der Trust Score ist bewusst konfigurierbar. Andere Communities können die TrustConfig-Klasse forken und anpassen.
Sicherheitsmodell
Was diese App garantiert

    Fälschungssicherheit — Badges können nicht ohne den privaten Schlüssel des Organisators erstellt werden (Schnorr/BIP-340).

    Kein Single Point of Failure — Kein Server, keine Datenbank. Fällt der Super-Admin aus, übernimmt das Web of Trust (Sunset-Logik).

    Physische Anwesenheit — NFC-Tags erfordern physische Nähe (~4cm), Rolling QR ändert sich alle 10s.

    Transparenz — Jede Signatur und jede Vouching-Kette kann unabhängig verifiziert werden.

Bedrohungsmodelle
Angriff	Schutzmechanismus
Badge fälschen	Schnorr-Signatur → erfordert Organisator-Privkey (nsec).
QR-Screenshot weiterleiten	Rolling Nonce → nach 10s mathematisch ungültig.
Zentraler Admin kompromittiert	Bootstrap Sunset deaktiviert den Super-Admin ab 20 organischen Admins permanent.
Backup-Diebstahl	AES-GCM Verschlüsselung macht das .21bkp Backup ohne das User-Passwort unlesbar.
Admin impersonieren	Admin-Liste / Vouchings sind signierte Nostr-Events.
Badge-Daten manipulieren	SHA-256 Event-ID → jede Änderung (z.B. Blockheight) bricht die Signatur.
Aktueller Entwicklungsstand (Changelog)

✅ Nostr-Keypair-Generierung und -Import (nsec/npub)

✅ Schnorr-Signaturen für Badges (BIP-340 via Nostr Kind 21000)

✅ NFC-Tag lesen und beschreiben (NTAG215)

✅ Rolling QR mit HMAC-Nonce (10s Intervall)

✅ Admin-System über signierte Nostr-Events (Web of Trust)

✅ Bootstrap-Sunset & P2P-Vouching (Vollständige Dezentralisierung) ✅ Trust Score mit Diversity, Decay, Quality

✅ Badge Wallet mit Crypto-Details

✅ Reputation teilen (QR, Text, JSON)

✅ Meetup-Radar mit Live-API

✅ AES-GCM 256-bit verschlüsseltes Backup & Restore ✅ Kompaktes NFC-Format (285 Bytes, passt auf NTAG215)

✅ 6-Stunden-Ablauf für Badges inkl. Session-Persistenz

✅ Echte Schnorr-Verifikation im QR-Scanner
Contributing

Contributions sind willkommen. Besonders gesucht:

    iOS-Tester — NFC-Verhalten auf iPhone testen

    Security Review — Kryptographische Kette prüfen

Workflow

    Fork → Feature-Branch → Pull Request

    Beschreibe was du geändert hast und warum

    Tests sollten durchlaufen

FAQ

Brauche ich einen Nostr-Account? Nein. Die App generiert automatisch ein Keypair lokal. Du kannst aber einen bestehenden nsec importieren.

Was passiert, wenn ich mein Handy verliere? Deine Badges sind weg, es sei denn, du hast ein verschlüsseltes Backup gemacht (.21bkp Datei). WICHTIG: Wenn du das Passwort für das Backup vergisst, sind deine Daten für immer verloren!

Wie werden neue Meetup-Admins ernannt? Durch ein "Web of Trust". Ein etablierter Admin scannt den QR-Code deines Profils ("Ritterschlag") und publiziert diese Bürgschaft im Netzwerk.

Kann der Organisator sehen, wer Badges gesammelt hat? Nein. Der NFC-Tag/QR-Code sendet Daten nur an den Scanner. Es gibt keinen Rückkanal zum Organisator. Die App ist tracking-frei.

Funktioniert das auch ohne Internet? NFC-Tags können offline gescannt werden. Der Rolling QR braucht einmalig Internet für die Block-Height. Das Web of Trust wird lokal gecacht.
Lizenz

MIT — siehe LICENSE
Credits

    Einundzwanzig — Die deutschsprachige Bitcoin-Community

    portal.einundzwanzig.space — Meetup-Daten-API

    mempool.space — Bitcoin Block Explorer API

    Nostr Protocol — Dezentrales Messaging

    Flutter — Cross-Platform Framework

---

**Made with 🧡 for the Bitcoin Community**