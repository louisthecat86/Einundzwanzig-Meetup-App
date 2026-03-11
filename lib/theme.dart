import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Einundzwanzig Farb-Palette
const Color cDark = Color(0xFF101012);
const Color cCard = Color(0xFF1A1A1E);
const Color cCardHover = Color(0xFF242428);
const Color cSurface = Color(0xFF16161A);
const Color cOrange = Color(0xFFF7931A);
const Color cOrangeLight = Color(0xFFFFB347);
const Color cOrangeDim = Color(0xFF7A4A0E);
const Color cCyan = Color(0xFF00B4CF);
const Color cCyanDim = Color(0xFF005A68);
const Color cPurple = Color(0xFFA915FF);
const Color cText = Color(0xFFF5F5F7);
const Color cTextSecondary = Color(0xFF9A9AA0);
const Color cTextTertiary = Color(0xFF5C5C64);
const Color cBorder = Color(0xFF2A2A30);
const Color cGlass = Color(0x14FFFFFF);
const Color cGlassBorder = Color(0x20FFFFFF);
const Color cGlassHeavy = Color(0x28FFFFFF);
const Color cGreen = Color(0xFF00C853);
const Color cRed = Color(0xFFCF6679);
const Color cTileBorder = Color(0xFF333338);

const LinearGradient gradientOrange = LinearGradient(colors: [Color(0xFFF7931A), Color(0xFFFF6B00)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const LinearGradient gradientCyan = LinearGradient(colors: [Color(0xFF00B4CF), Color(0xFF0088A0)], begin: Alignment.topLeft, end: Alignment.bottomRight);
const LinearGradient gradientPurple = LinearGradient(colors: [Color(0xFFA915FF), Color(0xFF7B00CC)], begin: Alignment.topLeft, end: Alignment.bottomRight);

// ============================================================
// FONT: Rajdhani — Geometrisch, semi-condensed, nah an "The Bold Font"
// Inconsolata bleibt für monospace Zahlen
// ============================================================
String? _rajdhani = GoogleFonts.rajdhani().fontFamily;
String? _mono = GoogleFonts.inconsolata().fontFamily;

// Exportiert für direkten Zugriff in Widgets
String? get fontMono => _mono;

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: cDark,
  primaryColor: cOrange,
  useMaterial3: true,
  fontFamily: _rajdhani,
  colorScheme: const ColorScheme.dark(primary: cOrange, secondary: cCyan, surface: cCard, error: cRed),

  textTheme: TextTheme(
    displayLarge: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 34, letterSpacing: -0.5, color: cText, height: 1.15),
    displayMedium: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 26, letterSpacing: -0.3, color: cText, height: 1.2),
    titleLarge: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w700, fontSize: 20, color: cText),
    titleMedium: TextStyle(fontFamily: _rajdhani, fontWeight: FontWeight.w600, fontSize: 16, color: cText),
    bodyLarge: TextStyle(fontFamily: _rajdhani, fontSize: 16, color: cText, height: 1.5),
    bodyMedium: TextStyle(fontFamily: _rajdhani, fontSize: 14, color: cTextSecondary, height: 1.5),
    bodySmall: TextStyle(fontFamily: _rajdhani, fontSize: 12, color: cTextTertiary, height: 1.4),
    labelSmall: TextStyle(fontFamily: _rajdhani, fontSize: 11, color: cTextSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.2),
  ),

  appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false,
    titleTextStyle: TextStyle(fontFamily: _rajdhani, color: cText, fontSize: 22, fontWeight: FontWeight.w700), iconTheme: const IconThemeData(color: cTextSecondary, size: 22)),
  cardTheme: CardThemeData(color: cCard, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: cTileBorder, width: 0.8)), margin: const EdgeInsets.symmetric(vertical: 6)),
  elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: cOrange, foregroundColor: Colors.black, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 15, fontWeight: FontWeight.w700))),
  outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: cText, side: const BorderSide(color: cTileBorder, width: 1), padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 15, fontWeight: FontWeight.w600))),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: cOrange, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), textStyle: TextStyle(fontFamily: _rajdhani, fontSize: 14, fontWeight: FontWeight.w600))),
  inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: cSurface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cTileBorder, width: 0.8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cTileBorder, width: 0.8)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: cOrange, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16), hintStyle: const TextStyle(color: cTextTertiary)),
  dividerTheme: const DividerThemeData(color: cBorder, thickness: 0.5, space: 32),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(backgroundColor: cCard, selectedItemColor: cOrange, unselectedItemColor: cTextTertiary, type: BottomNavigationBarType.fixed, elevation: 0, selectedLabelStyle: TextStyle(fontFamily: _rajdhani, fontSize: 11, fontWeight: FontWeight.w600), unselectedLabelStyle: TextStyle(fontFamily: _rajdhani, fontSize: 11)),
  snackBarTheme: SnackBarThemeData(backgroundColor: cCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), behavior: SnackBarBehavior.floating, elevation: 0),
  dialogTheme: DialogThemeData(backgroundColor: cCard, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
  bottomSheetTheme: const BottomSheetThemeData(backgroundColor: cCard, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24)))),
);