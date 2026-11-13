import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/guide_service.dart';
import 'services/safe_url_launcher.dart';
import 'widgets/guide_overlay.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'screens/intro.dart';
import 'screens/app_shell.dart';
import 'models/user.dart';
import 'services/secure_key_store.dart';
import 'services/locale_controller.dart';
import 'services/currency_service.dart';
import 'services/widget_service.dart';
import 'services/app_logger.dart';
import 'models/badge.dart';
import 'services/badge_sync_service.dart';
import 'services/diagnostics_service.dart';
import 'services/legacy_secure_storage.dart';
import 'services/signing_service.dart';

/// Messenger der App-Wurzel. Gebraucht, um Meldungen aus Code OHNE
/// BuildContext zu zeigen — etwa die Freigabe-Aufforderung eines
/// Remote-Signers, die mitten in einer beliebigen Signatur eintreffen kann.
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Nimmt `auth_url` des Remote-Signers ueberall in der App an.
///
/// Vorher war der Empfaenger nur gesetzt, solange das Verbindungs-Blatt offen
/// stand. Verlangt der Signer die Freigabe SPAETER — bei einer Signatur mitten
/// im Betrieb —, ging die Aufforderung verloren und der Nutzer sah nur eine
/// Zeitueberschreitung, ohne Chance zu erfahren, was fehlt.
///
/// Gezeigt wird ein Balken mit KNOPF statt eines automatisch geoeffneten
/// Fensters: im Web blockiert der Browser das Oeffnen ohne Nutzer-Gestik. Ein
/// Tipp auf den Knopf ist eine.
/// Host einer URL ohne Token/Query — für Logs, in denen die volle
/// auth_url nicht landen darf (Security Audit N5).
String _hostOf(String url) {
  try {
    final host = Uri.parse(url).host;
    return host.isEmpty ? 'unbekannt' : host;
  } catch (_) {
    return 'unbekannt';
  }
}

void _installNip46AuthUrlHandler() {
  SigningService.onNip46AuthUrl = (url) {
    final messenger = rootMessengerKey.currentState;
    final context = rootMessengerKey.currentContext;
    if (messenger == null || context == null) {
      // Security Audit N5: Die auth_url NICHT vollständig loggen — sie
      // enthält ein Freigabe-Token und das Log wird geteilt. Nur der Host
      // ist für die Diagnose relevant.
      AppLogger.warn('Nip46',
          'Freigabe-Aufforderung des Signers kam an, aber die App war noch '
          'nicht bereit sie zu zeigen (Host: ${_hostOf(url)}).');
      return;
    }
    final t = AppLocalizations.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(t.bunkerAuthNeeded),
      backgroundColor: Colors.orange,
      // Lange sichtbar: der Nutzer muss in einer anderen App bestaetigen, und
      // die Signatur wartet ohnehin bis zu 60 Sekunden auf ihn.
      duration: const Duration(seconds: 60),
      showCloseIcon: true,
      action: SnackBarAction(
        label: t.bunkerAuthAction,
        textColor: Colors.black,
        onPressed: () {
          // Security Audit M2 (Review-Fund): Die auth_url kommt vom REMOTEN
          // Signer — sie darf nicht ungeprüft als Intent rausgehen. Nur
          // http(s) öffnen; NIP-46-Freigabeseiten sind Web-URLs.
          // Security Audit N5: launchHttpUrl wirft nie und liefert nur
          // true/false — es gibt kein Fehlerobjekt, das die volle auth_url
          // samt Token in den Log tragen könnte. Geloggt wird nur der Host.
          launchHttpUrl(url).then((opened) {
            if (!opened) {
              AppLogger.warn('Nip46',
                  'Freigabe-Seite nicht geöffnet (Schema nicht http(s) oder '
                  'kein Browser), Host: ${_hostOf(url)}');
            }
          });
        },
      ),
    ));
  };
}

/// Wird vom Aktualisieren-Rädchen des Homescreen-Widgets ausgelöst:
/// läuft im HINTERGRUND (ohne die App zu öffnen), holt frische Daten
/// und schreibt sie ins Widget.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'refresh') {
    await WidgetService.refreshBitcoin();
    await WidgetService.refreshNews();
  }
}

/// Haengt den Logger an die beiden Stellen, an denen Flutter Fehler
/// abliefert, die NIEMAND gefangen hat.
///
/// Ohne das landeten genau die wertvollsten Fehler nirgends: ein Absturz
/// ging in die Debug-Konsole (im Release also ins Leere) und tauchte im
/// persistenten Diagnose-Log nie auf — dem einzigen, das ein Tester
/// ueberhaupt schicken kann. Berichte blieben deshalb bei "die App macht
/// nichts mehr" stehen.
///
/// Beide Handler sind selbst gegen Fehler abgesichert: wirft der Handler,
/// meldet Flutter das wieder an denselben Handler — eine Endlosschleife
/// waehrend eines Absturzes ist das Letzte, was man dann braucht.
void _installErrorHandlers() {
  FlutterError.onError = (details) {
    try {
      AppLogger.error(
        'Flutter',
        details.library ?? 'widget',
        details.exception,
        details.stack,
      );
    } catch (_) {}
    // Standardverhalten erhalten: Rotbild und Konsolenausgabe im Debug.
    FlutterError.presentError(details);
  };

  // Unbehandelte Fehler ausserhalb des Widget-Baums (Futures, Streams,
  // Plattform-Callbacks) auf den nativen Plattformen.
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    try {
      AppLogger.error('Async', 'Unbehandelter Fehler', error, stack);
    } catch (_) {}
    // Release: als behandelt melden, damit die App weiterlaeuft und der
    // Tester das Diagnose-Log noch exportieren kann. Debug/Profile: false,
    // damit der Fehler laut bleibt und kein korrupter Zustand still
    // weiterlaeuft.
    return kReleaseMode;
  };
}

