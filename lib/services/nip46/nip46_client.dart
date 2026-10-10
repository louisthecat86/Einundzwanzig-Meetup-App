// ============================================
// NIP-46 CLIENT — Remote-Signer (Bunker)
// ============================================
// Der private Schlüssel des Nutzers liegt in einer fremden App oder auf einer
// fremden Website (nsec.app, Amber, Alby). Die Meetup-App schickt ihre
// Signier-Anfragen dorthin und bekommt fertig signierte Events zurück.
//
// WARUM DAS GEBRAUCHT WIRD: auf iOS ist das der EINZIGE Weg zu einem externen
// Signer — Amber (NIP-55) gibt es dort nicht, eine Browsererweiterung
// (NIP-07) auch nicht.
//
// Transport: kind-24133-Events, Inhalt mit NIP-44 verschlüsselt, adressiert
// über ein p-Tag. Die App tritt dabei mit einem EIGENEN, zufälligen
// Sitzungsschlüssel auf (client_sk) — nicht mit der Identität des Nutzers.
// Der Nutzer-pubkey kommt erst per get_public_key aus dem Signer zurück.
//
// Alle Relays der Bunker-Adresse werden parallel genutzt: eine Anfrage geht
// an alle, die erste gültige Antwort gewinnt. Ein Signer ist oft nur auf
// einem seiner Relays wirklich erreichbar.
//
// Die Fristen sind lang (bis 120 s), weil der Nutzer in einer ANDEREN App
// bestätigen muss. Aufrufer müssen währenddessen einen sichtbaren Wartezustand
// zeigen und weitere Auslösungen sperren — ohne das tippen Nutzer mehrfach
// (dieselbe Lektion wie beim Backup, PR #32).
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:nostr/nostr.dart';

import '../app_logger.dart';
import '../nip44.dart';
import '../relay_socket.dart';
import 'bunker_uri.dart';
import 'client_metadata.dart';
import 'nip46_exception.dart';

/// Was der Client von einem Relay braucht. Existiert als eigener Typ, damit
/// der ganze RPC-Weg (verschlüsseln → Event → Antwort → entschlüsseln →
/// zuordnen) in Tests ohne echte WebSocket-Verbindung prüfbar ist.
abstract interface class Nip46RelayLink {
  Stream<dynamic> get stream;
  void add(String frame);
  Future<void> close();
}

typedef Nip46RelayOpener = Future<Nip46RelayLink> Function(String url);

class _RelaySocketLink implements Nip46RelayLink {
  final RelaySocket _socket;
  _RelaySocketLink(this._socket);

  @override
  Stream<dynamic> get stream => _socket.stream;
  @override
  void add(String frame) => _socket.add(frame);
  @override
  Future<void> close() => _socket.close();
}

Future<Nip46RelayLink> _openRelaySocket(String url) async =>
    _RelaySocketLink(await RelaySocket.connect(url));

/// Zustand einer über mehrere Relays veröffentlichten Anfrage.
class _Publish {
  /// id der RPC-Anfrage, die zu diesem Ereignis gehört.
  final String requestId;

  /// An wie viele Relays wurde gesendet.
  final int sent;

  int rejected = 0;
  bool accepted = false;
  String lastReason = '';

  _Publish(this.requestId, this.sent);
}

class Nip46Client {
  static const int eventKind = 24133;

  /// Fristen. Lang, weil am anderen Ende ein Mensch tippen muss.
  static const Duration connectTimeout = Duration(seconds: 75);
  static const Duration pairingTimeout = Duration(seconds: 120);
  static const Duration signTimeout = Duration(seconds: 60);
  static const Duration pingTimeout = Duration(seconds: 15);
  static const Duration _relayConnectTimeout = Duration(seconds: 10);

