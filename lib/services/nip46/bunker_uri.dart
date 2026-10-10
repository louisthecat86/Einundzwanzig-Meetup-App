// ============================================
// BUNKER-URI — Adresse eines Remote-Signers (NIP-46)
// ============================================
// Zwei Richtungen:
//
//   bunker://<signer-pubkey>?relay=wss://…&secret=…
//     Der Nutzer kopiert das aus nsec.app / Amber / Alby in die App.
//     Das ist auf iOS der Hauptweg, weil es dort keinen Deep-Link-Partner
//     gibt (kein Amber, keine Browsererweiterung).
//
//   nostrconnect://<client-pubkey>?relay=…&secret=…&perms=…&name=…
//     Die App gibt die Adresse aus (QR-Code oder Deep-Link), der Signer
//     verbindet sich daraufhin von seiner Seite.
//
// Nach einer erfolgreichen Kopplung wird IMMER als bunker:// gespeichert —
// auch wenn sie mit nostrconnect:// begonnen hat. So gibt es beim Neustart
// nur einen Wiederherstellungs-Pfad statt zwei.
// ============================================

import 'package:nostr/nostr.dart';

import 'nip46_exception.dart';

class BunkerPointer {
  /// hex-pubkey des Signers (NICHT der pubkey des Nutzers — bei nsec.app
  /// sind das zwei verschiedene Schlüssel).
  final String remoteSignerPubkey;

  /// Relays, über die der Signer erreichbar ist. Mindestens eines.
  final List<String> relays;

  /// Einmal-Geheimnis aus der URI. Wird nur beim ersten `connect`
  /// mitgeschickt und danach nicht gespeichert.
  final String? secret;

  const BunkerPointer({
    required this.remoteSignerPubkey,
    required this.relays,
    this.secret,
  });

  /// Liest `bunker://…`. Akzeptiert zusätzlich einen npub als Signer-Schlüssel,
  /// weil manche Signer ihn so ausgeben, obwohl das NIP hex vorschreibt.
  static BunkerPointer parse(String input) {
    final trimmed = input.trim();
    if (!trimmed.toLowerCase().startsWith('bunker://')) {
      throw const Nip46Exception(
          'Das ist keine Bunker-Adresse — sie muss mit "bunker://" beginnen.');
    }

    final Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      throw const Nip46Exception('Die Bunker-Adresse ist unlesbar.');
    }

    // Uri legt den Schlüssel in host ab; ohne Autorität landet er im Pfad.
    var key = uri.host;
    if (key.isEmpty && uri.pathSegments.isNotEmpty) {
      key = uri.pathSegments.first;
    }

    final relays = [
      for (final r in uri.queryParametersAll['relay'] ?? const <String>[])
        if (_isRelayUrl(r.trim())) r.trim(),
    ];
    if (relays.isEmpty) {
      throw const Nip46Exception(
          'In der Bunker-Adresse fehlt ein Relay (relay=wss://…). '
          'Ohne Relay ist der Signer nicht erreichbar.');
    }

    final secret = uri.queryParameters['secret']?.trim();

    return BunkerPointer(
      remoteSignerPubkey: normalizePubkey(key),
      relays: List.unmodifiable(relays),
      secret: (secret == null || secret.isEmpty) ? null : secret,
    );
  }

  /// Form für die Persistenz — ohne `secret`, das ist einmalig verwendbar
  /// und im gespeicherten Zustand nur noch ein Risiko.
  String toBunkerUri() {
    final query = relays.map((r) => 'relay=${Uri.encodeQueryComponent(r)}');
    return 'bunker://$remoteSignerPubkey?${query.join('&')}';
  }

  /// Baut die Adresse, die die App für den client-initiierten Weg ausgibt.
  static String buildNostrConnectUri({
    required String clientPubkeyHex,
    required List<String> relays,
    required String secret,
    required String perms,
    required String appName,
    String? appUrl,
    String? appImage,
  }) {
    final params = <String>[
      for (final r in relays) 'relay=${Uri.encodeQueryComponent(r)}',
      'secret=${Uri.encodeQueryComponent(secret)}',
      'perms=${Uri.encodeQueryComponent(perms)}',
      // Native URI-Parser behandeln '+' nicht zwingend als Leerzeichen.
      // Prozentkodierung (%20) funktioniert auch ohne Formular-Dekodierung.
      'name=${Uri.encodeComponent(appName)}',
      if (appUrl != null) 'url=${Uri.encodeQueryComponent(appUrl)}',
      if (appImage != null) 'image=${Uri.encodeQueryComponent(appImage)}',
    ];
    return 'nostrconnect://$clientPubkeyHex?${params.join('&')}';
  }

  /// npub oder hex → hex. Wirft bei allem anderen.
  static String normalizePubkey(String value) {
    var key = value.trim();
    if (key.toLowerCase().startsWith('npub1')) {
      try {
        key = Nip19.decodePubkey(key);
      } catch (_) {
        throw const Nip46Exception('Der npub des Signers ist ungültig.');
      }
    }
    key = key.toLowerCase();
    if (key.length != 64 || !_isHex(key)) {
      throw const Nip46Exception(
          'Der Schlüssel des Signers ist kein 64-stelliger Hex-Wert.');
    }
    return key;
  }

  // Nur wss:// (Security Audit N2): ws:// legt Metadaten und
  // Verfügbarkeit des Signer-Relays offen. Die Nutzlast bleibt zwar
  // NIP-44-verschlüsselt, aber wer den Relay-Verkehr beobachtet oder
  // unterbricht, kann den Bunker unbrauchbar machen.
  static bool _isRelayUrl(String value) => value.startsWith('wss://');

  static bool _isHex(String value) {
    for (final c in value.codeUnits) {
      final isDigit = c >= 0x30 && c <= 0x39;
      final isLower = c >= 0x61 && c <= 0x66;
      if (!isDigit && !isLower) return false;
    }
    return true;
  }
}
