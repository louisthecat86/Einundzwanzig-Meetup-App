import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import '../models/calendar_event.dart'; // Importiere das neue Modell

class MeetupCalendarService {
  static const String calendarUrl = 'https://portal.einundzwanzig.space/stream-calendar';

  Future<List<CalendarEvent>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(calendarUrl));

      if (response.statusCode == 200) {
        final iCalString = utf8.decode(response.bodyBytes);
        final iCalendar = ICalendar.fromString(iCalString);
        
        List<CalendarEvent> events = [];
        
        if (iCalendar.data != null) {
          for (var item in iCalendar.data) {
            if (item['type'] == 'VEVENT') {
              // Hier nutzen wir unsere neue "Waschstraße" für Daten
              events.add(CalendarEvent.fromMap(item));
            }
          }
        }
        
        // Sortieren: Nächste Termine zuerst
        events.sort((a, b) => a.startTime.compareTo(b.startTime));

        // Nur Termine in der Zukunft anzeigen (optional)
        // events = events.where((e) => e.startTime.isAfter(DateTime.now().subtract(const Duration(days: 1)))).toList();

        return events;
      } else {
        throw Exception('Server Fehler: ${response.statusCode}');
      }
    } catch (e) {
      print("Fehler im CalendarService: $e");
      return [];
    }
  }
}