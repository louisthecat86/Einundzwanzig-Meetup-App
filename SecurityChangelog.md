# Security Hardening v3.1 — Änderungsprotokoll

## Übersicht

7 Fixes, priorisiert von kritisch nach wichtig. Alle Änderungen sind rückwärtskompatibel.

---

## Fix 1: backup_service.dart — PBKDF2 Key Derivation [KRITISCH]

**Problem:** `_deriveKey()` nutzte einen einzelnen SHA-256 Hash (ohne Salt, ohne Iterationen) um den AES-Schlüssel aus dem Passwort abzuleiten. Ein Angreifer mit Zugriff auf ein Backup konnte Milliarden Passwörter pro Sekunde testen. Im Backup liegt der private Nostr-Key (nsec).

**Lösung:**
- PBKDF2-HMAC-SHA256 mit 600.000 Iterationen (OWASP-Empfehlung 2024)
- 32 Byte kryptographisch sicherer Salt pro Backup
- Neues Backup-Format: `enc_v2:[SALT]:[IV]:[CIPHERTEXT]`
- Rückwärtskompatibilität: `enc_v1` Backups können weiterhin importiert werden

**Datei:** `lib/services/backup_service.dart` → **Komplett ersetzt**

**Migration:** Keine. Neue Backups verwenden automatisch v2. Alte Backups werden beim Import über den Legacy-Pfad entschlüsselt.

---

## Fix 2: badge_security.dart — Whitelist + createdAt-Bug + Legacy-Alias [HOCH]

**Problem 1 (Whitelist):** `verifyCompact()` nutzte eine Blacklist (`_nonContentKeys`) um signierte Content-Felder zu identifizieren. Unbekannte Felder wurden automatisch in den signierten Content aufgenommen → Angreifer konnte Felder injizieren.

**Lösung:** Whitelist `{'v', 't', 'm', 'b', 'x'}` — nur bekannte Content-Felder werden verwendet.

**Problem 2 (createdAt):** `verifyNostr()` verwendete `block_height` als `createdAt` Fallback. Block Height ≠ Unix Timestamp → Event-ID-Rekonstruktion inkonsistent → Verifikation schlägt fehl oder akzeptiert falsche Events.

**Lösung:** `createdAt` wird aus dem gespeicherten `created_at` Feld gelesen. Ohne dieses Feld → Verifikation schlägt fehl (fail-secure). `signWithNostr()` speichert jetzt `created_at` mit.

**Problem 3 (Legacy-Alias):** `sign()` war ein Alias für `signLegacy()` — sah sicher aus, nutzte aber nur HMAC mit festem Secret.

**Lösung:** `sign()` Alias entfernt. Code der `BadgeSecurity.sign()` aufruft bekommt einen Compile-Error und muss explizit `signLegacy()` verwenden.

**Bonus:** Pubkey- und Signatur-Format-Validierung hinzugefügt (64 bzw. 128 Hex-Zeichen).

**Datei:** `lib/services/badge_security.dart` → **Komplett ersetzt**

---

## Fix 3: rolling_qr_service.dart — Sicherer Session-Seed [HOCH]

**Problem:** Der Session-Seed wurde aus dem Private Key abgeleitet:
```dart
final seedInput = '$privHex:$meetupId:$now';
final seed = sha256.convert(utf8.encode(seedInput)).toString();
```
Das leakt Information über den Private Key. Gleiche Inputs → gleicher Seed.

**Lösung:** 256 Bit kryptographisch sicherer Zufall via `Random.secure()`. Keine Verbindung zum Private Key. Jede Session hat einen garantiert einzigartigen Seed.

**Bonus:** Dokumentation der Nonce-Validierungs-Limitation (Scanner kann HMAC nicht verifizieren — by design).

**Datei:** `lib/services/rolling_qr_service.dart` → **Komplett ersetzt**

---

## Fix 4: badge-verifier.html — Echte Schnorr-Verifikation [HOCH]

**Problem:** Der HTML-Verifier prüfte nur eine SHA-256 Checksum. Keine Schnorr-Verifikation, keine Event-ID-Rekonstruktion, keine Pubkey-Validierung. Jeder konnte Badge + Checksum neu berechnen → Verifier akzeptierte es.

