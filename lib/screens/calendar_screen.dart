import 'package:flutter/material.dart';
// Hier importieren wir den Service, den du gerade erstellt hast.
// Achte darauf, dass der Pfad stimmt. Falls dein Ordner anders heißt, musst du das anpassen.
import '../services/meetup_calendar_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // Wir erstellen eine Instanz unseres Services
  final MeetupCalendarService _calendarService = MeetupCalendarService();
  
  // Hier speichern wir das "Versprechen" (Future) auf die Daten
  late Future<List<Map<String, dynamic>>> _meetupsFuture;

  @override
  void initState() {
    super.initState();
    // Sobald der Screen geladen wird, rufen wir die Daten ab
    _meetupsFuture = _calendarService.fetchMeetups();
  }

  // Eine kleine Hilfsfunktion, um das wilde iCal-Datum (z.B. 20240520T180000) 
  // etwas lesbarer zu machen, ohne gleich ein neues Paket zu brauchen.
  String _formatDate(String? iCalDate) {
    if (iCalDate == null || iCalDate.length < 8) return 'Datum unbekannt';
    // Format: YYYYMMDD...
    String year = iCalDate.substring(0, 4);
    String month = iCalDate.substring(4, 6);
    String day = iCalDate.substring(6, 8);
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einundzwanzig Kalender'),
        backgroundColor: Colors.orange, // Einundzwanzig Orange :)
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _meetupsFuture,
        builder: (context, snapshot) {
          // 1. Ladezustand: Kringel anzeigen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          // 2. Fehlerzustand: Fehlermeldung anzeigen
          else if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          } 
          // 3. Keine Daten vorhanden
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Keine Meetups gefunden.'));
          }

          // 4. Daten erfolgreich geladen
          final meetups = snapshot.data!;

          return ListView.builder(
            itemCount: meetups.length,
            itemBuilder: (context, index) {
              final meetup = meetups[index];
              
              // Die genauen Keys (summary, location etc.) kommen aus dem iCal Format
              final title = meetup['summary'] ?? 'Ohne Titel';
              final location = meetup['location'] ?? 'Ort unbekannt';
              final description = meetup['description'] ?? '';
              final dateString = _formatDate(meetup['dtstart']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.orange),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$dateString\n$location'),
                  isThreeLine: true,
                  onTap: () {
                    // Später könnten wir hier Details anzeigen
                    print(description); 
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}