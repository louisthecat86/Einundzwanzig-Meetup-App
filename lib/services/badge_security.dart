// ============================================
// BADGE SECURITY v2.1
// Dual-Mode: Legacy (APP_SECRET) + Nostr (Schnorr)
// + Kompakt-Format für kleine NFC-Tags
// ============================================
//
// v1 (Legacy): SHA-256 HMAC mit APP_SECRET
//   → Für alte Tags UND kleine Tags (NTAG213, 144 Bytes)
//
// v2 (Nostr): Schnorr-Signatur mit Admin-Key
//   → Für Tags mit ≥350 Bytes Kapazität (NTAG215+)
//   → Enthält Admin-Pubkey → jeder kann prüfen WER signiert hat
//   → Kein zentrales Geheimnis mehr
//
// KOMPAKT-FORMAT (kurze Keys für NFC):
//   v=Version, t=Type, m=MeetupId, n=MeetupName,
//   c=Country, ts=Timestamp, b=BlockHeight,
//   p=AdminPubkeyHex, s=Signature, i=EventId
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeSecurity {
  // =============================================
  // LEGACY v1: APP_SECRET
  // =============================================
  static const String _appSecret = "einundzwanzig_community_secret_21_btc_rocks";

  /// v1: Legacy-Signatur mit APP_SECRET
  static String signLegacy(String meetupId, String timestamp, int blockHeight) {
    final data = "$meetupId|$timestamp|$blockHeight|$_appSecret";
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// v1: Legacy-Verifizierung
  static bool verifyLegacy(Map<String, dynamic> data) {
    try {
      final norm = _normalizeFromCompact(data);
      final String id = norm['meetup_id'] ?? 'global';
      final String ts = norm['timestamp'] ?? '';
      final int bh = norm['block_height'] ?? 0;
      final String signature = norm['sig'] ?? '';
      final calculatedSignature = signLegacy(id, ts, bh);
      return signature == calculatedSignature;
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // v2: NOSTR SIGNIERUNG
  // =============================================

  /// v2: Tag-Daten mit Nostr-Key signieren
  /// Gibt KOMPAKTES Format zurück (kurze Keys für NFC)
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

    if (privHex == null || npub == null) {
      throw Exception('Kein Nostr-Schlüssel vorhanden.');
    }

    // Timestamp kürzen: nur bis Minute (spart ~10 Bytes)
    final shortTs = timestamp.length > 16 ? timestamp.substring(0, 16) : timestamp;

    // Daten für Nostr-Event (wird Content des Events)
    final Map<String, dynamic> contentForSign = {
      'v': 2,
      't': tagType == 'BADGE' ? 'B' : 'V',
      'm': meetupId,
      'n': meetupName,
      'ts': shortTs,
      'b': blockHeight,
    };

    // Nostr-Event erstellen → Signatur entsteht automatisch
    final event = Event.from(
      kind: 21000,
      tags: [
        ['t', tagType.toLowerCase()],
        ['meetup', meetupId],
        ['block', blockHeight.toString()],
      ],
      content: jsonEncode(contentForSign),
      privkey: privHex,
    );

    // KOMPAKTES Tag-Format (kurze Keys)
    final Map<String, dynamic> tagData = {
      'v': 2,
      't': tagType == 'BADGE' ? 'B' : 'V',
      'm': meetupId,
      'n': meetupName,
      'ts': shortTs,
      'b': blockHeight,
      'p': event.pubkey,    // Admin Pubkey (hex, 64 chars)
      's': event.sig,       // Schnorr Signature (128 chars)
      'i': event.id,        // Event ID (64 chars)
    };

    if (meetupCountry.isNotEmpty) {
      tagData['c'] = meetupCountry;
    }

    return tagData;
  }

  /// v2: Signieren mit voller Payload (für QR-Codes, nicht NFC)
  static Future<Map<String, dynamic>> signWithNostrFull({
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

    if (privHex == null || npub == null) {
      throw Exception('Kein Nostr-Schlüssel vorhanden.');
    }

    final Map<String, dynamic> tagData = {
      'v': 2,
      'type': tagType,
      'meetup_id': meetupId,
      'meetup_name': meetupName,
      'meetup_country': meetupCountry,
      'timestamp': timestamp,
      'block_height': blockHeight,
      'admin_npub': npub,
    };

    final event = Event.from(
      kind: 21000,
      tags: [
        ['t', tagType.toLowerCase()],
        ['meetup', meetupId],
        ['block', blockHeight.toString()],
      ],
      content: jsonEncode(tagData),
      privkey: privHex,
    );

    tagData['sig'] = event.sig;
    tagData['sig_id'] = event.id;
    tagData['admin_pubkey'] = event.pubkey;

    return tagData;
  }

  /// v1: KOMPAKT-Format für kleine Tags (NTAG213)
  static Map<String, dynamic> signLegacyCompact({
    required String meetupId,
    required String timestamp,
    required int blockHeight,
    required String meetupName,
    required String tagType,
  }) {
    final shortTs = timestamp.length > 16 ? timestamp.substring(0, 16) : timestamp;
    final signature = signLegacy(meetupId, shortTs, blockHeight);
    
    return {
      'v': 1,
      't': tagType == 'BADGE' ? 'B' : 'V',
      'm': meetupId,
      'n': meetupName,
      'ts': shortTs,
      'b': blockHeight,
      's': signature.substring(0, 32), // Gekürzt für kleine Tags
    };
  }

  // =============================================
  // NORMALISIERUNG: Kompakt → Voll
  // Wird beim Lesen/Verifizieren genutzt
  // =============================================

  /// Wandelt kompakte Keys in volle Keys um
  /// Funktioniert mit beiden Formaten
  static Map<String, dynamic> _normalizeFromCompact(Map<String, dynamic> data) {
    // Wenn schon volles Format → direkt zurück
    if (data.containsKey('meetup_id')) return data;

    // Kompakt → Voll
    final normalized = Map<String, dynamic>.from(data);
    
    if (data.containsKey('t')) {
      final t = data['t'];
      normalized['type'] = (t == 'B') ? 'BADGE' : (t == 'V') ? 'VERIFY' : t;
    }
    if (data.containsKey('m')) normalized['meetup_id'] = data['m'];
    if (data.containsKey('n')) normalized['meetup_name'] = data['n'];
    if (data.containsKey('c')) normalized['meetup_country'] = data['c'];
    if (data.containsKey('ts')) {
      normalized['timestamp'] = data['ts'];
      normalized['meetup_date'] = data['ts'];
    }
    if (data.containsKey('b')) normalized['block_height'] = data['b'];
    if (data.containsKey('p')) {
      normalized['admin_pubkey'] = data['p'];
      // npub aus hex ableiten
      try {
        normalized['admin_npub'] = Nip19.encodePubkey(data['p']);
      } catch (_) {}
    }
    if (data.containsKey('s')) normalized['sig'] = data['s'];
    if (data.containsKey('i')) normalized['sig_id'] = data['i'];

    return normalized;
  }

  /// Öffentliche Normalisierungsfunktion
  static Map<String, dynamic> normalize(Map<String, dynamic> data) {
    return _normalizeFromCompact(data);
  }

  // =============================================
  // VERIFIZIERUNG
  // =============================================

  /// v2: Nostr-Signatur prüfen (unterstützt kompaktes UND volles Format)
  static bool verifyNostr(Map<String, dynamic> data) {
    try {
      final norm = _normalizeFromCompact(data);
      final String adminPubkey = norm['admin_pubkey'] ?? norm['p'] ?? '';
      final String signature = norm['sig'] ?? norm['s'] ?? '';
      final String eventId = norm['sig_id'] ?? norm['i'] ?? '';

      if (adminPubkey.isEmpty || signature.isEmpty || eventId.isEmpty) {
        return false;
      }

      // Content rekonstruieren (ohne Signatur-Felder)
      final int version = data['v'] ?? 1;
      Map<String, dynamic> contentData;

      if (data.containsKey('meetup_id')) {
        // Volles Format
        contentData = Map.from(data);
        contentData.remove('sig');
        contentData.remove('sig_id');
        contentData.remove('admin_pubkey');
      } else {
        // Kompakt-Format: Content rekonstruieren wie beim Signieren
        contentData = {
          'v': 2,
          't': data['t'] ?? 'B',
          'm': data['m'] ?? '',
          'n': data['n'] ?? '',
          'ts': data['ts'] ?? '',
          'b': data['b'] ?? 0,
        };
      }

      final content = jsonEncode(contentData);
      final meetupId = (data['m'] ?? data['meetup_id'] ?? '').toString();
      final blockHeight = (data['b'] ?? data['block_height'] ?? 0);
      final tagType = data['t'] ?? (data['type'] ?? '').toString().toLowerCase();
      final normalizedType = (tagType == 'B') ? 'badge' : (tagType == 'V') ? 'verify' : tagType.toString().toLowerCase();

      final event = Event(
        eventId,
        adminPubkey,
        data['block_height'] is int
            ? (data['block_height'] as int)
            : DateTime.now().millisecondsSinceEpoch ~/ 1000,
        21000,
        [
          ['t', normalizedType],
          ['meetup', meetupId],
          ['block', blockHeight.toString()],
        ],
        content,
        signature,
      );

      return event.isValid();
    } catch (e) {
      return false;
    }
  }

  /// v1 kompakt verifizieren (gekürzter Hash)
  static bool verifyLegacyCompact(Map<String, dynamic> data) {
    try {
      final norm = _normalizeFromCompact(data);
      final String id = norm['meetup_id'] ?? 'global';
      final String ts = norm['timestamp'] ?? '';
      final int bh = norm['block_height'] ?? 0;
      final String signature = norm['sig'] ?? '';
      final calculatedSignature = signLegacy(id, ts, bh);
      // Vergleich mit gekürztem Hash
      return calculatedSignature.startsWith(signature) || signature == calculatedSignature;
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // UNIFIED VERIFY: Prüft v1 UND v2, kompakt UND voll
  // =============================================

  static VerifyResult verify(Map<String, dynamic> data) {
    final int version = data['v'] ?? 1;
    final norm = _normalizeFromCompact(data);

    if (version >= 2) {
      final isValid = verifyNostr(data);
      return VerifyResult(
        isValid: isValid,
        version: 2,
        adminNpub: norm['admin_npub'] ?? '',
        message: isValid
            ? 'Signatur gültig (Nostr v2)'
            : 'Nostr-Signatur ungültig!',
      );
    } else {
      // v1: Versuche volle UND kompakte Verifizierung
      final isValid = verifyLegacy(data) || verifyLegacyCompact(data);
      return VerifyResult(
        isValid: isValid,
        version: 1,
        adminNpub: '',
        message: isValid
            ? 'Signatur gültig (Legacy v1)'
            : 'Legacy-Signatur ungültig!',
      );
    }
  }

  // =============================================
  // QR-CODE SIGNIERUNG
  // =============================================

  static Future<String> signQR(String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');

    if (privHex == null) {
      return signLegacy(jsonData, "QR", 0);
    }

    final event = Event.from(
      kind: 21001,
      tags: [],
      content: jsonData,
      privkey: privHex,
    );

    return event.sig;
  }

  static QRVerifyResult verifyQR({
    required String data,
    required String signature,
    String? pubkeyHex,
  }) {
    if (pubkeyHex != null && pubkeyHex.isNotEmpty) {
      try {
        final event = Event.from(
          kind: 21001,
          tags: [],
          content: data,
          privkey: '',
        );
      } catch (e) {
        // Fallthrough to legacy
      }
    }

    final legacySig = signLegacy(data, "QR", 0);
    if (signature == legacySig) {
      return QRVerifyResult(isValid: true, version: 1, signerNpub: '');
    }

    return QRVerifyResult(isValid: false, version: 0, signerNpub: '');
  }

  // =============================================
  // BACKWARD COMPAT
  // =============================================
  static String sign(String meetupId, String timestamp, int blockHeight) {
    return signLegacy(meetupId, timestamp, blockHeight);
  }
}

// =============================================
// RESULT KLASSEN
// =============================================

class VerifyResult {
  final bool isValid;
  final int version;
  final String adminNpub;
  final String message;

  VerifyResult({
    required this.isValid,
    required this.version,
    required this.adminNpub,
    required this.message,
  });
}

class QRVerifyResult {
  final bool isValid;
  final int version;
  final String signerNpub;

  QRVerifyResult({
    required this.isValid,
    required this.version,
    required this.signerNpub,
  });
}