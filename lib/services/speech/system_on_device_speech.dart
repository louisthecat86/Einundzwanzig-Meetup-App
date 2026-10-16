import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'on_device_speech.dart';

/// System-Erkennung, und nur die Variante auf dem Geraet.
///
/// iPhone: `requiresOnDeviceRecognition`. Fehlt die Sprache, schlaegt die
/// Aufnahme fehl, statt zu Apple zu gehen.
///
/// Android bleibt zu. Das Plugin faellt dort auf den normalen Erkenner
/// zurueck, wenn das Offline-Paket fehlt, und der spricht mit Google.
/// Lieber stumm als eine Aufnahme, die das Telefon verlaesst.
class SystemOnDeviceSpeech implements OnDeviceSpeech {
  SystemOnDeviceSpeech({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;
  bool _ready = false;

  @override
  Future<SpeechFailure?> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  }) async {
    if (kIsWeb || !Platform.isIOS) return SpeechFailure.unavailable;

    if (!_ready) {
      final ok = await _speech.initialize(
        onError: (_) {},
        // Kein Debug-Log: der Text der Aufnahme gehoert nicht ins Protokoll.
        debugLogging: false,
      );
      if (!ok) return SpeechFailure.denied;
      _ready = true;
    }

    try {
      await _speech.listen(
        onResult: (result) => onWords(result.recognizedWords, result.finalResult),
        listenOptions: SpeechListenOptions(
          onDevice: true,
          listenMode: ListenMode.confirmation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: false,
          pauseFor: const Duration(seconds: 3),
          listenFor: const Duration(seconds: 8),
          localeId: localeId,
        ),
      );
    } on ListenFailedException {
      await _speech.cancel();
      return SpeechFailure.unavailable;
    }
    return null;
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}

/// Locale der Erkennung. Nur Deutsch und Englisch — die Sprachen, fuer die
/// wir Befehle verstehen. Die App-Sprache Spanisch hoert Englisch.
String onDeviceSpeechLocale(String languageCode) {
  switch (languageCode) {
    case 'de':
      return 'de_DE';
    default:
      return 'en_US';
  }
}
