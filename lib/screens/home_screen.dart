// ============================================================
// HOME SCREEN — v4.3
// ============================================================
// - Profile header with Nostr avatar (kind:0 picture)
// - Reorderable tiles (long press → drag in bottom sheet)
// - Reduced radius (kTileRadius = 14)
// - Subtler mirror gradients
// - All business logic 1:1 from dashboard.dart
// - NEU: Sprachauswahl (de/en/es/System) im Einstellungs-Sheet
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'profile_edit.dart';
import 'intro.dart';
import 'admin_panel.dart';
import 'converter_screen.dart';
import 'news_screen.dart';
import 'portal_meetups_screen.dart';
import 'rolling_qr_screen.dart';
import 'community_hub_screen.dart';
import 'reputation_card_screen.dart';
import '../services/portal_api_service.dart';
import 'meetup_details.dart';
import 'reputation_qr.dart';
import 'my_network_screen.dart';
import 'relay_settings_screen.dart';
import 'mempool_settings_screen.dart';
import 'plebrap_player_screen.dart';
import '../services/plebrap_audio.dart';
import 'package:just_audio/just_audio.dart';
import 'v4v_screen.dart';
import 'bitcoin_dashboard_screen.dart';
import 'log_screen.dart';
import '../services/mempool.dart';
import '../services/widget_service.dart';
import '../services/signing_service.dart';
import '../services/satoshiduell_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:home_widget/home_widget.dart';
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
import '../services/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/level_labels.dart';

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

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
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
  Timer? _midnightTimer; // Wechsel Heute/Morgen exakt um 0 Uhr
  String _sessionTimeLeft = '';
  bool _deviceCompromised = false;
  bool _dismissedIntegrityWarning = false;
  late final AnimationController _pulseController;
  CalendarEvent? _nextHomeMeetup;
  bool _countdownLoading = true;
  // FAVORITEN-KARTEN: je Favorit-Stadt eine Karte mit deren naechstem Event.
  // Chronologisch sortiert (Stadt mit dem fruehesten Event vorne); Staedte
  // ohne anstehenden Termin haengen hinten (event == null).
  List<_FavCard> _favCards = [];
  List<Meetup> _allMeetupsCache = [];
  final PageController _favPageCtrl = PageController();
  int _favPage = 0;

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
  static const _requiredTiles = {'home_meetup', 'reputation'};
  // Standard-Reihenfolge (alle optionalen Tiles sind sichtbar by default, wot_dashboard versteckt)
  static const _defaultOrder = ['home_meetup', 'reputation', 'trust_network', 'community', 'nostr', 'converter', 'btc_dashboard', 'news', 'portal', 'events', 'shoutout', 'podcast', 'satoshiduell', 'portal_area', 'plebrap', 'organisator', 'wot_dashboard'];
  static const _defaultHidden = {'wot_dashboard', 'news', 'shoutout', 'podcast', 'nostr', 'portal', 'events', 'satoshiduell', 'portal_area', 'plebrap'};

  late List<_TileDef> _tileDefs;
  String _appVersion = ''; // wird in initState aus package_info geladen

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _initTileDefs();
    _loadTileOrder();
    _loadAll();
    _loadAppVersion();
    WidgetService.refreshNews(); // News-Titel + NEU-Status fürs Widget
    WidgetsBinding.instance.addObserver(this); // für Widget-Ziel-Abfrage bei Resume
    _pollWidgetTarget();         // wurde die App über einen Widget-Bereich geöffnet?
    _scheduleMidnightRefresh();  // "Heute"/"Morgen" wechselt exakt um 0 Uhr
  }

  /// Widget-Klick-Routing: Das Ziel liegt im lokalen Speicher (von der
  /// WidgetRouterActivity geschrieben). Wir fragen es beim Start UND bei
  /// jedem App-Aufwachen ab — deterministisch, ohne Intent-Abhängigkeit.
  static const _widgetChannel = MethodChannel('einundzwanzig/widget');
  bool _routingWidgetTarget = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _pollWidgetTarget();
      // Der Mitternachts-Timer ist KEIN Verlass, wenn Android die App
      // schlafen legt (Doze) — dann feuert er verspätet oder gar nicht.
      // Deshalb beim Aufwachen immer neu rechnen und den Timer neu setzen:
      // Handy über Nacht in der Tasche, morgens aufgeklappt -> stimmt sofort.
      _loadNextHomeMeetup();
      _scheduleMidnightRefresh();
    }
  }

  Future<void> _pollWidgetTarget() async {
    if (_routingWidgetTarget) return; // kein Doppel-Routing
    try {
      final t = await _widgetChannel.invokeMethod<String>('getLaunchTarget');
      if (t == null || !mounted) return;
      _routingWidgetTarget = true;
      // kurzer Moment, damit der Frame steht (v.a. beim Kaltstart)
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) _routeWidgetTarget(t);
    } catch (_) {/* egal */} finally {
      _routingWidgetTarget = false;
    }
  }

  void _routeWidgetTarget(String? target) {
    if (target == null || !mounted) return;
    switch (target) {
      case 'news':
        _openNews();
        break;
      case 'bitcoin':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BitcoinDashboardScreen()));
        break;
      case 'meetup':
        // Vorderste Favoriten-Karte = global naechstes Meetup (Widget zeigt sie).
        final frontCity = _favCards.isNotEmpty ? _favCards.first.city : _homeMeetup?.city;
        if (frontCity != null && frontCity.isNotEmpty) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: frontCity)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
        }
        break;
    }
  }

  void _openNews() {
    WidgetService.markNewsSeen(); // NEU-Markierung entfernen
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsScreen()));
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = info.version);
    } catch (_) {/* Version bleibt leer, keine Anzeige */}
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
      _TileDef(id: 'trust_network', label: 'Vertrauensnetzwerk', span: 2, builder: _buildTrustNetworkTile),
      _TileDef(id: 'events',       label: 'Events',           span: 1, builder: _buildEventsTile),
      _TileDef(id: 'shoutout',     label: 'Shoutout',         span: 1, builder: _buildShoutoutTile),
      _TileDef(id: 'podcast',      label: 'Podcast',          span: 1, builder: _buildPodcastTile),
      _TileDef(id: 'satoshiduell', label: 'SatoshiDuell',     span: 2, builder: _buildSatoshiDuellTile),
      _TileDef(id: 'portal_area',  label: 'Portal',           span: 2, builder: _buildPortalAreaTile),
      _TileDef(id: 'plebrap',      label: 'PlebRap',          span: 2, builder: _buildPlebrapTile),
      _TileDef(id: 'nostr',        label: 'Nostr',            span: 1, builder: _buildNostrTile),
      _TileDef(id: 'portal_connect', label: 'Portal', span: 2, builder: _buildPortalConnectTile),
      _TileDef(id: 'converter',    label: 'Rechner',          span: 1, builder: _buildConverterTile),
      _TileDef(id: 'btc_dashboard', label: 'Bitcoin',         span: 2, builder: _buildBtcDashboardTile),
      _TileDef(id: 'news',         label: 'News',             span: 2, builder: _buildNewsTile),
      _TileDef(id: 'portal',       label: 'Meine Meetups',    span: 2, builder: _buildPortalTile),
      _TileDef(id: 'organisator',  label: 'Organisator',      span: 3, builder: _buildOrganisatorTile, visible: () => _user.isAdmin),
      // ── Admin-optionale Kacheln ──
      _TileDef(id: 'wot_dashboard', label: 'WoT Dashboard',  span: 3, builder: _buildWotDashboardTile, visible: () => _user.isAdmin),
    ];
  }

  Future<void> _loadTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('tile_order');
    final savedHidden = prefs.getStringList('tile_hidden')?.toSet() ?? Set.from(_defaultHidden);

    // EINMALIGE MIGRATION (Struktur C): Events-Kachel ausblenden, da der
    // Events-Tab unten alles abdeckt. Bleibt über "Kacheln anpassen"
    // jederzeit wieder einblendbar.
    if (!(prefs.getBool('mig_hide_events_v1') ?? false)) {
      savedHidden.add('events');
      await prefs.setBool('mig_hide_events_v1', true);
      await prefs.setStringList('tile_hidden', List<String>.from(savedHidden));
    }
    // Trust-Score-Kachel entfällt (Score sitzt jetzt in der Kopfzeile).
    if (!(prefs.getBool('mig_trust_header_v1') ?? false)) {
      savedHidden.add('trust_score');
      saved?.remove('trust_score');
      await prefs.setBool('mig_trust_header_v1', true);
      await prefs.setStringList('tile_hidden', List<String>.from(savedHidden));
      if (saved != null) await prefs.setStringList('tile_order', saved);
    }

    // EINMALIGE MIGRATION (v1.3.1): Die neuen Kacheln SatoshiDuell und
    // Portal starten auch bei Bestandsnutzern ausgeblendet — wer sie will,
    // schaltet sie über "Kacheln anpassen" ein.
    if (!(prefs.getBool('mig_hide_new_tiles_v131') ?? false)) {
      savedHidden.addAll(['satoshiduell', 'portal_area', 'plebrap']);
      await prefs.setBool('mig_hide_new_tiles_v131', true);
      await prefs.setStringList('tile_hidden', List<String>.from(savedHidden));
    }

    if (!(prefs.getBool('mig_hide_plebrap_v1') ?? false)) {
      savedHidden.add('plebrap');
      await prefs.setBool('mig_hide_plebrap_v1', true);
      await prefs.setStringList('tile_hidden', List<String>.from(savedHidden));
    }

    if (saved != null && saved.isNotEmpty) {
      // Merge: gespeicherte Reihenfolge + neue Tiles die noch nicht drin sind
      final known = saved.where((id) => _defaultOrder.contains(id)).toList();
      for (final id in _defaultOrder) { if (!known.contains(id)) known.add(id); }
      if (mounted) setState(() { _tileOrder = known; _hiddenTiles = savedHidden; });
    } else {
      if (mounted) setState(() { _tileOrder = List.from(_defaultOrder); _hiddenTiles = Set.from(_defaultHidden); });
    }
  }

  Future<void> _saveTileOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tile_order', _tileOrder);
    await prefs.setStringList('tile_hidden', _hiddenTiles.toList());
  }

  @override
  void dispose() {
    _favPageCtrl.dispose(); WidgetsBinding.instance.removeObserver(this); _sessionTimer?.cancel(); _midnightTimer?.cancel(); _pulseController.dispose(); super.dispose(); }
  void refreshAfterScan() { _loadBadges(); _calculateTrustScore(); _loadNextHomeMeetup(); _checkPortalOrganizer(); _refreshPortalConnected(); }

  bool _refreshing = false;

  /// MANUELLE VOLLAKTUALISIERUNG (Pfeil oben rechts): holt alle Daten neu und
  /// löst die daran hängenden Statusprüfungen aus:
  /// - Badges + Trust Score neu laden
  /// - WoT/Bürgen-Admin-Status neu verifizieren (_reVerifyAdminStatus)
  /// - Portal-Organisator-Status prüfen (Kachel erscheint/verschwindet)
  /// - nächstes Home-Meetup + Portal-Verbindung aktualisieren
  /// So bekommt z.B. ein frisch im Portal ernannter Organisator oder ein
  /// per Nostr Verbürgter seine Rechte/Kachel, ohne die App neu zu starten.
  Future<void> _refreshAll() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.refreshRunning), backgroundColor: cCard,
        duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
    try {
      await _loadUser(skipOrgCheck: true); // Org-Check unten kontrolliert
      await _loadBadges();
      await _calculateTrustScore();
      // REIHENFOLGE WICHTIG: Portal-Check ZUERST (räumt bei Entzug den
      // Admin-Cache), DANN WoT-Verifikation — sonst würde ein veralteter
      // Cache-Treffer den gerade entzogenen Status wieder als Vouch/Seed
      // setzen.
      await _checkPortalOrganizer();      // Portal-Weg (räumt ggf. Cache)
      await _reVerifyAdminStatus();       // WoT/Bürgen-Weg (sieht sauberen Cache)
      _loadNextHomeMeetup();              // void (feuert async intern)
    } catch (_) {/* einzelne Fehler ignorieren, Rest läuft */}
    if (!mounted) return;
    setState(() => _refreshing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.refreshDone), backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating));
  }

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).homeImageLoadError(e.toString()))));
    }
  }

  /// Kalendertage bis zum Meetup — NICHT volle 24-Stunden-Blöcke.
  ///
  /// WARUM NICHT `startTime.difference(DateTime.now()).inDays`:
  /// `Duration.inDays` schneidet ab und zählt vergangene 24-Stunden-Blöcke.
  /// Meetup morgen 19:00, jetzt heute 20:00 -> Differenz 23 h -> inDays = 0
  /// -> die App schrieb "Heute", obwohl es MORGEN ist. Der Fehler trat immer
  /// dann auf, wenn die aktuelle Uhrzeit später war als die Meetup-Uhrzeit.
  ///
  /// Richtig ist der Abstand zwischen den KALENDERTAGEN. Beide Zeitpunkte auf
  /// lokale Mitternacht normalisieren, dann in Stunden messen und auf ganze
  /// Tage runden. Das Runden ist kein Schönheitsfehler, sondern nötig:
  /// bei Sommer-/Winterzeitumstellung hat ein Kalendertag 23 bzw. 25 Stunden —
  /// mit `.inDays` käme sonst an genau zwei Tagen im Jahr wieder 0 statt 1 raus.
  ///
  /// 0 = heute, 1 = morgen, negativ = liegt in der Vergangenheit.
  int _daysUntil(DateTime target) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(target.year, target.month, target.day);
    return (day.difference(today).inHours / 24).round();
  }

  /// Plant den Neuaufbau des Countdowns exakt auf die nächste Mitternacht.
  /// Ohne das würde eine App, die über Mitternacht offen bleibt, weiter
  /// "Morgen" anzeigen, obwohl es längst "Heute" ist — der Wert wird sonst
  /// nur beim Laden berechnet.
  void _scheduleMidnightRefresh() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // 2 s Puffer, damit wir sicher NACH dem Datumswechsel rechnen.
    final wait = nextMidnight.difference(now) + const Duration(seconds: 2);
    _midnightTimer = Timer(wait, () {
      if (!mounted) return;
      _loadNextHomeMeetup();   // rechnet neu und schreibt das Widget
      _scheduleMidnightRefresh(); // für die übernächste Mitternacht
    });
  }

  void _loadNextHomeMeetup() async {
    final favs = _user.favoriteMeetupIds.isNotEmpty
        ? _user.favoriteMeetupIds
        : (_user.homeMeetupId.isNotEmpty ? [_user.homeMeetupId] : <String>[]);
    if (favs.isEmpty) { if (mounted) setState(() { _favCards = []; _countdownLoading = false; }); return; }
    try {
      final events = await MeetupCalendarService().fetchMeetupsPortalFirst();

      // Match-Begriffe fuer EINE Stadt (Titel/Ort/Beschreibung, Teilwoerter).
      bool matchesCity(CalendarEvent e, String cityName) {
        final city = cityName.toLowerCase().trim();
        // Generische Woerter duerfen NIE als Suchbegriff dienen — sonst
        // wuerde z.B. ein Favorit "Einundzwanzig Hildesheim" ueber das
        // Wort "einundzwanzig" JEDES Event der Liste matchen.
        const stop = {'einundzwanzig', 'bitcoin', 'meetup', 'stammtisch'};
        var terms = <String>{city, ...city.split(RegExp(r'[\s,/-]+'))}
            .where((s) => s.length >= 3 && !stop.contains(s));
        if (terms.isEmpty) terms = {city}; // Notanker: ganze Angabe
        // Nur Titel + Ort matchen. Die Beschreibung ist NICHT verlaesslich
        // (ein Event kann andere Staedte erwaehnen -> Fehlzuordnung, die ein
        // spaeteres Event einer Stadt als deren "naechstes" ausweist).
        final hay = '${e.title} ${e.location}'.toLowerCase();
        // WORTGRENZEN statt contains: "Frankfurter Str." in irgendeiner
        // Stadt matchte sonst den Favoriten "Frankfurt" — dessen Karte
        // zeigte dann den fremden Termin (dein 4-statt-6-Tage-Fall).
        return terms.any((term) =>
            RegExp('\\b' + RegExp.escape(term) + '\\b').hasMatch(hay));
      }

      // KALENDERTAG-KULANZ: ein Meetup bleibt den ganzen Tag "naechstes".
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Je Favorit-Stadt das naechste Event bestimmen.
      final cards = <_FavCard>[];
      for (final cityName in favs) {
        final upcoming = events
            .where((e) => !e.startTime.isBefore(todayStart) && matchesCity(e, cityName))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final chosen = upcoming.isNotEmpty ? upcoming.first : null;
        AppLogger.diag('HomeMeetup',
            'Favorit "$cityName": ${upcoming.length} Termine, naechster = '
            '${chosen == null ? "keiner" : "\"${chosen.title}\" am ${chosen.startTime.day}.${chosen.startTime.month}. (${_daysUntil(chosen.startTime)} Tage)"}');
        cards.add(_FavCard(city: cityName, event: chosen));
      }

      // Sortierung: Staedte MIT Termin nach Datum aufsteigend; Staedte OHNE
      // Termin ans Ende. So steht das global naechste Meetup immer vorne.
      cards.sort((a, b) {
        if (a.event == null && b.event == null) return a.city.compareTo(b.city);
        if (a.event == null) return 1;
        if (b.event == null) return -1;
        return a.event!.startTime.compareTo(b.event!.startTime);
      });

      if (mounted) {
        setState(() {
          _favCards = cards;
          // _nextHomeMeetup weiter fuer Kompatibilitaet (Widget/Routing) setzen:
          // das global naechste Event ueber alle Favoriten.
          _nextHomeMeetup = cards.isNotEmpty ? cards.first.event : null;
          _favPage = 0;
          _countdownLoading = false;
        });
        if (_favPageCtrl.hasClients) _favPageCtrl.jumpToPage(0);
      }

      // Homescreen-Widget: vorderste Karte (global naechstes Meetup).
      final front = cards.isNotEmpty ? cards.first : null;
      String countdown = '';
      if (front?.event != null) {
        final days = _daysUntil(front!.event!.startTime);
        countdown = days <= 0 ? 'Heute' : (days == 1 ? 'Morgen' : 'in $days Tagen');
      }
      WidgetService.updateMeetup(city: front?.city ?? '', countdown: countdown);
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

  void _checkActiveSession() async { final s = await RollingQRService.loadSession(); if (s != null && !s.isExpired) { if (mounted) setState(() => _activeSession = s); _startSessionTimer(); } else { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); } }
  void _startSessionTimer() { _sessionTimer?.cancel(); _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (_activeSession == null || _activeSession!.isExpired) { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); return; } if (mounted) setState(() { final r = _activeSession!.remainingTime; _sessionTimeLeft = '${r.inHours}h ${(r.inMinutes % 60).toString().padLeft(2, '0')}m'; }); }); }
  void _syncOrganicAdminsInBackground() async { try { await PromotionClaimService.syncOrganicAdmins(); } catch (_) {} }
  void _checkDeviceIntegrity() async { try { final r = await DeviceIntegrityService.check(); if (r.isCompromised && mounted) setState(() => _deviceCompromised = true); } catch (_) {} }
  Future<void> _loadBadges() async { final badges = await MeetupBadge.loadBadges(); await BadgeClaimService.ensureBadgesClaimed(badges); if (mounted) setState(() { myBadges.clear(); myBadges.addAll(badges); }); if (badges.isNotEmpty) ReputationPublisher.publishInBackground(badges); }
  Future<void> _loadUser({bool skipOrgCheck = false}) async { final u = await UserProfile.load(); Meetup? hm;
    // Meetup-Liste EINMAL laden und cachen — die Favoriten-Karten loesen
    // darueber Land/Wappen/Info-Screen fuer JEDE ihrer Staedte auf.
    if (u.homeMeetupId.isNotEmpty || u.favoriteMeetupIds.isNotEmpty) {
      List<Meetup> m = await MeetupService.fetchMeetups(); if (m.isEmpty) m = allMeetups;
      _allMeetupsCache = m;
      hm = m.where((x) => x.city == u.homeMeetupId).firstOrNull;
    }
    if (mounted) setState(() { _user = u; _homeMeetup = hm; }); if (!skipOrgCheck) _checkPortalOrganizer(); _refreshPortalConnected(); }
  Future<void> _calculateTrustScore() async { if (myBadges.isEmpty) { if (mounted) setState(() => _trustScore = TrustScoreService.calculateScore(badges: [], firstBadgeDate: null)); return; } final s = List<MeetupBadge>.from(myBadges)..sort((a, b) => a.date.compareTo(b.date)); if (mounted) setState(() => _trustScore = TrustScoreService.calculateScore(badges: myBadges, firstBadgeDate: s.first.date, coAttestorMap: null)); }
  /// PORTAL-ORGANISATOR = APP-ADMIN (robust, mit sicherem Entzug):
  /// - Portal-Login (Nostr) + my-meetups nicht leer  -> Admin VERGEBEN
  ///   und automatisch einen signierten Organizer-Claim an Nostr
  ///   publizieren (Sichtbarkeit für Dritte; Portal bleibt Autorität).
  /// - Ist der Nutzer per Portal Admin geworden und my-meetups ist bei
  ///   einer ERFOLGREICHEN Abfrage leer -> Admin ENTZIEHEN (Revocation).
  /// - Netzwerkfehler/offline: KEINE Änderung (kein fälschlicher Entzug).
  /// WoT-Bürgen und Seed-Admins bleiben davon unberührt.
  Future<void> _checkPortalOrganizer() async {
    try {
      AppLogger.diag('Portal', 'Organisator-Prüfung gestartet');

      // AUTO-CONNECT: Ist noch kein Portal-Token da, aber ein Schlüssel
      // aktiv, versucht die App EINMAL leise, sich mit dem Portal zu
      // verbinden. So muss der Nutzer nicht manuell über Community ->
      // Portal -> Meine Meetups gehen. Ist der Nutzer im Portal bekannt,
      // klappt es automatisch; ist er es nicht, passiert nichts Störendes.
      //
      // WICHTIG: Nur bei LOKALEM Schlüssel lautlos. Bei Amber würde die
      // Signatur ein Popup auslösen — das wäre beim App-Start unerwartet.
      // Amber-Nutzer verbinden sich weiter über den manuellen Weg.
      if (!await PortalApiService.hasToken()) {
        if (await SigningService.isAmber) {
          AppLogger.diag('Portal', 'Kein Token, aber Amber aktiv — Auto-Connect übersprungen (kein Überraschungs-Popup).');
          return;
        }
        AppLogger.diag('Portal', 'Kein Token — versuche automatische Verbindung (lokaler Schlüssel).');
        final res = await PortalApiService.loginWithNostr();
        if (res.ok) {
          AppLogger.diag('Portal', 'Automatische Verbindung erfolgreich.');
        } else {
          AppLogger.diag('Portal', 'Automatische Verbindung nicht möglich (Nutzer evtl. nicht im Portal) — übersprungen.');
          return;
        }
      }

      // Token muss zum AKTUELLEN Schlüssel gehören (kein geerbter Login!).
      if (!await PortalApiService.tokenMatchesCurrentKey()) {
        final hasStaleToken = await PortalApiService.hasToken();
        if (hasStaleToken) {
          AppLogger.warn('Portal', 'Token gehört zu anderem Schlüssel — getrennt. Neu verbinden nötig.');
          await PortalApiService.deleteToken();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context).portalTokenMismatch),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 6),
            ));
          }
        } else {
          AppLogger.diag('Portal', 'Kein Portal-Token vorhanden — übersprungen.');
        }
        return;
      }
      // Rohabfrage: null = Fehler/offline (nichts tun), Liste = Fakt.
      final body = await PortalApiService.rawGet('/my-meetups');
      if (body == null || !mounted) { AppLogger.diag('Portal', '/my-meetups: keine Antwort (offline/Fehler) — keine Änderung.'); return; }
      final data = (body is Map) ? body['data'] : body;
      final meetups = (data is List) ? data.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
      AppLogger.diag('Portal', '/my-meetups lieferte ${meetups.length} Meetup(s) für aktuellen Schlüssel.');

      if (meetups.isNotEmpty && !_user.adminViaPortal) {
        // VERGEBEN: nur das Portal-Flag setzen (Vouch/Seed unberührt).
        if (mounted) {
          setState(() {
            _user.adminViaPortal = true;
            _user.isAdminVerified = _user.isAdmin;
          });
        }
        await _user.save();
        // Organizer-Claim an Nostr publizieren (best effort): macht den
        // Status für Dritte sichtbar; kein manuelles Register nötig.
        final meetupName = (meetups.first['name'] ?? _user.homeMeetupId).toString();
        try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: meetupName.isNotEmpty ? meetupName : 'Unbekannt'); } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context).organizerPromoted),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else if (meetups.isEmpty && _user.adminViaPortal) {
        // ENTZIEHEN: nur das Portal-Flag löschen. Bleibt der Nutzer über
        // WoT-Bürgschaft/Seed berechtigt, behält er isAdmin (abgeleitet).
        if (mounted) {
          setState(() {
            _user.adminViaPortal = false;
            _user.isAdminVerified = _user.isAdmin;
          });
        }
        await _user.save();
        // WICHTIG: alten Admin-Cache-Eintrag für den eigenen npub räumen,
        // sonst würde der Registry-Cache ihn weiter als Admin ausweisen
        // (genau der Bug: Kachel kam nach Portal-Entzug wieder).
        // Modus-bewusst (Amber ODER lokal) — SecureKeyStore.getNpub() lieferte
        // bei Amber-Nutzern null, der Cache wurde dann nie geräumt.
        final ownNpub = await SigningService.npub();
        if (ownNpub != null) await AdminRegistry.removeFromCache(ownNpub);
      }
    } catch (_) {/* still: beim nächsten Start erneut */}
  }

  Future<void> _reVerifyAdminStatus() async { try { final v = await _user.reVerifyAdmin(myBadges); if (mounted) setState(() {}); if (v.isAdmin && (v.source == 'trust_score' || v.source == 'vouch_consensus')) { try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt'); } catch (_) {} if (mounted) { setState(() => _justPromoted = true); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).organizerPromoted), backgroundColor: Colors.green.shade700, duration: const Duration(seconds: 5), behavior: SnackBarBehavior.floating)); } } } catch (_) { if (mounted) setState(() { _user.adminViaVouch = false; _user.isAdminVerified = _user.isAdmin; }); } }
  void _resetApp() async {
    final t = AppLocalizations.of(context);
    // 1. Erste Bestätigung (wie bisher)
    final c = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.resetTitle),
        content: Text(t.resetBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.resetCancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.resetConfirm, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    ) ?? false;
    if (!c) return;

    // 2. Backup anbieten, BEVOR gelöscht wird
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.shield_outlined, color: cOrange, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(t.resetBackupTitle, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Text(t.resetBackupBody, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
        actionsOverflowDirection: VerticalDirection.down,
        actions: [
          // Empfohlen: Backup erstellen
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, 'backup'),
            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
            label: Text(t.resetBackupCreate),
          ),
          // Ohne Backup (gefährlich)
          TextButton(onPressed: () => Navigator.pop(ctx, 'skip'), child: Text(t.resetBackupSkip, style: const TextStyle(color: cRed))),
          // Abbrechen
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: Text(t.resetCancel, style: const TextStyle(color: cTextSecondary))),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    if (choice == 'backup') {
      // Backup erstellen (gleiche Logik wie der manuelle Button)
      final ok = await BackupService.createBackup(context);
      if (!ok) return; // Backup abgebrochen/fehlgeschlagen -> NICHT zurücksetzen
      // Nach erfolgreichem Backup nochmal bestätigen
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(t.resetBackupTitle, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          content: Text(t.resetBackupDone, style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.resetCancel, style: const TextStyle(color: cTextSecondary))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.resetNowConfirm, style: const TextStyle(color: cRed, fontWeight: FontWeight.bold))),
          ],
        ),
      ) ?? false;
      if (!proceed) return;
    }

    // 3. Eigentlicher Reset (vollständige Löschung)
    await _performReset();
  }

  /// Führt die vollständige Löschung durch. Nur nach Bestätigung +
  /// (optionalem) Backup aufrufen.
  Future<void> _performReset() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    myBadges.clear();
    await MeetupBadge.saveBadges([]);
    try { await SecureKeyStore.deleteKeys(); } catch (_) {}
    try { await PortalApiService.logout(); } catch (_) {}
    await NostrProfileService.clearCache();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const IntroScreen()), (r) => false);
    }
  }
  void _scanAnyMeetup() async { final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0); await Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupVerificationScreen(meetup: d))); _loadBadges(); _calculateTrustScore(); }
  void _selectHomeMeetup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const MeetupSelectionScreen()));
    // WICHTIG: erst den User FERTIG laden (neue Favoritenliste!), DANN die
    // Karten neu rechnen — sonst rechnet _loadNextHomeMeetup mit den alten
    // Favoriten und schreibt veraltete Daten ins Homescreen-Widget.
    await _loadUser();
    _loadNextHomeMeetup();
  }
  Future<void> _openUrl(String url) async { final uri = Uri.parse(url); if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).homeCouldNotOpen(url)))); } }

  Color get _levelColor { if (_trustScore == null) return cTextTertiary; switch (_trustScore!.level) { case 'VETERAN': return Colors.amber; case 'ETABLIERT': return Colors.green; case 'AKTIV': return cCyan; case 'STARTER': return cOrange; default: return cTextTertiary; } }
  IconData get _levelIcon { if (_trustScore == null) return Icons.fiber_new; switch (_trustScore!.level) { case 'VETERAN': return Icons.bolt; case 'ETABLIERT': return Icons.shield; case 'AKTIV': return Icons.local_fire_department; case 'STARTER': return Icons.eco; default: return Icons.fiber_new; } }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    // FIXES DASHBOARD (nicht scrollbar): Header + Home-Meetup-Kachel sitzen
    // fest oben. Der restliche Kachel-Block wird als GANZES so skaliert,
    // dass er den verbleibenden Raum darunter exakt füllt (3 Kacheln =>
    // groß, 8 Kacheln => proportional kleiner, immer eingepasst).
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildLogoBar(),
        const SizedBox(height: 14),
        _buildProfileHeader(),
        const SizedBox(height: 18),
        if (_deviceCompromised && !_dismissedIntegrityWarning) ...[_buildDeviceWarning(), const SizedBox(height: kTileGap)],
        if (_activeSession != null) ...[_buildActiveSessionTile(), const SizedBox(height: kTileGap)],
        // Fixe Home-Meetup-Kachel (immer gleiche Größe)
        _buildHomeMeetupTile(),
        const SizedBox(height: kTileGap),
        // Restlicher Raum: Kachel-Block füllt exakt bis zur unteren Leiste
        Expanded(child: _buildScaledTileBlock()),
      ]),
    );
  }

  /// Kachel-Block: füllt den Raum zwischen Home-Meetup-Kachel und unterer
  /// Leiste VOLLSTÄNDIG. Jede Reihe bekommt exakt dieselbe berechnete Höhe,
  /// sodass alle Reihen zusammen die volle Höhe ausfüllen (keine Lücke).
  /// Bis die Reihenhöhe unter die Mindesthöhe fällt -> dann scrollbar.
  Widget _buildScaledTileBlock() {
    final rows = _buildTileRows(excludeHomeMeetup: true);
    if (rows.isEmpty) return const SizedBox.shrink();

    const double minRowHeight = 92; // darunter wird gescrollt
    return LayoutBuilder(builder: (context, c) {
      final gaps = (rows.length - 1) * kTileGap;
      final avail = c.maxHeight - gaps;
      final perRow = avail / rows.length;

      if (perRow >= minRowHeight) {
        // FÜLLEN: jede Reihe exakt perRow hoch -> Summe = volle Höhe.
        return Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: kTileGap),
            SizedBox(height: perRow, child: rows[i]),
          ],
        ]);
      }
      // SCROLLEN: Reihen behalten Mindesthöhe.
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: kTileGap),
            SizedBox(height: minRowHeight, child: rows[i]),
          ],
        ]),
      );
    });
  }

  /// Baut die sichtbaren Kacheln als REIHEN (jede Reihe ein Row-Widget mit
  /// stretch), damit sie sich vertikal dehnen lassen.
  List<Widget> _buildTileRows({bool excludeHomeMeetup = false}) {
    final visibleTiles = _tileOrder
      .map((id) => _tileDefs.where((t) => t.id == id).firstOrNull)
      .where((t) => t != null && t.visible() && !_hiddenTiles.contains(t!.id))
      .cast<_TileDef>()
      .where((t) => !excludeHomeMeetup || t.id != 'home_meetup')
      .toList();

    final rows = <Widget>[];
    int i = 0;
    while (i < visibleTiles.length) {
      final tile = visibleTiles[i];
      if (tile.span == 3) {
        rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: tile.builder())]));
        i++;
      } else {
        final row = <_TileDef>[tile];
        int rowSpan = tile.span;
        while (i + row.length < visibleTiles.length && rowSpan < 3) {
          final next = visibleTiles[i + row.length];
          if (next.span == 3) break;
          if (rowSpan + next.span > 3) break;
          row.add(next);
          rowSpan += next.span;
        }
        rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (int j = 0; j < row.length; j++) ...[
            if (j > 0) const SizedBox(width: kTileGap),
            Expanded(flex: row[j].span, child: row[j].builder()),
          ],
        ]));
        i += row.length;
      }
    }
    return rows;
  }

  // ============================================================
  // DYNAMIC TILE LAYOUT — Packt Tiles in Reihen basierend auf Span
  // ============================================================


  // ============================================================
  // LOGO BAR
  // ============================================================
  Widget _buildLogoBar() => Row(children: [
    SvgPicture.asset('assets/images/einundzwanzig_logo.svg', height: 16),
    const Spacer(),
    _headerIcon(_refreshing ? Icons.hourglass_empty_rounded : Icons.refresh_rounded, _refreshing ? () {} : _refreshAll),
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
      // Name (ohne NEU-Badge)
      Expanded(child: Text(_user.nickname, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
      // Trust-Score als kompakte Plakette rechts -> öffnet Reputations-Profil
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationCardScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [cOrange, cOrange.withValues(alpha: 0.78)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text((_trustScore?.totalScore ?? 0.0).toStringAsFixed(1),
                style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900).copyWith(fontFamily: fontMono)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Colors.black54, size: 16),
          ]),
        ),
      ),
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
  Widget _tile({required Widget child, required Color accentColor, VoidCallback? onTap, double opacity = 0.06, IconData? watermark, String? watermarkAsset}) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: _showReorderSheet,
      child: Container(
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kTileRadius),
          child: Stack(
            children: [
              // Wasserzeichen: großes, transparentes Symbol unten rechts
              if (watermark != null)
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Icon(watermark, size: 96, color: accentColor.withValues(alpha: 0.10)),
                ),
              // Bild-Wasserzeichen (z.B. SatoshiDuell-Logo) — gleiche
              // Position/Wirkung wie das Icon-Wasserzeichen.
              if (watermarkAsset != null)
                Positioned(
                  right: -12,
                  bottom: -12,
                  child: Opacity(
                    opacity: 0.13,
                    child: Image.asset(watermarkAsset, width: 100, height: 100, fit: BoxFit.contain,
                        errorBuilder: (_, e, st) => const SizedBox.shrink()),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: child,
                ),
              ),
            ],
          ),
        ),
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
    final t = AppLocalizations.of(context);
    // KOMPAKT & DEZENT: kleine Score-Plakette links (Mini-Version der
    // Reputations-Karte), Level + Fortschritt rechts. Antippen öffnet
    // das volle Reputations-Profil ("Als Bild teilen"-Ansicht).
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationCardScreen())),
      onLongPress: _showReorderSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          // Score-Plakette
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [cOrange, cOrange.withValues(alpha: 0.75)]),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text((score?.totalScore ?? 0.0).toStringAsFixed(1),
                style: TextStyle(color: Colors.black, fontSize: 19, fontWeight: FontWeight.w900, fontFamily: fontMono)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(t.tileTrustScore, style: const TextStyle(color: cText, fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Row(children: [
              Icon(_levelIcon, color: _levelColor, size: 12),
              const SizedBox(width: 5),
              Text(score?.level == null ? t.levelNew : localizedLevel(context, score!.level),
                  style: TextStyle(color: _levelColor, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
              if (score != null && score.meetsPromotionThreshold) ...[
                const SizedBox(width: 8),
                Icon(Icons.verified_rounded, color: Colors.green.shade400, size: 12),
              ],
            ]),
            if (score != null && !score.meetsPromotionThreshold) ...[
              const SizedBox(height: 7),
              ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
                  value: score.promotionProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(_levelColor.withValues(alpha: 0.6)), minHeight: 3.5)),
            ],
          ])),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
        ]),
      ),
    );
  }

  Widget _buildCountdownTile() {
    if (_countdownLoading) return _tile(accentColor: cCyan, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Icon(Icons.hourglass_top_rounded, color: cCyan, size: 22), const Spacer(), const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: cCyan)), const SizedBox(height: 8), const Text('Lade...', style: TextStyle(color: cTextTertiary, fontSize: 11))]));
    if (_nextHomeMeetup != null) {
      final days = _daysUntil(_nextHomeMeetup!.startTime);
      return _tile(accentColor: cCyan, opacity: 0.08, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: _user.homeMeetupId))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Icon(Icons.event_available_rounded, color: cCyan, size: 22), const Spacer(),
          days <= 0 ? const Text('Heute!', style: TextStyle(color: cCyan, fontSize: 26, fontWeight: FontWeight.w900, height: 1))
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

  /// MEETUP-WAPPEN im "Cover-Flow"-Stil (iTunes): quadratisches Wappen,
  /// linke Kante fest, kippt perspektivisch nach rechts hinten und blendet
  /// dorthin weich aus. Bewusst einfach gehalten (robust auf allen Geräten).
  /// CoverFlow-Wappen fuer EINE Stadt (parametrisiert, damit jede
  /// Favoriten-Karte ihr eigenes Wappen zeigt).
  Widget _crestCoverFlow(String city, Meetup? meetup, {double size = 56}) {
    String url = MeetupCalendarService.logoFor(city);
    if (url.isEmpty && meetup != null) {
      // Fallback: Wappen aus /api/meetups — Pfade dort koennen RELATIV
      // sein, deshalb normalisieren (sonst laedt Image.network still nichts
      // und das Wappen fehlt, z.B. Darmstadt/Wiesbaden ohne Termin-Logo).
      url = MeetupCalendarService.absoluteImageUrl(
          meetup.logoUrl.isNotEmpty ? meetup.logoUrl : meetup.coverImagePath);
    }
    if (url.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: size * 1.12, height: size,
      child: Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0024)
          ..rotateY(-0.55),
        child: ShaderMask(
          // Weiches Auslaufen nach rechts, damit sich das Wappen wie ein
          // Wasserzeichen in die Kachel einbindet (linke Kante voll sichtbar).
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.white, Colors.white70, Colors.white24, Colors.transparent],
            stops: [0.0, 0.35, 0.7, 1.0],
          ).createShader(r),
          blendMode: BlendMode.dstIn,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeMeetupTile() {
    final hasHome = _user.homeMeetupId.isNotEmpty || _user.favoriteMeetupIds.isNotEmpty;

    if (!hasHome) {
      // Call-to-Action: noch kein Home Meetup gewählt
      return GestureDetector(
        onLongPress: _showReorderSheet,
        onTap: _selectHomeMeetup,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cOrange.withValues(alpha: 0.35), width: 1.5),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [cOrange.withValues(alpha: 0.10), const Color(0xFF141416)]),
          ),
          child: Row(children: [
            Container(width: 54, height: 54,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: cOrange.withValues(alpha: 0.14)),
              child: const Icon(Icons.add_location_rounded, color: cOrange, size: 28)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context).homeMeetupLabel, style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
              const SizedBox(height: 5),
              Text(AppLocalizations.of(context).homeMeetupChoose, style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(AppLocalizations.of(context).homeMeetupChooseSub, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: cOrange, size: 24),
          ]),
        ),
      );
    }

    // FAVORITEN: swipebare Karten (eine pro Favorit-Stadt), 3-Punkte-Indikator.
    // Hoehe fix, damit der PageView im Grid nicht springt.
    final cards = _favCards.isNotEmpty
        ? _favCards
        : [ _FavCard(city: _user.homeMeetupId, event: _nextHomeMeetup) ];

    return GestureDetector(
      onLongPress: _showReorderSheet,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 152,
          child: PageView.builder(
            controller: _favPageCtrl,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _favPage = i),
            itemBuilder: (_, i) => _favCardContent(cards[i]),
          ),
        ),
        // Seiten-Indikator (Punkte) — nur bei mehr als einer Karte.
        if (cards.length > 1) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (int i = 0; i < cards.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _favPage ? 18 : 6, height: 6,
                decoration: BoxDecoration(
                  color: i == _favPage ? cOrange : cTextTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3)),
              ),
          ]),
        ],
      ]),
    );
  }

  Meetup? _meetupForCity(String city) =>
      _allMeetupsCache.where((x) => x.city == city).firstOrNull ??
      allMeetups.where((x) => x.city == city).firstOrNull;

  /// EINE Favoriten-Karte: CoverFlow-Wappen, Stadt, Countdown, Events/Info.
  /// Bekommt ihre Daten als [card] — kein Zugriff mehr auf _homeMeetup/
  /// _nextHomeMeetup, damit jede Seite ihr eigenes Meetup zeigt.
  Widget _favCardContent(_FavCard card) {
    final cityName = card.city;
    final event = card.event;
    // Meetup-Objekt (fuer Land, Info-Screen, Wappen) zur Stadt aufloesen.
    final meetup = _meetupForCity(cityName);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kTileRadius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [cOrange.withValues(alpha: 0.13), cOrange.withValues(alpha: 0.04), const Color(0xFF141416)],
          stops: const [0.0, 0.45, 1.0]),
        border: Border.all(color: cOrange.withValues(alpha: 0.30), width: 1.0),
        boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          _crestCoverFlow(cityName, meetup, size: 68),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(6)),
                child: Text(AppLocalizations.of(context).homeMeetupLabel, style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
              const SizedBox(width: 8),
              Text(meetup?.country ?? 'DE',
                style: const TextStyle(color: cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(cityName.toUpperCase(),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: cText, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.05)),
          ])),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(initialSearch: cityName))),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(gradient: gradientOrange, borderRadius: BorderRadius.circular(9),
                    boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Center(child: Text(AppLocalizations.of(context).btnEvents, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6)))),
              ),
              if (meetup != null) ...[
                const SizedBox(height: 7),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: meetup))),
                  child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.info_outline_rounded, color: cTextSecondary, size: 16)),
                ),
              ],
            ]),
          ),
        ]),

        const SizedBox(height: 12),

        // Naechster Termin dieser Stadt
        if (_countdownLoading)
          const SizedBox(height: 16, child: LinearProgressIndicator(color: cOrange, backgroundColor: Colors.transparent))
        else if (event != null) Builder(builder: (_) {
          final days = _daysUntil(event.startTime);
          return Row(children: [
            const Icon(Icons.event_available_rounded, color: cTextTertiary, size: 15),
            const SizedBox(width: 7),
            Text(
              days <= 0 ? AppLocalizations.of(context).homeMeetupToday : days == 1 ? AppLocalizations.of(context).homeMeetupTomorrow : AppLocalizations.of(context).homeMeetupInDays(days),
              style: TextStyle(
                color: days <= 0 ? cOrange : days <= 3 ? cOrange.withValues(alpha: 0.8) : cTextSecondary,
                fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 5),
            Expanded(child: Text(
              '· ${event.startTime.day}.${event.startTime.month}.${event.startTime.year}',
              style: const TextStyle(color: cTextTertiary, fontSize: 13))),
          ]);
        })
        else
          Row(children: [
            const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 15),
            const SizedBox(width: 7),
            Text(AppLocalizations.of(context).homeMeetupNoDate, style: const TextStyle(color: cTextTertiary, fontSize: 13)),
          ]),
      ]),
    );

  }

  Widget _miniAct(IconData i, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(6), border: Border.all(color: cTileBorder, width: 0.5)), child: Icon(i, color: cTextTertiary, size: 15)));
  Widget _buildReputationTile() => _tile(accentColor: Colors.amber, watermark: Icons.workspace_premium_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileReputation, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(myBadges.isNotEmpty ? AppLocalizations.of(context).tileReputationShare : AppLocalizations.of(context).tileReputationCheck, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildTrustNetworkTile() => _tile(accentColor: cOrange, watermark: Icons.account_tree_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyNetworkScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.account_tree_rounded, color: cOrange, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileTrustNetwork, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileTrustNetworkSub, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildCommunityTile() => _tile(accentColor: cCyan, watermark: Icons.hub_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityHubScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.hub_rounded, color: cCyan, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileCommunity, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileCommunityPortal, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildEventsTile() => _tile(accentColor: cTextTertiary, watermark: Icons.event_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.event_rounded, color: cTextSecondary, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileEvents, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileEventsCalendar, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  bool _portalConnected = false;

  /// PORTAL-VERBINDUNG als Schieberegler auf dem Dashboard: rot/aus = nicht
  /// verbunden, grün/an = verbunden. Antippen verbindet (Nostr-Login) bzw.
  /// trennt. Macht das Portal-Login sichtbar statt versteckt.
  Widget _buildPortalConnectTile() {
    final t = AppLocalizations.of(context);
    final on = _portalConnected;
    return _tile(
      accentColor: on ? cGreen : cRed,
      watermark: Icons.hub_rounded,
      onTap: _togglePortalConnection,
      child: Row(children: [
        Icon(on ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
            color: on ? cGreen : cRed, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(on ? t.portalConnected : t.portalConnect,
              style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(t.portalTileSub, style: const TextStyle(color: cTextTertiary, fontSize: 11.5)),
        ])),
        // Optischer Schalter
        Container(
          width: 46, height: 26,
          decoration: BoxDecoration(
            color: on ? cGreen : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
        ),
      ]),
    );
  }

  Future<void> _refreshPortalConnected() async {
    final c = await PortalApiService.tokenMatchesCurrentKey();
    if (mounted && c != _portalConnected) setState(() => _portalConnected = c);
  }

  Future<void> _togglePortalConnection() async {
    final t = AppLocalizations.of(context);
    if (_portalConnected) {
      await PortalApiService.logout();
      if (mounted) setState(() => _portalConnected = false);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.portalConnecting), backgroundColor: cCard,
        duration: const Duration(seconds: 8), behavior: SnackBarBehavior.floating));
    final res = await PortalApiService.loginWithNostr();
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (res.ok) {
      setState(() => _portalConnected = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.portalConnected), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating));
      _checkPortalOrganizer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${t.portalLoginFailed}: ${res.error ?? ''}'), backgroundColor: cRed, behavior: SnackBarBehavior.floating));
    }
  }

  Widget _buildBtcDashboardTile() => _tile(
    accentColor: cOrange,
    opacity: 0.07,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BitcoinDashboardScreen())),
    child: const _BtcDashboardTileContent(),
  );

  Widget _buildConverterTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.swap_vert_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConverterScreen())), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.swap_vert_rounded, color: cOrange, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileConverter, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileConverterSub, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildNewsTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.article_rounded, onTap: _openNews, child: Row(children: [const Icon(Icons.article_rounded, color: cOrange, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context).tileNews, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileNewsSub, style: const TextStyle(color: cTextTertiary, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16)]));
  Widget _buildPortalTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.groups_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalMeetupsScreen())), child: Row(children: [const Icon(Icons.groups_rounded, color: cOrange, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context).tilePortal, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tilePortalSub, style: const TextStyle(color: cTextTertiary, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16)]));
  Widget _buildShoutoutTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.campaign_rounded, onTap: () => _openUrl('https://shoutout.einundzwanzig.space'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.campaign_rounded, color: cOrange, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tileShoutout, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tileShoutoutSend, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  Widget _buildPodcastTile() => _tile(accentColor: cPurple, opacity: 0.07, watermark: Icons.podcasts_rounded, onTap: () => _openUrl('https://einundzwanzig.space/podcast/'), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.podcasts_rounded, color: cPurple, size: 22), const SizedBox(height: 12), Text(AppLocalizations.of(context).tilePodcast, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(AppLocalizations.of(context).tilePodcastListen, style: const TextStyle(color: cTextTertiary, fontSize: 12))]));
  /// PLEBRAP: Die Kachel IST der Player — Play/Pause/Weiter direkt auf dem
  /// Dashboard, Bibliotheks-Knopf oeffnet die volle Titelliste. Player-
  /// Zustand kommt aus dem app-weiten PlebrapAudio-Service, laeuft also
  /// synchron mit dem Player-Screen und ueberlebt dessen Schliessen.
  Widget _buildPlebrapTile() => _tile(
    accentColor: cOrange,
    watermark: Icons.graphic_eq_rounded,
    child: ValueListenableBuilder<int?>(
      valueListenable: PlebrapAudio.index,
      builder: (_, idx, __) {
        final song = idx != null ? kPlebSongs[idx] : null;
        return Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.graphic_eq_rounded, color: cOrange, size: 20),
              const SizedBox(width: 8),
              const Text('PlebRap', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(song?.title ?? AppLocalizations.of(context).chPlebrapSub,
                style: TextStyle(color: song != null ? cOrange : cTextTertiary, fontSize: 12,
                    fontWeight: song != null ? FontWeight.w600 : FontWeight.w400),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            if (song != null)
              Text(song.artist, style: const TextStyle(color: cTextTertiary, fontSize: 10.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Play/Pause — Spinner waehrend des Ladens
          ValueListenableBuilder<bool>(
            valueListenable: PlebrapAudio.loading,
            builder: (_, busy, __) => StreamBuilder<PlayerState>(
              stream: PlebrapAudio.player.playerStateStream,
              builder: (_, snap) {
                final playing = snap.data?.playing ?? false;
                return GestureDetector(
                  onTap: PlebrapAudio.toggle,
                  child: Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: cOrange, shape: BoxShape.circle),
                    child: busy
                        ? const Padding(padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 24),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: cText, size: 26),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            onPressed: PlebrapAudio.next,
          ),
          const SizedBox(width: 6),
          // Bibliothek: voller Player mit Titelliste
          IconButton(
            icon: const Icon(Icons.queue_music_rounded, color: cTextSecondary, size: 24),
            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlebrapPlayerScreen())),
          ),
        ]);
      },
    ),
  );

  /// SATOSHIDUELL: Quiz-Duelle um Sats (satoshiduell.de). Öffnet die WebApp
  /// mit npub-Parameter -> Auto-Login. Badge = offene Duelle (Logik und
  /// Erklärung in SatoshiDuellService).
  Widget _buildSatoshiDuellTile() {
    const gold = Color(0xFFFFC93C);
    return _tile(
      accentColor: gold,
      watermarkAsset: 'assets/images/satoshiduell.png',
      onTap: () async {
        final npub = await SigningService.npub();
        _openUrl((npub != null && npub.isNotEmpty)
            ? 'https://satoshiduell.de/?npub=$npub'
            : 'https://satoshiduell.de/');
      },
      child: FutureBuilder<DuellStatus>(
        // EIN FutureBuilder für Badge UND Untertitel: der Untertitel sagt
        // WAS ansteht ("Du bist dran!" > Lobby > "Warten auf Gegner"),
        // das Badge zeigt die Zahl der Duelle, die eine Aktion erlauben.
        future: SatoshiDuellService.fetchStatus(),
        builder: (_, snap) {
          final st = snap.data ?? DuellStatus.empty;
          final t = AppLocalizations.of(context);
          // ALLES anzeigen, farblich wie in SatoshiDuell selbst:
          // dran = Gold, Lobby = Orange, warten (eigenes Spiel) = Grün.
          final spans = <TextSpan>[
            if (st.myTurn > 0)
              TextSpan(text: '⚡ ${st.myTurn} ${t.sdShortTurn}',
                  style: const TextStyle(color: gold, fontWeight: FontWeight.w700)),
            if (st.lobby > 0)
              TextSpan(text: '${st.lobby} ${t.sdShortLobby}',
                  style: const TextStyle(color: cOrange, fontWeight: FontWeight.w600)),
            if (st.waiting > 0)
              TextSpan(text: '${st.waiting} ${t.sdShortWait}',
                  style: const TextStyle(color: cGreen)),
          ];
          final joined = <TextSpan>[];
          for (var i = 0; i < spans.length; i++) {
            if (i > 0) joined.add(const TextSpan(text: '  ·  ', style: TextStyle(color: cTextTertiary)));
            joined.add(spans[i]);
          }
          final n = st.myTurn + st.lobby;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.bolt_rounded, color: gold, size: 22),
              const Spacer(),
              if (n > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: gold.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: Text('$n', style: const TextStyle(color: gold, fontSize: 11.5, fontWeight: FontWeight.w800)),
                ),
            ]),
            const SizedBox(height: 12),
            const Text('SatoshiDuell', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            joined.isEmpty
                ? Text(t.chDuellSub, style: const TextStyle(color: cTextTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)
                : Text.rich(TextSpan(children: joined), style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]);
        },
      ),
    );
  }

  /// PORTAL-BEREICH: direkter Einstieg in Meetups/Events/Kurse/Karte
  /// (gleiche Ebene wie im Community-Hub).
  Widget _buildPortalAreaTile() => _tile(
    accentColor: cOrange,
    watermark: Icons.public_rounded,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalAreaScreen())),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.public_rounded, color: cOrange, size: 22),
      const SizedBox(height: 12),
      const Text('Portal', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 3),
      Text(AppLocalizations.of(context).chPortalSub, style: const TextStyle(color: cTextTertiary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );

  Widget _buildNostrTile() => _tile(
    accentColor: cNostr,
    opacity: 0.07,
    onTap: _openNostr,
    child: Stack(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Opacity(
          opacity: _nostrHasNew ? 1.0 : 0.55,
          child: Image.asset(
            'assets/images/nostr_icon.png',
            width: 30,
            height: 30,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).tileNostr, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(AppLocalizations.of(context).tileNostrCommunity, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
      ]),
      if (_nostrHasNew) Positioned(
        top: 0, right: 0,
        child: Container(
          width: 7, height: 7,
          decoration: const BoxDecoration(color: cOrange, shape: BoxShape.circle),
        ),
      ),
    ]),
  );
  Widget _buildOrganisatorTile() => _tile(accentColor: cOrange, watermark: Icons.admin_panel_settings_rounded, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); }, child: Row(children: [Icon(Icons.admin_panel_settings_rounded, color: _justPromoted ? cGreen : cOrange, size: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context).tileOrganizer, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text(_justPromoted ? AppLocalizations.of(context).tileOrganizerNew : AppLocalizations.of(context).tileOrganizerPanel, style: const TextStyle(color: cTextTertiary, fontSize: 12))])), const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16)]));

  Widget _buildWotDashboardTile() => _tile(
    accentColor: cOrange,
    watermark: Icons.account_tree_rounded,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WotDashboardScreen())),
    child: Row(children: [
      const Icon(Icons.account_tree_rounded, color: cTextSecondary, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context).tileWot, style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(AppLocalizations.of(context).tileWotSubtitle, style: const TextStyle(color: cTextTertiary, fontSize: 12)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
    ]),
  );

  Widget _buildActiveSessionTile() => AnimatedBuilder(animation: _pulseController, builder: (_, __) => GestureDetector(
    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cGreen.withValues(alpha: 0.25), width: 0.5)),
    child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withValues(alpha: 0.5 + _pulseController.value * 0.5), boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3 * _pulseController.value), blurRadius: 8)])),
      const SizedBox(width: 14), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(AppLocalizations.of(context).statusLive, style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10), Expanded(child: Text(_activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : AppLocalizations.of(context).statusMeetupActive, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8), Text(_sessionTimeLeft, style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: fontMono)), const SizedBox(width: 8), Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withValues(alpha: 0.4), size: 14)]))));

  Widget _buildDeviceWarning() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5)),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Greifer
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: gradientOrange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.settings_rounded, color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppLocalizations.of(context).settingsHeaderTitle,
                        style: const TextStyle(color: cText, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(AppLocalizations.of(context).settingsHeaderSub,
                        style: const TextStyle(color: cTextTertiary, fontSize: 12)),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              // Scrollbarer Inhalt
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    // ACCOUNT
                    _sGroup(AppLocalizations.of(context).settingsSecAccount, [
                      _sRow(Icons.person_rounded, cOrange,
                        AppLocalizations.of(context).settingsProfile,
                        AppLocalizations.of(context).settingsProfileSub,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); }),
                    ]),
                    const SizedBox(height: 18),
                    // DATEN & SICHERHEIT
                    _sGroup(AppLocalizations.of(context).settingsSecData, [
                      _sRow(Icons.cloud_upload_rounded, cCyan,
                        AppLocalizations.of(context).settingsBackup,
                        AppLocalizations.of(context).settingsBackupSub,
                        () async { Navigator.pop(ctx); await BackupService.createBackup(context); }),
                    ]),
                    const SizedBox(height: 18),
                    // NETZWERK
                    _sGroup(AppLocalizations.of(context).settingsSecNetwork, [
                      _sRow(Icons.hub_rounded, cPurple,
                        AppLocalizations.of(context).settingsRelays,
                        AppLocalizations.of(context).settingsRelaysSub,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
                      _sDivider(),
                      // Mempool-Datenquelle (Clearnet / Tor-Onion / eigene Instanz)
                      _sRow(Icons.dns_rounded, cOrange,
                        AppLocalizations.of(context).settingsMempool,
                        AppLocalizations.of(context).settingsMempoolSub,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const MempoolSettingsScreen())); }),
                    ]),
                    const SizedBox(height: 18),
                    // APP
                    _sGroup(AppLocalizations.of(context).settingsSecApp, [
                      // Sprache
                      ValueListenableBuilder<Locale?>(
                        valueListenable: LocaleController.locale,
                        builder: (_, current, __) => _sRowCustom(
                          Icons.language_rounded, cGreen,
                          AppLocalizations.of(context).settingsLanguageTitle,
                          '${_flagFor(current)}  ${LocaleController.displayName(current)}',
                          trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
                          onTap: () => _showLanguagePopup(ctx),
                        ),
                      ),
                      _sDivider(),
                      // Haptik
                      _sRowCustom(
                        Icons.vibration_rounded, cGreen,
                        AppLocalizations.of(context).settingsHaptic,
                        haptic ? AppLocalizations.of(context).settingsHapticOn : AppLocalizations.of(context).settingsHapticOff,
                        trailing: Switch(value: haptic, activeColor: cOrange,
                          onChanged: (v) async { await prefs.setBool('haptic_enabled', v); ss(() => haptic = v); }),
                      ),
                      _sDivider(),
                      // Diagnose-Log
                      _sRow(Icons.bug_report_rounded, cCyan,
                        AppLocalizations.of(context).settingsLogTitle,
                        AppLocalizations.of(context).settingsLogSub,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const LogScreen())); }),
                    ]),
                    const SizedBox(height: 18),
                    // UNTERSTÜTZEN (V4V)
                    _sGroup(AppLocalizations.of(context).v4vSectionTitle, [
                      _sRow(Icons.bolt_rounded, cOrange,
                        'V4V',
                        AppLocalizations.of(context).v4vSectionSubtitle,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const V4VScreen())); }),
                    ]),
                    const SizedBox(height: 18),
                    // GEFAHRENZONE
                    _sGroup(AppLocalizations.of(context).settingsSecDanger, [
                      _sRow(Icons.delete_forever_rounded, cRed,
                        AppLocalizations.of(context).settingsReset,
                        AppLocalizations.of(context).settingsResetSub,
                        () { Navigator.pop(ctx); _resetApp(); }, danger: true),
                    ]),
                    const SizedBox(height: 20),
                    // Versionsanzeige (dezent, unten)
                    Center(
                      child: Text(
                        _appVersion.isEmpty ? '' : '21Meetup · Version $_appVersion',
                        style: const TextStyle(color: cTextTertiary, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Eine Gruppe: Label + Karten-Container mit den Items.
  Widget _sGroup(String label, List<Widget> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 8),
        child: Text(label,
          style: const TextStyle(color: cTextTertiary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
      ),
      Container(
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: items),
      ),
    ]);
  }

  /// Eine Standard-Zeile (Icon, Titel, Sub, Pfeil rechts).
  Widget _sRow(IconData i, Color c, String t, String s, VoidCallback onTap, {bool danger = false}) {
    return _sRowCustom(i, c, t, s,
      trailing: Icon(Icons.chevron_right_rounded, color: danger ? cRed.withValues(alpha: 0.5) : cTextTertiary, size: 18),
      onTap: onTap, danger: danger);
  }

  /// Flexible Zeile mit beliebigem trailing-Widget (Switch, Pfeil, ...).
  Widget _sRowCustom(IconData i, Color c, String t, String s, {Widget? trailing, VoidCallback? onTap, bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(i, color: c, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: TextStyle(color: danger ? cRed : cText, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(s, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
            ]),
          ),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  /// Trennlinie zwischen Items in einer Gruppe.
  Widget _sDivider() => Container(height: 0.5, color: cTileBorder, margin: const EdgeInsets.only(left: 56));


  // Flaggen-Emoji je Sprache (System = Globus)
  String _flagFor(Locale? loc) {
    switch (loc?.languageCode) {
      case 'de': return '🇩🇪';
      case 'en': return '🇬🇧';
      case 'es': return '🇪🇸';
      default: return '🌐';
    }
  }

  // Popup-Dialog mit Sprachauswahl (Flagge + Name)
  void _showLanguagePopup(BuildContext sheetCtx) {
    showDialog(
      context: context,
      builder: (dialogCtx) => ValueListenableBuilder<Locale?>(
        valueListenable: LocaleController.locale,
        builder: (_, current, __) => Dialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                const Icon(Icons.language_rounded, color: cOrange, size: 20),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).settingsLanguageChoose, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
            const Divider(color: cBorder, height: 1),
            _langOption('🌐', 'System', null, current, dialogCtx),
            _langOption('🇩🇪', 'Deutsch', const Locale('de'), current, dialogCtx),
            _langOption('🇬🇧', 'English', const Locale('en'), current, dialogCtx),
            _langOption('🇪🇸', 'Español', const Locale('es'), current, dialogCtx),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _langOption(String flag, String label, Locale? value, Locale? current, BuildContext dialogCtx) {
    final selected = current?.languageCode == value?.languageCode;
    return InkWell(
      onTap: () async {
        await LocaleController.setLocale(value);
        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? cOrange.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(
            color: selected ? cOrange : cText,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
          if (selected) const Icon(Icons.check_circle_rounded, color: cOrange, size: 20),
        ]),
      ),
    );
  }


  void _showScoreInfoSheet() {
    final score = _trustScore; final idCount = _platformProofCount + (_humanityVerified ? 1 : 0) + (_nip05Verified ? 1 : 0);
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.4, expand: false,
        builder: (_, sc) => SingleChildScrollView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 40), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2)))), const SizedBox(height: 20),
          Text(AppLocalizations.of(context).siTitle, style: const TextStyle(color: cOrange, fontSize: 17, fontWeight: FontWeight.w800)), const SizedBox(height: 6),
          Text(AppLocalizations.of(context).siIntro, style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)),
          // IDENTITY LAYER
          const SizedBox(height: 24), Text(AppLocalizations.of(context).siIdentityLayer, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 8),
          Text(AppLocalizations.of(context).siLinksActive(idCount), style: const TextStyle(color: cTextTertiary, fontSize: 11)), const SizedBox(height: 12),
          _idR(Icons.bolt_rounded, "Proof of Humanity", AppLocalizations.of(context).siHumanitySub, _humanityVerified, Colors.amber),
          _idR(Icons.alternate_email, "NIP-05", AppLocalizations.of(context).siNip05Sub, _nip05Verified, cCyan),
          ..._platformNames.map((n) => _idR(Icons.link_rounded, {'telegram': 'Telegram', 'twitter': 'X / Twitter', 'kleinanzeigen': 'Kleinanzeigen'}[n.toLowerCase()] ?? n, AppLocalizations.of(context).siPlatformActive, true, Colors.green)),
          if (_platformProofCount == 0) _idR(Icons.link_off_rounded, AppLocalizations.of(context).siPlatforms, AppLocalizations.of(context).siNoneLinked, false, cTextTertiary),
          // TRUST LEVEL
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          Text(AppLocalizations.of(context).siTrustLevel, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _lvl(Icons.fiber_new, localizedLevel(context, 'NEU'), "< 3", Colors.grey, AppLocalizations.of(context).siLvlNew, score?.level == 'NEU'),
          _lvl(Icons.eco, localizedLevel(context, 'STARTER'), "3–9", cOrange, AppLocalizations.of(context).siLvlStarter, score?.level == 'STARTER'),
          _lvl(Icons.local_fire_department, localizedLevel(context, 'AKTIV'), "10–19", cCyan, AppLocalizations.of(context).siLvlActive, score?.level == 'AKTIV'),
          _lvl(Icons.shield, localizedLevel(context, 'ETABLIERT'), "20–39", Colors.green, AppLocalizations.of(context).siLvlEstablished, score?.level == 'ETABLIERT'),
          _lvl(Icons.bolt, localizedLevel(context, 'VETERAN'), "40+", Colors.amber, AppLocalizations.of(context).siLvlVeteran, score?.level == 'VETERAN'),
          // BERECHNUNG
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          Text(AppLocalizations.of(context).siCalculation, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _fac(Icons.military_tech, cOrange, AppLocalizations.of(context).siFacBadges, AppLocalizations.of(context).siFacBadgesDesc),
          _fac(Icons.location_on, cCyan, AppLocalizations.of(context).siFacDiversity, AppLocalizations.of(context).siFacDiversityDesc),
          _fac(Icons.people_outline, cPurple, AppLocalizations.of(context).siFacSigners, AppLocalizations.of(context).siFacSignersDesc),
          _fac(Icons.schedule, Colors.green, AppLocalizations.of(context).siFacMaturity, AppLocalizations.of(context).siFacMaturityDesc),
          _fac(Icons.speed, cRed, AppLocalizations.of(context).siFacFrequency, AppLocalizations.of(context).siFacFrequencyDesc),
          // ORGANISATOR
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          Text(AppLocalizations.of(context).siBecomeOrganizer, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 8),
          Text(AppLocalizations.of(context).siBecomeOrgDesc, style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.5)), const SizedBox(height: 14),
          if (score != null && !score.meetsPromotionThreshold)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(AppLocalizations.of(context).siProgressLabel(score.activeThresholds.name), style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...score.progress.entries.map((e) => _pRow(e.value))]))
          else if (score != null)
            Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
              child: Row(children: [const Icon(Icons.verified, color: Colors.green, size: 20), const SizedBox(width: 10), Expanded(child: Text(AppLocalizations.of(context).siAlreadyOrganizer, style: TextStyle(color: Colors.green.shade300, fontSize: 12)))])),
          // TIPPS
          const SizedBox(height: 20), const Divider(color: cBorder), const SizedBox(height: 16),
          Text(AppLocalizations.of(context).siIncreaseScore, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)), const SizedBox(height: 12),
          _tip(Icons.event, AppLocalizations.of(context).siTip1), _tip(Icons.explore, AppLocalizations.of(context).siTip2),
          _tip(Icons.group_add, AppLocalizations.of(context).siTip3), _tip(Icons.bolt, AppLocalizations.of(context).siTip4),
          _tip(Icons.alternate_email, AppLocalizations.of(context).siTip5), _tip(Icons.link, AppLocalizations.of(context).siTip6),
          const SizedBox(height: 20),
        ]))));
  }

  Widget _idR(IconData i, String l, String d, bool a, Color c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Icon(i, color: a ? c : cTextTertiary.withValues(alpha: 0.5), size: 18), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(color: a ? cText : cTextTertiary, fontSize: 12, fontWeight: FontWeight.w600)), Text(d, style: TextStyle(color: a ? cTextSecondary : cTextTertiary.withValues(alpha: 0.5), fontSize: 10))])), Icon(a ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: a ? c : cTextTertiary.withValues(alpha: 0.3), size: 18)]));
  Widget _lvl(IconData i, String n, String r, Color c, String d, bool a) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: a ? c.withValues(alpha: 0.06) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: a ? Border.all(color: c.withValues(alpha: 0.2)) : null), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: c.withValues(alpha: a ? 0.15 : 0.06), shape: BoxShape.circle), child: Icon(i, color: a ? c : c.withValues(alpha: 0.3), size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Text(n, style: TextStyle(color: a ? c : cTextSecondary, fontSize: 12, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Text(r, style: const TextStyle(color: cTextTertiary, fontSize: 10)), if (a) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text('DU', style: TextStyle(color: c, fontSize: 8, fontWeight: FontWeight.w800)))]]), const SizedBox(height: 3), Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 10, height: 1.3))]))]));
  Widget _fac(IconData i, Color c, String t, String d) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: c, size: 18), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: cText, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(d, style: const TextStyle(color: cTextTertiary, fontSize: 11, height: 1.4))]))]));
  Widget _tip(IconData i, String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(i, color: cOrange.withValues(alpha: 0.6), size: 16), const SizedBox(width: 10), Expanded(child: Text(t, style: const TextStyle(color: cTextSecondary, fontSize: 11, height: 1.4)))]));
  Widget _pRow(PromotionProgress p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [Icon(p.met ? Icons.check_circle : Icons.radio_button_unchecked, color: p.met ? Colors.green : cTextTertiary, size: 16), const SizedBox(width: 8), Expanded(child: Text(AppLocalizations.of(context).siProgressRow(p.label, p.current, p.required), style: TextStyle(color: p.met ? Colors.green.shade300 : cTextSecondary, fontSize: 11, fontWeight: p.met ? FontWeight.w600 : FontWeight.normal))), SizedBox(width: 40, height: 4, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: p.percentage, backgroundColor: cSurface, valueColor: AlwaysStoppedAnimation(p.met ? Colors.green : cOrange))))]));
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

  static const _requiredTiles = {'home_meetup', 'reputation'};

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
                _sectionHeader(Icons.add_circle_outline_rounded, 'VERFÜGBAR', 'Schalter aktivieren zum Hinzufügen'),
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
          : Switch(
              value: true,
              activeColor: cOrange,
              onChanged: (_) => _hide(id),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
      ]),
    );
  }

  Widget _availableRow(String id) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: cSurface, borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorder, width: 0.5)),
    child: Row(children: [
      Icon(_iconFor(id), color: cTextTertiary, size: 15),
      const SizedBox(width: 10),
      Expanded(child: Text(_labelFor(id), style: const TextStyle(color: cTextTertiary, fontSize: 13, fontWeight: FontWeight.w500))),
      Switch(
        value: false,
        activeColor: cOrange,
        onChanged: (_) => _show(id),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ]),
  );
}

