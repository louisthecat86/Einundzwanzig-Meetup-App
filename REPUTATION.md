# Einundzwanzig Meetup Badge Reputation System

## Übersicht

Die Einundzwanzig Meetup App bietet ein dezentrales Reputationssystem basierend auf gesammelten Meetup-Badges. Nutzer können ihre physische Teilnahme an Meetups nachweisen und diese Reputation mit der Community teilen.

## Wie funktioniert es?

### 1. Badges sammeln
- Besuche Einundzwanzig Meetups
- Scanne den NFC-Tag am Meetup
- Erhalte ein Badge mit:
  - Meetup-Name
  - Datum
  - Bitcoin-Blockhöhe zum Zeitpunkt
  - Eindeutige Badge-ID

### 2. Reputation teilen

Die App bietet mehrere Möglichkeiten, deine Badges zu teilen:

#### A) Als Text (für Social Media)
```
🏆 MEINE EINUNDZWANZIG REPUTATION

Total Badges: 5
Meetups besucht: 3
Nostr: npub1abc...xyz

📍 Besuchte Meetups:
  • München (15.1.2026)
  • Berlin (22.1.2026)
  • Hamburg (29.1.2026)
```

#### B) Als JSON (für Verifizierung)
```json
{
  "version": "1.0",
  "user": "npub1abc...xyz",
  "total_badges": 5,
  "meetups_visited": 3,
  "badges": [
    {
      "meetup": "München",
      "date": "2026-01-15T19:00:00.000Z",
      "block": 875432,
      "hash": "a3f9b2c1e5d4f8a2"
    }
  ],
  "exported_at": "2026-02-09T12:30:00.000Z",
  "checksum": "d8e7f5a3"
}
```

#### C) Als QR-Code
- Zeige deinen QR-Code vor Ort
- Enthält alle Badges als JSON
- Kann gescannt und verifiziert werden

### 3. Reputation verifizieren

Jedes Badge hat:
- **Hash**: Eindeutige Prüfsumme aus `ID-Meetup-Datum-Block`
- **Checksum**: Gesamtprüfsumme des Exports
- **Blockzeit**: Unveränderbare Bitcoin-Blockhöhe

## Anwendungsfälle

### 1. satoshikleinanzeigen.space
- Zeige beim Verkauf deine Meetup-Reputation
- Käufer sehen: "Diese Person war bei 5 Meetups"
- Erhöht Vertrauen ohne KYC

### 2. Peer-to-Peer Handel
- QR-Code beim persönlichen Treffen zeigen
- Andere können deine Community-Aktivität prüfen

### 3. Community-Events
- Nachweis für vergünstigte Tickets
- "Nur für Mitglieder mit 3+ Badges"

### 4. Social Media
- Badge-Screenshots teilen
- Community-Engagement zeigen

## Technische Details

### Badge-Hash-Berechnung
```dart
String getVerificationHash() {
  final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
  final bytes = utf8.encode(data);
  final digest = sha256.convert(bytes);
  return digest.toString().substring(0, 16);
}
```

### Checksum-Berechnung
```dart
final jsonString = jsonEncode(data);
final checksum = sha256.convert(utf8.encode(jsonString))
                       .toString()
                       .substring(0, 8);
```

## Sicherheit & Datenschutz

- ✅ **Lokal gespeichert**: Badges liegen nur auf deinem Gerät
- ✅ **Selektives Teilen**: Du entscheidest, was du teilst
- ✅ **Pseudonym**: Nur Nostr npub, kein Realname nötig
- ✅ **Verifizierbar**: Hashes können überprüft werden
- ⚠️ **Nicht fälschungssicher**: Jemand könnte falsche Daten erstellen (in v2: Nostr-Signaturen)

## Zukünftige Features (v2)

- [ ] Nostr-Integration: Badges als signed Events
- [ ] NIP-XX: Badge-Verifikation über Relays
- [ ] Meetup-Admin-Signaturen für Badges
- [ ] Badge-Marketplace: Seltene Badges handeln
- [ ] Reputation-Score-Berechnung
- [ ] Web-Verifizierungstool

## Für Entwickler

### Badge-Export verwenden

```dart
import 'package:einundzwanzig_meetup_app/models/badge.dart';

// Badges exportieren
final badges = await MeetupBadge.loadBadges();
final json = MeetupBadge.exportBadgesForReputation(badges, userNpub);

// Als String teilen
await Share.share(json);

// Badge-Hash prüfen
final hash = badge.getVerificationHash();
print('Badge Hash: $hash');
```

### JSON-Schema

Siehe `lib/models/badge.dart` für die vollständige Implementierung.

## Support & Feedback

- GitHub Issues: [louisthecat86/Einundzwanzig-Meetup-App](https://github.com/louisthecat86/Einundzwanzig-Meetup-App)
- Telegram: @einundzwanzig
- Nostr: npub1einundzwanzig...

---

**Disclaimer**: Dieses System dient als soziales Reputationssignal, nicht als kryptografischer Identitätsnachweis. Für v2 ist eine Integration mit Nostr-Signaturen geplant.
