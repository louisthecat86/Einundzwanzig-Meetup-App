import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/user.dart';
import '../models/meetup.dart'; 
import 'meetup_verification.dart'; 
import 'dashboard.dart'; 

class VerificationGateScreen extends StatefulWidget {
  const VerificationGateScreen({super.key});

  @override
  State<VerificationGateScreen> createState() => _VerificationGateScreenState();
}

class _VerificationGateScreenState extends State<VerificationGateScreen> {
  final TextEditingController _pwController = TextEditingController();
  
  // Admin-Passwort (wird beim Compile obfuskiert)
  static const String _adminPassword = "#21AdminTag21#";

  void _startVerification() async {
    // Dummy Meetup für Scan
    final dummyMeetup = Meetup(id: "gate", city: "VERIFICATION", country: "", telegramLink: "", lat: 0, lng: 0);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeetupVerificationScreen(
        meetup: dummyMeetup,
        verifyOnlyMode: true, // NUR Verifizierung, keine Badges
      )),
    );

    if (result == true) {
      _checkStatus();
    }
  }

  void _checkStatus() async {
    final user = await UserProfile.load();
    if (user.isAdminVerified && mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const DashboardScreen())
      );
    }
  }

  // --- DIE HINTERTÜR FÜR ORGANISATOREN ---
  void _showAdminLogin() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cCard,
        title: const Text("ORGANISATOR LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Überspringe die Verifizierung, wenn du selbst ein Admin bist.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: _pwController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: "ADMIN PASSWORT",
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cOrange)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ABBRUCH", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cOrange),
            onPressed: () async {
              // Passwort direkt prüfen
              if (_pwController.text == _adminPassword) {
                // SUCCESS: User wird Admin UND verifiziert
                final user = await UserProfile.load();
                user.isAdmin = true; // Hat Admin-Rechte
                user.isAdminVerified = true; // Identität bestätigt
                // Wenn der Nutzer einen Nostr npub hat, verifizieren wir diesen auch
                if (user.nostrNpub.isNotEmpty) {
                  user.isNostrVerified = true;
                }
                await user.save();
                
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Willkommen, Admin! ⚡️")));
                }
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("❌ Falsches Passwort"),
                  backgroundColor: Colors.red,
                ));
              }
            },
            child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 30),
            const Text(
              "ZUTRITT BESCHRÄNKT",
              style: TextStyle(color: cOrange, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Um Zugang zur Zitadelle zu erhalten, muss deine Identität von einem Admin bestätigt werden.",
              style: TextStyle(color: Colors.white70, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton.icon(
                onPressed: _startVerification,
                icon: const Icon(Icons.nfc, color: Colors.white),
                label: const Text("ADMIN TAG SCANNEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: cOrange),
              ),
            ),
            const SizedBox(height: 30),
            
            // LINK FÜR ADMINS
            TextButton(
              onPressed: _showAdminLogin, 
              child: const Text("Ich bin Organisator / Admin", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline))
            )
          ],
        ),
      ),
    );
  }
}