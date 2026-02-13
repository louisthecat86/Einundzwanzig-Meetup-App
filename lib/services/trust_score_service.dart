// ============================================
// TRUST SCORE SERVICE
// ============================================
//
// Berechnet lokal, wie vertrauenswürdig ein User ist.
// Basiert NUR auf Badge-Daten – kein Server, kein Admin.
//
// Prinzip:
//   - Jedes Badge hat einen WERT (nicht binär "hab ich / hab ich nicht")
//   - Der Wert hängt davon ab:
//     → Wie viele Leute haben das gleiche Badge? (Co-Attestors)
//     → Wie vertrauenswürdig sind diese Leute? (Quality)
//     → Wie divers ist die Badge-Sammlung? (Diversity)
//     → Wie alt ist der Account? (Maturity)
//     → Wie aktuell sind die Badges? (Time Decay)
//
// Ergebnis:
//   Trust Score → Zahl die zeigt ob jemand Tags erstellen darf
//   Badge Value → Einzelwert pro Badge
//   Promotion   → Darf dieser User Meetup-Tags erstellen?
//
// Alles lokal berechnet. Verschiedene Apps können
// verschiedene Gewichtungen haben. Das ist gewollt.
// ============================================

import 'dart:math';
import '../models/badge.dart';

// =============================================
// KONFIGURATION (kann von der Community geforkt werden)
// =============================================
class TrustConfig {
  // Ab welchem Score darf man Tags erstellen?
  static const double promotionThreshold = 15.0;

  // Minimum-Anforderungen (zusätzlich zum Score)
  static const int minBadges = 5;
  static const int minUniqueMeetups = 3;
  static const int minUniqueSigners = 2;
  static const int minAccountAgeDays = 60; // ~2 Monate

  // Scoring Gewichtung
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
  final double baseValue;        // 1.0
  final double coAttestorBonus;  // Wie viele andere haben dieses Badge?
  final double veteranBonus;     // Wie viele Veteranen haben es?
  final double decayFactor;      // Wie alt ist es?
  final double totalValue;       // Endwert
  final int coAttestorCount;     // Anzahl Co-Attestors
  final int veteranCount;        // Anzahl Veteranen unter den Co-Attestors

  BadgeValue({
    required this.badgeId,
    required this.meetupName,
    required this.baseValue,
    required this.coAttestorBonus,
    required this.veteranBonus,
    required this.decayFactor,
    required this.totalValue,
    required this.coAttestorCount,
    required this.veteranCount,
  });
}

// =============================================
// TRUST SCORE: Gesamtbewertung eines Users
// =============================================
class TrustScore {
  final double totalScore;
  final double maturityScore;   // Wie alt ist der Account?
  final double diversityScore;  // Wie divers sind die Badges?
  final double qualityScore;    // Wie gut sind die Co-Attestors?
  final double activityScore;   // Wie aktiv ist der User?
  final int totalBadges;
  final int uniqueMeetups;
  final int uniqueSigners;
  final int uniqueCities;
  final int accountAgeDays;
  final bool meetsPromotionThreshold;
  final String promotionReason; // Warum ja/nein
  final List<BadgeValue> badgeValues;

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

  // Farbe für Anzeige
  String get levelColor {
    if (totalScore >= 40) return 'gold';
    if (totalScore >= 20) return 'green';
    if (totalScore >= 10) return 'cyan';
    if (totalScore >= 3) return 'orange';
    return 'grey';
  }
}