void main() {
  // Die Zone ist im WEB unverzichtbar: dort ruft die Engine
  // PlatformDispatcher.onError nicht auf. Nachweisbar daran, dass dart2js
  // den Handler-Rumpf als toten Code aus dem Release-Bundle entfernt —
  // derselbe Log-Aufruf ueberlebt in main() und im
  // FlutterError.onError-Closure, im platformDispatcher-Closure nicht.
  //
  // Beide Wege bleiben stehen: greift die Zone (Fehler innerhalb von
  // _start), meldet PlatformDispatcher.onError nichts mehr — es gibt also
  // keine Doppeleintraege. Fehler aus Callbacks, die AUSSERHALB dieser Zone
  // registriert wurden, erreichen umgekehrt nur PlatformDispatcher.onError.
  runZonedGuarded(_start, (error, stack) {
    try {
      AppLogger.error('Zone', 'Unbehandelter Fehler', error, stack);
    } catch (_) {}
  });
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init(); // persistente Diagnose-Logs laden
  // Flutter-/Platform-Handler erst danach: sie brauchen WidgetsBinding, und
  // init() behaelt inzwischen auch Eintraege, die die Zone schon vorher
  // geschrieben hat (siehe AppLogger.init).
  _installErrorHandlers();
  // Umgebungs-Steckbrief ins Log — ohne diese Angaben ist ein Bugreport
  // kaum auswertbar (siehe Feldtest: Geraeteunterschiede blieben lange
  // unerkannt). Laeuft im Hintergrund, blockiert den Start nicht.
  DiagnosticsService.logEnvironment();

  // Register only the Android home-widget callback. The current iOS target has
  // no widget extension/App Group, and home_widget otherwise throws
  // "AppGroupId not set" during simulator startup.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  // Gespeicherte Sprache laden, bevor die App startet
  await LocaleController.load();
  // Gewählte Anzeigewährung (Issue #66) — vor dem ersten Bild, sonst
  // blitzte auf der Startseite kurz € auf.
  await CurrencyService.load();

  // Zuerst die Badge-Datei lesen, bevor irgendetwas sonst den sicheren
  // Speicher anfasst. Der Umzug von flutter_secure_storage darf nicht aus
  // mehreren Objekten parallel starten, und ein fehlendes Lesen darf keinen
  // neuen Schlüssel über den alten schreiben.
  // Davor: Werte aus dem alten Android-Speicher (bis 1.6.9) nachholen,
  // sonst fehlt der Badge-Schlüssel beim ersten Lesen.
  await LegacySecureStorage.recover();
  await MeetupBadge.loadBadges();

  // Badge-Sync an saveBadges hängen und einmal fern lesen. Läuft im
  // Hintergrund; kann der Signer kein NIP-44, bleibt es aus.
  BadgeSyncService.init();
  BadgeSyncService.retryIfDirty();

  // Immersiver Vollbild-Modus: blendet die Android-Navigationsleiste aus.
  // Ab Android 15/16 erzwingt das System Edge-to-Edge und ignoriert
  // systemNavigationBarColor — daher hier immersiveSticky, damit die
  // Leiste verschwindet und nur bei einem Wisch vom Rand kurz erscheint.
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [SystemUiOverlay.top], // Statusleiste oben bleibt sichtbar
  );

  // Status Bar transparent für besseren Gradient-Look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  _installNip46AuthUrlHandler();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GuideService liegt UEBER der MaterialApp: Die Spotlight-Tour muss
    // ueber jeder Route liegen koennen, auch ueber Dialogen und Sheets.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GuideService()),
      ],
      child: ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Einundzwanzig Meetup',
          debugShowCheckedModeBanner: false,
          // Erlaubt Meldungen aus Code ohne BuildContext — siehe
          // _installNip46AuthUrlHandler.
          scaffoldMessengerKey: rootMessengerKey,
          theme: appTheme,
          locale: locale, // null = Systemsprache
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            // Handys nutzen die volle Breite. Die feste 420-dp-Spalte liess
            // auf grossen Handys (Pixel 9 Pro XL: 448 dp) links und rechts
            // schwarze Raender. Zentriert wird nur noch auf Tablet, Desktop
            // und Web — dieselbe 600-dp-Grenze der kleinsten Seite, an der
            // MainActivity das Hochformat freigibt. Die kleinste Seite
            // aendert sich beim Drehen nicht, und der Baum bleibt in beiden
            // Faellen gleich, damit der Navigator-Zustand erhalten bleibt.
            final wide = MediaQuery.sizeOf(context).shortestSide >= 600;
            return GuideOverlay(
              child: Center(
                child: Container(
                  constraints:
                      BoxConstraints(maxWidth: wide ? 420 : double.infinity),
                  decoration: BoxDecoration(
                    border: wide
                        ? Border.symmetric(
                            vertical: BorderSide(color: cBorder, width: 0.5),
                          )
                        : null,
                  ),
                  child: child,
                ),
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await SecureKeyStore.ensureMigrated();
    final user = await UserProfile.load();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Widget nextScreen;
    if (!user.isOnboarded) {
      nextScreen = const IntroScreen();
    } else {
      // NEU: Statt DashboardScreen → AppShell (mit BottomNav)
      nextScreen = const AppShell();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => nextScreen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo mit Glow-Effekt
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cOrange.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, size: 56, color: cOrange),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: cOrange,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

