// ============================================
// ROLLING QR SERVICE v3.1 — UNIFIED SESSION
// ============================================
//
// Kombiniert zwei Sicherheitskonzepte und erzwingt EINE
// einheitliche Signatur für NFC und QR.
//
// 1. SESSION (6h gültig, überlebt App-Neustart)
//    → Generiert EINMALIG den signierten Base-Payload (Schnorr)
//    → Speichert diesen Base-Payload in SharedPreferences
//    → NFC Writer liest exakt diesen Payload.
//
// 2. ROLLING NONCE (alle 10s neu, Screenshot = wertlos)
//    → Nimmt den gespeicherten Base-Payload
//    → Hängt nonce = HMAC(sessionSeed, zeitschritt) an
//    → Hängt timeStep an
//
// ÄNDERUNG v3.1:
//   Session-Seed wird mit Random.secure() erzeugt statt
//   aus dem Private Key abgeleitet. Der Private Key darf
//   NUR zum Signieren verwendet werden, NIEMALS als
//   Seed-Material für andere Zwecke.
//
//   VORHER (unsicher):
//     seed = SHA256("$privHex:$meetupId:$now")
//     → Leakt Information über den Private Key
//     → Gleiche Inputs = gleicher Seed (deterministisch)
//
//   JETZT (sicher):
//     seed = hex(Random.secure().nextInt(256) * 32)
//     → 256 Bit kryptographisch sicherer Zufall
//     → Keine Verbindung zum Private Key
//     → Jede Session hat garantiert einzigartigen Seed
//
// HINWEIS ZUR NONCE-VALIDIERUNG:
//   Die Scanner-Seite kann die HMAC-Nonce NICHT verifizieren,
//   da sie den Session-Seed nicht kennt (by design — sonst
//   wäre der Anti-Screenshot-Schutz wirkungslos).
//   Die Nonce-Validierung prüft daher NUR die Zeitnähe.
//   Die eigentliche Sicherheit kommt von der Schnorr-Signatur
//   des Base-Payloads + dem Ablaufzeitpunkt (x).
//
// ============================================

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'nostr_service.dart';
import 'badge_security.dart';
import 'secure_key_store.dart';
import 'mempool.dart';

class RollingQRService {
  // Wie oft sich der QR ändert
  static const int intervalSeconds = 10;

  // Toleranz: akzeptiere ±1 Intervall (also bis 20s alt)
  static const int toleranceSteps = 1;

  // Session-Gültigkeit
  static const int sessionValidityHours = 6;

  // =============================================
  // SECURITY AUDIT C3: Session Seed in SecureStorage
  // =============================================
  // Der Session Seed ist das HMAC-Geheimnis für Rolling Nonces.
  // Muss in hardware-geschütztem Storage liegen.
  // =============================================
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _secureKeySessionSeed = 'rqr_session_seed_secure';
  // Security Audit 2, Fund #3: Base-Payload enthält Schnorr-Signatur
  // und gehört in hardware-geschützten Storage statt SharedPreferences.
  static const String _secureKeyBasePayload = 'rqr_session_base_payload_secure';

  // SharedPreferences Keys (nicht-sensible Session-Metadaten)
  static const String _keySessionSeed = 'rqr_session_seed'; // LEGACY → wird migriert
  static const String _keySessionStart = 'rqr_session_start';
  static const String _keySessionExpires = 'rqr_session_expires';
  static const String _keySessionMeetupId = 'rqr_session_meetup_id';
  static const String _keySessionMeetupName = 'rqr_session_meetup_name';
  static const String _keySessionMeetupCountry = 'rqr_session_meetup_country';
  static const String _keySessionBlockHeight = 'rqr_session_block_height';
  static const String _keySessionPubkey = 'rqr_session_pubkey';
  
  // Hier speichern wir den EINMALIG signierten Base-Payload
  static const String _keySessionBasePayload = 'rqr_session_base_payload';

