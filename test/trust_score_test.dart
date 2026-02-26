// ============================================
// UNIT TESTS: TrustScoreService
// ============================================
// Testet das Trust-Score-System:
//   - Leere/keine Badges → Score 0
//   - v1 Legacy Badges werden ignoriert
//   - Bootstrap-Phasen (Keimphase, Wachstum, Stabil)
//   - Promotion-Schwellenwerte
//   - Diversity-, Maturity-, Activity-Scores
//   - Bridge Score (Cross-Meetup-Vernetzung)
//   - Frequency Cap (max 2 Badges/Woche)
//   - Sybil-Erkennung
//   - TrustScore Hilfsmethoden (level, displayScore)
// ============================================

import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/trust_score_service.dart';

void main() {
  // =============================================
  // TEST HELPERS
  // =============================================
  
  /// Erzeugt ein Test-Badge mit optionalen Parametern
  MeetupBadge _badge({
    String id = 'test',
    String meetupName = 'Aschaffenburg',
    DateTime? date,
    int blockHeight = 875000,
    String signerNpub = 'npub1testsigner',
    int sigVersion = 2,
    String sig = '',
    String adminPubkey = '',
  }) {
    return MeetupBadge(
      id: id,
      meetupName: meetupName,
      date: date ?? DateTime.now().subtract(const Duration(days: 7)),
      iconPath: '',
      blockHeight: blockHeight,
      signerNpub: signerNpub,
      sigVersion: sigVersion,
      sig: sig.isNotEmpty ? sig : 'a' * 128,
      adminPubkey: adminPubkey.isNotEmpty ? adminPubkey : 'b' * 64,
    );
  }

  // =============================================
  // LEERE EINGABEN
  // =============================================

  group('Leere/Keine Badges', () {
    test('keine Badges → Score 0', () {
      final score = TrustScoreService.calculateScore(
        badges: [],
        firstBadgeDate: null,
      );
      expect(score.totalScore, 0);
      expect(score.totalBadges, 0);
      expect(score.meetsPromotionThreshold, isFalse);
      expect(score.level, 'NEU');
    });

    test('nur v1 Legacy Badges → Score 0 (Security Audit C1)', () {
      final legacyBadges = [
        _badge(id: '1', sigVersion: 1, sig: 'legacy1' * 18 + 'ab'),
        _badge(id: '2', sigVersion: 1, sig: 'legacy2' * 18 + 'ab'),
        _badge(id: '3', sigVersion: 0, sig: ''),
      ];
      final score = TrustScoreService.calculateScore(
        badges: legacyBadges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 60)),
      );
      expect(score.totalScore, 0);
      expect(score.totalBadges, 0);
    });
  });

  // =============================================
  // BOOTSTRAP-PHASEN
  // =============================================

  group('Bootstrap-Phasen', () {
    test('Keimphase: nur 1 Signer', () {
      final badges = [
        _badge(id: '1', signerNpub: 'npub1signer_a'),
        _badge(id: '2', signerNpub: 'npub1signer_a'),
      ];
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(score.currentPhase, BootstrapPhase.keimphase);
    });

    test('Wachstum: 2-5 Signer', () {
      final badges = [
        _badge(id: '1', signerNpub: 'npub1signer_a'),
        _badge(id: '2', signerNpub: 'npub1signer_b'),
        _badge(id: '3', signerNpub: 'npub1signer_c'),
      ];
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(score.currentPhase, BootstrapPhase.wachstum);
    });

    test('Stabil: 6+ Signer', () {
      final badges = List.generate(6, (i) => 
        _badge(id: '$i', signerNpub: 'npub1signer_$i'));
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(score.currentPhase, BootstrapPhase.stabil);
    });
  });

  // =============================================
  // SCORE-BERECHNUNG
  // =============================================

  group('Score-Berechnung', () {
    test('mehr Badges = höherer Score', () {
      final few = [_badge(id: '1')];
      final many = [
        _badge(id: '1', meetupName: 'A', signerNpub: 'npub1a'),
        _badge(id: '2', meetupName: 'B', signerNpub: 'npub1b'),
        _badge(id: '3', meetupName: 'C', signerNpub: 'npub1c'),
      ];
      
      final scoreFew = TrustScoreService.calculateScore(
        badges: few, firstBadgeDate: DateTime.now(),
      );
      final scoreMany = TrustScoreService.calculateScore(
        badges: many, firstBadgeDate: DateTime.now().subtract(const Duration(days: 30)),
      );
      
      expect(scoreMany.totalScore, greaterThan(scoreFew.totalScore));
    });

    test('älteres Konto = höherer Maturity-Score', () {
      final badges = [_badge(id: '1')];
      
      final young = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now(),
      );
      final old = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 180)),
      );
      
      expect(old.maturityScore, greaterThanOrEqualTo(young.maturityScore));
    });

    test('verschiedene Meetups = höherer Diversity-Score', () {
      final sameMeetup = [
        _badge(id: '1', meetupName: 'A'),
        _badge(id: '2', meetupName: 'A'),
      ];
      final diverseMeetups = [
        _badge(id: '1', meetupName: 'A', signerNpub: 'npub1a'),
        _badge(id: '2', meetupName: 'B', signerNpub: 'npub1b'),
      ];
      
      final scoreSame = TrustScoreService.calculateScore(
        badges: sameMeetup, firstBadgeDate: DateTime.now(),
      );
      final scoreDiverse = TrustScoreService.calculateScore(
        badges: diverseMeetups, firstBadgeDate: DateTime.now(),
      );
      
      expect(scoreDiverse.diversityScore, greaterThan(scoreSame.diversityScore));
    });

    test('alte Badges verlieren durch Time Decay an Wert', () {
      final recent = [
        _badge(id: '1', date: DateTime.now().subtract(const Duration(days: 1))),
      ];
      final old = [
        _badge(id: '1', date: DateTime.now().subtract(const Duration(days: 365))),
      ];
      
      final scoreRecent = TrustScoreService.calculateScore(
        badges: recent, firstBadgeDate: DateTime.now(),
      );
      final scoreOld = TrustScoreService.calculateScore(
        badges: old, firstBadgeDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      
      expect(scoreRecent.activityScore, greaterThan(scoreOld.activityScore));
    });
  });

  // =============================================
  // FREQUENCY CAP
  // =============================================

  group('Frequency Cap', () {
    test('max 2 Badges pro Woche zählen', () {
      // 3 Badges am selben Tag → nur 2 zählen
      final date = DateTime.now().subtract(const Duration(days: 1));
      final badges = [
        _badge(id: '1', date: date, meetupName: 'A'),
        _badge(id: '2', date: date, meetupName: 'B'),
        _badge(id: '3', date: date, meetupName: 'C'),
      ];
      
      final score = TrustScoreService.calculateScore(
        badges: badges, firstBadgeDate: date,
      );
      
      // 3. Badge hat totalValue 0
      final zeroBadges = score.badgeValues.where((bv) => bv.totalValue == 0).length;
      expect(zeroBadges, 1);
    });
  });

  // =============================================
  // PROMOTION CHECKS
  // =============================================

  group('Promotion-Schwellenwerte', () {
    test('erfüllt Keimphase-Bedingungen', () {
      // Keimphase: 3 Badges, 2 Meetups, 1 Signer, 14 Tage, Score 5
      final badges = [
        _badge(id: '1', meetupName: 'A', date: DateTime.now().subtract(const Duration(days: 20))),
        _badge(id: '2', meetupName: 'B', date: DateTime.now().subtract(const Duration(days: 14))),
        _badge(id: '3', meetupName: 'C', date: DateTime.now().subtract(const Duration(days: 7))),
      ];
      
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: DateTime.now().subtract(const Duration(days: 20)),
      );
      
      // Prüfe dass Progress-Map vorhanden ist
      expect(score.progress, isNotEmpty);
      expect(score.progress.containsKey('badges'), isTrue);
      expect(score.progress.containsKey('meetups'), isTrue);
      expect(score.progress.containsKey('signers'), isTrue);
      expect(score.progress.containsKey('age'), isTrue);
    });

    test('PromotionProgress Prozentberechnung', () {
      final p = PromotionProgress(label: 'Test', current: 2, required: 4);
      expect(p.percentage, 0.5);
      expect(p.met, isFalse);
      
      final pMet = PromotionProgress(label: 'Test', current: 5, required: 4);
      expect(pMet.percentage, 1.0); // Clamped auf 1.0
      expect(pMet.met, isTrue);
    });
  });

  // =============================================
  // BRIDGE SCORE
  // =============================================

  group('calculateBridgeScore', () {
    test('weniger als 3 Badges → 0', () {
      expect(TrustScoreService.calculateBridgeScore([
        _badge(id: '1'),
        _badge(id: '2'),
      ]), 0);
    });

    test('nur ein Meetup → 0', () {
      expect(TrustScoreService.calculateBridgeScore([
        _badge(id: '1', meetupName: 'A'),
        _badge(id: '2', meetupName: 'A'),
        _badge(id: '3', meetupName: 'A'),
      ]), 0);
    });

    test('verschiedene Meetups und Signer → positiver Score', () {
      final score = TrustScoreService.calculateBridgeScore([
        _badge(id: '1', meetupName: 'A', signerNpub: 'npub1x'),
        _badge(id: '2', meetupName: 'B', signerNpub: 'npub1y'),
        _badge(id: '3', meetupName: 'C', signerNpub: 'npub1z'),
      ]);
      // 3 cities × 3 signers = 9
      expect(score, greaterThan(0));
    });
  });

  // =============================================
  // SYBIL-ERKENNUNG
  // =============================================

  group('detectSuspiciousPatterns', () {
    test('alle Badges von einem Signer → Warnung', () {
      final badges = List.generate(4, (i) =>
        _badge(id: '$i', signerNpub: 'npub1single'));
      
      final warnings = TrustScoreService.detectSuspiciousPatterns(badges, null);
      expect(warnings, contains(contains('einem Ersteller')));
    });

    test('viele Badges am gleichen Tag → Warnung', () {
      final date = DateTime.now();
      final badges = List.generate(4, (i) =>
        _badge(id: '$i', date: date, signerNpub: 'npub1_$i'));
      
      final warnings = TrustScoreService.detectSuspiciousPatterns(badges, null);
      expect(warnings, contains(contains('an einem Tag')));
    });

    test('normale Aktivität → keine Warnung', () {
      final badges = [
        _badge(id: '1', signerNpub: 'npub1a', 
               date: DateTime.now().subtract(const Duration(days: 30))),
        _badge(id: '2', signerNpub: 'npub1b',
               date: DateTime.now().subtract(const Duration(days: 14))),
      ];
      final warnings = TrustScoreService.detectSuspiciousPatterns(badges, null);
      expect(warnings, isEmpty);
    });

    test('leere Badges → keine Warnung', () {
      expect(TrustScoreService.detectSuspiciousPatterns([], null), isEmpty);
    });
  });

  // =============================================
  // TRUST SCORE HILFSMETHODEN
  // =============================================

  group('TrustScore — Level & Display', () {
    test('level Zuordnung korrekt', () {
      TrustScore _makeScore(double total) => TrustScore(
        totalScore: total, maturityScore: 0, diversityScore: 0,
        qualityScore: 0, activityScore: 0, totalBadges: 0,
        uniqueMeetups: 0, uniqueSigners: 0, uniqueCities: 0,
        accountAgeDays: 0, meetsPromotionThreshold: false,
        promotionReason: '', badgeValues: [],
        currentPhase: BootstrapPhase.keimphase,
        activeThresholds: TrustConfig.phases[BootstrapPhase.keimphase]!,
        progress: {},
      );

      expect(_makeScore(0).level, 'NEU');
      expect(_makeScore(3).level, 'STARTER');
      expect(_makeScore(10).level, 'AKTIV');
      expect(_makeScore(20).level, 'ETABLIERT');
      expect(_makeScore(40).level, 'VETERAN');
    });

    test('displayScore: 0-10 Skala', () {
      TrustScore _makeScore(double total) => TrustScore(
        totalScore: total, maturityScore: 0, diversityScore: 0,
        qualityScore: 0, activityScore: 0, totalBadges: 0,
        uniqueMeetups: 0, uniqueSigners: 0, uniqueCities: 0,
        accountAgeDays: 0, meetsPromotionThreshold: false,
        promotionReason: '', badgeValues: [],
        currentPhase: BootstrapPhase.keimphase,
        activeThresholds: TrustConfig.phases[BootstrapPhase.keimphase]!,
        progress: {},
      );

      expect(_makeScore(0).displayScore, 0.0);
      expect(_makeScore(25).displayScore, 5.0);
      expect(_makeScore(50).displayScore, 10.0);
      expect(_makeScore(100).displayScore, 10.0); // Clamped
    });

    test('promotionProgress: Durchschnitt', () {
      TrustScore _makeWithProgress(Map<String, PromotionProgress> progress) => TrustScore(
        totalScore: 0, maturityScore: 0, diversityScore: 0,
        qualityScore: 0, activityScore: 0, totalBadges: 0,
        uniqueMeetups: 0, uniqueSigners: 0, uniqueCities: 0,
        accountAgeDays: 0, meetsPromotionThreshold: false,
        promotionReason: '', badgeValues: [],
        currentPhase: BootstrapPhase.keimphase,
        activeThresholds: TrustConfig.phases[BootstrapPhase.keimphase]!,
        progress: progress,
      );

      final half = _makeWithProgress({
        'a': PromotionProgress(label: 'A', current: 5, required: 10),
        'b': PromotionProgress(label: 'B', current: 10, required: 10),
      });
      expect(half.promotionProgress, 0.75); // (0.5 + 1.0) / 2
    });
  });

  // =============================================
  // TRUST CONFIG
  // =============================================

  group('TrustConfig — Konstanten', () {
    test('alle Phasen definiert', () {
      expect(TrustConfig.phases.containsKey(BootstrapPhase.keimphase), isTrue);
      expect(TrustConfig.phases.containsKey(BootstrapPhase.wachstum), isTrue);
      expect(TrustConfig.phases.containsKey(BootstrapPhase.stabil), isTrue);
    });

    test('Schwellenwerte steigen mit Phase', () {
      final keim = TrustConfig.phases[BootstrapPhase.keimphase]!;
      final wachstum = TrustConfig.phases[BootstrapPhase.wachstum]!;
      final stabil = TrustConfig.phases[BootstrapPhase.stabil]!;

      expect(wachstum.minBadges, greaterThanOrEqualTo(keim.minBadges));
      expect(stabil.minBadges, greaterThanOrEqualTo(wachstum.minBadges));
      expect(stabil.promotionScore, greaterThan(keim.promotionScore));
    });

    test('Frequency Cap ist 2 Badges/Woche', () {
      expect(TrustConfig.maxBadgesPerWeek, 2);
    });

    test('Halbwertszeit ist ~6 Monate', () {
      expect(TrustConfig.halfLifeWeeks, 26.0);
    });
  });
}
