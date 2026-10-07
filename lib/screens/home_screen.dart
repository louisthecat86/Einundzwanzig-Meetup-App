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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nostr/nostr.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../services/haptic_service.dart';
import '../widgets/pressable.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../models/calendar_event.dart';
import '../services/calendar_event_service.dart';
import '../services/news_service.dart';
import '../services/meetup_service.dart';
import '../services/meetup_calendar_service.dart';
import '../services/trust_score_service.dart';
import '../services/admin_registry.dart';
import '../services/badge_claim_service.dart';
import '../services/reputation_publisher.dart';
import '../services/rolling_qr_service.dart';
import '../services/nostr_profile_service.dart';
import 'meetup_selection.dart';
import 'profile_edit.dart';
import 'identity_setup_screen.dart';
import 'intro.dart';
import 'admin_panel.dart';
import 'converter_screen.dart';
import 'news_screen.dart';
import 'event_calendar_screen.dart';
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
import 'voice_wallet_screen.dart';
import 'log_screen.dart';
import '../services/mempool.dart';
import '../services/widget_service.dart';
import '../services/signing_service.dart';
import '../services/satoshiduell_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'calendar_screen.dart';
import '../services/backup_service.dart';
import '../services/promotion_claim_service.dart';
import '../services/secure_key_store.dart';
import '../services/local_key_vault.dart';
import '../services/humanity_proof_service.dart';
import '../services/app_logger.dart';
import '../services/device_integrity_service.dart';
import '../services/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/chat_service.dart';
import '../services/meetup_event_matcher.dart';
import '../services/event_chat_service.dart';
import '../services/event_rsvp_service.dart';
import 'chat_screen.dart';
import 'my_events_screen.dart';
import 'package:provider/provider.dart';

