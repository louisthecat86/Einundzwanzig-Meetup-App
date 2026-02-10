import 'package:flutter/material.dart';
import '../services/meetup_calendar_service.dart';
import '../models/calendar_event.dart';
import '../theme.dart';

class CalendarScreen extends StatefulWidget {
  // Wir erlauben einen optionalen Suchbegriff beim Start (z.B. vom Dashboard kommend)
  final String? initialSearch;

  const CalendarScreen({super.key, this.initialSearch});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final MeetupCalendarService _calendarService = MeetupCalendarService();
  
  List<CalendarEvent> _allEvents = [];  // Alle geladenen Events
  List<CalendarEvent> _filteredEvents = []; // Die aktuell angezeigten Events
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Wenn ein Suchbegriff übergeben wurde (z.B. "Landau"), tragen wir ihn ein
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }
    _loadEvents();
  }

  void _loadEvents() async {
    final events = await _calendarService.fetchMeetups();
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
        _filterEvents(); // Direkt filtern nach dem Laden
      });
    }
  }

  // Diese Funktion filtert die Liste basierend auf dem Suchtext
  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents = _allEvents.where((event) {
        final title = event.title.toLowerCase();
        final location = event.location.toLowerCase();
        return title.contains(query) || location.contains(query);
      }).toList();
    });
  }

  // Hilfsfunktion für führende Nullen (z.B. 19:05 statt 19:5)
  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Zeigt Details in einem schönen "Bottom Sheet" statt der hässlichen Box
  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      isScrollControlled: true, // Damit es größer werden kann
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: 500, // Feste Höhe oder dynamisch
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
      backgroundColor: cDark, // Dunkler Hintergrund
      appBar: AppBar(
        title: const Text("MEETUP TERMINE"),
        backgroundColor: cDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // SUCHLEISTE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterEvents(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Suche (z.B. München, Bitcoin...)",
                hintStyle: TextStyle(color: Colors.grey.shade600),
                prefixIcon: const Icon(Icons.search, color: cOrange),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),

          // LISTE
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: cOrange))
                : _filteredEvents.isEmpty
                    ? Center(child: Text("Keine Termine gefunden.", style: TextStyle(color: Colors.grey.shade600)))
                    : ListView.builder(
                        itemCount: _filteredEvents.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return Card(
                            color: cCard,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () => _showEventDetails(event),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    // DATUMS-BOX (Links)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: cOrange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: cOrange.withOpacity(0.3)),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            _twoDigits(event.startTime.day),
                                            style: const TextStyle(color: cOrange, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            _twoDigits(event.startTime.month),
                                            style: const TextStyle(color: cOrange, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // INFO-TEXT (Mitte)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.title,
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${_twoDigits(event.startTime.hour)}:${_twoDigits(event.startTime.minute)} Uhr",
                                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            event.location,
                                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}