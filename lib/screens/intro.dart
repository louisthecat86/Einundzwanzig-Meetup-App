import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme.dart';
import 'profile_edit.dart';
import 'app_shell.dart';  // NEU: Statt dashboard.dart
import '../services/nostr_service.dart';
import '../services/backup_service.dart';
import '../services/app_logger.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  bool _showLogo = false;
  bool _showSlogan = false;
  bool _showButton = false;
  bool _isLoading = false;

  // NEU: Sanftere Animation über Controller
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _startAnimation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startAnimation() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showLogo = true);

    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _showSlogan = true);

    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showButton = true);
  }

  // --- BACKUP LOGIK (1:1 aus original) ---
  void _restoreAccount() async {
    bool success = await BackupService.restoreBackup(context);
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const AppShell(),  // NEU
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _enterCommunity() async {
    setState(() => _isLoading = true);
    UserProfile user = await UserProfile.load();
    if (!mounted) return;

    if (user.nickname == "Anon" && !user.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bitte lege zuerst deine Identität fest."),
          backgroundColor: cOrange,
          duration: Duration(seconds: 3),
        ),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
      );
      user = await UserProfile.load();
      if (!mounted) return;
      if (user.nickname == "Anon" || user.nickname.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (!mounted) return;

    if (!user.hasNostrKey) {
      try {
        final keys = await NostrService.generateKeyPair();
        if (keys['npub'] != null) {
          user.nostrNpub = keys['npub']!;
          user.hasNostrKey = true;
          user.isNostrVerified = true;
          await user.save();
          AppLogger.debug('Intro', 'Nostr-Key erstellt: ${NostrService.shortenNpub(keys['npub']!)}');
        }
      } catch (e) {
        AppLogger.debug('Intro', 'Nostr-Key-Erstellung fehlgeschlagen: $e');
      }
    }

    if (!mounted) return;

    // NEU: Route zu AppShell statt DashboardScreen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AppShell(),
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
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.0,
                  colors: [
                    cOrange.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutExpo,
                  opacity: _showLogo ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutExpo,
                    offset: _showLogo ? Offset.zero : const Offset(0, 0.3),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 260,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // SLOGAN
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _showSlogan ? 1.0 : 0.0,
                  child: Column(
                    children: [
                      Text(
                        "DEINE BITCOIN COMMUNITY",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 3.5,
                          color: cTextSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: gradientOrange,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // BUTTONS
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: _showButton ? 1.0 : 0.0,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 500),
                    offset: _showButton ? Offset.zero : const Offset(0, 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Hauptbutton mit Gradient
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _isLoading ? null : gradientOrange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: _isLoading ? [] : [
                                  BoxShadow(
                                    color: cOrange.withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _enterCommunity,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Text(
                                        "COMMUNITY BETRETEN",
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _restoreAccount,
                            icon: Icon(Icons.restore_rounded,
                                color: cOrange.withOpacity(0.7), size: 18),
                            label: Text(
                              "BACKUP LADEN",
                              style: TextStyle(
                                color: cOrange.withOpacity(0.7),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}