# Einundzwanzig Meetup — Reputation System

## Übersicht

Das Reputationssystem der Einundzwanzig Meetup App übersetzt **physische Meetup-Teilnahme** in **kryptographisch verifizierbare Reputation** — ohne zentrale Datenbank, ohne KYC, ohne Vertrauensvorschuss.

---

## Wie funktioniert es?

### 1. Badges sammeln

- Besuche ein Bitcoin-Meetup.
- Scanne den **NFC-Tag** oder den **Rolling-QR-Code** des Organisators.
- Die App verifiziert automatisch:
  - Schnorr-Signatur (BIP-340) des Organisators
  - Ablauf-/Zeitfenstergültigkeit
  - Admin-Registry-Status des Signers
- Bei Erfolg wird ein **Badge** lokal gespeichert.

### 2. Claim-Binding (Badge an dich binden)

- Nach dem Scan erstellt die App automatisch eine **Claim-Signatur** (Nostr Kind 21002).
- Damit ist das Badge kryptographisch an **deine** Nostr-Identität gebunden.
- Ohne Claim-Binding zählt ein Badge **nicht** für die Reputation.

### 3. Trust Score

Aus allen gebundenen Badges berechnet die App einen **Trust Score**, der folgende Faktoren gewichtet:

| Faktor | Beschreibung |
|--------|-------------|
| **Aktivität** | Summe gewichteter Badge-Werte |
| **Diversität** | Verschiedene Meetups x verschiedene Organisatoren |
| **Reife** | Account-Alter (max. Einfluss nach 180 Tagen) |
| **Qualität** | Vertrauenswürdigkeit der Signer (Veteran-Bonus) |
| **Time Decay** | Halbwertszeit 26 Wochen — alte Badges verlieren an Gewicht |
| **Frequency Cap** | Max. 2 Badges pro Woche zählen (Anti-Farming) |

**Trust Level:**

| Score | Level |
|-------|-------|
| >= 40 | VETERAN |
| >= 20 | ETABLIERT |
| >= 10 | AKTIV |
| >= 3  | STARTER |
| < 3   | NEU |

### 4. Reputation teilen

Die Reputation kann geteilt werden als:

- **QR-Code** — enthält signierte Reputation-Daten, vor Ort vorzeigbar
- **Nostr-Event** — wird als Kind 30078 auf Relays publiziert, von jedem abrufbar
- **Text/JSON** — für Social Media oder direkte Weitergabe

### 5. Reputation verifizieren

Ein Verifizierer prüft:

1. **Organisator-Signatur** (Schnorr/BIP-340)
2. **Claim-Signatur** des Sammlers
3. **Badge Proof Hash** (SHA-256 über alle gebundenen Badges)
4. **Admin-Registry** — ist der Signer ein bekannter Organisator?
5. Optional: Plattform-Proofs, Social Graph, Humanity-Proof, NIP-05

---

## Multi-Layer Identity

Neben Badges fließen weitere Signale in die Reputation ein:

| Layer | Beschreibung | Implementierung |
|-------|-------------|----------------|
| **Meetup-Badges** | Kernschicht — physische Präsenz | `badge_claim_service.dart`, `trust_score_service.dart` |
| **Plattform-Proofs** | Verknüpfte Accounts (z. B. Telegram, Twitter) | `platform_proof_service.dart` |
| **Social Graph** | Nostr-Follows, Mutuals, Common Contacts | `social_graph_service.dart` |
| **Lightning/Zaps** | Zap-Aktivität als Echtheitssignal | `zap_verification_service.dart` |
| **Humanity Proof** | Lightning-Zahlung = Anti-Bot | `humanity_proof_service.dart` |
| **NIP-05** | Domain-basierte Identitätsprüfung | `nip05_service.dart` |

---

## Datenschutz

- Auf Relays werden **nur aggregierte Zahlen** publiziert (Score, Badge-Anzahl, Signer-Anzahl etc.).
- **Keine** Meetup-Namen, Orte oder Besuchsdaten.
- Der `badge_proof_hash` beweist kryptographisch, welche Badges verwendet wurden — **ohne** Details preiszugeben.
- Plattform-Proofs werden **nur** publiziert, wenn der Nutzer sie explizit erstellt hat.

---

## Anwendungsfälle

### P2P-Handel (z. B. satoshikleinanzeigen.space)
Zeige QR-Code → Gegenüber sieht verifizierbare Community-Reputation → Vertrauen ohne KYC.

### Meetup-Events
Badge-Wallet als Teilnahmenachweis, z. B. für vergünstigte Tickets oder Community-Zugang.

### Social Media / Nostr
Reputation als signiertes Event (Kind 30078) auf Relays publizieren, von jedem Client abrufbar.

---

## Technische Referenz

### Badge Proof Hash (v2)

```dart
// Nur gebundene Badges (mit Claim-Signatur) werden einbezogen
final bound = badges.where((b) => b.isFullyBound).toList();
bound.sort((a, b) => a.claimTimestamp.compareTo(b.claimTimestamp));
final proofChain = bound.map((b) => b.claimProofId).join('|');
return sha256.convert(utf8.encode(proofChain)).toString();
```

### Reputation Event (Nostr Kind 30078)

```json
{
  "version": 2,
  "identity": { "nickname": "..." },
  "stats": {
    "score": 7.2,
    "level": "AKTIV",
    "total_badges": 8,
    "verified_badges": 8,
    "bound_badges": 7,
    "meetup_count": 4,
    "signer_count": 3,
    "account_age_days": 120,
    "since": "2025-11"
  },
  "proof": {
    "badge_proof_hash": "a3f9b2c1...",
    "proof_version": 2
  },
  "humanity_proof": {
    "verified": true,
    "method": "lightning_zap",
    "first_zap_at": 1739905680
  },
  "updated_at": 1739927280
}
```

### Sybil-Erkennung

Die App erkennt automatisch verdächtige Muster:
- Alle Badges von nur einem Signer
- Viele Badges am selben Tag
- Keine Co-Attestors bei keinem Badge

---

## Quellcode-Referenz

| Datei | Funktion |
|-------|----------|
| `lib/models/badge.dart` | Badge-Modell, Proof-Hash, verschlüsselte Persistenz |
| `lib/services/trust_score_service.dart` | Score-Berechnung, Bootstrap-Phasen, Promotion |
| `lib/services/badge_claim_service.dart` | Claim-Binding (Kind 21002) |
| `lib/services/reputation_publisher.dart` | Relay-Publishing (Kind 30078) |
| `lib/screens/reputation_qr.dart` | QR-Erstellung + Teilen |
| `lib/screens/reputation_verify_screen.dart` | Verifizierung eingehender Reputation |
| `lib/screens/qr_scanner.dart` | Scanner für Reputation-QRs |
