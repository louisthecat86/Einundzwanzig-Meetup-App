import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cashu_token.dart';

enum CashuFail {
  badToken,
  badMint,
  unknownKeyset,
  unsupportedUnit,
  feeTooHigh,
  noSatKey,
  spent,
  already,
  notEnough,
  network,
  mintRejected,
}

class CashuException implements Exception {
  final CashuFail fail;

  /// Kurz und ohne Geheimnis, z. B. `B:840` oder `lightning`.
  final String? detail;

  const CashuException(this.fail, {this.detail});
}

abstract class CashuMintClient {
  Future<MintSnapshot> snapshot(String mintUrl);
  Future<List<BlindSignature>> swap({
    required String mintUrl,
    required List<CashuProof> inputs,
    required List<BlindedOutput> outputs,
  });

  /// Keyset nachladen, wenn die Liste nur die lange ID kennt und der
  /// Token die kurze schickt. `null`, wenn der Mint dazu nichts sagt.
  Future<({String id, int ppk})?> identifyKeyset(String mintUrl, String id);
}

/// Aktive Schlüssel und Gebühren eines Mints.
class MintSnapshot {
  final String activeId;
  final Map<int, String> keys;
  final Map<String, int> feePpk;
  final Set<String> keysetIds;

  const MintSnapshot({
    required this.activeId,
    required this.keys,
    required this.feePpk,
    required this.keysetIds,
  });

  MintSnapshot addKeyset(String id, int ppk) {
    return MintSnapshot(
      activeId: activeId,
      keys: keys,
      feePpk: {...feePpk, id: ppk},
      keysetIds: {...keysetIds, id},
    );
  }

  /// Volle Keyset-ID zum Token. `null`, wenn sie in der Liste fehlt.
  /// Mehrdeutig ist ein Fehler, sonst würde der falsche Satz signiert.
  String? resolveKeyset(String id) {
    if (keysetIds.contains(id)) return id;
    if (!_hexId(id)) return null;
    final want = id.toLowerCase();
    final exact = [
      for (final known in keysetIds)
        if (_hexId(known) && known.toLowerCase() == want) known,
    ];
    if (exact.isNotEmpty) return exact.first;
    final matches = [
      for (final known in keysetIds)
        if (_hexId(known) && _sameKeyset(want, known.toLowerCase())) known,
    ];
    if (matches.length == 1) return matches.single;
    if (matches.length > 1) throw const CashuException(CashuFail.unknownKeyset);
    return null;
  }
}

bool _hexId(String id) => RegExp(r'^[0-9a-fA-F]+$').hasMatch(id) && id.length.isEven;

bool _sameKeyset(String a, String b) {
  if (a == b) return true;
  final short = a.length < b.length ? a : b;
  final long = a.length < b.length ? b : a;
  return short.length >= 16 && long.startsWith(short);
}

class BlindedOutput {
  final int amount;
  final String id;
  final String blinded;

  const BlindedOutput({
    required this.amount,
    required this.id,
    required this.blinded,
  });
}

class BlindSignature {
  final int amount;
  final String id;
  final String cBlind;

  const BlindSignature({
    required this.amount,
    required this.id,
    required this.cBlind,
  });
}

