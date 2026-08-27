# Einundzwanzig Meetup App

**Verifizierbare Community-Reputation fuer Bitcoin-Meetups: lokal, pseudonym und kryptographisch pruefbar.**

Die Einundzwanzig Meetup App verbindet Meetup-Termine, Anwesenheits-Badges, Nostr-Identitaet und Community-Werkzeuge in einer Flutter-App. Ein Badge entsteht aus einem von einem Organisator signierten Rolling-QR-Code und wird nach dem Scan an die Nostr-Identitaet des Teilnehmers gebunden. Daraus berechnet die App lokal einen Trust Score, der als aggregierte Reputation geteilt und von anderen geprueft werden kann.

> **Aktueller Stand:** Version `1.6.2+21`. Rolling-QR ist der aktive Weg zur Badge-Vergabe. NFC-Code ist im aktuellen Build deaktiviert (`kNfcEnabled = false`) und wird deshalb als Legacy-Funktion gefuehrt.

[![Flutter](https://img.shields.io/badge/Flutter-3.41%2B-02569B)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-2ea44f)](LICENSE)
[![Nostr](https://img.shields.io/badge/Nostr-BIP--340%20%7C%20NIP--01-7B61FF)](https://github.com/nostr-protocol/nips)

## Inhalt

- [Was die App loest](#was-die-app-loest)
- [Schnellstart](#schnellstart)
- [Badge- und Reputation-System](#badge--und-reputation-system)
- [Aktuelle Funktionen](#aktuelle-funktionen)
- [Identitaet und Signaturmodi](#identitaet-und-signaturmodi)
- [Dezentrale Organisator-Verwaltung](#dezentrale-organisator-verwaltung)
- [Sicherheit und Datenschutz](#sicherheit-und-datenschutz)
- [Netzwerk und Datenquellen](#netzwerk-und-datenquellen)
- [Architektur](#architektur)
- [Entwicklung und Release](#entwicklung-und-release)
- [Tests](#tests)
- [Bekannte Grenzen](#bekannte-grenzen)
- [Lizenz und Links](#lizenz-und-links)

## Was die App loest

Bei einem pseudonymen P2P-Handel ist ein Profil allein kein belastbarer Vertrauensbeweis. Zentrale Bewertungssysteme verlangen eine zentrale Instanz; KYC loest das Identitaetsproblem auf Kosten der Privatsphaere. Die App nutzt stattdessen wiederholte physische Teilnahme an Bitcoin-Meetups als Community-Signal.

Die App ist keine zentrale Zertifizierungsstelle. Private Schluessel und Besuchsdaten bleiben grundsaetzlich auf dem Geraet. Signaturen, Claims, Proof-Hashes und veroeffentlichte aggregierte Daten koennen von anderen Clients unabhaengig geprueft werden.

## Schnellstart

### Voraussetzungen

- Flutter SDK `3.41+`
- Dart SDK `3.10+`
- Android-Builds: Android SDK und JDK 17
- Android Keystore bzw. iOS Keychain fuer lokale Schluessel
- Fuer externe Signatur: NIP-07-Browser oder Amber auf Android

### Projekt starten

```bash
git clone https://github.com/louisthecat86/Einundzwanzig-Meetup-App.git
cd Einundzwanzig-Meetup-App
flutter pub get
flutter gen-l10n
flutter run
```

Beim ersten Start wird ein Profil eingerichtet. Im lokalen Signaturmodus erzeugt die App ein Nostr-Keypair; alternativ kann die Signatur an Amber oder eine NIP-07-Erweiterung delegiert werden. Das Dashboard fuehrt danach zu Favoriten, Terminen, Scan, Wallet und Reputation.

### Android-APK bauen

```bash
flutter build apk --release
```

Die APK liegt unter `build/app/outputs/flutter-apk/app-release.apk`. Fuer automatisierte Builds koennen `build-apk.sh` oder `quick-build.sh` verwendet werden. Details stehen in [BUILD_APK.md](BUILD_APK.md) und [QUICKSTART_APK.md](QUICKSTART_APK.md).

## Badge- und Reputation-System

### 1. Organisator startet eine Session

Ein berechtigter Organisator richtet eine Meetup-Session ein. Der aktive Ausgabekanal ist ein Rolling-QR-Code:

- Eine Session erhaelt einen kryptographisch zufaelligen 256-Bit-Seed.
- Der QR-Code wird in 10-Sekunden-Zeitschritten neu berechnet.
- Die Session ist aktuell vier Stunden gueltig.
- Der Seed wird im Secure Storage abgelegt und nicht aus dem privaten Nostr-Schluessel abgeleitet.

Ein stehender Screenshot enthaelt nach Ablauf seines Zeitschritts keinen aktuellen Code mehr. Der Scanner prueft zusaetzlich Zeitfenster, Payload und Signatur. Das erschwert die einfache Weitergabe statischer Screenshots, ersetzt aber keine vollstaendige Anwesenheitsgarantie.

### 2. Teilnehmer scannt und claimt

Der signierte Kompakt-Payload enthaelt nur die erlaubten Felder `v`, `t`, `m`, `b` und `x`. Die Organisator-Signatur ist eine BIP-340-Schnorr-Signatur ueber kanonisches JSON (Nostr Event Kind `21000`).

Nach erfolgreicher Pruefung signiert der Teilnehmer den Badge automatisch mit seiner eigenen Nostr-Identitaet. Dieser Claim (Kind `21002`) bindet den Badge an genau diesen Sammler. Ein kopierter Organisator-Payload kann dadurch nicht einfach fuer die Reputation einer anderen Identitaet verwendet werden.

Vor der Uebernahme prueft die App:

1. JSON-Whitelist, Format von Pubkey und Signatur sowie kanonische Darstellung
2. Signatur und Gueltigkeitszeitraum
3. den Signer gegen die Admin-/Organisator-Registry
4. Duplikate, Selbst-Scan-Regeln und die Claim-Bindung

Nur vollstaendig gebundene Badges zaehlen fuer den Trust Score. Event-Badges werden separat behandelt: Sie koennen Badge-Anzahl und Vielfalt erhoehen, gelten aber nicht automatisch als besuchtes Meetup.

### NFC-Status

Die NFC-Implementierung fuer NTAG215/NTAG216 bleibt im Quellcode erhalten, ist aber seit August 2026 abgeschaltet. Grund sind die geringere Geraeteabdeckung, iOS-Einschraenkungen und der zusaetzliche Testaufwand beim Badge-Format. Bestehende NFC-Codepfade sind daher nicht als aktuell verfuegbarer Produktablauf zu verstehen.

### Trust Score

Der Score wird aus gebundenen Badges lokal berechnet:

| Faktor | Wirkung |
| --- | --- |
| Diversity | Unterschiedliche Meetups, Staedte und Signer; Gewichtung `1.5x` |
| Quality | Qualitaet und Vertrauensniveau der Signer sowie Co-Attestoren; Gewichtung `1.2x` |
| Maturity | Alter und Kontinuitaet des Accounts |
| Activity | Regelmaessigkeit, mit maximal zwei gewerteten Badges pro Woche |
| Time decay | Halbwertszeit von 26 Wochen fuer ausbleibende Aktivitaet |

| Score | Stufe |
| ---: | --- |
| `< 3` | NEU |
| `3+` | STARTER |
| `10+` | AKTIV |
| `20+` | ETABLIERT |
| `40+` | VETERAN |

Die Mindestanforderungen passen sich an die Netzwerkphase an:

| Phase | Signer | Badges | Meetups | Signer-Minimum | Accountalter |
| --- | ---: | ---: | ---: | ---: | ---: |
| Keimphase | 1 | 3 | 2 | 1 | 14 Tage |
| Wachstum | 2-5 | 4 | 3 | 2 | 30 Tage |
| Stabil | 6+ | 5 | 3 | 2 | 60 Tage |

### Reputation teilen und pruefen

Die eigene Reputation kann als QR-Code, Text/JSON oder signiertes Nostr-Event geteilt werden. Der Reputation-QR und das Event enthalten aggregierte Werte wie Badge-, Meetup- und Signer-Anzahl, Accountalter, Stufe und einen `badge_proof_hash`. Meetup-Namen, Orte und Besuchsdaten werden nicht als Teil der oeffentlichen Aggregation veroeffentlicht.

Ein Verifizierer prueft Signaturen, Claims, Proof-Hash und den bekannten Status der Signer. Zusaetzliche Identitaetssignale wie NIP-05, Plattform-Proofs, Social Graph oder Humanity Proof koennen separat betrachtet werden.

## Aktuelle Funktionen

### Meetup und Dashboard

- Portal-Termine zuerst ueber die offizielle API, iCal als Fallback.
- Favoriten-Meetups im Onboarding und in der Terminliste.
- Home-Kachel pro Favorit mit dem naechsten Event, global chronologisch sortiert.
- Uebertragung des naechsten Events an ein Android-Homescreen-Widget.
- Meetup-Radar und Umgebungssuche mit Standort und Karte.
- Kalender-Export sowie RSVP mit „Zusagen“ und „Vielleicht“.
- Konfigurierbares Dashboard: Kacheln sortieren, ausblenden und neue Kacheln migrieren.

### Community und Events

- Community-Hub mit Portal, News und Community-Ressourcen.
- Event-Bereich mit Event-Badges, Sessions, Check-in und Event-Chats.
- Chats fuer Meetups und Events sowie eigener Netzwerk-/Trust-Bereich.
- News-Feed mit Reaktionen und optionalen Zaps/Value-for-Value-Interaktionen.
- PlebRap-Player mit Playlist, Album-Covern, Mini-Player und Value-for-Value-Link.
- SatoshiDuell-Kachel mit Auto-Login per npub und Status fuer offene Duelle, Warteraum und Lobby.
- Bitcoin-Dashboard, Einheiten-Converter, V4V-Bereich und Glossar.

### Profil, Identitaet und Netzwerk

- Profil mit Nickname, npub, Signaturmodus und Avatar.
- Plattform-Proofs fuer unter anderem Satoshi-Kleinanzeigen, Telegram, RoboSats und Nostr.
- NIP-05-Pruefung eines Nostr-Identifiers.
- Lightning-/Zap-basierter Humanity Proof als zusaetzliches Echtheitssignal.
- Nostr-Social-Graph mit Follower-, Following- und Kontaktanalyse.
- Nostr-Relay-Auswahl und eigene Relay-Konfiguration.
- Passkey-PRF-Unterstuetzung fuer lokale Authentifizierungs-/Schluesselablaeufe, wo die Plattform dies anbietet.

## Identitaet und Signaturmodi

Die Signatur wird ueber `SigningService` zentral abstrahiert:

- **Lokal:** Der private Schluessel liegt im Android Keystore bzw. iOS Keychain und wird nur zum Signieren verwendet.
- **Amber/NIP-55 (Android):** Amber signiert extern; der nsec verlaesst die Signer-App nicht.
- **NIP-07 (Web):** Eine Browser-Erweiterung signiert Events extern.
- **NIP-46:** Remote-Signing/Bunker-Verbindungen werden unterstuetzt.
- **NIP-49:** Passwortgeschuetzter `ncryptsec`-Export fuer kompatible Schluessel-Workflows.

Im Amber- oder NIP-07-Modus existiert nicht zwingend ein lokaler nsec.

## Dezentrale Organisator-Verwaltung

Organisator-/Admin-Status kann aus mehreren unabhaengigen Quellen stammen:

1. **Portal-Rechte:** Leader-Rechte im Einundzwanzig Portal.
2. **Web of Trust:** Andere berechtigte Admins veroeffentlichen signierte Vouchings fuer npubs.
3. **Auto-Promotion:** Trust Score und aktuelle Bootstrap-Phase erfuellen die Mindestanforderungen.
4. **Seed-Admin:** Initialer Bootstrap-Status fuer den Netzwerkanlauf.

Vouchings und Admin-Daten werden als signierte Nostr-Daten verteilt. Distrust-Meldungen (Kind `21003`) koennen kompromittierte oder missbrauchte Admins markieren. Die Registry nutzt Relay-Timeouts und einen lokalen Cache als Offline-Fallback.

Der Seed-Admin verliert seinen Sonderstatus beim Bootstrap-Sunset, sobald mindestens 20 verschiedene organische Admin-Autoren Vouchings publiziert haben. Es zaehlen Autoren, nicht einzelne Eintraege. Der kryptographisch erneut verifizierte Admin-Status ist fuer sicherheitskritische Aktionen massgeblich.

## Sicherheit und Datenschutz

### Schluessel und Backups

- Private Schluessel werden ueber `flutter_secure_storage` in Android Keystore bzw. iOS Keychain verwahrt.
- Eine Migration aus alten SharedPreferences-Bestaenden wird beim Start unterstuetzt; danach werden alte Schluessel dort entfernt.
- Backups verwenden zufaelligen 32-Byte-Salt, PBKDF2-HMAC-SHA256 mit 600.000 Iterationen und AES-256. Das Format ist `enc_v2:[SALT]:[IV]:[CIPHERTEXT]`.
- Der private Schluessel liegt nur im verschluesselten Teil des Backups.
- Der Rolling-QR-Session-Seed wird getrennt im Secure Storage gespeichert.

### Badge- und Protokollsicherheit

- BIP-340-Schnorr-Signaturen und defensive Laengenpruefungen.
- Whitelist statt Blacklist fuer Badge-Felder.
- Kanonisches JSON verhindert unterschiedliche Hashes durch Map-Reihenfolge.
- Legacy-v1-Signaturen sind deaktiviert und werden nicht als vertrauenswuerdige neue Badges akzeptiert.
- NIP-44 ist mit offiziellen Testvektoren abgedeckt; NIP-46 und NIP-49 sind ebenfalls integriert.

### Geraeteintegritaet und Privatsphaere

Root-/Magisk-/Jailbreak-Indikatoren werden erkannt und als Warnung angezeigt. Die App blockiert das Geraet nicht; Secure Storage und kryptographische Verifikation bleiben die primaere Schutzlinie.

Meetup-Historie und persoenliche Profildaten bleiben lokal. Auf Relays werden nur die fuer den jeweiligen Ablauf erforderlichen signierten Daten und bei der Reputation aggregierte Werte publiziert. IP-Adressen, Geraete-IDs und Zahlungsdetails werden nicht als Reputationsdaten gespeichert. Standort wird fuer Radar/Karte genutzt und nicht als Bestandteil des Reputation-Proofs veroeffentlicht.

## Netzwerk und Datenquellen

| Quelle | Verwendung |
| --- | --- |
| Einundzwanzig Portal API | Meetups, Wappen, Orte, Login, Organisator-Ansicht und RSVP |
| iCal-Feed | Termin-Fallback inklusive Wiederholungen und Zeitzonenbehandlung |
| Nostr-Relays | Signaturen, Admin-/Vouch-Registry, Reputation, Profile und Social Graph |
| Mempool.space | Blockhoehe und Netzwerkdaten; Clearnet, Tor-Onion oder eigene Instanz konfigurierbar |
| SatoshiDuell | Oeffentliche Statusdaten ueber die Supabase-REST-API |
| PlebRap | Audio-Streams, Cover und Value-for-Value-Ziel |

Default-Relays koennen durch eigene Relays ersetzt werden. Relay-Abfragen haben Timeouts; bei der Admin-Registry kann ein lokaler Cache verwendet werden. Portal-Zeitstempel werden je nach Endpoint ueber die zentrale Kalenderlogik zeitzonenbewusst in die lokale Anzeige umgerechnet.

## Architektur

```text
lib/
├── main.dart                 App-Start, Migration und Session-Pruefung
├── theme.dart                Design-System und Farben
├── models/                   Badge, User, Meetup und Kalenderdaten
├── screens/                  Onboarding, Dashboard, Scanner, Wallet, Kalender,
│                             Community, Profil, Einstellungen und Admin-Views
├── services/                 Krypto, Claims, Trust Score, Registry, Portal,
│                             Kalender, Relays, Mempool, Audio, News und Proofs
├── l10n/                     Deutsch, Englisch und Spanisch
└── widgets/                 Wiederverwendbare UI- und Reputation-Komponenten
```

Wichtige Kontrollpunkte sind `badge_security.dart`, `badge_claim_service.dart`, `trust_score_service.dart`, `admin_registry.dart`, `signing_service.dart`, `secure_key_store.dart`, `backup_service.dart`, `rolling_qr_service.dart` und `meetup_calendar_service.dart`.

## Entwicklung und Release

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

Die generierten Lokalisierungsdateien sind eingecheckt. UI, Kommentare und Commits folgen der deutschen Projektsprache; neue Texte muessen in DE, EN und ES synchron gehalten werden. Gemeinsame Theme-Konstanten aus `theme.dart` verwenden.

Fuer einen Release:

1. Version in `pubspec.yaml` erhoehen; Android `versionCode` muss streng steigen.
2. `flutter analyze` und `flutter test` ausfuehren.
3. Commit und Push auf `main`.
4. Einen Versions-Tag wie `v1.6.3` pushen; die GitHub Action baut und signiert die APK.

App-ID: `space.einundzwanzig.meetup`.

In GitHub Codespaces ist das Android SDK nicht zwingend vorhanden. In diesem Fall sind Android-Builds lokal nicht moeglich; die Release-Action oder eine lokal eingerichtete Android-Umgebung uebernimmt den APK-Build.

## Tests

Der Testbestand deckt unter anderem ab:

- Badge-Modell, Serialisierung, Claims und Proofs
- BIP-340-Badge-Signatur und Verifikation
- Trust-Score-Berechnung und Bootstrap-Regeln
- offizielle NIP-44-Testvektoren
- NIP-46-Client und Signing-Service
- NIP-49, PBKDF2 und Web-/Dart-Gleichheit
- NIP-07, Relay-Socket, lokale Authentifizierung und Key Vault
- Portal-/Mempool-Header, Passkey-RP-ID und User-Profile
- Widget-, App-Logger-, Badge- und Sicherheitsregressionen

Die Tests liegen im Verzeichnis [test](test). Bekannte kosmetische Analyzer-Hinweise sind im [Entwickler-Handbuch](UEBERGABE.md) dokumentiert; relevant sind neue `error`-Meldungen.

## Bekannte Grenzen

- NFC ist aktuell deaktiviert; Rolling-QR ist der vorgesehene produktive Badge-Weg.
- Der QR-Screenshot-Schutz basiert auf dem Zeitfenster. Ein Scanner kann den HMAC-Nonce-Wert konstruktionsbedingt nicht selbst aus dem geheimen Session-Seed berechnen; Ablauf und signierter Payload werden geprueft.
- Root-/Jailbreak-Erkennung ist ein Warnsignal, keine vollstaendige Hardware-Attestierung.
- Der PlebRap-V4V-Knopf oeffnet aktuell die Value-for-Value-Seite; eine direkte Kuenstler-Lightning-Adresse ist nicht Bestandteil dieses Ablaufs.
- Portal- und Relay-Funktionen benoetigen Netzwerkzugriff. Offline stehen nur lokal verfuegbare Daten und Cache-Inhalte zur Verfuegung.
- Ein unabhaengiges Audit der verwendeten BIP-340-Implementierung im `nostr`-Package bleibt ein sinnvoller offener Punkt.

Weitere technische Fallstricke, besonders zu Amber und Zeitzonen, stehen in [UEBERGABE.md](UEBERGABE.md). Sicherheits-Patchnotes und Audit-Historie finden sich in [SecurityAudit.md](SecurityAudit.md) und [SecurityChangelog.md](SecurityChangelog.md).

## Lizenz und Links

Das Projekt steht unter der [MIT-Lizenz](LICENSE).

- Repository: [github.com/louisthecat86/Einundzwanzig-Meetup-App](https://github.com/louisthecat86/Einundzwanzig-Meetup-App)
- Einundzwanzig Portal: [portal.einundzwanzig.space](https://portal.einundzwanzig.space)
- SatoshiDuell: [satoshiduell.de](https://satoshiduell.de)
- PlebRap: [plebrap.de](https://plebrap.de)
- Einundzwanzig Telegram: [t.me/einundzwanzig](https://t.me/einundzwanzig)
