import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'on_device_voice.dart';
import 'voice_choice.dart';

/// Systemstimme des iPhones. Android bleibt stumm: dort kann die Stimme
/// ins Netz ausweichen, und die Wallet sagt ihre Sätze nicht laut.
class SystemOnDeviceVoice implements OnDeviceVoice {
  SystemOnDeviceVoice({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  String? _voiceLanguage;
  PhoneVoice? _voice;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    final spoken = text.trim();
    if (spoken.isEmpty || kIsWeb || !Platform.isIOS) return;
    try {
      await _tts.stop();
      // Das Mikrofon gibt die Tonausgabe erst kurz danach frei.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
      );
      await _tts.setSpeechRate(0.5);
      await _tts.awaitSpeakCompletion(true);
      await _useVoice(_language(languageCode));
      await _tts.speak(spoken);
    } on Object {
      // Die Anzeige bleibt. Was gesagt werden sollte, steht nicht im Log.
    }
  }

  Future<void> _useVoice(String language) async {
    if (_voiceLanguage != language) {
      _voiceLanguage = language;
      _voice = pickPhoneVoice(await _tts.getVoices, language);
    }
    final voice = _voice;
    if (voice == null) {
      await _tts.setLanguage(language);
      return;
    }
    final chosen = await _tts.setVoice({
      'name': voice.name,
      'locale': voice.locale,
      'identifier': voice.identifier,
    });
    if (chosen != 1) await _tts.setLanguage(language);
  }

  @override
  Future<void> stop() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _tts.stop();
    } on Object {
      // Nichts zu sagen.
    }
  }

  String _language(String languageCode) {
    switch (languageCode) {
      case 'de':
        return 'de-DE';
      case 'es':
        return 'es-ES';
      default:
        return 'en-US';
    }
  }
}
