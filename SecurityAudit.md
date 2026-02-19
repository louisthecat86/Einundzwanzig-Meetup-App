# Security Audit — Patch Notes

## Übersicht

Dieses Patch-Set schließt alle identifizierten Sicherheitslücken im Einundzwanzig Meetup App Repository.
Die App-Logik bleibt unverändert — nur die Sicherheitsebene wurde gehärtet.

---

## 🚨 Fix 1: Secure Storage für private Schlüssel

**Problem:** `nsec`, `npub` und `privHex` wurden in `SharedPreferences` gespeichert — 
Klartext-XML auf dem Gerät, auslesbar über Root, ADB Backup oder Device-Cloning.

**Lösung:** Neuer zentraler `SecureKeyStore` (Wrapper um `flutter_secure_storage`):
- **Android:** EncryptedSharedPreferences (API 23+) bzw. AES + RSA-wrapped Key im Android Keystore
- **iOS:** Keychain mit `first_unlock_this_device` Accessibility

**Automatische Migration:**  
Beim ersten Start nach dem Update werden vorhandene Keys aus SharedPreferences 
in SecureStorage migriert und anschließend aus SharedPreferences gelöscht.

**Geänderte Dateien:**
| Datei | Änderung |
|-------|----------|
| `lib/services/secure_key_store.dart` | **NEU** — Zentraler Secure Storage Wrapper |
| `lib/services/nostr_service.dart` | SharedPreferences → SecureKeyStore |
| `lib/services/badge_security.dart` | SharedPreferences → SecureKeyStore |
| `lib/services/rolling_qr_service.dart` | Private Key aus SecureKeyStore laden |
| `lib/services/admin_registry.dart` | Private Key aus SecureKeyStore laden |
| `lib/services/backup_service.dart` | Keys aus SecureKeyStore lesen/schreiben |
| `lib/models/user.dart` | `hasKey`-Check über SecureKeyStore |
| `lib/main.dart` | Migration beim App-Start |
| `pubspec.yaml` | `flutter_secure_storage: ^9.2.4` hinzugefügt |

---

## 🚨 Fix 2: Admin-Registry Check im Scanner

**Problem:** Der Badge-Scanner in `meetup_verification.dart` prüfte nur ob die Schnorr-Signatur 
**mathematisch gültig** ist — aber NICHT ob der Signer ein bekannter Admin ist.  
→ Jeder mit einem Nostr-Keypair konnte gültig signierte Fake-Badges erstellen.

**Lösung:** Nach dem Schnorr-Check wird der Signer-Pubkey gegen die `AdminRegistry` geprüft:
- ✅ **Bekannter Admin** → Grünes Häkchen + Admin-Name
- ❌ **Unbekannter Signer** → Orange Warnung + deutliche Meldung "UNBEKANNTER SIGNER"
- ⚠️ **Offline / Cache-Miss** → Hinweis dass Status nicht geprüft werden konnte

**Neue Methode:** `AdminRegistry.checkAdminByPubkey(String pubkeyHex)` — 
konvertiert PubkeyHex → npub und prüft gegen Cache + Relay.

**Geänderte Dateien:**
| Datei | Änderung |
|-------|----------|
| `lib/screens/meetup_verification.dart` | Admin-Registry Check nach Signatur-Verifikation |
| `lib/services/admin_registry.dart` | Neue Methode `checkAdminByPubkey()` |

---

## 🔴 Fix 3: Legacy v1 als unsicher markiert

**Problem:** `badge_security.dart` enthält ein hardcoded Shared Secret:
```
static const String _appSecret = "einundzwanzig_community_secret_21_btc_rocks";
```
Sobald der Code öffentlich ist, kann jeder gültige v1-Badges fälschen.

**Lösung:** Legacy-Signaturen (v1) werden jetzt in der UI klar als unsicher markiert:
- `verify()` gibt bei v1 die Message `⚠️ Legacy-Signatur (v1) — nicht vertrauenswürdig` zurück
- `verifyQRLegacy()` ebenso

Das Secret bleibt für Rückwärtskompatibilität erhalten (alte Tags lesen),
wird aber nicht mehr für neue Signierungen empfohlen.

**Geänderte Dateien:**
| Datei | Änderung |
|-------|----------|
| `lib/services/badge_security.dart` | Legacy v1 Messages als "nicht vertrauenswürdig" |

