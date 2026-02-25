// ============================================
// BADGE MODEL v4 — MIT CLAIM-BINDING
// ============================================
// Jedes Badge hat jetzt ZWEI Signaturen:
//   1. Organisator-Signatur → "Dieses Meetup fand statt"
//   2. Claim-Signatur (NEU) → "Ich war dabei"
//
// Ohne Claim-Signatur zählt ein Badge NICHT
// für die Reputation. Die Claim-Signatur bindet
// das Badge kryptographisch an den Sammler.
//
// Die Kette:
//   Organisator signiert Tag → Schnorr-Signatur (unfälschbar)
//   Teilnehmer scannt Tag → Claim-Signatur (bindet an Sammler)
//   Reputation → Nur gebundene Badges zählen
//   Verifizierer prüft → Beide Signaturen + Proof-Hash
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
  // KRYPTOGRAPHISCHER BEWEIS (Organisator)
  // =============================================
  final String sig;             // Schnorr-Signatur des Organisators (128 hex chars)
  final String sigId;           // Nostr Event-ID (SHA-256 Hash, 64 hex chars)
  final String adminPubkey;     // Hex-Pubkey des Organisators (64 hex chars)
  final int sigVersion;         // 1 = Legacy (HMAC), 2 = Nostr (Schnorr)
  final String sigContent;      // Der signierte Content (für Re-Verifikation)

  // =============================================
  // CLAIM-BINDING (NEU in v4)
  // Bindet das Badge kryptographisch an den Sammler.
  // Ohne Claim → Badge zählt nicht für Reputation.
  // =============================================
  final String claimSig;        // Schnorr-Signatur des Sammlers
  final String claimEventId;    // Nostr Event-ID des Claim-Events
  final String claimPubkey;     // Hex-Pubkey des Sammlers
  final int claimTimestamp;     // Unix-Timestamp des Claims
  final bool isRetroactive;     // true = nachträglich geclaimed (reduzierter Vertrauenswert)

  MeetupBadge({
    required this.id,
    required this.meetupName,
    required this.date,
    required this.iconPath,
    this.blockHeight = 0,
    this.signerNpub = '',
    this.meetupEventId = '',
    this.delivery = 'nfc',
    // Organisator-Beweis
    this.sig = '',
    this.sigId = '',
    this.adminPubkey = '',
    this.sigVersion = 0,
    this.sigContent = '',
    // Claim-Binding
    this.claimSig = '',
    this.claimEventId = '',
    this.claimPubkey = '',
    this.claimTimestamp = 0,
    this.isRetroactive = false,
  });

  /// Hat dieses Badge einen kryptographischen Beweis (Organisator)?
  bool get hasCryptoProof => sig.isNotEmpty && sigVersion > 0;

  /// Ist dieses Badge Nostr-signiert (v2)?
  bool get isNostrSigned => sigVersion == 2 && sig.length == 128 && adminPubkey.isNotEmpty;

  /// Hat dieses Badge ein Claim-Binding?
  bool get isClaimed => claimSig.isNotEmpty && claimPubkey.isNotEmpty;

  /// Vollständig verifizierbar: Organisator-Signatur UND Claim-Binding
  bool get isFullyBound => hasCryptoProof && isClaimed;

  /// Badge-ID für den Proof-Hash (eindeutig pro Badge)
  String get proofId {
    if (sigId.isNotEmpty) return sigId;
    if (sig.isNotEmpty) return sig.substring(0, 64);
    // Fallback: Hash über Badge-Daten
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 64);
  }

  /// Claim-Proof-ID: Kombination aus Organisator-Sig + Claim-Sig + Claim-Pubkey
  /// Für den datenschutzkonformen badge_proof_hash
  String get claimProofId {
    if (!isClaimed) return '';
    final data = '$sig|$claimSig|$claimPubkey';
    return sha256.convert(utf8.encode(data)).toString();
  }

  // =============================================
  // SERIALISIERUNG
  // =============================================

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
      // Organisator-Beweis
      'sig': sig,
      'sigId': sigId,
      'adminPubkey': adminPubkey,
      'sigVersion': sigVersion,
      'sigContent': sigContent,
      // Claim-Binding
      'claimSig': claimSig,
      'claimEventId': claimEventId,
      'claimPubkey': claimPubkey,
      'claimTimestamp': claimTimestamp,
      'isRetroactive': isRetroactive,
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
      // Organisator-Beweis (backward-compatible)
      sig: json['sig'] as String? ?? '',
      sigId: json['sigId'] as String? ?? '',
      adminPubkey: json['adminPubkey'] as String? ?? '',
      sigVersion: json['sigVersion'] as int? ?? 0,
      sigContent: json['sigContent'] as String? ?? '',
      // Claim-Binding (backward-compatible: alte Badges ohne Claim laden auch)
      claimSig: json['claimSig'] as String? ?? '',
      claimEventId: json['claimEventId'] as String? ?? '',
      claimPubkey: json['claimPubkey'] as String? ?? '',
      claimTimestamp: json['claimTimestamp'] as int? ?? 0,
      isRetroactive: json['isRetroactive'] as bool? ?? false,
    );
  }

  /// Erstellt eine Kopie des Badges MIT Claim-Daten
  MeetupBadge withClaim({
    required String claimSig,
    required String claimEventId,
    required String claimPubkey,
    required int claimTimestamp,
    bool isRetroactive = false,
  }) {
    return MeetupBadge(
      id: id,
      meetupName: meetupName,
      date: date,
      iconPath: iconPath,
      blockHeight: blockHeight,
      signerNpub: signerNpub,
      meetupEventId: meetupEventId,
      delivery: delivery,
      sig: sig,
      sigId: sigId,
      adminPubkey: adminPubkey,
      sigVersion: sigVersion,
      sigContent: sigContent,
      // Claim-Daten
      claimSig: claimSig,
      claimEventId: claimEventId,
      claimPubkey: claimPubkey,
      claimTimestamp: claimTimestamp,
      isRetroactive: isRetroactive,
    );
  }

  // =============================================
  // PERSISTENZ
  // =============================================

  static Future<void> saveBadges(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> badgesJson = badges.map((b) => jsonEncode(b.toJson())).toList();
    await prefs.setStringList('badges', badgesJson);
  }

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
  // BADGE PROOF v2: Datenschutzkonform
  // =============================================
  // Erzeugt einen Hash der beweist:
  // "Genau DIESE Badges mit genau DIESEN Claims
  //  wurden für die Reputation verwendet."
  //
  // Verrät NICHT welche Meetups oder Orte.
  // =============================================

  /// Badge-Proof-Hash über ALLE gebundenen Badges (datenschutzkonform)
  /// Nur Badges mit Claim-Binding werden einbezogen.
  static String generateBadgeProofV2(List<MeetupBadge> badges) {
    // Nur gebundene Badges zählen
    final bound = badges.where((b) => b.isFullyBound).toList();
    if (bound.isEmpty) return '';
    
    // Sortieren nach Claim-Timestamp (deterministisch)
    bound.sort((a, b) => a.claimTimestamp.compareTo(b.claimTimestamp));
    
    // Claim-Proof-IDs verketten
    final proofChain = bound.map((b) => b.claimProofId).join('|');
    
    // SHA-256 über die gesamte Kette
    return sha256.convert(utf8.encode(proofChain)).toString();
  }

  /// Legacy Badge-Proof (v1) für Rückwärtskompatibilität
  static String generateBadgeProof(List<MeetupBadge> badges) {
    if (badges.isEmpty) return '';
    
    final sorted = List<MeetupBadge>.from(badges)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    final proofChain = sorted.map((b) => b.proofId).join('|');
    return sha256.convert(utf8.encode(proofChain)).toString();
  }

  /// Prüft ob ein Badge-Proof zu einer Badge-Liste passt
  static bool verifyBadgeProof(List<MeetupBadge> badges, String expectedProof) {
    final actualProof = generateBadgeProof(badges);
    return actualProof == expectedProof;
  }

  /// Badge-Statistiken für Reputation
  static Map<String, int> getReputationStats(List<MeetupBadge> badges) {
    final bound = badges.where((b) => b.isFullyBound).toList();
    final retroactive = bound.where((b) => b.isRetroactive).length;
    return {
      'total': badges.length,
      'crypto_proof': badges.where((b) => b.hasCryptoProof).length,
      'claimed': bound.length,
      'retroactive': retroactive,
      'fully_trusted': bound.length - retroactive,
    };
  }

  /// Wie viele Badges haben einen echten kryptographischen Beweis?
  static int countVerifiedBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.hasCryptoProof).length;
  }

  /// Wie viele Badges sind vollständig gebunden?
  static int countBoundBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.isFullyBound).length;
  }

  // Badge-Reputation-String für Sharing
  String toReputationString() {
    return 'Badge #$id\n'
           'Meetup: $meetupName\n'
           'Datum: ${date.day}.${date.month}.${date.year}\n'
           'Block: $blockHeight\n'
           '${isNostrSigned ? "🔐 Nostr-verifiziert" : "Verifiziert"} bei Einundzwanzig'
           '${isClaimed ? "\n🔗 Gebunden" : ""}';
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

    final stats = getReputationStats(badges);

    final data = {
      'version': '4.0',
      'identity': identity.isNotEmpty ? identity : {'status': 'anonymous'},
      'total_badges': badges.length,
      'verified_badges': countVerifiedBadges(badges),
      'bound_badges': countBoundBadges(badges),
      'meetups_visited': badges.map((b) => b.meetupName).toSet().length,
      'unique_signers': badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet().length,
      'badge_proof': generateBadgeProof(badges),
      'badge_proof_v2': generateBadgeProofV2(badges),
      'stats': stats,
      'badges': badges.map((b) => {
        'meetup': b.meetupName,
        'date': b.date.toIso8601String(),
        'block': b.blockHeight,
        'signer_npub': b.signerNpub,
        'sig_version': b.sigVersion,
        'is_bound': b.isFullyBound,
        'is_retroactive': b.isRetroactive,
        if (b.hasCryptoProof) ...{
          'sig': b.sig,
          'sig_id': b.sigId,
          'admin_pubkey': b.adminPubkey,
        },
        if (b.isClaimed) ...{
          'claim_sig': b.claimSig,
          'claim_event_id': b.claimEventId,
          'claim_pubkey': b.claimPubkey,
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