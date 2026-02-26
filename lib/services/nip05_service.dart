// ============================================
// NIP-05 VERIFICATION SERVICE
// ============================================
// Prüft NIP-05 Internet-Identifikatoren.
//
// NIP-05 Format: name@domain.com
// Prüfung: GET https://domain.com/.well-known/nostr.json?name=name
// Erwartung: {"names":{"name":"pubkey_hex"}}
//
// Beweist: Der Nutzer kontrolliert (oder wird endorsed von)
// der Domain. z.B. max@einundzwanzig.space beweist,
// dass die Einundzwanzig-Community diesen npub anerkennt.
//
// Gewichtung:
//   - Eigene Domain (z.B. max@maxhodler.de) → mittel
//   - Community-Domain (z.B. max@einundzwanzig.space) → hoch
//   - Public NIP-05 Provider (z.B. max@nostrplebs.com) → niedrig
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nostr/nostr.dart';
import 'secure_key_store.dart';
import 'dart:math';

class Nip05Service {
  static const Duration _timeout = Duration(seconds: 5);

  // Bekannte Community-Domains (höherer Vertrauenswert)
  static const List<String> communityDomains = [
    'einundzwanzig.space',
    'einundzwanzig.ch',
    'bitcoin.de',
    'nostr.com',
  ];

  // Public NIP-05 Provider (niedrigerer Vertrauenswert)
  static const List<String> publicProviders = [
    'nostrplebs.com',
    'nostr.wine',
    'iris.to',
    'snort.social',
    'damus.io',
  ];

  // =============================================
  // NIP-05 PRÜFEN
  // =============================================
  // Gibt ein Nip05Result zurück:
  //   - valid: Pubkey stimmt überein
  //   - domain: Die Domain des NIP-05
  //   - domainType: community / custom / public / unknown
  // =============================================

  static Future<Nip05Result> verify(String nip05, String expectedPubkeyHex) async {
    if (nip05.isEmpty || !nip05.contains('@')) {
      return Nip05Result(valid: false, nip05: nip05);
    }

    final parts = nip05.split('@');
    if (parts.length != 2) {
      return Nip05Result(valid: false, nip05: nip05);
    }

    final name = parts[0].toLowerCase();
    final domain = parts[1].toLowerCase();

    try {
      final url = Uri.parse('https://$domain/.well-known/nostr.json?name=$name');
      final client = HttpClient();
      client.connectionTimeout = _timeout;

      final request = await client.getUrl(url);
      final response = await request.close().timeout(_timeout);

      if (response.statusCode != 200) {
        return Nip05Result(valid: false, nip05: nip05, domain: domain);
      }

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final names = json['names'] as Map<String, dynamic>?;

      if (names == null) {
        return Nip05Result(valid: false, nip05: nip05, domain: domain);
      }

      final pubkey = names[name] as String?;
      final isValid = pubkey != null && pubkey == expectedPubkeyHex;

      // Domain-Typ bestimmen
      Nip05DomainType domainType;
      if (communityDomains.any((d) => domain == d || domain.endsWith('.$d'))) {
        domainType = Nip05DomainType.community;
      } else if (publicProviders.any((d) => domain == d || domain.endsWith('.$d'))) {
        domainType = Nip05DomainType.publicProvider;
      } else {
        domainType = Nip05DomainType.custom;
      }

      return Nip05Result(
        valid: isValid,
        nip05: nip05,
        domain: domain,
        domainType: domainType,
      );
    } catch (e) {
      return Nip05Result(valid: false, nip05: nip05, domain: domain);
    }
  }

  // =============================================
  // NIP-05 EINES NUTZERS VON RELAYS ABRUFEN
  // =============================================
  // Kind 0 Event (Metadata/Profile) enthält das NIP-05
  // im JSON-Content als "nip05" Feld.
  // =============================================

  static Future<String?> fetchNip05FromProfile(
    String pubkeyHex,
    List<String> relays,
  ) async {
    for (final relayUrl in relays.take(2)) {
      try {
        final nip05 = await _fetchProfileNip05(relayUrl, pubkeyHex);
        if (nip05 != null && nip05.isNotEmpty) return nip05;
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _fetchProfileNip05(
    String relayUrl,
    String pubkeyHex,
  ) async {
    WebSocket? ws;
    try {
      ws = await WebSocket.connect(relayUrl).timeout(_timeout);
      final completer = Completer<String?>();
      // Security Audit M4: Kryptographisch sichere Subscription-ID
      final random = Random.secure();
      final subIdHex = List.generate(8, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      final subId = 'nip05-$subIdHex';

      ws.listen(
        (data) {
          try {
            final message = jsonDecode(data as String) as List<dynamic>;
            final type = message[0] as String;

            if (type == 'EVENT' && message.length >= 3) {
              final eventData = message[2] as Map<String, dynamic>;
              final content = eventData['content'] as String? ?? '';
              try {
                final profile = jsonDecode(content) as Map<String, dynamic>;
                final nip05 = profile['nip05'] as String?;
                if (!completer.isCompleted) completer.complete(nip05);
              } catch (_) {}
            } else if (type == 'EOSE') {
              if (!completer.isCompleted) completer.complete(null);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      ws.add(jsonEncode([
        'REQ', subId,
        {
          'kinds': [0], // Metadata/Profile
          'authors': [pubkeyHex],
          'limit': 1,
        }
      ]));

      return await completer.future.timeout(
        _timeout,
        onTimeout: () => null,
      );
    } finally {
      ws?.close();
    }
  }

  // =============================================
  // NIP-05 SCORE
  // =============================================

  static double score(Nip05Result result) {
    if (!result.valid) return 0;
    switch (result.domainType) {
      case Nip05DomainType.community:
        return 1.0; // Höchste: Community-Endorsement
      case Nip05DomainType.custom:
        return 0.7; // Mittel: Eigene Domain
      case Nip05DomainType.publicProvider:
        return 0.3; // Niedrig: Public Provider
      default:
        return 0.2;
    }
  }
}

// =============================================
// DATENMODELLE
// =============================================

enum Nip05DomainType {
  community,      // einundzwanzig.space etc.
  custom,         // Eigene Domain
  publicProvider,  // nostrplebs.com etc.
  unknown,
}

class Nip05Result {
  final bool valid;
  final String nip05;
  final String? domain;
  final Nip05DomainType domainType;

  Nip05Result({
    required this.valid,
    required this.nip05,
    this.domain,
    this.domainType = Nip05DomainType.unknown,
  });

  String get domainLabel {
    switch (domainType) {
      case Nip05DomainType.community: return 'Community-verifiziert';
      case Nip05DomainType.custom: return 'Eigene Domain';
      case Nip05DomainType.publicProvider: return 'Public Provider';
      default: return '';
    }
  }
}