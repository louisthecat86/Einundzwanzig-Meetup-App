import 'package:flutter/material.dart';
// Pfad zu deinem Service
import '../services/meetup_calendar_service.dart';
// Import für dein Theme (damit wir auf cDark, cCard etc. zugreifen können, falls nötig)
import '../theme.dart'; 

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final MeetupCalendarService _calendarService = MeetupCalendarService();
  late Future<List<Map<String, dynamic>>> _meetupsFuture;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // Funktion ausgelagert, damit wir sie auch per Button (Refresh) aufrufen können
  void _loadEvents() {
    setState(() {
      _meetupsFuture = _calendarService.fetchMeetups();
    });
  }

  String _formatDate(dynamic iCalDate) {
    if (iCalDate == null) return 'Datum unbekannt';
    String dateStr = iCalDate.toString();
    
    // iCal Datum ist oft im Format YYYYMMDD...
    if (dateStr.length >= 8) {
      String year = dateStr.substring(0, 4);
      String month = dateStr.substring(4, 6);
      String day = dateStr.substring(6, 8);
      
      // Uhrzeit extrahieren (falls vorhanden, meist nach dem 'T')
      String timeInfo = "";
      if (dateStr.contains('T') && dateStr.length >= 13) {
        int tIndex = dateStr.indexOf('T');
        String hour = dateStr.substring(tIndex + 1, tIndex + 3);
        String minute = dateStr.substring(tIndex + 3, tIndex + 5);
        timeInfo = " • $hour:$minute Uhr";
      }

      return '$day.$month.$year$timeInfo';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark, // Hintergrundfarbe deiner App
      appBar: AppBar(
        title: const Text('MEETUP KALENDER'),
        backgroundColor: cDark,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _meetupsFuture,
        builder: (context, snapshot) {
          
          // 1. Ladezustand
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: cOrange));
          } 
          
          // 2. Fehlerzustand (Jetzt sehr ausführlich!)
          else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      "Ups! Das hat nicht geklappt.",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${snapshot.error}", // Hier steht der wahre Grund
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadEvents,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Nochmal versuchen"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cOrange,
                        foregroundColor: Colors.black,
                      ),
                    )
                  ],
                ),
              ),
            );
          } 
          
          // 3. Keine Daten (Liste leer)
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, color: Colors.grey, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Aktuell keine Termine im Kalender.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. Daten erfolgreich geladen
          final meetups = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: meetups.length,
            itemBuilder: (context, index) {
              final meetup = meetups[index];
              
              final title = meetup['summary'] ?? 'Ohne Titel';
              final location = meetup['location'] ?? 'Ort unbekannt';
              final description = meetup['description'] ?? '';
              final dateString = _formatDate(meetup['dtstart']);

              return Card(
                color: cCard, // Deine Kartenfarbe aus theme.dart
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cBorder, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.calendar_month, color: cOrange),
                  ),
                  title: Text(
                    title, 
                    style: const TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    )
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$dateString\n📍 $location',
                      style: TextStyle(color: Colors.grey[400], height: 1.4),
                    ),
                  ),
                  isThreeLine: true,
                  onTap: () {
                    // Hier könntest du später einen Dialog mit der Beschreibung öffnen
                    if (description.isNotEmpty) {
                      showDialog(
                        context: context, 
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cCard,
                          title: Text(title, style: const TextStyle(color: Colors.white)),
                          content: SingleChildScrollView(
                            child: Text(description, style: const TextStyle(color: Colors.white70)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx), 
                              child: const Text("OK", style: TextStyle(color: cOrange))
                            )
                          ],
                        )
                      );
                    }
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