  /// Rechte, die beim Verbinden angefragt werden.
  ///
  /// Das ist NICHT kosmetisch: `ReputationPublisher.publishInBackground()`
  /// läuft bei jedem App-Start. Fehlt hier ein kind, fragt der Signer den
  /// Nutzer bei JEDEM Start erneut um Erlaubnis. Die Liste deckt daher alle
  /// kinds ab, die die App überhaupt signiert:
  ///
  ///   21000 Badge-Signaturen (badge_security, nostr_service)
  ///   21001 Badge-Widerruf (badge_security)
  ///   21002 Badge-Claim (badge_claim_service)
  ///   21003 Plattform-Nachweis + Distrust (platform_proof, vouching)
  ///   22242 Portal-Anmeldung (portal_api_service)
  ///   30021 Promotion-Claim (promotion_claim_service)
  ///   30078 Reputation + Organisator-Registry (reputation_publisher,
  ///         admin_registry)
  ///   30079 gemeinsame Teilnahme (coattendance_service)
  ///   31922/31923 Kalender-Events (calendar_event_service)
  static const List<int> signedKinds = [
    21000,
    21001,
    21002,
    21003,
    22242,
    30021,
    30078,
    30079,
    31922,
    31923,
  ];

  static String get requestedPerms => [
        'get_public_key',
        for (final k in signedKinds) 'sign_event:$k',
      ].join(',');

  final String clientSecretKeyHex;
  final String clientPubkeyHex;
  final List<String> relays;

  /// Wird gerufen, wenn der Signer erst eine Freigabe im Browser verlangt.
  /// Im Web darf das NICHT automatisch ein Fenster öffnen — ohne Nutzer-Gestik
  /// blockiert der Browser das. Die UI muss einen Knopf anzeigen.
  final void Function(String url)? onAuthUrl;

  /// NUR für Tests: ersetzt jede Frist. Ohne diese Naht würde ein Test des
  /// Timeout-Pfads 60 Sekunden echte Zeit brauchen.
  @visibleForTesting
  final Duration? debugTimeout;

  final Nip46RelayOpener _open;
  final Map<String, Nip46RelayLink> _links = {};
  final List<StreamSubscription> _subs = [];
  final Map<String, Completer<dynamic>> _pending = {};
  final String _subId = 'nip46-${_randomHex(8)}';

  String? _remoteSignerPubkey;

  // Der Sitzungsschlüssel ist für ein Schlüsselpaar konstant, seine Ableitung
  // (ECDH) kostet aber ein Vielfaches des eigentlichen Ver- und
  // Entschlüsselns: gemessen 7,9 ms gegen 0,22 ms in der Dart-VM, Faktor 37 —
  // im Browser mit dart2js-BigInt deutlich mehr. Ohne Zwischenspeicher fielen
  // pro Signatur zwei Ableitungen an, plus eine je eingehendem Ereignis.
  //
  // Gespeichert wird NUR der Schlüssel des gekoppelten Signers. Eine Ablage
  // nach beliebigem Absender könnte ein Relay mit fremden Ereignissen
  // unbegrenzt füllen.
  Uint8List? _cachedKey;
  String? _cachedKeyFor;

  Completer<void>? _connecting;
  Completer<String>? _pairing;
  String? _pairingSecret;
  int _undecryptable = 0;
  int _foreignSender = 0;
  bool _closed = false;

  /// Veröffentlichte Anfragen, nach der Ereignis-id. Nur damit lässt sich eine
  /// Ablehnung des Relays der zugehörigen Anfrage zuordnen.
  final Map<String, _Publish> _publishes = {};

  Nip46Client({
    required this.clientSecretKeyHex,
    required List<String> relays,
    String? remoteSignerPubkey,
    this.onAuthUrl,
    this.debugTimeout,
    @visibleForTesting Nip46RelayOpener? debugOpenRelay,
  })  : relays = List.unmodifiable(relays),
        clientPubkeyHex = _derivePubkey(clientSecretKeyHex),
        _remoteSignerPubkey = remoteSignerPubkey == null
            ? null
            : BunkerPointer.normalizePubkey(remoteSignerPubkey),
        _open = debugOpenRelay ?? _openRelaySocket {
    if (this.relays.isEmpty) {
      throw const Nip46Exception(
          'Für den Remote-Signer ist kein Relay angegeben.');
    }
  }

