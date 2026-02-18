// ============================================
// TRUST SCORE SERVICE v3 — DEZENTRALE PROMOTION
// ============================================
//
// Das Herz des Web-of-Trust:
//
//   1. BOOTSTRAP-PHASEN: Schwellenwerte passen sich der
//      Netzwerkgröße an. Am Anfang (1 Signer) reichen
//      wenige Badges. Später (6+ Signer) braucht man mehr.
//
//   2. MEETUP-WERT: Ein Badge von einem gut besuchten
//      Meetup mit vielen Veteranen ist MEHR wert als
//      ein Badge von einem Treffen mit 2 Unbekannten.
//
//   3. AUTO-PROMOTION: Wer den Schwellenwert erreicht,
//      wird automatisch zum Organisator. Keine zentrale
//      Instanz nötig.
//
//   4. SYBIL-SCHUTZ: Du brauchst Badges von VERSCHIEDENEN
//      Signern, aus VERSCHIEDENEN Städten, über ZEIT verteilt.
//      Das kann man nicht faken ohne physisch dort zu sein.
//
// Alles lokal berechnet. Verschiedene Apps können
// verschiedene Gewichtungen haben. Das ist gewollt —
// es gibt keinen "richtigen" Score, nur Konsens.
// ============================================

import 'dart:math';
import '../models/badge.dart';

// =============================================
// BOOTSTRAP-PHASEN
// =============================================
// Das Netzwerk startet mit 1 Person (dem Gründer).
// Am Anfang müssen die Schwellen niedrig sein,
// sonst kann niemand jemals aufsteigen.
// Sobald mehr Signer aktiv sind, steigen die Anforderungen.
// =============================================

enum BootstrapPhase {
  keimphase,  // 1 einziger Signer im Netzwerk
  wachstum,   // 2-5 aktive Signer
  stabil,     // 6+ aktive Signer → Vollbetrieb
}

class PhaseThresholds {
  final String name;
  final String emoji;
  final int minBadges;
  final int minUniqueMeetups;
  final int minUniqueSigners;
  final int minAccountAgeDays;
  final double promotionScore;

  const PhaseThresholds({
    required this.name,
    required this.emoji,
    required this.minBadges,
    required this.minUniqueMeetups,
    required this.minUniqueSigners,
    required this.minAccountAgeDays,
    required this.promotionScore,
  });
}

// =============================================
// KONFIGURATION
// =============================================
class TrustConfig {
  // --- BOOTSTRAP-PHASEN ---
  static const Map<BootstrapPhase, PhaseThresholds> phases = {
    BootstrapPhase.keimphase: PhaseThresholds(
      name: 'Keimphase',
      emoji: '🌱',
      minBadges: 3,
      minUniqueMeetups: 2,
      minUniqueSigners: 1,      // Nur DU als Signer → 1 reicht
      minAccountAgeDays: 14,    // 2 Wochen
      promotionScore: 5.0,
    ),
    BootstrapPhase.wachstum: PhaseThresholds(
      name: 'Wachstum',
      emoji: '🌿',
      minBadges: 4,
      minUniqueMeetups: 3,
      minUniqueSigners: 2,      // Mindestens 2 verschiedene Signer
      minAccountAgeDays: 30,    // 1 Monat
      promotionScore: 10.0,
    ),
    BootstrapPhase.stabil: PhaseThresholds(
      name: 'Stabil',
      emoji: '🌳',
      minBadges: 5,
      minUniqueMeetups: 3,
      minUniqueSigners: 2,
      minAccountAgeDays: 60,    // 2 Monate
      promotionScore: 15.0,
    ),
  };

  // --- SCORING GEWICHTUNG ---
  static const double weightDiversity = 1.5;
  static const double weightMaturity = 1.0;
  static const double weightDecay = 1.0;
  static const double weightQuality = 1.2;

  // Time Decay: Halbwertszeit in Wochen
  static const double halfLifeWeeks = 26.0; // ~6 Monate

  // Frequency Cap: Max Badges pro Woche die zählen
  static const int maxBadgesPerWeek = 2;
}

// =============================================
// BADGE VALUE: Was ist ein einzelnes Badge wert?
// =============================================
class BadgeValue {
  final String badgeId;
  final String meetupName;
  final double baseValue;
  final double coAttestorBonus;  // Wie viele andere haben dieses Badge?
  final double signerBonus;      // Wie vertrauenswürdig ist der Signer?
  final double decayFactor;      // Wie alt ist es?
  final double totalValue;       // Endwert
  final int coAttestorCount;
  final int veteranCount;

  BadgeValue({
    required this.badgeId,
    required this.meetupName,
    required this.baseValue,
    required this.coAttestorBonus,
    required this.signerBonus,
    required this.decayFactor,
    required this.totalValue,
    required this.coAttestorCount,
    required this.veteranCount,
  });
}

