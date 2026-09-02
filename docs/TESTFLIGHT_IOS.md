# TestFlight — iOS Release Checkliste

Kurzanleitung für Maintainer mit **Apple Developer Program** (Org-/Vereins-Team).
Personal Developer Teams reichen **nicht** für TestFlight — nur USB-Sideload auf eigene Geräte.

**App:** `de.einundzwanzig.einundzwanzigMeetupApp` · Version siehe `pubspec.yaml` (z. B. 1.6.1+20)

---

## Voraussetzungen

| Punkt | Details |
|--------|---------|
| Apple Developer | Bezahltes Team (99 $/Jahr), **nicht** nur Personal Team |
| App Store Connect | Rolle Admin oder App Manager |
| Bundle-ID | `de.einundzwanzig.einundzwanzigMeetupApp` im Team registriert |
| Mac + Xcode | Aktuell (projektiert mit Xcode 26.x / Flutter stable) |
| Repo-Stand | `origin/main` + offene Fix-PRs prüfen (siehe unten) |

---

## Vor dem Build (Repo)

- [ ] `git fetch origin && git checkout main && git pull`
- [ ] **PR #50** (NFC-Entitlements entfernen) — mergen, solange `kNfcEnabled = false`
- [ ] **Guide-Fix-PR** (`fix/guide-dispose-provider`) — mergen (Provider-Fehler beim Tab-Wechsel)
- [ ] `flutter pub get`
- [ ] `flutter analyze` — 0 Issues
- [ ] `flutter test` — alle grün

---

## Xcode / Signing

1. `open ios/Runner.xcworkspace`
2. Target **Runner** → **Signing & Capabilities**
3. **Team:** Verein/Org (nicht Personal Team)
4. **Bundle Identifier:** `de.einundzwanzig.einundzwanzigMeetupApp`
5. **Automatically manage signing:** an
6. Keine NFC-Capability aktiv, solange NFC in der App aus ist (`lib/features.dart`)

---

## Archive & Upload

### Variante A — Xcode (empfohlen)

1. Gerät: **Any iOS Device (arm64)** (kein Simulator)
2. **Product → Archive**
3. **Distribute App → App Store Connect → Upload**
4. Bei **Export Compliance / Verschlüsselung:**
   - App nutzt HTTPS und lokale Krypto (Nostr, Backup) → in der Regel **Standardverschlüsselung**, oft **befreit** (kein eigenes Protokoll)
   - Im Zweifel in App Store Connect nach Upload unter „Compliance“ beantworten

### Variante B — Flutter CLI

```bash
flutter build ipa --release
# IPA liegt unter build/ios/ipa/*.ipa
# Hochladen mit Apple Transporter (Mac App Store) oder `xcrun altool`
```

---

## App Store Connect (nach Upload)

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Apps** → App anlegen oder öffnen
2. **TestFlight** → Build erscheint nach Verarbeitung (10–30 Min.)
3. **Was ist neu in dieser Version?** — Kurztext für Tester
4. **Interne Tester** — Gruppe anlegen, Apple-ID der Tester einladen
5. **Externe Tester** — optional; erfordert Beta-App-Review (Metadaten, ggf. Privacy-URL)

---

## Pflicht-Angaben / Review-Hinweise

| Thema | Status in App |
|--------|----------------|
| Kamera | QR-Scan — `NSCameraUsageDescription` ✅ |
| Standort | Meetups in der Nähe — `NSLocationWhenInUseUsageDescription` ✅ |
| Fotos | Profilbild — `NSPhotoLibraryUsageDescription` ✅ |
| Kalender | Termine — `NSCalendarsUsageDescription` ✅ |
| NFC | **Aus** in Code — Entitlements sollten leer sein (PR #50); `NFCReaderUsageDescription` in plist ist historisch |
| Passkeys | Optional; Domain-Verknüpfung `einundzwanzig.space` noch offen — Passwort-Login funktioniert ohne |
| Privacy Policy | Für **externe** TestFlight / Store oft nötig — URL in Connect hinterlegen |

Optional in `Info.plist` (vermeidet Rückfragen beim Upload):

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

(nur wenn ihr keine eigene, nicht standardisierte Krypto exportiert)

---

## Smoke-Test auf TestFlight-Gerät

- [ ] App startet (Intro / Login / Home)
- [ ] Portal-Termine laden
- [ ] QR-Scan / Badge-Flow (Rolling QR)
- [ ] Einstellungen → Diagnose-Log (kein `Provider`-ERROR beim Tab-Wechsel)
- [ ] Backup exportieren/importieren (optional)

---

## Bekannte Unterschiede: Sideload vs. TestFlight

| | Personal Team (USB) | TestFlight (Org) |
|--|---------------------|------------------|
| Zielgruppe | Nur eigenes Gerät | Eingeladene Tester |
| Laufzeit | ~7 Tage (Development) | 90 Tage pro Build |
| NFC-Entitlements | Blockiert ohne PR #50 | Org-Team + leere Entitlements ok |
| App Store Connect | Nein | Ja |

---

## Offene PRs (Stand Aug 2026)

- [#50](https://github.com/louisthecat86/Einundzwanzig-Meetup-App/pull/50) — NFC-Entitlements entfernen
- Guide-Fix — `fix/guide-dispose-provider` (Provider in `dispose`)

Passkey-Doku (`docs/passkey-assetlinks`) ist **unabhängig** vom iOS-Release.
