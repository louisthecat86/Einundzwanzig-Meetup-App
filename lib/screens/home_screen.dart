// ============================================================
// HOME SCREEN — Redesign v3 (Social Feed Style)
// ============================================================
// Design-Philosophie:
//   Weg vom "Dashboard mit Boxen" → hin zu einer fließenden,
//   intuitiven Social-App-Anmutung (Instagram/Facebook).
//
//   1. Top Bar: Brand + Icons (wie Instagram)
//   2. Stories-Row: Kreisförmige Actions (wie Instagram Stories)
//   3. Feed: Einheitliche, full-width Sektionen die fließen
//   4. Kein Kachel-Grid, keine verschachtelten Container
//   5. Konsistenter Rhythmus und Padding
//
// ALLE LOGIK IST 1:1 AUS dashboard.dart ÜBERNOMMEN.
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
  // STATE — 1:1 aus dashboard.dart
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

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _loadAll();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void refreshAfterScan() {
    _loadBadges();
    _calculateTrustScore();
  }

  // ============================================================
  // BUSINESS LOGIC — 1:1 aus dashboard.dart (UNVERÄNDERT)
  // ============================================================

  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
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
    try { await PromotionClaimService.syncOrganicAdmins(); } catch (_) {}
  }

  void _checkDeviceIntegrity() async {
    try {
      final report = await DeviceIntegrityService.check();
      if (report.isCompromised && mounted) setState(() => _deviceCompromised = true);
    } catch (_) {}
  }

  Future<void> _loadBadges() async {
    final badges = await MeetupBadge.loadBadges();
    await BadgeClaimService.ensureBadgesClaimed(badges);
    setState(() { myBadges.clear(); myBadges.addAll(badges); });
    if (badges.isNotEmpty) ReputationPublisher.publishInBackground(badges);
  }

  Future<void> _loadUser() async {
    final u = await UserProfile.load();
    Meetup? homeMeetup;
    if (u.homeMeetupId.isNotEmpty) {
      List<Meetup> meetups = await MeetupService.fetchMeetups();
      if (meetups.isEmpty) meetups = allMeetups;
      homeMeetup = meetups.where((m) => m.city == u.homeMeetupId).firstOrNull;
    }
    if (mounted) setState(() { _user = u; _homeMeetup = homeMeetup; });
  }

  Future<void> _calculateTrustScore() async {
    if (myBadges.isEmpty) {
      setState(() { _trustScore = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null); });
      return;
    }
    final sorted = List<MeetupBadge>.from(myBadges)..sort((a, b) => a.date.compareTo(b.date));
    final score = TrustScoreService.calculateScore(badges: myBadges, firstBadgeDate: sorted.first.date, coAttestorMap: null);
    setState(() => _trustScore = score);
  }

  Future<void> _reVerifyAdminStatus() async {
    try {
      final v = await _user.reVerifyAdmin(myBadges);
      if (mounted) setState(() {});
      if (v.isAdmin && v.source == 'trust_score') {
        try {
          await PromotionClaimService.publishAdminClaim(
            badges: myBadges, meetupName: _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt');
        } catch (_) {}
        if (mounted) {
          setState(() => _justPromoted = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text("Du bist jetzt ORGANISATOR!"),
            backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating));
        }
      }
    } catch (_) {
      if (mounted) setState(() { _user.isAdmin = false; _user.isAdminVerified = false; _user.promotionSource = ''; });
    }
  }

  void _resetApp() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("App zurücksetzen?"),
        content: const Text("Alle Badges und dein Profil werden gelöscht. Stelle sicher, dass du ein Backup hast!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbruch")),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
    if (!confirm) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); myBadges.clear(); await MeetupBadge.saveBadges([]);
    try { await SecureKeyStore.deleteKeys(); } catch (_) {}
    if (mounted) Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const IntroScreen()), (route) => false);
  }

  void _scanAnyMeetup() async {
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(context, MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: dummy)));
    _loadBadges(); _calculateTrustScore();
  }

  void _selectHomeMeetup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetupSelectionScreen()));
    _loadUser();
  }

  // ============================================================
  // HELPER
  // ============================================================

  Color get _levelColor {
    if (_trustScore == null) return cTextTertiary;
    switch (_trustScore!.level) {
      case 'VETERAN': return Colors.amber;
      case 'ETABLIERT': return Colors.green;
      case 'AKTIV': return cCyan;
      case 'STARTER': return cOrange;
      default: return cTextTertiary;
    }
  }

  IconData get _levelIcon {
    if (_trustScore == null) return Icons.fiber_new;
    switch (_trustScore!.level) {
      case 'VETERAN': return Icons.bolt;
      case 'ETABLIERT': return Icons.shield;
      case 'AKTIV': return Icons.local_fire_department;
      case 'STARTER': return Icons.eco;
      default: return Icons.fiber_new;
    }
  }

  // ============================================================
  // BUILD — SOCIAL FEED LAYOUT
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // ===== TOP BAR (Instagram-Style) =====
        SliverToBoxAdapter(child: _buildTopBar(top)),

        // ===== DEVICE WARNING =====
        if (_deviceCompromised && !_dismissedIntegrityWarning)
          SliverToBoxAdapter(child: _buildDeviceWarning()),

        // ===== AKTIVE SESSION (Pinned, wie Live-Badge) =====
        if (_activeSession != null)
          SliverToBoxAdapter(child: _buildActiveSessionBanner()),

        // ===== STORIES ROW =====
        SliverToBoxAdapter(child: _buildStoriesRow()),

        // ===== DIVIDER =====
        SliverToBoxAdapter(child: Divider(color: cBorder, height: 1, thickness: 0.5)),

        // ===== PROFILE SUMMARY (kompakt, wie ein Profil-Header) =====
        SliverToBoxAdapter(child: _buildProfileSummary()),

        // ===== HOME MEETUP =====
        if (_user.homeMeetupId.isNotEmpty)
          SliverToBoxAdapter(child: _buildHomeMeetupFeed())
        else
          SliverToBoxAdapter(child: _buildHomeMeetupEmpty()),

        // ===== IDENTITY LAYER =====
        SliverToBoxAdapter(child: _buildIdentitySection()),

        // ===== BADGE FEED =====
        SliverToBoxAdapter(child: _buildBadgeFeed()),

        // Bottom Padding
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ============================================================
  // TOP BAR — Wie Instagram: Brand links, Icons rechts
  // ============================================================
  Widget _buildTopBar(double topInset) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 16, 12),
      child: Row(
        children: [
          // Brand Name
          const Text(
            'einundzwanzig',
            style: TextStyle(
              color: cText,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 6),
          // Kleiner Blitz als Brand-Akzent
          const Icon(Icons.bolt_rounded, color: cOrange, size: 20),
          const Spacer(),
          // Help
          _topBarIcon(Icons.help_outline_rounded, onTap: _showHelpSheet),
          const SizedBox(width: 4),
          // Settings
          _topBarIcon(Icons.menu_rounded, onTap: _showSettings),
        ],
      ),
    );
  }

  Widget _topBarIcon(IconData icon, {required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: cTextSecondary, size: 24),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      splashRadius: 22,
    );
  }

  // ============================================================
  // STORIES ROW — Kreisförmige Action-Buttons
  // Wie Instagram Stories: Profil + Schnellzugriffe
  // ============================================================
  Widget _buildStoriesRow() {
    return Container(
      height: 106,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // "Dein Profil" (wie "Your Story")
          _storyCircle(
            label: _user.nickname.length > 8
                ? '${_user.nickname.substring(0, 7)}…'
                : _user.nickname,
            icon: Icons.person_rounded,
            gradientColors: [cOrange, cOrangeLight],
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
              _loadAll();
            },
          ),
          // Scan
          _storyCircle(
            label: 'Scannen',
            icon: Icons.qr_code_scanner_rounded,
            gradientColors: [cOrange, const Color(0xFFFF6B00)],
            onTap: _scanAnyMeetup,
          ),
          // Reputation
          _storyCircle(
            label: 'Reputation',
            icon: Icons.workspace_premium_rounded,
            gradientColors: [Colors.amber, Colors.orange],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())),
          ),
          // Events
          _storyCircle(
            label: 'Termine',
            icon: Icons.event_rounded,
            gradientColors: [cCyan, const Color(0xFF0088A0)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
          ),
          // Community
          _storyCircle(
            label: 'Community',
            icon: Icons.hub_rounded,
            gradientColors: [cCyan, const Color(0xFF0099B3)],
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())),
          ),
          // Organisator (nur wenn Admin)
          if (_user.isAdmin)
            _storyCircle(
              label: 'Organisator',
              icon: Icons.admin_panel_settings_rounded,
              gradientColors: [cPurple, const Color(0xFF7B00CC)],
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
                _checkActiveSession();
              },
            ),
        ],
      ),
    );
  }

  Widget _storyCircle({
    required String label,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              // Äußerer Ring (Gradient)
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cDark,
                    border: Border.all(color: cDark, width: 2.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          gradientColors[0].withOpacity(0.15),
                          gradientColors[1].withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Icon(icon, color: gradientColors[0], size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: cTextSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // AKTIVE SESSION — Pinned Banner (wie Live-Notification)
  // ============================================================
  Widget _buildActiveSessionBanner() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen()));
            _checkActiveSession();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5),
                    boxShadow: [BoxShadow(
                      color: Colors.green.withOpacity(0.3 * _pulseController.value),
                      blurRadius: 8, spreadRadius: 1,
                    )],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('LIVE', style: TextStyle(
                              color: Colors.green.shade300, fontSize: 9,
                              fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _activeSession!.meetupName.isNotEmpty
                                  ? _activeSession!.meetupName
                                  : 'Meetup aktiv',
                              style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Text('Noch $_sessionTimeLeft', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.5), size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // PROFILE SUMMARY — Kompakt, wie ein Social-Profil-Header
  // ============================================================
  Widget _buildProfileSummary() {
    final score = _trustScore;
    final badgeCount = myBadges.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          // Avatar mit Trust-Ring
          Container(
            width: 56, height: 56,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_levelColor, _levelColor.withOpacity(0.4)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cDark,
                border: Border.all(color: cDark, width: 2),
              ),
              child: Center(
                child: Text(
                  _user.nickname.isNotEmpty ? _user.nickname[0].toUpperCase() : '?',
                  style: TextStyle(color: _levelColor, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Stats (Instagram-style: Badges / Meetups / Score)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn(badgeCount.toString(), 'Badges'),
                _statColumn(score?.uniqueMeetups.toString() ?? '0', 'Meetups'),
                _statColumn(score?.totalScore.toStringAsFixed(1) ?? '0', 'Score'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(
          color: cText, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          color: cTextTertiary, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ============================================================
  // HOME MEETUP — Feed-Item-Style
  // ============================================================
  Widget _buildHomeMeetupFeed() {
    final hasData = _homeMeetup != null;
    final badgesHere = hasData ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length : 0;

    return _feedSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header-Zeile (wie ein Post-Header)
          GestureDetector(
            onTap: hasData
              ? () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!)))
              : null,
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: cOrange.withOpacity(0.1),
                    border: Border.all(color: cOrange.withOpacity(0.15)),
                  ),
                  child: hasData && _homeMeetup!.coverImagePath.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_homeMeetup!.coverImagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded, color: cOrange, size: 20)),
                      )
                    : const Icon(Icons.home_rounded, color: cOrange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            hasData ? _homeMeetup!.city : _user.homeMeetupId,
                            style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: cOrange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('HOME', style: TextStyle(
                              color: cOrange, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasData
                          ? [_homeMeetup!.country, if (badgesHere > 0) "$badgesHere Badge${badgesHere > 1 ? 's' : ''} hier"].join(' · ')
                          : 'Lade...',
                        style: const TextStyle(color: cTextTertiary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz_rounded, color: cTextTertiary, size: 20),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick-Action-Buttons
          Row(
            children: [
              _feedAction(Icons.event_rounded, 'Termine', () {
                if (hasData) Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CalendarScreen(initialSearch: _homeMeetup!.city)));
              }),
              const SizedBox(width: 12),
              _feedAction(Icons.info_outline_rounded, 'Details', () {
                if (hasData) Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!)));
              }),
              const SizedBox(width: 12),
              _feedAction(Icons.swap_horiz_rounded, 'Wechseln', _selectHomeMeetup),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHomeMeetupEmpty() {
    return _feedSection(
      child: GestureDetector(
        onTap: _selectHomeMeetup,
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cBorder,
              ),
              child: const Icon(Icons.add_rounded, color: cTextTertiary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Home Meetup wählen',
                    style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Wähle dein Stammtisch-Meetup',
                    style: TextStyle(color: cTextTertiary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: cTextTertiary),
          ],
        ),
      ),
    );
  }

  Widget _feedAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: cSurface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: cTextSecondary, size: 15),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // IDENTITY SECTION — Trust Level + Verknüpfungen
  // ============================================================
  Widget _buildIdentitySection() {
    final hasGaps = _platformProofCount == 0 || !_humanityVerified || !_nip05Verified;

    return _feedSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Level Zeile
          if (_trustScore != null) ...[
            Row(
              children: [
                Icon(_levelIcon, color: _levelColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  _trustScore!.level,
                  style: TextStyle(color: _levelColor, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                if (_trustScore!.meetsPromotionThreshold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 12),
                        const SizedBox(width: 3),
                        Text('Organisator', style: TextStyle(
                          color: Colors.green.shade400, fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _showScoreInfoSheet,
                  child: Text('Score Details →', style: TextStyle(
                    color: cOrange.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              ],
            ),

            if (!_trustScore!.meetsPromotionThreshold) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _trustScore!.promotionProgress,
                  backgroundColor: cSurface,
                  valueColor: AlwaysStoppedAnimation(_levelColor.withOpacity(0.7)),
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(_trustScore!.promotionProgress * 100).toInt()}% zum Organisator · ${_trustScore!.uniqueSigners} Signers',
                style: const TextStyle(color: cTextTertiary, fontSize: 11),
              ),
            ],

            const SizedBox(height: 16),
          ],

          // Identity Dots
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _idChip(Icons.bolt_rounded, 'Lightning', _humanityVerified, Colors.amber),
              _idChip(Icons.alternate_email, 'NIP-05', _nip05Verified, cCyan),
              ..._platformNames.map((name) {
                final iconMap = {'telegram': Icons.send, 'twitter': Icons.alternate_email, 'kleinanzeigen': Icons.storefront};
                final labelMap = {'telegram': 'Telegram', 'twitter': 'X', 'kleinanzeigen': 'Kleinanz.'};
                return _idChip(iconMap[name.toLowerCase()] ?? Icons.link, labelMap[name.toLowerCase()] ?? name, true, Colors.green);
              }),
              if (_platformProofCount == 0)
                _idChip(Icons.link_rounded, 'Plattform', false, cTextTertiary),
            ],
          ),

          if (hasGaps) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen()));
                _loadAll();
              },
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: cOrange.withOpacity(0.5), size: 16),
                  const SizedBox(width: 6),
                  Text('Verknüpfe Plattformen für mehr Trust',
                    style: TextStyle(color: cOrange.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _idChip(IconData icon, String label, bool active, Color activeColor) {
    final color = active ? activeColor : cTextTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withOpacity(active ? 1 : 0.5), size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
          color: color.withOpacity(active ? 0.9 : 0.5), fontSize: 12,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
        if (active) ...[
          const SizedBox(width: 3),
          Icon(Icons.check_circle_rounded, color: color, size: 12),
        ],
      ],
    );
  }

  // ============================================================
  // BADGE FEED — Wie Posts in einem Feed
  // ============================================================
  Widget _buildBadgeFeed() {
    if (myBadges.isEmpty) {
      return _feedSection(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Icon(Icons.military_tech_rounded, color: cTextTertiary.withOpacity(0.3), size: 52),
            const SizedBox(height: 16),
            const Text('Noch keine Badges',
              style: TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Besuche ein Meetup und scanne den NFC-Tag\noder QR-Code für dein erstes Badge.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cTextTertiary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanAnyMeetup,
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('JETZT SCANNEN'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Text('LETZTE BADGES', style: TextStyle(
                color: cTextTertiary, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BadgeWalletScreen())),
                child: Text('Alle ${myBadges.length} →', style: TextStyle(
                  color: cOrange.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ...myBadges.take(4).map((badge) => _buildBadgeItem(badge)),
      ],
    );
  }

  Widget _buildBadgeItem(MeetupBadge badge) {
    final dateStr = '${badge.date.day}.${badge.date.month}.${badge.date.year}';

    return GestureDetector(
      onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => BadgeDetailsScreen(badge: badge))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: cBorder, width: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [cOrange.withOpacity(0.15), cOrange.withOpacity(0.05)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.military_tech_rounded, color: cOrange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.meetupName,
                    style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(dateStr, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
                      if (badge.delivery.isNotEmpty) ...[
                        const Text(' · ', style: TextStyle(color: cTextTertiary, fontSize: 12)),
                        Icon(badge.delivery == 'nfc' ? Icons.nfc_rounded : Icons.qr_code_rounded,
                          color: cTextTertiary, size: 12),
                        const SizedBox(width: 2),
                        Text(badge.delivery.toUpperCase(),
                          style: const TextStyle(color: cTextTertiary, fontSize: 11)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge.isFullyBound)
                  Icon(Icons.link_rounded, color: cGreen.withOpacity(0.6), size: 16),
                if (badge.isNostrSigned)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified_outlined, color: cCyan.withOpacity(0.5), size: 16),
                  ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, color: cTextTertiary.withOpacity(0.5), size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FEED SECTION WRAPPER — Konsistentes Padding + Divider
  // ============================================================
  Widget _feedSection({required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cBorder, width: 0.5)),
      ),
      child: child,
    );
  }

  // ============================================================
  // DEVICE WARNING
  // ============================================================
  Widget _buildDeviceWarning() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(DeviceIntegrityService.warningMessage,
            style: TextStyle(color: Colors.orange.shade200, fontSize: 12))),
          GestureDetector(
            onTap: () => setState(() => _dismissedIntegrityWarning = true),
            child: Icon(Icons.close_rounded, color: Colors.orange.shade300, size: 16),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEETS — Logik 1:1 aus dashboard.dart
  // ============================================================

  void _showHelpSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text("SO FUNKTIONIERT'S",
              style: TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            _helpItem(Icons.military_tech, cOrange, "BADGES SAMMELN",
              "Scanne den NFC-Tag oder Rolling-QR-Code bei einem Meetup. Jeder Besuch = ein kryptographisch signiertes Badge."),
            _helpItem(Icons.workspace_premium, Colors.amber, "REPUTATION AUFBAUEN",
              "Dein Trust Score steigt mit jedem Badge. Diversität wird belohnt."),
            _helpItem(Icons.admin_panel_settings, Colors.green, "ORGANISATOR WERDEN",
              "Ab einem bestimmten Trust Score wirst du automatisch befördert und kannst eigene Meetups verifizieren."),
            _helpItem(Icons.verified_user, cCyan, "KRYPTOGRAPHISCHE SICHERHEIT",
              "BIP-340 Schnorr-Signaturen. Niemand kann Badges fälschen — auch wir nicht."),
            _helpItem(Icons.qr_code_scanner, cPurple, "REPUTATION PRÜFEN",
              "Teile deinen QR-Code. Andere sehen dein Trust Level — kryptographisch verifiziert."),
            _helpItem(Icons.upload, Colors.blue, "BACKUP",
              "Sichere deinen Account über die Einstellungen. Enthält Nostr-Key und alle Badges."),
            const SizedBox(height: 12),
            const Divider(color: cBorder),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.lock_outline_rounded, color: cTextTertiary, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text("Alle Daten auf deinem Gerät. Kein Server, kein Tracking.",
                style: TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, Color color, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          _settingsGroup("DATENSICHERUNG"),
          _settingsTile(Icons.upload_rounded, Colors.blue, "Backup erstellen",
            "Sichere deinen Account als Datei", () async { Navigator.pop(context); await BackupService.createBackup(context); }),
          const SizedBox(height: 16),
          _settingsGroup("NOSTR-NETZWERK"),
          _settingsTile(Icons.hub_rounded, cCyan, "Nostr-Relays",
            "Relays für Reputation konfigurieren", () { Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
          const SizedBox(height: 16),
          _settingsGroup("ACCOUNT"),
          _settingsTile(Icons.delete_forever_rounded, Colors.red, "App zurücksetzen",
            "Löscht Profil und Badges vom Gerät", () { Navigator.pop(context); _resetApp(); }),
        ]),
      ),
    );
  }

  Widget _settingsGroup(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(title, style: const TextStyle(
        color: cTextTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _settingsTile(IconData icon, Color color, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // ============================================================
  // SCORE INFO SHEET — Logik 1:1 aus dashboard.dart
  // ============================================================
  void _showScoreInfoSheet() {
    final score = _trustScore;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.80, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (context, sc) => SingleChildScrollView(
          controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("DEIN TRUST SCORE",
              style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text("Der Trust Score misst deine Vertrauenswürdigkeit. Er basiert auf kryptographischen Beweisen.",
              style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),

            const Text("TRUST LEVEL", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _lvl(Icons.fiber_new, "NEU", "< 3", Colors.grey, score?.level == 'NEU'),
            _lvl(Icons.eco, "STARTER", "3 – 9", cOrange, score?.level == 'STARTER'),
            _lvl(Icons.local_fire_department, "AKTIV", "10 – 19", cCyan, score?.level == 'AKTIV'),
            _lvl(Icons.shield, "ETABLIERT", "20 – 39", Colors.green, score?.level == 'ETABLIERT'),
            _lvl(Icons.bolt, "VETERAN", "40+", Colors.amber, score?.level == 'VETERAN'),

            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("BERECHNUNG", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _factor(Icons.military_tech, cOrange, "Meetup-Badges", "Basiswert pro Badge. Gut besuchte Meetups sind mehr wert."),
            _factor(Icons.location_on, cCyan, "Diversität", "Verschiedene Städte und Organisatoren zählen mehr."),
            _factor(Icons.people_outline, cPurple, "Signers", "Mehrere unabhängige Organisatoren = höherer Trust."),
            _factor(Icons.schedule, Colors.green, "Reife", "Regelmäßigkeit und Account-Alter geben Bonus."),
            _factor(Icons.speed, cRed, "Frequency Cap", "Max. 2 Badges/Woche zählen. Anti-Farming."),

            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("ORGANISATOR", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text("Automatische Beförderung ab genügend Trust Score.",
              style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),

            if (score != null && !score.meetsPromotionThreshold)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cOrange.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("FORTSCHRITT (${score.activeThresholds.name})",
                    style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ...score.progress.entries.map((e) => _progressRow(e.value)),
                ]),
              )
            else if (score != null)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.withOpacity(0.2))),
                child: Row(children: [
                  const Icon(Icons.verified, color: Colors.green, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text("Du bist bereits Organisator!",
                    style: TextStyle(color: Colors.green.shade300, fontSize: 13))),
                ]),
              ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _lvl(IconData icon, String name, String range, Color color, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: active ? Border.all(color: color.withOpacity(0.2)) : null,
      ),
      child: Row(children: [
        Icon(icon, color: active ? color : color.withOpacity(0.3), size: 18),
        const SizedBox(width: 12),
        Expanded(child: Row(children: [
          Text(name, style: TextStyle(color: active ? color : cTextSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(range, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
        ])),
        if (active) Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
          child: Text('DU', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }

  Widget _factor(IconData icon, Color color, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: cTextTertiary, fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _progressRow(PromotionProgress p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(p.met ? Icons.check_circle : Icons.radio_button_unchecked,
          color: p.met ? Colors.green : cTextTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text("${p.label}: ${p.current}/${p.required}",
          style: TextStyle(color: p.met ? Colors.green.shade300 : cTextSecondary, fontSize: 12,
            fontWeight: p.met ? FontWeight.w600 : FontWeight.normal))),
        SizedBox(width: 40, height: 4, child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: p.percentage,
            backgroundColor: cSurface, valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange)))),
      ]),
    );
  }
}