// =============================================
// TRUST SCORE: Gesamtbewertung
// =============================================
class TrustScore {
  final double totalScore;
  final double maturityScore;
  final double diversityScore;
  final double qualityScore;
  final double activityScore;
  final int totalBadges;
  final int uniqueMeetups;
  final int uniqueSigners;
  final int uniqueCities;
  final int accountAgeDays;
  final bool meetsPromotionThreshold;
  final String promotionReason;
  final List<BadgeValue> badgeValues;

  // NEU: Bootstrap-Phase Info
  final BootstrapPhase currentPhase;
  final PhaseThresholds activeThresholds;

  // NEU: Detaillierter Fortschritt
  final Map<String, PromotionProgress> progress;

  TrustScore({
    required this.totalScore,
    required this.maturityScore,
    required this.diversityScore,
    required this.qualityScore,
    required this.activityScore,
    required this.totalBadges,
    required this.uniqueMeetups,
    required this.uniqueSigners,
    required this.uniqueCities,
    required this.accountAgeDays,
    required this.meetsPromotionThreshold,
    required this.promotionReason,
    required this.badgeValues,
    required this.currentPhase,
    required this.activeThresholds,
    required this.progress,
  });

  // Kompakte Anzeige: 0-10 Skala
  double get displayScore => (totalScore / 5.0).clamp(0.0, 10.0);

  // Trust Level als Text
  String get level {
    if (totalScore >= 40) return 'VETERAN';
    if (totalScore >= 20) return 'ETABLIERT';
    if (totalScore >= 10) return 'AKTIV';
    if (totalScore >= 3) return 'STARTER';
    return 'NEU';
  }

  String get levelEmoji {
    if (totalScore >= 40) return '⭐';
    if (totalScore >= 20) return '🟢';
    if (totalScore >= 10) return '🔵';
    if (totalScore >= 3) return '🟠';
    return '⚪';
  }

  // Gesamtfortschritt in Prozent (0.0 - 1.0)
  double get promotionProgress {
    if (meetsPromotionThreshold) return 1.0;
    if (progress.isEmpty) return 0.0;
    final values = progress.values.map((p) => p.percentage).toList();
    return values.reduce((a, b) => a + b) / values.length;
  }
}

// =============================================
// PROMOTION FORTSCHRITT (pro Kriterium)
// =============================================
class PromotionProgress {
  final String label;
  final int current;
  final int required;
  final bool met;

  PromotionProgress({
    required this.label,
    required this.current,
    required this.required,
  }) : met = current >= required;

  double get percentage => required > 0 ? (current / required).clamp(0.0, 1.0) : 1.0;
}

// =============================================
// CO-ATTESTOR DATEN (von Relays oder Cache)
// =============================================
class CoAttestorData {
  final String meetupEventId;
  final int attendeeCount;
  final int veteranCount;
  final List<String> attendeeNpubs;

  CoAttestorData({
    required this.meetupEventId,
    required this.attendeeCount,
    required this.veteranCount,
    required this.attendeeNpubs,
  });
}

// =============================================
// DER SCORE-SERVICE
// =============================================
class TrustScoreService {

  // =============================================
  // BOOTSTRAP-PHASE BESTIMMEN
  // Basiert auf der Anzahl VERSCHIEDENER Signer
  // über ALLE Badges im Netzwerk (bzw. die der User kennt).
  // =============================================
  static BootstrapPhase _determinePhase(List<MeetupBadge> badges) {
    final uniqueSigners = badges
        .map((b) => b.signerNpub)
        .where((s) => s.isNotEmpty)
        .toSet();

    if (uniqueSigners.length >= 6) return BootstrapPhase.stabil;
    if (uniqueSigners.length >= 2) return BootstrapPhase.wachstum;
    return BootstrapPhase.keimphase;
  }

