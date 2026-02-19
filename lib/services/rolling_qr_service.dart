// ============================================
// ROLLING QR SERVICE v2 — SESSION + ROLLING
// ============================================
//
// Kombiniert zwei Sicherheitskonzepte:
//
// 1. SESSION (6h gültig, überlebt App-Neustart)
//    → Wird in SharedPreferences gespeichert
//    → Gleicher Seed für die gesamte Meetup-Dauer
//    → Nachzügler nach 1h → kein Problem
//
// 2. ROLLING NONCE (alle 10s neu, Screenshot = wertlos)
//    → nonce = HMAC(sessionSeed, zeitschritt)
//    → Code ändert sich → Foto weiterleiten unmöglich
//    → Scanner prüft: ist der Zeitschritt aktuell?
//
// Krypto-Kette:
//   sessionSeed = SHA256(privkey + meetupId + startTime)
//   nonce       = HMAC(sessionSeed, floor(now / 10))
//   payload     = signCompact(meetup) + nonce + timeStep
//   
// Scanner-Seite:
//   1. BadgeSecurity.verify() → Schnorr-Check
//   2. validateNonce() → Zeitschritt aktuell? (±1 Toleranz)
//   3. isExpired() → Session noch gültig?
//
// SICHERHEIT:
//   - Private Key wird über SecureKeyStore geladen
//   - Session-Seed ist ein SHA256 Derivat → kein Rückschluss
//     auf den privaten Schlüssel möglich
//
// ============================================

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nostr_service.dart';
import 'badge_security.dart';
import 'secure_key_store.dart';

class RollingQRService {
  // Wie oft sich der QR ändert
  static const int intervalSeconds = 10;

  // Toleranz: akzeptiere ±1 Intervall (also bis 20s alt)
  static const int toleranceSteps = 1;

  // Session-Gültigkeit
  static const int sessionValidityHours = 6;

  // SharedPreferences Keys (Session-Daten sind nicht geheim,
  // nur der Seed wird aus dem privKey abgeleitet)
  static const String _keySessionSeed = 'rqr_session_seed';
  static const String _keySessionStart = 'rqr_session_start';
  static const String _keySessionExpires = 'rqr_session_expires';
  static const String _keySessionMeetupId = 'rqr_session_meetup_id';
  static const String _keySessionMeetupName = 'rqr_session_meetup_name';
  static const String _keySessionMeetupCountry = 'rqr_session_meetup_country';
  static const String _keySessionBlockHeight = 'rqr_session_block_height';
  static const String _keySessionPubkey = 'rqr_session_pubkey';

  // =============================================
  // SESSION MANAGEMENT
  // =============================================

  /// Startet eine neue 6h-Session oder lädt eine bestehende
  static Future<MeetupSession?> getOrCreateSession({
    required String meetupId,
    required String meetupName,
    required String meetupCountry,
    required int blockHeight,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Bestehende Session prüfen
    final existing = await loadSession();
    if (existing != null && !existing.isExpired && existing.meetupId == meetupId) {
      return existing;
    }

    // Neue Session erstellen
    return await _createSession(
      prefs: prefs,
      meetupId: meetupId,
      meetupName: meetupName,
      meetupCountry: meetupCountry,
      blockHeight: blockHeight,
    );
  }

  /// Lädt bestehende Session aus SharedPreferences
  static Future<MeetupSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final seed = prefs.getString(_keySessionSeed);
    final start = prefs.getInt(_keySessionStart);
    final expires = prefs.getInt(_keySessionExpires);
    final meetupId = prefs.getString(_keySessionMeetupId);

    if (seed == null || start == null || expires == null || meetupId == null) {
      return null;
    }

    return MeetupSession(
      seed: seed,
      startedAt: start,
      expiresAt: expires,
      meetupId: meetupId,
      meetupName: prefs.getString(_keySessionMeetupName) ?? '',
      meetupCountry: prefs.getString(_keySessionMeetupCountry) ?? '',
      blockHeight: prefs.getInt(_keySessionBlockHeight) ?? 0,
      pubkey: prefs.getString(_keySessionPubkey) ?? '',
    );
  }

  /// Neue Session erstellen und speichern
  static Future<MeetupSession> _createSession({
    required SharedPreferences prefs,
    required String meetupId,
    required String meetupName,
    required String meetupCountry,
    required int blockHeight,
  }) async {
    // Private Key aus SecureKeyStore laden (nicht mehr aus SharedPreferences)
    final privHex = await SecureKeyStore.getPrivHex() ?? '';
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = now + (sessionValidityHours * 3600);

    // Session-Seed: deterministisch aus privkey + meetup + startzeit
    // → Gleicher Organisator, gleiches Meetup = gleicher Seed pro Session
    // Der SHA256-Hash lässt keinen Rückschluss auf den privKey zu.
    final seedInput = '$privHex:$meetupId:$now';
    final seed = sha256.convert(utf8.encode(seedInput)).toString();

    // Pubkey für Signatur
    String pubkey = '';
    try {
      final npub = await NostrService.getNpub();
      pubkey = npub ?? '';
    } catch (_) {}

    final session = MeetupSession(
      seed: seed,
      startedAt: now,
      expiresAt: expiresAt,
      meetupId: meetupId,
      meetupName: meetupName,
      meetupCountry: meetupCountry,
      blockHeight: blockHeight,
      pubkey: pubkey,
    );

    // In SharedPreferences speichern
    // (Session-Seed ist ein Hash-Derivat, kein Schlüssel)
    await prefs.setString(_keySessionSeed, seed);
    await prefs.setInt(_keySessionStart, now);
    await prefs.setInt(_keySessionExpires, expiresAt);
    await prefs.setString(_keySessionMeetupId, meetupId);
    await prefs.setString(_keySessionMeetupName, meetupName);
    await prefs.setString(_keySessionMeetupCountry, meetupCountry);
    await prefs.setInt(_keySessionBlockHeight, blockHeight);
    await prefs.setString(_keySessionPubkey, pubkey);

    return session;
  }

