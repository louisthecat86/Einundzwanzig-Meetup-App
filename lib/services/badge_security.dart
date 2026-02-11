import 'dart:convert';
import 'package:crypto/crypto.dart';

class BadgeSecurity {
  // Dieser Key ist das "Geheimnis" der App. 
  // Wer den Code nicht dekompiliert, kann keine Badges fälschen.
  static const String _appSecret = "einundzwanzig_community_secret_21_btc_rocks";

  /// Erstellt eine Signatur für die Daten
  static String sign(String meetupId, String timestamp, int blockHeight) {
    final data = "$meetupId|$timestamp|$blockHeight|$_appSecret";
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Prüft, ob ein Tag manipuliert wurde
  static bool verify(Map<String, dynamic> data) {
    try {
      final String id = data['meetup_id'] ?? 'global';
      final String ts = data['timestamp'] ?? '';
      final int bh = data['block_height'] ?? 0;
      final String signature = data['sig'] ?? '';

      // Wir berechnen, was die Signatur sein MÜSSTE
      final calculatedSignature = sign(id, ts, bh);

      // Stimmt sie mit dem Tag überein?
      return signature == calculatedSignature;
    } catch (e) {
      return false; // Bei Fehler (z.B. fehlende Daten) immer ablehnen
    }
  }
}