  // =============================================
  // TRUST SCORE BERECHNEN
  // =============================================
  static TrustScore calculateScore({
    required List<MeetupBadge> badges,
    required DateTime? firstBadgeDate,
    Map<String, CoAttestorData>? coAttestorMap,
  }) {
    // --- PHASE BESTIMMEN ---
    final phase = _determinePhase(badges);
    final thresholds = TrustConfig.phases[phase]!;

    if (badges.isEmpty) {
      return _emptyScore(phase, thresholds);
    }

    // --- GRUNDDATEN ---
    final uniqueMeetups = badges.map((b) => b.meetupName).toSet();
    final uniqueSigners = badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();
    final uniqueCities = uniqueMeetups;

    final accountAge = firstBadgeDate != null
        ? DateTime.now().difference(firstBadgeDate)
        : Duration.zero;

    // --- BADGE-WERTE BERECHNEN ---
    final List<BadgeValue> badgeValues = [];
    
    // Frequency Cap
    final Map<int, int> weeklyCount = {};
    final sortedBadges = List<MeetupBadge>.from(badges)
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final badge in sortedBadges) {
      final weekNumber = badge.date.difference(DateTime(2024)).inDays ~/ 7;
      weeklyCount[weekNumber] = (weeklyCount[weekNumber] ?? 0) + 1;

      if ((weeklyCount[weekNumber] ?? 0) > TrustConfig.maxBadgesPerWeek) {
        badgeValues.add(BadgeValue(
          badgeId: badge.id, meetupName: badge.meetupName,
          baseValue: 0, coAttestorBonus: 0, signerBonus: 0,
          decayFactor: 0, totalValue: 0, coAttestorCount: 0, veteranCount: 0,
        ));
        continue;
      }

      // Co-Attestor Daten
      final eventId = _badgeToEventId(badge);
      final coData = coAttestorMap?[eventId];
      final attendeeCount = coData?.attendeeCount ?? 1;
      final veteranCount = coData?.veteranCount ?? 0;

      // 1. CO-ATTESTOR BONUS: log2(teilnehmer + 1)
      final coAttestorBonus = log(attendeeCount + 1) / log(2);

      // 2. SIGNER BONUS: Vertrauenswürdigkeit des Tag-Erstellers
      //    Ein Veteran der Tags erstellt → seine Badges sind mehr wert
      //    Basierend auf Co-Attestor-Daten und Veteran-Zählung
      final signerBonus = 1.0 + (veteranCount * 0.3);

      // 3. TIME DECAY
      final ageWeeks = DateTime.now().difference(badge.date).inDays / 7.0;
      final decayFactor = pow(0.5, ageWeeks / TrustConfig.halfLifeWeeks).toDouble();

      // 4. TOTAL: base × co_attestor × signer × decay
      final totalValue = 1.0 * coAttestorBonus * signerBonus * decayFactor;

      badgeValues.add(BadgeValue(
        badgeId: badge.id,
        meetupName: badge.meetupName,
        baseValue: 1.0,
        coAttestorBonus: coAttestorBonus,
        signerBonus: signerBonus,
        decayFactor: decayFactor,
        totalValue: totalValue,
        coAttestorCount: attendeeCount,
        veteranCount: veteranCount,
      ));
    }

    // --- SCORES AGGREGIEREN ---

    // Maturity: min(1.0, account_alter_tage / 180)
    final maturityScore = min(1.0, accountAge.inDays / 180.0) * TrustConfig.weightMaturity;

    // Diversity: log2(unique_meetups + 1) × log2(unique_signers + 1)
    final diversityScore = (log(uniqueMeetups.length + 1) / log(2)) *
        (log(max(uniqueSigners.length, 1) + 1) / log(2)) *
        TrustConfig.weightDiversity;

    // Quality: Durchschnittlicher Signer-Bonus
    final qualitySum = badgeValues.fold<double>(0, (sum, bv) => sum + bv.signerBonus);
    final qualityScore = badgeValues.isNotEmpty
        ? (qualitySum / badgeValues.length) * TrustConfig.weightQuality
        : 0.0;

    // Activity: Summe aller Badge-Werte
    final activityScore = badgeValues.fold<double>(0, (sum, bv) => sum + bv.totalValue);

    // TOTAL SCORE
    final totalScore = activityScore * (1 + maturityScore) * (1 + diversityScore * 0.1);

    // --- PROMOTION CHECK (mit Phase-Schwellenwerten!) ---
    final progress = <String, PromotionProgress>{
      'badges': PromotionProgress(
        label: 'Badges',
        current: badges.length,
        required: thresholds.minBadges,
      ),
      'meetups': PromotionProgress(
        label: 'Verschiedene Meetups',
        current: uniqueMeetups.length,
        required: thresholds.minUniqueMeetups,
      ),
      'signers': PromotionProgress(
        label: 'Verschiedene Ersteller',
        current: uniqueSigners.length,
        required: thresholds.minUniqueSigners,
      ),
      'age': PromotionProgress(
        label: 'Account-Alter (Tage)',
        current: accountAge.inDays,
        required: thresholds.minAccountAgeDays,
      ),
      'score': PromotionProgress(
        label: 'Trust Score',
        current: totalScore.round(),
        required: thresholds.promotionScore.round(),
      ),
    };

    // Alle Kriterien prüfen
    String promotionReason = '';
    bool meetsThreshold = true;

    for (final entry in progress.entries) {
      if (!entry.value.met) {
        meetsThreshold = false;
        promotionReason = _buildReason(entry.key, entry.value, thresholds);
        break; // Erstes nicht erfülltes Kriterium
      }
    }

    if (meetsThreshold) {
      promotionReason = '${thresholds.emoji} Alle Bedingungen erfüllt! Du kannst jetzt Meetup-Tags erstellen.';
    }

