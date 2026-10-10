// Prueft die Anbindung des Remote-Signers an den SigningService:
// Modus-Persistenz, Wiederherstellung, Trennen — und die drei
// Sicherheitspruefungen des Signers.
//
// Die Pruefungen sind derselbe Code wie bei NIP-07 (verifySignerResponse).
// Genau deshalb muessen sie HIER nochmal geprueft werden: die gemeinsame
// Funktion darf sich nicht auf einem der beiden Wege anders verhalten, und
// nur die Fehlertexte unterscheiden sich.

import 'package:einundzwanzig_meetup_app/services/nip46/client_metadata.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/nip46_client.dart';
import 'package:einundzwanzig_meetup_app/services/nip46/nip46_exception.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mine =
    'fa5e347dd2d6b92d667dcab6cc8bbb1524e0a2ccc5eecddd551787473c3814d3';
const _other =
    'aaaa347dd2d6b92d667dcab6cc8bbb1524e0a2ccc5eecddd551787473c3814d3';
const _myNpub =
    'npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc';
const _sig =
    'abababababababababababababababababababababababababababababababab'
    'abababababababababababababababababababababababababababababababab';
const _eventId =
    'cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd';

const _bunkerUri = 'bunker://'
    'bbbb347dd2d6b92d667dcab6cc8bbb1524e0a2ccc5eecddd551787473c3814d3'
    '?relay=wss%3A%2F%2Frelay.damus.io';
const _clientKey =
    '1111111111111111111111111111111111111111111111111111111111111111';

/// In-Memory-Ersatz fuer den Keychain/Keystore. Ohne den koennte hier nichts
/// geprueft werden, was den Sitzungsschluessel anfasst.
Map<String, String> mockSecureStorage() {
  final store = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
      switch (call.method) {
        case 'write':
          store['${args['key']}'] = '${args['value']}';
          return null;
        case 'read':
          return store['${args['key']}'];
        case 'delete':
          store.remove('${args['key']}');
          return null;
        case 'readAll':
          return store;
        case 'deleteAll':
          store.clear();
          return null;
        case 'containsKey':
          return store.containsKey('${args['key']}');
      }
      return null;
    },
  );
  return store;
}

Map<String, dynamic> reply({
  String pubkey = _mine,
  int kind = 21000,
  String content = 'Badge',
  List<dynamic>? tags,
  String sig = _sig,
}) =>
    {
      'id': _eventId,
      'pubkey': pubkey,
      'created_at': 1786000000,
      'kind': kind,
      'tags': tags ?? [
            ['d', 'badge']
          ],
      'content': content,
      'sig': sig,
    };

Nip46NostrSigner signerReturning(Map<String, dynamic> r) => Nip46NostrSigner(
      expectedPubkeyHex: _mine,
      clientProvider: () async =>
          throw StateError('darf im Test nicht gerufen werden'),
      debugSignFn: (_) async => r,
    );

