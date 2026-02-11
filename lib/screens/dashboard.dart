import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'intro.dart'; 
import 'admin_panel.dart'; 
import 'events.dart'; 
import 'meetup_details.dart'; 
import 'reputation_qr.dart'; 
import 'calendar_screen.dart';
import '../services/backup_service.dart'; // Backup Service Import

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserProfile _user = UserProfile();
  Meetup? _homeMeetup; 
  
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
    
    Meetup? homeMeetup;
    if (u.homeMeetupId.isNotEmpty) {
      List<Meetup> meetups = await MeetupService.fetchMeetups();
      if (meetups.isEmpty) {
        meetups = allMeetups;
      }
      homeMeetup = meetups.where((m) => m.city == u.homeMeetupId).firstOrNull;
    }
    
    setState(() {
      _user = u;
      _homeMeetup = homeMeetup;
    });
  }

  void _resetApp() async {
    // Sicherheitsabfrage vor dem Löschen
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("App zurücksetzen?", style: TextStyle(color: Colors.white)),
        content: const Text("Alle Badges und dein Profil werden gelöscht. Stelle sicher, dass du ein Backup hast!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Abbruch")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("LÖSCHEN", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    myBadges.clear();    
    await MeetupBadge.saveBadges([]); 
    
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min, 
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4, 
                decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("DATENSICHERUNG", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),
            
            // --- BACKUP EXPORT (Nur Erstellen) ---
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.upload, color: Colors.blue),
              ),
              title: const Text("Backup erstellen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Sichere deinen Account extern als Datei.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () async {
                Navigator.pop(context); 
                await BackupService.createBackup(context);
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            
            const Text("ACCOUNT", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 10),

            // --- RESET ---
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_forever, color: Colors.red),
              ),
              title: const Text("App zurücksetzen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Löscht Profil und Badges vom Gerät.", style: TextStyle(color: Colors.grey, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _resetApp();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scanAnyMeetup() async {
    final dummy = Meetup(id: "global", city: "GLOBAL", country: "", telegramLink: "", lat: 0, lng: 0);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(meetup: dummy)),
    );
    _loadBadges(); // Sicherstellen, dass Badges nach Scan neu geladen werden
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
                  onTap: _scanAnyMeetup, 
                ),
                _buildTile(
                  icon: Icons.collections_bookmark, 
                  color: cPurple, 
                  title: "WALLET", 
                  subtitle: "${myBadges.length} Badges", 
                  onTap: () async {
                    await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => BadgeWalletScreen()),
                    );
                    _loadBadges(); // Reload nach Rückkehr aus Wallet
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
                if (myBadges.isNotEmpty) 
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
                if (_user.isAdmin) 
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
        onTap: hasHome && _homeMeetup != null ? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarScreen(
                initialSearch: _homeMeetup!.city 
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