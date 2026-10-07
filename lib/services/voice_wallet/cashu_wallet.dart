import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'cashu_crypto.dart';
import 'cashu_mint.dart';
import 'cashu_token.dart';

/// Proofs liegen im Schlüsselbund. Sie sind das Guthaben: weg damit, weg
/// das Geld. Getauscht wird vor dem Speichern, damit ein gescannter Token
/// nicht beim Absender liegen bleibt und ein verschickter Betrag hier
/// nicht doppelt existiert.
class StoredProof {
  final String mint;
  final CashuProof proof;

  const StoredProof({required this.mint, required this.proof});
}

abstract class ProofStore {
  Future<List<StoredProof>> load();
  Future<void> save(List<StoredProof> proofs);
}

class SecureProofStore implements ProofStore {
  SecureProofStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'voice_cashu_proofs_v1';
  final FlutterSecureStorage _storage;

  @override
  Future<List<StoredProof>> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return const [];
    final json = jsonDecode(raw);
    if (json is! Map || json['proofs'] is! List) return const [];
    return [
      for (final item in json['proofs'] as List)
        if (item is Map && item['mint'] is String && item['proof'] is Map)
          StoredProof(
            mint: item['mint'] as String,
            proof: CashuProof(
              amount: item['proof']['amount'] as int,
              id: item['proof']['id'] as String,
              secret: item['proof']['secret'] as String,
              c: item['proof']['C'] as String,
              witness: item['proof']['witness'] as String?,
            ),
          ),
    ];
  }

  @override
  Future<void> save(List<StoredProof> proofs) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        'v': 1,
        'proofs': [
          for (final stored in proofs)
            {'mint': stored.mint, 'proof': stored.proof.toJson()},
        ],
      }),
    );
  }
}

class MemoryProofStore implements ProofStore {
  List<StoredProof> proofs = [];

  @override
  Future<List<StoredProof>> load() async => List.of(proofs);

  @override
  Future<void> save(List<StoredProof> proofs) async {
    this.proofs = List.of(proofs);
  }
}

class CashuReceive {
  final int received;
  final int balance;

  const CashuReceive({required this.received, required this.balance});
}

class CashuSend {
  final String token;
  final int amount;
  final int balance;

  const CashuSend({
    required this.token,
    required this.amount,
    required this.balance,
  });
}

class CashuWallet {
  CashuWallet({ProofStore? store, CashuMintClient? mint})
      : _store = store ?? SecureProofStore(),
        _mint = mint ?? HttpsCashuMint();

  final ProofStore _store;
  final CashuMintClient _mint;
  Future<void> _tail = Future.value();

  Future<int> balance() {
    return _locked(() async {
      final proofs = await _store.load();
      return proofs.fold<int>(0, (sum, p) => sum + p.proof.amount);
    });
  }

  /// Löst einen Token beim Mint ein und legt die neuen Proofs hier ab.
  Future<CashuReceive> receive(String raw) {
    return _locked(() async {
      final tokens = _readTokens(raw);
      var have = await _store.load();
      final secrets = have.map((p) => p.proof.secret).toSet();
      var received = 0;
      CashuException? failure;
      for (final token in tokens) {
        if (token.proofs.any((p) => secrets.contains(p.secret))) {
          failure = const CashuException(CashuFail.already);
          break;
        }
        try {
          final fresh = await _swapIn(
            mintUrl: token.mint,
            inputs: token.proofs,
          );
          have = [...have, for (final proof in fresh) StoredProof(mint: token.mint, proof: proof)];
          for (final proof in fresh) {
            secrets.add(proof.secret);
          }
          received += fresh.fold<int>(0, (sum, p) => sum + p.amount);
          await _store.save(have);
        } on CashuException catch (e) {
          failure = e;
          break;
        }
      }
      if (received == 0) {
        throw failure ?? CashuException(CashuFail.badToken, detail: cashuReadHint(raw));
      }
      return CashuReceive(
        received: received,
        balance: have.fold<int>(0, (sum, p) => sum + p.proof.amount),
      );
    });
  }

