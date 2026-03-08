// ============================================
// PATCH 03: reputation_layers_widget.dart
// KOMPLETT NEUE VERSION — Verständliche UX
// ============================================
//
// ÄNDERUNG: Komplettes Redesign des Multi-Layer-Widgets
// für sofortige Verständlichkeit.
//
// VORHER:
//   - Technische Darstellung (Score-Zahlen, Layer-Gewichtung)
//   - User muss verstehen was "25% Social" bedeutet
//   - Keine Handlungsempfehlung
//
// JETZT:
//   1. VERTRAUENS-AMPEL oben: Rot/Gelb/Grün mit einem Satz
//   2. Jeder Layer hat ein klares "Was bedeutet das?" Label
//   3. Fehlende Layer zeigen "Warum das wichtig ist"
//   4. Konkrete Handlungsempfehlung am Ende
//
// ERSETZE: Die komplette Datei
//   lib/widgets/reputation_layers_widget.dart
//
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
  final Map<String, dynamic>? platformProofs;
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
    this.platformProofs,
    this.accountAgeDays,
    this.totalScore,
  });

  // =============================================
  // SCORES BERECHNEN
  // =============================================

  double? get _physicalScore {
    if (badgeCount == null || badgeCount == 0) return null;
    double score = 0;
    score += (badgeCount! / (badgeCount! + 5)) * 3.0;
    if (meetupCount != null) score += (meetupCount! / (meetupCount! + 3)) * 2.0;
    if (signerCount != null) score += (signerCount! / (signerCount! + 3)) * 2.0;
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

  // =============================================
  // VERTRAUENS-STUFE BERECHNEN
  // =============================================

  /// Wie viele der 4 Layer sind aktiv (Score > 0)?
  int get _activeLayerCount {
    int count = 0;
    if (_physicalScore != null && _physicalScore! > 0) count++;
    if (zapStats != null && zapStats!.totalCount > 0 || humanityVerified) count++;
    if (socialAnalysis != null && socialAnalysis!.socialScore > 0) count++;
    if (_identityScore != null && _identityScore! > 0) count++;
    return count;
  }

  /// Gesamt-Score (gewichtet)
  double get _combinedScore {
    final physical = (_physicalScore ?? 0) * 0.4;
    final lightning = (zapStats?.lightningScore ?? 0) * 0.25;
    final social = (socialAnalysis?.socialScore ?? 0) * 0.25;
    final identity = (_identityScore ?? 0) * 0.1;
    return (physical + lightning + social + identity).clamp(0.0, 10.0);
  }

  /// Vertrauens-Stufe als Ampel
  _TrustSignal get _trustSignal {
    final layers = _activeLayerCount;
    final score = _combinedScore;

    // Nur Badges, nichts anderes → Warnung
    if (layers <= 1 && score < 3.0) {
      return _TrustSignal(
        color: Colors.red.shade400,
        icon: Icons.warning_amber_rounded,
        label: 'Schwaches Profil',
        explanation: 'Nur ein Beweis-Layer aktiv. '
            'Dieser Nutzer hat kaum nachprüfbare Verbindungen. '
            'Bei größeren Transaktionen: Vorsicht.',
        actionHint: 'Frage nach weiteren Beweisen (Lightning, NIP-05) '
            'oder triff die Person zuerst persönlich.',
      );
    }

    if (layers <= 1) {
      return _TrustSignal(
        color: Colors.orange,
        icon: Icons.info_outline,
        label: 'Eingeschränkt',
        explanation: 'Es gibt Meetup-Badges, aber keine weiteren '
            'unabhängigen Beweise. Der Nutzer könnte echt sein — '
            'aber es fehlt die Bestätigung durch andere Layer.',
        actionHint: 'Für Kleinstbeträge OK. Für größere Beträge: '
            'Abwarten bis mehr Layer aktiv sind.',
      );
    }

    if (layers == 2 && score < 4.0) {
      return _TrustSignal(
        color: Colors.amber,
        icon: Icons.shield_outlined,
        label: 'Aufbauend',
        explanation: 'Zwei Beweis-Layer aktiv. Der Nutzer baut '
            'Reputation auf, hat aber noch nicht die volle Breite.',
        actionHint: 'Für moderate Transaktionen geeignet.',
      );
    }

    if (layers >= 3 && score >= 4.0) {
      return _TrustSignal(
        color: Colors.green,
        icon: Icons.verified_user,
        label: 'Gut vernetzt',
        explanation: 'Mehrere unabhängige Beweise: Meetups, '
            'Lightning-Aktivität und soziale Verbindungen. '
            'Schwer zu faken.',
        actionHint: 'Vertrauenswürdig für die meisten Transaktionen.',
      );
    }

    if (layers >= 3 || score >= 5.0) {
      return _TrustSignal(
        color: Colors.green.shade300,
        icon: Icons.shield,
        label: 'Solide',
        explanation: 'Breite Basis an Beweisen. Manipulation wäre '
            'aufwändig und teuer.',
        actionHint: 'Für die meisten Zwecke vertrauenswürdig.',
      );
    }

    return _TrustSignal(
      color: Colors.amber,
      icon: Icons.shield_outlined,
      label: 'Aufbauend',
      explanation: 'Einige Beweise vorhanden, aber Raum für mehr.',
      actionHint: 'Eigene Einschätzung nutzen.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final signal = _trustSignal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // =============================================
        // VERTRAUENS-AMPEL — Das Erste was man sieht
        // =============================================
        _buildTrustSignalCard(signal),

        const SizedBox(height: 16),

        // =============================================
        // DIE 4 BEWEIS-LAYER
        // =============================================
        _buildPhysicalLayer(),
        const SizedBox(height: 10),
        _buildLightningLayer(),
        const SizedBox(height: 10),
        _buildSocialLayer(),
        const SizedBox(height: 10),
        _buildIdentityLayer(),

        // =============================================
        // HANDLUNGSEMPFEHLUNG
        // =============================================
        if (signal.actionHint.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildActionHint(signal),
        ],
      ],
    );
  }

  // =============================================
  // VERTRAUENS-AMPEL CARD
  // =============================================

  Widget _buildTrustSignalCard(_TrustSignal signal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: signal.color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Ampel-Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: signal.color.withOpacity(0.15),
              border: Border.all(color: signal.color.withOpacity(0.3)),
            ),
            child: Icon(signal.icon, color: signal.color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stufe + Layer-Count
                Row(
                  children: [
                    Text(
                      signal.label.toUpperCase(),
                      style: TextStyle(
                        color: signal.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_activeLayerCount / 4 Beweise',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  signal.explanation,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // LAYER 1: PHYSISCHER BEWEIS (Meetup-Badges)
  // =============================================

  Widget _buildPhysicalLayer() {
    final hasData = _physicalScore != null && _physicalScore! > 0;
    final bool hasDiversity = (signerCount ?? 0) >= 2;
    final bool hasBound = boundBadges != null && badgeCount != null && boundBadges == badgeCount;

    return _buildLayerCard(
      icon: Icons.nfc,
      color: cOrange,
      title: 'Meetup-Beweise',
      hasData: hasData,
      // Was bedeutet das?
      meaningWhenPresent: hasDiversity
          ? 'War bei verschiedenen Meetups mit verschiedenen Organisatoren. '
            'Das erfordert physische Anwesenheit an mehreren Orten.'
          : badgeCount != null && badgeCount! > 0
              ? 'Hat Meetup-Badges, aber nur von ${signerCount ?? 1} Organisator(en). '
                'Mehr Vielfalt wäre überzeugender.'
              : null,
      meaningWhenMissing: 'Keine Meetup-Badges vorhanden. '
          'Dieser Nutzer hat noch kein Einundzwanzig-Meetup besucht — '
          'oder nutzt die App erst seit kurzem.',
      details: hasData
          ? [
              _LayerDetail(
                label: '${badgeCount ?? 0} Badge${(badgeCount ?? 0) != 1 ? 's' : ''}',
                sublabel: hasBound
                    ? 'Alle kryptographisch gebunden'
                    : '${boundBadges ?? 0} von ${badgeCount ?? 0} gebunden',
                positive: hasBound,
              ),
              _LayerDetail(
                label: '${meetupCount ?? 0} verschiedene Meetups',
                sublabel: (meetupCount ?? 0) >= 3
                    ? 'Gute regionale Streuung'
                    : 'Wenig Streuung',
                positive: (meetupCount ?? 0) >= 2,
              ),
              _LayerDetail(
                label: '${signerCount ?? 0} Organisator${(signerCount ?? 0) != 1 ? 'en' : ''}',
                sublabel: hasDiversity
                    ? 'Von verschiedenen Personen bestätigt'
                    : 'Nur ein Organisator — wenig unabhängige Bestätigung',
                positive: hasDiversity,
              ),
              if (since != null && since!.isNotEmpty)
                _LayerDetail(
                  label: 'Dabei seit $since',
                  sublabel: '${accountAgeDays ?? 0} Tage',
                  positive: (accountAgeDays ?? 0) > 60,
                ),
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 2: LIGHTNING-BEWEIS
  // =============================================

  Widget _buildLightningLayer() {
    final hasZaps = zapStats != null && zapStats!.totalCount > 0;
    final hasData = hasZaps || humanityVerified;

    return _buildLayerCard(
      icon: Icons.bolt,
      color: Colors.amber,
      title: 'Lightning-Beweis',
      hasData: hasData,
      meaningWhenPresent: humanityVerified && hasZaps
          ? 'Hat echte Lightning-Zahlungen getätigt und empfangen. '
            'Bots haben keine Lightning-Wallets — das ist ein starkes Echtheitssignal.'
          : humanityVerified
              ? 'Hat mindestens einmal über Lightning gezahlt. '
                'Grundlegender Beweis dass eine echte Wallet existiert.'
              : 'Lightning-Aktivität vorhanden, '
                'aber Humanity-Proof noch nicht aktiv.',
      meaningWhenMissing: 'Keine Lightning-Aktivität. '
          'Das heißt nicht dass der Nutzer unecht ist — '
          'vielleicht nutzt er Lightning nicht über Nostr. '
          'Aber es fehlt ein wichtiges Anti-Bot-Signal.',
      details: hasData
          ? [
              if (humanityVerified)
                _LayerDetail(
                  label: 'Mensch verifiziert',
                  sublabel: 'Echte Lightning-Zahlung nachgewiesen',
                  positive: true,
                ),
              if (hasZaps) ...[
                _LayerDetail(
                  label: '${zapStats!.sentCount} Zaps gesendet',
                  sublabel: 'An ${zapStats!.uniqueRecipientCount} verschiedene Empfänger',
                  positive: zapStats!.uniqueRecipientCount > 3,
                ),
                _LayerDetail(
                  label: '${zapStats!.receivedCount} Zaps empfangen',
                  sublabel: 'Von ${zapStats!.uniqueSenderCount} verschiedenen Sendern',
                  positive: zapStats!.receivedCount > 0,
                ),
                if (zapStats!.activeMonths > 0)
                  _LayerDetail(
                    label: '${zapStats!.activeMonths} Monate aktiv',
                    sublabel: zapStats!.activityLabel,
                    positive: zapStats!.activeMonths >= 3,
                  ),
              ],
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 3: SOZIALER BEWEIS
  // =============================================

  Widget _buildSocialLayer() {
    final hasData = socialAnalysis != null && socialAnalysis!.socialScore > 0;
    final sa = socialAnalysis;

    String? meaning;
    if (sa != null) {
      if (sa.isMutual && sa.commonContactCount > 3) {
        meaning = 'Ihr kennt euch gegenseitig auf Nostr und habt viele '
            'gemeinsame Kontakte. Starke Verbindung.';
      } else if (sa.isMutual) {
        meaning = 'Gegenseitiger Follow — ihr kennt euch auf Nostr.';
      } else if (sa.commonContactCount > 5) {
        meaning = 'Viele gemeinsame Kontakte — ihr bewegt euch '
            'im selben Netzwerk.';
      } else if (sa.iFollow || sa.followsMe) {
        meaning = 'Einseitige Verbindung. Ihr kennt euch flüchtig.';
      } else if (sa.orgFollowerCount > 0) {
        meaning = 'Bekannte Einundzwanzig-Organisatoren folgen diesem Nutzer. '
            'Das ist ein positives Signal.';
      }
    }

    return _buildLayerCard(
      icon: Icons.hub,
      color: cCyan,
      title: 'Soziales Netzwerk',
      hasData: hasData,
      meaningWhenPresent: meaning ??
          'Es gibt Verbindungen im Nostr-Netzwerk zu diesem Nutzer.',
      meaningWhenMissing: 'Keine Verbindung im Nostr-Netzwerk gefunden. '
          'Das kann bedeuten: Ihr seid euch noch nie auf Nostr begegnet, '
          'oder der Nutzer ist sehr neu. '
          'Bei Fremden ist das normal — bei angeblich bekannten Gesichtern ein Warnsignal.',
      details: sa != null
          ? [
              // Direkte Verbindung
              _LayerDetail(
                label: sa.isMutual
                    ? 'Gegenseitiger Follow'
                    : sa.iFollow
                        ? 'Du folgst'
                        : sa.followsMe
                            ? 'Folgt dir'
                            : 'Kein Follow',
                sublabel: sa.isMutual
                    ? 'Ihr kennt euch auf Nostr'
                    : 'Keine direkte Verbindung',
                positive: sa.isMutual || sa.iFollow || sa.followsMe,
              ),
              // Gemeinsame Kontakte
              _LayerDetail(
                label: '${sa.commonContactCount} gemeinsame Kontakte',
                sublabel: sa.commonContactCount > 5
                    ? 'Gleiches Netzwerk'
                    : sa.commonContactCount > 0
                        ? 'Einige Überlappungen'
                        : 'Getrennte Netzwerke',
                positive: sa.commonContactCount > 0,
              ),
              // Organisator-Follows
              if (sa.orgFollowerCount > 0)
                _LayerDetail(
                  label: '${sa.orgFollowerCount} Organisatoren folgen',
                  sublabel: 'Endorsement von bekannten Admins',
                  positive: true,
                ),
            ]
          : [],
    );
  }

  // =============================================
  // LAYER 4: IDENTITÄTS-BEWEIS
  // =============================================

  Widget _buildIdentityLayer() {
    final hasNip05 = nip05 != null && nip05!.valid;
    final hasPlatforms = (platformProofCount ?? 0) > 0 ||
        (platformProofs != null && platformProofs!.isNotEmpty);
    final hasData = hasNip05 || hasPlatforms;

    return _buildLayerCard(
      icon: Icons.fingerprint,
      color: Colors.purple,
      title: 'Identitäts-Nachweis',
      hasData: hasData,
      meaningWhenPresent: hasNip05
          ? 'Hat eine NIP-05-Adresse${hasPlatforms ? ' und verknüpfte Plattformen' : ''}. '
            'Das verknüpft die Nostr-Identität mit einer Domain — '
            'schwerer zu faken als ein anonymer Account.'
          : 'Verknüpfte Plattform-Accounts. '
            'Mehr Plattformen = mehr Aufwand für Fälscher.',
      meaningWhenMissing: 'Keine Internet-Identifikation. '
          'Komplett anonym. Das ist für Privatsphäre OK, '
          'aber gibt auch weniger Anhaltspunkte für Vertrauen.',
      details: [
        if (hasNip05)
          _LayerDetail(
            label: nip05!.nip05,
            sublabel: nip05!.domainLabel,
            positive: true,
          ),
        if (platformProofs != null && platformProofs!.isNotEmpty)
          ...platformProofs!.entries.map((entry) {
            final data = entry.value as Map<String, dynamic>? ?? {};
            final username = data['username'] as String? ?? '';
            return _LayerDetail(
              label: '${_platformLabel(entry.key)}${username.isNotEmpty ? ': @$username' : ''}',
              sublabel: 'Verknüpft',
              positive: true,
            );
          }),
        if (!hasNip05 && !hasPlatforms)
          _LayerDetail(
            label: 'Keine Identifikation',
            sublabel: 'Anonym',
            positive: false,
          ),
      ],
    );
  }

  // =============================================
  // HANDLUNGSEMPFEHLUNG
  // =============================================

  Widget _buildActionHint(_TrustSignal signal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: signal.color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: signal.color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: signal.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              signal.actionHint,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // GENERISCHER LAYER-CARD BUILDER
  // =============================================

  Widget _buildLayerCard({
    required IconData icon,
    required Color color,
    required String title,
    required bool hasData,
    String? meaningWhenPresent,
    required String meaningWhenMissing,
    required List<_LayerDetail> details,
  }) {
    final meaning = hasData ? meaningWhenPresent : meaningWhenMissing;

    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasData ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
          colorScheme: ColorScheme.dark(primary: color),
        ),
        child: ExpansionTile(
          // Layer-Header
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
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: hasData ? Colors.white : Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              // Status-Chip: ✓ oder ✗
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: hasData
                      ? color.withOpacity(0.12)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hasData ? '✓ aktiv' : '— fehlt',
                  style: TextStyle(
                    color: hasData ? color : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          // Kurze Erklärung immer sichtbar
          subtitle: meaning != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    meaning,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          // Details im Aufklapp-Bereich
          children: details.isNotEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: details.map((d) => _buildDetailRow(d, color)).toList(),
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  // =============================================
  // DETAIL-ZEILE (in Aufklapp)
  // =============================================

  Widget _buildDetailRow(_LayerDetail detail, Color layerColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            detail.positive ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: detail.positive ? Colors.green.shade400 : Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail.sublabel.isNotEmpty)
                  Text(
                    detail.sublabel,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // PLATTFORM-LABELS
  // =============================================

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
}

// =============================================
// HILFSKLASSEN
// =============================================

class _TrustSignal {
  final Color color;
  final IconData icon;
  final String label;
  final String explanation;
  final String actionHint;

  _TrustSignal({
    required this.color,
    required this.icon,
    required this.label,
    required this.explanation,
    this.actionHint = '',
  });
}

class _LayerDetail {
  final String label;
  final String sublabel;
  final bool positive;

  _LayerDetail({
    required this.label,
    this.sublabel = '',
    this.positive = false,
  });
}