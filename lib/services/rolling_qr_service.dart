import 'dart:convert';
import 'package:crypto/crypto.dart';

class RollingQrService {
  // Schnelles Intervall gegen Screenshots
  static const int intervalSeconds = 5; 

  String generatePayload(String meetupId, String meetupName, String country, String privKey, String pubKey, String adminNpub) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final timeStep = now ~/ intervalSeconds;
    
    // Nonce generieren (TOTP-artig)
    final nonceInput = "$meetupId$timeStep$privKey";
    final nonce = sha256.convert(utf8.encode(nonceInput)).toString().substring(0, 16);

    // Payload bauen
    final data = {
      'type': 'BADGE',
      'meetup_id': meetupId,
      'meetup_name': meetupName,
      'meetup_country': country,
      'timestamp': now,
      'block_height': 0, // Optional: Könnte man live holen
      'sig': 'placeholder_sig', // Hier würde man normal signieren
      'admin_npub': adminNpub,
      'admin_pubkey': pubKey,
      'qr_nonce': nonce,
      'qr_time_step': timeStep,
      'qr_interval': intervalSeconds,
      'delivery': 'rolling_qr' // Markiert Badge als QR-Import
    };

    return jsonEncode(data);
  }

  bool validatePayload(Map<String, dynamic> data) {
    // Prüfen ob 'qr_time_step' im erlaubten Fenster liegt (±5 Sek)
    if (!data.containsKey('qr_time_step')) return true; // Alte NFC Tags haben das nicht -> gültig

    final sentStep = data['qr_time_step'];
    final interval = data['qr_interval'] ?? 30;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final currentStep = now ~/ interval;

    // Erlaube aktuellen Schritt und den direkten Vorgänger/Nachfolger (Netzwerklatenz)
    return (sentStep >= currentStep - 1 && sentStep <= currentStep + 1);
  }
}