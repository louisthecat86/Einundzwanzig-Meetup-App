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
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../services/app_logger.dart';

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
  bool get isNostrSigned {
  final hex128 = RegExp(r'^[0-9a-fA-F]{128}$');
  final hex64 = RegExp(r'^[0-9a-fA-F]{64}$');

  if (sigVersion != 2) return false;

  if (!hex128.hasMatch(sig)) return false;
  if (!hex64.hasMatch(adminPubkey)) return false;

  // zusätzliche Sicherheitsprüfung:
  // keine reine Null- oder Dummy-Signatur akzeptieren
  if (BigInt.parse(sig, radix: 16) == BigInt.zero) return false;

  return true;
}

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
  // PERSISTENZ — Verschlüsselt (Security Audit M7)
  // =============================================
  // Badge-Daten werden mit AES-256-GCM verschlüsselt,
  // bevor sie in SharedPreferences geschrieben werden.
  // Der Schlüssel liegt in flutter_secure_storage
  // (Android Keystore / iOS Keychain geschützt).
  //
  // Migration: Beim ersten Laden werden unverschlüsselte
  // Legacy-Badges automatisch verschlüsselt gespeichert.
  // =============================================

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  static const String _badgeKeyAlias = 'badge_encryption_key';
  static const String _prefsBadgeEncrypted = 'badges_encrypted';
  static const String _prefsLegacyBadges = 'badges'; // Altes Klartext-Feld

  /// AES-256-Schlüssel aus SecureStorage laden oder erzeugen
  static Future<enc.Key> _getBadgeKey() async {
    final existing = await _secureStorage.read(key: _badgeKeyAlias);
    if (existing != null && existing.length == 64) {
      // Hex-encoded 32-byte key
      return enc.Key(Uint8List.fromList(
        List.generate(32, (i) => int.parse(existing.substring(i * 2, i * 2 + 2), radix: 16)),
      ));
    }
    // Neuen Schlüssel generieren (256 Bit)
    final key = enc.Key.fromSecureRandom(32);
    final keyHex = key.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secureStorage.write(key: _badgeKeyAlias, value: keyHex);
    AppLogger.debug('Badge', 'Neuer Badge-Encryption-Key generiert');
    return key;
  }

  static Future<void> saveBadges(List<MeetupBadge> badges) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(badges.map((b) => b.toJson()).toList());

    try {
      final key = await _getBadgeKey();
      final iv = enc.IV.fromSecureRandom(12); // 96 Bit (NIST-empfohlen)
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(jsonStr, iv: iv);

      // Format: base64(IV):base64(ciphertext)
      final stored = '${iv.base64}:${encrypted.base64}';
      await prefs.setString(_prefsBadgeEncrypted, stored);

      // Legacy-Klartext entfernen falls vorhanden
      if (prefs.containsKey(_prefsLegacyBadges)) {
        await prefs.remove(_prefsLegacyBadges);
        AppLogger.debug('Badge', 'Legacy-Klartextbadges aus SharedPrefs entfernt');
      }
    } catch (e) {
      // Fallback: Klartext (sollte nicht passieren, aber App darf nicht crashen)
      AppLogger.error('Badge', 'Verschlüsselung fehlgeschlagen, Klartext-Fallback: $e');
      final List<String> badgesJson = badges.map((b) => jsonEncode(b.toJson())).toList();
      await prefs.setStringList(_prefsLegacyBadges, badgesJson);
    }
  }

  static Future<List<MeetupBadge>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Verschlüsselte Badges versuchen
    final encryptedData = prefs.getString(_prefsBadgeEncrypted);
    if (encryptedData != null && encryptedData.contains(':')) {
      try {
        final parts = encryptedData.split(':');
        if (parts.length == 2) {
          final iv = enc.IV.fromBase64(parts[0]);
          final key = await _getBadgeKey();
          final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
          final decrypted = encrypter.decrypt64(parts[1], iv: iv);
          final List<dynamic> decoded = jsonDecode(decrypted) as List<dynamic>;
          return decoded.map((json) =>
            MeetupBadge.fromJson(json as Map<String, dynamic>)
          ).toList();
        }
      } catch (e) {
        AppLogger.error('Badge', 'Entschlüsselung fehlgeschlagen: $e');
        // Weiter mit Legacy-Versuch
      }
    }

    // 2. Legacy-Klartext migrieren
    final List<String>? legacyJson = prefs.getStringList(_prefsLegacyBadges);
    if (legacyJson != null && legacyJson.isNotEmpty) {
      AppLogger.debug('Badge', 'Migriere ${legacyJson.length} Badges von Klartext zu verschlüsselt');
      final badges = legacyJson.map((String json) =>
        MeetupBadge.fromJson(jsonDecode(json) as Map<String, dynamic>)
      ).toList();

      // Sofort verschlüsselt speichern (Migration)
      await saveBadges(badges);
      return badges;
    }

    return [];
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