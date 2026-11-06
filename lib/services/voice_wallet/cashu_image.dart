import 'dart:convert';

import 'package:mobile_scanner/mobile_scanner.dart';

import 'cashu_token.dart';
import 'cashu_ur.dart';

/// Was ein einzelnes Bild hergibt. Ein wechselnder Code braucht mehrere
/// Bilder, ein Foto davon ist nur ein Teil.
class CashuPicture {
  final String? code;
  final bool partial;

  const CashuPicture({this.code, this.partial = false});
}

CashuPicture readCashuPicture(List<Barcode> barcodes) {
  final ur = CashuUrCollector();
  var sawPart = false;
  for (final barcode in barcodes) {
    final code = _text(barcode);
    if (code == null || code.isEmpty) continue;
    if (urPart(code) != null) {
      sawPart = true;
      final token = ur.add(code);
      if (token != null && token.isNotEmpty) return CashuPicture(code: token);
      continue;
    }
    if (_score(code) > 0 || cashuReadHint(code) == 'lightning') {
      return CashuPicture(code: code);
    }
  }
  if (sawPart) return const CashuPicture(partial: true);
  return const CashuPicture();
}

String? _text(Barcode barcode) {
  final options = <String>[];
  final raw = barcode.rawValue?.trim();
  if (raw != null && raw.isNotEmpty) options.add(raw);
  final bytes = barcode.rawBytes;
  if (bytes != null && bytes.isNotEmpty) {
    options.add(utf8.decode(bytes, allowMalformed: true));
  }
  String? best;
  var bestScore = -1;
  for (final option in options) {
    final score = _score(option);
    if (score > bestScore) {
      best = option;
      bestScore = score;
    }
  }
  if (bestScore > 0) return best;
  return options.isEmpty ? null : options.first;
}

int _score(String text) {
  final match = RegExp(r'cashu[ABab]', caseSensitive: false).firstMatch(text);
  if (match == null) return 0;
  return text.length - match.start;
}
