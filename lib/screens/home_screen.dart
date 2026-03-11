// ============================================================
// HOME SCREEN — Redesign
// ============================================================
// Ersetzt dashboard.dart als Tab 0 in der AppShell.
// ALLE LOGIK IST IDENTISCH — nur die build()-Methode und
// die Widget-Builder sind visuell überarbeitet.
//
// Änderungen:
//   - Kein AppBar mehr (Header ist Teil des ScrollView)
//   - Horizontale Schnellzugriff-Leiste statt 2x2 Grid
//   - Stacked Cards statt Grid-Tiles
//   - Glassmorphism-Effekte
//   - Staggered Fade-In Animation
//   - Ambient Gradient im Hintergrund
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../services/meetup_service.dart';
import '../services/trust_score_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../services/badge_claim_service.dart';
import '../services/reputation_publisher.dart';
import '../services/rolling_qr_service.dart';
import '../widgets/glass_card.dart';
import 'meetup_verification.dart';
import 'meetup_selection.dart';
import 'badge_details.dart';
import 'badge_wallet.dart';
import 'profile_edit.dart';
import 'intro.dart';
import 'admin_panel.dart';
import 'rolling_qr_screen.dart';
import 'community_portal_screen.dart';
import 'meetup_details.dart';
import 'reputation_qr.dart';
import 'relay_settings_screen.dart';
import 'calendar_screen.dart';
import '../services/backup_service.dart';
import '../services/promotion_claim_service.dart';
import '../services/secure_key_store.dart';
import '../services/admin_status_verifier.dart';
import '../services/platform_proof_service.dart';
import '../services/humanity_proof_service.dart';
import '../services/nip05_service.dart';
import '../services/app_logger.dart';
import '../services/device_integrity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ============================================================
  // STATE — 1:1 aus dashboard.dart übernommen
  // ============================================================
  UserProfile _user = UserProfile();
  Meetup? _homeMeetup;
  TrustScore? _trustScore;
  bool _justPromoted = false;

  int _platformProofCount = 0;
  bool _humanityVerified = false;
  bool _nip05Verified = false;
  List<String> _platformNames = [];

  MeetupSession? _activeSession;
  Timer? _sessionTimer;
  String _sessionTimeLeft = '';

  bool _deviceCompromised = false;
  bool _dismissedIntegrityWarning = false;

  // NEU: Animationen
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Staggered Fade-In
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    // Pulse für aktive Session
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _loadAll();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Wird von AppShell nach einem Badge-Scan aufgerufen.
  void refreshAfterScan() {
    _loadBadges();
    _calculateTrustScore();
  }

  // ============================================================
  // BUSINESS LOGIC — 1:1 aus dashboard.dart (unverändert)
  // ============================================================

  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) {
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
        );
        await _loadUser();
      }
    }
    await _loadBadges();
    await _calculateTrustScore();
    await _reVerifyAdminStatus();
    _loadIdentityData();
    _checkActiveSession();
    _syncOrganicAdminsInBackground();
    _checkDeviceIntegrity();

    // Animation starten nachdem Daten geladen sind
    if (mounted) _fadeController.forward();
  }

  void _loadIdentityData() async {
    try {
      final proofs = await PlatformProofService.getSavedProofs();
      var humanity = await HumanityProofService.getStatus();
      if (humanity.needsReverification) {
        final reverified = await HumanityProofService.reverifyIfNeeded();
        if (reverified) humanity = await HumanityProofService.getStatus();
      }
      bool nip05 = false;
      if (_user.hasNostrKey && _user.nostrNpub.isNotEmpty) {
        try {
          final relays = ['wss://relay.damus.io', 'wss://nos.lol'];
          final pubkeyHex = Nip19.decodePubkey(_user.nostrNpub);
          final nip05Str = await Nip05Service.fetchNip05FromProfile(pubkeyHex, relays)
              .timeout(const Duration(seconds: 8), onTimeout: () => null);
          if (nip05Str != null && nip05Str.isNotEmpty) {
            final result = await Nip05Service.verify(nip05Str, pubkeyHex);
            nip05 = result.valid;
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _platformProofCount = proofs.length;
          _platformNames = proofs.map((p) => p.platform).toList();
          _humanityVerified = humanity.verified;
          _nip05Verified = nip05;
        });
      }
    } catch (_) {}
  }

  void _checkActiveSession() async {
    final session = await RollingQRService.loadSession();
    if (session != null && !session.isExpired) {
      setState(() => _activeSession = session);
      _startSessionTimer();
    } else {
      _sessionTimer?.cancel();
      if (mounted) setState(() => _activeSession = null);
    }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession == null || _activeSession!.isExpired) {
        _sessionTimer?.cancel();
        if (mounted) setState(() => _activeSession = null);
        return;
      }
      if (mounted) {
        setState(() {
          final r = _activeSession!.remainingTime;
          _sessionTimeLeft = '${r.inHours}h ${(r.inMinutes % 60).toString().padLeft(2, '0')}m';
        });
      }
    });
  }

  void _syncOrganicAdminsInBackground() async {
    try {
      await PromotionClaimService.syncOrganicAdmins();
    } catch (_) {}
  }

  void _checkDeviceIntegrity() async {
    try {
      final report = await DeviceIntegrityService.check();
      if (report.isCompromised && mounted) {
        setState(() => _deviceCompromised = true);
      }
    } catch (_) {}
  }

  Future<void> _loadBadges() async {
    final badges = await MeetupBadge.loadBadges();
    final claimedCount = await BadgeClaimService.ensureBadgesClaimed(badges);
    if (claimedCount > 0) {
      AppLogger.debug('Home', '$claimedCount Badges retroaktiv gebunden');
    }
    setState(() {
      myBadges.clear();
      myBadges.addAll(badges);
    });
    if (badges.isNotEmpty) {
      ReputationPublisher.publishInBackground(badges);
    }
  }

  Future<void> _loadUser() async {
    final u = await UserProfile.load();
    Meetup? homeMeetup;
    if (u.homeMeetupId.isNotEmpty) {
      List<Meetup> meetups = await MeetupService.fetchMeetups();
      if (meetups.isEmpty) meetups = allMeetups;
      homeMeetup = meetups.where((m) => m.city == u.homeMeetupId).firstOrNull;
    }
    if (mounted) {
      setState(() {
        _user = u;
        _homeMeetup = homeMeetup;
      });
    }
  }

  Future<void> _calculateTrustScore() async {
    if (myBadges.isEmpty) {
      setState(() {
        _trustScore = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null);
      });
      return;
    }
    final sortedByDate = List<MeetupBadge>.from(myBadges)
      ..sort((a, b) => a.date.compareTo(b.date));
    final firstBadgeDate = sortedByDate.first.date;
    final score = TrustScoreService.calculateScore(
      badges: myBadges,
      firstBadgeDate: firstBadgeDate,
      coAttestorMap: null,
    );
    setState(() => _trustScore = score);
  }

  Future<void> _reVerifyAdminStatus() async {
    try {
      final verification = await _user.reVerifyAdmin(myBadges);
      if (mounted) setState(() {});
      if (verification.isAdmin && verification.source == 'trust_score') {
        try {
          final meetupName = _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt';
          await PromotionClaimService.publishAdminClaim(
            badges: myBadges,
            meetupName: meetupName,
          );
        } catch (_) {}
        if (mounted) {
          setState(() => _justPromoted = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Du bist jetzt ORGANISATOR!"),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user.isAdmin = false;
          _user.isAdminVerified = false;
          _user.promotionSource = '';
        });
      }
    }
  }

  void _resetApp() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("App zurücksetzen?"),
        content: const Text("Alle Badges und dein Profil werden gelöscht. Stelle sicher, dass du ein Backup hast!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbruch")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    myBadges.clear();
    await MeetupBadge.saveBadges([]);
    try { await SecureKeyStore.deleteKeys(); } catch (_) {}
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IntroScreen()),
        (route) => false,
      );
    }
  }

  void _scanAnyMeetup() async {
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: dummy)),
    );
    _loadBadges();
    _calculateTrustScore();
  }

  void _selectHomeMeetup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetupSelectionScreen()));
    _loadUser();
  }

  static IconData _levelIcon(String level) {
    switch (level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  // ============================================================
  // BUILD — KOMPLETT NEUES LAYOUT
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Ambient Gradient Hintergrund
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    cOrange.withOpacity(0.06),
                    cDark.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),

          // Hauptinhalt
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // ===== HEADER =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 16, 24, 0),
                  child: _buildHeader(),
                ),
              ),

              // ===== DEVICE WARNING =====
              if (_deviceCompromised && !_dismissedIntegrityWarning)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: _buildDeviceWarning(),
                  ),
                ),

              // ===== AKTIVE SESSION =====
              if (_activeSession != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildActiveSessionCard(),
                  ),
                ),

              // ===== TRUST SCORE HERO =====
              if (_trustScore != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _buildTrustScoreHero(),
                  ),
                ),

              // ===== HOME MEETUP =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _buildHomeMeetupCard(),
                ),
              ),

              // ===== SCHNELLZUGRIFF =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildQuickActions(),
                ),
              ),

              // ===== ENTDECKEN =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildDiscoverSection(),
                ),
              ),

              // Bottom Padding für Navigation Bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER — Gruß + Settings
  // ============================================================
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hallo,",
                style: TextStyle(
                  color: cTextSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _user.nickname,
                style: const TextStyle(
                  color: cText,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Action-Buttons
        Row(
          children: [
            _buildHeaderButton(
              Icons.help_outline_rounded,
              onTap: _showHelpSheet,
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              Icons.settings_rounded,
              onTap: _showSettings,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cGlass,
          shape: BoxShape.circle,
          border: Border.all(color: cGlassBorder, width: 0.5),
        ),
        child: Icon(icon, color: cTextSecondary, size: 18),
      ),
    );
  }

  // ============================================================
  // TRUST SCORE HERO — Großes prominentes Widget
  // ============================================================
  Widget _buildTrustScoreHero() {
    final score = _trustScore!;

    Color levelColor;
    switch (score.level) {
      case 'VETERAN': levelColor = Colors.amber; break;
      case 'ETABLIERT': levelColor = Colors.green; break;
      case 'AKTIV': levelColor = cCyan; break;
      case 'STARTER': levelColor = cOrange; break;
      default: levelColor = Colors.grey;
    }

    final identityCount = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    final hasIdentityGaps = _platformProofCount == 0 || !_humanityVerified || !_nip05Verified;

    return GlassCard(
      borderColor: levelColor.withOpacity(0.3),
      glowing: score.level == 'VETERAN' || score.level == 'ETABLIERT',
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Oberer Bereich: Score + Level
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
            child: Row(
              children: [
                // Level Badge
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        levelColor.withOpacity(0.2),
                        levelColor.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: levelColor.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(_levelIcon(score.level), color: levelColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Level Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            score.level,
                            style: TextStyle(
                              color: levelColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (score.meetsPromotionThreshold) ...[
                            const SizedBox(width: 8),
                            StatusChip(
                              label: 'ORGANISATOR',
                              color: Colors.green,
                              icon: Icons.verified,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${score.totalBadges} Badges · ${score.uniqueMeetups} Meetups · ${score.uniqueSigners} Signers",
                        style: TextStyle(color: cTextTertiary, fontSize: 11, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
                // Score Number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      score.totalScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                        height: 1,
                      ),
                    ),
                    Text(
                      'SCORE',
                      style: TextStyle(
                        color: levelColor.withOpacity(0.5),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Bar (wenn noch nicht Organisator)
          if (!score.meetsPromotionThreshold)
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: score.promotionProgress,
                      backgroundColor: cGlass,
                      valueColor: AlwaysStoppedAnimation(levelColor.withOpacity(0.8)),
                      minHeight: 5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(score.promotionProgress * 100).toInt()}% zum Organisator',
                        style: TextStyle(color: cTextTertiary, fontSize: 10),
                      ),
                      GestureDetector(
                        onTap: _showScoreInfoSheet,
                        child: Text(
                          'Details →',
                          style: TextStyle(color: cOrange.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Identity Layer
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cGlass,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _buildIdDot(Icons.bolt, "Lightning", _humanityVerified,
                        _humanityVerified ? Colors.amber : null),
                    _buildIdDot(Icons.alternate_email, "NIP-05", _nip05Verified,
                        _nip05Verified ? cCyan : null),
                    ..._buildPlatformDots(),
                    if (_platformProofCount == 0)
                      _buildIdDot(Icons.link, "Plattform", false, null),
                  ],
                ),
                if (hasIdentityGaps) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                      );
                      _loadAll();
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: cOrange.withOpacity(0.5), size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Verknüpfe Plattformen für mehr Trust",
                            style: TextStyle(color: cOrange.withOpacity(0.6), fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AKTIVE SESSION CARD
  // ============================================================
  Widget _buildActiveSessionCard() {
    final session = _activeSession!;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = 0.15 + (_pulseController.value * 0.1);
        return GlassCard(
          borderColor: Colors.green.withOpacity(0.5),
          glowing: true,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RollingQRScreen()),
            );
            _checkActiveSession();
          },
          child: Row(
            children: [
              // Pulsierender Kreis
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(pulseValue),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_rounded, color: Colors.green, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const StatusChip(label: 'LIVE', color: Colors.green, icon: Icons.sensors),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      session.meetupName.isNotEmpty
                          ? session.meetupName.toUpperCase()
                          : "LAUFENDE SESSION",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Noch $_sessionTimeLeft",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.5), size: 16),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HOME MEETUP CARD — Modernisiert
  // ============================================================
  Widget _buildHomeMeetupCard() {
    final hasHome = _homeMeetup != null;
    final badgesHere = hasHome
        ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length
        : 0;

    if (!_user.homeMeetupId.isNotEmpty) {
      return GlassCard(
        onTap: _selectHomeMeetup,
        borderColor: cBorder,
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: cGlass,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.home_outlined, color: cTextTertiary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Home Meetup wählen",
                    style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text("Wähle dein Stammtisch-Meetup",
                    style: TextStyle(color: cTextTertiary, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 22),
          ],
        ),
      );
    }

    return GlassCard(
      borderColor: cOrange.withOpacity(0.2),
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Oberer Bereich
          GestureDetector(
            onTap: hasHome
                ? () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CalendarScreen(initialSearch: _homeMeetup!.city)))
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Row(
                children: [
                  // Meetup-Bild
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cOrange.withOpacity(0.15), cOrange.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cOrange.withOpacity(0.1), width: 0.5),
                    ),
                    child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              _homeMeetup!.coverImagePath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.home_rounded, color: cOrange, size: 24),
                            ),
                          )
                        : const Icon(Icons.home_rounded, color: cOrange, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatusChip(label: 'HOME', color: cOrange),
                        const SizedBox(height: 6),
                        Text(
                          hasHome ? _homeMeetup!.city.toUpperCase() : _user.homeMeetupId.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hasHome
                              ? [_homeMeetup!.country, if (badgesHere > 0) "$badgesHere Badge${badgesHere > 1 ? 's' : ''} hier"].join(' · ')
                              : "Lade...",
                          style: TextStyle(color: cTextTertiary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
                ],
              ),
            ),
          ),

          // Quick Actions
          if (hasHome)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  _buildMeetupAction(
                    icon: Icons.event_rounded,
                    label: "Termine",
                    color: cOrange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CalendarScreen(initialSearch: _homeMeetup!.city))),
                  ),
                  const SizedBox(width: 8),
                  _buildMeetupAction(
                    icon: Icons.info_outline_rounded,
                    label: "Details",
                    color: cTextTertiary,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => MeetupDetailsScreen(meetup: _homeMeetup!))),
                  ),
                  const SizedBox(width: 8),
                  _buildMeetupAction(
                    icon: Icons.swap_horiz_rounded,
                    label: "Ändern",
                    color: cTextTertiary,
                    onTap: _selectHomeMeetup,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeetupAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCHNELLZUGRIFF — Horizontale Liste statt Grid
  // ============================================================
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'SCHNELLZUGRIFF'),

        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              _buildActionCard(
                icon: Icons.workspace_premium_rounded,
                label: 'Reputation',
                subtitle: myBadges.isNotEmpty ? 'Teilen' : 'Prüfen',
                gradient: gradientOrange,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ReputationQRScreen())),
              ),
              const SizedBox(width: 12),
              _buildActionCard(
                icon: Icons.hub_rounded,
                label: 'Community',
                subtitle: 'Portal',
                gradient: gradientCyan,
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const CommunityPortalScreen())),
              ),
              if (_user.isAdmin) ...[
                const SizedBox(width: 12),
                _buildActionCard(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Organisator',
                  subtitle: _justPromoted ? 'Neu!' : 'Verwalten',
                  gradient: gradientPurple,
                  onTap: () async {
                    await Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const AdminPanelScreen()));
                    _checkActiveSession();
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              (gradient as LinearGradient).colors[0].withOpacity(0.15),
              (gradient).colors[1].withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: (gradient).colors[0].withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 14),
            Text(label, style: const TextStyle(
              color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(
              color: cTextTertiary, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ENTDECKEN — Badge-Übersicht + Stats
  // ============================================================
  Widget _buildDiscoverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'DEINE BADGES',
          actionLabel: myBadges.isNotEmpty ? 'Alle anzeigen →' : null,
          onAction: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BadgeWalletScreen()),
          ),
        ),

        if (myBadges.isEmpty)
          GlassCard(
            borderColor: cBorder,
            child: Column(
              children: [
                Icon(Icons.military_tech_rounded, color: cOrange.withOpacity(0.3), size: 48),
                const SizedBox(height: 14),
                const Text(
                  'Noch keine Badges',
                  style: TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Besuche ein Meetup und scanne den NFC-Tag oder QR-Code um dein erstes Badge zu erhalten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cTextTertiary, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _scanAnyMeetup,
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text('JETZT SCANNEN'),
                  ),
                ),
              ],
            ),
          )
        else
          _buildBadgePreview(),
      ],
    );
  }

  Widget _buildBadgePreview() {
    // Zeige die letzten 3 Badges als kompakte Liste
    final recentBadges = myBadges.take(3).toList();
    
    return Column(
      children: [
        ...recentBadges.map((badge) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderColor: cBorder,
            borderRadius: 14,
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (context) => BadgeDetailsScreen(badge: badge))),
            child: Row(
              children: [
                // Mini-Badge-Indikator
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cOrange.withOpacity(0.2), cOrange.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.military_tech_rounded, color: cOrange, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.meetupName.toUpperCase(),
                        style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.date,
                        style: TextStyle(color: cTextTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (badge.isBound)
                  Icon(Icons.link_rounded, color: cGreen.withOpacity(0.5), size: 16),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
              ],
            ),
          ),
        )),
        
        if (myBadges.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => BadgeWalletScreen())),
              child: Text(
                '+ ${myBadges.length - 3} weitere Badges',
                style: TextStyle(
                  color: cOrange.withOpacity(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // DEVICE WARNING
  // ============================================================
  Widget _buildDeviceWarning() {
    return GlassCard(
      borderColor: Colors.orange.withOpacity(0.5),
      padding: const EdgeInsets.all(14),
      borderRadius: 14,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              DeviceIntegrityService.warningMessage,
              style: TextStyle(color: Colors.orange.shade200, fontSize: 12, height: 1.3),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _dismissedIntegrityWarning = true),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.close, color: Colors.orange.shade300, size: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IDENTITY DOTS — Aus dashboard.dart übernommen
  // ============================================================
  Widget _buildIdDot(IconData icon, String label, bool active, Color? activeColor) {
    final color = active ? (activeColor ?? Colors.green) : cTextTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? color : cTextTertiary,
            fontSize: 11,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (active) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_circle, color: color, size: 11),
        ],
      ],
    );
  }

  List<Widget> _buildPlatformDots() {
    final iconMap = {
      'telegram': Icons.send,
      'twitter': Icons.alternate_email,
      'nostr': Icons.key,
      'kleinanzeigen': Icons.storefront,
    };
    final labelMap = {
      'telegram': 'Telegram',
      'twitter': 'X',
      'nostr': 'NIP-05',
      'kleinanzeigen': 'Kleinanzeigen',
    };
    return _platformNames.map<Widget>((name) {
      return _buildIdDot(
        iconMap[name.toLowerCase()] ?? Icons.link,
        labelMap[name.toLowerCase()] ?? name,
        true,
        Colors.green,
      );
    }).toList();
  }

  // ============================================================
  // BOTTOM SHEETS — Aus dashboard.dart übernommen (Logik 1:1)
  // ============================================================

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 24),
              const Text("SO FUNKTIONIERT'S",
                style: TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 20),
              _helpSection(icon: Icons.military_tech, color: cOrange, title: "BADGES SAMMELN",
                text: "Geh zu einem Einundzwanzig-Meetup und scanne den NFC-Tag oder Rolling-QR-Code des Organisators. "
                    "Für jeden Besuch bekommst du ein kryptographisch signiertes Badge."),
              _helpSection(icon: Icons.workspace_premium, color: Colors.amber, title: "REPUTATION AUFBAUEN",
                text: "Dein Trust Score steigt mit jedem Badge. Er berücksichtigt verschiedene Meetups, verschiedene Organisatoren, "
                    "und die Regelmäßigkeit deiner Teilnahme."),
              _helpSection(icon: Icons.admin_panel_settings, color: Colors.green, title: "ORGANISATOR WERDEN",
                text: "Ab einem bestimmten Trust Score wirst du automatisch zum Organisator befördert. "
                    "Dann kannst du selbst NFC-Tags und QR-Codes für dein eigenes Meetup erstellen."),
              _helpSection(icon: Icons.verified_user, color: cCyan, title: "KRYPTOGRAPHISCHE SICHERHEIT",
                text: "Jedes Badge enthält eine BIP-340 Schnorr-Signatur. Niemand kann Badges fälschen — auch wir nicht."),
              _helpSection(icon: Icons.qr_code_scanner, color: cPurple, title: "REPUTATION PRÜFEN",
                text: "Unter 'Reputation' kannst du deinen QR-Code teilen. Andere können ihn scannen und sehen dein Trust Level."),
              _helpSection(icon: Icons.upload, color: Colors.blue, title: "BACKUP",
                text: "Sichere deinen Account über die Einstellungen. Das Backup enthält deinen Nostr-Key und alle Badges."),
              const SizedBox(height: 16),
              const Divider(color: cBorder),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.lock_outline, color: cTextTertiary, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  "Alle Daten bleiben auf deinem Gerät. Kein Account, kein Server, kein Tracking.",
                  style: TextStyle(color: cTextTertiary, fontSize: 12, height: 1.4),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpSection({required IconData icon, required Color color, required String title, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),

            _settingsSection("DATENSICHERUNG"),
            _settingsTile(
              icon: Icons.upload_rounded, color: Colors.blue,
              title: "Backup erstellen",
              subtitle: "Sichere deinen Account als Datei",
              onTap: () async {
                Navigator.pop(context);
                await BackupService.createBackup(context);
              },
            ),

            const SizedBox(height: 16),
            _settingsSection("NOSTR-NETZWERK"),
            _settingsTile(
              icon: Icons.hub_rounded, color: cCyan,
              title: "Nostr-Relays",
              subtitle: "Relays für Reputation konfigurieren",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RelaySettingsScreen()));
              },
            ),

            const SizedBox(height: 16),
            _settingsSection("ACCOUNT"),
            _settingsTile(
              icon: Icons.delete_forever_rounded, color: Colors.red,
              title: "App zurücksetzen",
              subtitle: "Löscht Profil und Badges vom Gerät",
              onTap: () {
                Navigator.pop(context);
                _resetApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: TextStyle(
        color: cTextTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: cTextTertiary, fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ============================================================
  // SCORE INFO SHEET — Aus dashboard.dart (Logik 1:1)
  // ============================================================
  void _showScoreInfoSheet() {
    final score = _trustScore;
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 20),
              const Text("DEIN TRUST SCORE",
                style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(
                "Der Trust Score misst deine Vertrauenswürdigkeit in der Bitcoin-Community. "
                "Er basiert auf kryptographischen Beweisen.",
                style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Text("TRUST LEVEL",
                style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _scoreLevel(Icons.fiber_new, "NEU", "Score < 3", Colors.grey,
                "Startlevel. Besuche Meetups um Badges zu sammeln.",
                isActive: score != null && score.level == 'NEU'),
              _scoreLevel(Icons.eco, "STARTER", "Score 3 – 9", cOrange,
                "Du bist dabei. Deine ersten Badges zeigen Community-Teilnahme.",
                isActive: score != null && score.level == 'STARTER'),
              _scoreLevel(Icons.local_fire_department, "AKTIV", "Score 10 – 19", cCyan,
                "Regelmäßiger Teilnehmer mit verschiedenen Meetups und Organisatoren.",
                isActive: score != null && score.level == 'AKTIV'),
              _scoreLevel(Icons.shield, "ETABLIERT", "Score 20 – 39", Colors.green,
                "Vertrauenswürdiges Community-Mitglied. Breit vernetzt und lange dabei.",
                isActive: score != null && score.level == 'ETABLIERT'),
              _scoreLevel(Icons.bolt, "VETERAN", "Score 40+", Colors.amber,
                "Höchstes Trust Level. Reputation über Monate bewiesen.",
                isActive: score != null && score.level == 'VETERAN'),

              const SizedBox(height: 24),
              const Divider(color: cBorder),
              const SizedBox(height: 16),

              const Text("BERECHNUNG",
                style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              _scoreFactorTile(Icons.military_tech, cOrange, "Meetup-Badges",
                "Jedes Badge hat einen Basiswert. Gut besuchte Meetups sind mehr wert."),
              _scoreFactorTile(Icons.location_on, cCyan, "Diversität",
                "Badges aus verschiedenen Städten und von verschiedenen Organisatoren zählen mehr."),
              _scoreFactorTile(Icons.people_outline, cPurple, "Verschiedene Organisatoren",
                "Mehrere unabhängige Signer beweisen breite Vernetzung."),
              _scoreFactorTile(Icons.schedule, Colors.green, "Regelmäßigkeit & Alter",
                "Ältere Accounts mit regelmäßiger Teilnahme bekommen einen Reife-Bonus."),
              _scoreFactorTile(Icons.speed, cRed, "Frequency Cap",
                "Max. 2 Badges pro Woche zählen — verhindert Badge-Farming."),

              const SizedBox(height: 24),
              const Divider(color: cBorder),
              const SizedBox(height: 16),

              const Text("ORGANISATOR WERDEN",
                style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 12),
              Text(
                "Wenn dein Trust Score hoch genug ist, wirst du automatisch befördert.",
                style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),

              if (score != null && !score.meetsPromotionThreshold) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cOrange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cOrange.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("FORTSCHRITT (${score.activeThresholds.name})",
                        style: TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      const SizedBox(height: 10),
                      ...score.progress.entries.map((entry) => _progressRow(entry.value)),
                    ],
                  ),
                ),
              ] else if (score != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      "Du bist bereits Organisator!",
                      style: TextStyle(color: Colors.green.shade300, fontSize: 13),
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- Score Info Sheet Helpers ---

  Widget _scoreLevel(IconData icon, String name, String range, Color color, String description, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isActive ? Border.all(color: color.withOpacity(0.2)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: color.withOpacity(isActive ? 0.15 : 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? color : color.withOpacity(0.4), size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(name, style: TextStyle(
                    color: isActive ? color : cTextSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(range, style: TextStyle(color: cTextTertiary, fontSize: 11)),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    StatusChip(label: 'DU', color: color),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(description, style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.3)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _scoreFactorTile(IconData icon, Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(description, style: TextStyle(color: cTextTertiary, fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _progressRow(PromotionProgress p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(
          p.met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: p.met ? Colors.green : cTextTertiary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(
          "${p.label}: ${p.current}/${p.required}",
          style: TextStyle(
            color: p.met ? Colors.green.shade300 : cTextSecondary,
            fontSize: 12,
            fontWeight: p.met ? FontWeight.w600 : FontWeight.normal,
          ),
        )),
        SizedBox(
          width: 40, height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p.percentage,
              backgroundColor: cGlass,
              valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange),
            ),
          ),
        ),
      ]),
    );
  }
}