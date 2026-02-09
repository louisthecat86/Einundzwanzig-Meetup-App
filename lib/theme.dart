import 'package:flutter/material.dart';

// Einundzwanzig Farb-Palette (Angelehnt an einundzwanzig.space)
const Color cDark = Color(0xFF0A0A0A); // Sehr dunkler Hintergrund
const Color cCard = Color(0xFF1A1A1A); // Karten Hintergrund
const Color cCardHover = Color(0xFF242424); // Hover State
const Color cOrange = Color(0xFFF7931A); // Bitcoin Orange
const Color cOrangeLight = Color(0xFFFFB347); // Helleres Orange für Akzente
const Color cCyan = Color(0xFF00D4FF); // Aufgehelltes Cyan
const Color cPurple = Color(0xFFBB6BD9); // Sanfteres Lila
const Color cText = Color(0xFFFFFFFF); // Reines Weiß
const Color cTextSecondary = Color(0xFFB0B0B0); // Grauer Text
const Color cTextTertiary = Color(0xFF808080); // Noch grauer
const Color cBorder = Color(0xFF2A2A2A); // Subtile Borders

// Das globale Design-Thema (Einundzwanzig Style)
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: cDark,
  primaryColor: cOrange,
  useMaterial3: true,
  fontFamily: 'Roboto', // Modern & Clean
  
  // Color Scheme
  colorScheme: const ColorScheme.dark(
    primary: cOrange,
    secondary: cCyan,
    surface: cCard,
    background: cDark,
    error: Color(0xFFFF4444),
  ),
  
  // Text Styles
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 32,
      letterSpacing: -0.5,
      color: cText,
      height: 1.2,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 24,
      letterSpacing: -0.3,
      color: cText,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 20,
      letterSpacing: 0,
      color: cText,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      letterSpacing: 0.1,
      color: cText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      color: cText,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: cTextSecondary,
      height: 1.5,
      letterSpacing: 0.1,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: cTextTertiary,
      height: 1.4,
      letterSpacing: 0.2,
    ),
  ),

  // AppBar Style
  appBarTheme: const AppBarTheme(
    backgroundColor: cDark,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: cText,
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    ),
    iconTheme: IconThemeData(color: cOrange, size: 24),
  ),

  // Card Style
  cardTheme: CardThemeData(
    color: cCard,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: cBorder, width: 1),
    ),
    margin: const EdgeInsets.symmetric(vertical: 8),
  ),

  // Button Themes
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: cOrange,
      foregroundColor: Colors.black,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
      side: const BorderSide(color: cBorder, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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

  // Input Decoration
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: cCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cOrange, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: const TextStyle(color: cTextTertiary),
  ),

  // Divider
  dividerTheme: const DividerThemeData(
    color: cBorder,
    thickness: 1,
    space: 32,
  ),

  // Bottom Navigation Style
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: cCard,
    selectedItemColor: cOrange,
    unselectedItemColor: cTextTertiary,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  ),
);