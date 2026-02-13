import 'dart:convert';

class MeetupBadge {
  final String meetupId;
  final String meetupName;
  final String meetupCountry;
  final int timestamp;
  final int blockHeight;
  final String signature;
  
  // Neue Felder für Trust Score & Validierung
  final String? signerNpub;      // Wer hat den Tag erstellt?
  final String? meetupEventId;   // ID des Nostr-Events (für Co-Attestations)
  final String? delivery;        // 'nfc' oder 'rolling_qr'

  MeetupBadge({
    required this.meetupId,
    required this.meetupName,
    required this.meetupCountry,
    required this.timestamp,
    required this.blockHeight,
    required this.signature,
    this.signerNpub,
    this.meetupEventId,
    this.delivery,
  });

  Map<String, dynamic> toJson() {
    return {
      'meetupId': meetupId,
      'meetupName': meetupName,
      'meetupCountry': meetupCountry,
      'timestamp': timestamp,
      'blockHeight': blockHeight,
      'signature': signature,
      if (signerNpub != null) 'signerNpub': signerNpub,
      if (meetupEventId != null) 'meetupEventId': meetupEventId,
      if (delivery != null) 'delivery': delivery,
    };
  }

  factory MeetupBadge.fromJson(Map<String, dynamic> json) {
    return MeetupBadge(
      meetupId: json['meetupId'] ?? '',
      meetupName: json['meetupName'] ?? '',
      meetupCountry: json['meetupCountry'] ?? '',
      timestamp: json['timestamp'] ?? 0,
      blockHeight: json['blockHeight'] ?? 0,
      signature: json['signature'] ?? '',
      signerNpub: json['signerNpub'],
      meetupEventId: json['meetupEventId'],
      delivery: json['delivery'],
    );
  }
}