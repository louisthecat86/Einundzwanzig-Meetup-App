// ============================================
// REPUTATION LAYERS WIDGET — Multi-Layer Anzeige
// ============================================
// Wiederverwendbares Widget zur Anzeige aller
// Vertrauens-Layer mit Scores und Details.
//
// Wird verwendet in:
//   - reputation_verify_screen.dart (fremde Reputation)
//   - reputation_qr.dart (eigene Reputation)
// ============================================

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/social_graph_service.dart';
import '../services/zap_verification_service.dart';
import '../services/nip05_service.dart';

class ReputationLayersWidget extends StatelessWidget {
  // Layer 1: Physisch (aus Reputation-Event)
  final int? badgeCount;
  final int? boundBadges;
  final int? meetupCount;
  final int? signerCount;
  final double? meetupScore;
  final String? since;

  // Layer 2: Lightning/Zaps
  final ZapStats? zapStats;
  final bool humanityVerified;

  // Layer 3: Sozial
  final SocialAnalysis? socialAnalysis;

  // Layer 4: Identität
  final Nip05Result? nip05;
  final int? platformProofCount;
  final Map<String, dynamic>? platformProofs; // NEU: Volle Plattform-Details
  final int? accountAgeDays;

  // Gesamtscore
  final double? totalScore;

