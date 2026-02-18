import 'package:flutter/material.dart';
import '../models/user.dart'; 
import '../theme.dart'; 
import 'profile_edit.dart'; 
import 'dashboard.dart'; 
import '../services/nostr_service.dart';
import '../services/backup_service.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  bool _showLogo = false;
  bool _showSlogan = false;
  bool _showButton = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showLogo = true);

    await Future.delayed(const Duration(milliseconds: 800));
    setState(() => _showSlogan = true);

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _showButton = true);
  }

  // --- BACKUP LOGIK ---
  void _restoreAccount() async {
    bool success = await BackupService.restoreBackup(context);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(), 
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _enterCommunity() async {
    setState(() => _isLoading = true);

    UserProfile user = await UserProfile.load();

    if (!mounted) return;

    // Profil noch leer? → Erst Profil bearbeiten
    if (user.nickname == "Anon" && !user.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte lege zuerst deine Identität fest. 🕵️"),
          backgroundColor: cOrange,
          duration: Duration(seconds: 3),
        )
      );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
      );

      user = await UserProfile.load();
    }

    if (!mounted) return;

    // =============================================
    // NOSTR KEY: Automatisch im Hintergrund erstellen
    // Der User bekommt davon nichts mit.
    // =============================================
    if (!user.hasNostrKey) {
      try {
        final keys = await NostrService.generateKeyPair();
        if (keys['npub'] != null) {
          user.nostrNpub = keys['npub']!;
          user.hasNostrKey = true;
          user.isNostrVerified = true;
          await user.save();
          print('[Intro] Nostr-Key automatisch erstellt: ${NostrService.shortenNpub(keys['npub']!)}');
        }
      } catch (e) {
        print('[Intro] Nostr-Key-Erstellung fehlgeschlagen: $e');
        // Kein Problem — App funktioniert auch ohne
      }
    }

    if (!mounted) return;

    // =============================================
    // DIREKT ZUM DASHBOARD
    // Kein VerificationGate mehr!
    // Admin-Status kommt automatisch über Trust Score.
    // =============================================
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(), 
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
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
            // LOGO
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutExpo,
              opacity: _showLogo ? 1.0 : 0.0,
              child: Transform.translate(
                offset: _showLogo ? const Offset(0, 0) : const Offset(0, 50),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 50),

            // SLOGAN
            AnimatedOpacity(
              duration: const Duration(milliseconds: 800),
              opacity: _showSlogan ? 1.0 : 0.0,
              child: Column(
                children: [
                  Text(
                    "DEINE BITCOIN COMMUNITY",
                    style: TextStyle(
                      fontSize: 13, 
                      letterSpacing: 3.0, 
                      color: cTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Icon(Icons.keyboard_arrow_down, color: cOrange, size: 28),
                ],
              ),
            ),

            const SizedBox(height: 60),

            // BUTTONS
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _showButton ? 1.0 : 0.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _enterCommunity,
                        child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text("COMMUNITY BETRETEN"),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      onPressed: _isLoading ? null : _restoreAccount,
                      icon: const Icon(Icons.restore, color: Colors.orange, size: 20),
                      label: const Text(
                        "BACKUP LADEN",
                        style: TextStyle(
                          color: Colors.orange, 
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}