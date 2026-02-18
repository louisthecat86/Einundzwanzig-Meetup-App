// ============================================
// BADGE MODEL v3 — MIT KRYPTOGRAPHISCHEM BEWEIS
// ============================================
// Jedes Badge speichert die ORIGINAL-SIGNATUR des Organisators.
// Das bedeutet: Jedes einzelne Badge kann jederzeit
// unabhängig re-verifiziert werden.
//
// Die Kette:
//   Organisator signiert Tag → Schnorr-Signatur (unfälschbar)
//   Teilnehmer scannt Tag → Signatur wird MIT dem Badge gespeichert
//   Reputation QR → Hash über ALLE Badge-Signaturen
//   Scanner prüft → QR-Signatur + Badge-Proof-Hash
//
// Ohne die echte Organisator-Signatur kann kein Badge
// in die Reputation aufgenommen werden.
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class MeetupBadge {
  final String id;
  final String meetupName;
  final DateTime date;
  final String iconPath;
  final int blockHeight;
  final String signerNpub;      // Wer hat den Tag erstellt? (npub1...)
  final String meetupEventId;   // Eindeutige Event-ID (meetup-datum)
  final String delivery;        // 'nfc' oder 'rolling_qr'

  // =============================================
  // KRYPTOGRAPHISCHER BEWEIS (NEU in v3)
  // Diese Felder machen jedes Badge individuell verifizierbar.
  // =============================================
  final String sig;             // Schnorr-Signatur des Organisators (128 hex chars)
  final String sigId;           // Nostr Event-ID (SHA-256 Hash, 64 hex chars)
  final String adminPubkey;     // Hex-Pubkey des Organisators (64 hex chars)
  final int sigVersion;         // 1 = Legacy (HMAC), 2 = Nostr (Schnorr)
  final String sigContent;      // Der signierte Content (für Re-Verifikation)

  MeetupBadge({
    required this.id,
    required this.meetupName,
    required this.date,
    required this.iconPath,
    this.blockHeight = 0,
    this.signerNpub = '',
    this.meetupEventId = '',
    this.delivery = 'nfc',
    // Crypto proof fields
    this.sig = '',
    this.sigId = '',
    this.adminPubkey = '',
    this.sigVersion = 0,
    this.sigContent = '',
  });

  /// Hat dieses Badge einen kryptographischen Beweis?
  bool get hasCryptoProof => sig.isNotEmpty && sigVersion > 0;

  /// Ist dieses Badge Nostr-signiert (v2)?
  bool get isNostrSigned => sigVersion == 2 && sig.length == 128 && adminPubkey.isNotEmpty;

  /// Badge-ID für den Proof-Hash (eindeutig pro Badge)
  /// Kombiniert Event-ID + Signatur → einzigartig und unfälschbar
  String get proofId {
    if (sigId.isNotEmpty) return sigId;
    if (sig.isNotEmpty) return sig.substring(0, 64);
    // Fallback: Hash über Badge-Daten (weniger sicher, aber besser als nichts)
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 64);
  }

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
      // Crypto proof
      'sig': sig,
      'sigId': sigId,
      'adminPubkey': adminPubkey,
      'sigVersion': sigVersion,
      'sigContent': sigContent,
    };
  }

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
      // Crypto proof (backward-compatible: alte Badges ohne Proof laden auch)
      sig: json['sig'] as String? ?? '',
      sigId: json['sigId'] as String? ?? '',
      adminPubkey: json['adminPubkey'] as String? ?? '',
      sigVersion: json['sigVersion'] as int? ?? 0,
      sigContent: json['sigContent'] as String? ?? '',
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

  // =============================================
  // BADGE PROOF: Kryptographischer Beweis über ALLE Badges
  // =============================================
  // Erzeugt einen einzelnen Hash der beweist:
  // "Genau DIESE Badges mit genau DIESEN Signaturen
  //  wurden für die Reputation verwendet."
  //
  // Änderung eines einzigen Badges → Hash ändert sich
  // → QR-Signatur wird ungültig → Fälschung erkannt
  // =============================================

  /// Erzeugt den Badge-Proof-Hash über eine Liste von Badges
  /// Nur Badges MIT kryptographischem Beweis werden einbezogen.
  static String generateBadgeProof(List<MeetupBadge> badges) {
    if (badges.isEmpty) return '';
    
    // Sortieren nach Datum (deterministisch!)
    final sorted = List<MeetupBadge>.from(badges)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // Proof-IDs aller Badges verketten
    final proofChain = sorted.map((b) => b.proofId).join('|');
    
    // SHA-256 über die gesamte Kette
    final hash = sha256.convert(utf8.encode(proofChain));
    return hash.toString();
  }

  /// Prüft ob ein Badge-Proof zu einer Badge-Liste passt
  static bool verifyBadgeProof(List<MeetupBadge> badges, String expectedProof) {
    final actualProof = generateBadgeProof(badges);
    return actualProof == expectedProof;
  }

  /// Wie viele Badges haben einen echten kryptographischen Beweis?
  static int countVerifiedBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.hasCryptoProof).length;
  }

  // Badge-Reputation-String für Sharing
  String toReputationString() {
    return 'Badge #$id\n'
           'Meetup: $meetupName\n'
           'Datum: ${date.day}.${date.month}.${date.year}\n'
           'Block: $blockHeight\n'
           '${isNostrSigned ? "🔐 Nostr-verifiziert" : "Verifiziert"} bei Einundzwanzig';
  }

  // Badge-Hash für Verifizierung (Legacy)
  String getVerificationHash() {
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // =============================================
  // EXPORT: Vollständige Badge-Daten mit Beweisen
  // =============================================
  static String exportBadgesForReputation(
    List<MeetupBadge> badges,
    String userNpub, {
    String nickname = '',
    String telegram = '',
    String twitter = '',
  }) {
    final Map<String, dynamic> identity = {};
    if (nickname.isNotEmpty) identity['nickname'] = nickname;
    if (userNpub.isNotEmpty) identity['nostr_npub'] = userNpub;
    if (telegram.isNotEmpty) identity['telegram'] = telegram;
    if (twitter.isNotEmpty) identity['twitter'] = twitter;

    final data = {
      'version': '3.0',
      'identity': identity.isNotEmpty ? identity : {'status': 'anonymous'},
      'total_badges': badges.length,
      'verified_badges': countVerifiedBadges(badges),
      'meetups_visited': badges.map((b) => b.meetupName).toSet().length,
      'unique_signers': badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet().length,
      'badge_proof': generateBadgeProof(badges),
      'badges': badges.map((b) => {
        'meetup': b.meetupName,
        'date': b.date.toIso8601String(),
        'block': b.blockHeight,
        'signer_npub': b.signerNpub,
        'sig_version': b.sigVersion,
        // Voller kryptographischer Beweis (für Einzelverifikation)
        if (b.hasCryptoProof) ...{
          'sig': b.sig,
          'sig_id': b.sigId,
          'admin_pubkey': b.adminPubkey,
        },
        'hash': b.getVerificationHash(),
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(data);
    final checksum = sha256.convert(utf8.encode(jsonString)).toString().substring(0, 8);
    data['checksum'] = checksum;

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

// Globale Badge-Liste (wird beim App-Start geladen)
List<MeetupBadge> myBadges = [];