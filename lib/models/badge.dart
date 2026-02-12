import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class MeetupBadge {
  final String id;
  final String meetupName;
  final DateTime date;
  final String iconPath;
  final int blockHeight;
  final String signerNpub;      // NEU: Wer hat den Tag erstellt?
  final String meetupEventId;   // NEU: Eindeutige Event-ID (meetup-datum)
  final String delivery;        // NEU: 'nfc' oder 'rolling_qr'

  MeetupBadge({
    required this.id,
    required this.meetupName,
    required this.date,
    required this.iconPath,
    this.blockHeight = 0,
    this.signerNpub = '',
    this.meetupEventId = '',
    this.delivery = 'nfc',
  });

  // Serialisierung
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetupName': meetupName,
      'date': date.toIso8601String(),
      'iconPath': iconPath,
      'blockHeight': blockHeight,
      'signerNpub': signerNpub,
      'meetupEventId': meetupEventId,
      'delivery': delivery,
    };
  }

  // Deserialisierung
  factory MeetupBadge.fromJson(Map<String, dynamic> json) {
    return MeetupBadge(
      id: json['id'] as String,
      meetupName: json['meetupName'] as String,
      date: DateTime.parse(json['date'] as String),
      iconPath: json['iconPath'] as String,
      blockHeight: json['blockHeight'] as int? ?? 0,
      signerNpub: json['signerNpub'] as String? ?? '',
      meetupEventId: json['meetupEventId'] as String? ?? '',
      delivery: json['delivery'] as String? ?? 'nfc',
    );
  }

  // Badges speichern
  static Future<void> saveBadges(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> badgesJson = badges.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('badges', badgesJson);
  }

  // Badges laden
  static Future<List<MeetupBadge>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? badgesJson = prefs.getStringList('badges');
    
    if (badgesJson == null || badgesJson.isEmpty) {
      return [];
    }
    
    return badgesJson.map((String json) {
      return MeetupBadge.fromJson(jsonDecode(json) as Map<String, dynamic>);
    }).toList();
  }

  // Badge-Reputation-String für Sharing
  String toReputationString() {
    return 'Badge #${id}\n'
           'Meetup: $meetupName\n'
           'Datum: ${date.day}.${date.month}.${date.year}\n'
           'Block: $blockHeight\n'
           'Verifiziert bei Einundzwanzig';
  }

  // Badge-Hash für Verifizierung
  String getVerificationHash() {
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Kurzer Hash
  }

  // Exportiert alle Badges als verifizierbares JSON
  static String exportBadgesForReputation(
    List<MeetupBadge> badges,
    String userNpub, {
    String nickname = '',
    String telegram = '',
    String twitter = '',
  }) {
    // Identitäts-Block: Alle verknüpften Accounts
    final Map<String, dynamic> identity = {};
    if (nickname.isNotEmpty) identity['nickname'] = nickname;
    if (userNpub.isNotEmpty) identity['nostr_npub'] = userNpub;
    if (telegram.isNotEmpty) identity['telegram'] = telegram;
    if (twitter.isNotEmpty) identity['twitter'] = twitter;

    final data = {
      'version': '2.0',
      'identity': identity.isNotEmpty ? identity : {'status': 'anonymous'},
      'total_badges': badges.length,
      'meetups_visited': badges.map((b) => b.meetupName).toSet().length,
      'badges': badges.map((b) => {
        'meetup': b.meetupName,
        'date': b.date.toIso8601String(),
        'block': b.blockHeight,
        'hash': b.getVerificationHash(),
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    // Checksum über Identität + Badges (nicht nur Badges!)
    final jsonString = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(jsonString)).toString().substring(0, 8);

    data['checksum'] = checksum;

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

// Globale Badge-Liste (wird beim App-Start geladen)
List<MeetupBadge> myBadges = [];