import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';

class MeetupCalendarService {
  static const String calendarUrl = 'https://portal.einundzwanzig.space/stream-calendar';

  Future<List<Map<String, dynamic>>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(calendarUrl));

      if (response.statusCode == 200) {
        // Dekodieren als UTF-8 für Umlaute
        final iCalString = utf8.decode(response.bodyBytes);
        final iCalendar = ICalendar.fromString(iCalString);
        
        List<Map<String, dynamic>> meetups = [];
        
        if (iCalendar.data != null) {
          for (var item in iCalendar.data) {
            if (item['type'] == 'VEVENT') {
              meetups.add(item);
            }
          }
        }
        return meetups;
      } else {
        throw Exception('Fehler: ${response.statusCode}');
      }
   } catch (e) {
      print("Fehler im CalendarService: $e");
      // WICHTIG: Wir werfen den Fehler weiter, damit der Screen ihn anzeigen kann!
      throw Exception("Fehler beim Laden: $e"); 
    }
  }
}