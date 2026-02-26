// ============================================
// DEVICE INTEGRITY SERVICE (Security Audit M5)
// ============================================
// Erkennt gerootete Android-Geräte und jailbroken iOS-Geräte.
//
// WICHTIG: Keine 100%-Erkennung möglich – Magisk/KernelSU
// können Root vor vielen Checks verstecken. Deshalb:
//   - Warnung anzeigen, NICHT blockieren
//   - Kryptographische Sicherheit (SecureStorage, Nostr-Signaturen)
//     bleibt die primäre Verteidigungslinie
// ============================================

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_logger.dart';

enum DeviceIntegrityStatus {
  secure,       // Keine Auffälligkeiten
  warning,      // Root/Jailbreak-Indikatoren gefunden
  unknown,      // Prüfung nicht möglich (z.B. Web)
}

class IntegrityReport {
  final DeviceIntegrityStatus status;
  final List<String> findings;
  final DateTime checkedAt;

  IntegrityReport({
    required this.status,
    required this.findings,
    DateTime? checkedAt,
  }) : checkedAt = checkedAt ?? DateTime.now();

  bool get isCompromised => status == DeviceIntegrityStatus.warning;
}

class DeviceIntegrityService {
  static IntegrityReport? _cachedReport;

  /// Prüft die Geräte-Integrität.
  /// Ergebnis wird für die App-Session gecached.
  static Future<IntegrityReport> check({bool forceRefresh = false}) async {
    if (_cachedReport != null && !forceRefresh) {
      return _cachedReport!;
    }

    final findings = <String>[];

    try {
      if (Platform.isAndroid) {
        findings.addAll(await _checkAndroid());
      } else if (Platform.isIOS) {
        findings.addAll(await _checkIOS());
      } else {
        _cachedReport = IntegrityReport(
          status: DeviceIntegrityStatus.unknown,
          findings: ['Plattform nicht unterstützt: ${Platform.operatingSystem}'],
        );
        return _cachedReport!;
      }
    } catch (e) {
      AppLogger.warn('DeviceIntegrity', 'Integritätsprüfung fehlgeschlagen: $e');
      _cachedReport = IntegrityReport(
        status: DeviceIntegrityStatus.unknown,
        findings: ['Prüfung fehlgeschlagen'],
      );
      return _cachedReport!;
    }

    final status = findings.isEmpty
        ? DeviceIntegrityStatus.secure
        : DeviceIntegrityStatus.warning;

    if (findings.isNotEmpty) {
      AppLogger.security('DeviceIntegrity',
          '${findings.length} Auffälligkeit(en) gefunden');
    }

    _cachedReport = IntegrityReport(status: status, findings: findings);
    return _cachedReport!;
  }

  // =============================================
  // ANDROID ROOT DETECTION
  // =============================================
  static Future<List<String>> _checkAndroid() async {
    final findings = <String>[];

    // 1. Bekannte Root-Management-Binaries
    final rootBinaries = [
      '/system/bin/su',
      '/system/xbin/su',
      '/sbin/su',
      '/system/app/Superuser.apk',
      '/system/app/SuperSU.apk',
      '/data/local/bin/su',
      '/data/local/xbin/su',
    ];

    for (final path in rootBinaries) {
      if (await _fileExists(path)) {
        findings.add('Root-Binary gefunden: $path');
      }
    }

    // 2. Magisk-Indikatoren
    final magiskPaths = [
      '/sbin/.magisk',
      '/data/adb/magisk',
      '/data/adb/modules',
    ];

    for (final path in magiskPaths) {
      if (await _fileExists(path)) {
        findings.add('Magisk-Indikator: $path');
      }
    }

    // 3. Build-Tags prüfen (test-keys = nicht offiziell signiert)
    try {
      final result = await Process.run('getprop', ['ro.build.tags']);
      final tags = result.stdout.toString().trim();
      if (tags.contains('test-keys')) {
        findings.add('Build mit test-keys signiert');
      }
    } catch (_) {
      // getprop nicht verfügbar → ignorieren
    }

    // 4. Schreibzugriff auf /system prüfen
    try {
      final systemStat = await FileStat.stat('/system');
      // Auf normalen Geräten ist /system read-only
      if (systemStat.mode & 0x80 != 0) { // Owner write bit
        findings.add('/system ist beschreibbar');
      }
    } catch (_) {}

    // 5. BusyBox (häufig mit Root installiert)
    final busyboxPaths = ['/system/xbin/busybox', '/system/bin/busybox'];
    for (final path in busyboxPaths) {
      if (await _fileExists(path)) {
        findings.add('BusyBox installiert: $path');
      }
    }

    return findings;
  }

  // =============================================
  // iOS JAILBREAK DETECTION
  // =============================================
  static Future<List<String>> _checkIOS() async {
    final findings = <String>[];

    // 1. Bekannte Jailbreak-Pfade
    final jailbreakPaths = [
      '/Applications/Cydia.app',
      '/Applications/Sileo.app',
      '/Applications/Zebra.app',
      '/Library/MobileSubstrate/MobileSubstrate.dylib',
      '/usr/sbin/sshd',
      '/usr/bin/ssh',
      '/etc/apt',
      '/private/var/lib/apt/',
      '/var/lib/cydia',
      '/private/var/stash',
      '/usr/libexec/sftp-server',
    ];

    for (final path in jailbreakPaths) {
      if (await _fileExists(path)) {
        findings.add('Jailbreak-Pfad gefunden: $path');
      }
    }

    // 2. Schreibtest außerhalb der Sandbox
    try {
      final testFile = File('/private/jailbreak_check_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test');
      await testFile.delete();
      findings.add('Schreibzugriff außerhalb der Sandbox möglich');
    } catch (_) {
      // Erwartet: Kein Zugriff = gut
    }

    // 3. Fork-Check (Jailbroken devices erlauben fork())
    // Nicht direkt in Dart möglich, aber symbolic links prüfen
    try {
      final result = await FileStat.stat('/bin/bash');
      if (result.type != FileSystemEntityType.notFound) {
        findings.add('/bin/bash existiert');
      }
    } catch (_) {}

    return findings;
  }

  // =============================================
  // HELPER
  // =============================================
  static Future<bool> _fileExists(String path) async {
    try {
      return await File(path).exists() || await Directory(path).exists();
    } catch (_) {
      return false;
    }
  }

  /// Menschenlesbare Warnung für die UI
  static String get warningMessage =>
      'Dieses Gerät zeigt Anzeichen von Root/Jailbreak. '
      'Kryptographische Schlüssel könnten weniger geschützt sein. '
      'Für maximale Sicherheit ein nicht modifiziertes Gerät verwenden.';
}