  factory Nip46Client.fromPointer({
    required String clientSecretKeyHex,
    required BunkerPointer pointer,
    void Function(String url)? onAuthUrl,
    Duration? debugTimeout,
    @visibleForTesting Nip46RelayOpener? debugOpenRelay,
  }) =>
      Nip46Client(
        clientSecretKeyHex: clientSecretKeyHex,
        relays: pointer.relays,
        remoteSignerPubkey: pointer.remoteSignerPubkey,
        onAuthUrl: onAuthUrl,
        debugTimeout: debugTimeout,
        debugOpenRelay: debugOpenRelay,
      );

  /// Neuer Sitzungsschlüssel für die App-Seite. Das ist NICHT der Schlüssel
  /// des Nutzers — der verlässt den Signer nie.
  static String generateClientKey() => Keychain.generate().private;

  /// Einmal-Geheimnis für die Kopplung, 16 Hex-Zeichen.
  static String generateSecret() => _randomHex(8);

  String? get remoteSignerPubkey => _remoteSignerPubkey;

  bool get isPaired => _remoteSignerPubkey != null;

  // ---------- RPC-Methoden ----------

  /// Meldet die App beim Signer an. [secret] stammt aus der Bunker-Adresse.
  Future<void> connect({String? secret}) async {
    final remote = _remoteSignerPubkey;
    if (remote == null) {
      throw const Nip46Exception('Noch kein Signer gekoppelt.');
    }
    await _rpc(
      'connect',
      [
        remote,
        secret ?? '',
        requestedPerms,
        jsonEncode(Nip46ClientMetadata.values),
      ],
      timeout: connectTimeout,
    );
  }

  /// hex-pubkey des NUTZERS (nicht des Signers).
  Future<String> getPublicKey() async {
    final result = await _rpc('get_public_key', const [],
        timeout: connectTimeout);
    return BunkerPointer.normalizePubkey(result.toString());
  }

  /// Lässt ein unsigniertes Event signieren und gibt das signierte zurück.
  Future<Map<String, dynamic>> signEvent(Map<String, dynamic> unsigned) async {
    final result =
        await _rpc('sign_event', [jsonEncode(unsigned)], timeout: signTimeout);
    final decoded = _decodeSigned(result);
    if (decoded == null) {
      throw const Nip46Exception(
          'Der Signer hat kein lesbares Event zurückgegeben.');
    }
    return decoded;
  }

  /// Lebt die Sitzung noch? Wird nach einem Neustart geprüft, damit ein vom
  /// Nutzer im Signer widerrufener Zugang auffällt, bevor die App signiert.
  Future<bool> ping() async {
    try {
      final result = await _rpc('ping', const [], timeout: pingTimeout);
      return result.toString() == 'pong';
    } on Nip46Exception {
      return false;
    }
  }

  /// Wartet darauf, dass sich ein Signer auf die von der App ausgegebene
  /// nostrconnect://-Adresse hin meldet. Gibt dessen pubkey zurück.
  Future<String> awaitPairing({
    required String secret,
    Duration timeout = pairingTimeout,
  }) async {
    final existing = _remoteSignerPubkey;
    if (existing != null) return existing;

    await _ensureConnected();
    final completer = Completer<String>();
    _pairing = completer;
    _pairingSecret = secret;
    final limit = debugTimeout ?? timeout;
    try {
      return await completer.future.timeout(limit);
    } on TimeoutException {
      throw Nip46TimeoutException('pairing', limit, _undecryptable);
    } finally {
      _pairing = null;
      _pairingSecret = null;
    }
  }