  /// Session beenden (manuell oder bei Ablauf)
  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionSeed);
    await prefs.remove(_keySessionStart);
    await prefs.remove(_keySessionExpires);
    await prefs.remove(_keySessionMeetupId);
    await prefs.remove(_keySessionMeetupName);
    await prefs.remove(_keySessionMeetupCountry);
    await prefs.remove(_keySessionBlockHeight);
    await prefs.remove(_keySessionPubkey);
  }

  // =============================================
  // ROLLING NONCE (Anti-Screenshot)
  // =============================================

  static String _generateNonce(String seed, int timeStep) {
    final key = utf8.encode(seed);
    final data = utf8.encode(timeStep.toString());
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.toString().substring(0, 16); // 16 hex = 8 Bytes
  }

  static int _currentTimeStep() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ intervalSeconds;
  }

  // =============================================
  // QR-PAYLOAD GENERIEREN (Organisator-Seite)
  // Wird alle 10 Sekunden aufgerufen
  // =============================================

  static Future<String> generateQRString(MeetupSession session) async {
    final timeStep = _currentTimeStep();
    final nonce = _generateNonce(session.seed, timeStep);

    // Kompakt-Format: Badge-Daten + Rolling-Felder
    // Signiert mit signCompact (Schnorr)
    Map<String, dynamic> payload;

    final hasKey = await NostrService.hasKey();
    if (hasKey) {
      try {
        payload = await BadgeSecurity.signCompact(
          meetupId: session.meetupId,
          blockHeight: session.blockHeight,
          validityHours: sessionValidityHours,
        );
      } catch (e) {
        // Fallback Legacy
        payload = _legacyPayload(session);
      }
    } else {
      payload = _legacyPayload(session);
    }

    // Rolling-Felder anhängen
    payload['n'] = nonce;       // Rolling Nonce (16 hex)
    payload['ts'] = timeStep;   // Time-Step (für Validierung)
    payload['d'] = 'qr';       // delivery = rolling_qr

    return jsonEncode(payload);
  }

  static Map<String, dynamic> _legacyPayload(MeetupSession session) {
    final sig = BadgeSecurity.signLegacy(session.meetupId, DateTime.now().toIso8601String(), session.blockHeight);
    return {
      'v': 1,
      't': 'B',
      'm': session.meetupId,
      'b': session.blockHeight,
      'sig': sig,
    };
  }

  // =============================================
  // NONCE VALIDIEREN (Scanner-Seite)
  // =============================================

  static NonceValidation validateNonce(Map<String, dynamic> payload) {
    // Neue kompakte Felder
    final nonce = payload['n'] as String? ?? payload['qr_nonce'] as String?;
    final timeStep = payload['ts'] as int? ?? payload['qr_time_step'] as int?;

    if (nonce == null || timeStep == null) {
      // Kein Rolling QR — normaler NFC-Scan, das ist OK
      return NonceValidation(isValid: true, message: 'Kein Rolling-QR (NFC/Static)', ageSeconds: 0);
    }

    final currentStep = _currentTimeStep();
    final diff = (currentStep - timeStep).abs();

    if (diff > toleranceSteps) {
      final ageSeconds = diff * intervalSeconds;
      return NonceValidation(
        isValid: false,
        message: 'QR-Code abgelaufen (${ageSeconds}s alt). Bitte direkt am Bildschirm scannen.',
        ageSeconds: ageSeconds,
      );
    }

    final ageSeconds = diff * intervalSeconds;
    return NonceValidation(
      isValid: true,
      message: ageSeconds == 0 ? 'Frisch ✓' : 'Gültig (${ageSeconds}s)',
      ageSeconds: ageSeconds,
    );
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  static int secondsUntilNextChange() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return intervalSeconds - (now % intervalSeconds);
  }

  static double currentProgress() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (now % intervalSeconds) / intervalSeconds;
  }
}

// =============================================
// DATENKLASSEN
// =============================================

class MeetupSession {
  final String seed;
  final int startedAt;
  final int expiresAt;
  final String meetupId;
  final String meetupName;
  final String meetupCountry;
  final int blockHeight;
  final String pubkey;

  MeetupSession({
    required this.seed,
    required this.startedAt,
    required this.expiresAt,
    required this.meetupId,
    required this.meetupName,
    required this.meetupCountry,
    required this.blockHeight,
    required this.pubkey,
  });

  bool get isExpired {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now > expiresAt;
  }

  Duration get remainingTime {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = expiresAt - now;
    return Duration(seconds: diff > 0 ? diff : 0);
  }

  String get remainingTimeString {
    final r = remainingTime;
    if (r.inSeconds <= 0) return 'Abgelaufen';
    if (r.inHours > 0) return '${r.inHours}h ${r.inMinutes % 60}min';
    return '${r.inMinutes}min';
  }

  Duration get elapsedTime {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return Duration(seconds: now - startedAt);
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