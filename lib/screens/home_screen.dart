// ============================================================
// HOME SCREEN — Redesign v4 (Widget Landscape)
// ============================================================
// Design:
//   Kachel-Landschaft mit unterschiedlichen Größen.
//   Jede Kachel hat eine subtile Gradient-Fläche (Mirror-Effekt).
//   Einheitlicher Gap (12px) und Radius (20px) = Zusammengehörigkeit.
//   Einundzwanzig SVG-Logo im Header.
//
// Layout:
//   [Logo + Icons]
//   [Trust Score 2/3] [Badges 1/3]
//   [Home Meetup — full width]
//   [Reputation 1/2] [Community 1/2]
//   [Events 1/3] [Profil 1/3] [Scan 1/3]
//   [Organisator — full width, wenn Admin]
//
// ALLE LOGIK 1:1 AUS dashboard.dart.
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
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

// Konstanten für das Kachel-Layout
const double _gap = 12;
const double _tileRadius = 20;

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
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _loadAll();
  }

  @override
  void dispose() { _sessionTimer?.cancel(); _pulseController.dispose(); super.dispose(); }

  void refreshAfterScan() { _loadBadges(); _calculateTrustScore(); }

  // ============================================================
  // BUSINESS LOGIC — 1:1 aus dashboard.dart (UNVERÄNDERT)
  // ============================================================

  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) {
      if (mounted) { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); await _loadUser(); }
    }
    await _loadBadges(); await _calculateTrustScore(); await _reVerifyAdminStatus();
    _loadIdentityData(); _checkActiveSession(); _syncOrganicAdminsInBackground(); _checkDeviceIntegrity();
  }

  void _loadIdentityData() async {
    try {
      final proofs = await PlatformProofService.getSavedProofs();
      var humanity = await HumanityProofService.getStatus();
      if (humanity.needsReverification) { final r = await HumanityProofService.reverifyIfNeeded(); if (r) humanity = await HumanityProofService.getStatus(); }
      bool nip05 = false;
      if (_user.hasNostrKey && _user.nostrNpub.isNotEmpty) {
        try {
          final relays = ['wss://relay.damus.io', 'wss://nos.lol'];
          final pk = Nip19.decodePubkey(_user.nostrNpub);
          final n = await Nip05Service.fetchNip05FromProfile(pk, relays).timeout(const Duration(seconds: 8), onTimeout: () => null);
          if (n != null && n.isNotEmpty) { final r = await Nip05Service.verify(n, pk); nip05 = r.valid; }
        } catch (_) {}
      }
      if (mounted) setState(() { _platformProofCount = proofs.length; _platformNames = proofs.map((p) => p.platform).toList(); _humanityVerified = humanity.verified; _nip05Verified = nip05; });
    } catch (_) {}
  }

  void _checkActiveSession() async {
    final s = await RollingQRService.loadSession();
    if (s != null && !s.isExpired) { setState(() => _activeSession = s); _startSessionTimer(); }
    else { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); }
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession == null || _activeSession!.isExpired) { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); return; }
      if (mounted) setState(() { final r = _activeSession!.remainingTime; _sessionTimeLeft = '${r.inHours}h ${(r.inMinutes % 60).toString().padLeft(2, '0')}m'; });
    });
  }

  void _syncOrganicAdminsInBackground() async { try { await PromotionClaimService.syncOrganicAdmins(); } catch (_) {} }
  void _checkDeviceIntegrity() async { try { final r = await DeviceIntegrityService.check(); if (r.isCompromised && mounted) setState(() => _deviceCompromised = true); } catch (_) {} }

  Future<void> _loadBadges() async {
    final badges = await MeetupBadge.loadBadges(); await BadgeClaimService.ensureBadgesClaimed(badges);
    setState(() { myBadges.clear(); myBadges.addAll(badges); });
    if (badges.isNotEmpty) ReputationPublisher.publishInBackground(badges);
  }

  Future<void> _loadUser() async {
    final u = await UserProfile.load(); Meetup? hm;
    if (u.homeMeetupId.isNotEmpty) { List<Meetup> m = await MeetupService.fetchMeetups(); if (m.isEmpty) m = allMeetups; hm = m.where((x) => x.city == u.homeMeetupId).firstOrNull; }
    if (mounted) setState(() { _user = u; _homeMeetup = hm; });
  }

  Future<void> _calculateTrustScore() async {
    if (myBadges.isEmpty) { setState(() => _trustScore = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null)); return; }
    final s = List<MeetupBadge>.from(myBadges)..sort((a, b) => a.date.compareTo(b.date));
    setState(() => _trustScore = TrustScoreService.calculateScore(badges: myBadges, firstBadgeDate: s.first.date, coAttestorMap: null));
  }

  Future<void> _reVerifyAdminStatus() async {
    try {
      final v = await _user.reVerifyAdmin(myBadges); if (mounted) setState(() {});
      if (v.isAdmin && v.source == 'trust_score') {
        try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt'); } catch (_) {}
        if (mounted) { setState(() => _justPromoted = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Du bist jetzt ORGANISATOR!"), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 5), behavior: SnackBarBehavior.floating)); }
      }
    } catch (_) { if (mounted) setState(() { _user.isAdmin = false; _user.isAdminVerified = false; _user.promotionSource = ''; }); }
  }

  void _resetApp() async {
    bool c = await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("App zurücksetzen?"), content: const Text("Alle Badges und dein Profil werden gelöscht."),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbruch")),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))],
    )) ?? false;
    if (!c) return;
    final p = await SharedPreferences.getInstance(); await p.clear(); myBadges.clear(); await MeetupBadge.saveBadges([]);
    try { await SecureKeyStore.deleteKeys(); } catch (_) {}
    if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const IntroScreen()), (r) => false);
  }

  void _scanAnyMeetup() async {
    final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupVerificationScreen(meetup: d)));
    _loadBadges(); _calculateTrustScore();
  }

  void _selectHomeMeetup() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetupSelectionScreen())); _loadUser(); }

  // ============================================================
  // HELPER
  // ============================================================
  Color get _levelColor { if (_trustScore == null) return cTextTertiary; switch (_trustScore!.level) { case 'VETERAN': return Colors.amber; case 'ETABLIERT': return Colors.green; case 'AKTIV': return cCyan; case 'STARTER': return cOrange; default: return cTextTertiary; } }
  IconData get _levelIcon { if (_trustScore == null) return Icons.fiber_new; switch (_trustScore!.level) { case 'VETERAN': return Icons.bolt; case 'ETABLIERT': return Icons.shield; case 'AKTIV': return Icons.local_fire_department; case 'STARTER': return Icons.eco; default: return Icons.fiber_new; } }

  // ============================================================
  // BUILD — WIDGET LANDSCAPE
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== LOGO BAR =====
          _buildLogoBar(),
          const SizedBox(height: 20),

          // ===== DEVICE WARNING =====
          if (_deviceCompromised && !_dismissedIntegrityWarning) ...[
            _buildDeviceWarning(),
            const SizedBox(height: _gap),
          ],

          // ===== AKTIVE SESSION =====
          if (_activeSession != null) ...[
            _buildActiveSessionTile(),
            const SizedBox(height: _gap),
          ],

          // ===== ROW 1: Trust Score + Badge Count =====
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 2, child: _buildTrustScoreTile()),
                const SizedBox(width: _gap),
                Expanded(flex: 1, child: _buildBadgeCountTile()),
              ],
            ),
          ),
          const SizedBox(height: _gap),

          // ===== ROW 2: Home Meetup =====
          _buildHomeMeetupTile(),
          const SizedBox(height: _gap),

          // ===== ROW 3: Reputation + Community =====
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildReputationTile()),
                const SizedBox(width: _gap),
                Expanded(child: _buildCommunityTile()),
              ],
            ),
          ),
          const SizedBox(height: _gap),

          // ===== ROW 4: Events + Identity + Scan =====
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildEventsTile()),
                const SizedBox(width: _gap),
                Expanded(child: _buildIdentityTile()),
                const SizedBox(width: _gap),
                Expanded(child: _buildScanTile()),
              ],
            ),
          ),

          // ===== ROW 5: Organisator (conditional) =====
          if (_user.isAdmin) ...[
            const SizedBox(height: _gap),
            _buildOrganisatorTile(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // LOGO BAR
  // ============================================================
  Widget _buildLogoBar() {
    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/einundzwanzig_logo.svg',
          height: 16,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        const Spacer(),
        _headerIcon(Icons.help_outline_rounded, _showHelpSheet),
        const SizedBox(width: 4),
        _headerIcon(Icons.settings_rounded, _showSettings),
      ],
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E22),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: cTextSecondary, size: 18),
      ),
    );
  }

  // ============================================================
  // TILE BUILDER — Subtiler Mirror-Gradient
  // ============================================================
  Widget _tile({
    required Widget child,
    required Color accentColor,
    VoidCallback? onTap,
    double opacity = 0.08,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_tileRadius),
          // Mirror-Gradient: dezenter Schimmer von oben-links
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withOpacity(opacity),
              accentColor.withOpacity(opacity * 0.3),
              const Color(0xFF161618),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
          border: Border.all(
            color: accentColor.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }

  // ============================================================
  // TRUST SCORE TILE — Groß, prominent
  // ============================================================
  Widget _buildTrustScoreTile() {
    final score = _trustScore;
    final level = score?.level ?? 'NEU';
    final total = score?.totalScore ?? 0.0;

    return _tile(
      accentColor: _levelColor,
      opacity: 0.10,
      onTap: _showScoreInfoSheet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            children: [
              Icon(_levelIcon, color: _levelColor, size: 20),
              const SizedBox(width: 8),
              Text(level, style: TextStyle(color: _levelColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          // Score
          Text(
            total.toStringAsFixed(1),
            style: TextStyle(color: _levelColor, fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1),
          ),
          const SizedBox(height: 4),
          Text('Trust Score', style: TextStyle(color: cTextTertiary, fontSize: 12)),
          // Progress
          if (score != null && !score.meetsPromotionThreshold) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: score.promotionProgress,
                backgroundColor: Colors.white.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(_levelColor.withOpacity(0.6)),
                minHeight: 4,
              ),
            ),
          ] else if (score != null && score.meetsPromotionThreshold) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 14),
              const SizedBox(width: 4),
              Text('Organisator', style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BADGE COUNT TILE — Kompakt, klickbar
  // ============================================================
  Widget _buildBadgeCountTile() {
    return _tile(
      accentColor: cPurple,
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => BadgeWalletScreen()));
        _loadBadges(); _calculateTrustScore();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.style_rounded, color: cPurple, size: 22),
          const Spacer(),
          Text(
            '${myBadges.length}',
            style: const TextStyle(color: cText, fontSize: 34, fontWeight: FontWeight.w900, fontFamily: 'monospace', height: 1),
          ),
          const SizedBox(height: 4),
          Text('Badges', style: TextStyle(color: cTextTertiary, fontSize: 12)),
        ],
      ),
    );
  }

  // ============================================================
  // HOME MEETUP TILE — Full width
  // ============================================================
  Widget _buildHomeMeetupTile() {
    final hasHome = _homeMeetup != null;
    final badgesHere = hasHome ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length : 0;

    if (!_user.homeMeetupId.isNotEmpty) {
      return _tile(
        accentColor: cTextTertiary,
        opacity: 0.05,
        onTap: _selectHomeMeetup,
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.05)),
              child: const Icon(Icons.add_rounded, color: cTextTertiary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Home Meetup wählen', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Dein Stammtisch-Meetup', style: TextStyle(color: cTextTertiary, fontSize: 12)),
            ])),
            Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
          ],
        ),
      );
    }

    return _tile(
      accentColor: cOrange,
      onTap: hasHome ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _homeMeetup!.city))) : null,
      child: Row(
        children: [
          // Meetup-Bild
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: cOrange.withOpacity(0.12),
            ),
            child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty
              ? ClipRRect(borderRadius: BorderRadius.circular(14),
                  child: Image.network(_homeMeetup!.coverImagePath, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded, color: cOrange, size: 22)))
              : const Icon(Icons.home_rounded, color: cOrange, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(
                  hasHome ? _homeMeetup!.city : _user.homeMeetupId,
                  style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                )),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: cOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
                  child: const Text('HOME', style: TextStyle(color: cOrange, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(
                hasHome ? [_homeMeetup!.country, if (badgesHere > 0) '$badgesHere Badges hier'].join(' · ') : 'Lade...',
                style: const TextStyle(color: cTextTertiary, fontSize: 12),
              ),
            ]),
          ),
          // Schnellzugriff-Icons
          if (hasHome) ...[
            const SizedBox(width: 8),
            _miniAction(Icons.info_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!)))),
            const SizedBox(width: 6),
            _miniAction(Icons.swap_horiz_rounded, _selectHomeMeetup),
          ],
        ],
      ),
    );
  }

  Widget _miniAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: cTextSecondary, size: 16),
      ),
    );
  }

  // ============================================================
  // REPUTATION TILE
  // ============================================================
  Widget _buildReputationTile() {
    return _tile(
      accentColor: Colors.amber,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
          const SizedBox(height: 14),
          const Text('Reputation', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            myBadges.isNotEmpty ? 'QR teilen & prüfen' : 'Scannen & prüfen',
            style: const TextStyle(color: cTextTertiary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMUNITY TILE
  // ============================================================
  Widget _buildCommunityTile() {
    return _tile(
      accentColor: cCyan,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hub_rounded, color: cCyan, size: 24),
          const SizedBox(height: 14),
          const Text('Community', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          const Text('Portal & Netzwerk', style: TextStyle(color: cTextTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  // ============================================================
  // EVENTS TILE
  // ============================================================
  Widget _buildEventsTile() {
    return _tile(
      accentColor: const Color(0xFF8090A0), // Silber
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.event_rounded, color: Color(0xFF8090A0), size: 22),
          const SizedBox(height: 10),
          const Text('Events', style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Kalender', style: TextStyle(color: cTextTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================
  // IDENTITY TILE — Kompakte Übersicht
  // ============================================================
  Widget _buildIdentityTile() {
    final count = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    return _tile(
      accentColor: const Color(0xFF606068), // Neutral
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); _loadAll(); },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.fingerprint_rounded, color: Color(0xFF909098), size: 22),
          const SizedBox(height: 10),
          const Text('Identität', style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('$count aktiv', style: const TextStyle(color: cTextTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================
  // SCAN TILE — Call to Action
  // ============================================================
  Widget _buildScanTile() {
    return _tile(
      accentColor: cOrange,
      opacity: 0.14,
      onTap: _scanAnyMeetup,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: cOrange, size: 22),
          const SizedBox(height: 10),
          Text('Scannen', style: TextStyle(color: cOrange, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('Badge holen', style: TextStyle(color: cTextTertiary, fontSize: 10)),
        ],
      ),
    );
  }

  // ============================================================
  // ORGANISATOR TILE — Admin only
  // ============================================================
  Widget _buildOrganisatorTile() {
    return _tile(
      accentColor: _justPromoted ? Colors.green : cPurple,
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); },
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings_rounded, color: _justPromoted ? Colors.green : cPurple, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Organisator', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              _justPromoted ? 'Neu via Trust Score!' : _user.promotionSource == 'trust_score' ? 'Via Trust Score' : 'Tags erstellen',
              style: const TextStyle(color: cTextTertiary, fontSize: 12),
            ),
          ])),
          Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // AKTIVE SESSION TILE — Grün, pulsierend
  // ============================================================
  Widget _buildActiveSessionTile() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, __) => GestureDetector(
        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_tileRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Colors.green.withOpacity(0.12), Colors.green.withOpacity(0.04), const Color(0xFF161618)],
              stops: const [0.0, 0.4, 1.0],
            ),
            border: Border.all(color: Colors.green.withOpacity(0.2), width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5),
                boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3 * _pulseController.value), blurRadius: 8)]),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
              child: Text('LIVE', style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(
              _activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : 'Meetup aktiv',
              style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Text(_sessionTimeLeft, style: const TextStyle(color: cTextTertiary, fontSize: 12, fontFamily: 'monospace')),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.4), size: 14),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // DEVICE WARNING
  // ============================================================
  Widget _buildDeviceWarning() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(_tileRadius),
        color: Colors.orange.withOpacity(0.06), border: Border.all(color: Colors.orange.withOpacity(0.2), width: 0.5)),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(DeviceIntegrityService.warningMessage, style: TextStyle(color: Colors.orange.shade200, fontSize: 12))),
        GestureDetector(onTap: () => setState(() => _dismissedIntegrityWarning = true),
          child: Icon(Icons.close_rounded, color: Colors.orange.shade300, size: 16)),
      ]),
    );
  }

  // ============================================================
  // BOTTOM SHEETS — Logik 1:1 aus dashboard.dart
  // ============================================================
  void _showHelpSheet() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text("SO FUNKTIONIERT'S", style: TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            _helpItem(Icons.military_tech, cOrange, "BADGES SAMMELN", "Scanne den NFC-Tag oder Rolling-QR-Code bei einem Meetup. Jeder Besuch = ein kryptographisch signiertes Badge."),
            _helpItem(Icons.workspace_premium, Colors.amber, "REPUTATION AUFBAUEN", "Dein Trust Score steigt mit jedem Badge. Diversität wird belohnt."),
            _helpItem(Icons.admin_panel_settings, Colors.green, "ORGANISATOR WERDEN", "Ab einem bestimmten Trust Score wirst du automatisch befördert."),
            _helpItem(Icons.verified_user, cCyan, "KRYPTOGRAPHISCHE SICHERHEIT", "BIP-340 Schnorr-Signaturen. Niemand kann Badges fälschen."),
            _helpItem(Icons.qr_code_scanner, cPurple, "REPUTATION PRÜFEN", "Teile deinen QR-Code. Andere sehen dein Trust Level."),
            _helpItem(Icons.upload, Colors.blue, "BACKUP", "Sichere deinen Account über die Einstellungen."),
            const SizedBox(height: 12), const Divider(color: cBorder), const SizedBox(height: 8),
            Row(children: [const Icon(Icons.lock_outline_rounded, color: cTextTertiary, size: 14), const SizedBox(width: 8),
              Expanded(child: Text("Alle Daten auf deinem Gerät. Kein Server.", style: TextStyle(color: cTextTertiary, fontSize: 11)))]),
          ]))));
  }

  Widget _helpItem(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 20), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 4),
        Text(d, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5))]))]));

  void _showSettings() {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          _sGroup("DATENSICHERUNG"),
          _sTile(Icons.upload_rounded, Colors.blue, "Backup erstellen", "Sichere deinen Account", () async { Navigator.pop(context); await BackupService.createBackup(context); }),
          const SizedBox(height: 16),
          _sGroup("NOSTR-NETZWERK"),
          _sTile(Icons.hub_rounded, cCyan, "Nostr-Relays", "Relays konfigurieren", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
          const SizedBox(height: 16),
          _sGroup("ACCOUNT"),
          _sTile(Icons.delete_forever_rounded, Colors.red, "App zurücksetzen", "Löscht Profil und Badges", () { Navigator.pop(context); _resetApp(); }),
        ])));
  }

  Widget _sGroup(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(t, style: const TextStyle(color: cTextTertiary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)));
  Widget _sTile(IconData i, Color c, String t, String s, VoidCallback onTap) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: c, size: 20)),
    title: Text(t, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w600)),
    subtitle: Text(s, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
    onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 4));

  void _showScoreInfoSheet() {
    final score = _trustScore;
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.80, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("DEIN TRUST SCORE", style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 6),
            const Text("Der Trust Score misst deine Vertrauenswürdigkeit.", style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 24),
            const Text("TRUST LEVEL", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _lvl(Icons.fiber_new, "NEU", "< 3", Colors.grey, score?.level == 'NEU'),
            _lvl(Icons.eco, "STARTER", "3–9", cOrange, score?.level == 'STARTER'),
            _lvl(Icons.local_fire_department, "AKTIV", "10–19", cCyan, score?.level == 'AKTIV'),
            _lvl(Icons.shield, "ETABLIERT", "20–39", Colors.green, score?.level == 'ETABLIERT'),
            _lvl(Icons.bolt, "VETERAN", "40+", Colors.amber, score?.level == 'VETERAN'),
            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("BERECHNUNG", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _fac(Icons.military_tech, cOrange, "Meetup-Badges", "Basiswert pro Badge. Gut besuchte Meetups wertvoller."),
            _fac(Icons.location_on, cCyan, "Diversität", "Verschiedene Städte/Organisatoren = mehr Punkte."),
            _fac(Icons.people_outline, cPurple, "Signers", "Unabhängige Organisatoren = höherer Trust."),
            _fac(Icons.schedule, Colors.green, "Reife", "Regelmäßigkeit + Account-Alter = Bonus."),
            _fac(Icons.speed, cRed, "Frequency Cap", "Max. 2 Badges/Woche. Anti-Farming."),
            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("ORGANISATOR", style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text("Automatische Beförderung ab genügend Trust.", style: TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            if (score != null && !score.meetsPromotionThreshold)
              Container(width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: cOrange.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("FORTSCHRITT (${score.activeThresholds.name})", style: const TextStyle(color: cOrange, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10),
                  ...score.progress.entries.map((e) => _pRow(e.value))]))
            else if (score != null)
              Container(width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.withOpacity(0.2))),
                child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 20), const SizedBox(width: 10),
                  Expanded(child: Text("Du bist bereits Organisator!", style: TextStyle(color: Colors.green.shade300, fontSize: 13)))])),
            const SizedBox(height: 20),
          ]))));
  }

  Widget _lvl(IconData i, String n, String r, Color c, bool a) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: a ? c.withOpacity(0.06) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: a ? Border.all(color: c.withOpacity(0.2)) : null),
    child: Row(children: [Icon(i, color: a ? c : c.withOpacity(0.3), size: 18), const SizedBox(width: 12),
      Expanded(child: Row(children: [Text(n, style: TextStyle(color: a ? c : cTextSecondary, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Text(r, style: const TextStyle(color: cTextTertiary, fontSize: 11))])),
      if (a) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
        child: Text('DU', style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w800)))]));

  Widget _fac(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 18), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600)), const SizedBox(height: 2),
        Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 12, height: 1.4))]))]));

  Widget _pRow(PromotionProgress p) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(p.met ? Icons.check_circle : Icons.radio_button_unchecked, color: p.met ? Colors.green : cTextTertiary, size: 16), const SizedBox(width: 8),
      Expanded(child: Text("${p.label}: ${p.current}/${p.required}", style: TextStyle(color: p.met ? Colors.green.shade300 : cTextSecondary, fontSize: 12, fontWeight: p.met ? FontWeight.w600 : FontWeight.normal))),
      SizedBox(width: 40, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: p.percentage, backgroundColor: cSurface, valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange))))]));
}