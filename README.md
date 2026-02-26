# Einundzwanzig Meetup App

**Kryptographisch verifizierbare Reputation für die Bitcoin-Community — ohne Server, ohne KYC, ohne Vertrauen.**

Eine Flutter-Applikation, die Meetup-Teilnahme über NFC-Tags und QR-Codes erfasst, jeden Besuch mit einer Schnorr-Signatur (BIP-340) versiegelt und daraus einen Trust Score berechnet. Alles läuft lokal auf dem Gerät, alles ist verifizierbar, alles ist Open Source.

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.7+-blue)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Nostr](https://img.shields.io/badge/Nostr-NIP--01%20%7C%20BIP--340-purple)](https://github.com/nostr-protocol/nips)

---

## Inhaltsverzeichnis

1. [Das Problem und die Lösung](#das-problem-und-die-lösung)
2. [Kernkonzept in 60 Sekunden](#kernkonzept-in-60-sekunden)
3. [Architekturübersicht](#architekturübersicht)
4. [Die kryptographische Kette](#die-kryptographische-kette)
5. [Badge-System](#badge-system)
6. [Trust Score](#trust-score)
7. [Admin-System und Web of Trust](#admin-system-und-web-of-trust)
8. [Rolling QR-Code](#rolling-qr-code)
9. [Identitätsschichten (Reputation Layers)](#identitätsschichten-reputation-layers)
10. [Backup und Wiederherstellung](#backup-und-wiederherstellung)
11. [Schlüsselmanagement und Sicherheit](#schlüsselmanagement-und-sicherheit)
12. [Reputation Publishing](#reputation-publishing)
13. [Screens und Navigation](#screens-und-navigation)
14. [Datenmodelle](#datenmodelle)
15. [Services im Detail](#services-im-detail)
16. [Externe APIs und Abhängigkeiten](#externe-apis-und-abhängigkeiten)
17. [Installation und Build](#installation-und-build)
18. [Kryptographie-Referenz](#kryptographie-referenz)

---

## Das Problem und die Lösung

### Das Problem

Beim Peer-to-Peer Bitcoin-Handel (z.B. auf Satoshi-Kleinanzeigen, in Telegram-Gruppen oder bei Meetups) fehlt ein vertrauenswürdiger Mechanismus, um die Seriosität des Gegenübers einzuschätzen. Zentrale Bewertungssysteme (eBay, Amazon) benötigen eine zentrale Instanz, KYC-Verifizierung widerspricht dem Bitcoin-Grundgedanken, und pseudonyme Identitäten sind leicht zu fälschen.

### Die Lösung

Physische Anwesenheit bei Bitcoin-Meetups dient als Vertrauensbeweis. Die App erzeugt für jeden Meetup-Besuch ein kryptographisch signiertes **Badge** — ein unfälschbares Zertifikat, das beweist: „Diese Person war zu einem bestimmten Zeitpunkt physisch bei einem bestimmten Meetup." Aus der Summe dieser Badges entsteht eine verifizierbare Reputation, die per QR-Code bei P2P-Trades vorgezeigt und von jedem geprüft werden kann.

---

## Kernkonzept in 60 Sekunden

1. Ein **Meetup-Organisator** legt einen NFC-Tag auf den Tisch oder zeigt einen Rolling QR-Code auf seinem Handy.
2. Jeder **Teilnehmer** scannt ihn mit der App und erhält ein **Badge** — ein kryptographisch signiertes Nostr-Event (Kind 21000) mit Schnorr-Signatur des Organisators.
3. Das Badge enthält einen **Bitcoin-Block-Height** als unmanipulierbaren Zeitbeweis (verifizierbar auf mempool.space).
4. Der Teilnehmer erstellt zusätzlich eine **Claim-Signatur** (Kind 21002), die das Badge kryptographisch an seine Identität bindet.
5. Aus allen gesammelten Badges berechnet die App einen **Trust Score**, der Diversität, Regelmäßigkeit und Alter berücksichtigt.
6. Die Reputation wird als Nostr-Event (Kind 30078) auf Relays publiziert und kann von jedem verifiziert werden.

---

## Architekturübersicht

### Ordnerstruktur

```
lib/
├── main.dart                       # App-Entry, SplashScreen, Session-Check, Key-Migration
├── theme.dart                      # Material Design 3 (Dark Theme, Bitcoin-Orange Akzent)
│
├── models/
│   ├── user.dart                   # UserProfile (Nickname, npub, Admin-Status, Home-Meetup)
│   ├── badge.dart                  # MeetupBadge v4 mit Dual-Signatur (Organisator + Claim)
│   ├── meetup.dart                 # Meetup-Daten (Stadt, Land, Telegram, Koordinaten)
│   └── calendar_event.dart         # Kalender-Events (ICS-Parsing)
│
├── screens/                        # 25 Screens (siehe Abschnitt "Screens und Navigation")
│
├── services/                       # 18 Services (siehe Abschnitt "Services im Detail")
│
└── widgets/
    └── reputation_layers_widget.dart  # Visuelle Darstellung der Identitätsschichten
```

### Datenfluss

```
                    portal.einundzwanzig.space
                              │
                    Meetup-Liste (JSON API)
                              │
                              ▼
┌──────────────────────────────────────────────┐
│                    APP                       │
│                                              │
│   flutter_secure_storage (Hardware-Schutz)   │
│   ├── Nostr Private Key (nsec)               │
│   ├── Nostr Public Key (npub)                │
│   └── Private Key Hex                        │
│                                              │
│   SharedPreferences (Klartext)               │
│   ├── User Profile (Nickname, ...)           │
│   ├── Badges (signierte JSON-Objekte)        │
│   ├── Admin Registry Cache (WoT)             │
│   ├── Bootstrap Sunset Flag                  │
│   ├── Rolling QR Session                     │
│   ├── Platform Proofs                        │
│   ├── Humanity Proof Status                  │
│   └── Relay-Konfiguration                    │
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
```

---

## Die kryptographische Kette

Jedes Badge durchläuft eine vollständige kryptographische Verifikationskette:

### Schritt 1: Organisator signiert (Tag-Erstellung)

Der Organisator erstellt einen kompakten Payload, der auf einen NFC-Tag passt (~285 Bytes):

```json
{
  "v": 2,          // Signatur-Version
  "t": "B",        // Typ: Badge
  "m": "city-cc",  // Meetup-ID
  "b": 879432,     // Bitcoin Block Height
  "x": 1739927280, // Ablaufzeitpunkt (Unix)
  "c": 1739905680, // Erstellungszeitpunkt (createdAt des Nostr-Events)
  "p": "64hex...",  // Public Key des Organisators (32 Bytes)
  "s": "128hex..."  // Schnorr-Signatur (64 Bytes)
}
```

Der Content (`v`, `t`, `m`, `b`, `x`) wird als Nostr-Event (Kind 21000) signiert. Die JSON-Keys werden vor dem Signieren **alphabetisch sortiert** (Kanonisierung), um deterministisches Hashing zu gewährleisten.

### Schritt 2: Teilnehmer scannt (Badge-Empfang)

Die App des Teilnehmers führt folgende Prüfungen durch:

1. **Ablauf-Check**: Ist `x` (expires_at) in der Zukunft?
2. **Rolling Nonce** (nur bei QR): Ist der Zeitschritt aktuell? (±10 Sekunden Toleranz)
3. **Event-Rekonstruktion**: Aus dem Payload wird das Nostr-Event rekonstruiert
4. **SHA-256 Hash**: Der Event-Hash wird berechnet
5. **Schnorr-Verifikation**: `verify(pubkey, event_id, sig)` → Beweis, dass genau dieser Organisator signiert hat
6. **Admin-Registry-Check**: Ist der Signer ein bekannter, vertrauenswürdiger Organisator?

### Schritt 3: Claim-Binding (Identitätsbindung)

Nach erfolgreicher Verifikation erstellt die App automatisch eine **Claim-Signatur** (Nostr Kind 21002):

```json
{
  "action": "claim_badge",
  "org_sig": "...",        // Referenz zur Organisator-Signatur
  "org_event_id": "...",   // Event-ID des Badge-Events
  "org_pubkey": "...",     // Pubkey des Organisators
  "block_height": 879432,
  "claimed_at": 1739905700
}
```

Damit ist das Badge kryptographisch an den Sammler gebunden. Ohne Claim-Signatur zählt ein Badge **nicht** für die Reputation.

### Schritt 4: Verifizierung durch Dritte

Ein Verifizierer prüft:
- Die Organisator-Signatur (BIP-340 Schnorr)
- Die Claim-Signatur des Sammlers
- Den `badge_proof_hash` (SHA-256 über alle gebundenen Badges)
- Ob der Signer in der Admin-Registry steht

---

## Badge-System

### Badge-Modell (v4)

Jedes Badge (`MeetupBadge`) hat zwei Signaturen:

| Feld | Beschreibung |
|------|-------------|
| `sig` | Schnorr-Signatur des Organisators (128 Hex-Zeichen) |
| `sigId` | Nostr Event-ID (SHA-256 Hash, 64 Hex-Zeichen) |
| `adminPubkey` | Hex-Pubkey des Organisators (64 Hex-Zeichen) |
| `sigVersion` | 1 = Legacy (HMAC, unsicher), 2 = Nostr (Schnorr) |
| `sigContent` | Der signierte Content (für Re-Verifikation) |
| `claimSig` | Schnorr-Signatur des Sammlers |
| `claimEventId` | Event-ID des Claim-Events |
| `claimPubkey` | Hex-Pubkey des Sammlers |
| `claimTimestamp` | Unix-Timestamp des Claims |
| `isRetroactive` | true = nachträglich geclaimed (reduzierter Wert) |

Zusätzlich: `meetupName`, `date`, `blockHeight`, `delivery` (nfc/rolling_qr), `meetupEventId`.

### Zwei Auslieferungswege

| Methode | Anti-Screenshot | Offline | Kosten |
|---------|----------------|---------|--------|
| **NFC-Tag** (NTAG215) | Physisch vor Ort nötig | Kein Internet nötig | ~0,50 € |
| **Rolling QR** | Ändert sich alle 10s | Braucht Internet | Kostenlos |

### Badge Proof Hash (Datenschutzkonform)

Die App erzeugt einen `badge_proof_hash` (SHA-256), der beweist, welche Badges für die Reputation verwendet wurden, **ohne** die Meetup-Namen, Orte oder Daten zu verraten. Nur gebundene Badges (mit Claim-Signatur) werden einbezogen.

### Legacy v1 Badges

Ältere Badges mit Signatur-Version 1 nutzen ein HMAC-Shared-Secret. Diese sind als **unsicher** markiert, da das Secret im Quellcode steht. Die App zeigt sie als "Legacy — nicht vertrauenswürdig" an. Neue Badges verwenden ausschließlich Schnorr/BIP-340.

---

## Trust Score

### Berechnungsalgorithmus

Der Trust Score wird lokal berechnet und berücksichtigt mehrere Faktoren:

**Einzelner Badge-Wert:**
```
badge_value = base × co_attestor_bonus × signer_bonus × decay_factor
```

- **Co-Attestor Bonus**: `log₂(teilnehmer + 1)` — Ein gut besuchtes Meetup zählt mehr
- **Signer Bonus**: `1.0 + (veteran_count × 0.3)` — Badges von vertrauenswürdigen Signern wiegen schwerer
- **Time Decay**: `0.5^(alter_wochen / 26)` — Halbwertszeit von 26 Wochen (~6 Monate)
- **Frequency Cap**: Maximal 2 Badges pro Woche zählen (Anti-Farming)

**Aggregierte Scores:**
- **Maturity**: `min(1.0, account_alter_tage / 180)` — Ältere Accounts sind vertrauenswürdiger
- **Diversity**: `log₂(unique_meetups + 1) × log₂(unique_signers + 1)` — Verschiedene Meetups und Organisatoren
- **Quality**: Durchschnittlicher Signer-Bonus
- **Activity**: Summe aller Badge-Werte

**Gesamtscore:**
```
total = activity × (1 + maturity) × (1 + diversity × 0.1)
```

### Trust Level

| Score | Level | Bedeutung |
|-------|-------|-----------|
| ≥ 40 | VETERAN | Langfristig etabliertes Community-Mitglied |
| ≥ 20 | ETABLIERT | Regelmäßiger Meetup-Besucher |
| ≥ 10 | AKTIV | Aktives Community-Mitglied |
| ≥ 3 | STARTER | Erste Badges gesammelt |
| < 3 | NEU | Neuer Nutzer |

### Sybil-Erkennung

Die App erkennt verdächtige Muster automatisch:

- Alle Badges von nur einem einzigen Signer
- Mehr als 3 Badges an einem einzigen Tag
- Kein Badge hat Co-Attestors (andere Teilnehmer am selben Meetup)

---

## Admin-System und Web of Trust

Das Admin-System durchläuft drei autonome Phasen:

### Phase 1: Bootstrap (Keimphase)

Ein **hartcodierter Super-Admin** (der Entwickler) delegiert die ersten Organisatoren ("Seed-Admins"). Die Admin-Liste wird als signiertes Nostr-Event (Kind 30078, d-Tag: `einundzwanzig-admins`) auf Relays publiziert.

Schwellenwerte in der Keimphase sind niedrig: 3 Badges, 2 Meetups, 1 Signer, 14 Tage Account-Alter.

### Phase 2: Wachstum

Mit 2–5 aktiven Signern steigen die Anforderungen: 4 Badges, 3 Meetups, 2 Signer, 30 Tage.

### Phase 3: Bootstrap Sunset (Dezentralisierung)

Sobald das Netzwerk **20 verifizierte Organisatoren** erreicht, wird der "Sunset" **irreversibel aktiviert**:

- Der Super-Admin verliert seinen Sonderstatus dauerhaft
- Das Flag `bootstrap_permanently_sunset` wird gesetzt und nie wieder zurückgesetzt
- Ab jetzt wächst das Netzwerk rein über Peer-to-Peer-Mechanismen

### Auto-Promotion (Proof of Reputation)

Nutzer, die die Schwellenwerte erreichen (abhängig von der aktuellen Bootstrap-Phase), werden **automatisch** zum Organisator befördert. Die App:

1. Erkennt die Schwellenwert-Erfüllung im Trust Score
2. Setzt den Admin-Status lokal
3. Publiziert einen "Admin Claim" (Kind 21004) auf Nostr-Relays mit den Badge-Beweisen
4. Andere App-Instanzen laden und verifizieren diese Claims mathematisch

### Peer-to-Peer Vouching (Ritterschlag)

Etablierte Organisatoren können neue Co-Admins manuell bürgen: Sie scannen den npub (QR-Code) des neuen Organisators und veröffentlichen eine kryptographische Bürgschaft auf den Nostr-Relays. Das Admin-Management-Screen bietet dafür eine dedizierte UI.

### Admin-Registry Caching

Die Admin-Liste wird lokal gecacht (offline-fähig). Bei jedem App-Start wird im Hintergrund ein Relay-Update angestoßen. Der Cache wird mit den Relay-Daten zusammengeführt.

---

## Rolling QR-Code

### Problem

Wie verhindert man, dass jemand ein Foto vom QR-Code macht und es an jemanden schickt, der nicht vor Ort ist?

### Lösung

Der QR-Code ändert sich alle **10 Sekunden**. Jeder Code enthält den originalen (einmalig signierten) Badge-Payload plus eine **HMAC-Nonce**, die auf Aktualität geprüft wird.

### Technische Details

1. **Session-Start**: Der Organisator startet eine 6-Stunden-Session für ein bestimmtes Meetup
2. **Session-Seed**: 256 Bit kryptographisch sicherer Zufall (CSPRNG via `Random.secure()`)
3. **Base-Payload**: Wird einmalig mit Schnorr signiert (über `BadgeSecurity.signCompact()`)
4. **Rolling Nonce**: Alle 10 Sekunden wird eine neue HMAC-SHA256-Nonce berechnet: `HMAC(seed, zeitschritt)`
5. **QR-Payload**: `base_payload + { "n": nonce, "ts": zeitschritt }`
6. **Validierung beim Scanner**: Prüft ob der Zeitschritt aktuell ist (±1 Intervall Toleranz = max 20 Sekunden)

Die eigentliche Sicherheit kommt von der Schnorr-Signatur des Base-Payloads und dem Ablaufzeitpunkt. Der Scanner kann die HMAC-Nonce nicht kryptographisch verifizieren (er kennt den Seed nicht), prüft aber die Zeitnähe.

### Session-Persistenz

Die Session überlebt App-Neustarts: Seed, Start-/Ablaufzeit, Meetup-Daten und der signierte Base-Payload werden in SharedPreferences gespeichert.

---

## Identitätsschichten (Reputation Layers)

Die Reputation besteht aus mehreren unabhängigen Ebenen, die zusammen ein Gesamtbild ergeben:

### Layer 1: Meetup-Badges

Physische Anwesenheitsnachweise, kryptographisch signiert. Dies ist die Kernfunktion der App.

### Layer 2: Humanity Proof (Lightning Anti-Bot)

Die App prüft, ob der Nutzer **jemals einen echten Nostr-Zap** (Lightning-Zahlung) gesendet oder empfangen hat. Dafür werden Zap-Receipts (Kind 9735) und Zap-Requests (Kind 9734) auf Nostr-Relays gesucht.

Ein einziges Receipt reicht als Beweis:
- Der Nutzer besitzt eine echte Lightning-Wallet
- Er hat echte Sats ausgegeben
- Die Zahlung ist kryptographisch verifizierbar

Wem er gezappt hat, ist irrelevant. Die App speichert nur: `humanity_verified: true, method: lightning_zap, first_zap_at: timestamp`.

### Layer 3: NIP-05 Verifikation

Die App ruft das Nostr-Profil (Kind 0) des Nutzers von Relays ab und prüft den NIP-05 Identifier. Domain-Typen werden unterschiedlich gewichtet:

| Domain-Typ | Score | Beispiel |
|-----------|-------|---------|
| Community | 1.0 | einundzwanzig.space |
| Eigene Domain | 0.7 | dein-name.de |
| Public Provider | 0.3 | nostrplebs.com |

### Layer 4: Plattform-Proofs

Nutzer können ihre Accounts auf externen Plattformen (Satoshi-Kleinanzeigen, Telegram, RoboSats, Nostr) kryptographisch an ihren npub binden. Dafür wird ein signierter Verify-String erzeugt:

```
21rep::npub1abc...::satoshikleinanzeigen::username::sig=hex...
```

Dieser String wird als signiertes Nostr-Event (Kind 21003) erstellt. Der Nutzer kopiert ihn in sein Plattform-Profil. Verifizierer können die Schnorr-Signatur prüfen und den Username-Match bestätigen.

### Layer 5: Social Graph

Die App analysiert die Nostr-Follow-Listen (Kind 3) und prüft, ob der Nutzer von bekannten Community-Mitgliedern gefolgt wird. Folgen von bekannten Organisatoren wiegen besonders schwer.

---

## Backup und Wiederherstellung

### Export

Die App exportiert ein verschlüsseltes Backup als `.21bkp`-Datei:

1. **Profildaten**: Nickname, Telegram, Twitter, Home-Meetup, Admin-Status
2. **Alle Badges**: Inklusive aller kryptographischen Beweise (Signaturen, Event-IDs)
3. **Nostr-Keypair**: nsec, npub, privHex (sensibel!)
4. **Admin-Registry**: Lokaler Cache aller bekannten Organisatoren

### Verschlüsselung

- **Schlüsselableitung**: PBKDF2-SHA256 mit hoher Iterationsanzahl (100.000 Runden)
- **Verschlüsselung**: AES-256-GCM
- **Salt und IV**: Werden zufällig generiert und im Backup-Header gespeichert
- **Ohne Passwort kein Restore** — es gibt keine Hintertür

### Import

Beim Restore werden alle Daten wiederhergestellt, inklusive der Nostr-Keys in den SecureKeyStore (Hardware-geschützt).

---

## Schlüsselmanagement und Sicherheit

### SecureKeyStore

Private Schlüssel werden **niemals** im Klartext in SharedPreferences gespeichert. Der `SecureKeyStore` nutzt:

- **Android**: `EncryptedSharedPreferences` (API 23+) mit Android Keystore Backend. Auf älteren Geräten (API < 23): AES-Verschlüsselung mit RSA-wrapped Key im Android Keystore.
- **iOS**: iOS Keychain mit `kSecAttrAccessibleWhenUnlocked`

### Key-Migration

Beim ersten App-Start nach einem Update werden vorhandene Klartext-Keys aus SharedPreferences automatisch in den SecureKeyStore migriert und anschließend aus SharedPreferences gelöscht. Die Migration wird über ein Flag als erledigt markiert.

### Schlüssel-Generierung und Import

- **Neue Keys**: `Keychain.generate()` erzeugt ein secp256k1-Keypair, das als npub/nsec (Bech32) gespeichert wird
- **Import**: Der Nutzer kann seinen bestehenden nsec eingeben; der öffentliche Schlüssel wird daraus abgeleitet

---

## Reputation Publishing

### Automatisches Relay-Publishing

Nach jedem Badge-Scan wird die Reputation automatisch im Hintergrund auf Nostr-Relays aktualisiert. Das geschieht als **Parameterized Replaceable Event** (Kind 30078, d-Tag: `einundzwanzig-reputation`), das sich bei jedem Update selbst überschreibt.

### Datenschutz

Auf den Relays landen **nur aggregierte Zahlen**:

- Trust Score, Anzahl Badges, Unique Meetups, Unique Signers
- Account-Alter, Bridge Score
- `badge_proof_hash` (kryptographischer Beweis ohne Details)
- Plattform-Proofs (nur wenn vom Nutzer explizit erstellt)
- Humanity-Proof-Status

**Nicht** publiziert werden: Meetup-Namen, Besuchsdaten, Orte, Teilnehmer.

### Spam-Schutz

Zwischen zwei Publishes müssen mindestens 5 Minuten liegen. Change-Detection verhindert unnötige Updates.

### Relay-Konfiguration

Die App nutzt standardmäßig vier Relays: `relay.damus.io`, `nos.lol`, `relay.nostr.band`, `nostr.einundzwanzig.space`. Der Nutzer kann über den Relay-Settings-Screen eigene Relays hinzufügen oder Default-Relays deaktivieren.

---

## Screens und Navigation

### App-Start und Onboarding

| Screen | Datei | Funktion |
|--------|-------|----------|
| **SplashScreen** | `main.dart` | Key-Migration, Session-Check, Routing zu Intro oder Dashboard |
| **IntroScreen** | `intro.dart` | Onboarding für neue Nutzer: Erklärung des Konzepts |
| **ProfileEditScreen** | `profile_edit.dart` | Profil erstellen/bearbeiten: Nickname, Nostr-Key generieren/importieren, Home-Meetup wählen, nsec-Backup |

### Hauptnavigation

| Screen | Datei | Funktion |
|--------|-------|----------|
| **DashboardScreen** | `dashboard.dart` | Zentrale Übersicht: Trust Score, Badge-Zähler, Identity Layers, aktive Session, Feature-Kacheln, Auto-Promotion |
| **BadgeWalletScreen** | `badge_wallet.dart` | Alle gesammelten Badges mit Filter- und Sortieroptionen |
| **BadgeDetailsScreen** | `badge_details.dart` | Einzelnes Badge mit allen kryptographischen Details, Signatur-Verifikation, Claim-Status |

### Badge-Empfang

| Screen | Datei | Funktion |
|--------|-------|----------|
| **MeetupVerificationScreen** | `meetup_verification.dart` | NFC-Scan und QR-Scan zum Badge-Empfang; Signatur-Verifikation, Claim-Binding, Admin-Check |
| **QRScannerScreen** | `qr_scanner.dart` | Universeller QR-Scanner (für Badges, Vouching, Reputation-Verifikation) |

### Admin-Funktionen

| Screen | Datei | Funktion |
|--------|-------|----------|
| **AdminPanelScreen** | `admin_panel.dart` | Admin-Dashboard: NFC-Tag beschreiben, Rolling QR starten, Meetup-Session verwalten |
| **MeetupSessionWizard** | `meetup_session_wizard.dart` | Schritt-für-Schritt-Assistent zum Starten einer Meetup-Session |
| **MeetupSelectionScreen** | `meetup_selection.dart` | Meetup-Auswahl für neue Session oder Badge-Erstellung |
| **NFCWriterScreen** | `nfc_writer.dart` | NFC-Tags mit signiertem Badge-Payload beschreiben |
| **RollingQRScreen** | `rolling_qr_screen.dart` | Rolling QR-Code anzeigen (ändert sich alle 10s) |
| **AdminManagementScreen** | `admin_management.dart` | Web of Trust verwalten: P2P Vouching, Admin-Liste, Sunset-Status |

### Reputation und Verifikation

| Screen | Datei | Funktion |
|--------|-------|----------|
| **ReputationQRScreen** | `reputation_qr.dart` | Reputation als QR-Code teilen (JSON mit Checksumme), Text-Export, Relay-Publishing |
| **ReputationVerifyScreen** | `reputation_verify_screen.dart` | Reputation eines anderen Nutzers prüfen (QR-Scan oder npub-Eingabe) |
| **HumanityProofScreen** | `humanity_proof_screen.dart` | Lightning Zap-Beweis prüfen und Status anzeigen |
| **PlatformProofScreen** | `platform_proof_screen.dart` | Plattform-Proofs erstellen und verwalten |

### Meetup-Entdeckung

| Screen | Datei | Funktion |
|--------|-------|----------|
| **RadarScreen** | `radar.dart` | Meetup-Karte mit Live-Daten von portal.einundzwanzig.space |
| **EventsScreen** | `events.dart` | Meetup-Liste zum Durchsuchen |
| **MeetupDetailsScreen** | `meetup_details.dart` | Einzelnes Meetup: Logo, Links, Telegram, Twitter, Nostr |
| **MeetupListScreen** | `meetup_list_screen.dart` | Listenansicht aller verfügbaren Meetups |
| **CalendarScreen** | `calendar_screen.dart` | Meetup-Kalender (ICS-Feed von portal.einundzwanzig.space) |
| **CreateMeetupScreen** | `create_meetup.dart` | Neues Meetup erstellen |

### Einstellungen

| Screen | Datei | Funktion |
|--------|-------|----------|
| **RelaySettingsScreen** | `relay_settings_screen.dart` | Nostr-Relays verwalten: Defaults an/aus, Custom-Relays hinzufügen/entfernen |
| **MarketScreen** | `market.dart` | Marktplatz-Integration (Placeholder) |
| **POSScreen** | `pos.dart` | Point of Sale (Placeholder) |

---

## Datenmodelle

### UserProfile (`models/user.dart`)

Speichert das Nutzerprofil in SharedPreferences. Felder: `nickname`, `fullName`, `telegramHandle`, `nostrNpub`, `twitterHandle`, `isNostrVerified`, `isAdminVerified`, `isAdmin`, `homeMeetupId`, `hasNostrKey`, `promotionSource` (trust_score / seed_admin / leer).

Beim Laden wird der npub prioritär aus dem SecureKeyStore genommen (falls ein Keypair existiert).

### MeetupBadge (`models/badge.dart`)

Siehe [Badge-System](#badge-system). Unterstützt Serialisierung zu/von JSON, Persistenz über SharedPreferences, und eine `withClaim()`-Methode zum Hinzufügen der Claim-Daten.

### Meetup (`models/meetup.dart`)

Meetup-Daten mit Geo-Koordinaten, Social-Media-Links und Cover-Bild. Wird über die API von portal.einundzwanzig.space geladen. Fallback-Meetups (München, Hamburg, Berlin) für Offline-Betrieb.

### CalendarEvent (`models/calendar_event.dart`)

Kalender-Events aus dem ICS-Feed. Robustes Datum-Parsing mit Fallback-Logik für verschiedene Datumsformate.

---

## Services im Detail

### BadgeSecurity (`services/badge_security.dart`)

Kernservice für alle kryptographischen Operationen:

- `signCompact()` — Erstellt Schnorr-signiertes Kompakt-Payload für NFC-Tags
- `verifyCompact()` — Verifiziert Kompakt-Payloads mit **Whitelist** (nur bekannte Content-Felder `v, t, m, b, x`)
- `verify()` — Allgemeine Nostr-Event-Verifikation
- `canonicalJsonEncode()` — JSON-Kanonisierung (alphabetisch sortierte Keys)
- `signLegacy()` / `verifyLegacy()` — Legacy v1 HMAC (veraltet, nur Rückwärtskompatibilität)
- Pubkey/Signatur-Formatvalidierung (64 bzw. 128 Hex-Zeichen)

### RollingQRService (`services/rolling_qr_service.dart`)

Session-Management und Rolling Nonce:

- `getOrCreateSession()` — Startet oder lädt eine 6-Stunden-Session
- `generateRollingPayload()` — Erzeugt QR-Payload mit aktueller HMAC-Nonce
- `validateNonce()` — Prüft Nonce-Aktualität (±1 Intervall)
- `getBasePayload()` — Gibt den statischen, signierten Base-Payload zurück (für NFC)
- Session-Seed: 256 Bit CSPRNG (keine Ableitung vom Private Key)

### TrustScoreService (`services/trust_score_service.dart`)

Berechnet den Trust Score (siehe [Trust Score](#trust-score)):

- Bootstrap-Phasen-Erkennung (Keimphase / Wachstum / Stabil)
- Badge-Wert-Berechnung mit Co-Attestor-Bonus, Signer-Bonus, Time Decay
- Frequency Cap (max 2 Badges/Woche)
- Auto-Promotion-Check mit phasenabhängigen Schwellenwerten
- Bridge Score (Verbindung verschiedener Meetup-Cluster)
- Sybil-Erkennungsmuster

### AdminRegistry (`services/admin_registry.dart`)

Web of Trust für die Organisatoren-Verwaltung:

- `checkAdmin()` — Prüft ob ein npub ein bekannter Admin ist (Cache → Relay → Super-Admin)
- `checkAdminByPubkey()` — Prüfung per Hex-Pubkey
- `fetchFromRelays()` — Lädt Admin-Listen von Nostr-Relays (Phase-abhängig: Bootstrap nur Super-Admin, Sunset alle bekannten Admins)
- `isSunsetActive()` — Prüft und setzt den irreversiblen Sunset-Status
- `addAdmin()` / `removeAdmin()` / `getAdminList()` — Lokale Registry-Verwaltung
- `publishAdminList()` — Publiziert die eigene Admin-Liste als Nostr-Event

### BadgeClaimService (`services/badge_claim_service.dart`)

Identitätsbindung für Badges:

- `createClaim()` — Erstellt Schnorr-signierte Claim-Signatur (Kind 21002)
- `verifyClaim()` — Prüft Claim-Gültigkeit (Signatur + Referenz-Match)
- `claimUnboundBadges()` — Retroaktives Claiming aller ungebundenen Badges
- `ensureBadgesClaimed()` — Wird beim App-Start aufgerufen

### NostrService (`services/nostr_service.dart`)

Schlüssel-Management:

- `generateKeyPair()` — Neues secp256k1-Keypair erzeugen
- `importNsec()` — Bestehenden nsec importieren
- `loadKeys()` / `hasKey()` / `getNpub()` — Schlüssel abrufen
- `sign()` — Schnorr-Signatur über beliebige Daten
- `verify()` — Signatur-Verifikation
- `shortenNpub()` / `npubToHex()` — Hilfsfunktionen

### SecureKeyStore (`services/secure_key_store.dart`)

Hardware-verschlüsselte Schlüsselverwaltung:

- `ensureMigrated()` — Einmalige Migration von SharedPreferences zu SecureStorage
- `saveKeys()` / `getNsec()` / `getNpub()` / `getPrivHex()` / `loadKeys()` / `hasKey()` / `deleteKeys()`
- Android: EncryptedSharedPreferences
- iOS: Keychain

### ReputationPublisher (`services/reputation_publisher.dart`)

Automatisches Relay-Publishing:

- `publish()` — Erstellt und sendet Reputation-Event (Kind 30078) an alle aktiven Relays
- `publishInBackground()` — Non-blocking Hintergrund-Publishing
- `fetchByNpub()` — Lädt Reputation-Event eines anderen Nutzers von Relays
- Change-Detection und Spam-Schutz (min. 5 Minuten zwischen Publishes)

### PromotionClaimService (`services/promotion_claim_service.dart`)

Dezentrale Organisator-Beförderung:

- `publishAdminClaim()` — Publiziert Badge-Beweise als Admin-Claim (Kind 21004)
- `syncOrganicAdmins()` — Lädt und verifiziert Claims von Relays
- Mathematische Verifikation: Prüft Badge-Signaturen gegen bekannte Admin-Pubkeys, Schwellenwert-Check

### BackupService (`services/backup_service.dart`)

Verschlüsselter Export/Import:

- `exportBackup()` — AES-256-GCM verschlüsselter JSON-Export (.21bkp)
- `importBackup()` — Entschlüsselung und Wiederherstellung aller Daten
- PBKDF2-SHA256 Key-Derivation mit 100.000 Iterationen

### HumanityProofService (`services/humanity_proof_service.dart`)

Lightning Anti-Bot-Mechanismus:

- `checkForZaps()` — Sucht auf Relays nach Kind 9735 (Zap Receipts) und Kind 9734 (Zap Requests)
- `getStatus()` — Lokaler Cache-Status
- `verifyReceiptExists()` — Remote-Verifikation eines spezifischen Receipts

### PlatformProofService (`services/platform_proof_service.dart`)

Plattform-Account-Verknüpfung:

- `createProof()` — Erzeugt signierten Verify-String (Kind 21003)
- `verifyProofString()` — Parst und verifiziert einen Verify-String (Signatur + Username-Match + Relay-Check)
- Unterstützte Plattformen: Satoshi-Kleinanzeigen, Telegram, RoboSats, Nostr, Custom

### Nip05Service (`services/nip05_service.dart`)

NIP-05 Identifier-Verifikation:

- `verify()` — Prüft NIP-05 gegen die `.well-known/nostr.json` der Domain
- `fetchNip05FromProfile()` — Lädt NIP-05 aus dem Nostr-Profil (Kind 0)
- Domain-Typ-Erkennung (Community / Custom / Public Provider)

### SocialGraphService (`services/social_graph_service.dart`)

Nostr Social-Graph-Analyse:

- Lädt Follow-Listen (Kind 3) und prüft Überschneidungen mit bekannten Community-Mitgliedern

### ZapVerificationService (`services/zap_verification_service.dart`)

Verifiziert Nostr-Zaps für erweiterte Reputation-Daten.

### MeetupService (`services/meetup_service.dart`)

API-Anbindung an portal.einundzwanzig.space:

- `fetchMeetups()` — Lädt die aktuelle Meetup-Liste als JSON
- Fallback auf lokale Daten bei Netzwerkfehlern

### MeetupCalendarService (`services/meetup_calendar_service.dart`)

ICS-Kalender-Integration:

- `fetchMeetups()` — Lädt und parst den ICS-Feed von portal.einundzwanzig.space/stream-calendar

### MempoolService (`services/mempool.dart`)

Bitcoin Block-Height als Zeitbeweis:

- `getBlockHeight()` — Aktuelle Block-Height von mempool.space API

### RelayConfig (`services/relay_config.dart`)

Zentrale Relay-Verwaltung:

- `getActiveRelays()` — Gibt alle aktiven Relays zurück (Defaults + Custom)
- Custom-Relays hinzufügen/entfernen
- Default-Relays aktivieren/deaktivieren

---

## Externe APIs und Abhängigkeiten

### APIs

| API | Endpunkt | Zweck |
|-----|----------|-------|
| portal.einundzwanzig.space | `/api/meetups` | Meetup-Liste mit Geo-Daten |
| portal.einundzwanzig.space | `/stream-calendar` | ICS-Kalender-Feed |
| mempool.space | `/api/blocks/tip/height` | Aktuelle Bitcoin Block-Height |
| Nostr Relays | WebSocket (wss://) | Admin-Registry, Reputation, Zap-Verifikation |

### Nostr Event Kinds

| Kind | Zweck | d-Tag |
|------|-------|-------|
| 0 | Profil-Metadaten (NIP-05) | — |
| 3 | Follow-Liste (Social Graph) | — |
| 9734 | Zap Request (Humanity Proof) | — |
| 9735 | Zap Receipt (Humanity Proof) | — |
| 21000 | Badge-Signatur (Organisator) | — |
| 21001 | QR-Code-Signatur | — |
| 21002 | Badge-Claim (Sammler) | — |
| 21003 | Platform Proof | — |
| 21004 | Admin Promotion Claim | `einundzwanzig-admin-claim` |
| 30078 | Admin-Registry | `einundzwanzig-admins` |
| 30078 | Reputation-Event | `einundzwanzig-reputation` |

### Flutter-Pakete (Auswahl)

| Paket | Zweck |
|-------|-------|
| `nostr` | Schnorr-Signaturen, Keypair, Nip19, Event-Erstellung |
| `nfc_manager` / `nfc_manager_ndef` | NFC-Lesen und -Schreiben |
| `mobile_scanner` | QR-Code-Scanning |
| `qr_flutter` | QR-Code-Generierung |
| `flutter_secure_storage` | Hardware-verschlüsselte Schlüsselspeicherung |
| `crypto` | SHA-256, HMAC-SHA256 |
| `shared_preferences` | Lokale Datenpersistenz |
| `http` | API-Aufrufe |
| `share_plus` | System-Teilen-Dialog |
| `path_provider` | Dateisystem-Zugriff (Backup-Export) |
| `icalendar_parser` | ICS-Kalender-Parsing |

---

## Installation und Build

### Voraussetzungen

- Flutter SDK ≥ 3.38
- Dart ≥ 3.7
- Android SDK (für Android-Build)
- Xcode (für iOS, nur auf macOS)
- Java JDK 17

### Setup

```bash
# Repository klonen
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App

# Dependencies installieren
flutter pub get

# Android APK bauen
flutter build apk --release

# APK liegt unter: build/app/outputs/flutter-apk/app-release.apk
```

### GitHub Actions

Das Repository enthält einen CI-Workflow (`.github/workflows/build_apk.yml`), der bei jedem Push auf `main` automatisch eine Release-APK baut und als Artifact bereitstellt.

---

## Kryptographie-Referenz

| Komponente | Algorithmus | Zweck |
|-----------|-------------|-------|
| Badge-Signatur | Schnorr / BIP-340 | Beweis der Organisator-Identität |
| Claim-Signatur | Schnorr / BIP-340 | Bindung des Badges an den Sammler |
| Event-ID | SHA-256 | Eindeutige Nostr-Event-Identifikation |
| Rolling Nonce | HMAC-SHA256 | Anti-Screenshot (Freshness-Check) |
| Backups | AES-256-GCM + PBKDF2-SHA256 | Sichere Verwahrung von nsec und Profildaten |
| Trust Score Hash | SHA-256 | Checksumme für Reputation-Export |
| Badge Proof Hash | SHA-256 | Datenschutzkonformer Nachweis über Badge-Set |
| Admin Registry | Schnorr / BIP-340 | Signierte Nostr-Events für Organisator-Verwaltung |
| Platform Proofs | Schnorr / BIP-340 | Plattform-Account-Verknüpfung |
| Key Storage | Android Keystore / iOS Keychain | Hardware-geschützte Schlüsselverwaltung |
| JSON Kanonisierung | Alphabetische Key-Sortierung | Deterministisches Hashing |
| Session Seed | CSPRNG (256 Bit) | Sichere Zufallserzeugung für Rolling QR |
| Legacy (v1) | HMAC-SHA256 (Shared Secret) | Veraltet, unsicher, nur Rückwärtskompatibilität |

---

## Badge Verifier (Externes Tool)

Die Datei `badge-verifier.html` ist ein eigenständiges HTML-Tool, das ohne die App funktioniert. Ein Verifizierer kann den JSON-Export einer Reputation einfügen und jedes einzelne Badge kryptographisch prüfen — direkt im Browser, ohne Server, mit der `@noble/curves` JavaScript-Library für Schnorr-Verifikation.

---

## Lizenz

MIT License — siehe [LICENSE](LICENSE).