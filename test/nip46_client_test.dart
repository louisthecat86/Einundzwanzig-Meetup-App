// Prueft den NIP-46-Transport gegen einen SIMULIERTEN, aber echten Signer:
// der Gegenpart im Test entschluesselt die Anfragen wirklich mit NIP-44 und
// verschluesselt seine Antworten zurueck. Damit laeuft der ganze Weg durch —
// Schluesselableitung, kind-24133-Rahmen, Zuordnung ueber die Anfrage-id.
//
// Ein Test mit vorgefertigten Antwort-Objekten wuerde genau das ueberspringen,
// was im Betrieb schiefgeht.

import 'dart:async';
import 'dart:convert';

import 'package:einundzwanzig_meetup_app/services/nip44.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/bunker_uri.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/client_metadata.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/nip46_client.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/nip46_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nostr/nostr.dart';

/// Ein Relay, das nichts weiterleitet, sondern direkt den Test-Signer bedient.
class _FakeLink implements Nip46RelayLink {
  final String url;
  final void Function(_FakeLink link, String frame) onFrame;

  /// Simuliert einen Socket, der nach dem Abonnieren gestorben ist.
  final bool throwOnEvent;
  final _controller = StreamController<dynamic>.broadcast();
  final List<String> sentFrames = [];
  bool closed = false;

  _FakeLink(this.url, this.onFrame, {this.throwOnEvent = false});

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  void add(String frame) {
    if (throwOnEvent && frame.startsWith('["EVENT"')) {
      throw StateError('Socket ist tot (Test)');
    }
    sentFrames.add(frame);
    onFrame(this, frame);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void push(Map<String, dynamic> event) {
    if (!_controller.isClosed) {
      _controller.add(jsonEncode(['EVENT', 'sub', event]));
    }
  }

  /// Beliebiger Relay-Rahmen, z. B. `["OK", …]` oder `["CLOSED", …]`.
  void pushRaw(String frame) {
    if (!_controller.isClosed) _controller.add(frame);
  }
}

/// Gegenpart mit echtem Schluesselpaar. Entschluesselt jede Anfrage und
/// antwortet nach der vom Test gesetzten Regel.
class _FakeSigner {
  final Keychain keys;
  final List<Map<String, dynamic>> requests = [];
  final List<_FakeLink> links = [];

  /// Rueckgabe null => keine Antwort (fuer den Timeout-Pfad).
  Map<String, dynamic>? Function(Map<String, dynamic> request) respond;

  /// Relays, die beim Oeffnen scheitern sollen.
  Set<String> failingRelays = {};

  /// Relays, die sich oeffnen lassen, aber beim Senden scheitern.
  Set<String> deadAfterOpen = {};

  /// Relays, die das Ereignis mit `["OK", …, false, Grund]` abweisen. Der
  /// Signer sieht es dann nie.
  Set<String> rejectingRelays = {};
  String rejectReason = 'rate-limited: slow down';
  final rejectionLatency = Stopwatch();

  /// Antworten von ALLEN Relays statt nur vom ersten schicken.
  bool answerFromAllRelays = false;

  _FakeSigner({Map<String, dynamic>? Function(Map<String, dynamic>)? respond})
      : keys = Keychain.generate(),
        respond = respond ?? ((r) => {'id': r['id'], 'result': 'ack'});

  String get pubkey => keys.public;

  Future<Nip46RelayLink> open(String url) async {
    if (failingRelays.contains(url)) {
      throw StateError('Relay $url ist unerreichbar (Test)');
    }
    final link = _FakeLink(url, _handleFrame,
        throwOnEvent: deadAfterOpen.contains(url));
    links.add(link);
    return link;
  }

