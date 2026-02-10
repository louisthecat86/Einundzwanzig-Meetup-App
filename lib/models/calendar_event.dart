class CalendarEvent {
  final String title;
  final String description;
  final String location;
  final DateTime startTime;
  final String url;

  CalendarEvent({
    required this.title,
    required this.description,
    required this.location,
    required this.startTime,
    required this.url,
  });

  // Diese Funktion verwandelt den iCal-Müll in ein sauberes Objekt
  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    // 1. Datum parsen (Format: 20240520T180000)
    DateTime start = DateTime.now();
    try {
      String dtString = map['dtstart']?.toString() ?? '';
      if (dtString.length >= 8) {
        // Jahr, Monat, Tag extrahieren
        String y = dtString.substring(0, 4);
        String m = dtString.substring(4, 6);
        String d = dtString.substring(6, 8);
        String h = '00';
        String min = '00';
        
        // Uhrzeit extrahieren (falls vorhanden und mit T getrennt)
        if (dtString.contains('T') && dtString.length >= 13) {
          int tIndex = dtString.indexOf('T');
          h = dtString.substring(tIndex + 1, tIndex + 3);
          min = dtString.substring(tIndex + 3, tIndex + 5);
        }
        start = DateTime.parse('$y-$m-$d $h:$min:00');
      }
    } catch (e) {
      print("Datum konnte nicht geparst werden: $e");
    }

    // 2. Text säubern (Backslashes entfernen)
    String rawDesc = map['description']?.toString() ?? '';
    // Entferne typische iCal Escape Characters
    String cleanDesc = rawDesc.replaceAll('\\n', '\n').replaceAll('\\', '');

    return CalendarEvent(
      title: map['summary']?.toString() ?? 'Meetup',
      description: cleanDesc,
      location: map['location']?.toString() ?? 'Ort unbekannt',
      startTime: start,
      url: '', // Könnte man aus der Description parsen, falls nötig
    );
  }
}