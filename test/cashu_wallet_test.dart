import 'dart:math';
import 'dart:typed_data';

import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_crypto.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_mint.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_token.dart';
import 'package:einundzwanzig_meetup_app/services/voice_wallet/cashu_wallet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Blenden und Entblenden heben sich auf', () {
    final key = BigInt.one;
    final pub = publicFromPrivate(key);
    final blinded = blindSecret(Random(1));
    final signature = signBlindedMessage(blinded: blinded.blinded, privateKey: key);
    final c = unblindSignature(blindedSignature: signature, r: blinded.r, mintKey: pub);
    final expected = signBlindedMessage(
      blinded: encodePoint(hashToCurve(Uint8List.fromList(blinded.secret.codeUnits))),
      privateKey: key,
    );
    expect(c, expected);
  });

  test('Einlösen und Weitergeben über einen Mint', () async {
    final mint = _FakeMint();
    final alice = CashuWallet(store: MemoryProofStore(), mint: mint);
    final bob = CashuWallet(store: MemoryProofStore(), mint: mint);
    final original = encodeCashuToken(
      mint: 'https://mint.test',
      proofs: [mint.issue(8), mint.issue(32)],
    );

    final received = await alice.receive(original);
    expect(received.received, 40);
    expect(await alice.balance(), 40);
    expect(
      () => alice.receive(original),
      throwsA(isA<CashuException>().having((e) => e.fail, 'fail', CashuFail.spent)),
    );

    final sent = await alice.send(21);
    expect(sent.amount, 21);
    expect(sent.balance, 19);
    expect(await alice.balance(), 19);

    final taken = await bob.receive(sent.token);
    expect(taken.received, 21);
    expect(await bob.balance(), 21);
    expect(
      () => bob.receive(sent.token),
      throwsA(isA<CashuException>().having((e) => e.fail, 'fail', CashuFail.spent)),
    );
  });

  test('Zu wenig Guthaben wird nicht verschickt', () async {
    final mint = _FakeMint();
    final wallet = CashuWallet(store: MemoryProofStore(), mint: mint);
    await wallet.receive(encodeCashuToken(
      mint: 'https://mint.test',
      proofs: [mint.issue(4)],
    ));
    expect(
      () => wallet.send(5),
      throwsA(isA<CashuException>().having((e) => e.fail, 'fail', CashuFail.notEnough)),
    );
    expect(await wallet.balance(), 4);
  });

  test('Token im Link, http-Mint und kurze Keyset-ID', () async {
    expect(cashuMintBase('http://localhost:3338').scheme, 'http');
    expect(
      () => cashuMintBase('notaurl'),
      throwsA(isA<CashuException>().having((e) => e.fail, 'fail', CashuFail.badMint)),
    );

    const full = '0184237e63ce3423DF7DB2DCEDC7329C';
    final snapshot = MintSnapshot(
      activeId: full,
      keys: const {1: '02'},
      feePpk: {full: 0},
      keysetIds: {full, '${full}AA'},
    );
    expect(
      () => snapshot.resolveKeyset('0184237e63ce3423'),
      throwsA(isA<CashuException>().having((e) => e.fail, 'fail', CashuFail.unknownKeyset)),
    );
    expect(snapshot.resolveKeyset(full.toLowerCase()), full);
    final unique = MintSnapshot(
      activeId: full,
      keys: const {1: '02'},
      feePpk: {full: 0},
      keysetIds: {full},
    );
    expect(unique.resolveKeyset('0184237e63ce3423'), full);

    final mint = _FakeMint();
    final wallet = CashuWallet(store: MemoryProofStore(), mint: mint);
    final proof = mint.issue(8);
    final token = encodeCashuToken(
      mint: 'http://mint.local',
      proofs: [
        CashuProof(
          amount: proof.amount,
          id: proof.id,
          secret: proof.secret,
          c: proof.c,
          witness: '{"signatures":[]}',
        ),
      ],
    );
    final received = await wallet.receive('schau mal $token danke');
    expect(received.received, 8);
  });
}

class _FakeMint implements CashuMintClient {
  final BigInt key = BigInt.parse('7', radix: 16);
  late final String pub = publicFromPrivate(key);
  final Set<String> spent = {};

  CashuProof issue(int amount) {
    final blinded = blindSecret();
    final signature = signBlindedMessage(blinded: blinded.blinded, privateKey: key);
    return CashuProof(
      amount: amount,
      id: '00',
      secret: blinded.secret,
      c: unblindSignature(blindedSignature: signature, r: blinded.r, mintKey: pub),
    );
  }

  @override
  Future<({String id, int ppk})?> identifyKeyset(String mintUrl, String id) async => null;

  @override
  Future<MintSnapshot> snapshot(String mintUrl) async {
    return MintSnapshot(
      activeId: '00',
      keys: {for (var bit = 0; bit <= 12; bit++) 1 << bit: pub},
      feePpk: const {'00': 0},
      keysetIds: const {'00'},
    );
  }

  @override
  Future<List<BlindSignature>> swap({
    required String mintUrl,
    required List<CashuProof> inputs,
    required List<BlindedOutput> outputs,
  }) async {
    final inSum = inputs.fold(0, (sum, p) => sum + p.amount);
    final outSum = outputs.fold(0, (sum, p) => sum + p.amount);
    if (inSum != outSum) throw const CashuException(CashuFail.mintRejected);
    for (final input in inputs) {
      if (!spent.add(input.secret)) throw const CashuException(CashuFail.spent);
      final expected = signBlindedMessage(
        blinded: encodePoint(hashToCurve(Uint8List.fromList(input.secret.codeUnits))),
        privateKey: key,
      );
      // expected ist k·Y, nicht eine Blindsignatur. Direkt vergleichen.
      if (expected != input.c) {
        spent.remove(input.secret);
        throw const CashuException(CashuFail.mintRejected);
      }
    }
    return [
      for (final output in outputs)
        BlindSignature(
          amount: output.amount,
          id: '00',
          cBlind: signBlindedMessage(blinded: output.blinded, privateKey: key),
        ),
    ];
  }
}
