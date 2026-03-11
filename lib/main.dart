import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/intro.dart';
import 'screens/app_shell.dart';
import 'models/user.dart';
import 'services/secure_key_store.dart';
import 'services/promotion_claim_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Status Bar transparent für besseren Gradient-Look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: cDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Einundzwanzig Meetup',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
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
                      color: cOrange.withOpacity(0.2),
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