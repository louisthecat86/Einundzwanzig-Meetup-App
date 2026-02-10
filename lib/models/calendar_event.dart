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
    DateTime start = DateTime.now().add(const Duration(days: 365)); // Fallback weit in Zukunft, damit man Fehler bemerkt

    try {
      final dtStart = map['dtstart'];

      // Fall 1: Das Paket hat es schon als IcsDateTime Objekt erkannt
      if (dtStart is IcsDateTime) {
        start = dtStart.toDateTime() ?? DateTime.now();
      } 
      // Fall 2: Es ist ein String (z.B. "20260210T190000" oder "20260210T190000Z")
      else if (dtStart is String) {
        String cleanDt = dtStart.replaceAll('Z', ''); // Zeitzone 'Z' entfernen
        if (cleanDt.length >= 8) {
          String y = cleanDt.substring(0, 4);
          String m = cleanDt.substring(4, 6);
          String d = cleanDt.substring(6, 8);
          String time = "000000";
          
          if (cleanDt.contains('T')) {
             final parts = cleanDt.split('T');
             if (parts.length > 1) {
               time = parts[1].padRight(6, '0'); // Sicherstellen dass genug Stellen da sind
             }
          }
          
          String h = time.substring(0, 2);
          String min = time.substring(2, 4);
          
          start = DateTime.parse('$y-$m-$d $h:$min:00');
        }
      }
    } catch (e) {
      print("CRITICAL DATE ERROR: $e");
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