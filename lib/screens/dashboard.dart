import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Für Reset
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart';
import '../models/badge.dart';
import '../services/meetup_service.dart';
import 'meetup_verification.dart';
import 'meetup_selection.dart'; 
import 'badge_details.dart'; 
import 'badge_wallet.dart';
import 'profile_edit.dart'; 
import 'intro.dart'; // Um zum Start zurückzukehren
import 'admin_panel.dart'; // Neuer Admin Bereich
import 'events.dart'; // Events/Termine Screen
import 'meetup_details.dart'; // Meetup Details Screen
import 'reputation_qr.dart'; // Reputation QR-Code
import 'calendar_screen.dart'; // WICHTIG: Kalender importiert

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile _user = UserProfile();
  Meetup? _homeMeetup; // Das geladene Home-Meetup
  
  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadBadges();
  }

  void _loadBadges() async {
    final badges = await MeetupBadge.loadBadges();
    setState(() {
      myBadges.clear();
      myBadges.addAll(badges);
    });
    print("[DEBUG Dashboard] ${badges.length} Badges geladen");
  }

  void _loadUser() async {
    final u = await UserProfile.load();
    
    print("[DEBUG Dashboard] User geladen: ${u.nickname}, Home-Meetup: ${u.homeMeetupId}");
    
    // Home-Meetup laden wenn vorhanden (Matching auf Namen)
    Meetup? homeMeetup;
    if (u.homeMeetupId.isNotEmpty) {
      List<Meetup> meetups = await MeetupService.fetchMeetups();
      if (meetups.isEmpty) {
        meetups = allMeetups;
      }
      // Match auf Stadt-Namen statt ID
      homeMeetup = meetups.where((m) => m.city == u.homeMeetupId).firstOrNull;
      
      if (homeMeetup != null) {
        print("[DEBUG Dashboard] Home-Meetup gefunden: ${homeMeetup.city}");
      } else {
        print("[DEBUG Dashboard] Home-Meetup NICHT gefunden für: ${u.homeMeetupId}");
      }
    }
    
    setState(() {
      _user = u;
      _homeMeetup = homeMeetup;
    });
  }

  // APP ZURÜCKSETZEN (Logout)
  void _resetApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Alles löschen (Admin status, Namen, etc.)
    myBadges.clear();    // Badges im Speicher löschen
    await MeetupBadge.saveBadges([]); // Badges auch persistent löschen
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const IntroScreen()), 
        (route) => false
      );
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context, 
      backgroundColor: cCard,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          children: [
            const Text("EINSTELLUNGEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("App zurücksetzen / Logout", style: TextStyle(color: Colors.white)),
              onTap: _resetApp,
            ),
             ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text("Abbrechen", style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.pop(context),
            )
          ],
        ),
      )
    );
  }

  void _scanAnyMeetup() async {
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: dummy)),
    );
    setState(() {}); // Badge-Anzahl aktualisieren
  }

  void _selectHomeMeetup() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const MeetupSelectionScreen()));
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("DASHBOARD"),
        automaticallyImplyLeading: false, 
        actions: [
          IconButton(
             icon: const Icon(Icons.settings),
             onPressed: _showSettings,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Hallo, ${_user.nickname}!",
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: cText,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Willkommen zurück in der Community.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cTextSecondary,
              ),
            ),
            
            const SizedBox(height: 32),

            _buildHomeMeetupCard(),

            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildTile(
                  icon: Icons.military_tech,
                  color: cOrange,
                  title: "BADGES",
                  subtitle: "Jetzt scannen",
                  onTap: _scanAnyMeetup, // DIREKT NFC ÖFFNEN
                ),
                _buildTile(
                  icon: Icons.collections_bookmark, 
                  color: cPurple, 
                  title: "WALLET", 
                  subtitle: "${myBadges.length} Badges", 
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => BadgeWalletScreen()),
                    );
                  }
                ),
                _buildTile(
                  icon: Icons.event,
                  color: cCyan,
                  title: "TERMINE",
                  subtitle: "Kalender & Events",
                  onTap: () {
                    Navigator.push(
                      context,
                      // Öffnet den Kalender ohne Filter (alle Events)
                      MaterialPageRoute(builder: (context) => const CalendarScreen()),
                    );
                  },
                ),
                _buildTile(
                  icon: Icons.person, color: Colors.grey, title: "PROFIL", subtitle: "Identität", 
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()));
                    _loadUser();
                  }
                ),
                if (myBadges.isNotEmpty) // Nur wenn Badges vorhanden
                  _buildTile(
                    icon: Icons.workspace_premium,
                    color: Colors.amber,
                    title: "REPUTATION",
                    subtitle: "Badges teilen",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReputationQRScreen()),
                      );
                    },
                  ),
                if (_user.isAdmin) // Nur für echte Admins
                  _buildTile(
                    icon: Icons.admin_panel_settings,
                    color: Colors.redAccent,
                    title: "ADMIN",
                    subtitle: "Tags erstellen",
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                      );
                    }
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHomeMeetupCard() {
    bool hasHome = _user.homeMeetupId.isNotEmpty;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        // === HIER IST DIE ÄNDERUNG ===
        // Wenn man auf die Karte klickt, öffnet sich der Kalender mit Filter auf die Stadt
        onTap: hasHome && _homeMeetup != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarScreen(
                initialSearch: _homeMeetup!.city // Wir geben die Stadt als Filter mit
              ),
            ),
          );
        } : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasHome ? cOrange.withOpacity(0.4) : cBorder,
              width: 1.5,
            ),
            boxShadow: hasHome ? [
              BoxShadow(
                color: cOrange.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              )
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_filled, color: cOrange, size: 24),
                  ),
                  if (hasHome) 
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "DEIN MEETUP",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _homeMeetup != null ? _homeMeetup!.city.toUpperCase() : (_user.homeMeetupId.isNotEmpty ? "Lade..." : "KEIN HOME MEETUP"),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _homeMeetup != null ? "${_homeMeetup!.country} • Regelmäßige Treffen" : (_user.homeMeetupId.isNotEmpty ? "ID: ${_user.homeMeetupId}" : "Wähle dein Stammtisch-Meetup aus"), 
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selectHomeMeetup,
                      child: Text(hasHome ? "ÄNDERN" : "AUSWÄHLEN"),
                    ),
                  ),
                  if (hasHome) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Der "DETAILS" Button führt weiterhin zu den technischen Details (Links, Koordinaten etc.)
                          // Falls du das auch auf den Kalender ändern willst, sag Bescheid!
                          if (_homeMeetup != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeetupDetailsScreen(meetup: _homeMeetup!),
                              ),
                            );
                          }
                        },
                        child: const Text("DETAILS"),
                      ),
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cBorder, width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}