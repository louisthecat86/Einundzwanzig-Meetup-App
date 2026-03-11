// ============================================================
// HOME SCREEN — v4.3
// ============================================================
// - Profile header with Nostr avatar (kind:0 picture)
// - Reorderable tiles (long press → drag in bottom sheet)
// - Reduced radius (kTileRadius = 14)
// - Subtler mirror gradients
// - All business logic 1:1 from dashboard.dart
// ============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../models/calendar_event.dart';
import '../services/meetup_service.dart';
import '../services/meetup_calendar_service.dart';
import '../services/trust_score_service.dart';
import '../services/admin_registry.dart';
import '../services/nostr_service.dart';
import '../services/badge_claim_service.dart';
import '../services/reputation_publisher.dart';
import '../services/rolling_qr_service.dart';
import '../services/nostr_profile_service.dart';
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

// ============================================================
// TILE DEFINITION — Jede Kachel hat ID, Span (1-3), Builder
// ============================================================
class _TileDef {
  final String id;
  final String label; // Für Reorder-Sheet
  final int span; // 1=drittel, 2=zwei-drittel, 3=voll
  final Widget Function() builder;
  final bool Function() visible;

  _TileDef({required this.id, required this.label, required this.span, required this.builder, bool Function()? visible})
    : visible = visible ?? (() => true);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // State
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
  CalendarEvent? _nextHomeMeetup;
  bool _countdownLoading = true;

  // Profil
  String? _profilePicUrl;
  String? _localProfilePic;

  // Tile Order
  List<String> _tileOrder = [];
  static const _defaultOrder = ['trust_score', 'countdown', 'home_meetup', 'reputation', 'community', 'events', 'shoutout', 'podcast', 'organisator'];