  void _handleFrame(_FakeLink link, String frame) {
    final decoded = jsonDecode(frame) as List;
    if (decoded.first != 'EVENT') return; // REQ ignorieren
    final event = decoded[1] as Map<String, dynamic>;

    // Wie ein echtes Relay: jede Veroeffentlichung wird bestaetigt oder
    // abgewiesen. Der gute Fall laeuft dadurch in allen Tests mit ueber ein
    // ["OK", …, true, …] — so faellt auf, wenn das die Zuordnung stoert.
    if (rejectingRelays.contains(link.url)) {
      rejectionLatency.start();
      link.pushRaw(jsonEncode(['OK', event['id'], false, rejectReason]));
      return; // abgewiesen: der Signer bekommt es nie zu sehen
    }
    link.pushRaw(jsonEncode(['OK', event['id'], true, '']));

    final clientPubkey = event['pubkey'] as String;
    final key = Nip44.conversationKey(
        privkeyHex: keys.private, pubkeyHex: clientPubkey);
    final request =
        jsonDecode(Nip44.decrypt(event['content'] as String, key)) as Map;
    requests.add(request.cast<String, dynamic>());

    final answer = respond(request.cast<String, dynamic>());
    if (answer == null) return;

    final targets = answerFromAllRelays ? links : [link];
    for (final target in targets) {
      target.push(_wrap(answer, clientPubkey));
    }
  }

  /// Baut ein kind-24133-Antwortereignis. Absender ueberschreibbar, um einen
  /// fremden Signer zu simulieren.
  Map<String, dynamic> _wrap(Map<String, dynamic> payload, String toPubkey,
      {Keychain? as}) {
    final signer = as ?? keys;
    final key = Nip44.conversationKey(
        privkeyHex: signer.private, pubkeyHex: toPubkey);
    return {
      'kind': 24133,
      'pubkey': signer.public,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'tags': [
        ['p', toPubkey]
      ],
      'content': Nip44.encrypt(jsonEncode(payload), key),
      'sig': '00' * 32,
    };
  }