  /// Tauscht [amount] Satoshi in einen neuen Token. Der Rest bleibt hier.
  Future<CashuSend> send(int amount) {
    return _locked(() async {
      if (amount <= 0) throw const CashuException(CashuFail.notEnough);
      final have = await _store.load();
      final byMint = <String, List<StoredProof>>{};
      for (final stored in have) {
        byMint.putIfAbsent(stored.mint, () => []).add(stored);
      }
      final mints = byMint.keys.toList()
        ..sort((a, b) => _sum(byMint[b]!).compareTo(_sum(byMint[a]!)));

      CashuException? failure;
      for (final mint in mints) {
        final pile = byMint[mint]!;
        if (_sum(pile) < amount) continue;
        try {
          final snapshot = await _snapshotFor(mint, [for (final stored in pile) stored.proof]);
          final picked = _pick(pile, amount, snapshot);
          if (picked == null) continue;
          final inputs = picked.map((p) => _withFullId(p.proof, snapshot)).toList();
          final fee = _fee(inputs, snapshot);
          final inputSum = inputs.fold<int>(0, (sum, p) => sum + p.amount);
          final change = inputSum - amount - fee;
          if (change < 0) continue;

          final swapped = await _swap(
            mintUrl: mint,
            snapshot: snapshot,
            inputs: inputs,
            give: amount,
            change: change,
          );
          final spent = picked.map((p) => p.proof.secret).toSet();
          final next = [
            for (final stored in have)
              if (!spent.contains(stored.proof.secret)) stored,
            for (final proof in swapped.change)
              StoredProof(mint: mint, proof: proof),
          ];
          await _store.save(next);
          return CashuSend(
            token: encodeCashuToken(mint: mint, proofs: swapped.give),
            amount: amount,
            balance: next.fold<int>(0, (sum, p) => sum + p.proof.amount),
          );
        } on CashuException catch (e) {
          if (e.fail == CashuFail.notEnough) continue;
          failure = e;
        }
      }
      throw failure ?? const CashuException(CashuFail.notEnough);
    });
  }

  Future<List<CashuProof>> _swapIn({
    required String mintUrl,
    required List<CashuProof> inputs,
  }) async {
    final snapshot = await _snapshotFor(mintUrl, inputs);
    final full = inputs.map((p) => _withFullId(p, snapshot)).toList();
    final fee = _fee(full, snapshot);
    final output = full.fold<int>(0, (sum, p) => sum + p.amount) - fee;
    if (output <= 0) throw const CashuException(CashuFail.feeTooHigh);
    final swapped = await _swap(
      mintUrl: mintUrl,
      snapshot: snapshot,
      inputs: full,
      give: output,
      change: 0,
    );
    return swapped.give;
  }

  Future<({List<CashuProof> give, List<CashuProof> change})> _swap({
    required String mintUrl,
    required MintSnapshot snapshot,
    required List<CashuProof> inputs,
    required int give,
    required int change,
  }) async {
    final outs = <_Out>[
      for (final amount in splitCashuAmount(give, snapshot.keys.keys.toSet()))
        _Out(amount, true),
      for (final amount in splitCashuAmount(change, snapshot.keys.keys.toSet()))
        _Out(amount, false),
    ]..sort((a, b) => a.amount.compareTo(b.amount));

    final signatures = await _mint.swap(
      mintUrl: mintUrl,
      inputs: inputs,
      outputs: [
        for (final out in outs)
          BlindedOutput(
            amount: out.amount,
            id: snapshot.activeId,
            blinded: out.blinded.blinded,
          ),
      ],
    );
    final giveProofs = <CashuProof>[];
    final changeProofs = <CashuProof>[];
    for (var i = 0; i < outs.length; i++) {
      final out = outs[i];
      final signature = signatures[i];
      final key = snapshot.keys[out.amount];
      if (key == null || signature.amount != out.amount) {
        throw const CashuException(CashuFail.mintRejected);
      }
      final String unblinded;
      try {
        unblinded = unblindSignature(
          blindedSignature: signature.cBlind,
          r: out.blinded.r,
          mintKey: key,
        );
      } on FormatException {
        throw const CashuException(CashuFail.mintRejected);
      }
      final proof = CashuProof(
        amount: out.amount,
        id: signature.id,
        secret: out.blinded.secret,
        c: unblinded,
      );
      (out.give ? giveProofs : changeProofs).add(proof);
    }
    return (give: giveProofs, change: changeProofs);
  }

