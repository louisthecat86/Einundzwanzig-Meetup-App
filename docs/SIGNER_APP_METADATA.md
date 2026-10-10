# App-Name und Symbol in Clave

Clave identifiziert eine NIP-46-Verbindung anhand der vom Client übermittelten
Metadaten. Das installierte iOS-App-Symbol wird dabei nicht automatisch gelesen.
Fehlen diese Angaben, erscheint stattdessen der Sitzungsschlüssel mit einem
generischen Avatar, wie in den gemeldeten Screenshots.

Die App sendet jetzt für beide Kopplungswege dieselben öffentlichen Angaben aus
`lib/services/nip46/client_metadata.dart`:

- `bunker://`: JSON mit `name`, `url` und `image` als vierten Parameter der
  verschlüsselten `connect`-Anfrage. Ohne Geheimnis bleibt Position zwei leer.
- `nostrconnect://` (QR-Code oder Deep-Link): `name`, `url` und `image` als
  URL-kodierte Query-Parameter.

Der App-Name verwendet `%20` für Leerzeichen. Die bisherige Formularkodierung
mit `+` wurde von Clave wörtlich angezeigt. Ein echtes Pluszeichen wird weiterhin
als `%2B` kodiert; Umlaute und andere Sonderzeichen bleiben erhalten.

Die Projektadresse dient als App-URL. Das vorhandene native 180×180-PNG wird über die
öffentliche HTTPS-Raw-Adresse des Hauptprojekts geladen; lokale Asset-Pfade sind
für Clave nicht erreichbar. Die Adresse lieferte bei der Prüfung HTTP 200 und
`image/png`. Eine spätere eigene App-Domain kann zentral eingetragen werden.

## Auf einem iPhone prüfen

1. Eine Version mit dieser Änderung installieren.
2. Eine neue Clave-Verbindung über eine eingefügte Bunker-Adresse herstellen.
3. Prüfen, ob Clave „Einundzwanzig Meetup“ und das App-Symbol zeigt.
4. Dasselbe mit dem von der App erzeugten QR-Code / Deep-Link prüfen.
5. Eine Signaturanfrage bestätigen und die App neu starten, um die gespeicherte
   Sitzung zu prüfen.

Bestehende Sitzungen werden beim Wiederherstellen nicht erneut gekoppelt und
erhalten deshalb nicht automatisch neue Metadaten. Für diese Verbindungen nach
dem Update neu koppeln. Alte Einträge erst entfernen, wenn die neue Verbindung
funktioniert. Die tatsächliche Anzeige in Clave muss auf dem Gerät geprüft
werden; die automatisierten Tests prüfen die entschlüsselten Transportdaten.

Referenzen:

- [NIP-46: Client metadata](https://github.com/nostr-protocol/nips/blob/master/46.md#client-metadata)
- [Gemergte Erweiterung für Bunker-Verbindungen](https://github.com/nostr-protocol/nips/pull/2381)

## Testabdeckung

Die automatisierten Tests prüfen entschlüsselte `connect`-Metadaten mit und ohne
Bunker-Geheimnis, die URI-Kodierung für native Parser und den tatsächlichen
`SigningService.startNip46Pairing()`-Ablauf. Neue Kopplungen behalten App-Name,
URL und Symbol, erhalten aber neue Sitzungsschlüssel und Geheimnisse. Der private
Sitzungsschlüssel darf nicht in der QR-Adresse stehen. Abbrechen aktiviert keine
Signer-Sitzung.

Die CI führt die NIP-46-Transportsuite zusätzlich in Chrome aus. Die Reaktionszeit
auf Relay-Ablehnungen wird ab Eingang der Ablehnung gemessen, damit die im Browser
langsamere Verschlüsselung nicht fälschlich als Transportverzögerung zählt.

Der Nutzer bestätigte am 10.10.2026 mit Clave auf einem echten iPhone und
dem Simulator-Build beide Kopplungswege einzeln: Name, Symbol und das mit `%20`
kodierte Leerzeichen wurden korrekt angezeigt; auch eine Signaturanfrage nach
einem App-Neustart wurde erfolgreich bestätigt.
