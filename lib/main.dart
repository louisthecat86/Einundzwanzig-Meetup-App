import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'screens/intro.dart';
import 'screens/app_shell.dart';
import 'models/user.dart';
import 'services/secure_key_store.dart';
import 'services/promotion_claim_service.dart';
import 'services/locale_controller.dart';
import 'services/widget_service.dart';
import 'services/app_logger.dart';
import 'services/diagnostics_service.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init(); // persistente Diagnose-Logs laden
  // Umgebungs-Steckbrief ins Log — ohne diese Angaben ist ein Bugreport
  // kaum auswertbar (siehe Feldtest: Geraeteunterschiede blieben lange
  // unerkannt). Laeuft im Hintergrund, blockiert den Start nicht.
  DiagnosticsService.logEnvironment();

  // Hintergrund-Callback fürs Widget-Aktualisieren registrieren
  // (nur Android — home_widget braucht auf iOS eine App-Group-ID, die wir
  // nicht setzen, da es dort keine Widget-Extension gibt)
  if (Platform.isAndroid) {
    HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  }

  // Gespeicherte Sprache laden, bevor die App startet
  await LocaleController.load();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.locale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Einundzwanzig Meetup',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          locale: locale, // null = Systemsprache
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            return Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  border: Border.symmetric(
                    vertical: BorderSide(color: cBorder, width: 0.5),
                  ),
                ),
                child: child,
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
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
    if (user.nickname == "Anon" || user.nickname.isEmpty) {
      nextScreen = const IntroScreen();
    } else {
      // NEU: Statt DashboardScreen → AppShell (mit BottomNav)
      nextScreen = const AppShell();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, animation, __, child) =>
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


