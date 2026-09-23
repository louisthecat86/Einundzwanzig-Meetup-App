# Beispielcode: Bitcoin P2P Matchmaker (Issue #62)

**Ungetesteter Implementierungsentwurf – nicht als fertiges Feature oder Release verwenden.** Der Code wurde ohne Flutter-/Dart-SDK bereitgestellt; die 18 Unit-Tests sind geschrieben, aber **nicht ausgefuehrt**. Hier kein APK-Build, kein Zwei-Geraete- oder Relay-Integrationstest.

## Umfang

- `lib/models/p2p_offer.dart`: Angebotsmodell.
- `lib/services/p2p_match_service.dart`: lokale Gegenparteisuche und Deduplizierung.
- `lib/services/p2p_nostr_service.dart`: signierte, je Termin ersetzbare Nostr-Interessen (projektspezifischer Kind 30086), Signaturpruefung, OFF-Status, Relay-Timeouts.
- `lib/screens/p2p_match_screen.dart`: Kauf/Verkauf/Aus, freiwillige Selbstauskunft, Liste und Pop-up bei geoeffneter Ansicht; 30-s-Polling.
- `test/p2p_match_service_test.dart`: 18 **noch auszufuehrende** Unit-Tests.
- Einstieg in `lib/screens/my_events_screen.dart` bei Nostr-Events und Portal-Meetups.

## Bevor dieser Entwurf gemergt wird

```sh
flutter pub get
flutter gen-l10n
dart format lib/models/p2p_offer.dart lib/services/p2p_match_service.dart lib/services/p2p_nostr_service.dart lib/screens/p2p_match_screen.dart test/p2p_match_service_test.dart
flutter analyze
flutter test test/p2p_match_service_test.dart
flutter test
flutter build apk --debug
```

Zusatztests: zwei unabhaengige Konten/Geraete, externe Signer (Amber/NIP-46), zeitlich versetzte Relay-Ereignisse inkl. OFF auf mehreren Relays, Neustart beim Pop-up, mehrdeutige Event-Identitaeten, iOS/Android sowie Datenschutz-Review.

**Grenzen:** Kein belegter physischer Check-in (nur selbst bestaetigt), kein Betriebssystem-Push bei geschlossener App, kein integrierter Direktchat. Die Relays veroeffentlichen Nostr-Pubkey + Termin + Kauf-/Verkaufsrichtung. OFF entfernt historisch verbreitete Informationen nicht sicher. Keine Fiat- oder Bitcoin-Verwahrung, keine automatische Handelsausfuehrung. Betrag/Wallet/Standort werden nicht publiziert. Nostr-Kind 30086 vor Release auf Kollisionen/Interoperabilitaet pruefen.

Dieser Branch dient als Code-Vorschlag fuer den Maintainer-Agenten; bitte korrigieren und testen, bevor irgendetwas nach `main` gemergt wird.
