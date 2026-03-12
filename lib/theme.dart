import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Hintergründe (tiefschwarz) ────────────
const Color cDark    = Color(0xFF0C0C0E);
const Color cCard    = Color(0xFF131315);
const Color cCardHover = Color(0xFF1A1A1D);
const Color cSurface = Color(0xFF0F0F11);

// ── Einzige Akzentfarbe: Bitcoin Orange ───
const Color cOrange      = Color(0xFFF7931A);
const Color cOrangeLight = Color(0xFFFFB347);
const Color cOrangeDim   = Color(0xFF3D2500);

// ── Funktionale Statusfarben (nur für Inhalte, nie für Hintergründe) ──
const Color cCyan   = Color(0xFFD4A017); // Warm Gold – Countdown, Community
const Color cCyanDim = Color(0xFF3D2E00);
const Color cPurple = Color(0xFF9B45E8); // Podcast, Nostr
const Color cNostr  = Color(0xFF8B5CF6);

// ── Text (hoher Kontrast) ─────────────────
const Color cText          = Color(0xFFFFFFFF);
const Color cTextSecondary = Color(0xFF808088);
const Color cTextTertiary  = Color(0xFF3E3E46);

// ── Rahmen (minimal) ─────────────────────
const Color cBorder     = Color(0xFF1C1C22);
const Color cTileBorder = Color(0xFF202028);
const Color cGlass      = Color(0x0EFFFFFF);
const Color cGlassBorder = Color(0x14FFFFFF);
const Color cGlassHeavy = Color(0x1EFFFFFF);

// ── Status ────────────────────────────────
const Color cGreen = Color(0xFF22C55E);
const Color cRed   = Color(0xFFE53935);

// ── Gradient (NUR für primäre CTA-Buttons) ─
const LinearGradient gradientOrange = LinearGradient(
  colors: [Color(0xFFF7931A), Color(0xFFE07810)],
  begin: Alignment.topLeft, end: Alignment.bottomRight);

// Alias-Konstanten für Rückwärtskompatibilität
const LinearGradient gradientCyan   = gradientOrange;
const LinearGradient gradientPurple = gradientOrange;
const LinearGradient gradientGold   = gradientOrange;

// ── Fonts ─────────────────────────────────
String? _rajdhani = GoogleFonts.rajdhani().fontFamily;
String? _mono     = GoogleFonts.inconsolata().fontFamily;
String? get fontMono => _mono;

// ── Tiles ────────────────────────────────
const double kTileGap    = 10;
const double kTileRadius = 10;

// ── Theme ────────────────────────────────
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: cDark,
  primaryColor: cOrange,
  useMaterial3: true,
  fontFamily: _rajdhani,
  colorScheme: const ColorScheme.dark(
    primary: cOrange, secondary: cOrange, surface: cCard, error: cRed),
  textTheme: TextTheme(
    displayLarge:  TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.5, color: cText, height: 1.1),
    displayMedium: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 26, letterSpacing: -0.3, color: cText, height: 1.15),
    titleLarge:    TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 18, color: cText),
    titleMedium:   TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w600, fontSize: 15, color: cText),
    bodyLarge:     TextStyle(fontFamily: _rajdhani, fontSize: 15, color: cText, height: 1.5),
    bodyMedium:    TextStyle(fontFamily: _rajdhani, fontSize: 13, color: cTextSecondary, height: 1.5),
    bodySmall:     TextStyle(fontFamily: _rajdhani, fontSize: 11, color: cTextTertiary, height: 1.4),
    labelSmall:    TextStyle(fontFamily: _rajdhani, fontSize: 10, color: cTextSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.0),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
    elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontFamily: _rajdhani, color: cText, fontSize: 20, fontWeight: FontWeight.w700),
    iconTheme: const IconThemeData(color: cTextSecondary, size: 20)),
  cardTheme: CardThemeData(
    color: cCard, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius), side: const BorderSide(color: cTileBorder, width: 0.5))),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
    backgroundColor: cOrange, foregroundColor: Colors.black, elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
    textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 14, fontWeight: FontWeight.w800))),
  outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
    foregroundColor: cText, side: const BorderSide(color: cTileBorder, width: 0.5),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)))),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
    foregroundColor: cOrange,
    textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 14, fontWeight: FontWeight.w600))),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: cSurface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cOrange, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
  dividerTheme: const DividerThemeData(color: cBorder, thickness: 0.5, space: 28),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: cCard, selectedItemColor: cOrange, unselectedItemColor: cTextTertiary,
    type: BottomNavigationBarType.fixed, elevation: 0),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: cCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
    behavior: SnackBarBehavior.floating, elevation: 0),
  dialogTheme: DialogThemeData(
    backgroundColor: cCard, surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius + 2))),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: cCard, surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
);
