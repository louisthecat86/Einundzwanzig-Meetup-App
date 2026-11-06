import 'dart:io';

import 'package:flutter/services.dart';

/// Bild aus der Zwischenablage, als Datei. Text liest Flutter selbst.
class ClipboardPicture {
  static const _channel = MethodChannel('einundzwanzig/pasteboard');

  static Future<String?> file() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('image');
      final Uint8List? bytes = switch (raw) {
        Uint8List data => data,
        ByteData data => data.buffer.asUint8List(),
        _ => null,
      };
      if (bytes == null || bytes.isEmpty) return null;
      final path = '${Directory.systemTemp.path}/voice_cashu_clip.png';
      await File(path).writeAsBytes(bytes, flush: true);
      return path;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
