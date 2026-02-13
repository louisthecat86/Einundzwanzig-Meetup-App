import 'dart:io';
import 'dart:convert';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart'; 
import 'package:hex/hex.dart';

class CoAttestorInfo {
  final String meetupEventId;
  final int attendeeCount;
  final List<String> attendeeNpubs;
  
  CoAttestorInfo(this.meetupEventId, this.attendeeCount, this.attendeeNpubs);
}

class NostrService {
  static final NostrService _instance = NostrService._internal();
  factory NostrService() => _instance;
  NostrService._internal();

  Keychain? _keychain;
  
  // ... (Deine bestehenden Methoden generatePrivateKey, loadKeys etc. hier lassen) ...
  // Ich füge hier nur die NEUEN Methoden für Co-Attestor hinzu, 
  // kopiere den Rest aus deiner alten Datei oder lass ihn stehen.

  Future<bool> hasKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('nostr_priv_key');
  }

  Future<void> generatePrivateKey() async {
    final newKeychain = Keychain.generate();
    await _saveKeys(newKeychain.private);
    _keychain = newKeychain;
  }
  
  Future<void> _saveKeys(String privateKeyHex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nostr_priv_key', privateKeyHex);
  }

  Future<String?> getPublicKey() async {
     // ... (Implementierung wie gehabt)
     final prefs = await SharedPreferences.getInstance();
     final priv = prefs.getString('nostr_priv_key');
     if (priv != null) {
       return Keychain(priv).public;
     }
     return null;
  }
  
  Future<String?> getNpub() async {
    final pub = await getPublicKey();
    if (pub == null) return null;
    return Nip19.encodePubkey(pub);
  }

  // --- NEU: Anwesenheit publishen (Co-Attestor) ---
  Future<void> publishAttendance(String meetupEventId, String meetupName) async {
    if (_keychain == null) await loadKeys();
    if (_keychain == null) return;

    // Event Kind 21021 (Vorschlag für Attendance)
    final event = Event.from(
      kind: 21021,
      content: "Attesting attendance at $meetupName",
      tags: [
        ["e", meetupEventId, "wss://relay.damus.io", "root"],
        ["t", "einundzwanzig-meetup"],
      ],
      privkey: _keychain!.private,
    );
    
    // An Relay senden
    try {
      final ws = await WebSocket.connect("wss://relay.damus.io");
      ws.add(jsonEncode(["EVENT", event.toJson()]));
      await ws.close();
    } catch (e) {
      print("Relay error: $e");
    }
  }

  // --- NEU: Co-Attestors laden ---
  Future<CoAttestorInfo> fetchCoAttestors(String meetupEventId) async {
    final attendees = <String>{};
    
    try {
      final ws = await WebSocket.connect("wss://relay.damus.io");
      
      // Request Attendance Events die sich auf dieses Meetup beziehen
      final req = ["REQ", "co-attest", {
        "kinds": [21021],
        "#e": [meetupEventId]
      }];
      
      ws.add(jsonEncode(req));
      
      // 2 Sekunden lauschen reicht für Demo
      await for (final msg in ws.map((e) => jsonDecode(e as String)).timeout(const Duration(seconds: 2))) {
        if (msg[0] == "EVENT") {
          final ev = msg[2];
          attendees.add(ev['pubkey']);
        }
        if (msg[0] == "EOSE") break;
      }
      await ws.close();
    } catch (e) {
      print("Fetch error: $e");
    }
    
    return CoAttestorInfo(meetupEventId, attendees.length, attendees.toList());
  }

  // Hilfsmethode Laden
  Future<void> loadKeys() async {
     final prefs = await SharedPreferences.getInstance();
     final priv = prefs.getString('nostr_priv_key');
     if (priv != null) _keychain = Keychain(priv);
  }
}