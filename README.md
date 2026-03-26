# ⚡ Einundzwanzig Meetup App

**Kryptographisch verifizierbare Reputation für die Bitcoin-Community — ohne Server, ohne KYC, ohne Vertrauen.**

Eine Flutter-App, die Meetup-Teilnahme über NFC-Tags und Rolling-QR-Codes erfasst, jedes Badge mit einer Schnorr-Signatur (BIP-340) versiegelt und daraus einen dezentralen Trust Score berechnet. Alles lokal auf dem Gerät, alles verifizierbar, alles Open Source.

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10+-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Nostr](https://img.shields.io/badge/Nostr-BIP--340%20%7C%20NIP--01-purple)](https://github.com/nostr-protocol/nips)

---

## Das Problem

Du willst Bitcoin P2P kaufen oder verkaufen — auf Satoshi-Kleinanzeigen, in einer Telegram-Gruppe oder bei einem Meetup. Aber woher weißt du, dass dein Gegenüber kein Scammer ist?

Zentrale Bewertungssysteme (eBay, Amazon) brauchen eine zentrale Instanz. KYC-Verifizierung widerspricht dem Grundgedanken von Bitcoin. Pseudonyme Identitäten sind leicht zu faken. „Vertrau mir" reicht nicht.

**Die Lösung:** Physische Anwesenheit bei Bitcoin-Meetups als Vertrauensbeweis — kryptographisch gesichert, dezentral gespeichert, von jedem verifizierbar.

---

## Wie es funktioniert

### Die Idee in 30 Sekunden

Ein Meetup-Organisator startet eine Session in der App. Dabei wird ein NFC-Tag beschrieben oder ein Rolling-QR-Code generiert, der sich alle 10 Sekunden ändert. Jeder Teilnehmer scannt den Tag oder QR-Code und erhält ein **Badge** — ein kryptographisch signiertes Zertifikat, das beweist: „Diese Person war an diesem Datum bei diesem Meetup, bei Bitcoin-Block X."

Dieses Badge kann nicht gefälscht werden, weil es eine **Schnorr-Signatur** (BIP-340) des Organisators enthält. Es kann nicht kopiert werden, weil der Rolling-QR sich ständig ändert und der NFC-Tag nur vor Ort lesbar ist. Und es braucht keinen Server, weil alles lokal auf dem Gerät gespeichert wird.

Nach ein paar Meetups hat der Nutzer eine verifizierbare Reputation, die er per QR-Code bei einem P2P-Trade zeigen kann. Sein Gegenüber kann die Echtheit in Sekunden prüfen.

### Die kryptographische Kette

```
ORGANISATOR                          TEILNEHMER
────────────                         ──────────
Nostr-Keypair (BIP-340)              Nostr-Keypair (BIP-340)
        │                                    │
        ▼                                    │
signCompact()                                │
  Content: {v,t,m,b,x}                      │
  Nostr-Event Kind 21000                     │
  → Schnorr-Signatur (128 hex)              │
        │                                    │
        ▼                                    │
NFC-Tag / Rolling QR ─── Scan ──────→ verifyCompact()
  (~285 Bytes, NTAG215)                Schnorr-Check ✓
                                             │
                                             ▼
                                      BadgeClaimService
                                        Kind 21002
                                        → Claim-Signatur
                                             │
                                             ▼
                                      Badge mit ZWEI Signaturen:
                                        1. Organisator: „Meetup fand statt"
                                        2. Sammler: „Ich war dabei"
```

**Warum zwei Signaturen?** Die Organisator-Signatur beweist, dass das Meetup stattfand und dieser Tag echt ist. Die Claim-Signatur des Sammlers bindet das Badge an genau diese Person. Ohne Claim-Binding könnte jemand fremde Badges kopieren und für seine eigene Reputation verwenden.

---

## Features

### Badge-System

Die App unterstützt zwei Methoden zur Badge-Vergabe:

**NFC-Tags** — Der Organisator beschreibt einen NFC-Tag (NTAG215, 492 Bytes) mit einem signierten Kompakt-Payload (~285 Bytes). Teilnehmer halten ihr Smartphone an den Tag und erhalten das Badge. Die Signatur wird sofort geprüft.

**Rolling QR-Codes** — Für größere Meetups oder wenn kein NFC-Tag verfügbar ist. Der Organisator startet eine 6-Stunden-Session. Der QR-Code enthält den signierten Base-Payload plus eine HMAC-Nonce, die sich alle 10 Sekunden ändert. Screenshots werden dadurch wertlos, da abgelaufene Nonces nicht akzeptiert werden.

Beide Methoden erzeugen identische Badge-Objekte mit vollständiger kryptographischer Beweiskette.

### Badge Wallet

Alle gesammelten Badges werden verschlüsselt in der Badge Wallet gespeichert. Jedes Badge zeigt den Meetup-Namen, das Datum, die Bitcoin-Blockhöhe zum Zeitpunkt des Scans und den Verifikationsstatus. Badges werden nach Nostr-signiert (v2) und Legacy (v1, deaktiviert) unterschieden. Nur kryptographisch gebundene Badges (mit Claim-Signatur) zählen für die Reputation.

### Trust Score

Der Trust Score ist eine mehrdimensionale Bewertung, die sich aus vier Faktoren zusammensetzt:

**Diversity Score** — Verschiedene Meetups, verschiedene Städte, verschiedene Organisatoren. Wer nur ein einziges Meetup besucht, kann keinen hohen Score aufbauen. Gewichtung: 1.5x.

**Quality Score** — Der „Wert" einzelner Badges. Ein Badge von einem gut besuchten Meetup mit vielen verifizierten Teilnehmern (Co-Attestoren) ist mehr wert als ein Badge von einem Treffen mit zwei Unbekannten. Gewichtung: 1.2x.

**Maturity Score** — Account-Alter und Kontinuität. Wer seit 6 Monaten regelmäßig auf Meetups geht, ist vertrauenswürdiger als jemand der gestern angefangen hat.

**Activity Score** — Regelmäßigkeit mit Frequency Cap (max. 2 Badges pro Woche zählen). Time Decay mit Halbwertszeit von 26 Wochen — wer aufhört hinzugehen, verliert graduell an Score.

Die Levels reichen von NEU (0–3 Punkte) über STARTER, AKTIV, ETABLIERT bis VETERAN (40+ Punkte).

### Bootstrap-Phasen

Das System passt sich automatisch an die Netzwerkgröße an:

| Phase | Signer | Min. Badges | Min. Meetups | Min. Signer | Min. Alter |
|-------|--------|-------------|--------------|-------------|------------|
| Keimphase | 1 | 3 | 2 | 1 | 14 Tage |
| Wachstum | 2–5 | 4 | 3 | 2 | 30 Tage |
| Stabil | 6+ | 5 | 3 | 2 | 60 Tage |

In der Keimphase reichen wenige Badges, damit das Netzwerk überhaupt wachsen kann. Sobald mehr Organisatoren aktiv sind, steigen die Anforderungen automatisch.

### Dezentrale Admin-Verwaltung (Web of Trust)

Das Admin-System basiert auf gegenseitigem Bürgen (Vouching). Es gibt keine zentrale Instanz, die Admins ernennt oder absetzt.

**Auto-Promotion** — Wer den Trust-Score-Schwellenwert der aktuellen Bootstrap-Phase erreicht, wird automatisch zum Organisator. Keine Bewerbung, keine Genehmigung.

**Vouching-System** — Jeder Admin publiziert auf Nostr-Relays eine signierte Liste der npubs, für die er bürgt. Admin-Status erfordert eine Mindestanzahl an Bürgschaften (dynamisch: 2 bei wenigen Admins, steigend mit der Netzwerkgröße).

**Distrust-Meldungen** — Aktive Warnsignale (Kind 21003) ermöglichen es, vor kompromittierten oder missbräuchlichen Admins zu warnen. Ein einzelner Distrust ist Information, mehrere führen zum automatischen Downgrade.

**Bootstrap Sunset** — Der initiale Super-Admin verliert automatisch seinen hartcodierten Sonderstatus, sobald das Netzwerk eine kritische Masse an organischen Admins (20+) erreicht hat. Danach gilt reines Peer-to-Peer Vouching.

### Reputation teilen und prüfen

**Reputations-QR** — Der Nutzer kann seinen Trust Score als QR-Code generieren. Dieser enthält aggregierte Statistiken (Anzahl Badges, verschiedene Meetups, verschiedene Signer, Account-Alter) und einen kryptographischen Proof-Hash — aber keine persönlichen Details wie Meetup-Namen oder Besuchsdaten.

**Reputation verifizieren** — Per Scan des QR-Codes eines anderen Nutzers. Die App prüft die Schnorr-Signaturen, den Badge-Proof-Hash und zeigt das Trust Level an.

**Relay-Publishing** — Die Reputation wird automatisch als Nostr-Event (Kind 30078, Parameterized Replaceable) auf konfigurierbare Relays publiziert. Nur aggregierte Zahlen — keine Meetup-Details.

### Identitäts-Layer

Zusätzlich zu Meetup-Badges kann der Nutzer seine Identität über mehrere Kanäle verknüpfen:

**Plattform-Proofs** — Signierte Verify-Strings im Format `21rep::npub1...::plattform::username::sig=hex`, die Accounts auf Satoshi-Kleinanzeigen, Telegram, RoboSats oder Nostr kryptographisch an den npub binden. Der Nutzer kopiert den String in sein Plattform-Profil, der Verifizierer prüft automatisch.

**NIP-05 Verification** — Prüfung des Nostr Internet-Identifikators. Community-Domains wie `einundzwanzig.space` haben einen höheren Vertrauenswert als öffentliche NIP-05-Provider.

**Lightning / Humanity Proof** — Beweist Menschlichkeit durch Nachweis einer echten Lightning-Zap-Transaktion auf Nostr-Relays. Bots haben keine Lightning-Wallets, und jeder Fake-Account bräuchte echte Sats. Der Proof speichert nur den Fakt „hat gezappt" — nicht wen, wann oder wie viel.

**Social Graph** — Analyse der Nostr-Follower/Following-Beziehungen für einen zusätzlichen Vertrauenssignal.

---

## Sicherheitsarchitektur

### Kryptographie

Alle Signaturen verwenden **Schnorr (BIP-340)** über das Nostr-Protokoll. Private Schlüssel werden ausschließlich im **Android Keystore / iOS Keychain** gespeichert (via `flutter_secure_storage`). Kein privater Schlüssel verlässt jemals den sicheren Speicher — er wird nur zum Signieren verwendet.

Ein früheres v1-System, das auf einem Shared Secret (HMAC-SHA256) basierte, ist vollständig deaktiviert. `signLegacy()` gibt immer einen leeren String zurück, `verifyLegacy()` gibt immer `false` zurück. v1-Badges werden nicht mehr akzeptiert.

### Badge Security v3.1

Die Badge-Verifikation verwendet eine **Whitelist** für Content-Felder (nur `v`, `t`, `m`, `b`, `x`), nicht eine Blacklist. Unbekannte Felder werden ignoriert. JSON-Content wird vor dem Signieren **kanonisiert** (alphabetisch sortierte Keys), um deterministische Hashes zu garantieren. Pubkey-Länge (64 Hex) und Signatur-Länge (128 Hex) werden defensiv validiert.

### Rolling QR Security v3.1

Der Session-Seed wird mit `Random.secure()` (256 Bit kryptographisch sicher) erzeugt, nicht aus dem privaten Schlüssel abgeleitet. Der Base-Payload und der Session-Seed liegen in `FlutterSecureStorage` (hardware-geschützt), nicht in SharedPreferences.

### Backup-Verschlüsselung

Backups werden mit **AES-256** verschlüsselt. Der Schlüssel wird via **PBKDF2-HMAC-SHA256** mit 600.000 Iterationen und zufälligem 32-Byte-Salt aus dem Nutzerpasswort abgeleitet (OWASP-Empfehlung 2024). Der private Nostr-Schlüssel ist nur im verschlüsselten Teil des Backups enthalten.

### Device Integrity

Die App prüft beim Start auf Root-Indikatoren (su-Binaries, Magisk, Build-Tags) und Jailbreak-Merkmale. Kompromittierte Geräte erhalten eine Warnung, werden aber nicht blockiert — die kryptographische Sicherheit (SecureStorage, Nostr-Signaturen) bleibt die primäre Verteidigungslinie.

### Admin-Sicherheit

Der Admin-Status wird nicht einfach aus SharedPreferences geladen und vertraut. Nach dem Laden der Badges wird `reVerifyAdmin()` aufgerufen, das den Status kryptographisch gegen die tatsächlichen Badge-Signaturen und die Admin-Registry prüft. Nur der kryptographisch verifizierte Status (`isAdminCryptoVerified`) wird für sicherheitskritische Operationen verwendet.

### Durchgeführte Audits

Das Projekt hat mehrere Sicherheitsaudits durchlaufen, darunter adversariale Angriffsszenarien zum Reputation-Farming. Behobene Findings umfassen: Entfernung hardcodierter Secrets, Migration von SharedPreferences zu SecureKeyStore für alle Schlüssel, Absicherung gegen Admin-Injection über Backup-Restore, Behebung von Race Conditions in SecureKeyStore, Whitelist statt Blacklist in der Badge-Verifikation, und sichere Seed-Generierung für Rolling QR.

---

## Tech Stack

| Komponente | Technologie |
|---|---|
| Framework | Flutter 3.41+ / Dart 3.10+ |
| Kryptographie | BIP-340 Schnorr via `nostr` 1.5.0 |
| Hashing | `crypto` (SHA-256), `dbcrypt` (bcrypt) |
| Verschlüsselung | `encrypt` (AES-256) mit PBKDF2 |
| Secure Storage | `flutter_secure_storage` (Android Keystore / iOS Keychain) |
| NFC | `nfc_manager` 4.1.1 + `nfc_manager_ndef` |
| QR | `qr_flutter` + `mobile_scanner` |
| Blockchain-Daten | Mempool.space API (aktuelle Blockhöhe) |
| Design | Google Fonts (Rajdhani, Inconsolata), Bitcoin-Orange Theme |
| Plattformen | Android, iOS, Web (PWA), Linux, macOS, Windows |

---

## Projektstruktur

```
lib/
├── main.dart                          # App-Einstieg, Splash, Session-Check
├── theme.dart                         # Bitcoin-Orange Design-System (Rajdhani Font)
│
├── models/
│   ├── badge.dart                     # Badge v4 mit Claim-Binding + Proof-Hashes
│   ├── user.dart                      # Nutzerprofil mit kryptographischer Admin-Prüfung
│   ├── meetup.dart                    # Meetup-Datenmodell
│   └── calendar_event.dart            # Kalender-Events (iCal-Import)
│
├── screens/
│   ├── app_shell.dart                 # Hauptnavigation (BottomNav + Scan-FAB)
│   ├── intro.dart                     # Onboarding (Key-Generierung, Backup-Restore)
│   ├── badge_wallet.dart              # Badge-Sammlung mit Verifikationsstatus
│   ├── badge_details.dart             # Einzelansicht Badge + Krypto-Details
│   ├── meetup_verification.dart       # NFC/QR-Scanner + Badge-Claim
│   ├── nfc_writer.dart                # NFC-Tag beschreiben (Admin)
│   ├── rolling_qr_screen.dart         # Rolling QR generieren (Admin)
│   ├── meetup_session_wizard.dart     # Session-Setup für Organisatoren
│   ├── reputation_qr.dart            # Eigene Reputation als QR teilen
│   ├── reputation_verify_screen.dart  # Fremde Reputation prüfen
│   ├── qr_scanner.dart               # Universal-QR-Scanner
│   ├── profile_edit.dart              # Profil bearbeiten (Nickname, Nostr, Telegram)
│   ├── platform_proof_screen.dart     # Plattform-Verknüpfungen erstellen
│   ├── humanity_proof_screen.dart     # Lightning Humanity Proof
│   ├── admin_panel.dart               # Organisator-Werkzeuge
│   ├── admin_management.dart          # Admin-Verwaltung + Vouching
│   ├── calendar_screen.dart           # Meetup-Kalender (iCal)
│   ├── community_portal_screen.dart   # Links zu Community-Ressourcen
│   ├── relay_settings_screen.dart     # Nostr-Relay Konfiguration
│   └── radar.dart                     # Meetup-Radar (Umgebungssuche)
│
├── services/
│   ├── badge_security.dart            # Schnorr Sign/Verify v3.1 (Compact + Full)
│   ├── badge_claim_service.dart       # Claim-Binding (Kind 21002)
│   ├── trust_score_service.dart       # Score-Berechnung + Bootstrap-Phasen
│   ├── admin_registry.dart            # Web of Trust Admin-Registry v4
│   ├── admin_status_verifier.dart     # Kryptographische Admin-Prüfung
│   ├── vouching_service.dart          # Dezentrales Vouching + Distrust
│   ├── reputation_publisher.dart      # Relay-Publishing (Kind 30078)
│   ├── rolling_qr_service.dart        # Rolling QR Sessions v3.1
│   ├── secure_key_store.dart          # Android Keystore / iOS Keychain
│   ├── backup_service.dart            # AES-256 + PBKDF2 Backup
│   ├── nostr_service.dart             # Key-Generierung, Relay-Kommunikation
│   ├── platform_proof_service.dart    # Plattform-Verknüpfungen (Kind 21003)
│   ├── humanity_proof_service.dart    # Lightning Anti-Bot Proof
│   ├── social_graph_service.dart      # Nostr Follower/Following-Analyse
│   ├── zap_verification_service.dart  # Zap-Receipt Prüfung
│   ├── nip05_service.dart             # NIP-05 Internet-Identifikator
│   ├── device_integrity_service.dart  # Root/Jailbreak-Erkennung
│   ├── promotion_claim_service.dart   # Auto-Promotion Claims
│   ├── meetup_calendar_service.dart   # iCal-Feed Import
│   ├── relay_config.dart              # Relay-Verwaltung
│   ├── mempool.dart                   # Mempool.space API (Blockhöhe)
│   └── app_logger.dart                # Strukturiertes Logging
│
├── widgets/
│   ├── glass_card.dart                # Glasmorphism UI-Komponente
│   └── reputation_layers_widget.dart  # Visuelle Reputation-Darstellung
│
└── test/
    ├── badge_model_test.dart          # Badge-Serialisierung + Claim Tests
    ├── badge_security_test.dart       # Schnorr Sign/Verify Tests
    ├── trust_score_test.dart          # Score-Berechnung Tests
    └── widget_test.dart               # Widget Tests
```

---

## Quickstart

### Voraussetzungen

Flutter SDK 3.41+ und Dart 3.10+ müssen installiert sein. Für Android-Builds wird Java 17 und das Android SDK benötigt.

### Build

```bash
# Repository klonen
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App

# Dependencies installieren
flutter pub get

# Debug-Build starten
flutter run

# Release-APK bauen
flutter build apk --release

# Oder über das Build-Script
chmod +x quick-build.sh
./quick-build.sh
```

Die fertige APK liegt unter `build/app/outputs/flutter-apk/app-release.apk`.

### Erster Start

1. App öffnen → Nickname vergeben
2. Ein Nostr-Keypair wird automatisch im Hintergrund generiert
3. Dashboard öffnet sich → Scan-Button in der Mitte antippen
4. Beim nächsten Meetup: NFC-Tag oder QR-Code scannen → Erstes Badge erhalten

---

## Nostr Event Kinds

| Kind | Zweck |
|------|-------|
| 21000 | Badge-Signatur (Organisator signiert Meetup-Tag) |
| 21002 | Badge-Claim (Teilnehmer bindet Badge an sich) |
| 21003 | Distrust-Meldung / Platform-Proof |
| 30078 | Reputation-Event (Replaceable, `d`-Tag: `einundzwanzig-reputation` / `einundzwanzig-admins`) |

---

## Datenschutz

Die App folgt dem Prinzip **Privacy by Design**:

Was lokal bleibt: Private Schlüssel (Android Keystore / iOS Keychain), Meetup-Namen und -Daten, Besuchshistorie, persönliche Details.

Was auf Relays publiziert wird: Aggregierte Zahlen (Anzahl Badges, verschiedene Meetups, verschiedene Signer, Account-Alter), Trust Level, Badge-Proof-Hash (beweist Besitz ohne Details zu verraten), optional Plattform-Verknüpfungen.

Was nirgendwo gespeichert wird: IP-Adressen, Geräte-IDs, Standortdaten, Zahlungsdetails.

---

## Lizenz

[MIT](LICENSE)

---

## Links

- **Repository:** [github.com/louisthecat86/Einundzwanzig-Meetup-App](https://github.com/louisthecat86/Einundzwanzig-Meetup-App)
- **Einundzwanzig Portal:** [portal.einundzwanzig.space](https://portal.einundzwanzig.space)
- **Einundzwanzig Telegram:** [t.me/einundzwanzig](https://t.me/einundzwanzig)
