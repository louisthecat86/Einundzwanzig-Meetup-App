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
import 'wot_dashboard.dart';
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
  final String label;
  final int span; // 1=drittel, 2=zwei-drittel, 3=voll
  final Widget Function() builder;
  final bool Function() visible;
  final bool removable; // false = Pflicht-Kachel, kann nicht ausgeblendet werden

  _TileDef({required this.id, required this.label, required this.span, required this.builder, bool Function()? visible, this.removable = true})
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

  // Nostr
  bool _nostrHasNew = false;
  static const _nostrEinundzwanzigNpub = 'npub1qv02xpsc3lhxxx5x7xswf88w3u7kykft9ea7t78tz7ywxf7mxs9qrxujnc';
  // ↑ npub von Einundzwanzig auf Nostr. Bei Bedarf anpassen.

  // Tile Order & Visibility
  List<String> _tileOrder = [];
  Set<String> _hiddenTiles = {};
  // Pflicht-Kacheln (nicht löschbar)
  static const _requiredTiles = {'trust_score', 'home_meetup', 'reputation'};
  // Standard-Reihenfolge (alle optionalen Tiles sind sichtbar by default, wot_dashboard versteckt)
  static const _defaultOrder = ['trust_score', 'home_meetup', 'reputation', 'community', 'nostr', 'events', 'shoutout', 'podcast', 'organisator', 'wot_dashboard'];
  static const _defaultHidden = {'wot_dashboard'};

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
      // ── Pflicht-Kacheln (removable: false) ──
      _TileDef(id: 'trust_score',  label: 'Trust Score',      span: 2, removable: false, builder: _buildTrustScoreTile),
      // countdown-Kachel wurde in Home Meetup integriert
      _TileDef(id: 'home_meetup',  label: 'Home Meetup',      span: 3, removable: false, builder: _buildHomeMeetupTile),
      _TileDef(id: 'reputation',   label: 'Reputation',       span: 1, removable: false, builder: _buildReputationTile),
      // ── Optionale Kacheln (removable: true) ──
      _TileDef(id: 'community',    label: 'Community',        span: 2, builder: _buildCommunityTile),
      _TileDef(id: 'events',       label: 'Events',           span: 1, builder: _buildEventsTile),
      _TileDef(id: 'shoutout',     label: 'Shoutout',         span: 1, builder: _buildShoutoutTile),
      _TileDef(id: 'podcast',      label: 'Podcast',          span: 1, builder: _buildPodcastTile),
      _TileDef(id: 'nostr',        label: 'Nostr',            span: 1, builder: _buildNostrTile),
      _TileDef(id: 'organisator',  label: 'Organisator',      span: 3, builder: _buildOrganisatorTile, visible: () => _user.isAdmin),
      // ── Admin-optionale Kacheln ──
      _TileDef(id: 'wot_dashboard', label: 'WoT Dashboard',  span: 3, builder: _buildWotDashboardTile, visible: () => _user.isAdmin),
    ];
  }

  Future<void> _loadTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tile_order');
    final savedHidden = prefs.getStringList('tile_hidden')?.toSet() ?? Set.from(_defaultHidden);

    if (saved != null && saved.isNotEmpty) {
      // Merge: gespeicherte Reihenfolge + neue Tiles die noch nicht drin sind
      final known = saved.where((id) => _defaultOrder.contains(id)).toList();
      for (final id in _defaultOrder) { if (!known.contains(id)) known.add(id); }
      setState(() { _tileOrder = known; _hiddenTiles = savedHidden; });
    } else {
      setState(() { _tileOrder = List.from(_defaultOrder); _hiddenTiles = Set.from(_defaultHidden); });
    }
  }

  Future<void> _saveTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tile_order', _tileOrder);
    await prefs.setStringList('tile_hidden', _hiddenTiles.toList());
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
    _loadNextHomeMeetup(); _loadProfilePicture(); _checkNostrNew();
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

  void _checkNostrNew() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getInt('nostr_last_seen') ?? 0;
      // Prüfe via NostrService ob es neue Events gibt (einfache Timestamp-Prüfung)
      // Falls der Service keine direkte Methode hat, nutzen wir einen 24h-Hinweis
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final dayAgo = now - 86400;
      if (lastSeen < dayAgo) {
        if (mounted) setState(() => _nostrHasNew = true);
      }
    } catch (_) {}
  }

  void _openNostr() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('nostr_last_seen', DateTime.now().millisecondsSinceEpoch ~/ 1000);
    if (mounted) setState(() => _nostrHasNew = false);
    // Versuche zunächst die Nostr-App zu öffnen (universelles Schema)
    final nostrUri = Uri.parse('nostr:$_nostrEinundzwanzigNpub');
    final webUri = Uri.parse('https://njump.me/$_nostrEinundzwanzigNpub');
    try {
      if (!await launchUrl(nostrUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
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
      .where((t) => t != null && t.visible() && !_hiddenTiles.contains(t!.id))
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
    SvgPicture.asset('assets/images/einundzwanzig_logo.svg', height: 16),
    const Spacer(),
    _headerIcon(Icons.settings_rounded, _showSettings),
  ]);

  Widget _headerIcon(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: cTextTertiary, size: 18)));

  // ============================================================
  // PROFILE HEADER — Avatar + Name + Level
  // ============================================================
  Widget _buildProfileHeader() {
    return Row(children: [
      // Avatar — simpler Kreis, kein Gradient
      GestureDetector(
        onTap: _user.hasNostrKey && _profilePicUrl != null ? null : _pickLocalProfilePicture,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: cCard,
            border: Border.all(color: cTileBorder, width: 1),
          ),
          child: ClipOval(
            child: _localProfilePic != null
              ? Image.file(File(_localProfilePic!), fit: BoxFit.cover, width: 40, height: 40, errorBuilder: (_, __, ___) => _avatarFallback())
              : _profilePicUrl != null
                ? Image.network(_profilePicUrl!, fit: BoxFit.cover, width: 40, height: 40, errorBuilder: (_, __, ___) => _avatarFallback())
                : _avatarFallback(),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Name + Level — alles auf einer Zeile
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(_user.nickname, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
        if (_trustScore != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: cTileBorder, borderRadius: BorderRadius.circular(4)),
            child: Text(_trustScore!.level, style: TextStyle(color: _levelColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ])),
      // Badges — dezent rechts
      Text('${myBadges.length}', style: const TextStyle(color: cTextTertiary, fontSize: 13, fontWeight: FontWeight.w600)),
      const SizedBox(width: 2),
      const Icon(Icons.military_tech_rounded, color: cTextTertiary, size: 14),
    ]);
  }

  Widget _avatarFallback() => Container(
    color: cCard,
    child: Center(child: Text(
      _user.nickname.isNotEmpty ? _user.nickname[0].toUpperCase() : '?',
      style: const TextStyle(color: cTextSecondary, fontSize: 18, fontWeight: FontWeight.w700))));

  // ============================================================
  // TILE BUILDER — Dezenterer Mirror-Gradient
  // ============================================================
  // Flat tile — kein Gradient, kein farbiger Hintergrund
  // accentColor + opacity bleiben als Parameter (Rückwärtskompatibilität), werden aber ignoriert.
  Widget _tile({required Widget child, required Color accentColor, VoidCallback? onTap, double opacity = 0.06}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: _showReorderSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: child,
      ),
    );
  }

  // ============================================================
  // REORDER SHEET — Long press öffnet Sortierung
  // ============================================================
  void _showReorderSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CustomizeSheet(
        order: List.from(_tileOrder),
        hidden: Set.from(_hiddenTiles),
        tileDefs: _tileDefs.where((t) => t.visible()).toList(),
        onSave: (newOrder, newHidden) {
          setState(() { _tileOrder = newOrder; _hiddenTiles = newHidden; });
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
    return GestureDetector(
      onTap: _showScoreInfoSheet,
      onLongPress: _showReorderSheet,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [Icon(_levelIcon, color: _levelColor, size: 14), const SizedBox(width: 6),
            Text(score?.level ?? 'NEU', style: TextStyle(color: _levelColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8))]),
          const SizedBox(height: 12),
        Text((score?.totalScore ?? 0.0).toStringAsFixed(1), style: TextStyle(color: cText, fontSize: 38, fontWeight: FontWeight.w900, fontFamily: fontMono, height: 1)),
        const SizedBox(height: 4),
        const Text('Trust Score', style: TextStyle(color: cText, fontSize: 12)),
        if (score != null && !score.meetsPromotionThreshold) ...[const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: score.promotionProgress, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation(_levelColor.withOpacity(0.6)), minHeight: 4))],
        if (score != null && score.meetsPromotionThreshold) ...[const SizedBox(height: 10),
          Row(children: [Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 14), const SizedBox(width: 4), Text('Organisator', style: TextStyle(color: Colors.green.shade400, fontSize: 11, fontWeight: FontWeight.w600))])],
        ])));
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
    final hasHome = _user.homeMeetupId.isNotEmpty;
    final cityName = _homeMeetup?.city ?? _user.homeMeetupId;
    final bh = _homeMeetup != null ? myBadges.where((b) => b.meetupName == _homeMeetup!.city).length : 0;

    if (!hasHome) {
      // Call-to-Action: noch kein Home Meetup gewählt
      return GestureDetector(
        onLongPress: _showReorderSheet,
        onTap: _selectHomeMeetup,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cOrange.withOpacity(0.35), width: 1.5),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [cOrange.withOpacity(0.10), const Color(0xFF141416)]),
          ),
          child: Row(children: [
            Container(width: 54, height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: cOrange.withOpacity(0.14)),
              child: const Icon(Icons.add_location_rounded, color: cOrange, size: 28)),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HOME MEETUP', style: TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              SizedBox(height: 5),
              Text('Wähle deinen Stammtisch', style: TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)),
              SizedBox(height: 3),
              Text('Dein regelmäßiges Meetup auswählen', style: TextStyle(color: cTextTertiary, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: cOrange, size: 24),
          ]),
        ),
      );
    }

    return GestureDetector(
      onLongPress: _showReorderSheet,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(kTileRadius),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [cOrange.withOpacity(0.20), cOrange.withOpacity(0.07), const Color(0xFF141416)],
            stops: const [0.0, 0.45, 1.0]),
          border: Border.all(color: cOrange.withOpacity(0.38), width: 1.2),
          boxShadow: [BoxShadow(color: cOrange.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header: Label + Badge-Count ──
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: cOrange.withOpacity(0.22), borderRadius: BorderRadius.circular(6)),
              child: const Text('HOME MEETUP', style: TextStyle(color: cOrange, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
            const Spacer(),
            if (bh > 0) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.military_tech_rounded, color: cOrange, size: 11),
                const SizedBox(width: 4),
                Text('$bh Badges', style: const TextStyle(color: cOrange, fontSize: 9, fontWeight: FontWeight.w700)),
              ])),
          ]),

          const SizedBox(height: 16),

          // ── City Name — PROMINANT ──
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Meetup Bild oder Home-Icon
            Container(width: 52, height: 52,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: cOrange.withOpacity(0.14)),
              child: _homeMeetup != null && _homeMeetup!.coverImagePath.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(12),
                    child: Image.network(_homeMeetup!.coverImagePath, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.home_rounded, color: cOrange, size: 26)))
                : const Icon(Icons.home_rounded, color: cOrange, size: 26)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cityName.toUpperCase(),
                style: const TextStyle(color: cText, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.05)),
              const SizedBox(height: 3),
              Text(_homeMeetup?.country ?? '∙∙∙',
                style: const TextStyle(color: cTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
            ])),
          ]),

          const SizedBox(height: 14),

          // ── Nächster Termin ──
          if (_countdownLoading)
            const SizedBox(height: 16, child: LinearProgressIndicator(color: cOrange, backgroundColor: Colors.transparent))
          else if (_nextHomeMeetup != null) Builder(builder: (_) {
            final days = _nextHomeMeetup!.startTime.difference(DateTime.now()).inDays;
            return Row(children: [
              const Icon(Icons.event_available_rounded, color: cTextTertiary, size: 15),
              const SizedBox(width: 7),
              Text(
                days == 0 ? 'Heute!' : days == 1 ? 'Morgen' : 'in ${days} Tagen',
                style: TextStyle(
                  color: days == 0 ? cOrange : days <= 3 ? cOrange.withOpacity(0.8) : cTextSecondary,
                  fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(width: 5),
              Expanded(child: Text(
                '· ${_nextHomeMeetup!.startTime.day}.${_nextHomeMeetup!.startTime.month}.${_nextHomeMeetup!.startTime.year}',
                style: const TextStyle(color: cTextTertiary, fontSize: 13))),
            ]);
          })
          else if (_user.homeMeetupId.isNotEmpty)
            const Row(children: [
              Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 15),
              SizedBox(width: 7),
              Text('Kein Termin geplant', style: TextStyle(color: cTextTertiary, fontSize: 13)),
            ]),

          const SizedBox(height: 14),

          // ── Action Buttons ──
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: _homeMeetup != null
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _homeMeetup!.city)))
                : null,
              child: Container(
                height: 40,
                decoration: BoxDecoration(gradient: gradientOrange, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: cOrange.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))]),
                child: const Center(child: Text('EVENTS', style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8)))),
            )),
            const SizedBox(width: 8),
            if (_homeMeetup != null) GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: _homeMeetup!))),
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.info_outline_rounded, color: cTextSecondary, size: 17))),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _selectHomeMeetup,
              child: Container(width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.swap_horiz_rounded, color: cTextSecondary, size: 17))),
          ]),
        ]),
      ),
    );
  }

  Widget _miniAct(IconData i, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(6), border: Border.all(color: cTileBorder, width: 0.5)), child: Icon(i, color: cTextTertiary, size: 15)));
  Widget _buildReputationTile() => _tile(accentColor: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22), const SizedBox(height: 12), const Text('Reputation', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(myBadges.isNotEmpty ? 'QR teilen' : 'Prüfen', style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildCommunityTile() => _tile(accentColor: cCyan, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityPortalScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.hub_rounded, color: cCyan, size: 22), const SizedBox(height: 12), const Text('Community', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Portal', style: TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildEventsTile() => _tile(accentColor: cTextTertiary, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.event_rounded, color: cTextSecondary, size: 22), const SizedBox(height: 12), const Text('Events', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Kalender', style: TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildShoutoutTile() => _tile(accentColor: cOrange, opacity: 0.07, onTap: () => _openUrl('https://shoutout.einundzwanzig.space'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.campaign_rounded, color: cOrange, size: 22), const SizedBox(height: 12), const Text('Shoutout', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Senden', style: TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildPodcastTile() => _tile(accentColor: cPurple, opacity: 0.07, onTap: () => _openUrl('https://einundzwanzig.space/podcast/'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.podcasts_rounded, color: cPurple, size: 22), const SizedBox(height: 12), const Text('Podcast', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Anhören', style: TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildNostrTile() => _tile(accentColor: cNostr, opacity: 0.07, onTap: _openNostr, child: Stack(children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.bolt_rounded, color: _nostrHasNew ? cNostr : cTextSecondary, size: 22), const SizedBox(height: 12), const Text('Nostr', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), const Text('Community', style: TextStyle(color: cTextTertiary, fontSize: 12))]), if (_nostrHasNew) Positioned(top: 0, right: 0, child: Container(width: 7, height: 7, decoration: const BoxDecoration(color: cOrange, shape: BoxShape.circle)))]));
  Widget _buildOrganisatorTile() => _tile(accentColor: cOrange, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); }, child: Row(children: [Icon(Icons.admin_panel_settings_rounded, color: _justPromoted ? cGreen : cOrange, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Organisator', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(_justPromoted ? 'Neu via Trust Score' : 'Admin-Panel', style: const TextStyle(color: cTextTertiary, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16)]));

  Widget _buildWotDashboardTile() => _tile(
    accentColor: cOrange,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WotDashboardScreen())),
    child: Row(children: [
      const Icon(Icons.account_tree_rounded, color: cTextSecondary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('WoT', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        const Text('Web of Trust', style: TextStyle(color: cTextTertiary, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
    ]),
  );

  Widget _buildActiveSessionTile() => AnimatedBuilder(animation: _pulseController, builder: (_, __) => GestureDetector(
    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cGreen.withOpacity(0.25), width: 0.5)),
    child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withOpacity(0.5 + _pulseController.value * 0.5), boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3 * _pulseController.value), blurRadius: 8)])),
      const SizedBox(width: 14), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text('LIVE', style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10), Expanded(child: Text(_activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : 'Meetup aktiv', style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8), Text(_sessionTimeLeft, style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: fontMono)), const SizedBox(width: 8), Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withOpacity(0.4), size: 14)]))));

  Widget _buildDeviceWarning() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withOpacity(0.3), width: 0.5)),
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
// ============================================================
// CUSTOMIZE SHEET — v2.0
// Drei Sektionen: Fixiert | Aktiv (reorder + hide) | Verfügbar (add)
// ============================================================
class _CustomizeSheet extends StatefulWidget {
  final List<String> order;
  final Set<String> hidden;
  final List<_TileDef> tileDefs;
  final void Function(List<String> order, Set<String> hidden) onSave;

