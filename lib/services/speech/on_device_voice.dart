/// Stimme auf dem Gerät. Der Text verlässt das Telefon nicht.
abstract class OnDeviceVoice {
  Future<void> speak(String text, {required String languageCode});

  Future<void> stop();
}