  const ReputationLayersWidget({
    super.key,
    this.badgeCount,
    this.boundBadges,
    this.meetupCount,
    this.signerCount,
    this.meetupScore,
    this.since,
    this.zapStats,
    this.humanityVerified = false,
    this.socialAnalysis,
    this.nip05,
    this.platformProofCount,
    this.platformProofs, // NEU
    this.accountAgeDays,
    this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gesamtscore Header
        if (totalScore != null)
          _buildTotalScoreHeader(),

        const SizedBox(height: 16),

        // Layer 1: Physischer Beweis
        _buildLayer(
          icon: Icons.nfc,
          title: "PHYSISCHER BEWEIS",
          subtitle: "Meetup-Badges & Anwesenheit",
          color: cOrange,
          weight: "40%",
          score: _physicalScore,
          children: [
            if (badgeCount != null)
              _buildDetail(Icons.military_tech, "$badgeCount Badges", 
                boundBadges != null && boundBadges! > 0 
                    ? "$boundBadges gebunden" 
                    : "Nicht gebunden",
                boundBadges != null && boundBadges == badgeCount 
                    ? Colors.green : Colors.grey),
            if (meetupCount != null)
              _buildDetail(Icons.location_on, "$meetupCount Meetups",
                "Verschiedene Standorte", cCyan),
            if (signerCount != null)
              _buildDetail(Icons.people_outline, "$signerCount Signer",
                "Verschiedene Organisatoren", cPurple),
            if (since != null && since!.isNotEmpty)
              _buildDetail(Icons.calendar_today, "Seit $since",
                "${accountAgeDays ?? 0} Tage", Colors.green),
          ],
        ),

        const SizedBox(height: 12),

        // Layer 2: Lightning-Beweis
        _buildLayer(
          icon: Icons.bolt,
          title: "LIGHTNING-BEWEIS",
          subtitle: "Zap-Aktivität & Zahlungen",
          color: Colors.amber,
          weight: "25%",
          score: zapStats?.lightningScore,
          children: zapStats != null && zapStats!.totalCount > 0
              ? [
                  if (humanityVerified)
                    _buildDetail(Icons.verified_user, "Mensch verifiziert",
                      "21-Sat Lightning-Beweis aktiv", Colors.green),
                  _buildDetail(Icons.arrow_upward, "${zapStats!.sentCount} gesendet",
                    "${zapStats!.uniqueRecipientCount} verschiedene Empfänger",
                    zapStats!.sentCount > 5 ? Colors.green : Colors.grey),
                  _buildDetail(Icons.arrow_downward, "${zapStats!.receivedCount} empfangen",
                    "${zapStats!.uniqueSenderCount} verschiedene Sender",
                    zapStats!.receivedCount > 0 ? Colors.green : Colors.grey),
                  if (zapStats!.activeMonths > 0)
                    _buildDetail(Icons.schedule, "${zapStats!.activeMonths} Monate aktiv",
                      zapStats!.activityLabel, Colors.amber),
                  if (zapStats!.hasLightningProof)
                    _buildDetail(Icons.check_circle, "Lightning verifiziert",
                      "Echte Zahlung nachgewiesen", Colors.green),
                ]
              : humanityVerified
                  ? [
                      _buildDetail(Icons.verified_user, "Mensch verifiziert",
                        "21-Sat Lightning-Beweis aktiv", Colors.green),
                    ]
                  : [
                      _buildDetail(Icons.info_outline, "Keine Zap-Aktivität",
                        "Keine Lightning-Zahlungen gefunden", Colors.grey),
                    ],
        ),

        const SizedBox(height: 12),

        // Layer 3: Sozialer Beweis
        _buildLayer(
          icon: Icons.hub,
          title: "SOZIALER BEWEIS",
          subtitle: "Nostr-Netzwerk & Verbindungen",
          color: cCyan,
          weight: "25%",
          score: socialAnalysis?.socialScore,
          children: socialAnalysis != null
              ? [
                  // Direkte Verbindung
                  if (socialAnalysis!.isMutual)
                    _buildDetail(Icons.sync_alt, "Gegenseitiger Follow",
                      "Direkte bidirektionale Verbindung", Colors.green)
                  else if (socialAnalysis!.iFollow)
                    _buildDetail(Icons.person_add, "Du folgst",
                      "Einseitige Verbindung", cCyan)
                  else if (socialAnalysis!.followsMe)
                    _buildDetail(Icons.person, "Folgt dir",
                      "Einseitige Verbindung", cCyan)
                  else
                    _buildDetail(Icons.person_off, "Kein direkter Follow",
                      "", Colors.grey),

                  // Gemeinsame Kontakte
                  _buildDetail(Icons.group, "${socialAnalysis!.commonContactCount} gemeinsame Kontakte",
                    socialAnalysis!.commonContactCount > 3
                        ? "Starke Netzwerk-Überlappung"
                        : socialAnalysis!.commonContactCount > 0
                            ? "Teilweise verbunden"
                            : "Keine Überlappung",
                    socialAnalysis!.commonContactCount > 0 ? Colors.green : Colors.grey),

                  // Organisator-Follows
                  if (socialAnalysis!.orgFollowerCount > 0)
                    _buildDetail(Icons.verified_user, "${socialAnalysis!.orgFollowerCount} Organisatoren folgen",
                      "Endorsement von bekannten Admins", Colors.green),

                  // Hop-Distanz
                  if (socialAnalysis!.hops > 0)
                    _buildDetail(Icons.route, "${socialAnalysis!.hops} Hop${socialAnalysis!.hops > 1 ? 's' : ''} entfernt",
                      socialAnalysis!.hops == 1 ? "Direkte Verbindung" : "Über gemeinsame Kontakte",
                      socialAnalysis!.hops == 1 ? Colors.green : Colors.amber),
                ]
              : [
                  _buildDetail(Icons.info_outline, "Social-Graph nicht geladen",
                    "Nostr-Kontakte werden analysiert...", Colors.grey),
                ],
        ),

        const SizedBox(height: 12),

        // Layer 4: Identitäts-Beweis
        _buildLayer(
          icon: Icons.fingerprint,
          title: "IDENTITÄTS-BEWEIS",
          subtitle: "NIP-05, Plattform-Verknüpfung, Alter",
          color: Colors.purple,
          weight: "10%",
          score: _identityScore,
          children: [
            // NIP-05 Status
            if (nip05 != null && nip05!.valid)
              _buildDetail(Icons.verified, nip05!.nip05,
                nip05!.domainLabel, Colors.green)
            else if (nip05 != null)
              _buildDetail(Icons.cancel, "NIP-05 ungültig",
                nip05!.nip05, Colors.red)
            else
              _buildDetail(Icons.help_outline, "Kein NIP-05",
                "Keine Internet-Identifikation", Colors.grey),

            // ========================================
            // NEU: Plattform-Proofs einzeln mit Handle
            // ========================================
            if (platformProofs != null && platformProofs!.isNotEmpty)
              ..._buildPlatformProofDetails()
            else if (platformProofCount != null && platformProofCount! > 0)
              // Fallback: Nur Anzahl (Abwärtskompatibilität)
              _buildDetail(Icons.link, "$platformProofCount Plattform${platformProofCount! > 1 ? 'en' : ''}",
                "Aktive Verknüpfungen", Colors.green),
          ],
        ),
      ],
    );
  }

  // =============================================
  // GESAMTSCORE HEADER
  // =============================================

  Widget _buildTotalScoreHeader() {
    // Layer-Scores zusammenrechnen (gewichtet)
    final physical = (_physicalScore ?? 0) * 0.4;
    final lightning = (zapStats?.lightningScore ?? 0) * 0.25;
    final social = (socialAnalysis?.socialScore ?? 0) * 0.25;
    final identity = (_identityScore ?? 0) * 0.1;

    final combined = (physical + lightning + social + identity).clamp(0.0, 10.0);
    final layerCount = [
      _physicalScore != null && _physicalScore! > 0,
      zapStats != null && zapStats!.totalCount > 0,
      socialAnalysis != null && socialAnalysis!.socialScore > 0,
      _identityScore != null && _identityScore! > 0,
    ].where((b) => b).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Score-Kreis
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [cOrange, Colors.amber],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                combined.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("MULTI-LAYER SCORE",
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text("$layerCount von 4 Beweis-Layern aktiv",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // LAYER CARD
  // =============================================

  Widget _buildLayer({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String weight,
    double? score,
    required List<Widget> children,
  }) {
    final hasData = score != null && score > 0;

    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasData ? color.withOpacity(0.3) : Colors.white10),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.dark(primary: color),
        ),
        child: ExpansionTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(hasData ? 0.15 : 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: hasData ? color : Colors.grey, size: 20),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(title,
                  style: TextStyle(
                    color: hasData ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  )),
              ),
              // Score Badge
              if (score != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // DETAIL-ZEILE
  // =============================================

  Widget _buildDetail(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PLATTFORM-PROOF DETAILS (NEU)
  // =============================================
  // Zeigt jede verknüpfte Plattform einzeln an
  // mit Icon, Plattformname und @Handle.
  //
  // Daten kommen aus dem Reputation-Event:
  //   platform_proofs: {
  //     "telegram": {"username": "satoshi", "proof_sig": "abc...", "created_at": 1234},
  //     "robosats": {"username": "robot42", "proof_sig": "def...", "created_at": 5678},
  //   }
  // =============================================

  List<Widget> _buildPlatformProofDetails() {
    if (platformProofs == null || platformProofs!.isEmpty) return [];

    return platformProofs!.entries.map((entry) {
      final platform = entry.key;
      final data = entry.value as Map<String, dynamic>? ?? {};
      final username = data['username'] as String? ?? '';
      final hasSig = (data['proof_sig'] as String? ?? '').isNotEmpty;

      return _buildDetail(
        _platformIcon(platform),
        '${_platformLabel(platform)}${username.isNotEmpty ? ': @$username' : ''}',
        hasSig ? 'Signatur verifiziert' : 'Verknüpft',
        hasSig ? Colors.green : Colors.amber,
      );
    }).toList();
  }

  /// Icon für bekannte Plattformen
  /// (Muss mit PlatformProofService.platforms übereinstimmen)
  IconData _platformIcon(String platform) {
    switch (platform) {
      case 'telegram': return Icons.send;
      case 'satoshikleinanzeigen': return Icons.shopping_cart;
      case 'robosats': return Icons.smart_toy;
      case 'nostr': return Icons.hub;
      default: return Icons.language;
    }
  }

  /// Anzeigename für bekannte Plattformen
  String _platformLabel(String platform) {
    switch (platform) {
      case 'telegram': return 'Telegram';
      case 'satoshikleinanzeigen': return 'Satoshi-Kleinanzeigen';
      case 'robosats': return 'RoboSats';
      case 'nostr': return 'Nostr';
      case 'other': return 'Andere';
      default: return platform;
    }
  }

  // =============================================
  // BERECHNETE SCORES
  // =============================================

  double? get _physicalScore {
    if (badgeCount == null || badgeCount == 0) return null;
    double score = 0;
    // Badges (max 3.0)
    score += (badgeCount! / (badgeCount! + 5)) * 3.0;
    // Meetup-Diversität (max 2.0)
    if (meetupCount != null) score += (meetupCount! / (meetupCount! + 3)) * 2.0;
    // Signer-Diversität (max 2.0)
    if (signerCount != null) score += (signerCount! / (signerCount! + 3)) * 2.0;
    // Binding-Bonus (max 1.0)
    if (boundBadges != null && badgeCount! > 0) {
      score += (boundBadges! / badgeCount!) * 1.0;
    }
    return score.clamp(0.0, 8.0);
  }

  double? get _identityScore {
    double score = 0;
    if (nip05 != null && nip05!.valid) {
      score += Nip05Service.score(nip05!);
    }
    if (platformProofCount != null && platformProofCount! > 0) {
      score += (platformProofCount! * 0.3).clamp(0.0, 0.5);
    }
    if (accountAgeDays != null && accountAgeDays! > 30) {
      score += 0.5;
    }
    return score > 0 ? score.clamp(0.0, 2.0) : null;
  }
}