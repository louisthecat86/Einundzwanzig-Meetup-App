// ============================================================
// HOME SCREEN — v4.1 (Widget Landscape, fixes)
// ============================================================
// Changes from v4:
//   - SVG logo: No colorFilter → Bitcoin ₿ shows in orange
//   - Identity tile → Shoutout tile (shoutout.einundzwanzig.space)
//   - Scanner tile → Podcast tile (einundzwanzig.space/podcast)
//   - Stronger tile borders (cTileBorder, 0.8px)
//   - Sora font via theme, monospace for numbers
//   - No more duplications with bottom nav
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'package:google_fonts/google_fonts.dart';
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

const double _gap = 12;
const double _tileRadius = 20;
final String? _mono = GoogleFonts.inconsolata().fontFamily;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
  // BUSINESS LOGIC — 1:1 aus dashboard.dart
  // ============================================================
  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) { if (mounted) { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); await _loadUser(); } }
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
        try { final relays = ['wss://relay.damus.io', 'wss://nos.lol']; final pk = Nip19.decodePubkey(_user.nostrNpub);
          final n = await Nip05Service.fetchNip05FromProfile(pk, relays).timeout(const Duration(seconds: 8), onTimeout: () => null);
          if (n != null && n.isNotEmpty) { final r = await Nip05Service.verify(n, pk); nip05 = r.valid; } } catch (_) {}
      }
      if (mounted) setState(() { _platformProofCount = proofs.length; _platformNames = proofs.map((p) => p.platform).toList(); _humanityVerified = humanity.verified; _nip05Verified = nip05; });
    } catch (_) {}
  }

  void _checkActiveSession() async { final s = await RollingQRService.loadSession(); if (s != null && !s.isExpired) { setState(() => _activeSession = s); _startSessionTimer(); } else { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); } }
  void _startSessionTimer() { _sessionTimer?.cancel(); _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (_activeSession == null || _activeSession!.isExpired) { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); return; } if (mounted) setState(() { final r = _activeSession!.remainingTime; _sessionTimeLeft = '${r.inHours}h ${(r.inMinutes % 60).toString().padLeft(2, '0')}m'; }); }); }
  void _syncOrganicAdminsInBackground() async { try { await PromotionClaimService.syncOrganicAdmins(); } catch (_) {} }
  void _checkDeviceIntegrity() async { try { final r = await DeviceIntegrityService.check(); if (r.isCompromised && mounted) setState(() => _deviceCompromised = true); } catch (_) {} }
  Future<void> _loadBadges() async { final badges = await MeetupBadge.loadBadges(); await BadgeClaimService.ensureBadgesClaimed(badges); setState(() { myBadges.clear(); myBadges.addAll(badges); }); if (badges.isNotEmpty) ReputationPublisher.publishInBackground(badges); }
  Future<void> _loadUser() async { final u = await UserProfile.load(); Meetup? hm; if (u.homeMeetupId.isNotEmpty) { List<Meetup> m = await MeetupService.fetchMeetups(); if (m.isEmpty) m = allMeetups; hm = m.where((x) => x.city == u.homeMeetupId).firstOrNull; } if (mounted) setState(() { _user = u; _homeMeetup = hm; }); }
  Future<void> _calculateTrustScore() async { if (myBadges.isEmpty) { setState(() => _trustScore = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null)); return; } final s = List<MeetupBadge>.from(myBadges)..sort((a, b) => a.date.compareTo(b.date)); setState(() => _trustScore = TrustScoreService.calculateScore(badges: myBadges, firstBadgeDate: s.first.date, coAttestorMap: null)); }
  Future<void> _reVerifyAdminStatus() async { try { final v = await _user.reVerifyAdmin(myBadges); if (mounted) setState(() {}); if (v.isAdmin && v.source == 'trust_score') { try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt'); } catch (_) {} if (mounted) { setState(() => _justPromoted = true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Du bist jetzt ORGANISATOR!"), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 5), behavior: SnackBarBehavior.floating)); } } } catch (_) { if (mounted) setState(() { _user.isAdmin = false; _user.isAdminVerified = false; _user.promotionSource = ''; }); } }
  void _resetApp() async { bool c = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("App zurücksetzen?"), content: const Text("Alle Badges und dein Profil werden gelöscht."), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbruch")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))])) ?? false; if (!c) return; final p = await SharedPreferences.getInstance(); await p.clear(); myBadges.clear(); await MeetupBadge.saveBadges([]); try { await SecureKeyStore.deleteKeys(); } catch (_) {} if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const IntroScreen()), (r) => false); }
  void _scanAnyMeetup() async { final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0); await Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupVerificationScreen(meetup: d))); _loadBadges(); _calculateTrustScore(); }
  void _selectHomeMeetup() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetupSelectionScreen())); _loadUser(); }

  Future<void> _openUrl(String url) async { final uri = Uri.parse(url); if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Konnte $url nicht öffnen"))); } }

  // Helper
  Color get _levelColor { if (_trustScore == null) return cTextTertiary; switch (_trustScore!.level) { case 'VETERAN': return Colors.amber; case 'ETABLIERT': return Colors.green; case 'AKTIV': return cCyan; case 'STARTER': return cOrange; default: return cTextTertiary; } }
  IconData get _levelIcon { if (_trustScore == null) return Icons.fiber_new; switch (_trustScore!.level) { case 'VETERAN': return Icons.bolt; case 'ETABLIERT': return Icons.shield; case 'AKTIV': return Icons.local_fire_department; case 'STARTER': return Icons.eco; default: return Icons.fiber_new; } }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLogoBar(),
        const SizedBox(height: 20),
        if (_deviceCompromised && !_dismissedIntegrityWarning) ...[_buildDeviceWarning(), const SizedBox(height: _gap)],
        if (_activeSession != null) ...[_buildActiveSessionTile(), const SizedBox(height: _gap)],
        // Row 1: Trust + Badges
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 2, child: _buildTrustScoreTile()),
          const SizedBox(width: _gap),
          Expanded(flex: 1, child: _buildBadgeCountTile()),
        ])),
        const SizedBox(height: _gap),
        // Row 2: Home Meetup
        _buildHomeMeetupTile(),
        const SizedBox(height: _gap),
        // Row 3: Reputation + Community
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _buildReputationTile()),
          const SizedBox(width: _gap),
          Expanded(child: _buildCommunityTile()),
        ])),
        const SizedBox(height: _gap),
        // Row 4: Events + Shoutout + Podcast (GEÄNDERT!)
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _buildEventsTile()),
          const SizedBox(width: _gap),
          Expanded(child: _buildShoutoutTile()),     // war: Identity
          const SizedBox(width: _gap),
          Expanded(child: _buildPodcastTile()),       // war: Scanner
        ])),
        // Row 5: Organisator
        if (_user.isAdmin) ...[const SizedBox(height: _gap), _buildOrganisatorTile()],
      ]),
    );
  }

  // ============================================================
  // LOGO BAR — SVG ohne colorFilter → Bitcoin-₿ in Orange!
  // ============================================================
  Widget _buildLogoBar() {
    return Row(children: [
      SvgPicture.asset(
        'assets/images/einundzwanzig_logo.svg',
        height: 18,
        // KEIN colorFilter → Bitcoin-₿ bleibt Orange, Text bleibt Weiß
      ),
      const Spacer(),
      _headerIcon(Icons.help_outline_rounded, _showHelpSheet),
      const SizedBox(width: 4),
      _headerIcon(Icons.settings_rounded, _showSettings),
    ]);
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: const Color(0xFF1C1C20), shape: BoxShape.circle, border: Border.all(color: cTileBorder, width: 0.5)),
      child: Icon(icon, color: cTextSecondary, size: 18)));

  // ============================================================
  // TILE BUILDER — Stärkerer Kontrast
  // ============================================================
  Widget _tile({required Widget child, required Color accentColor, VoidCallback? onTap, double opacity = 0.08}) {
    return GestureDetector(onTap: onTap,
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_tileRadius),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [accentColor.withOpacity(opacity), accentColor.withOpacity(opacity * 0.2), const Color(0xFF151517)],
            stops: const [0.0, 0.45, 1.0]),
          border: Border.all(color: cTileBorder, width: 0.8), // stärkerer Border
        ),
        child: child));
  }

  // ============================================================
  // TRUST SCORE
  // ============================================================
  Widget _buildTrustScoreTile() {
    final score = _trustScore;
    return _tile(accentColor: _levelColor, opacity: 0.10, onTap: _showScoreInfoSheet,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(_levelIcon, color: _levelColor, size: 18),
          const SizedBox(width: 8),
          Text(score?.level ?? 'NEU', style: TextStyle(color: _levelColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 14),
        Text((score?.totalScore ?? 0.0).toStringAsFixed(1),
          style: TextStyle(color: _levelColor, fontSize: 38, fontWeight: FontWeight.w900, fontFamily: _mono, height: 1)),
        const SizedBox(height: 4),
        Text('Trust Score', style: TextStyle(color: cTextTertiary, fontSize: 11)),
        if (score != null && !score.meetsPromotionThreshold) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(value: score.promotionProgress, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation(_levelColor.withOpacity(0.6)), minHeight: 4)),
        ] else if (score != null && score.meetsPromotionThreshold) ...[
          const SizedBox(height: 10),
          Row(children: [Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 14), const SizedBox(width: 4),
            Text('Organisator', style: TextStyle(color: Colors.green.shade400, fontSize: 10, fontWeight: FontWeight.w600))]),
        ],
      ]));
  }

  // ============================================================
  // BADGES
  // ============================================================
  Widget _buildBadgeCountTile() {
    return _tile(accentColor: cPurple,
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => BadgeWalletScreen())); _loadBadges(); _calculateTrustScore(); },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Icon(Icons.style_rounded, color: cPurple, size: 22),
        const Spacer(),
        Text('${myBadges.length}', style: TextStyle(color: cText, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: _mono, height: 1)),
        const SizedBox(height: 4),
        Text('Badges', style: TextStyle(color: cTextTertiary, fontSize: 11)),
      ]));
  }

  // ============================================================
  // HOME MEETUP
  // ============================================================
  Widget _buildHomeMeetupTile() {
    final hasHome = _homeMeetup != null;
    final badgesHere = hasHome ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length : 0;
    if (!_user.homeMeetupId.isNotEmpty) {
      return _tile(accentColor: cTextTertiary, opacity: 0.05, onTap: _selectHomeMeetup,
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.05)), child: const Icon(Icons.add_rounded, color: cTextTertiary, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Home Meetup wählen', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600)),
            Text('Dein Stammtisch-Meetup', style: TextStyle(color: cTextTertiary, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
        ]));
    }
    return _tile(accentColor: cOrange,
      onTap: hasHome ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _homeMeetup!.city))) : null,
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: cOrange.withOpacity(0.12)),
          child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(_homeMeetup!.coverImagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded, color: cOrange, size: 22)))
            : const Icon(Icons.home_rounded, color: cOrange, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: Text(hasHome ? _homeMeetup!.city : _user.homeMeetupId, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: cOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(5)),
              child: const Text('HOME', style: TextStyle(color: cOrange, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.3))),
          ]),
          const SizedBox(height: 4),
          Text(hasHome ? [_homeMeetup!.country, if (badgesHere > 0) '$badgesHere Badges hier'].join(' · ') : 'Lade...', style: const TextStyle(color: cTextTertiary, fontSize: 11)),
        ])),
        if (hasHome) ...[const SizedBox(width: 8),
          _miniAction(Icons.info_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!)))),
          const SizedBox(width: 6),
          _miniAction(Icons.swap_horiz_rounded, _selectHomeMeetup)],
      ]));
  }

  Widget _miniAction(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: cTextSecondary, size: 16)));

  // ============================================================
  // REPUTATION
  // ============================================================
  Widget _buildReputationTile() => _tile(accentColor: Colors.amber,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24),
      const SizedBox(height: 14),
      const Text('Reputation', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(myBadges.isNotEmpty ? 'QR teilen & prüfen' : 'Scannen & prüfen', style: const TextStyle(color: cTextTertiary, fontSize: 10)),
    ]));

  // ============================================================
  // COMMUNITY
  // ============================================================
  Widget _buildCommunityTile() => _tile(accentColor: cCyan,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.hub_rounded, color: cCyan, size: 24),
      const SizedBox(height: 14),
      const Text('Community', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      const Text('Portal & Netzwerk', style: TextStyle(color: cTextTertiary, fontSize: 10)),
    ]));

  // ============================================================
  // EVENTS
  // ============================================================
  Widget _buildEventsTile() => _tile(accentColor: const Color(0xFF8090A0),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.event_rounded, color: Color(0xFF8090A0), size: 22),
      const SizedBox(height: 10),
      const Text('Events', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      const Text('Kalender', style: TextStyle(color: cTextTertiary, fontSize: 10)),
    ]));

  // ============================================================
  // SHOUTOUT TILE — Ersetzt Identity (keine Dopplung mit Profil)
  // ============================================================
  Widget _buildShoutoutTile() => _tile(accentColor: cOrange, opacity: 0.10,
    onTap: () => _openUrl('https://shoutout.einundzwanzig.space'),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.campaign_rounded, color: cOrange, size: 22),
      const SizedBox(height: 10),
      const Text('Shoutout', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      const Text('Senden', style: TextStyle(color: cTextTertiary, fontSize: 10)),
    ]));

  // ============================================================
  // PODCAST TILE — Ersetzt Scanner (keine Dopplung mit FAB)
  // ============================================================
  Widget _buildPodcastTile() => _tile(accentColor: cPurple, opacity: 0.10,
    onTap: () => _openUrl('https://einundzwanzig.space/podcast/'),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.podcasts_rounded, color: cPurple, size: 22),
      const SizedBox(height: 10),
      const Text('Podcast', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      const Text('Anhören', style: TextStyle(color: cTextTertiary, fontSize: 10)),
    ]));

  // ============================================================
  // ORGANISATOR
  // ============================================================
  Widget _buildOrganisatorTile() => _tile(accentColor: _justPromoted ? Colors.green : cPurple,
    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); },
    child: Row(children: [
      Icon(Icons.admin_panel_settings_rounded, color: _justPromoted ? Colors.green : cPurple, size: 24),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Organisator', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(_justPromoted ? 'Neu via Trust Score!' : _user.promotionSource == 'trust_score' ? 'Via Trust Score' : 'Tags erstellen', style: const TextStyle(color: cTextTertiary, fontSize: 11)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20),
    ]));

  // ============================================================
  // ACTIVE SESSION
  // ============================================================
  Widget _buildActiveSessionTile() => AnimatedBuilder(animation: _pulseController,
    builder: (_, __) => GestureDetector(
      onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(_tileRadius),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.green.withOpacity(0.12), Colors.green.withOpacity(0.04), const Color(0xFF151517)], stops: const [0.0, 0.4, 1.0]),
          border: Border.all(color: Colors.green.withOpacity(0.25), width: 0.8)),
        child: Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3 * _pulseController.value), blurRadius: 8)])),
          const SizedBox(width: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text('LIVE', style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800))),
          const SizedBox(width: 10),
          Expanded(child: Text(_activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : 'Meetup aktiv', style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(_sessionTimeLeft, style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: _mono)),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.4), size: 14),
        ]))));

  // ============================================================
  // DEVICE WARNING
  // ============================================================
  Widget _buildDeviceWarning() => Container(padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(_tileRadius), color: Colors.orange.withOpacity(0.06), border: Border.all(color: Colors.orange.withOpacity(0.2), width: 0.8)),
    child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18), const SizedBox(width: 10),
      Expanded(child: Text(DeviceIntegrityService.warningMessage, style: TextStyle(color: Colors.orange.shade200, fontSize: 11))),
      GestureDetector(onTap: () => setState(() => _dismissedIntegrityWarning = true), child: Icon(Icons.close_rounded, color: Colors.orange.shade300, size: 16))]));

  // ============================================================
  // BOTTOM SHEETS — 1:1
  // ============================================================
  void _showHelpSheet() { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => DraggableScrollableSheet(initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false,
      builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text("SO FUNKTIONIERT'S", style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          _helpItem(Icons.military_tech, cOrange, "BADGES SAMMELN", "Scanne den NFC-Tag oder Rolling-QR-Code bei einem Meetup."),
          _helpItem(Icons.workspace_premium, Colors.amber, "REPUTATION AUFBAUEN", "Dein Trust Score steigt mit jedem Badge."),
          _helpItem(Icons.admin_panel_settings, Colors.green, "ORGANISATOR WERDEN", "Ab genügend Trust Score wirst du automatisch befördert."),
          _helpItem(Icons.verified_user, cCyan, "KRYPTOGRAPHISCHE SICHERHEIT", "BIP-340 Schnorr-Signaturen. Unfälschbar."),
          _helpItem(Icons.qr_code_scanner, cPurple, "REPUTATION PRÜFEN", "Teile deinen QR-Code. Kryptographisch verifiziert."),
          _helpItem(Icons.upload, Colors.blue, "BACKUP", "Sichere deinen Account über die Einstellungen."),
          const SizedBox(height: 12), const Divider(color: cBorder), const SizedBox(height: 8),
          Row(children: [const Icon(Icons.lock_outline_rounded, color: cTextTertiary, size: 14), const SizedBox(width: 8),
            Expanded(child: Text("Alle Daten auf deinem Gerät. Kein Server.", style: TextStyle(color: cTextTertiary, fontSize: 10)))]),
        ])))); }

  Widget _helpItem(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 18),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 20), const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 4),
        Text(d, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5))]))]));

  void _showSettings() { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 24),
        _sGroup("DATENSICHERUNG"),
        _sTile(Icons.upload_rounded, Colors.blue, "Backup erstellen", "Sichere deinen Account", () async { Navigator.pop(context); await BackupService.createBackup(context); }),
        const SizedBox(height: 16), _sGroup("NOSTR-NETZWERK"),
        _sTile(Icons.hub_rounded, cCyan, "Nostr-Relays", "Relays konfigurieren", () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
        const SizedBox(height: 16), _sGroup("ACCOUNT"),
        _sTile(Icons.delete_forever_rounded, Colors.red, "App zurücksetzen", "Löscht Profil und Badges", () { Navigator.pop(context); _resetApp(); }),
      ]))); }

  Widget _sGroup(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(t, style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)));
  Widget _sTile(IconData i, Color c, String t, String s, VoidCallback onTap) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: c, size: 20)),
    title: Text(t, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(s, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
    onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 4));

  void _showScoreInfoSheet() { final score = _trustScore;
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.80, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text("DEIN TRUST SCORE", style: TextStyle(color: cOrange, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            const Text("Misst deine Vertrauenswürdigkeit in der Community.", style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
            const SizedBox(height: 24),
            const Text("TRUST LEVEL", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _lvl(Icons.fiber_new, "NEU", "< 3", Colors.grey, score?.level == 'NEU'),
            _lvl(Icons.eco, "STARTER", "3–9", cOrange, score?.level == 'STARTER'),
            _lvl(Icons.local_fire_department, "AKTIV", "10–19", cCyan, score?.level == 'AKTIV'),
            _lvl(Icons.shield, "ETABLIERT", "20–39", Colors.green, score?.level == 'ETABLIERT'),
            _lvl(Icons.bolt, "VETERAN", "40+", Colors.amber, score?.level == 'VETERAN'),
            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("BERECHNUNG", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            _fac(Icons.military_tech, cOrange, "Meetup-Badges", "Basiswert pro Badge."),
            _fac(Icons.location_on, cCyan, "Diversität", "Verschiedene Städte/Organisatoren."),
            _fac(Icons.people_outline, cPurple, "Signers", "Unabhängige Organisatoren."),
            _fac(Icons.schedule, Colors.green, "Reife", "Regelmäßigkeit + Account-Alter."),
            _fac(Icons.speed, cRed, "Frequency Cap", "Max. 2 Badges/Woche."),
            const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
            const Text("ORGANISATOR", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text("Automatische Beförderung ab genügend Trust.", style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
            const SizedBox(height: 14),
            if (score != null && !score.meetsPromotionThreshold)
              Container(width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: cOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: cOrange.withOpacity(0.2))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("FORTSCHRITT (${score.activeThresholds.name})", style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  const SizedBox(height: 10), ...score.progress.entries.map((e) => _pRow(e.value))]))
            else if (score != null)
              Container(width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.green.withOpacity(0.2))),
                child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 20), const SizedBox(width: 10),
                  Expanded(child: Text("Du bist bereits Organisator!", style: TextStyle(color: Colors.green.shade300, fontSize: 12)))])),
            const SizedBox(height: 20),
          ])))); }

  Widget _lvl(IconData i, String n, String r, Color c, bool a) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: a ? c.withOpacity(0.06) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: a ? Border.all(color: c.withOpacity(0.2)) : null),
    child: Row(children: [Icon(i, color: a ? c : c.withOpacity(0.3), size: 18), const SizedBox(width: 12),
      Expanded(child: Row(children: [Text(n, style: TextStyle(color: a ? c : cTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Text(r, style: const TextStyle(color: cTextTertiary, fontSize: 10))])),
      if (a) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
        child: Text('DU', style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w800)))]));

  Widget _fac(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 18), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2),
        Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))]))]));

  Widget _pRow(PromotionProgress p) => Padding(padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [Icon(p.met ? Icons.check_circle : Icons.radio_button_unchecked, color: p.met ? Colors.green : cTextTertiary, size: 16), const SizedBox(width: 8),
      Expanded(child: Text("${p.label}: ${p.current}/${p.required}", style: TextStyle(color: p.met ? Colors.green.shade300 : cTextSecondary, fontSize: 11, fontWeight: p.met ? FontWeight.w600 : FontWeight.normal))),
      SizedBox(width: 40, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(value: p.percentage, backgroundColor: cSurface, valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange))))]));
}