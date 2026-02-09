import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/intro.dart'; 
import 'screens/dashboard.dart';
import 'screens/verification_gate.dart';
import 'models/user.dart';

void main() {
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
      // HIER IST DER TRICK FÜR DIE HANDY-ANSICHT:
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420), // Maximale Breite wie ein großes Handy
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade900, width: 1)),
            ),
            child: child,
          ),
        );
      },
      home: const SplashScreen(), // Prüft Session beim Start
    );
  }
}

// Splash Screen der die Session prüft
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // User-Daten laden
    final user = await UserProfile.load();
    
    print("[DEBUG Session] User: ${user.nickname}, Verifiziert: ${user.isAdminVerified}");
    
    await Future.delayed(const Duration(milliseconds: 500)); // Kurze Verzögerung für UX
    
    if (!mounted) return;
    
    // Session-Check
    Widget nextScreen;
    
    if (user.nickname == "Anon" || user.nickname.isEmpty) {
      // Neuer User → Intro
      nextScreen = const IntroScreen();
      print("[DEBUG Session] → Intro (Neuer User)");
    } else if (user.isAdminVerified) {
      // Verifizierter User → Dashboard
      nextScreen = DashboardScreen();
      print("[DEBUG Session] → Dashboard (Verifiziert)");
    } else {
      // User existiert, aber nicht verifiziert → Verification Gate
      nextScreen = VerificationGateScreen();
      print("[DEBUG Session] → Verification Gate (Nicht verifiziert)");
    }
    
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextScreen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) => 
          FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Minimalistischer Splash Screen
    return Scaffold(
      backgroundColor: cDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bolt,
              size: 80,
              color: cOrange,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: cOrange,
            ),
          ],
        ),
      ),
    );
  }
}