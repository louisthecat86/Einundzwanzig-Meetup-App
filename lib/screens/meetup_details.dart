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

  void _loadSpecificEvents() async {
    final allEvents = await _calendarService.fetchMeetups();
    if (mounted) {
      setState(() {
        _meetupEvents = allEvents.where((e) {
          final city = widget.meetup.city.toLowerCase();
          return e.title.toLowerCase().contains(city) || 
                 e.location.toLowerCase().contains(city);
        }).toList();
        _meetupEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
        _isLoading = false;
      });
    }
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    // mode: LaunchMode.externalApplication ist wichtig, damit sich die echte App (Twitter/Maps) öffnet
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konnte Link nicht öffnen')));
    }
  }

  String _formatDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}. ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, color: Colors.grey, margin: const EdgeInsets.only(bottom: 20))),
                Text(event.title, style: const TextStyle(color: cOrange, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "${_twoDigits(event.startTime.day)}.${_twoDigits(event.startTime.month)}.${event.startTime.year}, ${_twoDigits(event.startTime.hour)}:${_twoDigits(event.startTime.minute)} Uhr",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(event.location, style: const TextStyle(color: Colors.white70, fontSize: 16))),
                  ],
                ),
                const Divider(color: Colors.white24, height: 40),
                const Text("BESCHREIBUNG", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(event.description, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
              ],
            ),
          ),
        );
      },
    );
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: cOrange), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.meetup.country.toUpperCase(), style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(widget.meetup.city, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),

            // TERMINE SEKTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.calendar_month, color: cCyan), SizedBox(width: 10), Text("TERMINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 16),
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: cCyan))
                    : _meetupEvents.isEmpty
                        ? Text("Aktuell keine Termine im Kalender.", style: TextStyle(color: Colors.grey.shade400))
                        : Column(
                            children: _meetupEvents.map((event) => InkWell(
                              onTap: () => _showEventDetails(event),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatDate(event.startTime), style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Text(event.title, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            )).toList(),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // LINKS SEKTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.link, color: cOrange), SizedBox(width: 10), Text("LINKS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 20),
                  
                  // Telegram
                  InkWell(
                    onTap: () => _launchURL(widget.meetup.telegramLink),
                    child: Row(children: [const Icon(Icons.send, color: Colors.grey, size: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Telegram", style: TextStyle(color: Colors.grey, fontSize: 12)), Text(widget.meetup.telegramLink, style: const TextStyle(color: cCyan), maxLines: 1, overflow: TextOverflow.ellipsis)])), const Icon(Icons.chevron_right, color: Colors.grey)]),
                  ),
                  
                  const Divider(color: Colors.white10, height: 30),

                  // Twitter / X (JETZT KORRIGIERT)
                  InkWell(
                    // Hier der Link zum offiziellen Account statt #Bitcoin
                    onTap: () => _launchURL("https://twitter.com/Einundzwanzig_"), 
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
             
             // STANDORT SEKTION (MIT FIX FÜR GOOGLE MAPS)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [Icon(Icons.location_on, color: Colors.redAccent), SizedBox(width: 10), Text("STANDORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${widget.meetup.lat.toStringAsFixed(4)}, ${widget.meetup.lng.toStringAsFixed(4)}", style: const TextStyle(color: Colors.grey, fontFamily: 'monospace')),
                      TextButton.icon(
                        // Hier war vorher ein Tippfehler mit '0{...}'
                        onPressed: () => _launchURL("https://www.google.com/maps/search/?api=1&query=${widget.meetup.lat},${widget.meetup.lng}"),
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