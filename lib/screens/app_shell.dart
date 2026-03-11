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
import '../models/meetup.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _homeKey = GlobalKey<HomeScreenState>();

  Future<void> _haptic(HapticFeedback Function()? type) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) {
      HapticFeedback.selectionClick();
    }
  }

  void _onTabTap(int index) {
    if (index == 2) { _openScanner(); return; }
    _haptic(null);
    setState(() => _currentIndex = index);
  }

  void _openScanner() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('haptic_enabled') ?? true) HapticFeedback.mediumImpact();
    final d = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(context, PageRouteBuilder(
      pageBuilder: (_, __, ___) => MeetupVerificationScreen(meetup: d),
      transitionsBuilder: (_, a, __, c) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: c)));
    _homeKey.currentState?.refreshAfterScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
        children: [
          HomeScreen(key: _homeKey),
          BadgeWalletScreen(),
          const CalendarScreen(),
          const ProfileEditScreen(),
        ],
      ),
      bottomNavigationBar: _buildNav(context),
    );
  }

  Widget _buildNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder, width: 0.5))),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            color: cDark.withOpacity(0.92),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 56,
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                  _navItem(1, Icons.style_rounded, Icons.style_outlined, 'Wallet'),
                  _scanBtn(),
                  _navItem(3, Icons.event_rounded, Icons.event_outlined, 'Events'),
                  _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
                ]),
              ),
            ),
          ),
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

  // ============================================================
  // SCAN BUTTON — Ragt aus der NavBar heraus
  // ============================================================
  Widget _scanBtn() {
    return GestureDetector(
      onTap: _openScanner,
      child: Transform.translate(
        offset: const Offset(0, -14), // Ragt 14px über die NavBar hinaus
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: gradientOrange,
            shape: BoxShape.circle,
            border: Border.all(color: cDark, width: 3), // Ring in Hintergrundfarbe
            boxShadow: [
              BoxShadow(color: cOrange.withOpacity(0.25), blurRadius: 16, spreadRadius: -2, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 26),
        ),
      ),
    );
  }
}