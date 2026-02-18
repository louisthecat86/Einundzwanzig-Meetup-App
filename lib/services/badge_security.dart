// ============================================
// BADGE SECURITY v3 — KOMPAKT + WASSERDICHT
// ============================================
//
// KOMPAKT-FORMAT (für NFC Tags — max 492B):
//   {"v":2,"t":"B","m":"city-cc","b":875432,"x":1739927280,
//    "c":1739905680,"p":"64hex","s":"128hex"}
//
//   ~285 Bytes → passt auf NTAG215 (492B)
//
// KRYPTO-KETTE:
//   1. signCompact() → Content {v,t,m,b,x} wird signiert
//   2. verifyCompact() → Event rekonstruiert → Schnorr-Check
//   3. Ablauf-Check: x > now() sonst "Tag abgelaufen"
//
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeSecurity {
  static const int badgeValidityHours = 6;

  // =============================================
  // LEGACY v1
  // =============================================
  static const String _appSecret = "einundzwanzig_community_secret_21_btc_rocks";

  static String signLegacy(String meetupId, String timestamp, int blockHeight) {
    final data = "$meetupId|$timestamp|$blockHeight|$_appSecret";
    return sha256.convert(utf8.encode(data)).toString();
  }

  static bool verifyLegacy(Map<String, dynamic> data) {
    try {
      final String id = data['meetup_id'] ?? data['m'] ?? 'global';
      final String ts = data['timestamp'] ?? data['c']?.toString() ?? '';
      final int bh = data['block_height'] ?? data['b'] ?? 0;
      final String signature = data['sig'] ?? data['s'] ?? '';
      return signature == signLegacy(id, ts, bh);
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // v2 KOMPAKT: NFC-Tag signieren (~285 Bytes)
  // =============================================

  static Future<Map<String, dynamic>> signCompact({
    required String meetupId,
    required int blockHeight,
    int validityHours = 6,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');
    if (privHex == null) throw Exception('Kein Nostr-Schlüssel vorhanden.');

    final int expiresAt = DateTime.now().millisecondsSinceEpoch ~/ 1000 + (validityHours * 3600);

    // Content der signiert wird (OHNE c, p, s)
    final Map<String, dynamic> content = {
      'v': 2,
      't': 'B',
      'm': meetupId,
      'b': blockHeight,
      'x': expiresAt,
    };

    final contentJson = jsonEncode(content);
    final tags = [['t', 'badge'], ['m', meetupId]];

    final event = Event.from(
      kind: 21000,
      tags: tags,
      content: contentJson,
      privkey: privHex,
    );

    return {
      ...content,
      'c': event.createdAt,
      'p': event.pubkey,
      's': event.sig,
    };
  }

  // =============================================
  // v2 KOMPAKT: Verifizierung
  // =============================================

  static VerifyResult verifyCompact(Map<String, dynamic> data) {
    try {
      final String pubkey = data['p'] ?? '';
      final String sig = data['s'] ?? '';
      final int createdAt = data['c'] ?? 0;

      if (pubkey.isEmpty || sig.isEmpty || createdAt == 0) {
        return VerifyResult(isValid: false, version: 2, adminNpub: '', adminPubkey: '',
          message: 'Fehlende Signatur-Daten');
      }

      // Ablauf prüfen
      final int expiresAt = data['x'] ?? 0;
      if (expiresAt > 0) {
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        if (now > expiresAt) {
          return VerifyResult(isValid: false, version: 2, adminNpub: '', adminPubkey: pubkey,
            message: 'Tag abgelaufen! ${expiryInfo(data)}. Bitte Organisator um neuen Tag.');
        }
      }

      // Content rekonstruieren (OHNE c, p, s)
      final Map<String, dynamic> content = {};
      for (final key in data.keys) {
        if (key != 'c' && key != 'p' && key != 's') {
          content[key] = data[key];
        }
      }
      final contentJson = jsonEncode(content);
      final meetupId = data['m'] ?? '';
      final tags = [['t', 'badge'], ['m', meetupId.toString()]];

      // Event-ID nachrechnen
      final serialized = jsonEncode([0, pubkey, createdAt, 21000, tags, contentJson]);
      final eventId = sha256.convert(utf8.encode(serialized)).toString();

      final event = Event(eventId, pubkey, createdAt, 21000, tags, contentJson, sig);
      final isValid = event.isValid();

      String adminNpub = '';
      try { adminNpub = Nip19.encodePubkey(pubkey); } catch (_) {}

      return VerifyResult(
        isValid: isValid, version: 2,
        adminNpub: adminNpub, adminPubkey: pubkey,
        message: isValid ? 'Schnorr-Signatur gültig ✓' : 'Signatur ungültig!',
      );
    } catch (e) {
      return VerifyResult(isValid: false, version: 0, adminNpub: '', adminPubkey: '',
        message: 'Verifikations-Fehler: $e');
    }
  }

  // =============================================
  // v2 LEGACY (volles Format) — Für alte Tags
  // =============================================

  static Future<Map<String, dynamic>> signWithNostr({
    required String meetupId,
    required String timestamp,
    required int blockHeight,
    required String meetupName,
    String meetupCountry = '',
    required String tagType,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');
    final npub = prefs.getString('nostr_npub_key');
    if (privHex == null || npub == null) throw Exception('Kein Nostr-Schlüssel vorhanden.');

    final Map<String, dynamic> tagData = {
      'v': 2, 'type': tagType,
      'meetup_id': meetupId, 'meetup_name': meetupName, 'meetup_country': meetupCountry,
      'meetup_date': timestamp, 'timestamp': timestamp,
      'block_height': blockHeight, 'admin_npub': npub,
    };

    final event = Event.from(
      kind: 21000,
      tags: [['t', tagType.toLowerCase()], ['meetup', meetupId], ['block', blockHeight.toString()]],
      content: jsonEncode(tagData),
      privkey: privHex,
    );

    tagData['sig'] = event.sig;
    tagData['sig_id'] = event.id;
    tagData['admin_pubkey'] = event.pubkey;
    return tagData;
  }

  static bool verifyNostr(Map<String, dynamic> data) {
    try {
      final String adminPubkey = data['admin_pubkey'] ?? '';
      final String signature = data['sig'] ?? '';
      final String eventId = data['sig_id'] ?? '';
      if (adminPubkey.isEmpty || signature.isEmpty || eventId.isEmpty) return false;

      final Map<String, dynamic> contentData = Map.from(data);
      contentData.remove('sig');
      contentData.remove('sig_id');
      contentData.remove('admin_pubkey');
      contentData.remove('_verified_by');

      final content = jsonEncode(contentData);
      final meetupId = data['meetup_id'] ?? '';
      final blockHeight = data['block_height'] ?? 0;
      final tagType = (data['type'] ?? '').toString().toLowerCase();

      final event = Event(
        eventId, adminPubkey,
        data['block_height'] is int ? (data['block_height'] as int) : DateTime.now().millisecondsSinceEpoch ~/ 1000,
        21000,
        [['t', tagType], ['meetup', meetupId.toString()], ['block', blockHeight.toString()]],
        content, signature,
      );
      return event.isValid();
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // UNIFIED VERIFY: Kompakt + Legacy
  // =============================================

  static VerifyResult verify(Map<String, dynamic> data) {
    // Kompakt-Format? (hat 'p' und 's' statt 'admin_pubkey' und 'sig')
    if (data.containsKey('p') && data.containsKey('s') && !data.containsKey('sig')) {
      return verifyCompact(data);
    }

    final int version = data['v'] ?? 1;
    if (version >= 2) {
      final isValid = verifyNostr(data);
      String adminNpub = data['admin_npub'] ?? '';
      if (adminNpub.isEmpty && (data['admin_pubkey'] ?? '').isNotEmpty) {
        try { adminNpub = Nip19.encodePubkey(data['admin_pubkey']); } catch (_) {}
      }
      return VerifyResult(isValid: isValid, version: 2, adminNpub: adminNpub,
        adminPubkey: data['admin_pubkey'] ?? '',
        message: isValid ? 'Schnorr-Signatur gültig (Legacy-Format)' : 'Signatur ungültig!');
    }

    final isValid = verifyLegacy(data);
    return VerifyResult(isValid: isValid, version: 1, adminNpub: '', adminPubkey: '',
      message: isValid ? 'Signatur gültig (Legacy v1)' : 'Legacy-Signatur ungültig!');
  }

  // =============================================
  // COMPACT FORMAT: Normalisierung
  // =============================================

  static Map<String, dynamic> normalize(Map<String, dynamic> data) {
    if (data.containsKey('meetup_id')) return data;

    final normalized = <String, dynamic>{};
    normalized['v'] = data['v'] ?? 1;

    final t = data['t'];
    if (t == 'B') normalized['type'] = 'BADGE';
    else if (t is String) normalized['type'] = t;
    else normalized['type'] = data['type'] ?? 'BADGE';

    // Meetup-ID: "aschaffenburg-de" → id + country
    final m = data['m'] as String? ?? '';
    if (m.contains('-')) {
      final parts = m.split('-');
      final country = parts.last.toUpperCase();
      final city = parts.sublist(0, parts.length - 1).join('-');
      normalized['meetup_id'] = city;
      normalized['meetup_name'] = city[0].toUpperCase() + city.substring(1);
      normalized['meetup_country'] = country;
    } else {
      normalized['meetup_id'] = m;
      normalized['meetup_name'] = m;
    }

    if (data['meetup_name'] != null) normalized['meetup_name'] = data['meetup_name'];
    if (data['meetup_country'] != null) normalized['meetup_country'] = data['meetup_country'];

    if (data['c'] != null) {
      final int c = data['c'];
      final dt = DateTime.fromMillisecondsSinceEpoch(c * 1000);
      normalized['timestamp'] = dt.toIso8601String();
      normalized['meetup_date'] = dt.toIso8601String();
    } else if (data['timestamp'] != null) {
      normalized['timestamp'] = data['timestamp'];
      normalized['meetup_date'] = data['meetup_date'] ?? data['timestamp'];
    }

    normalized['block_height'] = data['b'] ?? data['block_height'] ?? 0;
    if (data['x'] != null) normalized['expires_at'] = data['x'];

    if (data['p'] != null) {
      normalized['admin_pubkey'] = data['p'];
      try { normalized['admin_npub'] = Nip19.encodePubkey(data['p']); } catch (_) {}
    } else if (data['admin_pubkey'] != null) {
      normalized['admin_pubkey'] = data['admin_pubkey'];
      normalized['admin_npub'] = data['admin_npub'] ?? '';
    }

    if (data['s'] != null) normalized['sig'] = data['s'];
    else if (data['sig'] != null) normalized['sig'] = data['sig'];
    if (data['sig_id'] != null) normalized['sig_id'] = data['sig_id'];

    if (data['qr_nonce'] != null) normalized['qr_nonce'] = data['qr_nonce'];
    if (data['qr_time_step'] != null) normalized['qr_time_step'] = data['qr_time_step'];
    if (data['qr_interval'] != null) normalized['qr_interval'] = data['qr_interval'];
    if (data['delivery'] != null) normalized['delivery'] = data['delivery'];

    // Kompakte Rolling-QR-Felder
    if (data['n'] != null) normalized['qr_nonce'] = data['n'];
    if (data['ts'] != null) normalized['qr_time_step'] = data['ts'];
    if (data['d'] != null) normalized['delivery'] = data['d'] == 'qr' ? 'rolling_qr' : data['d'];

    return normalized;
  }

  // =============================================
  // ABLAUF-CHECK
  // =============================================

  static bool isExpired(Map<String, dynamic> data) {
    final int expiresAt = data['x'] ?? data['expires_at'] ?? 0;
    if (expiresAt == 0) return false;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 > expiresAt;
  }

  static String expiryInfo(Map<String, dynamic> data) {
    final int expiresAt = data['x'] ?? data['expires_at'] ?? 0;
    if (expiresAt == 0) return 'Kein Ablauf';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = expiresAt - now;
    if (diff <= 0) {
      final ago = Duration(seconds: -diff);
      if (ago.inHours > 0) return 'Abgelaufen vor ${ago.inHours}h ${ago.inMinutes % 60}min';
      return 'Abgelaufen vor ${ago.inMinutes}min';
    }
    final remaining = Duration(seconds: diff);
    if (remaining.inHours > 0) return 'Gültig noch ${remaining.inHours}h ${remaining.inMinutes % 60}min';
    return 'Gültig noch ${remaining.inMinutes}min';
  }

  // =============================================
  // QR-CODE SIGNIERUNG + VERIFIZIERUNG
  // =============================================

  static Future<QRSignResult> signQRv3(String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');
    if (privHex == null) {
      final legacySig = signLegacy(jsonData, "QR", 0);
      return QRSignResult(signature: legacySig, eventId: '', createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000, pubkeyHex: '', isNostr: false);
    }
    final event = Event.from(kind: 21001, tags: [], content: jsonData, privkey: privHex);
    return QRSignResult(signature: event.sig, eventId: event.id, createdAt: event.createdAt, pubkeyHex: event.pubkey, isNostr: true);
  }

  static Future<String> signQR(String jsonData) async {
    final result = await signQRv3(jsonData);
    return result.signature;
  }

  static QRVerifyResult verifyQRv3({
    required String jsonData, required String signature,
    required String eventId, required int createdAt, required String pubkeyHex,
  }) {
    if (pubkeyHex.isEmpty || signature.isEmpty || eventId.isEmpty) {
      return QRVerifyResult(isValid: false, version: 0, signerNpub: '', message: 'Fehlende Signatur-Daten');
    }
    try {
      final event = Event(eventId, pubkeyHex, createdAt, 21001, [], jsonData, signature);
      final isValid = event.isValid();
      String signerNpub = '';
      try { signerNpub = Nip19.encodePubkey(pubkeyHex); } catch (_) {}
      return QRVerifyResult(isValid: isValid, version: 3, signerNpub: signerNpub,
        message: isValid ? 'Schnorr-Signatur verifiziert ✓' : 'Schnorr-Signatur UNGÜLTIG!');
    } catch (e) {
      return QRVerifyResult(isValid: false, version: 0, signerNpub: '', message: 'Fehler: $e');
    }
  }

  static QRVerifyResult verifyQRLegacy({required String jsonData, required String signature, String? pubkeyHex}) {
    final legacySig = signLegacy(jsonData, "QR", 0);
    if (signature == legacySig) {
      return QRVerifyResult(isValid: true, version: 1, signerNpub: '', message: 'Legacy-Signatur gültig');
    }
    return QRVerifyResult(isValid: false, version: 0, signerNpub: '', message: 'Signatur ungültig');
  }

  static String sign(String meetupId, String timestamp, int blockHeight) => signLegacy(meetupId, timestamp, blockHeight);
}

// =============================================
// RESULT KLASSEN
// =============================================

class VerifyResult {
  final bool isValid;
  final int version;
  final String adminNpub;
  final String adminPubkey;
  final String message;
  VerifyResult({required this.isValid, required this.version, required this.adminNpub, this.adminPubkey = '', required this.message});
}

class QRSignResult {
  final String signature;
  final String eventId;
  final int createdAt;
  final String pubkeyHex;
  final bool isNostr;
  QRSignResult({required this.signature, required this.eventId, required this.createdAt, required this.pubkeyHex, required this.isNostr});
}

class QRVerifyResult {
  final bool isValid;
  final int version;
  final String signerNpub;
  final String message;
  QRVerifyResult({required this.isValid, required this.version, required this.signerNpub, this.message = ''});
}