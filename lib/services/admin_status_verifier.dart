// ============================================
// ADMIN STATUS VERIFIER — Kryptographische Prüfung
// ============================================
//
// SECURITY AUDIT C2: Admin-Status darf NICHT nur auf
// einem SharedPreferences Boolean basieren. Auf gerooteten
// Geräten kann jeder User `is_admin = true` setzen.
//
// LÖSUNG: Admin-Status wird bei JEDEM App-Start
// kryptographisch verifiziert durch:
//
//   1. Trust Score live aus Nostr-signierten Badges berechnen
//   2. Seed-Admin Prüfung gegen AdminRegistry
//
// Der SharedPreferences-Wert dient NUR als Cache für
// die Offline-UI. Sicherheitskritische Operationen
// (Signieren, NFC-Tags erstellen) MÜSSEN immer über
// verifyAdminStatus() geprüft werden.
//
// ============================================

import '../models/badge.dart';
import 'admin_registry.dart';
import 'secure_key_store.dart';
import 'trust_score_service.dart';

class AdminVerification {
  final bool isAdmin;
  final String source; // 'trust_score', 'seed_admin', 'not_admin'
  final String reason;

  const AdminVerification({
    required this.isAdmin,
    required this.source,
    this.reason = '',
  });

  static const notAdmin = AdminVerification(
    isAdmin: false,
    source: 'not_admin',
    reason: 'Weder Trust Score noch Seed-Admin Bedingungen erfüllt.',
  );
}

class AdminStatusVerifier {
  // =============================================
  // HAUPTMETHODE: Kryptographische Admin-Prüfung
  // =============================================
  //
  // Wird bei jedem App-Start aufgerufen.
  // Gibt verified=true zurück wenn EINE der Bedingungen gilt:
  //
  //   a) Trust Score aus Nostr-signierten Badges >= Schwellenwert
  //   b) User ist in der AdminRegistry als Seed-Admin gelistet
  //
  // =============================================
  static Future<AdminVerification> verifyAdminStatus({
    required List<MeetupBadge> badges,
  }) async {
    // --- CHECK 1: Hat der User überhaupt einen Nostr-Key? ---
    final hasKey = await SecureKeyStore.hasKey();
    if (!hasKey) {
      return const AdminVerification(
        isAdmin: false,
        source: 'no_key',
        reason: 'Kein Nostr-Key vorhanden.',
      );
    }

    // --- CHECK 2: Trust Score (aus Nostr-signierten Badges) ---
    // calculateScore() filtert bereits v1 Badges raus (Security Audit C1)
    if (badges.isNotEmpty) {
      final sorted = List<MeetupBadge>.from(badges)
        ..sort((a, b) => a.date.compareTo(b.date));
      final score = TrustScoreService.calculateScore(
        badges: badges,
        firstBadgeDate: sorted.first.date,
      );
      if (score.meetsPromotionThreshold) {
        return AdminVerification(
          isAdmin: true,
          source: 'trust_score',
          reason: 'Trust Score ${score.totalScore.toStringAsFixed(1)} '
              'erfüllt Schwellenwert (${score.activeThresholds.promotionScore}).',
        );
      }
    }

    // --- CHECK 3: Seed-Admin in Registry ---
    final npub = await SecureKeyStore.getNpub();
    if (npub != null && npub.isNotEmpty) {
      try {
        final result = await AdminRegistry.checkAdmin(npub);
        if (result.isAdmin) {
          return AdminVerification(
            isAdmin: true,
            source: 'seed_admin',
            reason: 'Seed-Admin (${result.source}).',
          );
        }
      } catch (_) {
        // Registry nicht erreichbar — kein Admin-Status vergeben
        // Sicherheit > Verfügbarkeit: Im Zweifel NICHT Admin
      }
    }

    return AdminVerification.notAdmin;
  }

  // =============================================
  // SCHNELL-CHECK: Für sicherheitskritische Operationen
  // =============================================
  //
  // Kurzform für Guards in Signatur-Operationen.
  // Beispiel:
  //   if (!await AdminStatusVerifier.isVerifiedAdmin(badges)) {
  //     throw SecurityException('Kein verifizierter Admin');
  //   }
  //
  // =============================================
  static Future<bool> isVerifiedAdmin({
    required List<MeetupBadge> badges,
  }) async {
    final result = await verifyAdminStatus(badges: badges);
    return result.isAdmin;
  }
}