**Lösung:** Kompletter Rewrite mit:
- noble-secp256k1 JS-Library (audited) für echte BIP-340 Schnorr-Verifikation
- Event-ID-Rekonstruktion aus Canonical JSON
- Organizer-Pubkey-Validierung (Format + Signatur)
- Einzelverifikation jedes Badges mit detailliertem Status
- Unterstützung für Kompakt-Format (v2) und Legacy-Nostr-Format

**Datei:** `badge-verifier.html` → **Komplett ersetzt**

---

## Fix 5: badge.dart — Co-Signatur-Protokoll [MITTEL]

**Problem:** Badges sind nicht an den Teilnehmer gebunden. Ein gescannter NFC-Tag/QR kann kopiert und von einem anderen User verwendet werden.

**Lösung: Co-Signatur-Protokoll**

Nach dem Scannen signiert der Teilnehmer den Badge-Hash mit seinem eigenen Nostr-Key:
```
participantSig = SchnorrSign(SHA256(proofId + participantPubkey), participantPrivKey)
```

Dadurch:
- Badge ist NICHT übertragbar (ohne den Private Key des Teilnehmers)
- Besitz ist kryptographisch beweisbar
- Manipulation der Badge-Liste ist erkennbar

**Signierter Export (v4):**
- Export wird mit Schnorr signiert
- Manipulation (Badges hinzufügen/entfernen) → Signatur bricht
- Export-Version auf 4.0 erhöht

**Neue Felder in MeetupBadge:**
- `participantPubkey` (String, hex64)
- `participantSig` (String, hex128)

**Neue Methoden:**
- `MeetupBadge.createWithCoSignature(badge)` — async, erstellt Co-Signatur
- `badge.verifyCoSignature()` — prüft Co-Signatur
- `MeetupBadge.countBoundBadges(badges)` — zählt gebundene Badges
- `exportBadgesForReputation()` → jetzt `async` (signiert den Export)

**Datei:** `lib/models/badge.dart` → **Komplett ersetzt**

---

## Fix 6: meetup_verification.dart — Co-Signatur bei Sammlung [MITTEL]

**Änderung:** In `_processFoundTagData()` wird nach dem Erstellen des Badge-Objekts `MeetupBadge.createWithCoSignature()` aufgerufen, bevor das Badge in die Liste aufgenommen wird.

**Datei:** `PATCH_meetup_verification.dart` → **Chirurgische Änderung**

Ersetze in `_processFoundTagData()` den Block:
```dart
myBadges.add(MeetupBadge(...));
await MeetupBadge.saveBadges(myBadges);
```
mit:
```dart
var newBadge = MeetupBadge(...);
newBadge = await MeetupBadge.createWithCoSignature(newBadge);
myBadges.add(newBadge);
await MeetupBadge.saveBadges(myBadges);
```

---

## Fix 7: reputation_qr.dart — Async Export [MINOR]

**Änderung:** `exportBadgesForReputation()` ist jetzt async. Alle Aufrufe brauchen `await`.

**Datei:** `PATCH_reputation_qr.dart` → **Chirurgische Änderung**

Suche im Projekt nach `MeetupBadge.exportBadgesForReputation(` und stelle sicher, dass überall `await` davor steht.

---

## Implementierungs-Reihenfolge

1. **backup_service.dart** ersetzen (keine Abhängigkeiten)
2. **badge_security.dart** ersetzen (keine neuen Abhängigkeiten)
3. **rolling_qr_service.dart** ersetzen (keine neuen Abhängigkeiten)
4. **badge.dart** ersetzen (importiert jetzt `secure_key_store.dart` und `badge_security.dart`)
5. **meetup_verification.dart** patchen (nutzt neues `badge.dart`)
6. **reputation_qr.dart** patchen (async export)
7. **badge-verifier.html** ersetzen (standalone, keine App-Abhängigkeiten)

## Keine neuen Dependencies

Alle Fixes nutzen bestehende Dependencies (`crypto`, `nostr`, `flutter_secure_storage`). Keine neuen Packages in pubspec.yaml nötig.

## Rückwärtskompatibilität

- Alte Backups (enc_v1) → werden weiterhin importiert
- Alte Badges ohne Co-Signatur → funktionieren weiterhin (participantSig ist optional)
- Alte Badges ohne created_at → verifyNostr() gibt false zurück (fail-secure)
- Legacy v1 Badges → werden weiterhin als "nicht vertrauenswürdig" angezeigt
- Export v3.0 → wird weiterhin von alten Verifiern akzeptiert (neue Felder werden ignoriert)