  late List<_TileDef> _tileDefs;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _initTileDefs();
    _loadTileOrder();
    _loadAll();
  }

  void _initTileDefs() {
    _tileDefs = [
      _TileDef(id: 'trust_score', label: 'Trust Score', span: 2, builder: _buildTrustScoreTile),
      _TileDef(id: 'countdown', label: 'Nächstes Meetup', span: 1, builder: _buildCountdownTile),
      _TileDef(id: 'home_meetup', label: 'Home Meetup', span: 3, builder: _buildHomeMeetupTile),
      _TileDef(id: 'reputation', label: 'Reputation', span: 1, builder: _buildReputationTile),
      _TileDef(id: 'community', label: 'Community', span: 2, builder: _buildCommunityTile),
      _TileDef(id: 'events', label: 'Events', span: 1, builder: _buildEventsTile),
      _TileDef(id: 'shoutout', label: 'Shoutout', span: 1, builder: _buildShoutoutTile),
      _TileDef(id: 'podcast', label: 'Podcast', span: 1, builder: _buildPodcastTile),
      _TileDef(id: 'organisator', label: 'Organisator', span: 3, builder: _buildOrganisatorTile, visible: () => _user.isAdmin),
    ];
  }

  Future<void> _loadTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tile_order');
    if (saved != null && saved.isNotEmpty) {
      // Merge: gespeicherte Reihenfolge + neue Tiles die noch nicht drin sind
      final known = saved.where((id) => _defaultOrder.contains(id)).toList();
      for (final id in _defaultOrder) { if (!known.contains(id)) known.add(id); }
      setState(() => _tileOrder = known);
    } else {
      setState(() => _tileOrder = List.from(_defaultOrder));
    }
  }

  Future<void> _saveTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tile_order', _tileOrder);
  }

  @override
  void dispose() { _sessionTimer?.cancel(); _pulseController.dispose(); super.dispose(); }
  void refreshAfterScan() { _loadBadges(); _calculateTrustScore(); }

  // ============================================================
  // BUSINESS LOGIC (1:1 dashboard.dart + Profilbild + Countdown)
  // ============================================================
  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) { if (mounted) { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); await _loadUser(); } }
    await _loadBadges(); await _calculateTrustScore(); await _reVerifyAdminStatus();
    _loadIdentityData(); _checkActiveSession(); _syncOrganicAdminsInBackground(); _checkDeviceIntegrity();
    _loadNextHomeMeetup(); _loadProfilePicture();
  }

  void _loadProfilePicture() async {
    // Lokales Bild hat Vorrang
    final local = await NostrProfileService.getLocalPicture();
    if (local != null && local.isNotEmpty && mounted) { setState(() => _localProfilePic = local); return; }
    // Nostr-Profilbild laden
    if (_user.hasNostrKey && _user.nostrNpub.isNotEmpty) {
      try {
        final pk = Nip19.decodePubkey(_user.nostrNpub);
        final url = await NostrProfileService.fetchProfilePicture(pk);
        if (url != null && mounted) setState(() => _profilePicUrl = url);
      } catch (_) {}
    }
  }

  void _pickLocalProfilePicture() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 80);
      if (image != null) {
        await NostrProfileService.setLocalPicture(image.path);
        if (mounted) setState(() { _localProfilePic = image.path; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bild konnte nicht geladen werden: $e')));
    }
  }

  void _loadNextHomeMeetup() async {
    if (_user.homeMeetupId.isEmpty) { if (mounted) setState(() => _countdownLoading = false); return; }
    try {
      final events = await MeetupCalendarService().fetchMeetups();
      final now = DateTime.now(); final city = _user.homeMeetupId.toLowerCase();
      final future = events.where((e) => e.startTime.isAfter(now) && (e.title.toLowerCase().contains(city) || e.location.toLowerCase().contains(city))).toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
      if (mounted) setState(() { _nextHomeMeetup = future.isNotEmpty ? future.first : null; _countdownLoading = false; });
    } catch (_) { if (mounted) setState(() => _countdownLoading = false); }
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
  void _resetApp() async { bool c = await showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("App zurücksetzen?"), content: const Text("Alle Badges und dein Profil werden gelöscht."), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbruch")), TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))])) ?? false; if (!c) return; final p = await SharedPreferences.getInstance(); await p.clear(); myBadges.clear(); await MeetupBadge.saveBadges([]); try { await SecureKeyStore.deleteKeys(); } catch (_) {} await NostrProfileService.clearCache(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const IntroScreen()), (r) => false); }
  void _scanAnyMeetup() async { final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0); await Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupVerificationScreen(meetup: d))); _loadBadges(); _calculateTrustScore(); }
  void _selectHomeMeetup() async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetupSelectionScreen())); _loadUser(); _loadNextHomeMeetup(); }
  Future<void> _openUrl(String url) async { final uri = Uri.parse(url); if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Konnte $url nicht öffnen"))); } }

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
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLogoBar(),
        const SizedBox(height: 14),
        _buildProfileHeader(),
        const SizedBox(height: 18),
        if (_deviceCompromised && !_dismissedIntegrityWarning) ...[_buildDeviceWarning(), const SizedBox(height: kTileGap)],
        if (_activeSession != null) ...[_buildActiveSessionTile(), const SizedBox(height: kTileGap)],
        // Dynamisch geordnete Tiles
        ..._buildOrderedTiles(),
      ]),
    );
  }

  // ============================================================
  // DYNAMIC TILE LAYOUT — Packt Tiles in Reihen basierend auf Span
  // ============================================================
  List<Widget> _buildOrderedTiles() {
    final visibleTiles = _tileOrder
      .map((id) => _tileDefs.where((t) => t.id == id).firstOrNull)
      .where((t) => t != null && t.visible())
      .cast<_TileDef>()
      .toList();

    final widgets = <Widget>[];
    int i = 0;
    while (i < visibleTiles.length) {
      final tile = visibleTiles[i];
      if (tile.span == 3) {
        // Full width
        widgets.add(tile.builder());
        widgets.add(const SizedBox(height: kTileGap));
        i++;
      } else {
        // Sammle Tiles für eine Reihe (max span = 3)
        final row = <_TileDef>[tile];
        int rowSpan = tile.span;
        while (i + row.length < visibleTiles.length && rowSpan < 3) {
          final next = visibleTiles[i + row.length];
          if (next.span == 3) break; // Full-width Tile bricht Reihe ab
          if (rowSpan + next.span > 3) break;
          row.add(next);
          rowSpan += next.span;
        }
        widgets.add(IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (int j = 0; j < row.length; j++) ...[
              if (j > 0) const SizedBox(width: kTileGap),
              Expanded(flex: row[j].span, child: row[j].builder()),
            ],
          ]),
        ));
        widgets.add(const SizedBox(height: kTileGap));
        i += row.length;
      }
    }
    return widgets;
  }

  // ============================================================
  // LOGO BAR
  // ============================================================
  Widget _buildLogoBar() => Row(children: [
    SvgPicture.asset('assets/images/einundzwanzig_logo.svg', height: 18),
    const Spacer(),
    _headerIcon(Icons.help_outline_rounded, _showHelpSheet),
    const SizedBox(width: 4),
    _headerIcon(Icons.settings_rounded, _showSettings),
  ]);

  Widget _headerIcon(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: const Color(0xFF1C1C20), shape: BoxShape.circle, border: Border.all(color: cTileBorder, width: 0.5)),
      child: Icon(icon, color: cTextSecondary, size: 18)));

  // ============================================================
  // PROFILE HEADER — Avatar + Name + Level
  // ============================================================
  Widget _buildProfileHeader() {
    final hasAvatar = _localProfilePic != null || _profilePicUrl != null;

    return Row(children: [
      // Avatar
      GestureDetector(
        onTap: _user.hasNostrKey && _profilePicUrl != null ? null : _pickLocalProfilePicture,
        child: Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_levelColor, _levelColor.withOpacity(0.4)]),
            border: Border.all(color: _levelColor.withOpacity(0.3), width: 1.5),
          ),
          child: ClipOval(
            child: _localProfilePic != null
              ? Image.file(File(_localProfilePic!), fit: BoxFit.cover, width: 46, height: 46, errorBuilder: (_, __, ___) => _avatarFallback())
              : _profilePicUrl != null
                ? Image.network(_profilePicUrl!, fit: BoxFit.cover, width: 46, height: 46, errorBuilder: (_, __, ___) => _avatarFallback())
                : _avatarFallback(),
          ),
        ),
      ),
      const SizedBox(width: 14),
      // Name + Level
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_user.nickname, style: const TextStyle(color: cText, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Row(children: [
          if (_trustScore != null) ...[
            Icon(_levelIcon, color: _levelColor, size: 14),
            const SizedBox(width: 4),
            Text(_trustScore!.level, style: TextStyle(color: _levelColor, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
          ],
          Text('${myBadges.length} Badges', style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ]),
      ])),
      // Wenn kein Nostr-Bild: Kamera-Button
      if (!hasAvatar)
        GestureDetector(
          onTap: _pickLocalProfilePicture,
          child: Container(width: 32, height: 32,
            decoration: BoxDecoration(color: cOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.add_a_photo_rounded, color: cOrange, size: 16)),
        ),
    ]);
  }

  Widget _avatarFallback() => Container(
    color: _levelColor.withOpacity(0.15),
    child: Center(child: Text(
      _user.nickname.isNotEmpty ? _user.nickname[0].toUpperCase() : '?',
      style: TextStyle(color: _levelColor, fontSize: 20, fontWeight: FontWeight.w800))));

  // ============================================================
  // TILE BUILDER — Dezenterer Mirror-Gradient
  // ============================================================
  Widget _tile({required Widget child, required Color accentColor, VoidCallback? onTap, double opacity = 0.06}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: _showReorderSheet,
      child: Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kTileRadius),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [accentColor.withOpacity(opacity), accentColor.withOpacity(opacity * 0.15), const Color(0xFF141416)],
            stops: const [0.0, 0.35, 1.0]),
          border: Border.all(color: cTileBorder, width: 0.8)),
        child: child));
  }

  // ============================================================
  // REORDER SHEET — Long press öffnet Sortierung
  // ============================================================
  void _showReorderSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReorderSheet(
        order: List.from(_tileOrder),
        tileDefs: _tileDefs,
        onSave: (newOrder) {
          setState(() => _tileOrder = newOrder);
          _saveTileOrder();
        },
      ),
    );
  }

  // ============================================================
  // TILE BUILDERS
  // ============================================================
  Widget _buildTrustScoreTile() {
    final score = _trustScore;
    return _tile(accentColor: _levelColor, opacity: 0.08, onTap: _showScoreInfoSheet,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(_levelIcon, color: _levelColor, size: 18), const SizedBox(width: 8),
          Text(score?.level ?? 'NEU', style: TextStyle(color: _levelColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5))]),
        const SizedBox(height: 14),
        Text((score?.totalScore ?? 0.0).toStringAsFixed(1), style: TextStyle(color: cText, fontSize: 38, fontWeight: FontWeight.w900, fontFamily: fontMono, height: 1)),
        const SizedBox(height: 4),
        const Text('Trust Score', style: TextStyle(color: cText, fontSize: 12)),
        if (score != null && !score.meetsPromotionThreshold) ...[const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: score.promotionProgress, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation(_levelColor.withOpacity(0.6)), minHeight: 4))],
        if (score != null && score.meetsPromotionThreshold) ...[const SizedBox(height: 10),
          Row(children: [Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 14), const SizedBox(width: 4), Text('Organisator', style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.w600))])],
      ]));
  }

  Widget _buildCountdownTile() {
    if (_countdownLoading) return _tile(accentColor: cCyan, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.hourglass_top_rounded, color: cCyan, size: 22), const Spacer(), const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan)), const SizedBox(height: 8), const Text('Lade...', style: TextStyle(color: cTextTertiary, fontSize: 11))]));
    if (_nextHomeMeetup != null) {
      final days = _nextHomeMeetup!.startTime.difference(DateTime.now()).inDays;
      return _tile(accentColor: cCyan, opacity: 0.08, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _user.homeMeetupId))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Icon(Icons.event_available_rounded, color: cCyan, size: 22), const Spacer(),
          days == 0 ? const Text('Heute!', style: TextStyle(color: cCyan, fontSize: 26, fontWeight: FontWeight.w900, height: 1))
            : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('$days', style: TextStyle(color: cText, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: fontMono, height: 1)), const SizedBox(width: 4),
              Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(days == 1 ? 'Tag' : 'Tage', style: const TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w600)))]),
          const SizedBox(height: 4), const Text('Nächstes Meetup', style: TextStyle(color: cText, fontSize: 11))]));
    }
    return _tile(accentColor: const Color(0xFF606068), opacity: 0.04, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 22), const Spacer(),
        Text('--', style: TextStyle(color: cText, fontSize: 28, fontWeight: FontWeight.w900, fontFamily: fontMono, height: 1)), const SizedBox(height: 4),
        Text(_user.homeMeetupId.isNotEmpty ? 'Kein Termin in Sicht.\nWird Zeit, das zu ändern!' : 'Erst Home Meetup\nwählen!', style: const TextStyle(color: cTextSecondary, fontSize: 10, height: 1.3))]));
  }

  Widget _buildHomeMeetupTile() {
    final hasHome = _homeMeetup != null; final bh = hasHome ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length : 0;
    if (!_user.homeMeetupId.isNotEmpty) return _tile(accentColor: cTextTertiary, opacity: 0.04, onTap: _selectHomeMeetup, child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.05)), child: const Icon(Icons.add_rounded, color: cTextTertiary, size: 22)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Home Meetup wählen', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600)), Text('Dein Stammtisch-Meetup', style: TextStyle(color: cTextTertiary, fontSize: 11))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20)]));
    return _tile(accentColor: cOrange, onTap: hasHome ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _homeMeetup!.city))) : null, child: Row(children: [
      Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: cOrange.withOpacity(0.12)),
        child: hasHome && _homeMeetup!.coverImagePath.isNotEmpty ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_homeMeetup!.coverImagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded, color: cOrange, size: 22))) : const Icon(Icons.home_rounded, color: cOrange, size: 22)),
      const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Flexible(child: Text(hasHome ? _homeMeetup!.city : _user.homeMeetupId, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)), const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: cOrange.withOpacity(0.15), borderRadius: BorderRadius.circular(5)), child: const Text('HOME', style: TextStyle(color: cOrange, fontSize: 8, fontWeight: FontWeight.w800)))]),
        const SizedBox(height: 4), Text(hasHome ? [_homeMeetup!.country, if (bh > 0) '$bh Badges hier'].join(' · ') : 'Lade...', style: const TextStyle(color: cTextTertiary, fontSize: 11))])),
      if (hasHome) ...[const SizedBox(width: 8), _miniAct(Icons.info_outline_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!)))), const SizedBox(width: 6), _miniAct(Icons.swap_horiz_rounded, _selectHomeMeetup)]]));
  }

  Widget _miniAct(IconData i, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(8)), child: Icon(i, color: cTextSecondary, size: 16)));
  Widget _buildReputationTile() => _tile(accentColor: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 24), const SizedBox(height: 14), const Text('Reputation', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(myBadges.isNotEmpty ? 'QR teilen & prüfen' : 'Scannen & prüfen', style: const TextStyle(color: cTextTertiary, fontSize: 10))]));
  Widget _buildCommunityTile() => _tile(accentColor: cCyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.hub_rounded, color: cCyan, size: 24), const SizedBox(height: 14), const Text('Community', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Portal & Netzwerk', style: TextStyle(color: cTextTertiary, fontSize: 10))]));
  Widget _buildEventsTile() => _tile(accentColor: const Color(0xFF8090A0), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.event_rounded, color: Color(0xFF8090A0), size: 22), const SizedBox(height: 10), const Text('Events', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 2), const Text('Kalender', style: TextStyle(color: cTextTertiary, fontSize: 10))]));
  Widget _buildShoutoutTile() => _tile(accentColor: cOrange, opacity: 0.07, onTap: () => _openUrl('https://shoutout.einundzwanzig.space'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.campaign_rounded, color: cOrange, size: 22), const SizedBox(height: 10), const Text('Shoutout', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 2), const Text('Senden', style: TextStyle(color: cTextTertiary, fontSize: 10))]));
  Widget _buildPodcastTile() => _tile(accentColor: cPurple, opacity: 0.07, onTap: () => _openUrl('https://einundzwanzig.space/podcast/'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.podcasts_rounded, color: cPurple, size: 22), const SizedBox(height: 10), const Text('Podcast', style: TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(height: 2), const Text('Anhören', style: TextStyle(color: cTextTertiary, fontSize: 10))]));
  Widget _buildOrganisatorTile() => _tile(accentColor: _justPromoted ? Colors.green : cPurple, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); }, child: Row(children: [Icon(Icons.admin_panel_settings_rounded, color: _justPromoted ? Colors.green : cPurple, size: 24), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Organisator', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 2), Text(_justPromoted ? 'Neu via Trust Score!' : _user.promotionSource == 'trust_score' ? 'Via Trust Score' : 'Tags erstellen', style: const TextStyle(color: cTextTertiary, fontSize: 11))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 20)]));

  Widget _buildActiveSessionTile() => AnimatedBuilder(animation: _pulseController, builder: (_, __) => GestureDetector(
    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
    child: Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(kTileRadius),
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.green.withOpacity(0.08), Colors.green.withOpacity(0.03), const Color(0xFF141416)], stops: const [0.0, 0.35, 1.0]),
      border: Border.all(color: Colors.green.withOpacity(0.2), width: 0.8)),
    child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3 * _pulseController.value), blurRadius: 8)])),
      const SizedBox(width: 14), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text('LIVE', style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10), Expanded(child: Text(_activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : 'Meetup aktiv', style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8), Text(_sessionTimeLeft, style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: fontMono)), const SizedBox(width: 8), Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.4), size: 14)]))));

  Widget _buildDeviceWarning() => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(kTileRadius), color: Colors.orange.withOpacity(0.06), border: Border.all(color: Colors.orange.withOpacity(0.2), width: 0.8)),
    child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18), const SizedBox(width: 10), Expanded(child: Text(DeviceIntegrityService.warningMessage, style: TextStyle(color: Colors.orange.shade200, fontSize: 11))),
      GestureDetector(onTap: () => setState(() => _dismissedIntegrityWarning = true), child: Icon(Icons.close_rounded, color: Colors.orange.shade300, size: 16))]));

  // ============================================================
  // BOTTOM SHEETS (Help, Settings, Score Info) — wie in v4.2
  // Hier nur gekürzt, identische Logik
  // ============================================================
  void _showHelpSheet() { showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (_) => DraggableScrollableSheet(initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5, expand: false, builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 24),
    const Text("SO FUNKTIONIERT'S", style: TextStyle(color: cOrange, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 20),
    _helpI(Icons.military_tech, cOrange, "BADGES SAMMELN", "Geh zu einem Meetup und scanne den NFC-Tag oder Rolling-QR-Code. Jeder Besuch = ein kryptographisch signiertes Badge."),
    _helpI(Icons.workspace_premium, Colors.amber, "REPUTATION AUFBAUEN", "Dein Trust Score steigt mit jedem Badge. Verschiedene Meetups, Organisatoren und Regelmäßigkeit zählen."),
    _helpI(Icons.admin_panel_settings, Colors.green, "ORGANISATOR WERDEN", "Ab genügend Trust Score wirst du automatisch befördert und kannst eigene NFC-Tags und QR-Codes erstellen."),
    _helpI(Icons.verified_user, cCyan, "KRYPTOGRAPHISCHE SICHERHEIT", "BIP-340 Schnorr-Signaturen. Niemand kann Badges fälschen — auch wir nicht."),
    _helpI(Icons.qr_code_scanner, cPurple, "REPUTATION PRÜFEN", "Teile deinen QR-Code. Andere sehen dein Trust Level — kryptographisch verifiziert."),
    _helpI(Icons.upload, Colors.blue, "BACKUP", "Sichere deinen Account über die Einstellungen. Enthält Nostr-Key und alle Badges."),
    const Divider(color: cBorder), const SizedBox(height: 8),
    Row(children: [const Icon(Icons.lock_outline_rounded, color: cTextTertiary, size: 14), const SizedBox(width: 8), Expanded(child: Text("Alle Daten auf deinem Gerät. Kein Server, kein Tracking.", style: TextStyle(color: cTextTertiary, fontSize: 10)))]),
  ])))); }

  Widget _helpI(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 20), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 4), Text(d, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.5))]))]));

  void _showSettings() async {
    final prefs = await SharedPreferences.getInstance();
    bool haptic = prefs.getBool('haptic_enabled') ?? true;
    if (!mounted) return;
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) => Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 24),
        _sG("DATENSICHERUNG"), _sT(Icons.upload_rounded, Colors.blue, "Backup erstellen", "Sichere deinen Account", () async { Navigator.pop(ctx); await BackupService.createBackup(context); }),
        const SizedBox(height: 16), _sG("NOSTR-NETZWERK"), _sT(Icons.hub_rounded, cCyan, "Nostr-Relays", "Relays konfigurieren", () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
        const SizedBox(height: 16), _sG("BEDIENUNG"),
        ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: cOrange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.vibration_rounded, color: cOrange, size: 20)),
          title: const Text('Vibrationsfeedback', style: TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(haptic ? 'Aktiv' : 'Deaktiviert', style: const TextStyle(color: cTextTertiary, fontSize: 11)),
          trailing: Switch(value: haptic, activeColor: cOrange, onChanged: (v) async { await prefs.setBool('haptic_enabled', v); ss(() => haptic = v); }),
          contentPadding: const EdgeInsets.symmetric(horizontal: 4)),
        const SizedBox(height: 16), _sG("ACCOUNT"), _sT(Icons.delete_forever_rounded, Colors.red, "App zurücksetzen", "Löscht Profil und Badges", () { Navigator.pop(ctx); _resetApp(); }),
      ]))));
  }

  Widget _sG(String t) => Padding(padding: const EdgeInsets.only(bottom: 10, left: 4), child: Text(t, style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)));
  Widget _sT(IconData i, Color c, String t, String s, VoidCallback onTap) => ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(i, color: c, size: 20)), title: Text(t, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w600)), subtitle: Text(s, style: const TextStyle(color: cTextTertiary, fontSize: 11)), onTap: onTap, contentPadding: const EdgeInsets.symmetric(horizontal: 4));

  void _showScoreInfoSheet() {
    final score = _trustScore; final idCount = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 20),
          const Text("DEIN TRUST SCORE", style: TextStyle(color: cOrange, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
          const Text("Misst deine Vertrauenswürdigkeit. Basiert auf kryptographischen Beweisen — niemand kann ihn fälschen.", style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
          // IDENTITY LAYER
          const SizedBox(height: 24), const Text("IDENTITY LAYER", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 8),
          Text("$idCount Verknüpfungen aktiv", style: const TextStyle(color: cTextTertiary, fontSize: 11)), const SizedBox(height: 12),
          _idR(Icons.bolt_rounded, "Proof of Humanity", "Lightning Zap Verifikation", _humanityVerified, Colors.amber),
          _idR(Icons.alternate_email, "NIP-05", "Nostr-Identität (name@domain)", _nip05Verified, cCyan),
          ..._platformNames.map((n) => _idR(Icons.link_rounded, {'telegram': 'Telegram', 'twitter': 'X / Twitter', 'kleinanzeigen': 'Kleinanzeigen'}[n.toLowerCase()] ?? n, "Plattform aktiv", true, Colors.green)),
          if (_platformProofCount == 0) _idR(Icons.link_off_rounded, "Plattformen", "Noch keine verknüpft", false, cTextTertiary),
          // TRUST LEVEL
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          const Text("TRUST LEVEL", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _lvl(Icons.fiber_new, "NEU", "< 3", Colors.grey, "Startlevel. Besuche Meetups um Badges zu sammeln.", score?.level == 'NEU'),
          _lvl(Icons.eco, "STARTER", "3–9", cOrange, "Deine ersten Badges zeigen Community-Teilnahme.", score?.level == 'STARTER'),
          _lvl(Icons.local_fire_department, "AKTIV", "10–19", cCyan, "Regelmäßig dabei. Verschiedene Meetups und Organisatoren stärken dein Profil.", score?.level == 'AKTIV'),
          _lvl(Icons.shield, "ETABLIERT", "20–39", Colors.green, "Vertrauenswürdiges Mitglied. Breit vernetzt und lange dabei.", score?.level == 'ETABLIERT'),
          _lvl(Icons.bolt, "VETERAN", "40+", Colors.amber, "Höchstes Level. Reputation über Monate bewiesen.", score?.level == 'VETERAN'),
          // BERECHNUNG
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          const Text("BERECHNUNG", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _fac(Icons.military_tech, cOrange, "Meetup-Badges", "Basiswert pro Badge. Gut besuchte Meetups wertvoller."),
          _fac(Icons.location_on, cCyan, "Diversität", "Verschiedene Städte/Organisatoren = mehr Punkte."),
          _fac(Icons.people_outline, cPurple, "Signers", "Unabhängige Organisatoren = höherer Trust."),
          _fac(Icons.schedule, Colors.green, "Reife", "Account-Alter + Regelmäßigkeit = Bonus."),
          _fac(Icons.speed, cRed, "Frequency Cap", "Max. 2 Badges/Woche. Anti-Farming."),
          // ORGANISATOR
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          const Text("ORGANISATOR WERDEN", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 8),
          const Text("Automatische Beförderung ab genügend Trust Score. Dann eigene NFC-Tags und QR-Codes erstellen.", style: TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)), const SizedBox(height: 14),
          if (score != null && !score.meetsPromotionThreshold)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cOrange.withOpacity(0.06), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withOpacity(0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("FORTSCHRITT (${score.activeThresholds.name})", style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...score.progress.entries.map((e) => _pRow(e.value))]))
          else if (score != null)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.green.withOpacity(0.06), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: Colors.green.withOpacity(0.2))),
              child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 20), const SizedBox(width: 10), Expanded(child: Text("Du bist bereits Organisator!", style: TextStyle(color: Colors.green.shade300, fontSize: 12)))])),
          // TIPPS
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          const Text("SCORE ERHÖHEN", style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _tip(Icons.event, "Regelmäßig verschiedene Meetups besuchen"), _tip(Icons.explore, "Badges bei Meetups in anderen Städten sammeln"),
          _tip(Icons.group_add, "Badges von verschiedenen Organisatoren"), _tip(Icons.bolt, "Identität mit Lightning-Zap verifizieren"),
          _tip(Icons.alternate_email, "NIP-05 einrichten"), _tip(Icons.link, "Plattformen verknüpfen"),
          const SizedBox(height: 20),
        ]))));
  }

  Widget _idR(IconData i, String l, String d, bool a, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(i, color: a ? c : cTextTertiary.withOpacity(0.5), size: 18), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(color: a ? cText : cTextTertiary, fontSize: 12, fontWeight: FontWeight.w600)), Text(d, style: TextStyle(color: a ? cTextSecondary : cTextTertiary.withOpacity(0.5), fontSize: 10))])), Icon(a ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: a ? c : cTextTertiary.withOpacity(0.3), size: 18)]));
  Widget _lvl(IconData i, String n, String r, Color c, String d, bool a) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: a ? c.withOpacity(0.06) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: a ? Border.all(color: c.withOpacity(0.2)) : null), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withOpacity(a ? 0.15 : 0.06), shape: BoxShape.circle), child: Icon(i, color: a ? c : c.withOpacity(0.3), size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(n, style: TextStyle(color: a ? c : cTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Text(r, style: const TextStyle(color: cTextTertiary, fontSize: 10)), if (a) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text('DU', style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w800)))]]), const SizedBox(height: 3), Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 10, height: 1.3))]))]));
  Widget _fac(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 18), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))]))]));
  Widget _tip(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: cOrange.withOpacity(0.6), size: 16), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4)))]));
  Widget _pRow(PromotionProgress p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(p.met ? Icons.check_circle : Icons.radio_button_unchecked, color: p.met ? Colors.green : cTextTertiary, size: 16), const SizedBox(width: 8), Expanded(child: Text("${p.label}: ${p.current}/${p.required}", style: TextStyle(color: p.met ? Colors.green.shade300 : cTextSecondary, fontSize: 11, fontWeight: p.met ? FontWeight.w600 : FontWeight.normal))), SizedBox(width: 40, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: p.percentage, backgroundColor: cSurface, valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange))))]));
}

