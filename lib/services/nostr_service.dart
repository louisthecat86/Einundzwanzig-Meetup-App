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
//
// SICHERHEIT:
// - Alle privaten Schlüssel werden über SecureKeyStore
//   gespeichert (Android Keystore / iOS Keychain).
// - Keine Klartextspeicherung in SharedPreferences.
// ============================================

import 'package:nostr/nostr.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'secure_key_store.dart';

class NostrService {

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

    // 3. Sicher speichern (SecureKeyStore → Android Keystore / iOS Keychain)
    await SecureKeyStore.saveKeys(
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

      // 3. Sicher speichern
      await SecureKeyStore.saveKeys(
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
    return await SecureKeyStore.loadKeys();
  }

  // =============================================
  // HAT DER USER EINEN KEY?
  // =============================================
  static Future<bool> hasKey() async {
    return await SecureKeyStore.hasKey();
  }

  // =============================================
  // NPUB LADEN (ohne nsec preiszugeben)
  // =============================================
  static Future<String?> getNpub() async {
    return await SecureKeyStore.getNpub();
  }

  // =============================================
  // DATEN SIGNIEREN
  // Erzeugt eine Schnorr-Signatur über beliebige Daten
  // =============================================
  static Future<String> sign(String data) async {
    final privHex = await SecureKeyStore.getPrivHex();

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
  // Verifiziert ob eine Signatur zu einem pubkey passt
  //
  // WICHTIG: createdAt und eventId müssen vom
  // Original-Event übernommen werden, NICHT neu
  // generiert — sonst stimmt der Hash nicht!
  // =============================================
  static bool verify({
    required String data,
    required String signature,
    required String pubkeyHex,
    required String eventId,
    required int createdAt,
    List<List<String>> tags = const [],
    int kind = 21000,
  }) {
    try {
      final event = Event(
        eventId,
        pubkeyHex,
        createdAt,
        kind,
        tags,
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
    final privHex = await SecureKeyStore.getPrivHex();
    final npub = await SecureKeyStore.getNpub();

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
    await SecureKeyStore.deleteKeys();
  }
}