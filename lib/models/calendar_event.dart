import 'package:icalendar_parser/icalendar_parser.dart';

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

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    // Standard-Fallback (falls alles schiefgeht): Datum in der Zukunft
    DateTime start = DateTime.now().add(const Duration(days: 365));

    try {
      final dtStart = map['dtstart'];

      // VARIANTE A: Das Paket hat das Datum schon erkannt
      if (dtStart is IcsDateTime) {
        // .toLocal() ist hier wichtig!
        start = dtStart.toDateTime()?.toLocal() ?? start;
      } 
      // VARIANTE B: Wir müssen den String selbst zerlegen (häufigster Fall)
      else if (dtStart is String) {
        // Wir entfernen alles, was keine Zahl ist (z.B. T, Z, -)
        // Beispiel Input: "20260210T173000Z" -> "20260210173000"
        String s = dtStart.replaceAll(RegExp(r'[^0-9]'), ''); 
        
        if (s.length >= 8) {
          int y = int.parse(s.substring(0, 4));
          int m = int.parse(s.substring(4, 6));
          int d = int.parse(s.substring(6, 8));
          int h = 19; // Fallback, falls keine Uhrzeit dabei ist
          int min = 0;

          // Wenn Uhrzeit dabei ist (String ist lang genug)
          if (s.length >= 12) {
             h = int.parse(s.substring(8, 10));
             min = int.parse(s.substring(10, 12));
          }

          // DER ENTSCHEIDENDE FIX:
          // 1. Wir erstellen das Datum als UTC (Weltzeit) -> DateTime.utc(...)
          // 2. Wir wandeln es sofort in Lokale Zeit um -> .toLocal()
          start = DateTime.utc(y, m, d, h, min).toLocal();
        }
      }
    } catch (e) {
      print("PARSE ERROR: $e");
    }

    // Beschreibung säubern (Zeilenumbrüche fixen)
    String rawDesc = map['description']?.toString() ?? '';
    String cleanDesc = rawDesc
        .replaceAll('\\n', '\n')
        .replaceAll('\\', '')
        .replaceAll('\,', ',');

    return CalendarEvent(
      title: map['summary']?.toString() ?? 'Meetup',
      description: cleanDesc,
      location: map['location']?.toString() ?? 'Ort unbekannt',
      startTime: start,
      url: '',
    );
  }
}