// ============================================================
// REORDER SHEET — Drag-and-Drop für Tile-Reihenfolge
// ============================================================
class _ReorderSheet extends StatefulWidget {
  final List<String> order;
  final List<_TileDef> tileDefs;
  final void Function(List<String>) onSave;
  const _ReorderSheet({required this.order, required this.tileDefs, required this.onSave});
  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<_ReorderSheet> {
  late List<String> _order;
  @override
  void initState() { super.initState(); _order = List.from(widget.order); }

  String _labelFor(String id) => widget.tileDefs.where((t) => t.id == id).firstOrNull?.label ?? id;
  IconData _iconFor(String id) {
    switch (id) {
      case 'trust_score': return Icons.workspace_premium_rounded;
      case 'countdown': return Icons.event_available_rounded;
      case 'home_meetup': return Icons.home_rounded;
      case 'reputation': return Icons.star_rounded;
      case 'community': return Icons.hub_rounded;
      case 'events': return Icons.event_rounded;
      case 'shoutout': return Icons.campaign_rounded;
      case 'podcast': return Icons.podcasts_rounded;
      case 'organisator': return Icons.admin_panel_settings_rounded;
      default: return Icons.widgets_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          const Text('KACHELN ANORDNEN', style: TextStyle(color: cOrange, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const Spacer(),
          TextButton(onPressed: () { widget.onSave(_order); Navigator.pop(context); },
            child: const Text('FERTIG', style: TextStyle(fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 8),
        const Text('Halte und ziehe die Kacheln in die gewünschte Reihenfolge.', style: TextStyle(color: cTextTertiary, fontSize: 11)),
        const SizedBox(height: 12),
        Flexible(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            itemCount: _order.length,
            onReorder: (oldI, newI) {
              setState(() {
                if (newI > oldI) newI--;
                final item = _order.removeAt(oldI);
                _order.insert(newI, item);
              });
            },
            itemBuilder: (_, i) => Container(
              key: ValueKey(_order[i]),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF1C1C20), borderRadius: BorderRadius.circular(10), border: Border.all(color: cTileBorder, width: 0.5)),
              child: Row(children: [
                Icon(Icons.drag_indicator_rounded, color: cTextTertiary, size: 20),
                const SizedBox(width: 12),
                Icon(_iconFor(_order[i]), color: cOrange, size: 18),
                const SizedBox(width: 10),
                Text(_labelFor(_order[i]), style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}