import '../services/guide_service.dart';
import '../tours/home_tour.dart';
import 'glossary_screen.dart';
import '../tours/settings_tour.dart';
import '../l10n/level_labels.dart';
import '../services/currency_service.dart';

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

  // ZAEHLER auf den Kacheln — werden nach dem ersten Aufbau nachgeladen,
  // damit sie das Dashboard nicht ausbremsen.
  int _unreadNews = 0;
  int _eventsToday = 0;
  /// Titel des neuesten Artikels — macht aus der News-Kachel einen echten
  /// Anreiz statt einer blossen Beschriftung.
  String _latestNewsTitle = '';

  /// Graue "Verfuegbar"-Sektion eingeklappt? Standard: ja, damit der
  /// Alltagsblick knapp bleibt.
  bool _availableCollapsed = true;

  /// BEARBEITEN-MODUS: id der gerade markierten Kachel, sonst null.
  /// Langes Druecken markiert eine Kachel — sie bekommt einen Rahmen, eine
  /// Pinnadel und laesst sich auf eine andere Kachel ziehen. Alle uebrigen
  /// Kacheln werden dabei zu Ablagezielen. Bewusst nur EINE Kachel
  /// gleichzeitig: So bleibt der Normalzustand frei von Symbolen.
  String? _editTileId;

  /// Wird unmittelbar vor jedem tile.builder()-Aufruf gesetzt und von
  /// _tile() gelesen: angeheftete Kacheln bekommen den goldenen Anstrich
  /// der Home-Meetup-Kachel, verfuegbare bleiben zurueckhaltend.
  ///
  /// Ein schlichtes Feld statt eines Parameters, weil _tile() an rund
  /// fuenfzehn Stellen aufgerufen wird — der Bau laeuft synchron, das
  /// Feld ist beim Lesen also garantiert der richtige Wert.
  bool _buildingPinnedTile = true;
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
  // Standard-Reihenfolge (alle optionalen Kacheln sind zunaechst sichtbar)
  // WICHTIG: Jede neue Kachel muss hier stehen. _buildTileRows geht ueber
  // diese Reihenfolge — was nicht drin ist, wird nie gezeichnet, egal was
  // in _tileDefs steht. "event_chats" fehlte hier, deshalb blieb die Kachel
  // "Meine Termine" unsichtbar, obwohl Zusagen vorlagen.
  static const _defaultOrder = ['home_meetup', 'event_chats', 'reputation', 'trust_network', 'community', 'nostr', 'converter', 'btc_dashboard', 'voice_wallet', 'news', 'portal', 'events', 'shoutout', 'podcast', 'satoshiduell', 'portal_area', 'plebrap', 'organisator'];
  static const _defaultHidden = {'news', 'shoutout', 'podcast', 'nostr', 'portal', 'events', 'satoshiduell', 'portal_area', 'plebrap'};

  late List<_TileDef> _tileDefs;
  String _appVersion = ''; // wird in initState aus package_info geladen

  @override
  void initState() {
    super.initState();
    // Waehrung umgestellt → Kacheln neu zeichnen (Issue #66).
    CurrencyService.current.addListener(_onCurrencyChanged);
    _loadTileCounters();
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
      // Laufende Session ebenfalls neu pruefen. Ohne diese Zeile erschien
      // die Kachel erst beim naechsten KALTSTART: Wer die App nur in den
      // Hintergrund schiebt — der Normalfall auf einem Event — kam zurueck
      // und sah nichts, obwohl die Session lief.
      _checkActiveSession();
      _loadChatUnread();
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
          final key = _favCards.isNotEmpty ? _favCards.first.key : _user.homeMeetupId;
          Navigator.push(context, MaterialPageRoute(builder: (_) => CalendarScreen(
              initialSearch: frontCity,
              initialMeetupId: MeetupService.resolveFavorite(key)?.id)));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CalendarScreen()));
        }
        break;
    }
  }

  /// Laedt die Kachel-Zaehler. Bewusst getrennt vom uebrigen Aufbau und
  /// ohne await im initState: Wenn ein Feed haengt, soll das Dashboard
  /// trotzdem sofort stehen — die Zahl trudelt dann eben nach.
  Future<void> _loadTileCounters() async {
    // --- News: seit dem letzten Besuch dazugekommen ---
    try {
      final n = await NewsService.unreadCount();
      final articles = await NewsService.cachedArticles();
      // Nicht auf die Feed-Reihenfolge verlassen — den juengsten Artikel
      // ueber den Zeitstempel bestimmen.
      String title = '';
      if (articles.isNotEmpty) {
        final newest = articles.reduce((a, b) => a.publishedAt >= b.publishedAt ? a : b);
        title = newest.title.trim();
      }
      if (mounted && (n != _unreadNews || title != _latestNewsTitle)) {
        setState(() {
          _unreadNews = n;
          _latestNewsTitle = title;
        });
      }
    } catch (e) {
      AppLogger.warn('Dashboard', 'News-Zaehler fehlgeschlagen', e);
    }

    // --- Events heute ---
    // Gezaehlt werden Portal-Meetups und Nostr-Events. KURSE bleiben aussen
    // vor: Die wuerden pro Kurs einen eigenen Portal-Abruf brauchen, was auf
    // dem Dashboard zu teuer waere. Findet an einem Tag ausschliesslich ein
    // Kurs statt, zeigt die Kachel deshalb 0, der Kalender aber einen Eintrag.
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      bool isToday(DateTime d) {
        final l = d.toLocal();
        return !l.isBefore(dayStart) && l.isBefore(dayEnd);
      }

      final results = await Future.wait([
        MeetupCalendarService().fetchMeetupsPortalFirst(),
        CalendarEventService.fetchEvents(),
      ]);
      var count = 0;
      for (final e in (results[0] as List<CalendarEvent>)) {
        if (isToday(e.startTime)) count++;
      }
      for (final e in (results[1] as List<NostrCalendarEvent>)) {
        if (isToday(e.start)) count++;
      }
      if (mounted && count != _eventsToday) setState(() => _eventsToday = count);
      AppLogger.diag('Dashboard', 'Kachel-Zaehler: $_unreadNews News, $count Event(s) heute.');
    } catch (e) {
      AppLogger.warn('Dashboard', 'Event-Zaehler fehlgeschlagen', e);
    }
  }

  void _openNews() {
    WidgetService.markNewsSeen(); // NEU-Markierung entfernen
    // Zaehler zuruecksetzen und Kachel sofort aktualisieren.
    NewsService.markRead();
    setState(() => _unreadNews = 0);
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
      // Feste Kachel direkt darunter: "Was habe ich vor" gehoert neben
      // "Wo gehoere ich hin". Nicht abwaehlbar und IMMER sichtbar — auch
      // ohne Zusagen, denn dann erklaert sie, dass es sie gibt. Eine Kachel,
      // die erst bei Inhalt erscheint, findet niemand.
      _TileDef(id: 'event_chats',  label: 'Meine Termine',    span: 3, removable: false, builder: _buildMyEventsTile),
      _TileDef(id: 'reputation',   label: 'Reputation',       span: 1, builder: _buildReputationTile),
      // ── Optionale Kacheln (removable: true) ──
      _TileDef(id: 'community',    label: 'Community',        span: 2, builder: _buildCommunityTile),
      _TileDef(id: 'trust_network', label: 'Vertrauensnetzwerk', span: 2, builder: _buildTrustNetworkTile),
      _TileDef(id: 'events',       label: 'Events',           span: 1, builder: _buildEventsTile),
      _TileDef(id: 'shoutout',     label: 'Shoutout',         span: 1, builder: _buildShoutoutTile),
      _TileDef(id: 'podcast',      label: 'Podcast',          span: 1, builder: _buildPodcastTile),
      _TileDef(id: 'satoshiduell', label: 'SatoshiDuell',     span: 2, builder: _buildSatoshiDuellTile),
      _TileDef(id: 'portal_area',  label: 'Portal',           span: 2, builder: _buildPortalAreaTile),
      // Volle Breite: Der Mini-Player traegt Titel, Kuenstler und drei
      // Bedienelemente — auf zwei Dritteln ueberlappten sie sich.
      _TileDef(id: 'plebrap',      label: 'PlebRap',          span: 3, builder: _buildPlebrapTile),
      _TileDef(id: 'nostr',        label: 'Nostr',            span: 1, builder: _buildNostrTile),
      _TileDef(id: 'portal_connect', label: 'Portal', span: 2, builder: _buildPortalConnectTile),
      _TileDef(id: 'converter',    label: 'Rechner',          span: 1, builder: _buildConverterTile),
      _TileDef(id: 'btc_dashboard', label: 'Bitcoin',         span: 2, builder: _buildBtcDashboardTile),
      _TileDef(id: 'voice_wallet', label: 'Sats',            span: 2, builder: _buildVoiceWalletTile),
      _TileDef(id: 'news',         label: 'News',             span: 2, builder: _buildNewsTile),
      _TileDef(id: 'portal',       label: 'Meine Meetups',    span: 2, builder: _buildPortalTile),
      _TileDef(id: 'organisator',  label: 'Organisator',      span: 3, builder: _buildOrganisatorTile, visible: () => _user.isAdmin || _user.isReviewDemo),
      // ── Admin-optionale Kacheln ──
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

      // Neue Kacheln an ihren VORGESEHENEN Platz einfuegen, nicht ans Ende.
      //
      // Vorher landete alles Neue hinter der letzten Kachel — bei jemandem
      // mit siebzehn angehefteten Kacheln also ganz unten, wo es niemand
      // sieht. Gesucht wird deshalb der naechste Vorgaenger aus der
      // Standardreihenfolge, der beim Nutzer schon vorhanden ist; dahinter
      // kommt die neue Kachel.
      for (final id in _defaultOrder) {
        if (known.contains(id)) continue;
        final idx = _defaultOrder.indexOf(id);
        var pos = 0;
        for (var i = idx - 1; i >= 0; i--) {
          final at = known.indexOf(_defaultOrder[i]);
          if (at >= 0) {
            pos = at + 1;
            break;
          }
        }
        known.insert(pos, id);
      }
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

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    CurrencyService.current.removeListener(_onCurrencyChanged);
    _favPageCtrl.dispose(); WidgetsBinding.instance.removeObserver(this); _sessionTimer?.cancel(); _midnightTimer?.cancel(); _pulseController.dispose(); super.dispose(); }
  /// Wird von der Huelle gerufen, sobald der Home-Reiter wieder vorne ist.
  ///
  /// Hier gehoeren die Zusagen mit hinein: Wer ueber die untere Leiste in den
  /// Kalender geht, dort zusagt und zurueckwechselt, loest KEINE Rueckkehr
  /// aus einer Route aus — das Dashboard blieb einfach stehen. Genau deshalb
  /// erschien die Kachel erst nach dem Aktualisieren von Hand.
  void refreshAfterScan() {
    _loadBadges();
    _calculateTrustScore();
    _loadNextHomeMeetup();
    _checkPortalOrganizer();
    _refreshPortalConnected();
    _loadMyEvents();
  }

  bool _refreshing = false;

  /// MANUELLE VOLLAKTUALISIERUNG (Pfeil oben rechts): holt alle Daten neu und
  /// löst die daran hängenden Statusprüfungen aus:
  /// - Badges + Trust Score neu laden
  /// - WoT/Bürgen-Admin-Status neu verifizieren (_reVerifyAdminStatus)
  /// - Portal-Organisator-Status prüfen (Kachel erscheint/verschwindet)
  /// - nächstes Home-Meetup + Portal-Verbindung aktualisieren
  /// So bekommt z.B. ein frisch im Portal ernannter Organisator oder ein
  /// per Nostr Verbürgter seine Rechte/Kachel, ohne die App neu zu starten.
  /// [fromGesture] unterdrueckt die Lauf-Meldung.
  ///
  /// Beim Ziehen sieht man den Kringel bereits — eine zusaetzliche Meldung
  /// "wird aktualisiert" waere doppelt. Beim Knopf oben gibt es keine solche
  /// Rueckmeldung, dort bleibt sie.
  Future<void> _refreshAll({bool fromGesture = false}) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    final t = AppLocalizations.of(context);
    if (!fromGesture) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.refreshRunning), backgroundColor: cCard,
          duration: const Duration(seconds: 2), behavior: SnackBarBehavior.floating));
    }
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
      // Zusagen und ungelesene Nachrichten gehoeren dazu: Wer aktualisiert,
      // will den GANZEN Stand sehen, nicht nur Badges und Punkte.
      _loadMyEvents();
      _loadChatUnread();
    } catch (_) {/* einzelne Fehler ignorieren, Rest läuft */}
    if (!mounted) return;
    setState(() => _refreshing = false);
    if (!fromGesture) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(t.refreshDone), backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating));
    }
  }

  // ============================================================
  // BUSINESS LOGIC (1:1 dashboard.dart + Profilbild + Countdown)
  // ============================================================
  void _loadAll() async {
    await _loadUser();
    if (_user.nickname == 'Anon' || _user.nickname.isEmpty) { if (mounted) { await Navigator.push(context, MaterialPageRoute(builder: (_) => const IdentitySetupScreen())); await _loadUser(); } }
    await _loadBadges(); await _calculateTrustScore(); await _reVerifyAdminStatus();
    _loadIdentityData(); _checkActiveSession(); _loadChatUnread(); _loadMyEvents(); _syncOrganicAdminsInBackground(); _checkDeviceIntegrity();
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

  bool _eventMatchesFavorite(CalendarEvent event, String key) {
    final meetup = MeetupService.resolveFavorite(key);
    return meetup != null
        ? MeetupEventMatcher.resolve(event, MeetupService.cached)?.id == meetup.id
        : MeetupEventMatcher.matchesCity(event, key);
  }

  void _loadNextHomeMeetup() async {
    final favs = _user.favoriteMeetupIds.isNotEmpty
        ? _user.favoriteMeetupIds
        : (_user.homeMeetupId.isNotEmpty ? [_user.homeMeetupId] : <String>[]);
    if (favs.isEmpty) { if (mounted) setState(() { _favCards = []; _countdownLoading = false; }); return; }
    try {
      final events = await MeetupCalendarService().fetchMeetupsPortalFirst();
      if (MeetupService.cached.isEmpty) await MeetupService.fetchMeetups();

      // KALENDERTAG-KULANZ: ein Meetup bleibt den ganzen Tag "naechstes".
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Je Favorit-Stadt das naechste Event bestimmen.
      final cards = <_FavCard>[];
      for (final favKey in favs) {
        // Der gespeicherte Wert ist eine Portal-ID (oder bei Altbestand eine
        // Stadt). Fuer die Terminsuche wird daraus der Ort, fuer die
        // Aufschrift der Gruppenname, falls die Stadt mehrere Meetups hat.
        final cityName = MeetupService.cityFor(favKey);
        final label = MeetupService.labelFor(favKey);
        final upcoming = events.where((e) => _eventMatchesFavorite(e, favKey))
            .where((e) => !e.startTime.isBefore(todayStart))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        final chosen = upcoming.isNotEmpty ? upcoming.first : null;
        AppLogger.diag('HomeMeetup',
            'Favorit "$label" ($favKey): ${upcoming.length} Termine, naechster = '
            '${chosen == null ? "keiner" : "\"${chosen.title}\" am ${chosen.startTime.day}.${chosen.startTime.month}. (${_daysUntil(chosen.startTime)} Tage)"}');
        cards.add(_FavCard(
            key: favKey, label: label, city: cityName, event: chosen));
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

      // Zusagen zu Meetup-Terminen im Hintergrund nachziehen. Hier, weil die
      // Terminliste an dieser Stelle ohnehin vorliegt — ein zweiter Abruf
      // waere reine Verschwendung.
      _loadMeetupRsvps(events);
    } catch (_) { if (mounted) setState(() => _countdownLoading = false); }
  }

  /// Haelt den Proof of Humanity aktuell.
  ///
  /// Frueher sammelte diese Methode zusaetzlich Plattform-Nachweise und
  /// prueefte NIP-05 — beides nur, um vier Felder zu fuellen, die
  /// ausschliesslich das Trust-Score-Sheet las. Mit dessen Wegfall waren die
  /// Abfragen Arbeit ohne Wirkung: Relay-Verbindungen und eine
  /// NIP-05-Aufloesung bei jedem Start, deren Ergebnis niemand ansah.
  ///
  /// Die Neupruefung bleibt, weil sie eine echte NEBENWIRKUNG hat: Sie
  /// schreibt den bestaetigten Zustand in die Einstellungen zurueck. Wer sie
  /// mitentfernt haette, haette einen abgelaufenen Nachweis nie wieder
  /// aufgefrischt.
  void _loadIdentityData() async {
    try {
      final humanity = await HumanityProofService.getStatus();
      if (humanity.needsReverification) {
        await HumanityProofService.reverifyIfNeeded();
      }
    } catch (_) {}
  }

  void _checkActiveSession() async { final s = await RollingQRService.loadSession(); if (s != null && !s.isExpired) { if (!mounted) return; setState(() => _activeSession = s); _startSessionTimer(); } else { _sessionTimer?.cancel(); if (mounted) setState(() => _activeSession = null); } }
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
  /// Einmaliger Hinweis pro Sitzung: Ohne Portal-Verbindung kann der
  /// Organisator-Status nicht erkannt werden. Betrifft vor allem
  /// Amber-Nutzer, bei denen die stille Auto-Anmeldung nicht geht.
  bool _portalHintShown = false;

  void _showPortalHint() {
    if (_portalHintShown || !mounted) return;
    // Ist der Nutzer bereits ueber eine andere Quelle Organisator, waere
    // der Hinweis nur Laerm.
    if (_user.isAdmin) return;
    _portalHintShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).portalConnectForOrganizer),
      backgroundColor: Colors.orange.shade800,
      duration: const Duration(seconds: 8),
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: AppLocalizations.of(context).portalConnect,
        textColor: Colors.white,
        onPressed: _togglePortalConnection,
      ),
    ));
  }

  Future<void> _checkPortalOrganizer() async {
    try {
      AppLogger.diag('Portal', 'Organisator-Prüfung gestartet');

      // AUTO-CONNECT: Ist noch kein Portal-Token da, aber ein Schlüssel
      // aktiv, versucht die App EINMAL leise, sich mit dem Portal zu
      // verbinden. So muss der Nutzer nicht manuell über Community ->
      // Portal -> Meine Meetups gehen. Ist der Nutzer im Portal bekannt,
      // klappt es automatisch; ist er es nicht, passiert nichts Störendes.
      //
      // WICHTIG: Nur bei LOKALEM Schlüssel lautlos. Bei einem EXTERNEN Signer
      // löst die Signatur eine Rückfrage aus — beim App-Start unerwartet.
      // Diese Nutzer verbinden sich weiter über den manuellen Weg.
      if (!await PortalApiService.hasToken()) {
        if (await SigningService.isExternalSigner) {
          // Bei einem externen Signer loest jede Signatur eine Rueckfrage aus
          // — beim App-Start waere das unerwartet. ABER: Frueher endete es
          // hier stumm, und Nutzer mit Leader-Status im Portal bekamen NIE die
          // Organisator-Kachel, ohne zu ahnen warum. Jetzt gibt es einen
          // sichtbaren, einmaligen Hinweis mit dem Weg dorthin.
          //
          // Die Meldung nannte hier "Amber", weil das lange der einzige
          // externe Signer war. Mit Browsererweiterung und Bunker war sie fuer
          // zwei von drei Faellen falsch — und schickte im Diagnose-Log auf
          // eine falsche Spur.
          AppLogger.warn('Portal',
              'Kein Token und ein externer Signer ist aktiv — Auto-Verbindung '
              'nicht moeglich. Organisator-Status kann ohne '
              'Portal-Verbindung nicht erkannt werden.');
          if (mounted) _showPortalHint();
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
          AppLogger.warn('Portal', 'Token gehört zu anderem Schlüssel — getrennt.');
          await PortalApiService.deleteToken();
          // SOFORT neu anmelden statt bis zum naechsten App-Start zu warten.
          // Vorher blieb ein Organisator nach einem Schluesselwechsel eine
          // ganze Sitzung lang ohne Kachel, obwohl er im Portal Leader ist.
          if (!await SigningService.isExternalSigner) {
            final retry = await PortalApiService.loginWithNostr();
            if (retry.ok) {
              AppLogger.diag('Portal', 'Nach Token-Wechsel automatisch neu verbunden.');
              // Weiter im Ablauf — kein return.
            } else {
              AppLogger.warn('Portal', 'Neuanmeldung nach Token-Wechsel fehlgeschlagen.');
              if (mounted) _showPortalHint();
              return;
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(AppLocalizations.of(context).portalTokenMismatch),
                backgroundColor: Colors.orange.shade800,
                duration: const Duration(seconds: 6),
              ));
            }
            return;
          }
        } else {
          AppLogger.diag('Portal', 'Kein Portal-Token vorhanden — übersprungen.');
          return;
        }
      }
      // Abfrage MIT Statuscode: Ein abgelaufener Token (401) sah frueher
      // aus wie "offline" — der Nutzer blieb still ohne Kachel.
      var res = await PortalApiService.rawGetStatus('/my-meetups');

      if (res.status == 401 || res.status == 403) {
        AppLogger.warn('Portal',
            'Token abgelehnt (HTTP ${res.status}) — wird erneuert.');
        await PortalApiService.deleteToken();
        if (await SigningService.isExternalSigner) {
          // Kein stilles Popup bei Amber — stattdessen ein sichtbarer Hinweis.
          if (mounted) _showPortalHint();
          return;
        }
        final again = await PortalApiService.loginWithNostr();
        if (!again.ok) {
          AppLogger.warn('Portal', 'Erneuerung fehlgeschlagen — keine Änderung.');
          return;
        }
        res = await PortalApiService.rawGetStatus('/my-meetups');
      }

      if (res.status != 200 || res.body == null || !mounted) {
        AppLogger.diag('Portal',
            '/my-meetups: keine verwertbare Antwort (HTTP ${res.status}) — keine Änderung.');
        return;
      }
      final body = res.body;
      final data = (body is Map) ? body['data'] : body;
      final meetups = (data is List) ? data.whereType<Map<String, dynamic>>().toList() : <Map<String, dynamic>>[];
      AppLogger.diag('Portal', '/my-meetups lieferte ${meetups.length} Meetup(s) für aktuellen Schlüssel.');

      if (meetups.isNotEmpty && !_user.adminViaPortal) {
        // VERGEBEN: nur das Portal-Flag setzen (Vouch/Seed unberührt).
        // Die Daten werden IMMER gesetzt, nur das UI-Update haengt an
        // mounted: sonst wuerde _user.save() unten den alten Stand
        // speichern, falls der Screen zwischenzeitlich verlassen wurde.
        _user.adminViaPortal = true;
        _user.isAdminVerified = _user.isAdmin;
        if (mounted) setState(() {});
        await _user.save();
        // Organizer-Claim an Nostr publizieren (best effort): macht den
        // Status für Dritte sichtbar; kein manuelles Register nötig.
        final meetupName = (meetups.first['name'] ?? _user.homeMeetupId).toString();
        try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: meetupName.isNotEmpty ? meetupName : 'Unbekannt'); } catch (_) {}
        // Keine Meldung mehr.
        //
        // Die Pruefung laeuft bei jedem Start und bei jedem Aktualisieren —
        // die Einblendung erschien also nicht bei einer VERAENDERUNG, sondern
        // jedes Mal aufs Neue. Wer laengst Organisator ist, bekam dauernd
        // gesagt, dass er es jetzt geworden sei. Den Status zeigt die
        // Organisator-Kachel, und die ist der ruhigere Ort dafuer.
        AppLogger.info('Portal', 'Organisator-Status bestaetigt (Portal).');
      } else if (meetups.isEmpty && _user.adminViaPortal) {
        // ENTZIEHEN: nur das Portal-Flag löschen. Bleibt der Nutzer über
        // WoT-Bürgschaft/Seed berechtigt, behält er isAdmin (abgeleitet).
        // Daten immer setzen, UI-Update nur wenn noch gemountet (s.o.).
        _user.adminViaPortal = false;
        _user.isAdminVerified = _user.isAdmin;
        if (mounted) setState(() {});
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

  Future<void> _reVerifyAdminStatus() async { try { final v = await _user.reVerifyAdmin(myBadges); if (mounted) setState(() {}); if (v.isAdmin && (v.source == 'trust_score' || v.source == 'vouch_consensus')) { try { await PromotionClaimService.publishAdminClaim(badges: myBadges, meetupName: _user.homeMeetupId.isNotEmpty ? _user.homeMeetupId : 'Unbekannt'); } catch (_) {} AppLogger.info('Admin', 'Organisator-Status bestaetigt (${v.source}).'); } } catch (_) { if (mounted) setState(() { _user.adminViaVouch = false; _user.isAdminVerified = _user.isAdmin; }); } }
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
      // Der Auswahldialog oben war ein await — erst pruefen, dann den
      // Context weiterreichen.
      if (!mounted) return;
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
    // Zuerst die laufende NIP-46-Sitzung schliessen (In-Memory-Client +
    // Sitzungsschluessel). Nur deleteNip46ClientKey() liess offene Relays und
    // den geheimen Schluessel in _nip46 bis zum Prozessende liegen.
    try { await SigningService.disconnectNip46(); } catch (_) {}
    final p = await SharedPreferences.getInstance();
    await p.clear();
    myBadges.clear();
    await MeetupBadge.saveBadges([]);
    try { await SecureKeyStore.deleteKeys(); } catch (_) {}
    // Idempotent: disconnectNip46 hat den Key schon geloescht; falls der
    // Aufruf scheiterte, raeumen wir hier nach.
    try { await SecureKeyStore.deleteNip46ClientKey(); } catch (_) {}
    // Die EasyAuth-Blobs auch: `easyauth_password_ncryptsec` ist eine
    // VOLLSTAENDIGE Kopie des privaten Schluessels, nur passwortverschluesselt.
    // Ohne diese Zeile ueberlebt sie das Zuruecksetzen — dieselbe Luecke wie
    // vorher beim Sitzungsschluessel des Remote-Signers.
    try { await LocalKeyVault.clearAll(); } catch (_) {}
    try { await PortalApiService.logout(); } catch (_) {}
    await NostrProfileService.clearCache();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const IntroScreen()), (r) => false);
    }
  }
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
        //
        // Der Tour-Schluessel haengt HIER und nicht in der _tourKeys-Tabelle:
        // Diese Kachel wird als einzige nicht ueber _wrapEditable gezeichnet,
        // also griff die Tabelle bei ihr nie. Die Dashboard-Tour wartete
        // dadurch auf ein Ziel, das nie erschien, und startete nicht.
        KeyedSubtree(
            key: HomeTour.homeMeetupKey, child: _buildHomeMeetupTile()),
        const SizedBox(height: kTileGap),
        // Restlicher Raum: Der angeheftete Block fuellt weiterhin den
        // sichtbaren Bereich; die graue Reserve haengt darunter und wird
        // durch Scrollen erreicht. Ist etwas verfuegbar, bleibt unten Platz
        // fuer den Sektionskopf, damit man sieht, dass da noch etwas ist.
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final hasAvailable =
                _buildTileRows(excludeHomeMeetup: true, pinned: false).isNotEmpty;
            // Untergrenze nie ueber der verfuegbaren Hoehe: clamp(120, x)
            // mit x < 120 wirft einen ArgumentError — passiert im Feld,
            // wenn eine Snackbar oder die Tastatur den Platz kurz verkleinert
            // (Fehler "Invalid argument(s): 120.0", Oktober 2026).
            final minPinned = c.maxHeight < 120.0 ? c.maxHeight : 120.0;
            final pinnedHeight = hasAvailable
                ? (c.maxHeight - 34).clamp(minPinned, c.maxHeight)
                : c.maxHeight;
            // Ziehen zum Aktualisieren.
            //
            // Der Knopf oben bleibt — er ist der sichtbare Weg —, aber die
            // Geste ist der erwartete. Wichtig dabei: Das Dashboard ist meist
            // KUERZER als der Bildschirm und liesse sich dann gar nicht
            // ziehen. Deshalb AlwaysScrollableScrollPhysics: Damit reagiert
            // es auch ohne Ueberlaenge auf die Geste.
            return RefreshIndicator(
              onRefresh: () => _refreshAll(fromGesture: true),
              color: cOrange,
              backgroundColor: cCard,
              // Etwas tiefer als ueblich, damit der Kringel unter der
              // Kopfzeile erscheint und sie nicht ueberdeckt.
              displacement: 28,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildScaledTileBlock(pinnedHeight),
                  _buildAvailableSection(),
                  const SizedBox(height: 8),
                ]),
              ),
            );
          }),
        ),
      ]),
    );
  }

  /// Verschiebt [draggedId] an die Position von [targetId] und speichert.
  Future<void> _moveTile(String draggedId, String targetId) async {
    if (draggedId == targetId) return;
    final order = List<String>.from(_tileOrder);
    final from = order.indexOf(draggedId);
    final to = order.indexOf(targetId);
    if (from < 0 || to < 0) return;
    order.removeAt(from);
    order.insert(to, draggedId);
    // Aktion ausgefuehrt -> Modus SOFORT beenden. Ein zusaetzliches
    // "Fertig" waere ein Klick zu viel: Der Nutzer hat sein Ziel erreicht,
    // die App soll das erkennen statt nachzufragen.
    setState(() {
      _tileOrder = order;
      _editTileId = null;
    });
    await _saveTileOrder();
    AppLogger.diag('Dashboard', 'Kachel "$draggedId" vor "$targetId" einsortiert.');
  }

  /// Heftet an bzw. loest die Verankerung. Pflichtkacheln bleiben unberuehrt.
  Future<void> _togglePin(_TileDef tile) async {
    if (!tile.removable) return;
    setState(() {
      if (_hiddenTiles.contains(tile.id)) {
        _hiddenTiles.remove(tile.id);   // -> angeheftet
      } else {
        _hiddenTiles.add(tile.id);      // -> verfuegbar
      }
      _editTileId = null; // Aktion erledigt -> Modus zu
    });
    await _saveTileOrder();
    AppLogger.diag('Dashboard',
        'Kachel "${tile.id}" ${_hiddenTiles.contains(tile.id) ? "geloest" : "angeheftet"}.');
  }

  /// Huelle um jede Kachel: im Normalzustand nur ein Langdruck-Erkenner,
  /// im Bearbeiten-Modus Ziehen, Ablegen und Pinnadel.
  /// Ordnet Kachel-Kennungen den Zielen der Dashboard-Tour zu.
  ///
  /// Bewusst EINE Tabelle statt eines Schluessels in jedem der dreizehn
  /// Kachel-Bauer: Die Bauer geben teils ein _tile zurueck, teils einen
  /// GestureDetector, teils einen ganzen Block — jeden einzeln zu umhuellen
  /// waere dreizehnmal dieselbe Fehlerquelle. Hier haengt der Schluessel
  /// dort, wo die Kachel ohnehin schon als Einheit vorliegt.
  static final Map<String, GlobalKey> _tourKeys = {
    'trust_score':   HomeTour.trustScoreKey,
    'home_meetup':   HomeTour.homeMeetupKey,
    'reputation':    HomeTour.reputationKey,
    'trust_network': HomeTour.wotKey,
    'community':     HomeTour.communityKey,
    'events':        HomeTour.eventsKey,
    'portal_connect':HomeTour.portalConnectKey,
    'btc_dashboard': HomeTour.bitcoinKey,
    'converter':     HomeTour.umrechnerKey,
    'news':          HomeTour.newsKey,
    'portal':        HomeTour.myMeetupsKey,
    'shoutout':      HomeTour.shoutoutKey,
    'podcast':       HomeTour.podcastKey,
  };

  Widget _wrapEditable(_TileDef tile, Widget child) {
    // Schluessel der Tour aussen anlegen, damit das Overlay die Kachel
    // MITSAMT ihrer Umrandung misst.
    final tourKey = _tourKeys[tile.id];
    if (tourKey != null) child = KeyedSubtree(key: tourKey, child: child);

    final isEditing = _editTileId != null;
    final isSelected = _editTileId == tile.id;
    final isPinned = !_hiddenTiles.contains(tile.id);

    if (!isEditing) {
      return GestureDetector(
        onLongPress: () => setState(() => _editTileId = tile.id),
        child: child,
      );
    }

    if (isSelected) {
      // Nochmal antippen = abbrechen, ohne etwas zu aendern.
      final marked = GestureDetector(
        onTap: () => setState(() => _editTileId = null),
        child: Stack(clipBehavior: Clip.none, children: [
        // Rahmen + leichte Vergroesserung heben die Kachel heraus.
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(color: cOrange, width: 2),
            boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.25), blurRadius: 14)],
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(kTileRadius), child: child),
        ),
        const Positioned(
          top: 9, left: 9,
          child: Icon(Icons.open_with_rounded, color: cOrange, size: 15),
        ),
        // PINNADEL: gefuellt = angeheftet, hohl = verfuegbar.
        if (tile.removable)
          Positioned(
            top: -9, right: -7,
            child: GestureDetector(
              onTap: () => _togglePin(tile),
              child: Container(
                width: 30, height: 30,
                decoration: BoxDecoration(
                  color: isPinned ? cOrange : cCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: cOrange, width: 1.5),
                ),
                child: Icon(isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                    color: isPinned ? Colors.black : cOrange, size: 15),
              ),
            ),
          ),
      ]));

      return Draggable<String>(
        data: tile.id,
        feedback: Opacity(
          opacity: 0.9,
          child: SizedBox(width: 190, height: 96,
              child: Material(color: Colors.transparent, child: child)),
        ),
        childWhenDragging: DottedPlaceholder(),
        child: marked,
      );
    }

    // Nicht markiert: Ablageziel fuer die gezogene Kachel.
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) => d.data != tile.id,
      onAcceptWithDetails: (d) => _moveTile(d.data, tile.id),
      builder: (context, cand, rej) => Container(
        decoration: cand.isNotEmpty
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cOrange.withValues(alpha: 0.7), width: 1.5))
            : null,
        child: Opacity(opacity: cand.isNotEmpty ? 0.6 : 1.0, child: child),
      ),
    );
  }

  /// Sektionskopf ueber einer Kachelgruppe.
  Widget _sectionHeader(String label, {int? count, bool? collapsed, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      // Langer Druck auf den Sektionskopf oeffnet die vollstaendige
      // Kachel-Liste — der erweiterte Weg, wenn man mehrere auf einmal
      // umsortieren oder anheften will.
      onLongPress: _showReorderSheet,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
        child: Row(children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: cTextTertiary, fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
          if (count != null) ...[
            const SizedBox(width: 7),
            Text('$count',
                style: const TextStyle(color: cTextTertiary, fontSize: 10.5, fontWeight: FontWeight.w700)),
          ],
          const Spacer(),
          if (collapsed != null)
            Icon(collapsed ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                color: cTextTertiary, size: 18),
        ]),
      ),
    );
  }

  /// Die graue Reserve: alles, was nicht angeheftet ist. Gedaempft
  /// dargestellt, aber voll bedienbar — ein Tipp oeffnet die Funktion wie
  /// gewohnt. Angeheftet wird spaeter im Bearbeiten-Modus.
  Widget _buildAvailableSection() {
    final rows = _buildTileRows(excludeHomeMeetup: true, pinned: false);
    if (rows.isEmpty) return const SizedBox.shrink();
    // Die Nostr-Kachel hat ein eigenes Icon-Layout und benoetigt etwas mehr
    // Hoehe als die standardisierten Wert-Kacheln.
    const double availableTileHeight = 124;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: kTileGap),
      KeyedSubtree(
        key: HomeTour.customizeKey,
        child: _sectionHeader(
          AppLocalizations.of(context).tilesAvailable,
          count: rows.length,
          collapsed: _availableCollapsed,
          onTap: () => setState(() => _availableCollapsed = !_availableCollapsed),
        ),
      ),
      if (!_availableCollapsed || _editTileId != null)
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: kTileGap),
          // Leicht gedaempft. Die eigentliche Abgrenzung leistet inzwischen
          // der Anstrich (schlicht statt gold), deshalb reicht ein Hauch.
          Opacity(opacity: 0.8, child: SizedBox(height: availableTileHeight, child: rows[i])),
        ],
    ]);
  }

  /// Kachel-Block: füllt den Raum zwischen Home-Meetup-Kachel und unterer
  /// Leiste VOLLSTÄNDIG. Jede Reihe bekommt exakt dieselbe berechnete Höhe,
  /// sodass alle Reihen zusammen die volle Höhe ausfüllen (keine Lücke).
  /// Bis die Reihenhöhe unter die Mindesthöhe fällt -> dann scrollbar.
  /// [targetHeight] ist der Platz, den der Block im Idealfall ausfuellen
  /// soll. Passen die Reihen nicht in dieser Hoehe, waechst der Block ueber
  /// sie hinaus — das Dashboard scrollt ohnehin.
  ///
  /// WICHTIG (Fehler in der ersten Fassung): Frueher steckte der Block in
  /// einer SizedBox mit fester Hoehe und rechnete intern per LayoutBuilder.
  /// Brauchten die Reihen mehr Platz, lief der Inhalt aus der SizedBox
  /// heraus und ueberlappte die darunterliegende Sektion. Deshalb gibt der
  /// Block seine Hoehe jetzt SELBST vor und wird nicht mehr beschnitten.
  Widget _buildScaledTileBlock(double targetHeight) {
    final rows = _buildTileRows(excludeHomeMeetup: true);
    if (rows.isEmpty) return const SizedBox.shrink();

    // 118 statt 92 — der Wert stammt aus Razues PR #8: Icon 22 + Abstand +
    // Titel + Untertitel brauchen mit dem Innenabstand zusammen mehr Platz.
    // Mein Umbau des Blocks hatte den Wert versehentlich zurueckgesetzt,
    // wodurch Kacheln wieder aus ihrem Kasten liefen.
    //
    // 120 statt 118: bei 118 lief die Umrechnen-Kachel um 1,4 px ueber. Ihr
    // Wert ("1 € = 1.779 sats") braucht in einer schmalen Kachel die zweite
    // Zeile, die _heroContent erlaubt — danach bleibt fuer die Zusatzzeile
    // ("Kurs & Sats") kein Platz mehr. Zwei Pixel mehr loesen das, ohne
    // Inhalt zu opfern; ein Flexible auf der Zusatzzeile haette sie im
    // Engpass ganz verschwinden lassen, weil der Inhalt hier in einem
    // Positioned.fill mit fester Hoehe sitzt.
    //
    // Die Erhoehung wirkt NUR im Engpass: liegt genug Platz vor, bestimmt
    // ohnehin perRow die Zeilenhoehe.
    const double minRowHeight = 120;
    final gaps = (rows.length - 1) * kTileGap;
    final perRow = (targetHeight - gaps) / rows.length;
    // Fuellen, solange es reicht — sonst Mindesthoehe und ueberstehen lassen.
    final rowHeight = perRow >= minRowHeight ? perRow : minRowHeight;

    return Column(children: [
      for (int i = 0; i < rows.length; i++) ...[
        if (i > 0) const SizedBox(height: kTileGap),
        SizedBox(height: rowHeight, child: rows[i]),
      ],
    ]);
  }

  /// Baut die sichtbaren Kacheln als REIHEN (jede Reihe ein Row-Widget mit
  /// stretch), damit sie sich vertikal dehnen lassen.
  List<Widget> _buildTileRows({bool excludeHomeMeetup = false, bool pinned = true}) {
    _buildingPinnedTile = pinned;
    // pinned=true  -> angeheftete Kacheln (bisher "sichtbar")
    // pinned=false -> verfuegbare Kacheln (bisher "ausgeblendet"), grau
    final visibleTiles = _tileOrder
      .map((id) => _tileDefs.where((t) => t.id == id).firstOrNull)
      .where((t) => t != null && t.visible() && (_hiddenTiles.contains(t.id) != pinned))
      .cast<_TileDef>()
      .where((t) => !excludeHomeMeetup || t.id != 'home_meetup')
      .toList();

    final rows = <Widget>[];
    int i = 0;
    while (i < visibleTiles.length) {
      final tile = visibleTiles[i];
      if (tile.span == 3) {
        rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [Expanded(child: _wrapEditable(tile, tile.builder()))]));
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
            Expanded(flex: row[j].span, child: _wrapEditable(row[j], row[j].builder())),
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
    // Nachschlagen steht LINKS vom Zahnrad: Wer nicht weiterweiss, sucht
    // eher Hilfe als Einstellungen — und trifft sie so zuerst.
    KeyedSubtree(
        key: HomeTour.glossaryKey,
        child: _headerIcon(
            Icons.help_outline_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const GlossaryScreen())))),
    KeyedSubtree(
        key: HomeTour.settingsKey,
        child: _headerIcon(Icons.settings_rounded, _showSettings)),
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
              // Im Browser liefert image_picker eine blob:-URL statt eines
              // Dateipfads, und `File` aus dart:io existiert dort nicht — der
              // Konstruktor wirft schon beim Bauen des Widgets, was
              // errorBuilder NICHT abfaengt. Deshalb dort NetworkImage: blob:
              // ist same-origin und laedt ohne CORS. Nach einem Reload ist die
              // blob:-URL ungueltig; dann greift errorBuilder wie bisher.
              ? Image(
                  image: kIsWeb
                      ? NetworkImage(_localProfilePic!)
                      : FileImage(File(_localProfilePic!)),
                  fit: BoxFit.cover, width: 40, height: 40,
                  errorBuilder: (_, _, _) => _avatarFallback())
              : _profilePicUrl != null
                ? Image.network(_profilePicUrl!, fit: BoxFit.cover, width: 40, height: 40, errorBuilder: (_, _, _) => _avatarFallback())
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
    // Pressable statt GestureDetector: Die Kachel sinkt beim Antippen leicht
    // ein und gibt einen kurzen Haptik-Impuls. KEIN onLongPress hier — der
    // Langdruck gehoert _wrapEditable (Bearbeiten-Modus); ein Erkenner an
    // dieser Stelle wuerde ihn abfangen, bevor die Huelle ihn sieht.
    // In eine lokale Variable holen: Dart traegt die Null-Pruefung von
    // `onTap` NICHT in den Rumpf der Closure hinein — `onTap()` dort waere
    // "kann null sein" und damit ein Compilerfehler. Eine finale lokale
    // Kopie ist promotbar und loest das sauber.
    final tap = onTap;
    return Pressable(
      onTap: tap == null
          ? null
          : () {
              HapticService.light();
              tap();
            },
      child: Container(
        // ANGEHEFTET: derselbe goldene Verlauf wie die Home-Meetup-Kachel,
        // damit oben alles zusammengehoerig wirkt. VERFUEGBAR: schlicht.
        decoration: _buildingPinnedTile
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(kTileRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cOrange.withValues(alpha: 0.13),
                    cOrange.withValues(alpha: 0.04),
                    const Color(0xFF141416),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
                border: Border.all(color: cOrange.withValues(alpha: 0.30), width: 1.0),
                boxShadow: [
                  BoxShadow(
                      color: cOrange.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5)),
                ],
              )
            : BoxDecoration(
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
                // WASSERZEICHEN — bewusst BEIBEHALTEN: Sie sind eine
                // Wiedererkennungshilfe, sobald man die Kacheln kennt.
                // Geaendert wurde nur ihre Zurueckhaltung: kleiner und
                // weiter in die Ecke geschoben, damit sie nicht mehr unter
                // dem Text liegen. Ihre Farbe folgt dem Akzent der Kachel —
                // mit den neuen Bereichsfarben unterscheiden sie sich damit
                // von selbst und tragen zur Orientierung bei, statt als
                // gleichfoermiges Muster zu flimmern.
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: Icon(watermark, size: 84, color: accentColor.withValues(alpha: 0.10)),
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


  /// MEETUP-WAPPEN im "Cover-Flow"-Stil (iTunes): quadratisches Wappen,
  /// linke Kante fest, kippt perspektivisch nach rechts hinten und blendet
  /// dorthin weich aus. Bewusst einfach gehalten (robust auf allen Geräten).
  /// CoverFlow-Wappen fuer EINE Stadt (parametrisiert, damit jede
  /// Favoriten-Karte ihr eigenes Wappen zeigt).
  Widget _crestCoverFlow(String city, Meetup? meetup, {double size = 56}) {
    // Das EIGENE Wappen des Meetups hat Vorrang.
    //
    // MeetupCalendarService.logoFor() sucht ueber den Namen und liefert bei
    // zwei Meetups derselben Stadt beiden dasselbe Bild. Liegt das Meetup-
    // Objekt vor — seit der Umstellung auf die Portal-ID ist das der
    // Normalfall —, nehmen wir dessen Logo.
    String url = '';
    if (meetup != null) {
      url = MeetupCalendarService.absoluteImageUrl(
          meetup.logoUrl.isNotEmpty ? meetup.logoUrl : meetup.coverImagePath);
    }
    // Rueckfall: das ueber den Namen gefundene Termin-Logo. Greift bei
    // Favoriten aus aelteren Fassungen, zu denen kein Meetup-Objekt
    // aufloest.
    if (url.isEmpty) url = MeetupCalendarService.logoFor(city);
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
                errorBuilder: (_, _, _) => const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }

  /// Ungelesene Nachrichten je gespeichertem Favoriten. Leer, solange
  /// nichts geladen wurde.
  final Map<String, int> _chatUnread = {};

  /// Kachel "Meine Termine".
  ///
  /// Erscheint nur, wenn ueberhaupt etwas zugesagt ist — eine Kachel, die
  /// dauerhaft "0" zeigt, ist verschenkte Flaeche. Ausblenden laesst sie sich
  /// wie jede andere per Langdruck.
  Widget _buildMyEventsTile() => Container(
        child: _tile(
          accentColor: cNostr,
          watermark: Icons.event_available_rounded,
          onTap: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyEventsScreen(
                    events: _myEvents,
                    meetupDates: _favMeetupDates
                        .map((m) => MyMeetupDate(
                            favKey: m.favKey,
                            label: m.label,
                            event: m.event,
                            attendees: m.attendees))
                        .toList(),
                    onOpenMeetupChat: _openMeetupChat,
                    onChanged: _loadMyEvents,
                  ),
                ));
            // Zurueck: Lesestaende koennen sich geaendert haben.
            if (mounted) _loadMyEvents();
          },
          child: _heroContent(
            icon: Icons.event_available_rounded,
            accent: cNostr,
            label: AppLocalizations.of(context).tileEventChats,
            // Die ZAHL traegt die Kachel: zugesagte Veranstaltungen PLUS die
            // naechsten Termine der Favoriten-Meetups. Beides ist "was ich
            // vorhabe" — die Unterscheidung, ob dahinter eine Zusage oder ein
            // Favorit steht, interessiert erst eine Ebene tiefer.
            value: '${_myEvents.length + _favMeetupDates.length}',
            // Die Farbe der ZAHL macht den Unterschied: orange, wenn etwas
            // Neues in einem der Chats steht. Ein zusaetzliches Abzeichen
            // waere auf einer Kachel dieser Groesse Zierrat.
            valueColor: _myEventsUnread > 0 ? cOrange : null,
            sub: _myEvents.isEmpty && _favMeetupDates.isEmpty
                ? AppLocalizations.of(context).tileEventChatsNone
                : _myEventsUnread > 0
                ? AppLocalizations.of(context).tileEventChatsUnread(_myEventsUnread)
                : AppLocalizations.of(context).tileEventChatsSub,
          ),
        ),
      );

  /// Zugesagte, noch bevorstehende Veranstaltungen — Grundlage der Kachel.
  List<NostrCalendarEvent> _myEvents = [];

  /// Meetup-Termine, fuer die man im Portal ZUGESAGT hat.
  ///
  /// Das Portal fuehrt Zu- und Absagen je Termin unter einer eigenen Nummer
  /// (`portalEventId`) — samt Teilnehmerzahl. Anfangs hatte ich angenommen,
  /// es gaebe das nicht, und den Favoriten als Aussage genommen. Das war
  /// falsch: Ein Favorit heisst "das ist mein Meetup", eine Zusage heisst
  /// "ich komme am 20." — zwei verschiedene Dinge.
  List<_MeetupDateEntry> _favMeetupDates = [];

  /// Ungelesene Beitraege ueber ALLE zugesagten Termine zusammen.
  int _myEventsUnread = 0;

  /// Sammelt Meetup-Termine, fuer die im Portal zugesagt wurde.
  ///
  /// Gefragt wird nur fuer Termine der EIGENEN Favoriten und nur fuer die
  /// naechsten drei Monate — eine Abfrage je Termin ueber alle 158 Termine
  /// des Portals waere unverhaeltnismaessig fuer eine Kachel.
  Future<void> _loadMeetupRsvps(List<CalendarEvent> allEvents) async {
    final favKeys = <String>{
      if (_user.homeMeetupId.isNotEmpty) _user.homeMeetupId,
      ..._user.favoriteMeetupIds,
    };
    if (favKeys.isEmpty) {
      if (mounted) setState(() => _favMeetupDates = []);
      return;
    }

    final now = DateTime.now();
    final horizon = now.add(const Duration(days: 90));
    final candidates = allEvents.where((e) {
      if (e.portalEventId == null) return false;
      if (e.startTime.isBefore(now.subtract(const Duration(days: 1)))) {
        return false;
      }
      if (e.startTime.isAfter(horizon)) return false;
      // Use the same identity rules as the Home cards.
      return favKeys.any((key) => _eventMatchesFavorite(e, key));
    }).toList();

    final out = <_MeetupDateEntry>[];
    for (final e in candidates) {
      final r = await PortalApiService.getRsvpCached(e.portalEventId!);
      if (!PortalApiService.isGoing(r)) continue;
      // Recover the saved favorite using the same rule as the filter above.
      final favKey = favKeys.firstWhere(
        (key) => _eventMatchesFavorite(e, key),
        orElse: () => e.meetupId,
      );
      out.add(_MeetupDateEntry(
        favKey: favKey,
        label: MeetupService.labelFor(favKey),
        event: e,
        attendees: (r?['attendees'] ?? r?['count'] ?? -1) is int
            ? (r?['attendees'] ?? r?['count'] ?? -1) as int
            : -1,
      ));
    }
    out.sort((a, b) => a.event.startTime.compareTo(b.event.startTime));

    if (mounted) setState(() => _favMeetupDates = out);
    AppLogger.diag('Events',
        '${candidates.length} Termine der Favoriten geprueft, ${out.length} davon zugesagt.');
  }

  /// Laedt Zusagen und die dazugehoerigen Termine.
  ///
  /// Zwei Abfragen: erst die eigenen Antworten (eine je Nutzer), dann die
  /// Termine dazu. Vergangenes faellt weg — eine Kachel soll zeigen, was
  /// ansteht, nicht was war.
  Future<void> _loadMyEvents() async {
    try {
      final rsvps = await EventRsvpService.loadMine();
      final accepted = rsvps.entries
          .where((e) => e.value == RsvpStatus.accepted)
          .map((e) => e.key)
          .toList();
      if (accepted.isEmpty) {
        if (mounted) {
          setState(() {
            _myEvents = [];
            _myEventsUnread = 0;
          });
        }
        return;
      }

      final events = <NostrCalendarEvent>[];
      for (final address in accepted) {
        final ev = await CalendarEventService.fetchByAddress(address);
        if (ev == null) continue;
        // Termine von gestern interessieren niemanden mehr; der Chat dazu
        // bleibt ueber den Kalender erreichbar.
        if (ev.start.isBefore(
            DateTime.now().subtract(const Duration(days: 1)))) {
          continue;
        }
        events.add(ev);
      }
      events.sort((a, b) => a.start.compareTo(b.start));

      final counts = events.isEmpty
          ? <String, int>{}
          : await EventChatService.unreadCounts(
              events.map((e) => e.address).toList());

      if (!mounted) return;
      setState(() {
        _myEvents = events;
        _myEventsUnread =
            counts.values.fold<int>(0, (sum, v) => sum + v);
      });
    } catch (e) {
      AppLogger.debug('Events', 'Zusagen konnten nicht geladen werden: $e');
    }
  }

  /// Findet den Raum zu einem gespeicherten Favoriten.
  ///
  /// Zuerst ueber die PORTAL-ID — das ist die exakte Zuordnung und der
  /// einzige Weg, bei mehreren Meetups einer Stadt das richtige zu treffen.
  /// Nur wenn der Favorit noch aus einer aelteren Fassung stammt und einen
  /// Stadtnamen enthaelt, greift die alte Namenssuche.
  ///
  /// Wirft [ChatRelayUnavailable], wenn das Relay keine Auskunft gab. Dann
  /// wird bewusst NICHT ueber den Stadtnamen weitergesucht: Dieselbe
  /// Stoerung traefe auch diese Suche, und ihr leeres Ergebnis saehe aus
  /// wie "kein Raum".
  Future<ChatRoom?> _findRoomFor(String favKey) async {
    final meetup = MeetupService.resolveFavorite(favKey);
    if (meetup != null) {
      final byId = await ChatService.findRoomForMeetupId(meetup.id);
      if (byId != null) return byId;
    }
    return ChatService.findRoomForCity(MeetupService.cityFor(favKey));
  }

  /// Prueft fuer alle Favoriten, ob im jeweiligen Chatraum etwas Neues liegt.
  ///
  /// Laeuft im Hintergrund und ohne Ladeanzeige: Das Dashboard soll nicht auf
  /// das Relay warten. Kommt nichts zurueck, bleibt die Leiste eben ohne
  /// Punkt — das ist besser als ein Dashboard, das haengt.
  Future<void> _loadChatUnread() async {
    // Mengen-Literal statt Liste plus toSet(): Doppelte fallen direkt weg,
    // ohne dass eine Zwischenliste entsteht. Home-Meetup steht zuerst und
    // bleibt es auch — Mengen-Literale behalten die Einfuegereihenfolge.
    final favKeys = <String>{
      if (_user.homeMeetupId.isNotEmpty) _user.homeMeetupId,
      ..._user.favoriteMeetupIds,
    }.toList();
    if (favKeys.isEmpty) return;

    try {
      // Erst Favorit -> Raum, dann eine einzige Abfrage fuer alle Raeume.
      final byRoom = <String, String>{};
      for (final favKey in favKeys) {
        final room = await _findRoomFor(favKey);
        if (room != null) byRoom[room.h] = favKey;
      }
      if (byRoom.isEmpty || !mounted) return;

      final counts = await ChatService.unreadCounts(byRoom.keys.toList());
      if (!mounted) return;
      setState(() {
        for (final e in counts.entries) {
          final favKey = byRoom[e.key];
          if (favKey != null) _chatUnread[favKey] = e.value;
        }
      });
    } catch (e) {
      AppLogger.debug('Chat', 'Ungelesen-Abfrage fehlgeschlagen: $e');
    }
  }

  /// Oeffnet den Chat-Raum eines Meetups.
  ///
  /// Die Suche laeuft ueber das Relay und dauert einen Moment — deshalb ein
  /// Ladehinweis, sonst wirkt der Knopf tot.
  Future<void> _openMeetupChat(String favKey, String label) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    messenger.showSnackBar(SnackBar(
        content: Text(t.chatSearching),
        duration: const Duration(seconds: 4),
        backgroundColor: cCard));

    ChatRoom? room;
    try {
      room = await _findRoomFor(favKey);
    } on ChatRelayUnavailable catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      // Keine Behauptung ueber das Meetup — nur ueber die Verbindung. Und
      // unterscheiden: Ohne Netz liegt es weder am Relay noch am Signierer.
      messenger.showSnackBar(SnackBar(
          content: Text(e.offline ? t.chatOffline : t.chatRelayUnavailable),
          duration: const Duration(seconds: 5),
          backgroundColor: cCard));
      return;
    }
    if (!mounted) return;
    messenger.hideCurrentSnackBar();

    if (room == null) {
      // Vier Sekunden statt der ueblichen zwei: Der Satz nennt einen Grund
      // und einen Ort zum Nachsehen — den liest niemand im Vorbeigehen.
      messenger.showSnackBar(SnackBar(
          content: Text(t.chatNoRoom(label)),
          duration: const Duration(seconds: 4),
          backgroundColor: cCard));
      return;
    }
    // Eigene final-Variable: In der Builder-Closure greift die
    // Null-Pruefung von `room` nicht, weil es vorher zugewiesen wurde.
    final found = room;
    await navigator.push(
        MaterialPageRoute(builder: (_) => ChatScreen.room(found)));
    // Zurueck aus dem Raum: Der Lesestand hat sich geaendert, also neu
    // zaehlen — sonst bliebe der Punkt stehen, obwohl alles gelesen ist.
    if (mounted) _loadChatUnread();
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
              Text(AppLocalizations.of(context).homeMeetupChooseSub, style: const TextStyle(color: cTextSecondary, fontSize: 12.5)),
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
        : [
            _FavCard(
                key: _user.homeMeetupId,
                label: MeetupService.labelFor(_user.homeMeetupId),
                city: MeetupService.cityFor(_user.homeMeetupId),
                event: _nextHomeMeetup)
          ];

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
  /// Die Favoriten-Kachel.
  ///
  /// Aufbau (Entwurf A): Kopfbereich mit Wappen, Ort und naechstem Termin,
  /// darunter eine Aktionsleiste aus drei gleich breiten Feldern.
  ///
  /// Vorher lagen die Handlungen in einer 88 Punkte schmalen Spalte rechts —
  /// ein beschrifteter Knopf und darunter zwei winzige Symbolknoepfe. Drei
  /// Handlungen in drei verschiedenen Formaten auf engstem Raum; mit dem
  /// Chat als drittem kippte es. Jetzt haben alle drei dieselbe Form, gleiche
  /// Breite und rund dreimal so grosse Trefferflaechen.
  ///
  /// Der naechste Termin ist nach OBEN gewandert: Er beschreibt das Meetup,
  /// er ist keine Handlung — unten stehen nur noch Handlungen.
  Widget _favCardContent(_FavCard card) {
    final cityName = card.city;
    final event = card.event;
    // Ueber die gespeicherte Kennung aufloesen, nicht ueber die Stadt: Nur
    // so trifft es bei mehreren Meetups derselben Stadt das richtige.
    final meetup =
        MeetupService.resolveFavorite(card.key) ?? _meetupForCity(cityName);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kTileRadius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [cOrange.withValues(alpha: 0.13), cOrange.withValues(alpha: 0.04), const Color(0xFF141416)],
          stops: const [0.0, 0.45, 1.0]),
        border: Border.all(color: cOrange.withValues(alpha: 0.30), width: 1.0),
        boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _crestCoverFlow(cityName, meetup, size: 60),
            const SizedBox(width: 14),
            Expanded(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.20), borderRadius: BorderRadius.circular(6)),
                    child: Text(AppLocalizations.of(context).homeMeetupLabel, style: const TextStyle(color: cOrange, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
                  const SizedBox(width: 8),
                  Text(meetup?.country ?? 'DE',
                    style: const TextStyle(color: cTextSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 5),
                // Der Ortsname wird NICHT abgeschnitten: Bei laengeren Namen
                // schrumpft die Schrift und darf auf zwei Zeilen umbrechen.
                // Die Staffelung ist bewusst grob — feinere Abstufungen
                // bringen optisch nichts.
                Text(card.label.toUpperCase(),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: cText,
                      fontSize: card.label.length > 20
                          ? 13
                          : card.label.length > 15
                              ? 15
                              : card.label.length > 10
                                  ? 17
                                  : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.05)),
                const SizedBox(height: 5),
                _favNextEvent(event),
              ])),
          ]),
        ),
        _favActions(card, meetup),
      ]),
    );
  }

  /// Zeile mit dem naechsten Termin — kompakt, damit sie in den Kopfbereich
  /// passt.
  Widget _favNextEvent(CalendarEvent? event) {
    if (_countdownLoading) {
      return const SizedBox(
          height: 14,
          width: 90,
          child: LinearProgressIndicator(
              color: cOrange, backgroundColor: Colors.transparent));
    }
    if (event == null) {
      return Row(children: [
        const Icon(Icons.event_busy_rounded, color: cTextTertiary, size: 13),
        const SizedBox(width: 6),
        Flexible(
          child: Text(AppLocalizations.of(context).homeMeetupNoDate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: cTextTertiary, fontSize: 12)),
        ),
      ]);
    }

    final days = _daysUntil(event.startTime);
    final label = days <= 0
        ? AppLocalizations.of(context).homeMeetupToday
        : days == 1
            ? AppLocalizations.of(context).homeMeetupTomorrow
            : AppLocalizations.of(context).homeMeetupInDays(days);

    return Row(children: [
      const Icon(Icons.event_available_rounded, color: cTextTertiary, size: 13),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              color: days <= 0
                  ? cOrange
                  : days <= 3
                      ? cOrange.withValues(alpha: 0.8)
                      : cTextSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800)),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
            '· ${event.startTime.day}.${event.startTime.month}.${event.startTime.year}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: cTextTertiary, fontSize: 12)),
      ),
    ]);
  }

  /// Die Aktionsleiste: Termine, Chat, Info — drei gleich breite Felder,
  /// getrennt durch Haarlinien.
  ///
  /// Gleiche Breite ist Absicht: Keine der drei Handlungen ist wichtiger als
  /// die anderen, und gleiche Felder lassen sich blind treffen.
  Widget _favActions(_FavCard card, Meetup? meetup) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cTileBorder, width: 0.5)),
      ),
      child: Row(children: [
        Expanded(
          child: _favAction(
            icon: Icons.event_rounded,
            label: AppLocalizations.of(context).btnEvents,
            accent: cOrange,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CalendarScreen(
                    initialSearch: card.city, initialMeetupId: meetup?.id))),
          ),
        ),
        Container(width: 0.5, height: 26, color: cTileBorder),
        Expanded(
          child: _favAction(
            icon: Icons.forum_rounded,
            label: AppLocalizations.of(context).btnChat,
            accent: cNostr,
            badge: _chatUnread[card.key] ?? 0,
            onTap: () => _openMeetupChat(card.key, card.label),
          ),
        ),
        Container(width: 0.5, height: 26, color: cTileBorder),
        Expanded(
          child: _favAction(
            icon: Icons.info_outline_rounded,
            label: AppLocalizations.of(context).btnInfo,
            accent: cTextSecondary,
            // Ohne Meetup-Datensatz gibt es nichts zu zeigen — dann bleibt
            // das Feld sichtbar, aber blass und ohne Wirkung. So bleibt die
            // Leiste bei allen Favoriten gleich breit.
            onTap: meetup == null
                ? null
                : () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => MeetupDetailsScreen(meetup: meetup))),
          ),
        ),
      ]),
    );
  }

  /// [badge] > 0 setzt einen Zaehler ans Symbol.
  Widget _favAction({
    required IconData icon,
    required String label,
    required Color accent,
    int badge = 0,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // Stack statt einer zusaetzlichen Zeile: Der Zaehler sitzt AM
          // Symbol und veraendert die Breite des Feldes nicht — sonst
          // wuerden die drei Felder ungleich breit, sobald etwas ungelesen
          // ist.
          Stack(clipBehavior: Clip.none, children: [
            Icon(icon,
                color: enabled ? accent : cTextTertiary.withValues(alpha: 0.5),
                size: 15),
            if (badge > 0)
              Positioned(
                right: -6,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 13),
                  decoration: BoxDecoration(
                    color: cOrange,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(badge > 99 ? '99+' : '$badge',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          height: 1.3)),
                ),
              ),
          ]),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: enabled ? accent : cTextTertiary.withValues(alpha: 0.5),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2)),
          ),
        ]),
      ),
    );
  }

  /// WERT-KACHEL: kleines Etikett oben, grosser Wert darunter, Zusatz klein.
  ///
  /// Der Unterschied zur bisherigen Bauform ist inhaltlich, nicht kosmetisch:
  /// Frueher stand ueberall der NAME der Funktion gross und darunter eine
  /// Beschreibung ("Bitcoin / Netzwerk & Kurs"). Damit sahen fuenfzehn Kacheln
  /// gleich aus und keine sagte etwas. Jetzt traegt der WERT die Kachel und
  /// der Name schrumpft auf eine unauffaellige Zeile — dadurch unterscheiden
  /// sich die Kacheln von selbst und man sieht auf einen Blick, was los ist.
  Widget _heroContent({
    required IconData icon,
    required Color accent,
    required String label,
    required String value,
    String? sub,
    Color? valueColor,
    double valueSize = 24,
    Widget? trailing,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        Icon(icon, color: accent, size: 16),
        const SizedBox(width: 6),
        // Das Etikett ist der Aufhaenger: in der Akzentfarbe der Kachel und
        // fett, damit man in einem Blick weiss, WAS man da sieht.
        // FittedBox statt Abschneiden — "REPUTATION" passte in einer
        // Drittel-Kachel sonst nicht und wurde zu "REPUTATI…".
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(label.toUpperCase(),
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                    color: accent, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
          ),
        ),
        ?trailing,
      ]),
      const SizedBox(height: 7),
      Text(value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              color: valueColor ?? cText, fontSize: valueSize, fontWeight: FontWeight.w800, height: 1.12)),
      if (sub != null && sub.isNotEmpty) ...[
        const SizedBox(height: 3),
        Text(sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: cTextSecondary, fontSize: 12.5)),
      ],
    ]);
  }

  Widget _buildReputationTile() {
    final score = _trustScore;
    final counted = myBadges.where((b) => b.isNostrSigned && !b.isOrganizer).length;
    return _tile(
      accentColor: Colors.amber,
      watermark: Icons.workspace_premium_rounded,
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ReputationQRScreen())),
      child: _heroContent(
        icon: Icons.workspace_premium_rounded,
        accent: Colors.amber,
        label: AppLocalizations.of(context).tileReputation,
        value: score != null ? score.totalScore.toStringAsFixed(1) : '—',
        sub: counted > 0
            ? AppLocalizations.of(context).tileReputationBadges(counted)
            : AppLocalizations.of(context).tileReputationCheck,
        // Weiss statt Stufenfarbe: Die Stufenfarben (Amber, Gruen, Cyan)
        // haben auf dem goldenen Untergrund zu wenig Kontrast — die Zahl
        // war schlechter lesbar als der Rest der Kachel.
        valueSize: 26,
      ),
    );
  }
  Widget _buildTrustNetworkTile() => _tile(accentColor: cOrange, watermark: Icons.account_tree_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyNetworkScreen())), child: _heroContent(
      icon: Icons.account_tree_rounded,
      accent: cGreen,
      label: AppLocalizations.of(context).tileActEncounters,
      value: AppLocalizations.of(context).tileTrustNetwork,
      valueSize: 17,
      sub: AppLocalizations.of(context).tileTrustNetworkSub,
    ));
  Widget _buildCommunityTile() => _tile(accentColor: cCyan, watermark: Icons.hub_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityHubScreen())), child: _heroContent(
      icon: Icons.hub_rounded,
      accent: cGreen,
      label: AppLocalizations.of(context).tileActExchange,
      value: AppLocalizations.of(context).tileCommunity,
      valueSize: 17,
      sub: AppLocalizations.of(context).tileCommunityPortal,
    ));
  Widget _buildEventsTile() {
    final t = AppLocalizations.of(context);
    final hasToday = _eventsToday > 0;
    return _tile(
      accentColor: hasToday ? cOrange : cTextTertiary,
      watermark: Icons.event_rounded,
      // Nach der Rueckkehr die Session pruefen: Im Kalender laesst sich
      // inzwischen eine Event-Badge-Session starten, und ohne diese Zeile
      // erschiene die laufende Session erst beim naechsten Aktualisieren
      // des Dashboards.
      onTap: () async {
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EventCalendarScreen(initialDay: DateTime.now())));
        _checkActiveSession();
        // Im Kalender kann man zugesagt haben — dann gehoert die Kachel
        // "Meine Termine" sofort her, nicht erst beim naechsten Start.
        _loadMyEvents();
      },
      child: _heroContent(
        icon: Icons.event_rounded,
        accent: hasToday ? cOrange : cTextSecondary,
        label: t.tileEvents,
        // Steht heute etwas an, traegt die ZAHL die Kachel. Sonst waere eine
        // grosse "0" nur truebselig — dann steht dort die Funktion selbst,
        // eine Stufe kleiner.
        value: hasToday ? '$_eventsToday' : t.tileEventsCalendar,
        valueSize: hasToday ? 26 : 16,
        valueColor: hasToday ? cText : cTextSecondary,
        sub: hasToday ? t.tileEventsToday : null,
      ),
    );
  }

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
              style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(t.portalTileSub, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
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

  Widget _buildVoiceWalletTile() => _tile(
    accentColor: cOrange,
    opacity: 0.07,
    watermark: Icons.mic_rounded,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceWalletScreen())),
    child: _heroContent(
      icon: Icons.mic_rounded,
      accent: cOrange,
      label: AppLocalizations.of(context).tileVoiceWallet,
      value: AppLocalizations.of(context).tileVoiceWalletValue,
      valueSize: 17,
      sub: AppLocalizations.of(context).tileVoiceWalletSub,
    ),
  );

  Widget _buildBtcDashboardTile() => _tile(
    accentColor: cOrange,
    opacity: 0.07,
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BitcoinDashboardScreen())),
    child: const _BtcDashboardTileContent(),
  );

  Widget _buildConverterTile() {
    // Echter Wert statt Wegweiser: Der Kurs liegt ohnehin vor, also
    // zeigt die Kachel gleich, was eine Einheit der gewählten Währung
    // heute in Sats ist — "1 € = …", "1 CHF = …" (Issue #66).
    //
    // BEWUSST ohne ValueListenableBuilder: Dessen Builder laeuft erst
    // spaeter, wenn _buildingPinnedTile schon fuer die naechste Gruppe
    // umgestellt ist — die angeheftete Kachel erschien dadurch grau statt
    // orange. Neu gezeichnet wird stattdessen ueber _onCurrencyChanged.
    final cur = CurrencyService.current.value;
    final price = MempoolService.lastDashboard?.priceIn(cur) ?? 0;
    final satsPerUnit = price > 0 ? (100000000 / price).round() : 0;
    return _tile(accentColor: cCyan, opacity: 0.07, watermark: Icons.swap_vert_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConverterScreen())), child: _heroContent(
      icon: Icons.swap_vert_rounded,
      accent: cCyan,
      label: AppLocalizations.of(context).tileActConvert,
      value: satsPerUnit > 0
          ? '1 ${CurrencyService.symbol(cur)} = ${CurrencyService.groupInt(satsPerUnit)} sats'
          : AppLocalizations.of(context).tileConverter,
      valueSize: 17,
      sub: AppLocalizations.of(context).tileConverterSub,
    ));
  }

  Widget _buildNewsTile() => _tile(
    accentColor: cOrange,
    opacity: 0.07,
    watermark: Icons.article_rounded,
    onTap: _openNews,
    child: _heroContent(
      icon: Icons.article_rounded,
      accent: cOrange,
      label: AppLocalizations.of(context).tileNews,
      // Die Schlagzeile IST der Wert — sie sagt in einem Blick, ob sich
      // das Antippen lohnt.
      value: _latestNewsTitle.isNotEmpty
          ? _latestNewsTitle
          : AppLocalizations.of(context).tileNewsSub,
      valueSize: 14,
      valueColor: _latestNewsTitle.isNotEmpty ? cText : cTextSecondary,
      trailing: _unreadNews > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: cRed, borderRadius: BorderRadius.circular(8)),
              child: Text('$_unreadNews',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
            )
          : null,
    ),
  );

  Widget _buildPortalTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.groups_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PortalMeetupsScreen())), child: _heroContent(
      icon: Icons.groups_rounded,
      accent: cCyan,
      label: AppLocalizations.of(context).tileActLookup,
      value: AppLocalizations.of(context).tilePortal,
      valueSize: 17,
      sub: AppLocalizations.of(context).tilePortalSub,
      trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
    ));
  Widget _buildShoutoutTile() => _tile(accentColor: cOrange, opacity: 0.07, watermark: Icons.campaign_rounded, onTap: () => _openUrl('https://shoutout.einundzwanzig.space'), child: _heroContent(
      icon: Icons.campaign_rounded,
      accent: cOrange,
      label: AppLocalizations.of(context).tileActSend,
      value: AppLocalizations.of(context).tileShoutout,
      valueSize: 17,
      sub: AppLocalizations.of(context).tileShoutoutSend,
    ));
  Widget _buildPodcastTile() => _tile(accentColor: cPurple, opacity: 0.07, watermark: Icons.podcasts_rounded, onTap: () => _openUrl('https://einundzwanzig.space/podcast/'), child: _heroContent(
      icon: Icons.podcasts_rounded,
      accent: cPurpleLight,
      label: AppLocalizations.of(context).tileActListen,
      value: AppLocalizations.of(context).tilePodcast,
      valueSize: 17,
      sub: AppLocalizations.of(context).tilePodcastListen,
    ));
  /// PLEBRAP: Die Kachel IST der Player — Play/Pause/Weiter direkt auf dem
  /// Dashboard, Bibliotheks-Knopf oeffnet die volle Titelliste. Player-
  /// Zustand kommt aus dem app-weiten PlebrapAudio-Service, laeuft also
  /// synchron mit dem Player-Screen und ueberlebt dessen Schliessen.
  Widget _buildPlebrapTile() => _tile(
    accentColor: cOrange,
    watermark: Icons.graphic_eq_rounded,
    child: ValueListenableBuilder<int?>(
      valueListenable: PlebrapAudio.index,
      builder: (_, idx, _) {
        final song = idx != null ? kPlebSongs[idx] : null;
        return Row(children: [
          Expanded(child: _heroContent(
            icon: Icons.graphic_eq_rounded,
            accent: cOrange,
            label: 'PlebRap',
            // Laeuft etwas, steht der TITEL da — sonst der Hinweis, worum
            // es geht. Der Kuenstler rutscht in die Zusatzzeile.
            value: song?.title ?? AppLocalizations.of(context).chPlebrapSub,
            valueSize: song != null ? 17 : 14,
            valueColor: song != null ? cText : cTextSecondary,
            sub: song?.artist,
          )),
          // Play/Pause — Spinner waehrend des Ladens
          ValueListenableBuilder<bool>(
            valueListenable: PlebrapAudio.loading,
            builder: (_, busy, _) => StreamBuilder<PlayerState>(
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
          // Wert der Kachel ist die Anzahl offener Partien. Steht nichts an,
          // traegt der Name die Kachel — eine grosse Null waere truebselig.
          return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.bolt_rounded, color: gold, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('SATOSHIDUELL',
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                          color: gold, fontSize: 12, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            const SizedBox(height: 7),
            Text(n > 0 ? '$n' : t.chDuellSub,
                maxLines: n > 0 ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: n > 0 ? cText : cTextSecondary,
                    fontSize: n > 0 ? 26 : 14,
                    fontWeight: FontWeight.w800,
                    height: 1.12)),
            if (joined.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text.rich(TextSpan(children: joined),
                  style: const TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
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
    child: _heroContent(
      icon: Icons.public_rounded,
      accent: cOrange,
      label: 'Portal',
      value: AppLocalizations.of(context).chPortalSub,
      valueSize: 17,
    ),
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
        Text(AppLocalizations.of(context).tileNostr, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(AppLocalizations.of(context).tileNostrCommunity, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
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
  Widget _buildOrganisatorTile() => _tile(accentColor: cOrange, watermark: Icons.admin_panel_settings_rounded, onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelScreen())); _checkActiveSession(); }, child: _heroContent(
      icon: Icons.admin_panel_settings_rounded,
      accent: cOrange,
      label: AppLocalizations.of(context).tileActManage,
      value: AppLocalizations.of(context).tileOrganizer,
      sub: AppLocalizations.of(context).tileOrganizerPanel,
      valueSize: 17,
      trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 16),
    ));


  /// Kachel fuer die laufende Session.
  ///
  /// Sie fuehrt direkt zum QR — auf einem Event will man die App oeffnen und
  /// den Code zeigen, nicht erst durch den Kalender navigieren. Event- und
  /// Meetup-Sessions unterscheiden sich nur im Symbol; alles andere ist
  /// gleich, weil auch die Handlung dieselbe ist.
  Widget _buildActiveSessionTile() => AnimatedBuilder(animation: _pulseController, builder: (_, _) => GestureDetector(
    onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const RollingQRScreen())); _checkActiveSession(); },
    child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cGreen.withValues(alpha: 0.25), width: 0.5)),
    child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.green.withValues(alpha: 0.5 + _pulseController.value * 0.5), boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.3 * _pulseController.value), blurRadius: 8)])),
      const SizedBox(width: 14), Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)), child: Text(AppLocalizations.of(context).statusLive, style: TextStyle(color: Colors.green.shade300, fontSize: 9, fontWeight: FontWeight.w800))),
      const SizedBox(width: 10),
      // Ordenssymbol bei Event-Sessions: Auf dem Dashboard soll erkennbar
      // sein, WOFUER der Code gerade laeuft — Meetup oder Sondereevent.
      if (_activeSession!.meetupId.startsWith('evt:')) ...[
        const Icon(Icons.military_tech_rounded, color: cOrange, size: 15),
        const SizedBox(width: 6),
      ],
      Expanded(child: Text(_activeSession!.meetupName.isNotEmpty ? _activeSession!.meetupName : AppLocalizations.of(context).statusMeetupActive, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      const SizedBox(width: 8), Text(_sessionTimeLeft, style: TextStyle(color: cTextTertiary, fontSize: 11, fontFamily: fontMono)), const SizedBox(width: 8), Icon(Icons.arrow_forward_ios_rounded, color: Colors.green.withValues(alpha: 0.4), size: 14)]))));

  Widget _buildDeviceWarning() => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(kTileRadius), border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5)),
    child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18), const SizedBox(width: 10), Expanded(child: Text(DeviceIntegrityService.warningMessage, style: TextStyle(color: Colors.orange.shade200, fontSize: 11))),
      GestureDetector(onTap: () => setState(() => _dismissedIntegrityWarning = true), child: Icon(Icons.close_rounded, color: Colors.orange.shade300, size: 16))]));



  void _showSettings() async {
    // Guide VOR dem Sheet holen: Danach zeigt der Context auf eine andere
    // Route.
    final guide = context.read<GuideService>();

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
                        style: const TextStyle(color: cTextSecondary, fontSize: 13)),
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
                      KeyedSubtree(
                        key: SettingsTour.profileKey,
                        child: _sRow(Icons.person_rounded, cOrange,
                          AppLocalizations.of(context).settingsProfile,
                          AppLocalizations.of(context).settingsProfileSub,
                          () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileEditScreen())); }),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    // DATEN & SICHERHEIT
                    _sGroup(AppLocalizations.of(context).settingsSecData, [
                      KeyedSubtree(
                        key: SettingsTour.backupKey,
                        child: _sRow(Icons.cloud_upload_rounded, cCyan,
                          AppLocalizations.of(context).settingsBackup,
                          AppLocalizations.of(context).settingsBackupSub,
                          () async { Navigator.pop(ctx); await BackupService.createBackup(context); }),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    // NETZWERK
                    _sGroup(AppLocalizations.of(context).settingsSecNetwork, [
                      KeyedSubtree(
                        key: SettingsTour.relaysKey,
                        child: _sRow(Icons.hub_rounded, cPurple,
                          AppLocalizations.of(context).settingsRelays,
                          AppLocalizations.of(context).settingsRelaysSub,
                          () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const RelaySettingsScreen())); }),
                      ),
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
                      KeyedSubtree(
                        key: SettingsTour.languageKey,
                        child: ValueListenableBuilder<Locale?>(
                        valueListenable: LocaleController.locale,
                        builder: (_, current, _) => _sRowCustom(
                          Icons.language_rounded, cGreen,
                          AppLocalizations.of(context).settingsLanguageTitle,
                          '${_flagFor(current)}  ${LocaleController.displayName(current)}',
                          trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
                          onTap: () => _showLanguagePopup(ctx),
                        ),
                      ),
                      ),
                      _sDivider(),
                      // Währung (Issue #66) — gilt für Umrechner, Kacheln,
                      // Dashboard und Widget.
                      ValueListenableBuilder<String>(
                        valueListenable: CurrencyService.current,
                        builder: (_, cur, _) => _sRowCustom(
                          Icons.currency_exchange_rounded, cGreen,
                          AppLocalizations.of(context).settingsCurrencyTitle,
                          '$cur · ${_currencyName(cur)}',
                          trailing: const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
                          onTap: () => _showCurrencyPopup(),
                        ),
                      ),
                      _sDivider(),
                      // Haptik
                      KeyedSubtree(
                        key: SettingsTour.hapticKey,
                        child: _sRowCustom(
                        Icons.vibration_rounded, cGreen,
                        AppLocalizations.of(context).settingsHaptic,
                        haptic ? AppLocalizations.of(context).settingsHapticOn : AppLocalizations.of(context).settingsHapticOff,
                        trailing: Switch(value: haptic, activeThumbColor: cOrange,
                          onChanged: (v) async { await prefs.setBool('haptic_enabled', v); ss(() => haptic = v); }),
                      ),
                      ),
                      _sDivider(),
                      // Diagnose-Log
                      _sRow(Icons.bug_report_rounded, cCyan,
                        AppLocalizations.of(context).settingsLogTitle,
                        AppLocalizations.of(context).settingsLogSub,
                        () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const LogScreen())); }),
                      _sDivider(),
                      // Tour wiederholen — der einzige Weg, die Spotlights
                      // ein zweites Mal zu sehen. Ohne ihn liesse sich der
                      // Guide nur durch Zuruecksetzen der App testen.
                      KeyedSubtree(
                        key: SettingsTour.restartKey,
                        child: _sRow(Icons.replay_rounded, cOrange,
                          AppLocalizations.of(context).settingsRestartGuide,
                          AppLocalizations.of(context).settingsRestartGuideSub,
                          () async {
                            // Text und Messenger vor dem await greifen — nach
                            // Navigator.pop ist der Sheet-Context weg.
                            final messenger = ScaffoldMessenger.of(context);
                            final msg = AppLocalizations.of(context).settingsGuideReset;
                            Navigator.pop(ctx);
                            await guide.resetAllTours();
                            messenger.showSnackBar(SnackBar(
                                content: Text(msg), backgroundColor: cOrange));
                          }),
                      ),
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
                      KeyedSubtree(
                        key: SettingsTour.resetKey,
                        child: _sRow(Icons.delete_forever_rounded, cRed,
                          AppLocalizations.of(context).settingsReset,
                          AppLocalizations.of(context).settingsResetSub,
                          () { Navigator.pop(ctx); _resetApp(); }, danger: true),
                      ),
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
    ).whenComplete(() {
      // Sheet zu, Tour raus. Sonst suchte das Overlay Ziele, die es nicht
      // mehr gibt, und arbeitete die Restschritte unsichtbar ab.
      if (guide.activeTour == GuideTour.settings) guide.finishTour();
    });

    // Erst starten, wenn das Sheet oben steht — vorher sind die Ziele noch
    // nicht im Baum.
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      guide.startTour(GuideTour.settings, SettingsTour.steps());
    });
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
          ?trailing,
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
        builder: (_, current, _) => Dialog(
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

  /// Ausgeschriebener Name einer Währung.
  String _currencyName(String code) {
    final t = AppLocalizations.of(context);
    switch (code) {
      case 'EUR': return t.curEUR;
      case 'USD': return t.curUSD;
      case 'CHF': return t.curCHF;
      case 'GBP': return t.curGBP;
      case 'CAD': return t.curCAD;
      case 'AUD': return t.curAUD;
      case 'JPY': return t.curJPY;
      default: return code;
    }
  }

  /// Auswahl der Anzeigewährung — wie die Sprachauswahl aufgebaut.
  void _showCurrencyPopup() {
    showDialog(
      context: context,
      builder: (dialogCtx) => ValueListenableBuilder<String>(
        valueListenable: CurrencyService.current,
        builder: (_, current, _) => Dialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogCtx).size.height * 0.8),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(children: [
                    const Icon(Icons.currency_exchange_rounded, color: cOrange, size: 20),
                    const SizedBox(width: 10),
                    Text(AppLocalizations.of(context).convSelectCurrency, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Text(AppLocalizations.of(context).settingsCurrencyHint,
                      style: const TextStyle(color: cTextSecondary, fontSize: 12, height: 1.4)),
                ),
                const Divider(color: cBorder, height: 1),
                for (final code in CurrencyService.supported)
                  _currencyOption(code, current, dialogCtx),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currencyOption(String code, String current, BuildContext dialogCtx) {
    final selected = code == current;
    return InkWell(
      onTap: () async {
        await CurrencyService.set(code);
        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: selected ? cOrange.withValues(alpha: 0.08) : Colors.transparent,
        child: Row(children: [
          SizedBox(
            width: 44,
            child: Text(CurrencyService.symbol(code),
                style: TextStyle(color: selected ? cOrange : cTextSecondary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$code · ${_currencyName(code)}', style: TextStyle(
            color: selected ? cOrange : cText,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
          if (selected) const Icon(Icons.check_circle_rounded, color: cOrange, size: 20),
        ]),
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
      default: return Icons.widgets_rounded;
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
                // onReorderItem statt onReorder: Der neue Rueckruf rechnet den
                // newIndex bereits um das entnommene Element zurueck. Die
                // frueher noetige Korrektur "if (newI > oldI) newI--;" faellt
                // deshalb ersatzlos weg — bliebe sie stehen, saesse jede
                // Kachel nach dem Verschieben eine Position zu weit oben.
                onReorderItem: (oldI, newI) {
                  setState(() {
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
              activeThumbColor: cOrange,
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
        activeThumbColor: cOrange,
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
                    const Text('Bitcoin', style: TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Netzwerk & Kurs', style: TextStyle(color: cTextSecondary, fontSize: 13)),
                  // Kurs in der gewählten Währung (Issue #66). Lauscht auf
                  // die Einstellung, damit ein Wechsel sofort sichtbar ist.
                  if (d != null)
                    ValueListenableBuilder<String>(
                      valueListenable: CurrencyService.current,
                      builder: (_, cur, _) {
                        final p = d.priceIn(cur);
                        if (p <= 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(CurrencyService.formatPrice(p, cur),
                              style: const TextStyle(color: cTextSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
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
                      color: (d != null && !d.isDead)
                          ? cGreen.withValues(alpha: 0.7)
                          : cTextTertiary,
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

/// Eine Favoriten-Karte.
///
/// [key] ist der GESPEICHERTE Wert — seit dem Umbau die Portal-ID, bei
/// Altbestand noch ein Stadtname. [city] ist der daraus aufgeloeste Ort
/// fuer Terminsuche und Wappen, [label] die Aufschrift: bei mehreren
/// Meetups in einer Stadt der Gruppenname, sonst die Stadt.
/// Ein Meetup-Termin, fuer den man zugesagt hat.
class _MeetupDateEntry {
  final String favKey;
  final String label;
  final CalendarEvent event;

  /// Teilnehmerzahl laut Portal, -1 wenn unbekannt.
  final int attendees;

  const _MeetupDateEntry({
    required this.favKey,
    required this.label,
    required this.event,
    required this.attendees,
  });
}

class _FavCard {
  final String key;
  final String label;
  final String city;
  final CalendarEvent? event;
  const _FavCard({
    required this.key,
    required this.label,
    required this.city,
    required this.event,
  });
}

/// Gestrichelter Platzhalter an der Stelle, von der eine Kachel gerade
/// weggezogen wird.
class DottedPlaceholder extends StatelessWidget {
  const DottedPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cOrange.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cOrange.withValues(alpha: 0.45), width: 1),
        ),
      );
}
