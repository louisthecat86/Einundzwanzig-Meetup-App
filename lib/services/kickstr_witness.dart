import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/badge.dart';
import 'badge_security.dart';
import 'signing_service.dart';

/// The round encoded in the QR on Kickstr `/forecast`.
class KickstrRound {
  final int topicId;
  final Uri postUrl;

  const KickstrRound({required this.topicId, required this.postUrl});
}

/// A guess signed by the meetup key, with the badge claims that key holds.
class KickstrWitness {
  static const int guessKind = 30233;

  /// `21k:1:<topic_id>:<base64url of the POST url>`
  static KickstrRound? parse(String code) {
    final parts = code.split(':');
    if (parts.length != 4 || parts[0] != '21k' || parts[1] != '1') return null;
    final topicId = int.tryParse(parts[2]);
    if (topicId == null || topicId <= 0) return null;
    try {
      final url = utf8.decode(base64Url.decode(base64Url.normalize(parts[3])));
      final uri = Uri.parse(url);
      if (uri.scheme != 'https' && uri.scheme != 'http') return null;
      if (uri.host.isEmpty) return null;
      return KickstrRound(topicId: topicId, postUrl: uri);
    } catch (_) {
      return null;
    }
  }

  /// Badges this key has claimed. Organizer markers do not count.
  static Future<List<MeetupBadge>> heldBadges() async {
    final all = await MeetupBadge.loadBadges();
    return all.where(_claimable).toList();
  }

  static bool _claimable(MeetupBadge badge) {
    return !badge.isOrganizer &&
        badge.claimSig.length == 128 &&
        badge.claimEventId.length == 64 &&
        badge.claimPubkey.length == 64 &&
        badge.adminPubkey.length == 64 &&
        badge.sig.length == 128 &&
        badge.sigId.length == 64 &&
        badge.claimTimestamp > 0 &&
        badge.blockHeight > 0;
  }

  /// The claim event, rebuilt the way it was signed.
  static Map<String, dynamic> claimEvent(MeetupBadge badge) {
    final content = BadgeSecurity.canonicalJsonEncode({
      'action': 'claim_badge',
      'org_sig': badge.sig,
      'org_event_id': badge.sigId,
      'org_pubkey': badge.adminPubkey,
      'block_height': badge.blockHeight,
      'claimed_at': badge.claimTimestamp,
    });
    return {
      'id': badge.claimEventId,
      'pubkey': badge.claimPubkey,
      'created_at': badge.claimTimestamp,
      'kind': 21002,
      'tags': [
        ['t', 'badge_claim'],
        ['p', badge.adminPubkey],
        ['block', badge.blockHeight.toString()],
      ],
      'content': content,
      'sig': badge.claimSig,
    };
  }

  /// Signs the guess and posts it. Returns the server's error code, or null.
  static Future<String?> submit({
    required KickstrRound round,
    required String name,
    required int price,
    String lud16 = '',
  }) async {
    final badges = await heldBadges();
    final tags = <List<String>>[
      ['d', 'glimpse:${round.topicId}'],
      ['name', name.trim()],
      ['client', 'einundzwanzig'],
      ['badge', '${badges.length}'],
    ];
    final address = lud16.trim();
    if (address.isNotEmpty) tags.add(['lud16', address]);

    final signed = await SigningService.signEvent(
      kind: guessKind,
      tags: tags,
      content: '$price',
    );

    final response = await http
        .post(
          round.postUrl,
          headers: const {'content-type': 'application/json', 'accept': 'application/json'},
          body: jsonEncode({
            'event': signed.toJson(),
            'proofs': badges.map(claimEvent).toList(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 200 && response.statusCode < 300) return null;
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['error'] is String) return body['error'] as String;
    } catch (_) {}
    return 'http_${response.statusCode}';
  }
}