/// Kompakter Inhalt der Bitcoin-Dashboard-Kachel im Home-Grid:
/// Blockhöhe + EUR-Preis. Lädt selbst und aktualisiert alle 60s.

/// Kompakter Inhalt der Bitcoin-Dashboard-Kachel im Home-Grid.
/// Layout: offizielles Bitcoin-Logo im Hintergrund (rechts, transparent),
/// links die Kachel-Beschreibung, rechts die aktuelle Blockhöhe.
class _BtcDashboardTileContent extends StatefulWidget {
  const _BtcDashboardTileContent();

  @override
  State<_BtcDashboardTileContent> createState() => _BtcDashboardTileContentState();
}

class _BtcDashboardTileContentState extends State<_BtcDashboardTileContent> {
  BitcoinDashboardData? _d;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _d = MempoolService.lastDashboard;
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await MempoolService.getDashboardData();
    if (mounted) setState(() => _d = d);
    WidgetService.updateBitcoin(d); // Homescreen-Widget mitversorgen
  }

  String _fmtInt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return Stack(
      children: [
        // Offizielles Bitcoin-Logo im Hintergrund (rechts, dezent)
        Positioned(
          right: -18,
          top: 0,
          bottom: 0,
          child: Center(
            child: Opacity(
              opacity: 0.10,
              child: SvgPicture.asset('assets/icons/bitcoin.svg', width: 104, height: 104),
            ),
          ),
        ),
        // Inhalt: links Beschreibung, rechts Blockhöhe
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Links: Titel + Untertitel + Preis
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    SvgPicture.asset('assets/icons/bitcoin.svg', width: 22, height: 22),
                    const SizedBox(width: 8),
                    const Text('Bitcoin', style: TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Netzwerk & Kurs', style: TextStyle(color: cTextTertiary, fontSize: 12)),
                  if (d != null && d.priceEur > 0) ...[
                    const SizedBox(height: 8),
                    Text('${_fmtInt(d.priceEur.round())} €',
                        style: const TextStyle(color: cTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
            // Rechts: Blockhöhe
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d != null ? cGreen.withValues(alpha: 0.7) : cTextTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('BLOCK', style: TextStyle(color: cTextTertiary, fontSize: 10, letterSpacing: 2)),
                ]),
                const SizedBox(height: 4),
                Text(
                  d != null && d.blockHeight > 0 ? _fmtInt(d.blockHeight) : '––',
                  style: const TextStyle(color: cOrange, fontSize: 26, fontWeight: FontWeight.w800, height: 1.0)
                      .copyWith(fontFamily: fontMono),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Eine Favoriten-Karte: Stadt + deren naechstes Event (oder null).
class _FavCard {
  final String city;
  final CalendarEvent? event;
  const _FavCard({required this.city, required this.event});
}
