// ============================================
// NOSTR SERVICE
// Schlüssel-Management & Signierung
// ============================================
//
// Was macht dieser Service?
// 1. Keypair generieren (für neue User)
// 2. Keypair importieren (nsec eingeben)
// 3. Daten signieren (Badges, QR-Codes)
// 4. Signaturen prüfen (von anderen Usern)
// 5. npub/nsec Konvertierung
//
// Das nostr-Package übernimmt die Krypto:
// - secp256k1 für Schlüsselpaare
// - Schnorr-Signaturen (BIP-340)
// - Bech32 für npub/nsec Encoding
// ============================================

import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class NostrService {
  // SharedPreferences Keys
  static const String _nsecKey = 'nostr_nsec_key';  // Privater Schlüssel
  static const String _npubKey = 'nostr_npub_key';  // Öffentlicher Schlüssel (abgeleitet)
  static const String _privHexKey = 'nostr_priv_hex'; // Private Key als Hex (für schnellen Zugriff)

  // =============================================
  // SCHLÜSSEL GENERIEREN
  // Erstellt ein komplett neues Keypair
  // =============================================
  static Future<Map<String, String>> generateKeyPair() async {
    // 1. Zufälliges Keypair erzeugen (secp256k1)
    final keychain = Keychain.generate();

    // 2. In Bech32 konvertieren (npub1.../nsec1...)
    final npub = Nip19.encodePubkey(keychain.public);
    final nsec = Nip19.encodePrivkey(keychain.private);

    // 3. Lokal speichern
    await _saveKeys(
      nsec: nsec,
      npub: npub,
      privHex: keychain.private,
    );

    return {
      'nsec': nsec,
      'npub': npub,
      'pubHex': keychain.public,
    };
  }

  // =============================================
  // SCHLÜSSEL IMPORTIEREN
  // User gibt seinen bestehenden nsec ein
  // =============================================
  static Future<Map<String, String>> importNsec(String nsec) async {
    // Whitespace entfernen
    nsec = nsec.trim();

    // Validierung
    if (!nsec.startsWith('nsec1')) {
      throw FormatException('Ungültiges Format. Der Key muss mit "nsec1" beginnen.');
    }

    try {
      // 1. nsec → privater Schlüssel (Hex)
      final privateKeyHex = Nip19.decodePrivkey(nsec);

      // 2. Öffentlichen Schlüssel ableiten
      final keychain = Keychain(privateKeyHex);
      final npub = Nip19.encodePubkey(keychain.public);

      // 3. Lokal speichern
      await _saveKeys(
        nsec: nsec,
        npub: npub,
        privHex: privateKeyHex,
      );

      return {
        'nsec': nsec,
        'npub': npub,
        'pubHex': keychain.public,
      };
    } catch (e) {
      throw FormatException('Ungültiger nsec Key: $e');
    }
  }

  // =============================================
  // SCHLÜSSEL LADEN
  // Gibt gespeichertes Keypair zurück (oder null)
  // =============================================
  static Future<Map<String, String>?> loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final nsec = prefs.getString(_nsecKey);
    final npub = prefs.getString(_npubKey);

    if (nsec == null || npub == null) return null;

    return {
      'nsec': nsec,
      'npub': npub,
    };
  }

  // =============================================
  // HAT DER USER EINEN KEY?
  // =============================================
  static Future<bool> hasKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nsecKey) != null;
  }

  // =============================================
  // NPUB LADEN (ohne nsec preiszugeben)
  // =============================================
  static Future<String?> getNpub() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_npubKey);
  }

  // =============================================
  // DATEN SIGNIEREN
  // Erzeugt eine Schnorr-Signatur über beliebige Daten
  // =============================================
  static Future<String> sign(String data) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString(_privHexKey);

    if (privHex == null) {
      throw Exception('Kein Nostr-Schlüssel vorhanden. Bitte erst Key generieren oder importieren.');
    }

    // Wir erstellen ein Nostr-Event und nutzen dessen Signatur
    // Kind 21000 = Custom (Einundzwanzig Badge)
    final event = Event.from(
      kind: 21000,
      tags: [],
      content: data,
      privkey: privHex,
    );

    return event.sig;
  }

  // =============================================
  // SIGNATUR PRÜFEN
  // Verifiziert ob eine Signatur zu einem npub passt
  // =============================================
  static bool verify({
    required String data,
    required String signature,
    required String pubkeyHex,
  }) {
    try {
      // Wir bauen das Event nach und prüfen die Signatur
      // Das nostr-Package verifiziert intern mit BIP-340 Schnorr
      final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Event-ID nachrechnen (SHA-256 über serialisierte Daten)
      final serialized = jsonEncode([
        0,
        pubkeyHex,
        createdAt,
        21000,
        [],
        data,
      ]);
      final id = sha256.convert(utf8.encode(serialized)).toString();

      final event = Event(
        id,
        pubkeyHex,
        createdAt,
        21000,
        [],
        data,
        signature,
      );

      return event.isValid();
    } catch (e) {
      return false;
    }
  }

  // =============================================
  // BADGE SIGNIEREN
  // Erstellt eine signierte Badge-Nachricht
  // Enthält: Badge-Daten + User-npub + Signatur
  // =============================================
  static Future<Map<String, dynamic>> signBadge({
    required String meetupId,
    required String meetupName,
    required String date,
    required int blockHeight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final privHex = prefs.getString(_privHexKey);
    final npub = prefs.getString(_npubKey);

    if (privHex == null || npub == null) {
      throw Exception('Kein Nostr-Schlüssel vorhanden.');
    }

    // Badge-Daten als JSON
    final badgeData = jsonEncode({
      'meetup_id': meetupId,
      'meetup_name': meetupName,
      'date': date,
      'block_height': blockHeight,
      'npub': npub,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Mit privatem Key signieren (Nostr Event)
    final event = Event.from(
      kind: 21000, // Custom Kind für Einundzwanzig Badges
      tags: [
        ['meetup', meetupId],
        ['block', blockHeight.toString()],
      ],
      content: badgeData,
      privkey: privHex,
    );

    return {
      'event_id': event.id,
      'pubkey': event.pubkey,
      'npub': npub,
      'signature': event.sig,
      'content': badgeData,
      'created_at': event.createdAt,
    };
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  /// npub → Public Key Hex
  static String npubToHex(String npub) {
    return Nip19.decodePubkey(npub);
  }

  /// Public Key Hex → npub
  static String hexToNpub(String hex) {
    return Nip19.encodePubkey(hex);
  }

  /// nsec → Private Key Hex (VORSICHT! Nur intern verwenden)
  static String nsecToHex(String nsec) {
    return Nip19.decodePrivkey(nsec);
  }

  /// Prüft ob ein npub-String gültig ist
  static bool isValidNpub(String npub) {
    try {
      if (!npub.startsWith('npub1')) return false;
      Nip19.decodePubkey(npub);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Prüft ob ein nsec-String gültig ist
  static bool isValidNsec(String nsec) {
    try {
      if (!nsec.startsWith('nsec1')) return false;
      Nip19.decodePrivkey(nsec);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// npub kürzen für Anzeige: "npub1abc...xyz"
  static String shortenNpub(String npub, {int chars = 8}) {
    if (npub.length < chars * 2 + 5) return npub;
    return '${npub.substring(0, 4 + chars)}...${npub.substring(npub.length - chars)}';
  }

  // =============================================
  // SCHLÜSSEL LÖSCHEN (GEFÄHRLICH!)
  // =============================================
  static Future<void> deleteKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nsecKey);
    await prefs.remove(_npubKey);
    await prefs.remove(_privHexKey);
  }

  // =============================================
  // INTERNES: Keys speichern
  // =============================================
  static Future<void> _saveKeys({
    required String nsec,
    required String npub,
    required String privHex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nsecKey, nsec);
    await prefs.setString(_npubKey, npub);
    await prefs.setString(_privHexKey, privHex);
  }
}