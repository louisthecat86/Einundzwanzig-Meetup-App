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
    if (urlString.isEmpty) return;
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konnte Link nicht öffnen')));
      }
    }
  }

  String _formatDate(DateTime dt) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final wd = weekdays[dt.weekday - 1];
    return "$wd, ${_twoDigits(dt.day)}.${_twoDigits(dt.month)}. ${_twoDigits(dt.hour)}:${_twoDigits(dt.minute)}";
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 24),
                Text(event.title, style: const TextStyle(color: cOrange, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Datum
                _detailRow(
                  Icons.calendar_today,
                  "${_twoDigits(event.startTime.day)}.${_twoDigits(event.startTime.month)}.${event.startTime.year}, ${_twoDigits(event.startTime.hour)}:${_twoDigits(event.startTime.minute)} Uhr",
                ),
                const SizedBox(height: 10),
                // Ort
                if (event.location.isNotEmpty)
                  _detailRow(Icons.location_on, event.location),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12),
                const SizedBox(height: 16),
                const Text("BESCHREIBUNG", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                Text(event.description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4))),
      ],
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
          if (widget.meetup.telegramLink.isNotEmpty)
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
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border.all(color: cOrange), borderRadius: BorderRadius.circular(8)),
              child: Text(widget.meetup.country.toUpperCase(), style: const TextStyle(color: cOrange, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
            const SizedBox(height: 12),
            Text(widget.meetup.city, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),

            // TERMINE
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.calendar_month, color: cCyan, size: 20),
                    SizedBox(width: 10),
                    Text("TERMINE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 16),
                  _isLoading 
                    ? const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(color: cCyan, strokeWidth: 2),
                      ))
                    : _meetupEvents.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text("Aktuell keine Termine im Kalender.", style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                          )
                        : Column(
                            children: _meetupEvents.map((event) => Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showEventDetails(event),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Datum-Chip
                                      Container(
                                        width: 100,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cOrange.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          _formatDate(event.startTime),
                                          style: const TextStyle(color: cOrange, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(event.title,
                                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                              maxLines: 2, overflow: TextOverflow.ellipsis),
                                            if (event.location.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(event.location,
                                                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // LINKS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.link, color: cOrange, size: 20),
                    SizedBox(width: 10),
                    Text("LINKS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 16),
                  
                  // Telegram
                  if (widget.meetup.telegramLink.isNotEmpty)
                    _buildLinkTile(
                      icon: Icons.send,
                      label: "Telegram",
                      value: widget.meetup.telegramLink,
                      onTap: () => _launchURL(widget.meetup.telegramLink),
                    ),

                  // Twitter / X
                  if (widget.meetup.twitterUsername.isNotEmpty) ...[
                    if (widget.meetup.telegramLink.isNotEmpty)
                      const Divider(color: Colors.white10, height: 24),
                    _buildLinkTile(
                      icon: Icons.alternate_email,
                      label: "Twitter / X",
                      value: "@${widget.meetup.twitterUsername}",
                      onTap: () {
                        final handle = widget.meetup.twitterUsername.replaceAll('@', '');
                        _launchURL("https://twitter.com/$handle");
                      },
                    ),
                  ],

                  // Nostr
                  if (widget.meetup.nostrNpub.isNotEmpty) ...[
                    const Divider(color: Colors.white10, height: 24),
                    _buildLinkTile(
                      icon: Icons.key,
                      label: "Nostr",
                      value: widget.meetup.nostrNpub.length > 28
                          ? "${widget.meetup.nostrNpub.substring(0, 28)}..."
                          : widget.meetup.nostrNpub,
                      onTap: () {},
                      mono: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // STANDORT
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("STANDORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5)),
                  ]),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${widget.meetup.lat.toStringAsFixed(4)}, ${widget.meetup.lng.toStringAsFixed(4)}",
                        style: TextStyle(color: Colors.grey.shade500, fontFamily: 'monospace', fontSize: 13),
                      ),
                      TextButton.icon(
                        onPressed: () => _launchURL(
                          "https://www.google.com/maps/search/?api=1&query=${widget.meetup.lat},${widget.meetup.lng}",
                        ),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text("Route"),
                        style: TextButton.styleFrom(foregroundColor: cCyan),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool mono = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: cCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: mono ? 'monospace' : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        ]),
      ),
    );
  }
}