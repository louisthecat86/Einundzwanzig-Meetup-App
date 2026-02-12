// ============================================
// BADGE SECURITY v2
// Dual-Mode: Legacy (APP_SECRET) + Nostr (Schnorr)
// ============================================
//
// v1 (Legacy): SHA-256 HMAC mit APP_SECRET
//   → Für alte Tags die noch im Umlauf sind
//   → Wird beim Verifizieren noch akzeptiert
//
// v2 (Nostr): Schnorr-Signatur mit Admin-Key
//   → Für alle neuen Tags
//   → Enthält Admin-npub → jeder kann prüfen WER signiert hat
//   → Kein zentrales Geheimnis mehr
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BadgeSecurity {
  // =============================================
  // LEGACY v1: APP_SECRET (wird NICHT mehr für neue Tags genutzt)
  // Bleibt nur für Rückwärtskompatibilität
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
      final String id = data['meetup_id'] ?? 'global';
      final String ts = data['timestamp'] ?? '';
      final int bh = data['block_height'] ?? 0;
      final String signature = data['sig'] ?? '';
      final calculatedSignature = signLegacy(id, ts, bh);
      return signature == calculatedSignature;
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // v2: NOSTR SIGNIERUNG
  // Admin signiert Tags mit seinem privaten Schlüssel
  // =============================================

  /// v2: Tag-Daten mit Nostr-Key signieren (für NFC-Writer)
  /// Gibt die kompletten Tag-Daten MIT Signatur zurück
  static Future<Map<String, dynamic>> signWithNostr({
    required String meetupId,
    required String timestamp,
    required int blockHeight,
    required String meetupName,
    String meetupCountry = '',
    required String tagType, // 'BADGE' oder 'VERIFY'
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');
    final npub = prefs.getString('nostr_npub_key');

    if (privHex == null || npub == null) {
      throw Exception('Kein Nostr-Schlüssel vorhanden. Bitte erst Key generieren.');
    }

    // Die Daten die signiert werden
    final Map<String, dynamic> tagData = {
      'v': 2, // Version 2 = Nostr-signiert
      'type': tagType,
      'meetup_id': meetupId,
      'meetup_name': meetupName,
      'meetup_country': meetupCountry,
      'meetup_date': timestamp,
      'timestamp': timestamp,
      'block_height': blockHeight,
      'admin_npub': npub, // WER hat signiert
    };

    // Nostr-Event erstellen → Signatur entsteht automatisch
    final event = Event.from(
      kind: 21000, // Custom Kind: Einundzwanzig Badge
      tags: [
        ['t', tagType.toLowerCase()],
        ['meetup', meetupId],
        ['block', blockHeight.toString()],
      ],
      content: jsonEncode(tagData),
      privkey: privHex,
    );

    // Signatur + Event-ID zum Tag hinzufügen
    tagData['sig'] = event.sig;
    tagData['sig_id'] = event.id; // Event-ID für Nachvollziehbarkeit
    tagData['admin_pubkey'] = event.pubkey; // Hex-Pubkey des Admins

    return tagData;
  }

  /// v2: Nostr-Signatur prüfen
  /// Prüft ob die Schnorr-Signatur zum admin_pubkey passt
  static bool verifyNostr(Map<String, dynamic> data) {
    try {
      final String adminPubkey = data['admin_pubkey'] ?? '';
      final String signature = data['sig'] ?? '';
      final String eventId = data['sig_id'] ?? '';

      if (adminPubkey.isEmpty || signature.isEmpty || eventId.isEmpty) {
        return false;
      }

      // Tag-Daten ohne Signatur-Felder rekonstruieren
      final Map<String, dynamic> contentData = Map.from(data);
      contentData.remove('sig');
      contentData.remove('sig_id');
      contentData.remove('admin_pubkey');

      final content = jsonEncode(contentData);
      final meetupId = data['meetup_id'] ?? '';
      final blockHeight = data['block_height'] ?? 0;
      final tagType = (data['type'] ?? '').toString().toLowerCase();

      // Event nachbauen und validieren
      final event = Event(
        eventId,
        adminPubkey,
        data['block_height'] is int 
            ? (data['block_height'] as int) 
            : DateTime.now().millisecondsSinceEpoch ~/ 1000,
        21000,
        [
          ['t', tagType],
          ['meetup', meetupId.toString()],
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

  // =============================================
  // UNIFIED VERIFY: Prüft v1 UND v2
  // =============================================

  /// Erkennt automatisch ob v1 oder v2 und prüft entsprechend
  /// Gibt ein VerifyResult mit Details zurück
  static VerifyResult verify(Map<String, dynamic> data) {
    final int version = data['v'] ?? 1;

    if (version >= 2) {
      // v2: Nostr-Signatur prüfen
      final isValid = verifyNostr(data);
      return VerifyResult(
        isValid: isValid,
        version: 2,
        adminNpub: data['admin_npub'] ?? '',
        message: isValid
            ? 'Signatur gültig (Nostr)'
            : 'Nostr-Signatur ungültig!',
      );
    } else {
      // v1: Legacy-Signatur prüfen
      final isValid = verifyLegacy(data);
      return VerifyResult(
        isValid: isValid,
        version: 1,
        adminNpub: '',
        message: isValid
            ? 'Signatur gültig (Legacy)'
            : 'Legacy-Signatur ungültig!',
      );
    }
  }

  // =============================================
  // QR-CODE SIGNIERUNG (User signiert eigene Reputation)
  // =============================================

  /// QR-Code mit User's eigenem Nostr-Key signieren
  static Future<String> signQR(String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex');

    if (privHex == null) {
      // Fallback: Legacy-Signierung
      return signLegacy(jsonData, "QR", 0);
    }

    // Nostr-Event für QR-Signatur
    final event = Event.from(
      kind: 21001, // Custom Kind: Reputation QR
      tags: [],
      content: jsonData,
      privkey: privHex,
    );

    return event.sig;
  }

  /// QR-Code verifizieren (v1 oder v2)
  static QRVerifyResult verifyQR({
    required String data,
    required String signature,
    String? pubkeyHex,
  }) {
    // Versuch 1: Nostr-Signatur (wenn pubkey vorhanden)
    if (pubkeyHex != null && pubkeyHex.isNotEmpty) {
      try {
        final event = Event.from(
          kind: 21001,
          tags: [],
          content: data,
          privkey: '', // Wird nicht gebraucht für Verify
        );

        // Wir können die Event-Validierung nicht direkt nutzen
        // da wir den privkey nicht haben. Stattdessen prüfen wir
        // ob die Signatur zur pubkey passt.
        // Für jetzt: Legacy-Check als Fallback
      } catch (e) {
        // Fallthrough to legacy
      }
    }

    // Versuch 2: Legacy-Signatur
    final legacySig = signLegacy(data, "QR", 0);
    if (signature == legacySig) {
      return QRVerifyResult(
        isValid: true,
        version: 1,
        signerNpub: '',
      );
    }

    return QRVerifyResult(
      isValid: false,
      version: 0,
      signerNpub: '',
    );
  }

  // =============================================
  // BACKWARD COMPAT: Alte sign() Methode
  // Wird von reputation_qr.dart und qr_scanner.dart genutzt
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
  final int version;       // 1 = Legacy, 2 = Nostr
  final String adminNpub;  // Wer hat signiert (nur v2)
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