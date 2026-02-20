// ============================================
// MEETUP LIST SCREEN — Alle Meetups anzeigen
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/meetup_service.dart';
import '../models/meetup.dart';
import '../theme.dart';
import 'meetup_details.dart';

class MeetupListScreen extends StatefulWidget {
  const MeetupListScreen({super.key});

  @override
  State<MeetupListScreen> createState() => _MeetupListScreenState();
}

class _MeetupListScreenState extends State<MeetupListScreen> {
  late Future<List<Meetup>> _futureMeetups;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _futureMeetups = MeetupService.fetchMeetups();
  }

  void _refresh() {
    setState(() {
      _futureMeetups = MeetupService.fetchMeetups();
    });
  }

  List<Meetup> _filterMeetups(List<Meetup> meetups) {
    if (_searchQuery.isEmpty) return meetups;
    final q = _searchQuery.toLowerCase();
    return meetups.where((m) =>
      m.city.toLowerCase().contains(q) ||
      m.country.toLowerCase().contains(q) ||
      m.description.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("MEETUPS"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Suchleiste
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Meetup suchen...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Liste
          Expanded(
            child: FutureBuilder<List<Meetup>>(
              future: _futureMeetups,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: cOrange));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.grey, size: 48),
                          const SizedBox(height: 16),
                          Text("Fehler beim Laden", style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text("${snapshot.error}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Erneut versuchen"),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text("Keine Meetups gefunden.", style: TextStyle(color: Colors.grey.shade500)),
                  );
                }

                final meetups = _filterMeetups(snapshot.data!);

                if (meetups.isEmpty) {
                  return Center(
                    child: Text("Kein Meetup für \"$_searchQuery\" gefunden.", style: TextStyle(color: Colors.grey.shade500)),
                  );
                }

                // Nach Land gruppieren
                final grouped = <String, List<Meetup>>{};
                for (final m in meetups) {
                  final country = m.country.isNotEmpty ? m.country : 'Sonstige';
                  grouped.putIfAbsent(country, () => []).add(m);
                }
                final sortedCountries = grouped.keys.toList()..sort();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedCountries.length,
                  itemBuilder: (context, groupIndex) {
                    final country = sortedCountries[groupIndex];
                    final items = grouped[country]!;
                    items.sort((a, b) => a.city.compareTo(b.city));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Länderkopf
                        Padding(
                          padding: EdgeInsets.only(top: groupIndex == 0 ? 4 : 20, bottom: 10),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: cOrange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _countryName(country),
                                style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "${items.length} Meetup${items.length == 1 ? '' : 's'}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ]),
                        ),

                        // Meetup-Karten
                        ...items.map((meetup) => _buildMeetupCard(meetup)),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupCard(Meetup meetup) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MeetupDetailsScreen(meetup: meetup)),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Stadt-Icon
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: cOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_city, color: cOrange, size: 22),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meetup.city,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meetup.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          meetup.description,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (meetup.telegramLink.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.send, color: Colors.grey.shade600, size: 12),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              meetup.telegramLink,
                              style: TextStyle(color: cCyan.withOpacity(0.7), fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.white24, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _countryName(String code) {
    switch (code.toUpperCase()) {
      case 'DE': return 'Deutschland';
      case 'AT': return 'Österreich';
      case 'CH': return 'Schweiz';
      case 'ES': return 'Spanien';
      case 'NL': return 'Niederlande';
      case 'IT': return 'Italien';
      case 'FR': return 'Frankreich';
      default: return code;
    }
  }
}