  Future<void> close() async {
    _closed = true;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    for (final link in _links.values) {
      try {
        await link.close();
      } catch (_) {}
    }
    _links.clear();

    // Offene Anfragen dürfen nicht ewig hängen, wenn die Sitzung getauscht
    // wird — sonst wartet die UI auf eine Antwort, die niemand mehr liest.
    for (final pending in _pending.values) {
      if (!pending.isCompleted) {
        pending.completeError(
            const Nip46Exception('Verbindung zum Signer wurde geschlossen.'));
      }
    }
    _pending.clear();
    _publishes.clear();
    final pairing = _pairing;
    if (pairing != null && !pairing.isCompleted) {
      pairing.completeError(
          const Nip46Exception('Kopplung wurde abgebrochen.'));
    }
  }

  // ---------- Transport ----------

  Future<dynamic> _rpc(
    String method,
    List<String> params, {
    required Duration timeout,
  }) async {
    if (_closed) {
      throw const Nip46Exception('Die Signer-Sitzung ist geschlossen.');
    }
    final remote = _remoteSignerPubkey;
    if (remote == null) {
      throw const Nip46Exception('Noch kein Signer gekoppelt.');
    }
    await _ensureConnected();

    final id = _randomHex(8);
    final request = _buildFrame(
      remote,
      jsonEncode({'id': id, 'method': method, 'params': params}),
    );

    final completer = Completer<dynamic>();
    _pending[id] = completer;

    var sent = 0;
    for (final link in _links.values.toList()) {
      try {
        link.add(request.frame);
        sent++;
      } catch (e) {
        AppLogger.warn('Nip46', 'Senden an ein Relay fehlgeschlagen', e);
      }
    }
    if (sent == 0) {
      _pending.remove(id);
      throw const Nip46Exception(
          'Kein Relay des Signers ist erreichbar.');
    }
    // Erst NACH dem Senden vermerken: nur so steht die Zahl der Relays fest,
    // von denen eine Bestätigung kommen kann.
    _publishes[request.eventId] = _Publish(id, sent);

    final limit = debugTimeout ?? timeout;
    try {
      return await completer.future.timeout(limit);
    } on TimeoutException {
      _pending.remove(id);
      AppLogger.warn(
          'Nip46',
          '$method: keine Antwort in ${limit.inSeconds}s '
              '(unlesbar: $_undecryptable, fremder Absender: $_foreignSender)');
      throw Nip46TimeoutException(
          method, limit, _undecryptable, _foreignSender);
    } finally {
      _publishes.remove(request.eventId);
    }
  }

  Uint8List _conversationKey(String pubkey) {
    if (_cachedKeyFor == pubkey) return _cachedKey!;
    final key = Nip44.conversationKey(
        privkeyHex: clientSecretKeyHex, pubkeyHex: pubkey);
    if (pubkey == _remoteSignerPubkey) {
      _cachedKey = key;
      _cachedKeyFor = pubkey;
    }
    return key;
  }

  /// Gibt die Ereignis-id mit zurück — nur über sie lässt sich ein
  /// `["OK", <id>, false, …]` des Relays der Anfrage zuordnen.
  ({String frame, String eventId}) _buildFrame(String remote, String payload) {
    final key = _conversationKey(remote);
    final event = Event.from(
      kind: eventKind,
      tags: [
        ['p', remote]
      ],
      content: Nip44.encrypt(payload, key),
      privkey: clientSecretKeyHex,
    );
    return (frame: jsonEncode(['EVENT', event.toJson()]), eventId: event.id);
  }

  /// Baut die Verbindungen auf. Mehrfache Aufrufe warten auf denselben
  /// Versuch — sonst entstünden bei parallelen Signier-Anfragen mehrere
  /// Socket-Sätze und damit doppelte Subscriptions.
  Future<void> _ensureConnected() async {
    if (_closed) {
      throw const Nip46Exception('Die Signer-Sitzung ist geschlossen.');
    }
    if (_links.isNotEmpty) return;

    final running = _connecting;
    if (running != null) return running.future;

    final completer = Completer<void>();
    _connecting = completer;
    try {
      await Future.wait(relays.map(_openLink));
      if (_links.isEmpty) {
        throw const Nip46Exception(
            'Kein Relay des Signers ist erreichbar. Ist das Gerät online?');
      }
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _connecting = null;
    }
    return completer.future;
  }