---

## 🟡 Fix 4: JSON Kanonisierung

**Problem:** `signCompact()` und `verifyCompact()` nutzen `jsonEncode()` direkt.
Dart's `LinkedHashMap` behält zwar die Insertions-Reihenfolge, aber dies ist 
nicht sprachspezifisch garantiert und kann bei Transformationen brechen.

**Lösung:** Neue Methode `canonicalJsonEncode()` die Keys vor dem Encoding 
alphabetisch sortiert → deterministischer Hash unabhängig von Map-Implementierung.

Wird konsistent in `signCompact()`, `verifyCompact()`, `signWithNostr()` und 
`verifyNostr()` verwendet.

**Geänderte Dateien:**
| Datei | Änderung |
|-------|----------|
| `lib/services/badge_security.dart` | Neue `canonicalJsonEncode()` Methode |

---

## 🟡 Fix 5: Toter Code aufgeräumt

**Problem:** Mehrere Artefakte eines alten Passwort-Systems sind noch im Code:
- `adminSecret = "21"` im Meetup-Model
- `'password'` im `promotionSource`-Kommentar
- `NostrService.verify()` war kaputt (generierte neuen Timestamp bei jedem Aufruf → Hash stimmt nie)

**Lösung:**
- `adminSecret` komplett aus `Meetup`-Model entfernt
- `promotionSource`-Kommentar bereinigt (nur noch `'trust_score'`, `'seed_admin'`)
- `NostrService.verify()` erhält jetzt alle nötigen Parameter (`eventId`, `createdAt`) statt sie neu zu generieren

**Geänderte Dateien:**
| Datei | Änderung |
|-------|----------|
| `lib/models/meetup.dart` | `adminSecret` Feld entfernt |
| `lib/models/user.dart` | `promotionSource` Kommentar bereinigt |
| `lib/services/nostr_service.dart` | `verify()` korrigiert |

---

## ⚠️ Noch offen (Empfehlungen für Post-Beta)

1. **Passwort-Referenzen in Markdown-Dateien entfernen:**  
   `QUICKSTART_APK.md`, `REPUTATION.md` enthalten noch `#21AdminTag21#`. 
   Diese sollten manuell bereinigt werden.

2. **Legacy v1 komplett entfernen:**  
   Sobald alle NFC-Tags mit v2-Signaturen überschrieben sind, 
   kann `signLegacy()` / `verifyLegacy()` entfernt werden.

3. **Schnorr-Library Audit:**  
   Das `nostr`-Package nutzt intern `secp256k1`. Ein unabhängiger 
   Audit der BIP-340 Implementierung wird für Public Release empfohlen.

4. **Android minSdkVersion:**  
   Aktuell 21. `flutter_secure_storage` mit `encryptedSharedPreferences: true`
   benötigt API 23+. Auf API 21-22 Geräten fällt die Library auf AES-Verschlüsselung
   mit RSA-wrapped Key zurück — funktional aber weniger sicher als EncryptedSharedPreferences.
   Erwäge `minSdkVersion` auf 23 anzuheben (betrifft < 1% der Geräte).

---

## Datei-Übersicht (alle geänderten / neuen Dateien)

```
lib/
├── main.dart                              ← GEÄNDERT (Migration beim Start)
├── models/
│   ├── meetup.dart                        ← GEÄNDERT (adminSecret entfernt)
│   └── user.dart                          ← GEÄNDERT (SecureKeyStore, Kommentar)
├── screens/
│   └── meetup_verification.dart           ← GEÄNDERT (Admin-Registry Check)
└── services/
    ├── secure_key_store.dart              ← NEU (Secure Storage Wrapper)
    ├── nostr_service.dart                 ← GEÄNDERT (SecureKeyStore)
    ├── badge_security.dart                ← GEÄNDERT (SecureKeyStore, Canonical JSON, Legacy-Warnung)
    ├── rolling_qr_service.dart            ← GEÄNDERT (SecureKeyStore)
    ├── admin_registry.dart                ← GEÄNDERT (SecureKeyStore, checkAdminByPubkey)
    └── backup_service.dart                ← GEÄNDERT (SecureKeyStore)

pubspec.yaml                               ← GEÄNDERT (flutter_secure_storage)
```