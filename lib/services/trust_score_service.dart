import '../models/user.dart';
import '../models/badge.dart';
import 'nostr_service.dart'; // Für Co-Attestor Daten Struktur

class TrustConfig {
  // Adaptive Phasen-Definitionen
  static const int phase1Signers = 1; // Keimphase: Nur 1 Signer nötig (du selbst)
  static const int phase2Signers = 3; // Wachstumsphase
  static const int phase3Signers = 6; // Stabile Phase

  // Basis-Werte
  static const double basePromotionThreshold = 15.0;
  static const int minBadges = 3;
  static const int minMeetups = 2;
}

class TrustScore {
  final double score;
  final int uniqueMeetups;
  final int uniqueSigners;
  final int accountAgeDays;
  final bool meetsPromotionThreshold;
  final double activeThreshold; // Welcher Threshold gilt gerade?
  final String phaseLabel;      // "Keimphase", "Wachstum", "Stabil"

  TrustScore({
    required this.score,
    required this.uniqueMeetups,
    required this.uniqueSigners,
    required this.accountAgeDays,
    required this.meetsPromotionThreshold,
    required this.activeThreshold,
    required this.phaseLabel,
  });
}

class CoAttestorData {
  final String meetupEventId;
  final int attendeeCount;
  final List<String> attendeeNpubs;
  final int veteranCount;

  CoAttestorData({
    required this.meetupEventId,
    required this.attendeeCount,
    required this.attendeeNpubs,
    required this.veteranCount,
  });
}

class TrustScoreService {
  static final TrustScoreService _instance = TrustScoreService._internal();
  factory TrustScoreService() => _instance;
  TrustScoreService._internal();

  Future<TrustScore> calculateScore(UserProfile user, [Map<String, CoAttestorData>? coAttestorMap]) async {
    if (user.badges.isEmpty) {
      return TrustScore(
        score: 0.0, uniqueMeetups: 0, uniqueSigners: 0, accountAgeDays: 0, 
        meetsPromotionThreshold: false, activeThreshold: 5.0, phaseLabel: "Keimphase"
      );
    }

    // 1. Metriken berechnen
    final uniqueMeetups = user.badges.map((b) => b.meetupId).toSet().length;
    final uniqueSigners = user.badges.map((b) => b.signerNpub).where((s) => s != null).toSet().length;
    
    // Alter des ältesten Badges
    user.badges.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldestTs = user.badges.first.timestamp;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final accountAgeDays = (now - oldestTs) ~/ 86400;

    // 2. Score Summierung
    double totalScore = 0.0;
    for (var badge in user.badges) {
      double badgeValue = 1.0; // Basiswert

      // Co-Attestor Bonus (wenn Daten da sind)
      if (coAttestorMap != null && badge.signature != null && coAttestorMap.containsKey(badge.signature)) {
        final data = coAttestorMap[badge.signature]!;
        // Logarithmischer Netzwerkeffekt: Mehr Teilnehmer = mehr Wert
        if (data.attendeeCount > 1) {
           badgeValue += (data.attendeeCount / 5.0); 
        }
        // Veteranen-Bonus
        if (data.veteranCount > 0) {
           badgeValue += (data.veteranCount * 0.5);
        }
      }
      totalScore += badgeValue;
    }

    // Multiplikatoren für Diversität
    if (uniqueMeetups > 2) totalScore *= 1.2;
    if (uniqueSigners > 2) totalScore *= 1.5;

    // 3. Adaptive Phase bestimmen (Bootstrap-Logik)
    // Wir schauen, wie "reif" das Netzwerk aus Sicht des Users ist
    int requiredSigners;
    double promoThreshold;
    String phase;
    int minDays;

    if (uniqueSigners <= TrustConfig.phase1Signers) {
      // Phase 1: Keimphase (Am Anfang gibt es nur dich als Admin)
      requiredSigners = 1; 
      promoThreshold = 5.0; // Niedrige Hürde
      minDays = 14;         // Schnell aufsteigen
      phase = "Keimphase";
    } else if (uniqueSigners <= TrustConfig.phase2Signers) {
      // Phase 2: Wachstum
      requiredSigners = 2;
      promoThreshold = 10.0;
      minDays = 30;
      phase = "Wachstum";
    } else {
      // Phase 3: Stabil
      requiredSigners = 3;
      promoThreshold = TrustConfig.basePromotionThreshold;
      minDays = 60;
      phase = "Stabil";
    }

    // 4. Prüfung
    bool promoted = false;
    if (totalScore >= promoThreshold && 
        user.badges.length >= TrustConfig.minBadges &&
        uniqueMeetups >= TrustConfig.minMeetups &&
        uniqueSigners >= requiredSigners &&
        accountAgeDays >= minDays) {
      promoted = true;
    }

    return TrustScore(
      score: totalScore,
      uniqueMeetups: uniqueMeetups,
      uniqueSigners: uniqueSigners,
      accountAgeDays: accountAgeDays,
      meetsPromotionThreshold: promoted,
      activeThreshold: promoThreshold,
      phaseLabel: phase,
    );
  }
}