  /// Öffnet EIN Relay. Fehler bleiben hier: ein totes Relay darf die anderen
  /// nicht mitnehmen.
  Future<void> _openLink(String url) async {
    try {
      final link = await _open(url).timeout(_relayConnectTimeout);
      if (_closed) {
        await link.close();
        return;
      }
      _links[url] = link;
      _subs.add(link.stream.listen(
        (data) => _onMessage(url, data),
        onError: (Object e) => _dropLink(url),
        onDone: () => _dropLink(url, closeSocket: false),
        cancelOnError: false,
      ));
      // `since` hält alte Antworten aus dem Relay-Speicher fern; die Toleranz
      // deckt eine schiefe Geräteuhr ab.
      link.add(jsonEncode([
        'REQ',
        _subId,
        {
          'kinds': [eventKind],
          '#p': [clientPubkeyHex],
          'since': DateTime.now().millisecondsSinceEpoch ~/ 1000 - 60,
        }
      ]));
    } catch (e) {
      AppLogger.warn('Nip46', 'Relay des Signers nicht erreichbar: $url', e);
    }
  }

  void _dropLink(String url, {bool closeSocket = true}) {
    final link = _links.remove(url);
    if (link == null) return;
    // Socket-Close nicht synchron aus dem Stream-Listener (CLOSED): sonst
    // Reentrancy beim Schliessen des Controllers. onDone braucht kein close
    // mehr — der Stream ist schon tot.
    if (!closeSocket) return;
    scheduleMicrotask(() {
      try {
        link.close();
      } catch (_) {}
    });
  }

  void _onMessage(String url, dynamic data) {
    if (data is! String) return;
    try {
      final decoded = jsonDecode(data);
      if (decoded is! List || decoded.isEmpty) return;

      // Antwort des RELAYS auf unsere Veröffentlichung, nicht des Signers.
      // Wurde vorher ignoriert — eine Ablehnung lief damit stumm in die volle
      // Frist, obwohl das Relay einen Grund genannt hatte.
      if (decoded[0] == 'OK') {
        _handleRelayAck(decoded);
        return;
      }

      // Das Relay hat unser Abo beendet (z. B. Auth-Pflicht). Ohne Abo kann
      // keine Antwort mehr eintreffen — Link droppen, sonst bleiben spaetere
      // EVENT-Publishes an einer toten Subscription haengen und laufen in den
      // vollen Timeout (sah aus wie ein schweigender Signer).
      if (decoded[0] == 'CLOSED') {
        AppLogger.warn(
            'Nip46',
            'Ein Relay hat das Abo beendet: '
                '${decoded.length > 2 ? decoded[2] : "ohne Angabe"}');
        _dropLink(url);
        return;
      }

      if (decoded.length < 3 || decoded[0] != 'EVENT') return;
      final event = decoded[2];
      if (event is! Map || event['kind'] != eventKind) return;

      final sender = (event['pubkey'] ?? '').toString();
      if (sender.length != 64) return;

      final remote = _remoteSignerPubkey;
      // Ist die Kopplung fertig, wird ausschliesslich dem gekoppelten Signer
      // geglaubt. Ein fremder Absender könnte sonst Antworten unterschieben.
      //
      // Wird MITGEZÄHLT: vorher war der Rücksprung spurlos, und dadurch war
      // „unlesbar: 0" scheinbar ein Beweis, dass nichts ankam.
      if (remote != null && sender != remote) {
        _foreignSender++;
        return;
      }

      // Die Signatur des Ereignisses wird BEWUSST nicht geprüft: die Echtheit
      // folgt schon aus der Verschlüsselung. Der Sitzungsschlüssel entsteht
      // aus client_sk × signer_sk — wer das pubkey-Feld fälscht, erzeugt einen
      // anderen Sitzungsschlüssel, und das Entschlüsseln scheitert. Eine
      // wortgleich wiedereingespielte echte Antwort trägt eine alte id und
      // findet keine offene Anfrage mehr.

      final key = _conversationKey(sender);
      final payload =
          jsonDecode(Nip44.decrypt((event['content'] ?? '').toString(), key));
      if (payload is! Map) return;
      _dispatch(sender, payload.cast<String, dynamic>());
    } catch (_) {
      // Bewusst stumm: an dieser Subscription landen auch Ereignisse, die
      // nicht für diese Sitzung gedacht sind — jedes einzeln zu loggen wäre
      // im Betrieb pures Rauschen. Stattdessen wird gezählt und der Zähler
      // beim Timeout mitgemeldet: erst DA ist er die Diagnose.
      _undecryptable++;
    }
  }

