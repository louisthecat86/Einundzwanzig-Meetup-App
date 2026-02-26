// ============================================
// APP LOGGER — Sicheres Logging (Security Audit H1)
// ============================================
//
// Ersetzt alle print()-Aufrufe im Codebase.
// In Release-Builds wird NICHTS geloggt.
// Sensible Daten (Keys, Seeds, Admin-Status) werden
// NIEMALS in logcat geschrieben.
//
// Auf Android landen print()-Ausgaben in logcat, das
// von jeder App mit READ_LOGS Permission gelesen werden kann.
// ============================================

import 'package:flutter/foundation.dart';

class AppLogger {
  /// Debug-Level: Nur in kDebugMode sichtbar
  static void debug(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  /// Info-Level: Nur in kDebugMode sichtbar
  static void info(String tag, String message) {
    if (kDebugMode) {
      print('[$tag] $message');
    }
  }

  /// Warning-Level: Nur in kDebugMode sichtbar
  static void warn(String tag, String message) {
    if (kDebugMode) {
      print('[WARN:$tag] $message');
    }
  }

  /// Error-Level: Nur in kDebugMode sichtbar
  /// Zukünftig: An Crash-Reporting (Sentry/Crashlytics) senden
  static void error(String tag, String message, [Object? error]) {
    if (kDebugMode) {
      print('[ERROR:$tag] $message');
      if (error != null) print('[ERROR:$tag] $error');
    }
    // TODO: Sentry/Crashlytics Integration (Sprint 3)
    // _sendToCrashReporting(tag, message, error);
  }

  /// Security-Level: NUR in kDebugMode, für krypto-relevante Operationen.
  /// NIEMALS private Keys, Seeds oder vollständige Pubkeys loggen!
  static void security(String tag, String message) {
    if (kDebugMode) {
      print('[SEC:$tag] $message');
    }
  }
}
