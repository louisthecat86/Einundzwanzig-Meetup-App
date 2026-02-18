import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/intro.dart'; 
import 'screens/dashboard.dart';
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
      builder: (context, child) {
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: Colors.grey.shade900, width: 1)),
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

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final user = await UserProfile.load();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    // VEREINFACHT: Entweder Intro (neuer User) oder direkt Dashboard
    // Kein VerificationGate mehr im Hauptfluss!
    // Admin-Status kommt automatisch über Trust Score.
    Widget nextScreen;
    if (user.nickname == "Anon" || user.nickname.isEmpty) {
      nextScreen = const IntroScreen();
    } else {
      nextScreen = const DashboardScreen();
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
    return Scaffold(
      backgroundColor: cDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 80, color: cOrange),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: cOrange),
          ],
        ),
      ),
    );
  }
}