  // =============================================
  // SEED MIGRATION: SharedPreferences → SecureStorage
  // =============================================
  static Future<void> _migrateSeedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final legacySeed = prefs.getString(_keySessionSeed);
    if (legacySeed != null && legacySeed.isNotEmpty) {
      // Migrate to secure storage
      await _secureStorage.write(key: _secureKeySessionSeed, value: legacySeed);
      await prefs.remove(_keySessionSeed);
    }
  }

  static Future<void> _saveSeedSecure(String seed) async {
    await _secureStorage.write(key: _secureKeySessionSeed, value: seed);
  }

  static Future<String?> _loadSeedSecure() async {
    await _migrateSeedIfNeeded();
    return await _secureStorage.read(key: _secureKeySessionSeed);
  }

  static Future<void> _deleteSeedSecure() async {
    await _secureStorage.delete(key: _secureKeySessionSeed);
  }

  // =============================================
  // BASE PAYLOAD: SecureStorage (Security Audit 2, Fund #3)
  // =============================================
  static Future<void> _saveBasePayloadSecure(String payload) async {
    await _secureStorage.write(key: _secureKeyBasePayload, value: payload);
  }

  static Future<String?> _loadBasePayloadSecure() async {
    // Migration: Falls noch in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_keySessionBasePayload);
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(key: _secureKeyBasePayload, value: legacy);
      await prefs.remove(_keySessionBasePayload);
    }
    return await _secureStorage.read(key: _secureKeyBasePayload);
  }

  static Future<void> _deleteBasePayloadSecure() async {
    await _secureStorage.delete(key: _secureKeyBasePayload);
    // Auch Legacy-Key aufräumen falls vorhanden
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySessionBasePayload);
  }

  // =============================================
  // KRYPTOGRAPHISCH SICHERER SEED-GENERATOR
  // =============================================
  //
  // Erzeugt 32 Bytes (256 Bit) kryptographisch sicheren
  // Zufall als Hex-String. Verwendet dart:math Random.secure()
  // das auf /dev/urandom (Linux), CryptGenRandom (Windows),
  // SecRandomCopyBytes (iOS/macOS) mapped.
  //
  // =============================================
  static String _generateSecureSeed() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

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

    // Wenn keine valide BlockHeight übergeben wurde (Fallback-Case), hole sie
    int finalBlockHeight = blockHeight;
    if (finalBlockHeight <= 0) {
      finalBlockHeight = await MempoolService.getBlockHeight();
      if (finalBlockHeight == 0) finalBlockHeight = 850000; // Fallback
    }

    // Neue Session erstellen
    return await _createSession(
      prefs: prefs,
      meetupId: meetupId,
      meetupName: meetupName,
      meetupCountry: meetupCountry,
      blockHeight: finalBlockHeight,
    );
  }

  /// Lädt bestehende Session (Seed aus SecureStorage, Rest aus SharedPreferences)
  static Future<MeetupSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final seed = await _loadSeedSecure(); // Security Audit C3: Aus SecureStorage
    final start = prefs.getInt(_keySessionStart);
    final expires = prefs.getInt(_keySessionExpires);
    final meetupId = prefs.getString(_keySessionMeetupId);

    if (seed == null || start == null || expires == null || meetupId == null) {
      return null;
    }

    final session = MeetupSession(
      seed: seed,
      startedAt: start,
      expiresAt: expires,
      meetupId: meetupId,
      meetupName: prefs.getString(_keySessionMeetupName) ?? '',
      meetupCountry: prefs.getString(_keySessionMeetupCountry) ?? '',
      blockHeight: prefs.getInt(_keySessionBlockHeight) ?? 0,
      pubkey: prefs.getString(_keySessionPubkey) ?? '',
    );

    // Wenn abgelaufen, direkt bereinigen
    if (session.isExpired) {
      await endSession();
      return null;
    }

    return session;
  }

  /// Neue Session erstellen und speichern
  static Future<MeetupSession> _createSession({
    required SharedPreferences prefs,
    required String meetupId,
    required String meetupName,
    required String meetupCountry,
    required int blockHeight,
  }) async {
    // 1. Keys laden (nur pubkey für die Session-Metadaten)
    final pubkey = await NostrService.getNpub() ?? '';
    
    // 2. Zeitstempel
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = now + (sessionValidityHours * 3600);

    // 3. Session-Seed: CSPRNG statt Private-Key-Ableitung
    //
    // VORHER (v3.0 — unsicher):
    //   final seedInput = '$privHex:$meetupId:$now';
    //   final seed = sha256.convert(utf8.encode(seedInput)).toString();
    //
    // JETZT (v3.1 — sicher):
    final seed = _generateSecureSeed();

    // 4. BASE-PAYLOAD EINMALIG SIGNIEREN
    Map<String, dynamic> basePayload;
    final hasKey = await NostrService.hasKey();
    if (hasKey) {
      try {
        basePayload = await BadgeSecurity.signCompact(
          meetupId: meetupId,
          blockHeight: blockHeight,
          validityHours: sessionValidityHours,
        );
      } catch (e) {
        // Signierung fehlgeschlagen — Session kann nicht erstellt werden
        // Legacy-Fallback wurde entfernt (Security Audit C1)
        throw StateError('Badge-Signierung fehlgeschlagen: $e. '
            'Bitte stelle sicher, dass ein Nostr-Key vorhanden ist.');
      }
    } else {
      // Kein Nostr-Key → Session kann nicht erstellt werden
      // Legacy-Fallback wurde entfernt (Security Audit C1)
      throw StateError('Kein Nostr-Key vorhanden. '
          'Bitte zuerst einen Key erstellen oder importieren.');
    }

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

    // 5. Session Seed in SecureStorage (Security Audit C3)
    await _saveSeedSecure(seed);
    
    // 6. Nicht-sensible Metadaten in SharedPreferences
    await prefs.setInt(_keySessionStart, now);
    await prefs.setInt(_keySessionExpires, expiresAt);
    await prefs.setString(_keySessionMeetupId, meetupId);
    await prefs.setString(_keySessionMeetupName, meetupName);
    await prefs.setString(_keySessionMeetupCountry, meetupCountry);
    await prefs.setInt(_keySessionBlockHeight, blockHeight);
    await prefs.setString(_keySessionPubkey, pubkey);
    
    // Base-Payload in SecureStorage speichern (enthält Schnorr-Signatur)
    await _saveBasePayloadSecure(jsonEncode(basePayload));

    return session;
  }

  /// Session beenden (manuell oder bei Ablauf)
  static Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _deleteSeedSecure(); // Security Audit C3: Seed aus SecureStorage löschen
    await prefs.remove(_keySessionSeed); // Legacy-Seed entfernen falls noch vorhanden
    await prefs.remove(_keySessionStart);
    await prefs.remove(_keySessionExpires);
    await prefs.remove(_keySessionMeetupId);
    await prefs.remove(_keySessionMeetupName);
    await prefs.remove(_keySessionMeetupCountry);
    await prefs.remove(_keySessionBlockHeight);
    await prefs.remove(_keySessionPubkey);
    await _deleteBasePayloadSecure();
  }

  // =============================================
  // PAYLOAD ABRUF (Für NFC Writer)
  // =============================================
  
  /// Gibt den statischen, fertig signierten Base-Payload für den NFC-Tag zurück
  static Future<Map<String, dynamic>?> getBasePayload() async {
    final session = await loadSession();
    if (session == null) return null;
    
    final payloadStr = await _loadBasePayloadSecure();
    if (payloadStr == null) return null;
    
    return jsonDecode(payloadStr);
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
    // 1. Hole den EINMALIG signierten Base-Payload aus SecureStorage
    final basePayloadStr = await _loadBasePayloadSecure();
    
    Map<String, dynamic> payload;
    if (basePayloadStr != null) {
      payload = jsonDecode(basePayloadStr);
    } else {
      // Kein Base-Payload vorhanden — Session ist ungültig
      // Legacy-Fallback wurde entfernt (Security Audit C1)
      throw StateError('Kein signierter Base-Payload vorhanden. '
          'Bitte neue Session starten.');
    }

    // 2. Rolling Nonce berechnen
    final timeStep = _currentTimeStep();
    final nonce = _generateNonce(session.seed, timeStep);

    // 3. Rolling-Felder an den bestehenden Payload anhängen
    //    HINWEIS: Diese Felder sind NICHT von der Schnorr-Signatur
    //    abgedeckt (werden vor Verify entfernt). Sie dienen nur
    //    dem Anti-Screenshot-Schutz via Zeitnähe-Check.
    payload['n'] = nonce;       // Rolling Nonce (16 hex)
    payload['ts'] = timeStep;   // Time-Step (für Validierung)
    payload['d'] = 'rolling_qr';// delivery methode

    return jsonEncode(payload);
  }

  /// @deprecated Legacy payload ist deaktiviert (Security Audit C1).
  /// Wird nicht mehr aufgerufen — alle Aufrufer wurden entfernt.
  /// Behält die Methode für Code-Kompatibilität, gibt aber
  /// ein unsigniertes Payload zurück das von verify() abgelehnt wird.
  static Map<String, dynamic> _legacyPayload(String meetupId, int blockHeight) {
    return {
      'v': 1,
      't': 'B',
      'm': meetupId,
      'b': blockHeight,
      'sig': '', // Leer — wird von verify() abgelehnt
    };
  }

  // =============================================
  // NONCE VALIDIEREN (Scanner-Seite)
  // =============================================
  //
  // WICHTIGER HINWEIS:
  // Der Scanner kann die HMAC-Nonce NICHT kryptographisch
  // verifizieren, da er den Session-Seed nicht kennt.
  // Er prüft NUR die Zeitnähe des timeStep.
  //
  // Das ist eine bewusste Design-Entscheidung:
  // - Den Seed zu verteilen würde den Anti-Screenshot-
  //   Schutz komplett aushebeln
  // - Die echte Sicherheit kommt von der Schnorr-Signatur
  //   im Base-Payload + dem Ablaufzeitpunkt
  // - Die Nonce verhindert nur Screenshot-Weitergabe
  //   (zeitlich begrenzt, nicht kryptographisch)
  //
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