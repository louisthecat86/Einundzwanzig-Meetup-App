import 'package:flutter/material.dart';
import '../models/meetup.dart';
import '../models/user.dart';
import '../services/meetup_service.dart'; // <--- Service nutzen
import '../theme.dart';
import 'radar.dart'; 

class MeetupSelectionScreen extends StatefulWidget {
  const MeetupSelectionScreen({super.key});

  @override
  State<MeetupSelectionScreen> createState() => _MeetupSelectionScreenState();
}

class _MeetupSelectionScreenState extends State<MeetupSelectionScreen> {
  List<Meetup> _meetups = [];
  List<Meetup> _filteredMeetups = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterMeetups);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterMeetups() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMeetups = _meetups;
      } else {
        _filteredMeetups = _meetups.where((meetup) =>
          meetup.city.toLowerCase().contains(query) ||
          meetup.country.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  void _loadData() async {
    // Echte Daten laden
    final list = await MeetupService.fetchMeetups();
    setState(() {
      _meetups = list;
      _filteredMeetups = list;
      // Falls API leer (oder Fehler), nutzen wir Fallback (aus meetup.dart, falls definiert, sonst leer)
      if (_meetups.isEmpty) {
         // Hier könnten wir Dummy Daten laden oder leer lassen
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("MEETUP AUSWÄHLEN"),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: cOrange))
        : Column(
            children: [
              // Suchfeld
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Meetup suchen...",
                    prefixIcon: const Icon(Icons.search, color: cOrange),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: cTextTertiary),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Meetup-Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _filteredMeetups.length,
                  itemBuilder: (context, index) {
                    final meetup = _filteredMeetups[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: cCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cBorder),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Home-Meetup speichern (Name statt ID, da API keine guten IDs hat)
                            final user = await UserProfile.load();
                            user.homeMeetupId = meetup.city; // Speichere Stadt-Namen
                            await user.save();
                            
                            print("[DEBUG] Home-Meetup gespeichert: Name=${meetup.city}");

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("✅ ${meetup.city} als Home-Meetup gesetzt"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.pop(context); // Zurück zum Dashboard
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cOrange.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: cOrange,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    meetup.city.toUpperCase(),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  color: cTextTertiary,
                                  size: 16,
                                ),
                              ],
                            ),
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