  Future<MintSnapshot> _snapshotFor(String mintUrl, List<CashuProof> inputs) async {
    var snapshot = await _mint.snapshot(mintUrl);
    for (final proof in inputs) {
      if (snapshot.resolveKeyset(proof.id) != null) continue;
      final found = await _mint.identifyKeyset(mintUrl, proof.id);
      if (found == null) continue;
      snapshot = snapshot.addKeyset(found.id, found.ppk);
    }
    return snapshot;
  }

  CashuProof _withFullId(CashuProof proof, MintSnapshot snapshot) {
    final id = snapshot.resolveKeyset(proof.id) ?? proof.id;
    if (id == proof.id) return proof;
    return CashuProof(
      amount: proof.amount,
      id: id,
      secret: proof.secret,
      c: proof.c,
      witness: proof.witness,
    );
  }

  int _fee(List<CashuProof> inputs, MintSnapshot snapshot) {
    var ppk = 0;
    for (final proof in inputs) {
      ppk += _ppk(snapshot, proof.id);
    }
    return (ppk + 999) ~/ 1000;
  }

  int _ppk(MintSnapshot snapshot, String id) {
    final direct = snapshot.feePpk[id];
    if (direct != null) return direct;
    final want = id.toLowerCase();
    for (final entry in snapshot.feePpk.entries) {
      if (entry.key.toLowerCase() == want) return entry.value;
    }
    return 0;
  }

  List<StoredProof>? _pick(List<StoredProof> pile, int amount, MintSnapshot snapshot) {
    final sorted = [...pile]..sort((a, b) => b.proof.amount.compareTo(a.proof.amount));
    final picked = <StoredProof>[];
    var sum = 0;
    for (final stored in sorted) {
      picked.add(stored);
      sum += stored.proof.amount;
      final fee = _fee(
        picked.map((p) => _withFullId(p.proof, snapshot)).toList(),
        snapshot,
      );
      if (sum - fee >= amount) return picked;
    }
    return null;
  }

  int _sum(List<StoredProof> proofs) =>
      proofs.fold<int>(0, (sum, p) => sum + p.proof.amount);

  List<CashuToken> _readTokens(String raw) {
    final List<CashuToken> all;
    try {
      all = parseCashuTokens(raw);
    } on FormatException {
      throw CashuException(CashuFail.badToken, detail: cashuReadHint(raw));
    }
    final sat = all.where((token) => token.unit.toLowerCase() == 'sat' && token.proofs.isNotEmpty).toList();
    if (sat.isEmpty) {
      throw CashuException(
        all.isEmpty ? CashuFail.badToken : CashuFail.unsupportedUnit,
        detail: cashuReadHint(raw),
      );
    }
    return sat;
  }

  Future<T> _locked<T>(Future<T> Function() run) {
    final previous = _tail;
    final gate = Completer<void>();
    _tail = gate.future;
    return previous.then((_) => run()).whenComplete(gate.complete);
  }
}

class _Out {
  final int amount;
  final bool give;
  final BlindedSecret blinded = blindSecret();

  _Out(this.amount, this.give);
}

/// Zerlegt einen Betrag in Stücke, für die der Mint einen Schlüssel hat.
List<int> splitCashuAmount(int amount, Set<int> denominations) {
  if (amount == 0) return const [];
  if (amount < 0) throw const CashuException(CashuFail.notEnough);
  final denoms = denominations.where((d) => d > 0).toList()..sort((a, b) => b.compareTo(a));
  final out = <int>[];
  var left = amount;
  for (final denom in denoms) {
    while (left >= denom) {
      out.add(denom);
      left -= denom;
    }
  }
  if (left != 0) throw const CashuException(CashuFail.notEnough);
  return out;
}