Nip46NostrSigner signerThrowing(Object error) => Nip46NostrSigner(
      expectedPubkeyHex: _mine,
      clientProvider: () async =>
          throw StateError('darf im Test nicht gerufen werden'),
      debugSignFn: (_) async => throw error,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Signer: guter Fall', () {
    test('uebernimmt id, sig, created_at und normalisierte Tags', () async {
      final signed = await signerReturning(
        reply(tags: [
          ['d', 'badge'],
          ['client', 'nsec.app']
        ]),
      ).signEvent(kind: 21000, tags: [
        ['d', 'badge']
      ], content: 'Badge');

      expect(signed.id, _eventId);
      expect(signed.sig, _sig);
      expect(signed.createdAt, 1786000000);
      expect(signed.tags, [
        ['d', 'badge'],
        ['client', 'nsec.app'],
      ]);
      expect(signed.kind, 21000);
      expect(signed.content, 'Badge');
    });
  });

  group('Signer: Sicherheitspruefungen', () {
    test('fremdes Konto wird abgewiesen', () async {
      await expectLater(
        signerReturning(reply(pubkey: _other))
            .signEvent(kind: 21000, tags: const [], content: 'Badge'),
        throwsA(isA<WrongAccountException>()),
      );
    });

    test('fehlende Signatur wird abgewiesen', () async {
      await expectLater(
        signerReturning(reply(sig: ''))
            .signEvent(kind: 21000, tags: const [], content: 'Badge'),
        throwsA(isA<SigningException>()),
      );
    });

    test('veraenderter Event-Typ wird abgewiesen', () async {
      await expectLater(
        signerReturning(reply(kind: 1))
            .signEvent(kind: 21000, tags: const [], content: 'Badge'),
        throwsA(isA<SigningException>()),
      );
    });

    test('veraenderter Inhalt wird abgewiesen', () async {
      await expectLater(
        signerReturning(reply(content: 'etwas anderes'))
            .signEvent(kind: 21000, tags: const [], content: 'Badge'),
        throwsA(isA<SigningException>()),
      );
    });

    // Der Fehlertext nennt die Gegenstelle. Bei NIP-07 heisst sie
    // "Die Erweiterung", hier "Der Signer" — sonst schickt die Meldung den
    // Nutzer an die falsche Stelle.
    test('Fehlertext nennt den Signer, nicht die Erweiterung', () async {
      await expectLater(
        signerReturning(reply(content: 'anders'))
            .signEvent(kind: 21000, tags: const [], content: 'Badge'),
        throwsA(isA<SigningException>().having((e) => e.message, 'message',
            allOf(contains('Der Signer'), isNot(contains('Erweiterung'))))),
      );
    });
  });

  group('Signer: Transportfehler werden uebersetzt', () {
    test('Zeitueberschreitung wird ein Hinweis auf die Signer-App', () async {
      await expectLater(
        signerThrowing(const Nip46TimeoutException(
                'sign_event', Duration(seconds: 60), 0))
            .signEvent(kind: 21000, tags: const [], content: 'x'),
        throwsA(isA<SigningException>().having((e) => e.message, 'message',
            contains('Signer-App'))),
      );
    });

    test('Ablehnung des Signers wird durchgereicht', () async {
      await expectLater(
        signerThrowing(const Nip46RemoteException('user rejected'))
            .signEvent(kind: 21000, tags: const [], content: 'x'),
        throwsA(isA<SigningException>().having(
            (e) => e.message, 'message', contains('user rejected'))),
      );
    });
  });

  group('Modus und Sitzung', () {
    test("wird als 'nip46' gespeichert und gelesen", () async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();

      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );

      expect(await SigningService.getMode(), SigningMode.nip46);
      expect(await SigningService.isNip46, isTrue);
      expect(await SigningService.isNip07, isFalse);
      expect(await SigningService.isExternalSigner, isTrue);
      expect(await SigningService.npub(), _myNpub);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('signing_mode'), 'nip46',
          reason: 'der gespeicherte Wert muss stabil bleiben');
    });

    test('canSign braucht alle drei Teile der Sitzung', () async {
      SharedPreferences.setMockInitialValues({});
      final store = mockSecureStorage();
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      expect(await SigningService.canSign(), isTrue);

      // Ohne Sitzungsschluessel kann die App nicht mehr anfragen — dann darf
      // sie auch nicht behaupten, sie koenne signieren.
      store.remove('nip46_client_sk');
      expect(await SigningService.canSign(), isFalse);
    });

    test('canSign ist false, wenn die Bunker-Adresse fehlt', () async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('nip46_bunker_uri');
      expect(await SigningService.canSign(), isFalse);
    });

    test('kaputte Bunker-Adresse wird nicht gespeichert', () async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      await expectLater(
        SigningService.restoreNip46(
          npub: _myNpub,
          bunkerUri: 'bunker://ohne-relay',
          clientSecretKeyHex: _clientKey,
        ),
        throwsA(isA<Nip46Exception>()),
      );
      // Wichtig: der Modus darf NICHT umgestellt worden sein, sonst stuende
      // die App auf einem Signer, den sie nie erreichen kann.
      expect(await SigningService.getMode(), SigningMode.local);
    });

    test('disconnect raeumt alle vier Felder ab', () async {
      SharedPreferences.setMockInitialValues({});
      final store = mockSecureStorage();
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      await SigningService.disconnectNip46();

      expect(await SigningService.getMode(), SigningMode.local);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nip46_pubkey_hex'), isNull);
      expect(prefs.getString('nip46_npub'), isNull);
      expect(prefs.getString('nip46_bunker_uri'), isNull);
      expect(store['nip46_client_sk'], isNull,
          reason: 'der Sitzungsschluessel darf nicht liegenbleiben');
    });

    test('useLocalMode raeumt die Bunker-Sitzung mit ab', () async {
      // Wechsel-Pfad: vorher blieb der Sitzungsschluessel liegen, wenn man
      // nur den Modus auf local stellte (Schluessel erzeugen / Import).
      SharedPreferences.setMockInitialValues({});
      final store = mockSecureStorage();
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      await SigningService.useLocalMode();

      expect(await SigningService.getMode(), SigningMode.local);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nip46_bunker_uri'), isNull);
      expect(store['nip46_client_sk'], isNull);
    });

  });

  // Der Signer UEBERNIMMT diese Liste und merkt sie sich fuer die Sitzung.
  // Ein fest verdrahtetes Relay pflanzt sich damit in die Gegenstelle fort —
  // genau das ist in der Praxis passiert: ein ausgefallenes relay.damus.io
  // stand danach in der Bunker-Datenbank und war ohne neue Verbindung nicht
  // mehr wegzukriegen.
  group('Metadaten im tatsaechlichen Kopplungsablauf', () {
    test('QR-Adresse enthaelt Name, Symbol, URL und die aktive Sitzung',
        () async {
      SharedPreferences.setMockInitialValues({});
      final pairing = await SigningService.startNip46Pairing();
      addTearDown(pairing.cancel);

      final uri = Uri.parse(pairing.uri);
      expect(uri.scheme, 'nostrconnect');
      expect(uri.host, pairing.client.clientPubkeyHex);
      expect(uri.queryParameters['secret'], pairing.secret);
      expect(uri.queryParameters['perms'], Nip46Client.requestedPerms);
      expect(uri.queryParametersAll['relay'], pairing.relays);
      expect(uri.queryParameters['name'], 'Einundzwanzig Meetup');
      expect(pairing.uri, contains('name=Einundzwanzig%20Meetup'));
      expect(uri.queryParameters['url'], Nip46ClientMetadata.url);
      expect(uri.queryParameters['image'], Nip46ClientMetadata.image);
      expect(Uri.parse(uri.queryParameters['image']!).scheme, 'https');
      expect(pairing.uri, isNot(contains(pairing.clientSecretKeyHex)),
          reason: 'Der private Sitzungsschluessel darf nicht im QR-Code stehen');
    });

    test('neue Kopplung behaelt Metadaten, erneuert aber Sitzung und Geheimnis',
        () async {
      SharedPreferences.setMockInitialValues({});
      final first = await SigningService.startNip46Pairing();
      addTearDown(first.cancel);
      final second = await SigningService.startNip46Pairing();
      addTearDown(second.cancel);

      expect(second.secret, isNot(first.secret));
      expect(second.client.clientPubkeyHex,
          isNot(first.client.clientPubkeyHex));
      final firstParams = Uri.parse(first.uri).queryParameters;
      final secondParams = Uri.parse(second.uri).queryParameters;
      for (final key in ['name', 'url', 'image']) {
        expect(secondParams[key], firstParams[key]);
      }
      await first.cancel();
      await second.cancel();
      expect(await SigningService.getMode(), SigningMode.local,
          reason: 'Abgebrochene Kopplung darf keine Sitzung aktivieren');
    });
  });

  group('Relays fuer die Kopplung folgen den Einstellungen', () {
    test('abgewaehltes Relay kommt NICHT in die Kopplungsadresse', () async {
      SharedPreferences.setMockInitialValues({
        'disabled_default_relays': ['wss://relay.damus.io'],
      });
      final relays = await SigningService.nip46PairingRelays();
      expect(relays, isNot(contains('wss://relay.damus.io')));
      expect(relays, isNotEmpty);
    });

    test('eigene Relays werden verwendet', () async {
      SharedPreferences.setMockInitialValues({
        'custom_relays': ['wss://mein.relay.test'],
        'disabled_default_relays': [
          'wss://relay.damus.io',
          'wss://nos.lol',
          'wss://relay.nostr.band',
          'wss://nostr.einundzwanzig.space',
        ],
      });
      expect(await SigningService.nip46PairingRelays(),
          ['wss://mein.relay.test']);
    });

    test('hoechstens drei — jedes weitere verlaengert nur den Aufbau',
        () async {
      SharedPreferences.setMockInitialValues({});
      expect((await SigningService.nip46PairingRelays()).length,
          lessThanOrEqualTo(3));
    });

    test('ohne jedes aktive Relay greift ein Rueckfall', () async {
      // Sonst waere eine Kopplung unmoeglich: ohne Relay kein Transport.
      SharedPreferences.setMockInitialValues({
        'disabled_default_relays': [
          'wss://relay.damus.io',
          'wss://nos.lol',
          'wss://relay.nostr.band',
          'wss://nostr.einundzwanzig.space',
        ],
      });
      expect(await SigningService.nip46PairingRelays(), isNotEmpty);
    });
  });

  group('Backup: die Sitzung reist NICHT mit', () {
    test('das Backup traegt die Adresse, aber keinen Sitzungsschluessel',
        () async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();
      expect(await SigningService.nip46SessionForBackup(), isNull);

      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      final session = await SigningService.nip46SessionForBackup();
      expect(session?['bunker_uri'], _bunkerUri);
      // Der Kern der Entscheidung: der Sitzungsschluessel ist die
      // Berechtigung, mit der der Signer Anfragen annimmt. Im Backup waere
      // die Datei fuer Bunker-Nutzer eine Signier-Berechtigung — und genau
      // fuer die soll gelten, dass dort KEIN Schluessel liegt.
      expect(session!.containsKey('client_sk'), isFalse);
      expect(session.values.any((v) => v == _clientKey), isFalse,
          reason: 'der Sitzungsschluessel darf nirgends im Backup auftauchen');
    });

    test('Wiederherstellen ohne Schluessel: Identitaet ja, signieren nein',
        () async {
      SharedPreferences.setMockInitialValues({});
      mockSecureStorage();

      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
      );

      // Identitaet bleibt sichtbar — wie bei einem Amber-Backup auf iOS.
      expect(await SigningService.getMode(), SigningMode.nip46);
      expect(await SigningService.npub(), _myNpub);
      expect(await SigningService.isExternalSigner, isTrue);
      // Aber die App taeuscht keine Signier-Faehigkeit vor.
      expect(await SigningService.canSign(), isFalse,
          reason: 'ohne Sitzungsschluessel kann sie nicht anfragen');
    });

    test('ein alter Sitzungsschluessel wird beim Wiederherstellen entfernt',
        () async {
      SharedPreferences.setMockInitialValues({});
      final store = mockSecureStorage();

      // Zustand vorher: eine laufende Sitzung mit Schluessel.
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
        clientSecretKeyHex: _clientKey,
      );
      expect(store['nip46_client_sk'], _clientKey);

      // Backup einspielen, das keinen Schluessel mitbringt.
      await SigningService.restoreNip46(
        npub: _myNpub,
        bunkerUri: _bunkerUri,
      );

      // Bliebe der alte liegen, haette die App sich fuer signierfaehig
      // gehalten und waere erst bei der ersten Anfrage gescheitert — mit einem
      // Schluessel, der nicht zur wiederhergestellten Adresse gehoert.
      expect(store['nip46_client_sk'], isNull);
      expect(await SigningService.canSign(), isFalse);
    });
  });
}
