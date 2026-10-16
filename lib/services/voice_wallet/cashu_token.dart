import 'dart:convert';
import 'dart:typed_data';

import 'cashu_cbor.dart';

/// Ein Proof. Das Geheimnis und `C` zusammen sind das Geld.
class CashuProof {
  final int amount;
  final String id;
  final String secret;
  final String c;
  final String? witness;

  const CashuProof({
    required this.amount,
    required this.id,
    required this.secret,
    required this.c,
    this.witness,
  });

  Map<String, Object> toJson() => {
        'amount': amount,
        'id': id,
        'secret': secret,
        'C': c,
        'witness': ?witness,
      };
}

/// Ein gelesener Token, noch nicht eingelöst.
class CashuToken {
  final String mint;
  final String unit;
  final List<CashuProof> proofs;

  const CashuToken({
    required this.mint,
    required this.unit,
    required this.proofs,
  });

  int get sats => proofs.fold(0, (sum, p) => sum + p.amount);
}

/// Was die Sprachseite anzeigen kann, ohne den Mint zu fragen.
class CashuPeek {
  final bool isCashu;
  final int? sats;

  const CashuPeek({required this.isCashu, this.sats});

  static const notToken = CashuPeek(isCashu: false);
}

CashuPeek peekCashuToken(String raw) {
  try {
    final parts = parseCashuTokens(raw);
    final sats = parts
        .where((token) => token.unit.toLowerCase() == 'sat')
        .fold<int>(0, (sum, token) => sum + token.sats);
    if (sats == 0 && parts.any((token) => token.unit.toLowerCase() != 'sat')) {
      return const CashuPeek(isCashu: true);
    }
    return CashuPeek(isCashu: true, sats: sats);
  } on FormatException {
    if (_tokenIn(raw) != null) return const CashuPeek(isCashu: true);
    return CashuPeek.notToken;
  }
}

/// Kurzer Hinweis ohne Geheimnis: `A:840`, `B:840`, `lightning` oder `none`.
String cashuReadHint(String raw) {
  final lower = raw.toLowerCase();
  if (lower.contains('lnbc') || lower.contains('lntb') || lower.contains('lnurl')) {
    return 'lightning';
  }
  final token = _tokenIn(raw);
  if (token == null || token.length < 6) return 'none';
  return '${token[5]}:${token.length}';
}

/// Findet `cashuA`/`cashuB` auch in einem Link. Zeilenumbrüche im Token
/// fallen raus, ein Leerzeichen beendet ihn, damit der Satz danach nicht
/// mitdekodiert wird.
String? _tokenIn(String raw) {
  var text = raw.trim();
  if (text.contains('%')) {
    try {
      text = Uri.decodeFull(text);
    } catch (_) {}
  }
  text = text.replaceAll(RegExp(r'[\u0000\uFEFF\u200B]'), '');
  if (text.toLowerCase().startsWith('cashu:')) text = text.substring('cashu:'.length);
  final start = RegExp(r'cashu[ABab]', caseSensitive: false).firstMatch(text);
  if (start == null) return null;
  final buf = StringBuffer(start.group(0)!);
  for (var i = start.end; i < text.length; i++) {
    final ch = text[i];
    final code = ch.codeUnitAt(0);
    final isToken = (code >= 0x41 && code <= 0x5A) ||
        (code >= 0x61 && code <= 0x7A) ||
        (code >= 0x30 && code <= 0x39) ||
        ch == '+' ||
        ch == '/' ||
        ch == '_' ||
        ch == '-' ||
        ch == '=';
    if (isToken) {
      buf.write(ch);
    } else if (ch == '\n' || ch == '\r' || ch == '\t') {
      continue;
    } else {
      break;
    }
  }
  final token = buf.toString();
  if (token.length < 7) return null;
  final version = token[5].toUpperCase();
  if (version != 'A' && version != 'B') return null;
  return 'cashu$version${token.substring(6)}';
}

CashuToken parseCashuToken(String raw) {
  final parts = parseCashuTokens(raw);
  if (parts.isEmpty) throw const FormatException('Token ohne Proofs.');
  return parts.first;
}

List<CashuToken> parseCashuTokens(String raw) {
  final token = _tokenIn(raw);
  if (token == null) throw const FormatException('Kein Cashu-Token.');
  if (token.startsWith('cashuA')) return _parseV3(token.substring('cashuA'.length));
  return [_parseV4(token.substring('cashuB'.length))];
}