  /// `["OK", <event-id>, <bool>, "<Grund>"]`.
  ///
  /// Abgebrochen wird erst, wenn ALLE Relays abgelehnt haben. Eines kann
  /// ablehnen, während ein anderes annimmt — dann ist die Anfrage unterwegs
  /// und ein Abbruch wäre falsch.
  void _handleRelayAck(List<dynamic> message) {
    if (message.length < 3) return;
    final publish = _publishes[message[1].toString()];
    if (publish == null) return;

    if (message[2] == true) {
      publish.accepted = true;
      return;
    }

    publish.rejected++;
    publish.lastReason =
        message.length > 3 ? message[3].toString() : '';
    if (publish.accepted || publish.rejected < publish.sent) return;

    final completer = _pending.remove(publish.requestId);
    if (completer == null || completer.isCompleted) return;
    final reason =
        publish.lastReason.isEmpty ? 'ohne Angabe' : publish.lastReason;
    AppLogger.warn(
        'Nip46', 'Alle ${publish.sent} Relays haben abgelehnt: $reason');
    completer.completeError(Nip46RelayRejectedException(reason));
  }

  void _dispatch(String sender, Map<String, dynamic> payload) {
    final id = (payload['id'] ?? '').toString();
    final result = payload['result'];
    final error = (payload['error'] ?? '').toString();

    // Kopplung: der Signer weist sich mit dem Einmal-Geheimnis aus.
    final pairing = _pairing;
    final secret = _pairingSecret;
    if (pairing != null && secret != null && result?.toString() == secret) {
      _remoteSignerPubkey = sender;
      if (!pairing.isCompleted) pairing.complete(sender);
      AppLogger.security(
          'Nip46', 'Signer gekoppelt: ${sender.substring(0, 12)}…');
      return;
    }

    if (!_pending.containsKey(id)) return;

    // Zwischenantwort: der Signer will erst eine Freigabe im Browser. Die
    // Anfrage bleibt offen, die eigentliche Antwort kommt später mit derselben
    // id — deshalb hier NICHT aus _pending entfernen.
    if (result?.toString() == 'auth_url') {
      if (error.isNotEmpty) onAuthUrl?.call(error);
      return;
    }

    final completer = _pending.remove(id)!;
    if (completer.isCompleted) return;
    if (error.isNotEmpty) {
      completer.completeError(Nip46RemoteException(error));
      return;
    }
    completer.complete(result);
  }

  // ---------- Hilfen ----------

  static Map<String, dynamic>? _decodeSigned(dynamic result) {
    if (result is Map) return result.cast<String, dynamic>();
    if (result is String) {
      try {
        final decoded = jsonDecode(result);
        if (decoded is Map) return decoded.cast<String, dynamic>();
      } catch (_) {}
    }
    return null;
  }

  static String _derivePubkey(String privkeyHex) {
    if (privkeyHex.length != 64) {
      throw const Nip46Exception('Der Sitzungsschlüssel der App ist ungültig.');
    }
    try {
      return Keychain(privkeyHex).public;
    } catch (_) {
      throw const Nip46Exception('Der Sitzungsschlüssel der App ist ungültig.');
    }
  }

  static final Random _random = Random.secure();

  static String _randomHex(int bytes) => [
        for (var i = 0; i < bytes; i++)
          _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ].join();
}