  /// Schickt eine Antwort, die von einem GANZ ANDEREN Schluessel kommt.
  void pushFromStranger(Map<String, dynamic> payload, String toPubkey) {
    final stranger = Keychain.generate();
    for (final link in links) {
      link.push(_wrap(payload, toPubkey, as: stranger));
    }
  }
}

void main() {
  const relayA = 'wss://relay-a.test';
  const relayB = 'wss://relay-b.test';
  const shortLimit = Duration(milliseconds: 300);

  late _FakeSigner signer;
  late String clientKey;

  Nip46Client build({
    List<String> relays = const [relayA],
    bool paired = true,
    void Function(String)? onAuthUrl,
  }) =>
      Nip46Client(
        clientSecretKeyHex: clientKey,
        relays: relays,
        remoteSignerPubkey: paired ? signer.pubkey : null,
        onAuthUrl: onAuthUrl,
        debugTimeout: shortLimit,
        debugOpenRelay: signer.open,
      );

  setUp(() {
    signer = _FakeSigner();
    clientKey = Nip46Client.generateClientKey();
  });

  group('RPC-Weg', () {
    test('sign_event: Anfrage kommt entschluesselt an, Antwort kommt zurueck',
        () async {
      final unsigned = {
        'kind': 21000,
        'created_at': 1700000000,
        'tags': [
          ['d', 'badge']
        ],
        'content': 'Badge-Signatur',
      };
      signer.respond = (request) => {
            'id': request['id'],
            'result': jsonEncode({
              ...jsonDecode((request['params'] as List).first as String) as Map,
              'id': 'a' * 64,
              'pubkey': 'b' * 64,
              'sig': 'c' * 128,
            }),
          };

      final client = build();
      final signed = await client.signEvent(unsigned);

      expect(signer.requests, hasLength(1));
      expect(signer.requests.single['method'], 'sign_event');
      // Der Signer hat den Inhalt wirklich gelesen — also stimmte die
      // NIP-44-Verschluesselung in beide Richtungen.
      final received = jsonDecode(
          (signer.requests.single['params'] as List).first as String) as Map;
      expect(received['kind'], 21000);
      expect(received['content'], 'Badge-Signatur');

      expect(signed['sig'], 'c' * 128);
      expect(signed['kind'], 21000);
      await client.close();
    });

    test('get_public_key liefert den Nutzer-pubkey', () async {
      final userKey = Keychain.generate().public;
      signer.respond = (r) => {'id': r['id'], 'result': userKey};

      final client = build();
      expect(await client.getPublicKey(), userKey);
      await client.close();
    });

    test('connect fragt Rechte fuer alle signierten kinds an', () async {
      final client = build();
      await client.connect(secret: 'geheim123');

      final params = signer.requests.single['params'] as List;
      expect(params[0], signer.pubkey);
      expect(params[1], 'geheim123');
      expect(params, hasLength(4));
      expect(jsonDecode(params[3] as String), Nip46ClientMetadata.values);
      final perms = params[2] as String;
      expect(perms, contains('get_public_key'));
      for (final kind in Nip46Client.signedKinds) {
        expect(perms, contains('sign_event:$kind'),
            reason: 'kind $kind fehlt in den angefragten Rechten');
      }
      await client.close();
    });

    test(
      'connect ohne Geheimnis belaesst Metadaten an vierter Position',
      () async {
        final client = build();
        await client.connect();
        final params = signer.requests.single['params'] as List;
        expect(params, hasLength(4));
        expect(params[0], signer.pubkey);
        expect(params[1], '');
        expect(params[2], Nip46Client.requestedPerms);
        expect(jsonDecode(params[3] as String), Nip46ClientMetadata.values);
        await client.close();
      },
    );

    test('ping erkennt eine lebende Sitzung', () async {
      signer.respond = (r) => {'id': r['id'], 'result': 'pong'};
      final client = build();
      expect(await client.ping(), isTrue);
      await client.close();
    });

    test('ping meldet false, wenn der Signer schweigt', () async {
      signer.respond = (_) => null;
      final client = build();
      expect(await client.ping(), isFalse);
      await client.close();
    });

    test('CLOSED droppt den Link — naechste Anfrage baut neu auf', () async {
      signer.respond = (r) => {'id': r['id'], 'result': 'pong'};
      final client = build();
      expect(await client.ping(), isTrue);
      expect(signer.links, hasLength(1));
      final first = signer.links.single;

      first.pushRaw(jsonEncode(['CLOSED', 'sub', 'auth-required: login']));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(first.closed, isTrue,
          reason: 'nach CLOSED muss der Socket freigegeben werden');

      expect(await client.ping(), isTrue);
      expect(signer.links.length, greaterThan(1),
          reason: 'ohne Drop bliebe die tote Subscription in _links und '
              'es gaebe keinen Neuaufbau');
      await client.close();
    });
  });

  group('Fehlerwege', () {
    test('Fehlerantwort des Signers wird durchgereicht', () async {
      signer.respond =
          (r) => {'id': r['id'], 'error': 'Nutzer hat abgelehnt'};
      final client = build();
      await expectLater(
        client.connect(),
        throwsA(isA<Nip46RemoteException>().having(
            (e) => e.message, 'message', 'Nutzer hat abgelehnt')),
      );
      await client.close();
    });

    test('Schweigen laeuft in Nip46TimeoutException mit Methodennamen',
        () async {
      signer.respond = (_) => null;
      final client = build();
      await expectLater(
        client.signEvent({'kind': 1, 'content': '', 'tags': []}),
        throwsA(isA<Nip46TimeoutException>()
            .having((e) => e.method, 'method', 'sign_event')),
      );
      await client.close();
    });

    test('Antwort eines fremden Absenders wird verworfen UND gezaehlt',
        () async {
      // Der echte Signer schweigt; ein Fremder schickt eine passende id.
      signer.respond = (request) {
        signer.pushFromStranger(
          {'id': request['id'], 'result': 'ack'},
          Keychain(clientKey).public,
        );
        return null;
      };
      final client = build();
      await expectLater(
        client.connect(),
        // Der Zaehler ist der Punkt: ohne ihn waere "unlesbar: 0" scheinbar
        // ein Beweis, dass ueberhaupt nichts angekommen ist.
        throwsA(isA<Nip46TimeoutException>()
            .having((e) => e.foreignSender, 'foreignSender', greaterThan(0))
            .having((e) => e.undecryptable, 'undecryptable', 0)),
      );
      await client.close();
    });

    test('Ablehnung durch alle Relays meldet den Grund statt zu warten',
        () async {
      signer.rejectingRelays = {relayA};
      signer.rejectReason = 'blocked: pubkey not allowed';
      final client = build();

      await expectLater(
        client.connect(),
        throwsA(isA<Nip46RelayRejectedException>()
            .having((e) => e.reason, 'reason', 'blocked: pubkey not allowed')
            // Die Oberflaeche zeigt `message`: der Grund MUSS dort drinstehen,
            // sonst sieht der Nutzer wieder nur "irgendwas ging schief".
            .having((e) => e.message, 'message',
                contains('blocked: pubkey not allowed'))),
      );
      signer.rejectionLatency.stop();

      // Der eigentliche Gewinn: es wird NICHT die Frist abgewartet.
      // Ab Relay-Ablehnung messen: die vorherige Verschluesselung kann im
      // Browser laenger dauern als die fuer den Test verkuerzte RPC-Frist.
      expect(signer.rejectionLatency.elapsed, lessThan(shortLimit),
          reason: 'die Ablehnung muss sofort durchschlagen');
      expect(signer.requests, isEmpty,
          reason: 'ein abgewiesenes Ereignis erreicht den Signer nie');
      await client.close();
    });

    test('lehnt nur EIN Relay ab, laeuft die Anfrage weiter', () async {
      // Sonst wuerde ein einzelnes zickiges Relay jede Anfrage abbrechen,
      // obwohl ein anderes sie angenommen hat.
      signer.rejectingRelays = {relayA};
      final client = build(relays: [relayA, relayB]);
      await client.connect();
      expect(signer.requests, hasLength(1),
          reason: 'ueber relayB muss sie angekommen sein');
      await client.close();
    });

    test('ohne Kopplung wird nicht gesendet', () async {
      final client = build(paired: false);
      await expectLater(
        client.signEvent({'kind': 1, 'content': '', 'tags': []}),
        throwsA(isA<Nip46Exception>()),
      );
      expect(signer.requests, isEmpty);
      await client.close();
    });

    test('kein erreichbares Relay meldet einen klaren Fehler', () async {
      signer.failingRelays = {relayA};
      final client = build();
      await expectLater(
        client.connect(),
        throwsA(isA<Nip46Exception>()
            .having((e) => e.message, 'message', contains('erreichbar'))),
      );
      await client.close();
    });

    // Der Socket steht beim Abonnieren noch und ist beim Senden tot. Ohne die
    // Pruefung auf "an niemanden gesendet" wartet der Nutzer die vollen
    // 60 Sekunden auf eine Antwort, die nie angefragt wurde.
    test('Socket stirbt nach dem Abonnieren: sofort klarer Fehler', () async {
      signer.deadAfterOpen = {relayA};
      final client = build();
      await expectLater(
        client.connect(),
        throwsA(isA<Nip46Exception>()
            .having((e) => e.message, 'message', contains('erreichbar'))),
      );
      expect(signer.requests, isEmpty);
      await client.close();
    });

    test('close() laesst offene Anfragen nicht haengen', () async {
      signer.respond = (_) => null;
      final client = build();
      final pending = client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await client.close();
      await expectLater(pending, throwsA(isA<Nip46Exception>()));
    });
  });

  group('Mehrere Relays', () {
    test('ein totes Relay stoert das andere nicht', () async {
      signer.failingRelays = {relayA};
      final client = build(relays: [relayA, relayB]);
      await client.connect();
      expect(signer.links.map((l) => l.url), [relayB]);
      await client.close();
    });

    test('doppelte Antwort von zwei Relays fuehrt zu genau einem Ergebnis',
        () async {
      signer.answerFromAllRelays = true;
      final client = build(relays: [relayA, relayB]);

      // Ohne Schutz gegen die zweite Zustellung wuerde hier ein
      // "Completer already completed" die Zone sprengen.
      await client.connect();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(signer.links, hasLength(2));
      await client.close();
    });

    // Der Plan verlangt das ausdruecklich: ohne Zusammenfuehrung baut jede
    // parallele Signier-Anfrage ihren eigenen Socket-Satz auf und abonniert
    // erneut — der Signer bekaeme jede Antwort mehrfach zugestellt.
    test('parallele Anfragen oeffnen jedes Relay nur einmal', () async {
      final client = build(relays: [relayA, relayB]);
      await Future.wait([client.connect(), client.connect(), client.connect()]);
      expect(signer.links.map((l) => l.url).toList()..sort(),
          [relayA, relayB]);
      await client.close();
    });

    test('die Anfrage geht an alle offenen Relays', () async {
      final client = build(relays: [relayA, relayB]);
      await client.connect();
      for (final link in signer.links) {
        // je ein REQ und ein EVENT
        expect(link.sentFrames.where((f) => f.startsWith('["EVENT"')),
            hasLength(1));
      }
      await client.close();
    });
  });

  group('auth_url', () {
    test('Zwischenantwort meldet die URL und laesst die Anfrage offen',
        () async {
      final urls = <String>[];
      var first = true;
      signer.respond = (request) {
        if (first) {
          first = false;
          // Zwischenantwort: result auth_url, URL steht in error.
          Future<void>.delayed(const Duration(milliseconds: 30), () {
            for (final link in signer.links) {
              link.push(signer._wrap(
                  {'id': request['id'], 'result': 'ack'},
                  Keychain(clientKey).public));
            }
          });
          return {
            'id': request['id'],
            'result': 'auth_url',
            'error': 'https://nsec.app/auth?x=1',
          };
        }
        return null;
      };

      final client = build(onAuthUrl: urls.add);
      await client.connect();

      expect(urls, ['https://nsec.app/auth?x=1']);
      await client.close();
    });
  });

  group('Kopplung ueber nostrconnect', () {
    test('Signer weist sich mit dem Einmal-Geheimnis aus', () async {
      const secret = 'abcdef0123456789';
      final client = build(paired: false);

      final pairing = client.awaitPairing(secret: secret);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      for (final link in signer.links) {
        link.push(signer._wrap(
            {'id': 'x', 'result': secret}, Keychain(clientKey).public));
      }

      expect(await pairing, signer.pubkey);
      expect(client.remoteSignerPubkey, signer.pubkey);
      expect(client.isPaired, isTrue);
      await client.close();
    });

    test('falsches Geheimnis koppelt nicht', () async {
      final client = build(paired: false);
      final pairing = client.awaitPairing(secret: 'richtig');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      for (final link in signer.links) {
        link.push(signer._wrap(
            {'id': 'x', 'result': 'falsch'}, Keychain(clientKey).public));
      }
      await expectLater(pairing, throwsA(isA<Nip46TimeoutException>()));
      expect(client.isPaired, isFalse);
      await client.close();
    });
  });

  group('Bunker-Adresse', () {
    test('vollstaendige Adresse wird gelesen', () {
      final p = BunkerPointer.parse(
          ' bunker://${'ab' * 32}?relay=wss://a.test&relay=wss://b.test'
          '&secret=deadbeef ');
      expect(p.remoteSignerPubkey, 'ab' * 32);
      expect(p.relays, ['wss://a.test', 'wss://b.test']);
      expect(p.secret, 'deadbeef');
    });

    test('npub als Signer-Schluessel wird akzeptiert', () {
      final keys = Keychain.generate();
      final npub = Nip19.encodePubkey(keys.public);
      final p = BunkerPointer.parse('bunker://$npub?relay=wss://a.test');
      expect(p.remoteSignerPubkey, keys.public);
    });

    test('Persistenzform laesst das Einmal-Geheimnis weg', () {
      final p = BunkerPointer.parse(
          'bunker://${'ab' * 32}?relay=wss://a.test&secret=deadbeef');
      final uri = p.toBunkerUri();
      expect(uri, isNot(contains('secret')));
      expect(uri, contains('relay=wss%3A%2F%2Fa.test'));
      // und laesst sich erneut lesen
      expect(BunkerPointer.parse(uri).relays, ['wss://a.test']);
    });

    test('fehlendes Relay, falsches Schema und Muell werden abgewiesen', () {
      for (final bad in [
        'bunker://${'ab' * 32}',
        'bunker://${'ab' * 32}?relay=http://a.test',
        'https://example.com',
        'bunker://nichthex?relay=wss://a.test',
        'bunker://${'ab' * 31}?relay=wss://a.test',
        '',
      ]) {
        expect(() => BunkerPointer.parse(bad),
            throwsA(isA<Nip46Exception>()), reason: bad);
      }
    });

    test('nostrconnect-Adresse traegt Geheimnis, Rechte und Relays', () {
      final uri = BunkerPointer.buildNostrConnectUri(
        clientPubkeyHex: 'cd' * 32,
        relays: const ['wss://a.test'],
        secret: 'abc123',
        perms: Nip46Client.requestedPerms,
        appName: Nip46ClientMetadata.name,
        appUrl: Nip46ClientMetadata.url,
        appImage: Nip46ClientMetadata.image,
      );
      expect(uri, startsWith('nostrconnect://${'cd' * 32}?'));
      expect(uri, contains('secret=abc123'));
      expect(uri, contains('sign_event%3A21000'));
      expect(uri, contains('name=Einundzwanzig%20Meetup'));
      final parsed = Uri.parse(uri);
      expect(parsed.queryParameters['url'], Nip46ClientMetadata.url);
      expect(parsed.queryParameters['image'], Nip46ClientMetadata.image);
      expect(parsed.queryParametersAll['relay'], ['wss://a.test']);
    });

    test('App-Name bleibt fuer native URI-Parser unveraendert', () {
      for (final name in ['Einundzwanzig Meetup', 'Meetup + Café & Bitcoin']) {
        final uri = BunkerPointer.buildNostrConnectUri(
          clientPubkeyHex: 'cd' * 32,
          relays: const ['wss://a.test'],
          secret: 'abc123',
          perms: Nip46Client.requestedPerms,
          appName: name,
        );
        final encodedName = uri.split('&name=').last;
        // Wie ein nativer Parser: Prozentkodierung dekodieren, '+' erhalten.
        expect(Uri.decodeComponent(encodedName), name);
        expect(encodedName, isNot(contains('+')));
        expect(Uri.parse(uri).queryParameters['name'], name);
      }
    });

    test('nostrconnect kodiert Bild- und App-URLs ohne Parameterverlust', () {
      const appUrl = 'https://example.org/app?lang=de&source=signer';
      const image = 'https://example.org/icon.png?v=2&size=192';
      final uri = Uri.parse(
        BunkerPointer.buildNostrConnectUri(
          clientPubkeyHex: 'cd' * 32,
          relays: const ['wss://a.test', 'wss://b.test'],
          secret: 'abc123',
          perms: Nip46Client.requestedPerms,
          appName: 'Einundzwanzig Meetup',
          appUrl: appUrl,
          appImage: image,
        ),
      );
      expect(uri.queryParameters['url'], appUrl);
      expect(uri.queryParameters['image'], image);
      expect(uri.queryParametersAll['relay'], ['wss://a.test', 'wss://b.test']);
    });
  });
}
