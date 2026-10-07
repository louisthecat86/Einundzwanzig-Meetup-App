import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

/// Blindsignatur nach NUT-00, secp256k1.
///
/// `hash_to_curve` folgt der Fassung in cashu-ts: SHA256 über den
/// Domänentrenner und das UTF-8-Geheimnis, dann SHA256 mit einem
/// Little-Endian-Zähler, bis `02 || hash` auf der Kurve liegt.
class BlindedSecret {
  final String secret;
  final BigInt r;

  /// Geblendete Nachricht, komprimiert, hex.
  final String blinded;

  const BlindedSecret({
    required this.secret,
    required this.r,
    required this.blinded,
  });
}

final ECDomainParameters _curve = ECCurve_secp256k1();
final Uint8List _domain = Uint8List.fromList(
  'Secp256k1_HashToCurve_Cashu_'.codeUnits,
);

BlindedSecret blindSecret([Random? random]) {
  final rng = random ?? Random.secure();
  final secret = _hex(_randomBytes(rng, 32));
  final r = _randomScalar(rng);
  final y = hashToCurve(Uint8List.fromList(secret.codeUnits));
  final blinded = (y + (_curve.G * r))!;
  return BlindedSecret(secret: secret, r: r, blinded: encodePoint(blinded));
}

/// `C = C_ - r·K`. [mintKey] ist der öffentliche Schlüssel des Betrags.
/// Öffentlicher Mint-Schlüssel zu einem Betragsschlüssel. Nur für Tests.
String publicFromPrivate(BigInt privateKey) => encodePoint((_curve.G * privateKey)!);

/// Blindsignatur des Mints. Nur für Tests.
String signBlindedMessage({
  required String blinded,
  required BigInt privateKey,
}) =>
    encodePoint((decodePoint(blinded) * privateKey)!);

String unblindSignature({
  required String blindedSignature,
  required BigInt r,
  required String mintKey,
}) {
  final cBlind = decodePoint(blindedSignature);
  final k = decodePoint(mintKey);
  final c = (cBlind - (k * r)!)!;
  return encodePoint(c);
}

ECPoint hashToCurve(Uint8List secretUtf8) {
  final msg = Uint8List.fromList(sha256.convert([..._domain, ...secretUtf8]).bytes);
  final counter = Uint8List(4);
  final view = ByteData.sublistView(counter);
  for (var i = 0; i < 0x10000; i++) {
    view.setUint32(0, i, Endian.little);
    final hash = sha256.convert([...msg, ...counter]).bytes;
    final compressed = Uint8List(33);
    compressed[0] = 0x02;
    compressed.setRange(1, 33, hash);
    try {
      final point = _curve.curve.decodePoint(compressed);
      if (point != null && !point.isInfinity) return point;
    } catch (_) {}
  }
  throw StateError('Kein Kurvenpunkt für das Geheimnis.');
}

ECPoint decodePoint(String hex) {
  final bytes = _unhex(hex);
  final point = _curve.curve.decodePoint(Uint8List.fromList(bytes));
  if (point == null || point.isInfinity) {
    throw FormatException('Kein Kurvenpunkt.');
  }
  return point;
}

String encodePoint(ECPoint point) => _hex(point.getEncoded(true));

BigInt _randomScalar(Random random) {
  final n = _curve.n;
  while (true) {
    final r = BigInt.parse(_hex(_randomBytes(random, 32)), radix: 16) % n;
    if (r != BigInt.zero) return r;
  }
}

Uint8List _randomBytes(Random random, int n) =>
    Uint8List.fromList(List<int>.generate(n, (_) => random.nextInt(256)));

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _unhex(String hex) {
  final s = hex.trim().toLowerCase();
  if (s.length.isOdd || !RegExp(r'^[0-9a-f]+$').hasMatch(s)) {
    throw FormatException('Kein Hex.');
  }
  return List<int>.generate(
    s.length ~/ 2,
    (i) => int.parse(s.substring(i * 2, i * 2 + 2), radix: 16),
  );
}
