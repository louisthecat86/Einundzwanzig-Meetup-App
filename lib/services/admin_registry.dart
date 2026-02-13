import 'dart:convert';
import 'dart:io';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nostr_service.dart';

class AdminRegistry {
  static final AdminRegistry _instance = AdminRegistry._internal();
  factory AdminRegistry() => _instance;
  AdminRegistry._internal();

  // --- HIER DEINEN ECHTEN NPUB EINTRAGEN ---
  // Das ist der "Ur-Admin" (Du).
  static const List<String> seedAdminNpubs = [
    "npub1lf0rga7j66uj6enae2mxezamz5nsz3vechhvmh25tcarn4u8qf5q534jzc" 
  ];

  List<String> _cachedAdmins = [];

  Future<void> init() async {
    await _loadFromCache();
    // Versuchen im Hintergrund zu aktualisieren
    _fetchFromRelays().then((_) => _saveToCache());
  }

  Future<bool> isAdmin(String? userNpub) async {
    if (userNpub == null) return false;
    
    // 1. Ist es einer der Seed-Admins?
    if (seedAdminNpubs.contains(userNpub)) return true;

    // 2. Ist er in der geladenen Liste?
    if (_cachedAdmins.contains(userNpub)) return true;

    return false;
  }

  Future<void> _fetchFromRelays() async {
    // Holt die Liste von Admins, die von einem Seed-Admin signiert wurde
    try {
      final ws = await WebSocket.connect("wss://relay.damus.io");
      
      // Wir suchen Events von ALLEN Seed-Admins
      List<String> seedPubkeys = [];
      for (var npub in seedAdminNpubs) {
        seedPubkeys.add(Nip19.decode(npub));
      }

      final req = ["REQ", "admin-list", {
        "kinds": [30078], 
        "authors": seedPubkeys,
        "#d": ["einundzwanzig-admins"],
        "limit": 1
      }];
      
      ws.add(jsonEncode(req));
      
      await for (final msg in ws.map((e) => jsonDecode(e as String)).timeout(const Duration(seconds: 3))) {
        if (msg[0] == "EVENT") {
          final event = msg[2];
          // Content ist JSON-Liste von npubs
          final List<dynamic> loaded = jsonDecode(event['content']);
          _cachedAdmins = loaded.cast<String>();
        }
      }
      await ws.close();
    } catch (e) {
      print("Admin registry fetch error: $e");
    }
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedAdmins = prefs.getStringList('admin_registry_cache') ?? [];
  }

  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('admin_registry_cache', _cachedAdmins);
  }
}