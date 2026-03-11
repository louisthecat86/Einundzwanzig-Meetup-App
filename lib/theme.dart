import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================
// Einundzwanzig Farb-Palette (Offiziell: einundzwanzig.space/media)
// ============================================================
//   #F7931A  — Bitcoin Orange (Logo, Primary)
//   #00B4CF  — Einundzwanzig Cyan (Akzente)
//   #A915FF  — Einundzwanzig Lila (Web of Trust, Delegation)
//   #151515  — Hintergrund (Dark)
// ============================================================

const Color cDark = Color(0xFF101012);        // Tiefes Schwarz mit Minimal-Blau
const Color cCard = Color(0xFF1A1A1E);        // Karten-Hintergrund (wärmer)
const Color cCardHover = Color(0xFF242428);   // Hover State
const Color cSurface = Color(0xFF16161A);     // Zwischen-Surface
const Color cOrange = Color(0xFFF7931A);      // Brand: Bitcoin Orange
const Color cOrangeLight = Color(0xFFFFB347); // Helleres Orange
const Color cOrangeDim = Color(0xFF7A4A0E);   // Gedämpftes Orange für Hintergründe
const Color cCyan = Color(0xFF00B4CF);        // Brand: Einundzwanzig Cyan
const Color cCyanDim = Color(0xFF005A68);     // Gedämpftes Cyan
const Color cPurple = Color(0xFFA915FF);      // Brand: Lila
const Color cText = Color(0xFFF5F5F7);        // Fast-Weiß (Apple-Style)
const Color cTextSecondary = Color(0xFF9A9AA0); // Mittleres Grau
const Color cTextTertiary = Color(0xFF5C5C64);  // Dunkleres Grau
const Color cBorder = Color(0xFF2A2A30);      // Borders mit Blau-Stich

// Glassmorphism-Farben
const Color cGlass = Color(0x14FFFFFF);       // 8% Weiß
const Color cGlassBorder = Color(0x20FFFFFF); // 12% Weiß
const Color cGlassHeavy = Color(0x28FFFFFF);  // 16% Weiß für aktive States

// Status-Farben
const Color cGreen = Color(0xFF00C853);
const Color cRed = Color(0xFFCF6679);

// Gradient-Presets
const LinearGradient gradientOrange = LinearGradient(
  colors: [Color(0xFFF7931A), Color(0xFFFF6B00)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient gradientCyan = LinearGradient(
  colors: [Color(0xFF00B4CF), Color(0xFF0088A0)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient gradientPurple = LinearGradient(
  colors: [Color(0xFFA915FF), Color(0xFF7B00CC)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const LinearGradient gradientAmbient = LinearGradient(
  colors: [Color(0xFF1A1A2E), Color(0xFF101012)],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// ============================================================
// GLOBALES DESIGN-THEMA — Modernisiert
// ============================================================
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: cDark,
  primaryColor: cOrange,
  useMaterial3: true,
  fontFamily: GoogleFonts.inconsolata().fontFamily,
  
  colorScheme: const ColorScheme.dark(
    primary: cOrange,
    secondary: cCyan,
    surface: cCard,
    error: cRed,
  ),
  
  // Text Styles — verbesserte Hierarchie
  textTheme: TextTheme(
    displayLarge: const TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 34,
      letterSpacing: -1.0,
      color: cText,
      height: 1.15,
    ),
    displayMedium: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 26,
      letterSpacing: -0.5,
      color: cText,
      height: 1.2,
    ),
    titleLarge: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: -0.2,
      color: cText,
    ),
    titleMedium: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0,
      color: cText,
    ),
    bodyLarge: const TextStyle(
      fontSize: 16,
      color: cText,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodyMedium: const TextStyle(
      fontSize: 14,
      color: cTextSecondary,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodySmall: const TextStyle(
      fontSize: 12,
      color: cTextTertiary,
      height: 1.4,
      letterSpacing: 0.2,
    ),
    // NEU: Overline für Section-Headers
    labelSmall: TextStyle(
      fontSize: 11,
      color: cTextSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5,
      fontFamily: GoogleFonts.inconsolata().fontFamily,
    ),
  ),

  // AppBar — komplett flach, transparent
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: cText,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
    iconTheme: IconThemeData(color: cTextSecondary, size: 22),
  ),

  // Cards — Glassmorphism-Ready
  cardTheme: CardThemeData(
    color: cCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: cGlassBorder, width: 0.5),
    ),
    margin: const EdgeInsets.symmetric(vertical: 6),
  ),

  // Buttons — moderner mit größerem Radius
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: cOrange,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: cText,
      side: const BorderSide(color: cGlassBorder, width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: cOrange,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
  ),

  // Inputs — abgerundeter
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cBorder, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cBorder, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: cOrange, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    hintStyle: const TextStyle(color: cTextTertiary),
  ),

  // Divider — subtiler
  dividerTheme: const DividerThemeData(
    color: cBorder,
    thickness: 0.5,
    space: 32,
  ),

  // Bottom Navigation — wird durch custom Widget ersetzt, aber fallback:
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: cCard,
    selectedItemColor: cOrange,
    unselectedItemColor: cTextTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
    unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  ),

  // Chip Theme — für Labels und Tags
  chipTheme: ChipThemeData(
    backgroundColor: cGlass,
    side: const BorderSide(color: cGlassBorder, width: 0.5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    labelStyle: const TextStyle(
      color: cText,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),

  // SnackBar
  snackBarTheme: SnackBarThemeData(
    backgroundColor: cCard,
    contentTextStyle: const TextStyle(color: cText, fontSize: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    behavior: SnackBarBehavior.floating,
    elevation: 0,
  ),

  // Dialog
  dialogTheme: DialogThemeData(
    backgroundColor: cCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  ),

  // BottomSheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: cCard,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
  ),
);