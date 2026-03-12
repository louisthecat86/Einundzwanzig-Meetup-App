import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Hintergründe ──────────────────────────────────
const Color cDark    = Color(0xFF0E0E10);
const Color cCard    = Color(0xFF18181C);
const Color cCardHover = Color(0xFF222228);
const Color cSurface = Color(0xFF141418);

// ── Bitcoin / Einundzwanzig Brand ─────────────────
const Color cOrange      = Color(0xFFF7931A); // Bitcoin Orange – primär
const Color cOrangeLight = Color(0xFFFFB347);
const Color cOrangeDim   = Color(0xFF7A4A0E);

// ── Warm Gold – Sekundärfarbe (ersetzt Cyan-Blau) ──
const Color cCyan    = Color(0xFFD4A017); // Warm Gold (vorher: Cyan-Blau)
const Color cCyanDim = Color(0xFF6B4E00);

// ── Nostr Lila ────────────────────────────────────
const Color cPurple  = Color(0xFF9B45E8); // Nostr-nah + Podcast
const Color cNostr   = Color(0xFF8B5CF6); // Dedizierter Nostr-Button

// ── Text ──────────────────────────────────────────
const Color cText          = Color(0xFFF5F5F7);
const Color cTextSecondary = Color(0xFF9A9AA0);
const Color cTextTertiary  = Color(0xFF5C5C64);

// ── Rahmen & Glas ─────────────────────────────────
const Color cBorder      = Color(0xFF2A2A32);
const Color cTileBorder  = Color(0xFF30303A);
const Color cGlass       = Color(0x14FFFFFF);
const Color cGlassBorder = Color(0x20FFFFFF);
const Color cGlassHeavy  = Color(0x28FFFFFF);

// ── Status ────────────────────────────────────────
const Color cGreen = Color(0xFF22C55E);
const Color cRed   = Color(0xFFE04040); // Sauberes Rot, kein Rosa mehr

// ── Verläufe ──────────────────────────────────────
const LinearGradient gradientOrange = LinearGradient(
  colors: [Color(0xFFF7931A), Color(0xFFFF6B00)],
  begin: Alignment.topLeft, end: Alignment.bottomRight);

const LinearGradient gradientGold = LinearGradient(
  colors: [Color(0xFFD4A017), Color(0xFFA07800)],
  begin: Alignment.topLeft, end: Alignment.bottomRight);

const LinearGradient gradientCyan = gradientGold; // Alias für Rückwärtskompatibilität

const LinearGradient gradientPurple = LinearGradient(
  colors: [Color(0xFF9B45E8), Color(0xFF6D00CC)],
  begin: Alignment.topLeft, end: Alignment.bottomRight);

// ── Fonts ─────────────────────────────────────────
String? _rajdhani = GoogleFonts.rajdhani().fontFamily;
String? _mono     = GoogleFonts.inconsolata().fontFamily;
String? get fontMono => _mono;

// ── Tile-Konstanten ───────────────────────────────
const double kTileGap    = 12;
const double kTileRadius = 14;

// ── App Theme ────────────────────────────────────
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: cDark,
  primaryColor: cOrange,
  useMaterial3: true,
  fontFamily: _rajdhani,
  colorScheme: const ColorScheme.dark(
    primary: cOrange, secondary: cCyan, surface: cCard, error: cRed),
  textTheme: TextTheme(
    displayLarge:  TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.5, color: cText, height: 1.15),
    displayMedium: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 26, letterSpacing: -0.3, color: cText, height: 1.2),
    titleLarge:    TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 20, color: cText),
    titleMedium:   TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w600, fontSize: 16, color: cText),
    bodyLarge:     TextStyle(fontFamily: _rajdhani, fontSize: 16, color: cText, height: 1.5),
    bodyMedium:    TextStyle(fontFamily: _rajdhani, fontSize: 14, color: cTextSecondary, height: 1.5),
    bodySmall:     TextStyle(fontFamily: _rajdhani, fontSize: 12, color: cTextTertiary, height: 1.4),
    labelSmall:    TextStyle(fontFamily: _rajdhani, fontSize: 11, color: cTextSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.2),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent,
    elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontFamily: _rajdhani, color: cText, fontSize: 22, fontWeight: FontWeight.w700),
    iconTheme: const IconThemeData(color: cTextSecondary, size: 22)),
  cardTheme: CardThemeData(
    color: cCard, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius), side: const BorderSide(color: cTileBorder, width: 0.8))),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
    backgroundColor: cOrange, foregroundColor: Colors.black, elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
    textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 15, fontWeight: FontWeight.w700))),
  outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
    foregroundColor: cText, side: const BorderSide(color: cTileBorder, width: 1),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)))),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
    foregroundColor: cOrange,
    textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 14, fontWeight: FontWeight.w600))),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: cSurface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.8)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cTileBorder, width: 0.8)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kTileRadius), borderSide: const BorderSide(color: cOrange, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16)),
  dividerTheme: const DividerThemeData(color: cBorder, thickness: 0.5, space: 32),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: cCard, selectedItemColor: cOrange, unselectedItemColor: cTextTertiary,
    type: BottomNavigationBarType.fixed, elevation: 0),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: cCard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius)),
    behavior: SnackBarBehavior.floating, elevation: 0),
  dialogTheme: DialogThemeData(
    backgroundColor: cCard, surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kTileRadius + 4))),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: cCard, surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
);
