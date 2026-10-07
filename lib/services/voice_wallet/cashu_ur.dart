import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_ur/bc_ur.dart';

/// Sammelt die wechselnden `ur:`-Teile eines animierten Cashu-QR
/// (cashu.me) und liefert den Token-Text, sobald der Fountain-Code
/// vollstaendig ist. Ein einzelner `ur:bytes/…` ohne Zaehler gilt sofort.
class CashuUrCollector {
  final BCURFountainDecoder _decoder = BCURFountainDecoder();

  int get received => _decoder.receivedCount;

  int get expected => _decoder.expectedCount;

  /// [raw] darf der reine Teil oder ein laengerer Text sein.
  /// Liefert den Token, oder null solange noch Teile fehlen.
  String? add(String raw) {
    final part = urPart(raw);
    if (part == null) return null;
    final pieces = part.substring(3).split('/');
    try {
      if (pieces.length == 2) return _text(BCUR.fromString(part));
      if (pieces.length != 3) return null;
      _decoder.receivePart(part);
    } on ArgumentError catch (error) {
      final message = '${error.message}';
      if (!message.contains('Type mismatch')) return null;
      _decoder.reset();
      try {
        _decoder.receivePart(part);
      } on Object {
        return null;
      }
    } on Object {
      return null;
    }
    if (!_decoder.isComplete) return null;
    final ur = _decoder.getResult();
    if (ur == null) {
      _decoder.reset();
      return null;
    }
    return _text(ur);
  }
}

/// `ur:`-Anteil aus einem Kameratext, klein geschrieben, ohne Rand.
String? urPart(String raw) {
  final lower = raw.toLowerCase();
  final start = lower.indexOf('ur:');
  if (start < 0) return null;
  final tail = lower.substring(start);
  final cut = RegExp(r'\s').firstMatch(tail);
  var part = cut == null ? tail : tail.substring(0, cut.start);
  part = part.replaceAll(RegExp(r'[^a-z0-9:/-]+$'), '');
  if (!part.contains('/')) return null;
  return part;
}

String? _text(BCUR ur) {
  Object? decoded;
  try {
    decoded = ur.decodeData();
  } on Object {
    decoded = null;
  }
  final fromCbor = _asText(decoded);
  if (fromCbor != null && fromCbor.toLowerCase().contains('cashu')) {
    return fromCbor;
  }
  final raw = utf8.decode(ur.payload, allowMalformed: true);
  if (raw.toLowerCase().contains('cashu')) return raw;
  if (fromCbor != null && fromCbor.isNotEmpty) return fromCbor;
  return raw.isEmpty ? null : raw;
}

String? _asText(Object? data) {
  if (data is Uint8List) return utf8.decode(data, allowMalformed: true);
  if (data is String) return data;
  if (data is List<int>) return utf8.decode(data, allowMalformed: true);
  return null;
}