/// Spricht mit einem Cashu-Mint. Nur die Rufe, die Einlösen und
/// Weitergeben brauchen: Schlüssel und Tausch. http bleibt erlaubt,
/// weil die Mint-Adresse im Token steht und oft kein TLS hat.
Uri cashuMintBase(String mintUrl) {
  final uri = Uri.tryParse(mintUrl.trim());
  if (uri == null || uri.host.isEmpty || (uri.scheme != 'https' && uri.scheme != 'http')) {
    throw const CashuException(CashuFail.badMint);
  }
  return uri;
}
class HttpsCashuMint implements CashuMintClient {
  HttpsCashuMint({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<MintSnapshot> snapshot(String mintUrl) async {
    final base = _base(mintUrl);
    final keysets = await _get(base, '/v1/keysets');
    final keys = await _get(base, '/v1/keys');
    final listed = keysets['keysets'];
    final activeSets = keys['keysets'];
    if (listed is! List || activeSets is! List) {
      throw const CashuException(CashuFail.mintRejected);
    }

    final fee = <String, int>{};
    final ids = <String>{};
    for (final item in listed) {
      if (item is! Map) continue;
      final id = item['id'];
      if (id is! String) continue;
      ids.add(id);
      final ppk = item['input_fee_ppk'];
      fee[id] = ppk is int ? ppk : 0;
    }

    Map<String, Object?>? active;
    for (final item in activeSets) {
      if (item is! Map) continue;
      final unit = item['unit'];
      final unitText = unit is String ? unit.trim().toLowerCase() : null;
      if (unitText == null || unitText == 'sat') {
        active = item.cast<String, Object?>();
        break;
      }
    }
    if (active == null) throw const CashuException(CashuFail.noSatKey);
    final id = active['id'];
    final rawKeys = active['keys'];
    if (id is! String || rawKeys is! Map) {
      throw const CashuException(CashuFail.mintRejected);
    }
    final decoded = <int, String>{};
    for (final entry in rawKeys.entries) {
      final amount = int.tryParse(entry.key.toString());
      final point = entry.value;
      if (amount == null || amount <= 0 || point is! String) continue;
      decoded[amount] = point;
    }
    if (decoded.isEmpty) throw const CashuException(CashuFail.mintRejected);
    ids.add(id);
    return MintSnapshot(activeId: id, keys: decoded, feePpk: fee, keysetIds: ids);
  }

  @override
  Future<List<BlindSignature>> swap({
    required String mintUrl,
    required List<CashuProof> inputs,
    required List<BlindedOutput> outputs,
  }) async {
    final body = await _post(_base(mintUrl), '/v1/swap', {
      'inputs': inputs.map((p) => p.toJson()).toList(),
      'outputs': [
        for (final output in outputs)
          {'amount': output.amount, 'id': output.id, 'B_': output.blinded},
      ],
    });
    final signatures = body['signatures'];
    if (signatures is! List || signatures.length != outputs.length) {
      throw const CashuException(CashuFail.mintRejected);
    }
    return [
      for (final item in signatures)
        if (item is Map && item['C_'] is String && item['amount'] is int && item['id'] is String)
          BlindSignature(
            amount: item['amount'] as int,
            id: item['id'] as String,
            cBlind: item['C_'] as String,
          )
        else
          throw const CashuException(CashuFail.mintRejected),
    ];
  }

  @override
  Future<({String id, int ppk})?> identifyKeyset(String mintUrl, String id) async {
    final http.Response response;
    try {
      final base = _base(mintUrl);
      response = await _send(http.Request(
        'GET',
        base.replace(path: _join(base.path, '/v1/keys/${Uri.encodeComponent(id)}')),
      ));
    } on CashuException {
      return null;
    }
    if (response.statusCode != 200) return null;
    Object? json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      return null;
    }
    if (json is! Map) return null;
    final sets = json['keysets'];
    if (sets is! List) return null;
    for (final item in sets) {
      if (item is! Map) continue;
      final found = item['id'];
      if (found is! String || found.isEmpty) continue;
      final trial = MintSnapshot(
        activeId: found,
        keys: const {},
        feePpk: const {},
        keysetIds: {found},
      );
      if (trial.resolveKeyset(id) != found) continue;
      final ppk = item['input_fee_ppk'];
      return (id: found, ppk: ppk is int ? ppk : 0);
    }
    return null;
  }

  Uri _base(String mintUrl) => cashuMintBase(mintUrl);

  Future<Map<String, Object?>> _get(Uri base, String path) async {
    return _read(await _send(http.Request('GET', base.replace(path: _join(base.path, path)))));
  }

  Future<Map<String, Object?>> _post(Uri base, String path, Object body) async {
    final request = http.Request('POST', base.replace(path: _join(base.path, path)));
    request.headers['content-type'] = 'application/json';
    request.body = jsonEncode(body);
    return _read(await _send(request));
  }

  Future<http.Response> _send(http.Request request) async {
    try {
      final streamed = await _http.send(request).timeout(const Duration(seconds: 20));
      return await http.Response.fromStream(streamed);
    } catch (_) {
      throw const CashuException(CashuFail.network);
    }
  }

  Map<String, Object?> _read(http.Response response) {
    Object? json;
    try {
      json = jsonDecode(response.body);
    } catch (_) {
      json = null;
    }
    if (response.statusCode != 200 || json is! Map) {
      final detail = json is Map ? json['detail'] : null;
      if (detail is String && detail.toLowerCase().contains('spent')) {
        throw const CashuException(CashuFail.spent);
      }
      throw const CashuException(CashuFail.mintRejected);
    }
    return json.cast<String, Object?>();
  }

  String _join(String prefix, String path) {
    final left = prefix.endsWith('/') ? prefix.substring(0, prefix.length - 1) : prefix;
    return '$left$path';
  }
}
