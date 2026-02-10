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
    DateTime start = DateTime.now().add(const Duration(days: 365)); // Fallback

    try {
      final dtStart = map['dtstart'];

      // Fall A: Das Paket hat es schon erkannt
      if (dtStart is IcsDateTime) {
        start = dtStart.toDateTime() ?? start;
      } 
      // Fall B: String parsen (Manuell & Robust)
      else if (dtStart is String) {
        // Bereinigen: "20260210T183000Z" -> "20260210183000"
        String s = dtStart.replaceAll(RegExp(r'[^0-9]'), ''); 
        
        if (s.length >= 8) {
          int y = int.parse(s.substring(0, 4));
          int m = int.parse(s.substring(4, 6));
          int d = int.parse(s.substring(6, 8));
          int h = 19; // Standard 19 Uhr
          int min = 0;

          if (s.length >= 12) {
             h = int.parse(s.substring(8, 10));
             min = int.parse(s.substring(10, 12));
          }

          start = DateTime(y, m, d, h, min);
        }
      }
    } catch (e) {
      print("PARSE ERROR: $e");
    }

    // Text säubern
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