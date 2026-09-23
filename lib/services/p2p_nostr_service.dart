// Beispiel-Implementierung fuer Issue #62; NICHT produktionsreif.
// Oeffentliche Nostr-Events: Interessen, Pubkey und Termin sind einsehbar.
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';

import '../models/p2p_offer.dart';
import 'news_reactions_service.dart';
import 'relay_socket.dart';
import 'signing_service.dart';

class P2pNostrService {
  const P2pNostrService();
  // Projektspezifisch, KEIN standardisierter NIP-Kind.
  static const int kind = 30086;
  static const Duration timeout = Duration(seconds: 7);

  static String dTag(String address) =>
      'p2p-${sha256.convert(utf8.encode(address)).toString()}';

  /// null = mindestens ein Relay bestaetigt; OFF-Events sind keine
  /// garantierte Loeschung bereits verteilter Nostr-Inhalte.
  Future<String?> publish({
    required String eventAddress,
    required P2pSide? side,
    required DateTime expiresAt,
  }) async {
    if (eventAddress.trim().isEmpty) return 'Keine Termin-ID vorhanden.';
    final now = DateTime.now().toUtc();
    if (side != null &&
        (!expiresAt.isAfter(now) ||
            expiresAt.difference(now) > const Duration(hours: 4))) {
      return 'Ungueltiger Angebotszeitraum.';
    }
    final signed = await SigningService.signEvent(
      kind: kind,
      content: jsonEncode({
        'v': 1,
        'side': side?.name ?? 'off',
        'expires': side == null
            ? 0
            : expiresAt.toUtc().millisecondsSinceEpoch ~/ 1000,
      }),
      tags: [
        ['d', dTag(eventAddress)],
        ['a', eventAddress],
        ['t', 'einundzwanzig-p2p-v1'],
      ],
    );
    final relays = (await NewsReactionsService.readTargets())
        .where((r) => !NewsReactionsService.readOnlyRelays.contains(r))
        .toSet();
    final results = await Future.wait(relays.map(
        (url) => _send(url, signed.toEventMessage(), signed.id)));
    return results.any((ok) => ok)
        ? null : 'Kein Relay hat das Angebot bestaetigt.';
  }

  Future<List<P2pOffer>> load(String eventAddress, DateTime now) async {
    if (eventAddress.trim().isEmpty) return [];
    final relays = await NewsReactionsService.readTargets();
    final latest = <String, Map<String, dynamic>>{};
    await Future.wait(relays.map((url) async {
      for (final raw in await _query(url, eventAddress)) {
        if (!_valid(raw, eventAddress, now)) continue;
        final author = raw['pubkey'] as String;
        final previous = latest[author];
        final stamp = raw['created_at'] as int;
        if (previous == null ||
            stamp > (previous['created_at'] as int) ||
            (stamp == previous['created_at'] &&
                (raw['id'] as String).compareTo(previous['id'] as String) > 0)) {
          latest[author] = raw;
        }
      }
    }));
    final active = <P2pOffer>[];
    for (final e in latest.values) {
      final content = jsonDecode(e['content'] as String) as Map<String, dynamic>;
      if (content['side'] == 'off') continue;
      final expires = DateTime.fromMillisecondsSinceEpoch(
          (content['expires'] as int) * 1000, isUtc: true);
      if (!expires.isAfter(now)) continue;
      active.add(P2pOffer(
        id: e['id'] as String,
        authorPubkey: e['pubkey'] as String,
        meetupEventId: eventAddress,
        side: content['side'] == 'buy' ? P2pSide.buy : P2pSide.sell,
        startsAt: DateTime.fromMillisecondsSinceEpoch(
            (e['created_at'] as int) * 1000, isUtc: true),
        expiresAt: expires,
        checkedIn: true, // Selbstauskunft, KEIN Rolling-QR-Nachweis!
      ));
    }
    return active;
  }

  bool _valid(Map<String, dynamic> raw, String address, DateTime now) {
    try {
      if (raw['kind'] != kind ||
          raw['id'] is! String || raw['pubkey'] is! String ||
          raw['sig'] is! String || raw['created_at'] is! int ||
          raw['content'] is! String || raw['tags'] is! List) return false;
      final ts = raw['created_at'] as int;
      final nowSec = now.millisecondsSinceEpoch ~/ 1000;
      if (ts > nowSec + 300 || ts < nowSec - 86400) return false;
      final tags = (raw['tags'] as List)
          .map((t) => (t as List).map((v) => v.toString()).toList())
          .toList();
      bool tag(String key, String value) => tags.any(
          (t) => t.length >= 2 && t[0] == key && t[1] == value);
      if (!tag('d', dTag(address)) || !tag('a', address) ||
          !tag('t', 'einundzwanzig-p2p-v1')) return false;
      final event = Event(raw['id'] as String, raw['pubkey'] as String,
          ts, kind, tags, raw['content'] as String, raw['sig'] as String);
      if (!event.isValid()) return false;
      final content = jsonDecode(raw['content'] as String);
      if (content is! Map<String, dynamic> || content['v'] != 1 ||
          !{'buy', 'sell', 'off'}.contains(content['side']) ||
          content['expires'] is! int) return false;
      final expires = content['expires'] as int;
      if (content['side'] != 'off' &&
          (expires <= ts || expires > ts + 4 * 3600)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _query(String url, String address) async {
    final items = <Map<String, dynamic>>[];
    RelaySocket? socket;
    try {
      socket = await RelaySocket.connect(url)
          .timeout(const Duration(seconds: 4));
      final done = Completer<void>();
      socket.listen((data) {
        try {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.length >= 3 && msg[0] == 'EVENT' && msg[2] is Map) {
            items.add(Map<String, dynamic>.from(msg[2] as Map));
          } else if (msg.isNotEmpty &&
              (msg[0] == 'EOSE' || msg[0] == 'CLOSED')) {
            if (!done.isCompleted) done.complete();
          }
        } catch (_) {}
      }, onError: (_) {
        if (!done.isCompleted) done.complete();
      }, onDone: () {
        if (!done.isCompleted) done.complete();
      });
      socket.add(jsonEncode(['REQ', 'p2p', {
        'kinds': [kind], '#a': [address], 'limit': 300,
      }]));
      await done.future.timeout(timeout, onTimeout: () {});
    } catch (_) {
      // Einzelne Relay-Ausfaelle sind tolerierbar.
    } finally {
      try { socket?.close(); } catch (_) {}
    }
    return items;
  }

  Future<bool> _send(String url, String frame, String id) async {
    RelaySocket? socket;
    try {
      socket = await RelaySocket.connect(url)
          .timeout(const Duration(seconds: 4));
      final done = Completer<bool>();
      socket.listen((data) {
        try {
          final msg = jsonDecode(data as String) as List<dynamic>;
          if (msg.length >= 3 && msg[0] == 'OK' && msg[1] == id &&
              !done.isCompleted) done.complete(msg[2] == true);
        } catch (_) {}
      }, onError: (_) {
        if (!done.isCompleted) done.complete(false);
      }, onDone: () {
        if (!done.isCompleted) done.complete(false);
      });
      socket.add(frame);
      return await done.future.timeout(timeout, onTimeout: () => false);
    } catch (_) {
      return false;
    } finally {
      try { socket?.close(); } catch (_) {}
    }
  }
}
