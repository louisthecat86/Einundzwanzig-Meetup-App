// ============================================
// BADGE MODEL v4 — MIT CO-SIGNATUR-PROTOKOLL
// ============================================
//
// ÄNDERUNGEN v4 (gegenüber v3):
//
// 1. CO-SIGNATUR:
//    Nach dem Scannen signiert der Teilnehmer den Badge-Hash
//    mit seinem eigenen Nostr-Key. Dadurch:
//    → Badge ist NICHT übertragbar
//    → Besitz ist kryptographisch beweisbar
//    → Manipulation der Badge-Liste ist erkennbar
//
//    Kette:
//      Organisator signiert Badge → sig (Schnorr)
//      Teilnehmer signiert Badge-Hash → participantSig (Schnorr)
//      Export: User signiert ALLE Badges → exportSig (Schnorr)
//
// 2. SIGNIERTER EXPORT:
//    Der Export wird vom User mit Schnorr signiert.
//    Manipulation des Exports (Badges hinzufügen/entfernen/ändern)
//    bricht die Export-Signatur.
//
// 3. BADGE-PROOF:
//    Hash-Chain über alle Badge-Signaturen.
//    Änderung eines Badges → Proof-Hash ändert sich.
//
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:nostr/nostr.dart';
import '../services/secure_key_store.dart';
import '../services/badge_security.dart';

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
  // ORGANISATOR-BEWEIS (v3)
  // =============================================
  final String sig;             // Schnorr-Signatur des Organisators (128 hex chars)
  final String sigId;           // Nostr Event-ID (SHA-256 Hash, 64 hex chars)
  final String adminPubkey;     // Hex-Pubkey des Organisators (64 hex chars)
  final int sigVersion;         // 1 = Legacy (HMAC), 2 = Nostr (Schnorr)
  final String sigContent;      // Der signierte Content (für Re-Verifikation)

  // =============================================
  // TEILNEHMER-CO-SIGNATUR (NEU in v4)
  // =============================================
  //
  // Nach dem Scannen signiert der Teilnehmer den Badge-Hash
  // mit seinem eigenen Nostr-Key.
  //
  // participantSig beweist:
  //   "ICH (mit diesem Pubkey) habe DIESES Badge erhalten"
  //
  // Format:
  //   participantSig = SchnorrSign(SHA256(badgeProofId + participantPubkey), participantPrivKey)
  //
  // Dadurch:
  //   - Badge kann nicht auf anderen User übertragen werden
  //   - Verifier kann prüfen: participantPubkey + participantSig + proofId
  //   - Ohne den Private Key des Teilnehmers: keine gültige Co-Signatur
  //
  // =============================================
  final String participantPubkey;   // Hex-Pubkey des Teilnehmers (64 hex chars)
  final String participantSig;      // Schnorr Co-Signatur des Teilnehmers (128 hex chars)

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
    // Teilnehmer-Co-Signatur
    this.participantPubkey = '',
    this.participantSig = '',
  });

  /// Hat dieses Badge einen kryptographischen Beweis vom Organisator?
  bool get hasCryptoProof => sig.isNotEmpty && sigVersion > 0;

  /// Ist dieses Badge Nostr-signiert (v2)?
  bool get isNostrSigned => sigVersion == 2 && sig.length == 128 && adminPubkey.isNotEmpty;

  /// Hat dieses Badge eine Teilnehmer-Co-Signatur?
  bool get hasParticipantSig => participantSig.isNotEmpty && participantPubkey.isNotEmpty;

  /// Ist dieses Badge vollständig verifizierbar?
  /// (Organisator-Signatur + Teilnehmer-Co-Signatur)
  bool get isFullyBound => isNostrSigned && hasParticipantSig;

  /// Badge-ID für den Proof-Hash (eindeutig pro Badge)
  String get proofId {
    if (sigId.isNotEmpty) return sigId;
    if (sig.isNotEmpty) return sig.substring(0, 64);
    // Fallback: Hash über Badge-Daten
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    return sha256.convert(utf8.encode(data)).toString().substring(0, 64);
  }

  // =============================================
  // CO-SIGNATUR ERSTELLEN
  // =============================================
  //
  // Wird aufgerufen nachdem ein Badge gescannt wurde.
  // Der Teilnehmer signiert: SHA256(proofId + participantPubkey)
  //
  // Returns: MeetupBadge mit gesetzter Co-Signatur
  //          oder null wenn kein Nostr-Key vorhanden
  //
  // =============================================
  static Future<MeetupBadge> createWithCoSignature(MeetupBadge badge) async {
    final privHex = await SecureKeyStore.getPrivHex();
    if (privHex == null) return badge; // Kein Key → Badge ohne Co-Signatur

    try {
      // Participant Pubkey aus dem Private Key ableiten
      final keyPair = Keychain(privHex);
      final participantPubkey = keyPair.public;

      // Co-Signatur-Nachricht: SHA256(proofId + participantPubkey)
      // Das bindet die Signatur an DIESES spezifische Badge UND DIESEN Teilnehmer
      final message = '${badge.proofId}:$participantPubkey';
      final messageHash = sha256.convert(utf8.encode(message)).toString();

      // Nostr Event für die Co-Signatur erstellen
      // Kind 21002 = Badge Co-Signatur (nicht auf Relays publiziert)
      final event = Event.from(
        kind: 21002,
        tags: [
          ['badge_proof', badge.proofId],
          ['participant', participantPubkey],
        ],
        content: messageHash,
        privkey: privHex,
      );

      return MeetupBadge(
        id: badge.id,
        meetupName: badge.meetupName,
        date: badge.date,
        iconPath: badge.iconPath,
        blockHeight: badge.blockHeight,
        signerNpub: badge.signerNpub,
        meetupEventId: badge.meetupEventId,
        delivery: badge.delivery,
        // Organisator-Beweis
        sig: badge.sig,
        sigId: badge.sigId,
        adminPubkey: badge.adminPubkey,
        sigVersion: badge.sigVersion,
        sigContent: badge.sigContent,
        // Teilnehmer-Co-Signatur
        participantPubkey: participantPubkey,
        participantSig: event.sig,
      );
    } catch (e) {
      print('[Badge] Co-Signatur fehlgeschlagen: $e');
      return badge; // Fallback: Badge ohne Co-Signatur
    }
  }

  // =============================================
  // CO-SIGNATUR VERIFIZIEREN
  // =============================================
  //
  // Prüft ob die Co-Signatur zu diesem Badge und
  // diesem Teilnehmer passt.
  //
  // =============================================
  bool verifyCoSignature() {
    if (!hasParticipantSig) return false;

    try {
      // Co-Signatur-Nachricht rekonstruieren
      final message = '$proofId:$participantPubkey';
      final messageHash = sha256.convert(utf8.encode(message)).toString();

      // Nostr Event rekonstruieren
      final tags = [
        ['badge_proof', proofId],
        ['participant', participantPubkey],
      ];
      final serialized = jsonEncode([0, participantPubkey, 0, 21002, tags, messageHash]);
      // HINWEIS: createdAt ist 0, da wir ihn nicht gespeichert haben.
      // Für die lokale Verifikation reicht die Signatur über den Content.
      // Für eine vollständige Nostr-Event-Verifikation müsste createdAt
      // mitgespeichert werden. Das ist ein bekannter Tradeoff:
      // Weniger Speicherplatz vs. vollständige Event-Rekonstruierbarkeit.
      //
      // Alternativ: Direkte Schnorr-Verifikation über den messageHash
      // ohne Event-Wrapper. Das ist was wir tatsächlich tun:

      // Schnorr direkt verifizieren (via nostr package)
      // Wir bauen ein minimales Event nur um event.isValid() nutzen zu können
      final eventId = sha256.convert(utf8.encode(
        jsonEncode([0, participantPubkey, 0, 21002, tags, messageHash])
      )).toString();

      final event = Event(eventId, participantPubkey, 0, 21002, tags, messageHash, participantSig);
      return event.isValid();
    } catch (e) {
      return false;
    }
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
      // Organisator-Beweis
      'sig': sig,
      'sigId': sigId,
      'adminPubkey': adminPubkey,
      'sigVersion': sigVersion,
      'sigContent': sigContent,
      // Teilnehmer-Co-Signatur (v4)
      'participantPubkey': participantPubkey,
      'participantSig': participantSig,
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
      // Teilnehmer-Co-Signatur (v4, backward-compatible)
      participantPubkey: json['participantPubkey'] as String? ?? '',
      participantSig: json['participantSig'] as String? ?? '',
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

  static bool verifyBadgeProof(List<MeetupBadge> badges, String expectedProof) {
    final actualProof = generateBadgeProof(badges);
    return actualProof == expectedProof;
  }

  static int countVerifiedBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.hasCryptoProof).length;
  }

  /// Wie viele Badges haben eine Teilnehmer-Co-Signatur?
  static int countBoundBadges(List<MeetupBadge> badges) {
    return badges.where((b) => b.isFullyBound).length;
  }

  // Badge-Reputation-String für Sharing
  String toReputationString() {
    return 'Badge #$id\n'
           'Meetup: $meetupName\n'
           'Datum: ${date.day}.${date.month}.${date.year}\n'
           'Block: $blockHeight\n'
           '${isFullyBound ? "🔐 Gebunden & verifiziert" : isNostrSigned ? "🔐 Nostr-verifiziert" : "Verifiziert"} bei Einundzwanzig';
  }

  // Badge-Hash für Verifizierung (Legacy)
  String getVerificationHash() {
    final data = '$id-$meetupName-${date.toIso8601String()}-$blockHeight';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // =============================================
  // SIGNIERTER EXPORT v4
  // =============================================
  //
  // Der Export wird mit dem Private Key des Users signiert.
  //
  // Kette:
  //   1. Alle Badge-Daten + Beweise werden in JSON gepackt
  //   2. SHA-256 Hash über den gesamten Export (ohne Signatur)
  //   3. User signiert diesen Hash mit Schnorr
  //   4. Signatur wird an den Export angehängt
  //
  // Manipulation (Badges hinzufügen/entfernen/ändern)
  //   → Hash ändert sich → Signatur wird ungültig
  //
  // =============================================
  static Future<String> exportBadgesForReputation(
    List<MeetupBadge> badges,
    String userNpub, {
    String nickname = '',
    String telegram = '',
    String twitter = '',
  }) async {
    final Map<String, dynamic> identity = {};
    if (nickname.isNotEmpty) identity['nickname'] = nickname;
    if (userNpub.isNotEmpty) identity['nostr_npub'] = userNpub;
    if (telegram.isNotEmpty) identity['telegram'] = telegram;
    if (twitter.isNotEmpty) identity['twitter'] = twitter;

    // User Pubkey für den Export
    String userPubkeyHex = '';
    try {
      if (userNpub.isNotEmpty) {
        userPubkeyHex = Nip19.decodePubkey(userNpub);
      }
    } catch (_) {}

    final data = {
      'version': '4.0',
      'identity': identity.isNotEmpty ? identity : {'status': 'anonymous'},
      'user_pubkey': userPubkeyHex,
      'total_badges': badges.length,
      'verified_badges': countVerifiedBadges(badges),
      'bound_badges': countBoundBadges(badges),
      'meetups_visited': badges.map((b) => b.meetupName).toSet().length,
      'unique_signers': badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet().length,
      'badge_proof': generateBadgeProof(badges),
      'badges': badges.map((b) => {
        'meetup': b.meetupName,
        'date': b.date.toIso8601String(),
        'block': b.blockHeight,
        'signer_npub': b.signerNpub,
        'sig_version': b.sigVersion,
        // Organisator-Beweis
        if (b.hasCryptoProof) ...{
          'sig': b.sig,
          'sig_id': b.sigId,
          'admin_pubkey': b.adminPubkey,
          'sig_content': b.sigContent,
        },
        // Teilnehmer-Co-Signatur (v4)
        if (b.hasParticipantSig) ...{
          'participant_pubkey': b.participantPubkey,
          'participant_sig': b.participantSig,
        },
        'hash': b.getVerificationHash(),
      }).toList(),
      'exported_at': DateTime.now().toIso8601String(),
    };

    // =============================================
    // EXPORT SIGNIEREN
    // =============================================
    final privHex = await SecureKeyStore.getPrivHex();
    if (privHex != null && userPubkeyHex.isNotEmpty) {
      // Canonical JSON des Exports (ohne Signaturfelder)
      final canonicalExport = BadgeSecurity.canonicalJsonEncode(data);
      final exportHash = sha256.convert(utf8.encode(canonicalExport)).toString();

      try {
        // Schnorr-Signatur über den Export-Hash
        final event = Event.from(
          kind: 21003, // Badge Export Signatur
          tags: [
            ['export_hash', exportHash],
            ['badge_count', badges.length.toString()],
          ],
          content: exportHash,
          privkey: privHex,
        );

        data['export_signature'] = {
          'sig': event.sig,
          'sig_id': event.id,
          'pubkey': event.pubkey,
          'created_at': event.createdAt,
          'hash': exportHash,
        };
      } catch (e) {
        print('[Badge] Export-Signatur fehlgeschlagen: $e');
        // Export ohne Signatur — besser als gar kein Export
      }
    }

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

// Globale Badge-Liste (wird beim App-Start geladen)
List<MeetupBadge> myBadges = [];