    return TrustScore(
      totalScore: totalScore,
      maturityScore: maturityScore,
      diversityScore: diversityScore,
      qualityScore: qualityScore,
      activityScore: activityScore,
      totalBadges: badges.length,
      uniqueMeetups: uniqueMeetups.length,
      uniqueSigners: uniqueSigners.length,
      uniqueCities: uniqueCities.length,
      accountAgeDays: accountAge.inDays,
      meetsPromotionThreshold: meetsThreshold,
      promotionReason: promotionReason,
      badgeValues: badgeValues,
      currentPhase: phase,
      activeThresholds: thresholds,
      progress: progress,
    );
  }

  // =============================================
  // BRIDGE SCORE: Verbindest du Meetup-Cluster?
  // =============================================
  static double calculateBridgeScore(List<MeetupBadge> badges) {
    if (badges.length < 3) return 0;
    final cities = badges.map((b) => b.meetupName).toSet();
    if (cities.length <= 1) return 0;
    final signers = badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();
    return cities.length.toDouble() * max(signers.length.toDouble(), 1.0);
  }

  // =============================================
  // SYBIL-ERKENNUNG
  // =============================================
  static List<String> detectSuspiciousPatterns(
    List<MeetupBadge> badges,
    Map<String, CoAttestorData>? coAttestorMap,
  ) {
    final warnings = <String>[];
    if (badges.isEmpty) return warnings;

    // Check 1: Alle Badges vom gleichen Signer?
    final signers = badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();
    if (signers.length == 1 && badges.length > 3) {
      warnings.add('Alle Badges von nur einem Ersteller');
    }

    // Check 2: Viele Badges am gleichen Tag?
    final dates = <String, int>{};
    for (final b in badges) {
      final day = b.date.toIso8601String().substring(0, 10);
      dates[day] = (dates[day] ?? 0) + 1;
    }
    final maxPerDay = dates.values.fold<int>(0, max);
    if (maxPerDay > 3) {
      warnings.add('$maxPerDay Badges an einem Tag');
    }

    // Check 3: Keine Co-Attestors?
    if (coAttestorMap != null) {
      final lonelyBadges = badges.where((b) {
        final eventId = _badgeToEventId(b);
        final coData = coAttestorMap[eventId];
        return coData == null || coData.attendeeCount <= 1;
      }).length;

      if (lonelyBadges == badges.length && badges.length > 2) {
        warnings.add('Kein Badge hat Co-Attestors');
      }
    }

    return warnings;
  }

  // =============================================
  // HILFSFUNKTIONEN
  // =============================================

  static String _badgeToEventId(MeetupBadge badge) {
    final dateStr = badge.date.toIso8601String().substring(0, 10);
    final meetup = badge.meetupName.toLowerCase().replaceAll(' ', '-');
    return '$meetup-$dateStr';
  }

  static String _buildReason(String key, PromotionProgress p, PhaseThresholds thresholds) {
    switch (key) {
      case 'badges': return 'Noch ${p.required - p.current} Badges sammeln (${p.current}/${p.required})';
      case 'meetups': return 'Noch ${p.required - p.current} verschiedene Meetups besuchen (${p.current}/${p.required})';
      case 'signers': return 'Badges von ${p.required - p.current} weiteren Erstellern nötig (${p.current}/${p.required})';
      case 'age': return 'Noch ${p.required - p.current} Tage warten (${p.current}/${p.required} Tage)';
      case 'score': return 'Trust Score ${p.current} / ${p.required}';
      default: return '${p.label}: ${p.current}/${p.required}';
    }
  }

  static TrustScore _emptyScore(BootstrapPhase phase, PhaseThresholds thresholds) {
    return TrustScore(
      totalScore: 0, maturityScore: 0, diversityScore: 0,
      qualityScore: 0, activityScore: 0, totalBadges: 0,
      uniqueMeetups: 0, uniqueSigners: 0, uniqueCities: 0,
      accountAgeDays: 0, meetsPromotionThreshold: false,
      promotionReason: 'Besuche Meetups und sammle Badges!',
      badgeValues: [],
      currentPhase: phase,
      activeThresholds: thresholds,
      progress: {
        'badges': PromotionProgress(label: 'Badges', current: 0, required: thresholds.minBadges),
        'meetups': PromotionProgress(label: 'Meetups', current: 0, required: thresholds.minUniqueMeetups),
        'signers': PromotionProgress(label: 'Ersteller', current: 0, required: thresholds.minUniqueSigners),
        'age': PromotionProgress(label: 'Tage', current: 0, required: thresholds.minAccountAgeDays),
        'score': PromotionProgress(label: 'Score', current: 0, required: thresholds.promotionScore.round()),
      },
    );
  }
}