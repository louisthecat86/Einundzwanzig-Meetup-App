import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/meetup_service.dart'; // Importiert den neuen Service
import '../models/meetup.dart';

class MeetupListScreen extends StatefulWidget {
  const MeetupListScreen({super.key});

  @override
  _MeetupListScreenState createState() => _MeetupListScreenState();
}

class _MeetupListScreenState extends State<MeetupListScreen> {
  final MeetupService _service = MeetupService();
    late Future<List<Meetup>> _futureMeetups;

  @override
  void initState() {
    super.initState();
      _futureMeetups = _service.fetchMeetups();
  }

  Future<void> _onOpenLink(LinkableElement link) async {
    final Uri uri = Uri.parse(link.url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konnte Link nicht öffnen: ${link.url}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nächste Termine"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _futureEvents = _service.fetchEvents();
              });
            },
          )
        ],
      ),
      body: FutureBuilder<List<Meetup>>(
        future: _futureMeetups,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Keine aktuellen Termine gefunden."),
            );
          }

          final meetups = snapshot.data!;
          return ListView.builder(
            itemCount: meetups.length,
            itemBuilder: (context, index) {
              final meetup = meetups[index];
              return ListTile(
                title: Text(meetup.city),
                subtitle: Text(meetup.description),
                onTap: () {},
              );
            },
          );
            itemBuilder: (context, index) {
              final event = snapshot.data![index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ExpansionTile(
                  leading: const Icon(Icons.calendar_month, color: Colors.orange),
                  title: Text(
                    event.title, // z.B. "Einundzwanzig München"
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(event.formattedDate), // z.B. "Do, 12.02. 18:00 Uhr"
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.location.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 5),
                                Expanded(child: Text(event.location)),
                              ],
                            ),
                          const SizedBox(height: 10),
                          // Automatisch klickbare Links in der Beschreibung
                          Linkify(
                            onOpen: _onOpenLink,
                            text: event.description,
                            style: const TextStyle(fontSize: 15),
                            linkStyle: const TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}