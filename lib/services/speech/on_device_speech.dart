// Gesprochene Wallet-Befehle.
//
// Die Seite kennt nur diese Schnittstelle. Was darunter hoert — heute die
// Systemerkennung, spaeter ein mitgeliefertes Modell — bleibt austauschbar.

/// Warum eine Aufnahme nicht gestartet wurde.
enum SpeechFailure {
  /// Keine Erkennung, die sicher auf dem Geraet bleibt.
  unavailable,

  /// Der Nutzer hat Mikrofon oder Spracherkennung abgelehnt.
  denied,
}

/// Eine Aufnahme, die das Geraet nicht verlaesst.
abstract class OnDeviceSpeech {
  /// Startet das Zuhoeren. [onWords] bekommt Zwischenergebnisse und am Ende
  /// den fertigen Satz. Gibt einen Fehler zurueck, wenn gar nicht aufgenommen
  /// wird — dann ist [onWords] nie aufgerufen worden.
  Future<SpeechFailure?> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onWords,
  });

  Future<void> stop();
}