String encodeCashuToken({required String mint, required List<CashuProof> proofs}) {
  final json = jsonEncode({
    'token': [
      {
        'mint': _mint(mint),
        'proofs': proofs.map((p) => p.toJson()).toList(),
      },
    ],
    'unit': 'sat',
  });
  final encoded = base64Url.encode(utf8.encode(json)).replaceAll('=', '');
  return 'cashuA$encoded';
}

List<CashuToken> _parseV3(String payload) {
  final Object? json;
  try {
    json = jsonDecode(utf8.decode(_decode64(payload)));
  } catch (_) {
    throw const FormatException('cashuA ist kein Token.');
  }
  if (json is! Map) throw const FormatException('cashuA ist kein Token.');
  final unit = json['unit'] ?? 'sat';
  if (unit is! String) throw const FormatException('Einheit fehlt.');
  final entries = json['token'];
  if (entries is! List || entries.isEmpty) {
    throw const FormatException('Token ohne Proofs.');
  }
  final tokens = <CashuToken>[];
  for (final entry in entries) {
    if (entry is! Map) throw const FormatException('Token ohne Proofs.');
    final mint = entry['mint'];
    final proofs = entry['proofs'];
    if (mint is! String || proofs is! List || proofs.isEmpty) {
      throw const FormatException('Token ohne Proofs.');
    }
    tokens.add(CashuToken(
      mint: _mint(mint),
      unit: unit,
      proofs: [
        for (final proof in proofs) _proofMap(proof),
      ],
    ));
  }
  return tokens;
}

CashuToken _parseV4(String payload) {
  final Object? decoded;
  try {
    decoded = decodeCbor(Uint8List.fromList(_decode64(payload)));
  } catch (_) {
    throw const FormatException('cashuB ist kein Token.');
  }
  if (decoded is! Map) throw const FormatException('cashuB ist kein Token.');
  final mint = decoded['m'];
  final unit = decoded['u'] ?? 'sat';
  final groups = decoded['t'];
  if (mint is! String || unit is! String || groups is! List || groups.isEmpty) {
    throw const FormatException('cashuB ist kein Token.');
  }
  final proofs = <CashuProof>[];
  for (final group in groups) {
    if (group is! Map) throw const FormatException('cashuB ist kein Token.');
    final id = _asId(group['i']);
    final list = group['p'];
    if (id == null || list is! List) {
      throw const FormatException('cashuB ist kein Token.');
    }
    for (final item in list) {
      if (item is! Map) throw const FormatException('cashuB ist kein Token.');
      final amount = _asAmount(item['a']);
      final secret = _asSecret(item['s']);
      final c = _asPoint(item['c']);
      if (amount == null || amount < 0 || secret == null || c == null) {
        throw const FormatException('cashuB ist kein Token.');
      }
      proofs.add(CashuProof(
        amount: amount,
        id: id,
        secret: secret,
        c: c,
        witness: _asWitness(item['w']),
      ));
    }
  }
  if (proofs.isEmpty) throw const FormatException('Token ohne Proofs.');
  return CashuToken(mint: _mint(mint), unit: unit, proofs: proofs);
}

CashuProof _proofMap(Object? raw) {
  if (raw is! Map) throw const FormatException('Proof unvollständig.');
  final amount = _asAmount(raw['amount']);
  final id = raw['id'];
  final secret = _asSecret(raw['secret']);
  final point = _asPoint(raw['C'] ?? raw['c']);
  if (amount == null || amount < 0 || id is! String || id.isEmpty || secret == null || point == null) {
    throw const FormatException('Proof unvollständig.');
  }
  return CashuProof(
    amount: amount,
    id: id,
    secret: secret,
    c: point,
    witness: _asWitness(raw['witness']),
  );
}

List<int> _decode64(String payload) {
  final url = payload.replaceAll('+', '-').replaceAll('/', '_');
  return base64Url.decode(base64Url.normalize(url));
}

int? _asAmount(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value >= 0 && value == value.roundToDouble()) {
    return value.round();
  }
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asSecret(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  if (value is Uint8List && value.isNotEmpty) {
    return utf8.decode(value, allowMalformed: true);
  }
  return null;
}

String? _asId(Object? value) {
  if (value is Uint8List && value.isNotEmpty) return _hex(value);
  if (value is String && value.isNotEmpty) return value;
  return null;
}

String? _asPoint(Object? value) {
  if (value is Uint8List && value.isNotEmpty) return _hex(value);
  if (value is String && value.isNotEmpty) return value;
  return null;
}

String? _asWitness(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  if (value is Map || value is List) return jsonEncode(value);
  return null;
}

String _mint(String url) => url.trim().replaceAll(RegExp(r'/+$'), '');

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
