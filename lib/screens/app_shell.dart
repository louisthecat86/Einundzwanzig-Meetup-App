import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'badge_wallet.dart';
import 'calendar_screen.dart';
import 'profile_edit.dart';
import 'meetup_verification.dart';
import '../models/meetup.dart';

/// Haupt-Shell der App mit persistenter Bottom Navigation.
/// 
/// Die gesamte Navigation läuft über diese Shell.
/// Tabs: Home | Wallet | [Scan] | Events | Profil
/// 
/// LOGIK: Komplett beibehalten — nur visuell umstrukturiert.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _fabController;
  late final Animation<double> _fabPulse;

  // Keys für die Tabs, damit sie ihren State behalten
  final _homeKey = GlobalKey<HomeScreenState>();
  
  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _fabPulse = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    // Index 2 ist der Scan-Button (kein Tab)
    if (index == 2) {
      _openScanner();
      return;
    }
    
    HapticFeedback.selectionClick();
    setState(() {
      // Mapping: 0,1 bleiben gleich, 3→2 (Events), 4→3 (Profil)
      _currentIndex = index;
    });
  }

  void _openScanner() async {
    HapticFeedback.mediumImpact();
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MeetupVerificationScreen(meetup: dummy),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
    // Nach dem Scan: Home-Tab refreshen
    _homeKey.currentState?.refreshAfterScan();
  }

  Widget _buildBody() {
    // IndexedStack hält alle Tabs am Leben
    return IndexedStack(
      index: _currentIndex > 2 ? _currentIndex - 1 : _currentIndex,
      children: [
        HomeScreen(key: _homeKey),
        BadgeWalletScreen(),
        const CalendarScreen(),
        const ProfileEditScreen(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      extendBody: true,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        // Frosted-Glass-Effekt
        border: Border(
          top: BorderSide(color: cGlassBorder, width: 0.5),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            color: cDark.withOpacity(0.85),
            child: SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                    _buildNavItem(1, Icons.wallet_rounded, Icons.wallet_outlined, 'Wallet'),
                    _buildScanButton(),
                    _buildNavItem(3, Icons.event_rounded, Icons.event_outlined, 'Events'),
                    _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTap(index),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aktiv-Indikator
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isActive ? 24 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: cOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Icon mit Animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                key: ValueKey(isActive),
                color: isActive ? cOrange : cTextTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? cOrange : cTextTertiary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: _openScanner,
      child: AnimatedBuilder(
        animation: _fabPulse,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabPulse.value,
            child: child,
          );
        },
        child: Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            gradient: gradientOrange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cOrange.withOpacity(0.3),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.qr_code_scanner_rounded,
            color: Colors.black,
            size: 24,
          ),
        ),
      ),
    );
  }
}