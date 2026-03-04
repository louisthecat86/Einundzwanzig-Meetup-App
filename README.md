# Einundzwanzig Meetup App

[![Build Android APK](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/actions/workflows/build_apk.yml/badge.svg)](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/actions/workflows/build_apk.yml)

> **[APK herunterladen (neueste Version)](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/releases/tag/latest)** — wird bei jedem Commit auf `main` automatisch aktualisiert.

Dezentrale, kryptographisch verifizierbare Reputation für die Bitcoin-Community – ohne zentrale User-Datenbank, ohne KYC-Zwang, ohne Trust-Server.

Die App verbindet **physische Meetup-Teilnahme** mit **Nostr-Signaturen**, **lokaler Schlüsselhoheit**, **Web-of-Trust-Mechaniken** und **datenschutzorientiertem Reputation-Publishing**.

---

## Inhaltsverzeichnis

1. [Executive Summary](#executive-summary)
2. [Welches Problem wird gelöst?](#welches-problem-wird-gelöst)
3. [Lösungsansatz in einem Satz](#lösungsansatz-in-einem-satz)
4. [Kernfunktionen (kompletter Roundup)](#kernfunktionen-kompletter-roundup)
5. [Architektur & Datenfluss](#architektur--datenfluss)
6. [Datenmodelle](#datenmodelle)
7. [Services im Detail](#services-im-detail)
8. [Screens im Detail](#screens-im-detail)
9. [Sicherheit: Bedrohungsmodell & Gegenmaßnahmen](#sicherheit-bedrohungsmodell--gegenmaßnahmen)
10. [Build, Run, APK, Skripte](#build-run-apk-skripte)
11. [Tests & Qualität](#tests--qualität)
12. [Bekannte Grenzen & bewusst getroffene Design-Entscheidungen](#bekannte-grenzen--bewusst-getroffene-design-entscheidungen)
13. [FAQ (Praxisfragen)](#faq-praxisfragen)
14. [Technologie-Stack](#technologie-stack)

---

## Executive Summary

Diese App erzeugt und verifiziert kryptographische Teilnahme-Nachweise (Badges) für Bitcoin-Meetups. Ein Badge ist nur wertvoll, wenn er:

1. von einem Organisator signiert wurde,
2. (je nach Flow) zeitlich plausibel ist,
3. optional/ergänzend an den Teilnehmer geclaimt wurde,
4. in Reputation und Trust-Berechnung einfließt,
5. später gegenüber Dritten verifizierbar bleibt.

Die Anwendung arbeitet mit lokalen Schlüsseln (Secure Storage), publiziert aggregierte Reputation auf Nostr-Relays und enthält Mechanismen für Admin-Wachstum, Governance, Identitäts-Layer und Backups.

---

## Welches Problem wird gelöst?

### Problem

Bei P2P-Interaktionen (z. B. Kauf/Verkauf ohne zentrale Plattform) fehlt oft ein vertrauenswürdiges Reputationssignal ohne zentrale Instanz.

### Herausforderungen

- Zentrale Ratingsysteme sind manipulierbar oder KYC-lastig.
- Reine Online-Identitäten sind leicht zu fälschen.
- Offene Communities brauchen ein Trust-Modell ohne Single Point of Failure.

### Ziel

Ein **dezentral verifizierbares**, **lokal kontrolliertes** Reputationssystem auf Basis von realer Community-Teilnahme.

---

## Lösungsansatz in einem Satz

**Physische Meetup-Präsenz wird über signierte Badge-Ereignisse in messbare, verifizierbare, privacy-schonende Reputation übersetzt.**

---

## Kernfunktionen (kompletter Roundup)

## 1) Badge-Ausstellung (NFC + Rolling-QR)

- Organisator startet Meetup-Session.
- App erzeugt einen signierten Base-Payload (Nostr/Schnorr).
- Ausgabe über:
  - NFC-Tag (offline-freundlich)
  - Rolling-QR (zeitlich rotierender Code gegen Screenshot-Replay)

**Gelöstes Problem:** Präsenznachweis soll nicht nur „ich habe einen QR gesehen“, sondern möglichst realer Vor-Ort-Kontakt sein.

## 2) Badge-Verifikation beim Sammeln

- Scanner liest Payload.
- Signatur und strukturelle Integrität werden geprüft.
- Ablauf-/Zeitfenster-Checks verhindern alte/wiederverwendete Codes.
- Admin-Registry-Check bewertet den Signer-Kontext.

**Gelöstes Problem:** „Kryptographisch gültig“ allein reicht nicht; der Kontext „wer signiert“ wird mitgeprüft.

## 3) Claim-Binding / Badge-Bindung an Sammler

- Nach Erhalt wird ein Claim-Event signiert.
- Badge wird damit an die Sammler-Identität gebunden.

**Gelöstes Problem:** Badge-Sharing/Weitergabe wird deutlich erschwert, weil Besitz kryptographisch gebunden ist.

## 4) Trust Score + Promotion-Logik

- Score berücksichtigt u. a. Aktivität, Diversität, Alterung (Decay), Meetups/Signer-Verteilung.
- Bootstrap-Phasen passen Schwellen im Netzwerkwachstum an.
- Promotion-Fortschritt zeigt transparent, was noch fehlt.

**Gelöstes Problem:** Reputation ist nicht nur „Badge-Anzahl“, sondern gewichtet Qualität, Zeit und Netzwerkstruktur.

## 5) Reputation-Publishing auf Nostr

- Publiziert aggregierte Reputation als signiertes Event (Kind 30078).
- Enthält bewusst keine kompletten Rohdaten aller Meetup-Details.

**Gelöstes Problem:** Verifizierbarkeit ohne zentrale API, bei gleichzeitiger Datensparsamkeit.

## 6) Multi-Layer Identity / Proofs

- Plattform-Proofs (verknüpfte Accounts)
- Social Graph Signale
- Zap/Humanity-Proof (Lightning-Aktivität als Anti-Bot-Signal)

**Gelöstes Problem:** Reputation wird mehrdimensional statt eindimensional.

## 7) Admin Registry & Web of Trust Governance

- Bootstrap-Mechanik für frühe Netzwerkphase.
- Sunset-Logik reduziert zentrale Sonderrolle bei wachsendem Netzwerk.
- Vouching-/Distrust-Komponenten für Governance.

**Gelöstes Problem:** Wachstum von zentraler Initialphase zu dezentralerer Vertrauensstruktur.

## 8) Backup/Wiederherstellung

- Verschlüsseltes Backup mit Passwort.
- Restore inkl. User/Badges/Keys/Proof-Daten (mit Sicherheitsprüfungen und Revalidierungslogik).

**Gelöstes Problem:** Geräteverlust darf nicht identisch mit Reputationsverlust sein.

---

## Architektur & Datenfluss

## High-Level

- **UI Layer:** `lib/screens/*`
- **Domain Models:** `lib/models/*`
- **Core Services:** `lib/services/*`
- **Persistenz:**
  - Sensitive Secrets: `flutter_secure_storage`
  - Sonstige App-Daten/Cache: `SharedPreferences`

## Externe Schnittstellen

- Nostr Relays (Publizieren/Abfragen von Events)
- Meetup-Portal/API (Meetup-Listen)
- iCal-Feeds (Kalender)
- mempool.space (Blockhöhe)

## Kritischer End-to-End Flow (vereinfacht)

1. Organisator startet Session (`rolling_qr_service.dart`)
2. Base-Payload wird signiert (`badge_security.dart`)
3. Teilnehmer scannt (`meetup_verification.dart`)
4. Verifikation + Admin-Check (`badge_security.dart`, `admin_registry.dart`)
5. Badge speichern (`badge.dart`)
6. Claim erzeugen (`badge_claim_service.dart`)
7. Reputation aktualisieren/publizieren (`reputation_publisher.dart`)

---

## Datenmodelle

## `lib/models/user.dart`

Repräsentiert lokales Nutzerprofil, Verifikations-/Admin-Status und Nostr-Bezug. Unterstützt kryptographische Re-Verifikation des Admin-Status.

## `lib/models/badge.dart`

Badge-Domänenmodell inklusive Signaturfelder, Claim-Bindung, Proof-Hashing und verschlüsselter Persistenz/Migration von Badge-Daten.

## `lib/models/meetup.dart`

Meetup-Metadaten (Stadt/Land/Koordinaten/Kommunikationsdaten), genutzt in Listing-, Auswahl- und Session-Flows.

## `lib/models/calendar_event.dart`

Kalender/Event-Darstellung aus iCal-Daten.

---

## Services im Detail

### Sicherheits-/Krypto-Kern

- `secure_key_store.dart`  
  Sichere Schlüsselablage (Keystore/Keychain), Migration aus älteren Speicherorten, Grundlage für alle privaten Schlüssel.

- `nostr_service.dart`  
  Key-Erstellung, nsec-Import, Signierung, Verifikation, NIP19-Konvertierung.

- `badge_security.dart`  
  Badge-/QR-Signierung und Verifikation, Canonical JSON, Formatchecks, Legacy-Ablehnung/-Kompatibilitätslogik.

- `badge_claim_service.dart`  
  Erzeugt/verifiziert Claim-Events zur Bindung von Badge ↔ Sammler.

### Trust / Governance

- `trust_score_service.dart`  
  Score-Berechnung, Bootstrap-Phasen, Promotion-Fortschritt, Suspicious Pattern Detection.

- `admin_registry.dart`  
  Admin-Cache, Relay-Fetch, Sunset-Mechanik, Admin-Prüfung auch über Pubkey-Hex.

- `admin_status_verifier.dart`  
  Kryptographisch orientierter Admin-Status-Check statt blindem Bool-Trust.

- `promotion_claim_service.dart`  
  Claim-basierte Promotion-Events und deren Verifikation/Übernahme.

- `vouching_service.dart`  
  Vouch-/Distrust-Mechanik für WoT-Governance-Szenarien.

### Reputation / Relay / Identitätslayer

- `reputation_publisher.dart`  
  Baut datensparsame Reputation-Events und publiziert sie auf aktive Relays, inkl. Publish-Intervall-/Change-Checks.

- `relay_config.dart`  
  Verwaltung aktiver Relays (Default + Custom), Validierung von Relay-URLs.

- `platform_proof_service.dart`  
  Signierte Plattform-Proofs erstellen/speichern/entziehen.

- `social_graph_service.dart`  
  Social-Metriken (Follows/Mutuals/Hops) via Relay-Abfragen.

- `zap_verification_service.dart`  
  Zap-Receipt-Auswertung und Lightning-Aktivitätsmetriken.

- `humanity_proof_service.dart`  
  Humanity-Signal über Zap-Aktivität, inkl. Reverification nach Restore.

- `nip05_service.dart`  
  NIP-05 Validierung (`.well-known/nostr.json`) gegen erwarteten Pubkey.

### Session / Scanning / Integrität / Datenquellen

- `rolling_qr_service.dart`  
  Session-Lifecycle, nonce/time-step Mechanik, Replay-Schutzmodell.

- `device_integrity_service.dart`  
  Root/Jailbreak-Heuristiken und Sicherheitswarnungen.

- `meetup_service.dart`  
  Meetup-API-Laden und Mapping.

- `meetup_calendar_service.dart`  
  iCal-Laden/Parsing/Sortierung.

- `mempool.dart`  
  Blockhöhenabfrage.

- `backup_service.dart`  
  Export/Import verschlüsselter Backups (inkl. Validierungs- und Restore-Guardrails).

- `nostr_web.dart`  
  Web-spezifische Nostr-Integration.

- `app_logger.dart`  
  Zentrales Logging (debug-orientiert).

---

## Screens im Detail

### Entry, Dashboard, Profil

- `intro.dart` – Onboarding/Restore/Entry-Flow
- `dashboard.dart` – zentrale Orchestrierung (Status, Score, Session, Security)
- `profile_edit.dart` – Profil + Key-Management

### Badge- und Verifikationsflows

- `meetup_verification.dart` – NFC/QR-Scan, Verifikation, Speichern, Claim, Publish
- `nfc_writer.dart` – NFC-Tag-Beschreibung mit signiertem Payload
- `rolling_qr_screen.dart` – Live-Rolling-QR-Anzeige
- `badge_wallet.dart` – Badge-Bestand/Sharing
- `badge_details.dart` – Badge-Details
- `reputation_qr.dart` – Reputation als QR + Publish
- `reputation_verify_screen.dart` – Verifikation eingehender Reputation
- `qr_scanner.dart` – Scanner für Reputation/Proof-QRs

### Meetup/Community/Events

- `meetup_list_screen.dart`, `events.dart`, `meetup_details.dart`, `meetup_selection.dart`
- `calendar_screen.dart`
- `community_portal_screen.dart`
- `create_meetup.dart`
- `radar.dart`

### Admin/Governance

- `admin_panel.dart` – Organisatorsteuerung + Sessionkontrolle
- `admin_management.dart` – Co-Admin-Verwaltung
- `wot_dashboard.dart` – WoT-Netzwerk-/Vouching-Ansichten
- `relay_settings_screen.dart` – Relay-Konfiguration
- `meetup_session_wizard.dart` – geführter Session-Start

### Trust-/Proof-Layer UX

- `platform_proof_screen.dart`
- `humanity_proof_screen.dart`

### Sonstige

- `pos.dart` – einfacher/platzhalterhafter POS-Bereich

---

## Sicherheit: Bedrohungsmodell & Gegenmaßnahmen

## 1) Schlüsselabfluss

**Risiko:** Private Keys im unsicheren Speicher.  
**Gegenmaßnahme:** `secure_key_store.dart`, Migration aus älteren Stores, Nutzung hardwaregestützter Mechanismen.

## 2) Replay/Screenshot von QR-Codes

**Risiko:** Ein statischer Screenshot wird später als gültiger Proof benutzt.  
**Gegenmaßnahme:** Rolling-QR mit Zeitfenster + Session-Ablauf + signierter Base-Payload.

## 3) „Mathematisch gültig, aber sozial unbekannt“

**Risiko:** Beliebiger Key signiert valide Daten.  
**Gegenmaßnahme:** Registry-/WoT-Checks zusätzlich zur reinen Signaturprüfung.

## 4) Legacy-Unsicherheiten

**Risiko:** Alte Signaturpfade/Secrets.  
**Gegenmaßnahme:** Legacy-Ablehnung bzw. klare Degradierung, v2/v3-fokussierte Verifikation.

## 5) Backup-Angriffe

**Risiko:** Offline-Passwort-Bruteforce gegen Backup-Datei.  
**Gegenmaßnahme:** Salt + PBKDF2-HMAC-SHA256 (hohe Iteration) + AES-GCM-Flow.

## 6) Restore-Manipulation

**Risiko:** Manipulierte Backupinhalte hebeln Trust-Status aus.  
**Gegenmaßnahme:** Validierung beim Restore + Reverification-Pfade (z. B. Humanity/Admin-Daten).

## 7) Gerätekompromittierung

**Risiko:** Root/Jailbreak erhöht Exfiltrationsrisiko.  
**Gegenmaßnahme:** Device-Integrity-Checks + Warnsignale.

---

## Build, Run, APK, Skripte

### Fertige APK herunterladen (empfohlen)

Die APK wird bei jedem Push auf `main` automatisch per GitHub Actions gebaut und als Release veröffentlicht:

**[Neueste APK herunterladen](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/releases/tag/latest)**

Einfach die `.apk`-Datei auf dem Android-Gerät öffnen und installieren ("Aus unbekannten Quellen" muss erlaubt sein).

### Selbst bauen

## Wichtige Root-Skripte

- `setup-android-and-build.sh` – Android SDK Setup + Build
- `build-apk.sh` – regulärer APK-Build
- `quick-build.sh` – schneller Build-Flow
- `fix-and-build.sh` – Clean/Fix-orientierter Build-Flow
- `diagnose.sh` – Diagnose/Fehlersuche für Build-Umgebung

## Dokumente für Betrieb

- `BUILD_APK.md` – ausführliche APK-Anleitung
- `QUICKSTART_APK.md` – kompakter Schnellstart
- `SecurityAudit.md` / `SecurityChangelog.md` – Security-Historie und Maßnahmen

---

## Tests & Qualität

Projekt enthält Flutter/Dart-Tests, u. a. für:

- Trust-Score-Logik (`test/trust_score_test.dart`)
- Badge-Modell/Security (`test/badge_model_test.dart`, `test/badge_security_test.dart`)
- Widget-Basics (`test/widget_test.dart`)

Beispielhaft abgedeckt sind Bootstrap-Phasen, Legacy-Ausgrenzung, Frequency-Cap, Decay- und Diversity-Effekte sowie Suspicious-Pattern-Basics.

---

## Bekannte Grenzen & bewusst getroffene Design-Entscheidungen

1. **Rolling-Nonce ist Zeitfenster-Schutz, kein globales Geheimnis-Protokoll.**  
   Der Scanner validiert primär Zeitnähe; Hauptsicherheit bleibt die Signaturkette.

2. **Relay-Erreichbarkeit beeinflusst Frische, nicht zwingend lokale Grundfunktion.**  
   Viele Flows sind mit Cache/Offline-Fallbacks gebaut.

3. **Trust Score ist ein Modell, kein universelles Naturgesetz.**  
   Gewichte/Schwellen sind bewusst Community-spezifisch.

4. **Legacy-Kompatibilität existiert teilweise nur für Übergang/Migration.**

5. **Ohne Schlüssel kein sicherer Verifikations-/Publish-Pfad.**

---

## FAQ (Praxisfragen)

### Warum nicht einfach ein zentrales Bewertungssystem?

Weil dieses Projekt bewusst auf **dezentral überprüfbare Reputation** setzt und keinen zentralen Betreiber als Wahrheitsinstanz benötigt.

### Kann jemand Badges einfach kopieren?

Kopieren von Daten ist immer möglich; entscheidend ist die **Verifizierbarkeit der Signatur- und Claim-Kette**. Ohne passende Signaturen und Kontextprüfungen ist ein „kopiertes Badge“ reputationsseitig entwertet.

### Warum werden nicht alle Rohdaten veröffentlicht?

Datenschutz: publiziert werden primär **aggregierte Kennzahlen + Proof-Hashes**, nicht die komplette persönliche Historie.

### Was passiert bei verlorenem Smartphone?

Mit verschlüsseltem Backup kann der Zustand wiederhergestellt werden. Ohne Backup sind lokale Daten inkl. Schlüssel ggf. verloren.

### Ist die App komplett offline nutzbar?

Teilweise: lokale Datenhaltung und gewisse Badge-Flows funktionieren offline, aber Relay-Fetch, Publishing, einige Verifikationslayer und externe Datenquellen benötigen Netz.

### Warum gibt es Bootstrap/Sunset in der Admin-Logik?

Um den Start eines neuen Netzwerks praktikabel zu machen, ohne dauerhaft bei einer zentralen Sonderrolle zu bleiben.

---

## Technologie-Stack

- **Framework:** Flutter / Dart
- **Krypto/Identität:** Nostr, Schnorr/`secp256k1`, `crypto`
- **Storage:** `flutter_secure_storage`, `shared_preferences`
- **NFC/QR:** `nfc_manager`, `mobile_scanner`, `qr_flutter`
- **Netzwerk/Parsing:** `http`, `icalendar_parser`
- **Backup/Sharing:** `encrypt`, `share_plus`, `file_picker`, `path_provider`

---

## Hinweis für Maintainer

Diese README wurde als **codebasierter Gesamt-Roundup** erstellt. Bei neuen Features bitte immer die Abschnitte

- Kernfunktionen
- Services im Detail
- Screens im Detail
- Sicherheit

parallel aktualisieren, damit Doku und Implementierung synchron bleiben.