// =============================================
// CO-ATTESTOR DATEN
// (kommt von Nostr Relays oder lokalem Cache)
// =============================================
class CoAttestorData {
  final String meetupEventId;  // z.B. "muenchen-2026-02-12"
  final int attendeeCount;      // Wie viele haben dieses Badge
  final int veteranCount;       // Wie viele davon sind Veteranen
  final List<String> attendeeNpubs; // npubs der Teilnehmer

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
  // TRUST SCORE BERECHNEN
  // =============================================
  static TrustScore calculateScore({
    required List<MeetupBadge> badges,
    required DateTime? firstBadgeDate,
    Map<String, CoAttestorData>? coAttestorMap,
  }) {
    if (badges.isEmpty) {
      return TrustScore(
        totalScore: 0,
        maturityScore: 0,
        diversityScore: 0,
        qualityScore: 0,
        activityScore: 0,
        totalBadges: 0,
        uniqueMeetups: 0,
        uniqueSigners: 0,
        uniqueCities: 0,
        accountAgeDays: 0,
        meetsPromotionThreshold: false,
        promotionReason: 'Keine Badges vorhanden',
        badgeValues: [],
      );
    }

    // --- GRUNDDATEN EXTRAHIEREN ---
    final uniqueMeetups = badges.map((b) => b.meetupName).toSet();
    // SignerNpub kommt aus dem erweiterten Badge-Model
    final uniqueSigners = badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();
    // Städte (vereinfacht: meetupName = Stadt)
    final uniqueCities = uniqueMeetups; // Für jetzt gleich

    // Account-Alter
    final accountAge = firstBadgeDate != null
        ? DateTime.now().difference(firstBadgeDate)
        : Duration.zero;

    // --- BADGE-WERTE BERECHNEN ---
    final List<BadgeValue> badgeValues = [];
    
    // Frequency Cap: Max 2 Badges pro Woche
    final Map<int, int> weeklyCount = {};
    final sortedBadges = List<MeetupBadge>.from(badges)
      ..sort((a, b) => b.date.compareTo(a.date)); // Neueste zuerst

    for (final badge in sortedBadges) {
      final weekNumber = badge.date.difference(DateTime(2024)).inDays ~/ 7;
      weeklyCount[weekNumber] = (weeklyCount[weekNumber] ?? 0) + 1;

      // Frequency Cap: Mehr als 2 pro Woche zählen nicht
      final cappedByFrequency = (weeklyCount[weekNumber] ?? 0) > TrustConfig.maxBadgesPerWeek;

      if (cappedByFrequency) {
        badgeValues.add(BadgeValue(
          badgeId: badge.id,
          meetupName: badge.meetupName,
          baseValue: 0,
          coAttestorBonus: 0,
          veteranBonus: 0,
          decayFactor: 0,
          totalValue: 0, // Frequency-capped!
          coAttestorCount: 0,
          veteranCount: 0,
        ));
        continue;
      }

      // Co-Attestor Daten (wenn verfügbar)
      final eventId = _badgeToEventId(badge);
      final coData = coAttestorMap?[eventId];
      final attendeeCount = coData?.attendeeCount ?? 1;
      final veteranCount = coData?.veteranCount ?? 0;

      // 1. CO-ATTESTOR BONUS: log2(teilnehmer + 1)
      //    1 Person  → 1.0
      //    7 Personen → 3.0
      //    31 Personen → 5.0
      final coAttestorBonus = log(attendeeCount + 1) / log(2);

      // 2. VETERANEN BONUS: 1 + (veteranen * 0.3)
      //    0 Veteranen → 1.0
      //    3 Veteranen → 1.9
      //    10 Veteranen → 4.0
      final veteranBonus = 1.0 + (veteranCount * 0.3);

      // 3. TIME DECAY: 0.5^(alter_in_wochen / halbwertszeit)
      final ageWeeks = DateTime.now().difference(badge.date).inDays / 7.0;
      final decayFactor = pow(0.5, ageWeeks / TrustConfig.halfLifeWeeks).toDouble();

      // 4. TOTAL: base × co_attestor × veteran × decay
      final baseValue = 1.0;
      final totalValue = baseValue * coAttestorBonus * veteranBonus * decayFactor;

      badgeValues.add(BadgeValue(
        badgeId: badge.id,
        meetupName: badge.meetupName,
        baseValue: baseValue,
        coAttestorBonus: coAttestorBonus,
        veteranBonus: veteranBonus,
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

    // Quality: Durchschnittlicher Co-Attestor/Veteranen-Bonus
    final qualitySum = badgeValues.fold<double>(0, (sum, bv) => sum + bv.veteranBonus);
    final qualityScore = badgeValues.isNotEmpty
        ? (qualitySum / badgeValues.length) * TrustConfig.weightQuality
        : 0.0;

    // Activity: Summe aller Badge-Werte (inkl. Decay)
    final activityScore = badgeValues.fold<double>(0, (sum, bv) => sum + bv.totalValue);

    // TOTAL SCORE
    final totalScore = activityScore * (1 + maturityScore) * (1 + diversityScore * 0.1);

    // --- PROMOTION CHECK ---
    String promotionReason = '';
    bool meetsThreshold = true;

    if (badges.length < TrustConfig.minBadges) {
      meetsThreshold = false;
      promotionReason = 'Mindestens ${TrustConfig.minBadges} Badges nötig (hast ${badges.length})';
    } else if (uniqueMeetups.length < TrustConfig.minUniqueMeetups) {
      meetsThreshold = false;
      promotionReason = 'Mindestens ${TrustConfig.minUniqueMeetups} verschiedene Meetups nötig (hast ${uniqueMeetups.length})';
    } else if (uniqueSigners.length < TrustConfig.minUniqueSigners) {
      meetsThreshold = false;
      promotionReason = 'Badges von mindestens ${TrustConfig.minUniqueSigners} verschiedenen Erstellern nötig (hast ${uniqueSigners.length})';
    } else if (accountAge.inDays < TrustConfig.minAccountAgeDays) {
      meetsThreshold = false;
      final daysLeft = TrustConfig.minAccountAgeDays - accountAge.inDays;
      promotionReason = 'Account muss mindestens ${TrustConfig.minAccountAgeDays} Tage alt sein (noch $daysLeft Tage)';
    } else if (totalScore < TrustConfig.promotionThreshold) {
      meetsThreshold = false;
      promotionReason = 'Trust Score ${totalScore.toStringAsFixed(1)} / ${TrustConfig.promotionThreshold} (besuche gut besuchte Meetups um deinen Score zu erhöhen)';
    } else {
      promotionReason = 'Alle Bedingungen erfüllt!';
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
    );
  }

  // =============================================
  // BRIDGE SCORE: Bist du ein Brückenbauer?
  // =============================================
  // Ein hoher Bridge Score bedeutet: Dieser User verbindet
  // verschiedene Meetup-Cluster. Das ist extrem wertvoll
  // und extrem schwer zu faken.
  static double calculateBridgeScore(List<MeetupBadge> badges) {
    if (badges.length < 3) return 0;

    // Wie viele verschiedene Städte/Meetups?
    final cities = badges.map((b) => b.meetupName).toSet();
    if (cities.length <= 1) return 0;

    // Wie viele verschiedene Ersteller?
    final signers = badges.map((b) => b.signerNpub).where((s) => s.isNotEmpty).toSet();

    // Bridge Score: cities × signers (geometrisch)
    // 2 Städte, 2 Signer = 4
    // 4 Städte, 3 Signer = 12
    // 8 Städte, 5 Signer = 40
    return cities.length.toDouble() * max(signers.length.toDouble(), 1.0);
  }

  // =============================================
  // SYBIL-ERKENNUNG (einfache Version)
  // =============================================
  // Erkennt verdächtige Muster:
  // - Alle Badges vom gleichen Signer
  // - Alle Badges am gleichen Tag
  // - Keine Co-Attestors
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
      warnings.add('$maxPerDay Badges an einem Tag – ungewöhnlich');
    }

    // Check 3: Keine Co-Attestors?
    if (coAttestorMap != null) {
      final lonelyBadges = badges.where((b) {
        final eventId = _badgeToEventId(b);
        final coData = coAttestorMap[eventId];
        return coData == null || coData.attendeeCount <= 1;
      }).length;

      if (lonelyBadges == badges.length && badges.length > 2) {
        warnings.add('Kein Badge hat Co-Attestors – keine bestätigte Anwesenheit');
      }
    }

    return warnings;
  }

  // Badge zu Event-ID konvertieren (für Co-Attestor Lookup)
  static String _badgeToEventId(MeetupBadge badge) {
    final dateStr = badge.date.toIso8601String().substring(0, 10);
    final meetup = badge.meetupName.toLowerCase().replaceAll(' ', '-');
    return '$meetup-$dateStr';
  }
}