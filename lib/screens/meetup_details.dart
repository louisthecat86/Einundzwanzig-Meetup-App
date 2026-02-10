import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/meetup.dart';
import '../theme.dart';
import '../services/meetup_calendar_service.dart';
import '../models/calendar_event.dart';

class MeetupDetailsScreen extends StatefulWidget {
  final Meetup meetup;

  const MeetupDetailsScreen({super.key, required this.meetup});

  @override
  State<MeetupDetailsScreen> createState() => _MeetupDetailsScreenState();
}

class _MeetupDetailsScreenState extends State<MeetupDetailsScreen> {
  final MeetupCalendarService _calendarService = MeetupCalendarService();
  List<CalendarEvent> _meetupEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSpecificEvents();
  }

  // Lädt ALLE Events und behält nur die für DIESE Stadt
  void _loadSpecificEvents() async {
    final allEvents = await _calendarService.fetchMeetups();
    
    if (mounted) {
      setState(() {
        _meetupEvents = allEvents.where((e) {
          // Wir prüfen ob der Stadtname im Titel oder Ort des Events vorkommt
          final city = widget.meetup.city.toLowerCase();
          return e.title.toLowerCase().contains(city) || 
                 e.location.toLowerCase().contains(city);
        }).toList();
        
        // Sortieren nach Datum
        _meetupEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        _isLoading = false;
      });
    }
  }

  // Hilfsfunktion zum Öffnen von Links
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Link nicht öffnen')),
      );
    }
  }

  // Datumsformatierer (Hilfsfunktion)
  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(widget.meetup.city.toUpperCase()),
        backgroundColor: cDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => _launchURL(widget.meetup.telegramLink),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FLAGGE & TITEL
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: cOrange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.meetup.country.toUpperCase(),
                style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.meetup.city,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 32),

            // --- SEKTION 1: TERMINE (JETZT DYNAMISCH) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month, color: cCyan),
                      SizedBox(width: 10),
                      Text("TERMINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Ladeanzeige oder Liste
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: cCyan))
                    : _meetupEvents.isEmpty
                        ? Text(
                            "Aktuell keine Termine im Kalender gefunden.\nCheck die Telegram-Gruppe!",
                            style: TextStyle(color: Colors.grey.shade400, height: 1.5),
                          )
                        : Column(
                            children: _meetupEvents.map((event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDate(event.startTime),
                                    style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(color: Colors.white),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SEKTION 2: LINKS (JETZT KLICKBAR) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.link, color: cOrange),
                      SizedBox(width: 10),
                      Text("LINKS & KONTAKTE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Telegram Button
                  InkWell(
                    onTap: () => _launchURL(widget.meetup.telegramLink),
                    child: Row(
                      children: [
                        const Icon(Icons.send, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Telegram", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(
                                widget.meetup.telegramLink, 
                                style: const TextStyle(color: cCyan, fontWeight: FontWeight.w500),
                                maxLines: 1, overflow: TextOverflow.ellipsis
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 30),

                  // Twitter Button (Dummy, falls du Twitter im Model hast, hier einfügen)
                  InkWell(
                    onTap: () => _launchURL("https://twitter.com/search?q=%23Bitcoin"), // Beispiel
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Twitter / X", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text("@Einundzwanzig", style: TextStyle(color: cCyan, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- SEKTION 3: STANDORT ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.redAccent),
                      SizedBox(width: 10),
                      Text("STANDORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.meetup.lat.toStringAsFixed(4)}, ${widget.meetup.lng.toStringAsFixed(4)}",
                        style: const TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          // Google Maps öffnen
                          final url = "https://www.google.com/maps/search/?api=1&query=${widget.meetup.lat},${widget.meetup.lng}";
                          _launchURL(url);
                        },
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text("Route"),
                        style: TextButton.styleFrom(foregroundColor: cCyan),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}