  const _CustomizeSheet({required this.order, required this.hidden, required this.tileDefs, required this.onSave});

  @override
  State<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends State<_CustomizeSheet> {
  late List<String> _order;
  late Set<String> _hidden;

  static const _requiredTiles = {'trust_score', 'home_meetup', 'reputation'};

  @override
  void initState() {
    super.initState();
    _order = List.from(widget.order);
    _hidden = Set.from(widget.hidden);
  }

  _TileDef? _defFor(String id) => widget.tileDefs.where((t) => t.id == id).firstOrNull;
  String _labelFor(String id) => _defFor(id)?.label ?? id;
  IconData _iconFor(String id) {
    switch (id) {
      case 'trust_score': return Icons.shield_rounded;

      case 'home_meetup': return Icons.home_rounded;
      case 'reputation': return Icons.workspace_premium_rounded;
      case 'community': return Icons.hub_rounded;
      case 'events': return Icons.event_rounded;
      case 'shoutout': return Icons.campaign_rounded;
      case 'podcast': return Icons.podcasts_rounded;
      case 'organisator': return Icons.admin_panel_settings_rounded;
      case 'wot_dashboard': return Icons.account_tree_rounded;
      default: return Icons.widgets_rounded;
    }
  }

  Color _colorFor(String id) {
    switch (id) {
      case 'trust_score': return Colors.amber;
      case 'home_meetup': return const Color(0xFFF7931A);
      case 'reputation': return Colors.amber;
      case 'community': return const Color(0xFF00B4CF);
      case 'events': return const Color(0xFF8090A0);
      case 'shoutout': return const Color(0xFFF7931A);
      case 'podcast': return const Color(0xFFA915FF);
      case 'organisator': return const Color(0xFFA915FF);
      case 'wot_dashboard': return const Color(0xFF00B4CF);
      default: return const Color(0xFF9A9AA0);
    }
  }

  void _hide(String id) => setState(() => _hidden.add(id));
  void _show(String id) => setState(() => _hidden.remove(id));

  @override
  Widget build(BuildContext context) {
    // Alle sichtbaren Tiles in gespeicherter Reihenfolge
    final visibleTiles = _order.where((id) {
      final d = _defFor(id);
      if (d == null) return false;
      if (_hidden.contains(id)) return false;
      return true;
    }).toList();

    // Ausgeblendete optionale Tiles
    final availableTiles = widget.tileDefs
      .where((d) => d.removable && _hidden.contains(d.id))
      .map((d) => d.id)
      .toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Header
        Row(children: [
          const Text('ANPASSEN', style: TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const Spacer(),
          TextButton(
            onPressed: () { widget.onSave(_order, _hidden); Navigator.pop(context); },
            child: const Text('FERTIG', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 4),
        const Text('Halten & ziehen zum Sortieren  ·  🔒 = Pflicht  ·  ✕ = ausblenden', style: TextStyle(color: cTextTertiary, fontSize: 10)),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── ALLE AKTIVEN KACHELN (sortierbar) ──
              _sectionHeader(Icons.drag_indicator_rounded, 'AKTIV', 'Alle Kacheln können verschoben werden'),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleTiles.length,
                onReorder: (oldI, newI) {
                  setState(() {
                    if (newI > oldI) newI--;
                    final oldOrderIdx = _order.indexOf(visibleTiles[oldI]);
                    final newOrderIdx = _order.indexOf(visibleTiles[newI]);
                    final item = _order.removeAt(oldOrderIdx);
                    _order.insert(newOrderIdx, item);
                  });
                },
                itemBuilder: (_, i) => _tileRow(visibleTiles[i], ValueKey(visibleTiles[i])),
              ),

              if (availableTiles.isNotEmpty) ...[
                const SizedBox(height: 20),
                // ── VERFÜGBAR ──
                _sectionHeader(Icons.add_circle_outline_rounded, 'VERFÜGBAR', 'Tippe auf + zum Hinzufügen'),
                const SizedBox(height: 8),
                ...availableTiles.map((id) => _availableRow(id)),
              ],

              const SizedBox(height: 8),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _sectionHeader(IconData icon, String title, String subtitle) => Row(children: [
    Text(title, style: const TextStyle(color: cTextSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
    const SizedBox(width: 8),
    Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 10)),
  ]);

  // Einheitliche Zeile: für alle Tiles (fest = Schloss, entfernbar = ✕)
  Widget _tileRow(String id, Key key) {
    final isFixed = _requiredTiles.contains(id);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cTileBorder, width: 0.5)),
      child: Row(children: [
        const Icon(Icons.drag_indicator_rounded, color: cTextTertiary, size: 16),
        const SizedBox(width: 8),
        Icon(_iconFor(id), color: cTextSecondary, size: 15),
        const SizedBox(width: 10),
        Expanded(child: Text(_labelFor(id), style: TextStyle(
          color: isFixed ? cTextSecondary : cText,
          fontSize: 13, fontWeight: FontWeight.w600))),
        isFixed
          ? const Icon(Icons.lock_outline_rounded, color: cTextTertiary, size: 13)
          : GestureDetector(
              onTap: () => _hide(id),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: cTextTertiary, size: 14))),
      ]),
    );
  }

  Widget _availableRow(String id) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorder, width: 0.5)),
    child: Row(children: [
      Icon(_iconFor(id), color: cTextTertiary, size: 15),
      const SizedBox(width: 10),
      Expanded(child: Text(_labelFor(id), style: const TextStyle(color: cTextTertiary, fontSize: 13, fontWeight: FontWeight.w500))),
      GestureDetector(
        onTap: () => _show(id),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: const Icon(Icons.add_rounded, color: cOrange, size: 15),
        ),
      ),
    ]),
  );
}
