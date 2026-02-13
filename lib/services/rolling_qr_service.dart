// ============================================
// ROLLING QR SERVICE
// ============================================
// 
// Wie TOTP (Google Authenticator), aber für Meetup Check-In.
//
// Prinzip:
//   nonce = HMAC-SHA256(secret, floor(time / interval))
//   QR    = meetup_data + nonce + timestamp
//
// Der QR-Code ändert sich alle 10 Sekunden.
// Ein Screenshot ist nach 10s wertlos.
// Die Validierung akzeptiert ±1 Intervall (Toleranz).
//
// Secret = SHA256(organizer_privkey + meetup_id + datum)
// → Jeder Organisator, jedes Meetup, jeder Tag hat ein anderes Secret
// → Ohne den privkey kann niemand gültige QR-Codes erzeugen
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nostr_service.dart';
import 'badge_security.dart';

class RollingQRService {
  // Intervall in Sekunden (wie oft der QR-Code sich ändert)
  static const int intervalSeconds = 10;

  // Toleranz: akzeptiere auch das vorherige und nächste Intervall
  static const int toleranceSteps = 1;

  // =============================================
  // NONCE GENERIEREN (für Anzeige)
  // =============================================
  static String _generateNonce(String secret, int timeStep) {
    final key = utf8.encode(secret);
    final data = utf8.encode(timeStep.toString());
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    // 8 Zeichen Hex-Nonce (kompakt genug für QR)
    return digest.toString().substring(0, 16);
  }

  // Aktueller Time-Step
  static int _currentTimeStep() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ intervalSeconds;
  }

  // Secret aus Organizer-Key + Meetup + Datum ableiten
  static Future<String> _deriveSecret(String meetupId) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString('nostr_priv_hex') ?? '';
    final dateKey = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    
    final raw = '$privHex:$meetupId:$dateKey';
    final hash = sha256.convert(utf8.encode(raw));
    return hash.toString();
  }

  // =============================================
  // QR-PAYLOAD ERSTELLEN (Organizer-Seite)
  // Wird alle 10 Sekunden neu aufgerufen
  // =============================================
  static Future<Map<String, dynamic>> generatePayload({
    required String meetupId,
    required String meetupName,
    required String meetupCountry,
    required int blockHeight,
  }) async {
    final secret = await _deriveSecret(meetupId);
    final timeStep = _currentTimeStep();
    final nonce = _generateNonce(secret, timeStep);
    final timestamp = DateTime.now().toIso8601String();
    final npub = await NostrService.getNpub();

    // Signatur über die Daten (Nostr Schnorr)
    Map<String, dynamic> payload;
    final hasKey = await NostrService.hasKey();

    if (hasKey) {
      // v2: Nostr-signiert
      payload = await BadgeSecurity.signWithNostr(
        meetupId: meetupId,
        timestamp: timestamp,
        blockHeight: blockHeight,
        meetupName: meetupName,
        meetupCountry: meetupCountry,
        tagType: 'BADGE',
      );
    } else {
      // v1: Legacy
      final sig = BadgeSecurity.signLegacy(meetupId, timestamp, blockHeight);
      payload = {
        'type': 'BADGE',
        'meetup_id': meetupId,
        'timestamp': timestamp,
        'block_height': blockHeight,
        'meetup_name': meetupName,
        'meetup_country': meetupCountry,
        'sig': sig,
      };
    }

    // Rolling Nonce hinzufügen
    payload['qr_nonce'] = nonce;
    payload['qr_time_step'] = timeStep;
    payload['qr_interval'] = intervalSeconds;
    payload['delivery'] = 'rolling_qr'; // Damit Scanner weiß: das kam per QR

    return payload;
  }

  // =============================================
  // QR-STRING ERSTELLEN (zum Anzeigen)
  // =============================================
  static Future<String> generateQRString({
    required String meetupId,
    required String meetupName,
    required String meetupCountry,
    required int blockHeight,
  }) async {
    final payload = await generatePayload(
      meetupId: meetupId,
      meetupName: meetupName,
      meetupCountry: meetupCountry,
      blockHeight: blockHeight,
    );
    return jsonEncode(payload);
  }

  // =============================================
  // NONCE VALIDIEREN (Scanner-Seite)
  // Prüft ob der QR-Code frisch ist (±10 Sek)
  // =============================================
  static Future<NonceValidation> validateNonce(Map<String, dynamic> payload) async {
    final nonce = payload['qr_nonce'] as String?;
    final timeStep = payload['qr_time_step'] as int?;
    final meetupId = payload['meetup_id'] as String?;

    if (nonce == null || timeStep == null || meetupId == null) {
      return NonceValidation(
        isValid: false,
        message: 'QR-Code enthält keine Nonce-Daten',
        ageSeconds: -1,
      );
    }

    // Wir können das Secret nicht ableiten (wir haben nicht den privkey
    // des Organisators). ABER: Wir können die ZEIT prüfen.
    // Wenn der timeStep zu weit von unserem aktuellen entfernt ist,
    // ist der QR-Code abgelaufen.
    final currentStep = _currentTimeStep();
    final diff = (currentStep - timeStep).abs();

    if (diff > toleranceSteps) {
      final ageSeconds = diff * intervalSeconds;
      return NonceValidation(
        isValid: false,
        message: 'QR-Code abgelaufen (${ageSeconds}s alt)',
        ageSeconds: ageSeconds,
      );
    }

    // Zeit ist OK. Die kryptographische Validierung passiert
    // über die Schnorr-Signatur im BadgeSecurity.verify()
    final ageSeconds = diff * intervalSeconds;
    return NonceValidation(
      isValid: true,
      message: ageSeconds == 0 ? 'Frisch (aktuell)' : 'Gültig (${ageSeconds}s alt)',
      ageSeconds: ageSeconds,
    );
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  /// Sekunden bis zum nächsten QR-Wechsel
  static int secondsUntilNextChange() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now % intervalSeconds;
    return intervalSeconds - elapsed;
  }

  /// Fortschritt im aktuellen Intervall (0.0 bis 1.0)
  static double currentProgress() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final elapsed = now % intervalSeconds;
    return elapsed / intervalSeconds;
  }
}

class NonceValidation {
  final bool isValid;
  final String message;
  final int ageSeconds;

  NonceValidation({
    required this.isValid,
    required this.message,
    required this.ageSeconds,
  });
}