import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'badge_wallet.dart';
import 'calendar_screen.dart';
import 'profile_edit.dart';
import 'meetup_verification.dart';
import 'reputation_qr.dart';
import '../models/meetup.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  Future<void> _doHaptic() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) HapticFeedback.selectionClick();
  }

  void _onTabTap(int index) {
    if (index == 2) return;
    _doHaptic();
    setState(() => _currentIndex = index);
  }

  // Öffnet das Scan-Auswahlmenü mit drei Optionen
  void _openScanner() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) HapticFeedback.mediumImpact();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScanSheet(
        onBadge: () async {
          Navigator.pop(ctx);
          final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
          await Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => MeetupVerificationScreen(meetup: d),
            transitionsBuilder: (_, a, __, c) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)));
          _homeKey.currentState?.refreshAfterScan();
        },
        onReputation: () async {
          Navigator.pop(ctx);
          await Navigator.push(context, PageRouteBuilder(
            pageBuilder: (_, __, ___) => const ReputationQRScreen(),
            transitionsBuilder: (_, a, __, c) => SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cDark,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          BadgeWalletScreen(),
          const CalendarScreen(),
          const ProfileEditScreen(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 56 + bottomPad + 16,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0,
              height: 56 + bottomPad,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cDark.withOpacity(0.92),
                      border: const Border(top: BorderSide(color: cBorder, width: 0.5)),
                    ),
                    padding: EdgeInsets.only(bottom: bottomPad),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                        _navItem(1, Icons.style_rounded, Icons.style_outlined, 'Wallet'),
                        const SizedBox(width: 60),
                        _navItem(3, Icons.event_rounded, Icons.event_outlined, 'Events'),
                        _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: bottomPad + 10,
              left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _openScanner,
                  child: Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      gradient: gradientOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: cDark, width: 3),
                      boxShadow: [BoxShadow(color: cOrange.withOpacity(0.3), blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 4))],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData a, IconData ia, String l) {
    final active = _currentIndex == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque, onTap: () => _onTabTap(i),
      child: SizedBox(width: 60, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(active ? a : ia, color: active ? cText : cTextTertiary, size: 24),
        const SizedBox(height: 2),
        Text(l, style: TextStyle(color: active ? cText : cTextTertiary, fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ])));
  }
}

// ═══════════════════════════════════════════════════════
// Scan-Auswahl-Sheet — drei Optionen
// ═══════════════════════════════════════════════════════
class _ScanSheet extends StatelessWidget {
  final VoidCallback onBadge;
  final VoidCallback onReputation;

  const _ScanSheet({required this.onBadge, required this.onReputation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 24),
      decoration: const BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(width: 40, height: 4, decoration: BoxDecoration(color: cTextTertiary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),

        // Option 1: Badge / Meetup QR
        _ScanOption(
          icon: Icons.qr_code_rounded,
          iconColor: cOrange,
          title: 'Badge scannen',
          subtitle: 'QR-Code oder NFC-Tag vom Meetup',
          onTap: onBadge,
        ),
        const SizedBox(height: 8),

        // Option 2: Reputation prüfen
        _ScanOption(
          icon: Icons.workspace_premium_rounded,
          iconColor: Colors.amber,
          title: 'Reputation prüfen',
          subtitle: 'Trust Score einer anderen Person verifizieren',
          onTap: onReputation,
        ),

        const SizedBox(height: 16),
      ]),
    );
  }
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOption({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cSurface,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: cText, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: cTextTertiary, size: 18),
        ]),
      ),
    );
  }
}
