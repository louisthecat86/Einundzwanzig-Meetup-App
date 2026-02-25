// ============================================
// RELAY CONFIG — Konfigurierbare Nostr-Relays
// ============================================
// Verwaltet Default-Relays und benutzerdefinierte Relays.
// Alle Services die Relays nutzen (AdminRegistry,
// PromotionClaimService, ReputationPublisher) sollten
// diese zentrale Konfiguration verwenden.
//
// Default-Relays sind bewährte, zuverlässige Relays.
// Der Nutzer kann in den Einstellungen eigene Relays
// hinzufügen oder Default-Relays deaktivieren.
// ============================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RelayConfig {
  // =============================================
  // DEFAULT-RELAYS
  // =============================================
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://nos.lol',
    'wss://relay.nostr.band',
    'wss://nostr.einundzwanzig.space',
  ];

  // Cache Keys
  static const String _customRelaysKey = 'custom_relays';
  static const String _disabledDefaultsKey = 'disabled_default_relays';

  // Timeout
  static const Duration relayTimeout = Duration(seconds: 8);
  static const Duration publishTimeout = Duration(seconds: 5);

  // =============================================
  // AKTIVE RELAYS ABRUFEN
  // Gibt alle aktiven Relays zurück:
  // Default-Relays (sofern nicht deaktiviert) + Custom-Relays
  // =============================================
  static Future<List<String>> getActiveRelays() async {
    final prefs = await SharedPreferences.getInstance();

    // Deaktivierte Default-Relays laden
    final disabledJson = prefs.getStringList(_disabledDefaultsKey) ?? [];

    // Aktive Default-Relays
    final activeDefaults = defaultRelays
        .where((r) => !disabledJson.contains(r))
        .toList();

    // Custom-Relays laden
    final customRelays = prefs.getStringList(_customRelaysKey) ?? [];

    // Zusammenführen und Duplikate entfernen
    final all = <String>{...activeDefaults, ...customRelays};
    return all.toList();
  }

  // =============================================
  // CUSTOM-RELAYS VERWALTEN
  // =============================================
  static Future<List<String>> getCustomRelays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_customRelaysKey) ?? [];
  }

  static Future<void> addCustomRelay(String url) async {
    final trimmed = url.trim();
    if (!trimmed.startsWith('wss://')) {
      throw ArgumentError('Relay-URL muss mit wss:// beginnen');
    }

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customRelaysKey) ?? [];
    if (current.contains(trimmed)) return; // Bereits vorhanden
    current.add(trimmed);
    await prefs.setStringList(_customRelaysKey, current);
  }

  static Future<void> removeCustomRelay(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_customRelaysKey) ?? [];
    current.remove(url);
    await prefs.setStringList(_customRelaysKey, current);
  }

  // =============================================
  // DEFAULT-RELAYS AKTIVIEREN/DEAKTIVIEREN
  // =============================================
  static Future<List<String>> getDisabledDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_disabledDefaultsKey) ?? [];
  }

  static Future<void> setDefaultRelayEnabled(String url, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final disabled = prefs.getStringList(_disabledDefaultsKey) ?? [];
    if (enabled) {
      disabled.remove(url);
    } else {
      if (!disabled.contains(url)) disabled.add(url);
    }
    await prefs.setStringList(_disabledDefaultsKey, disabled);
  }

  // =============================================
  // RELAY-STATUS (für UI)
  // =============================================
  static Future<Map<String, bool>> getRelayStatus() async {
    final disabled = await getDisabledDefaults();
    final custom = await getCustomRelays();

    final status = <String, bool>{};
    for (final r in defaultRelays) {
      status[r] = !disabled.contains(r);
    }
    for (final r in custom) {
      status[r] = true; // Custom Relays sind immer aktiv
    }
    return status;
  }
}