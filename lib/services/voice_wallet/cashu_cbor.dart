import 'dart:convert';
import 'dart:typed_data';

/// CBOR für einen Cashu-V4-Token. Feste Längen, dazu Tags (werden
/// ausgewickelt), negative Zahlen und die einfachen Werte, die in
/// optionalen Feldern vorkommen. Unbekannte Typen werfen.
Object? decodeCbor(Uint8List bytes) {
  final reader = _CborReader(bytes);
  return reader.read();
}

class _CborReader {
  _CborReader(this.bytes);

  final Uint8List bytes;
  int _i = 0;

  bool get done => _i >= bytes.length;

  Object? read() {
    if (_i >= bytes.length) {
      throw const FormatException('CBOR bricht mitten im Wert ab.');
    }
    final initial = bytes[_i++];
    final major = initial >> 5;
    final info = initial & 0x1f;
    switch (major) {
      case 0:
        return _argument(info);
      case 1:
        return -1 - _argument(info);
      case 2:
        if (info == 31) return Uint8List.fromList(_indefiniteChunks((v) => v is Uint8List ? v : null));
        return Uint8List.fromList(_bytes(_argument(info)));
      case 3:
        if (info == 31) {
          final chunks = _indefiniteChunks((v) => v is String ? utf8.encode(v) : null);
          return utf8.decode(chunks, allowMalformed: true);
        }
        return utf8.decode(_bytes(_argument(info)), allowMalformed: true);
      case 4:
        if (info == 31) return _untilBreak(read);
        final n = _argument(info);
        return List<Object?>.generate(n, (_) => read());
      case 5:
        if (info == 31) return _indefiniteMap();
        final n = _argument(info);
        return _readMap(n);
      case 6:
        _argument(info);
        return read();
      case 7:
        return _simple(info);
      default:
        throw FormatException('CBOR-Typ $major wird hier nicht gelesen.');
    }
  }

  Object? _simple(int info) {
    if (info == 20) return false;
    if (info == 21) return true;
    if (info == 22 || info == 23) return null;
    if (info == 24) {
      final value = _take(1);
      if (value == 20) return false;
      if (value == 21) return true;
      if (value == 22 || value == 23) return null;
      throw FormatException('CBOR-Wert $value wird hier nicht gelesen.');
    }
    if (info == 25) {
      final data = ByteData(4)..setUint32(0, _float16Bits(_take(2)));
      return data.getFloat32(0);
    }
    if (info == 26) {
      final data = ByteData(4)..setUint32(0, _take(4));
      return data.getFloat32(0);
    }
    if (info == 27) {
      final data = ByteData(8)..setUint64(0, _take(8));
      return data.getFloat64(0);
    }
    throw FormatException('CBOR-Typ 7 $info wird hier nicht gelesen.');
  }

  Map<String, Object?> _readMap(int n) {
    final map = <String, Object?>{};
    for (var i = 0; i < n; i++) {
      final key = read();
      final value = read();
      final name = _mapKey(key);
      if (name == null) continue;
      map[name] = value;
    }
    return map;
  }

  Map<String, Object?> _indefiniteMap() {
    final map = <String, Object?>{};
    while (!_atBreak()) {
      final key = read();
      final value = read();
      final name = _mapKey(key);
      if (name == null) continue;
      map[name] = value;
    }
    return map;
  }

  List<Object?> _untilBreak(Object? Function() next) {
    final list = <Object?>[];
    while (!_atBreak()) {
      list.add(next());
    }
    return list;
  }

  List<int> _indefiniteChunks(List<int>? Function(Object?) take) {
    final out = <int>[];
    while (!_atBreak()) {
      final chunk = take(read());
      if (chunk == null) {
        throw const FormatException('CBOR-Stück passt nicht.');
      }
      out.addAll(chunk);
    }
    return out;
  }

  bool _atBreak() {
    if (_i >= bytes.length) {
      throw const FormatException('CBOR bricht mitten im Wert ab.');
    }
    if (bytes[_i] != 0xff) return false;
    _i++;
    return true;
  }

  String? _mapKey(Object? key) {
    return switch (key) {
      String s => s,
      Uint8List b => utf8.decode(b, allowMalformed: true),
      int n => '$n',
      _ => null,
    };
  }

  int _argument(int info) {
    if (info < 24) return info;
    if (info == 24) return _take(1);
    if (info == 25) return _take(2);
    if (info == 26) return _take(4);
    if (info == 27) return _take(8);
    throw const FormatException('Unbestimmte CBOR-Länge.');
  }

  int _float16Bits(int bits) {
    final sign = (bits & 0x8000) << 16;
    final exp = (bits >> 10) & 0x1f;
    final frac = bits & 0x3ff;
    if (exp == 0) {
      if (frac == 0) return sign;
      var mantissa = frac;
      var exponent = -1;
      while ((mantissa & 0x400) == 0) {
        mantissa <<= 1;
        exponent--;
      }
      mantissa &= 0x3ff;
      final exp32 = exponent + 127;
      return sign | (exp32 << 23) | (mantissa << 13);
    }
    if (exp == 31) return sign | 0x7f800000 | (frac << 13);
    final exp32 = exp + (127 - 15);
    return sign | (exp32 << 23) | (frac << 13);
  }

  int _take(int width) {
    if (_i + width > bytes.length) {
      throw const FormatException('CBOR bricht in der Länge ab.');
    }
    var n = 0;
    for (var i = 0; i < width; i++) {
      n = (n << 8) | bytes[_i++];
    }
    return n;
  }

  List<int> _bytes(int length) {
    if (length < 0 || _i + length > bytes.length) {
      throw const FormatException('CBOR-Bytes reichen nicht.');
    }
    final out = bytes.sublist(_i, _i + length);
    _i += length;
    return out;
  }
}
