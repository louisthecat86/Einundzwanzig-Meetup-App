import 'package:flutter/material.dart';
import 'package:dbcrypt/dbcrypt.dart';
import '../models/meetup.dart'; 
import 'meetup_verification.dart';

// War früher "VerificationGate"
class OrganisatorLoginScreen extends StatefulWidget {
  const OrganisatorLoginScreen({super.key});
  @override
  State<OrganisatorLoginScreen> createState() => _OrganisatorLoginScreenState();
}

class _OrganisatorLoginScreenState extends State<OrganisatorLoginScreen> {
  final TextEditingController _pwController = TextEditingController();
  // DEIN HASH VON VORHIN
  static const String _adminPasswordHash = r"$2a$12$kq69Oonj6Fk13v7nq6YAmu2CGzivJWmjKN12.UVgnl08RTIEKxWQG";

  void _checkPassword() {
    final isValid = DBCrypt().checkpw(_pwController.text, _adminPasswordHash);
    if (isValid) {
      // Dummy Meetup für Admin-Modus
      final dummyMeetup = Meetup(id: "admin", city: "ADMIN", country: "", telegramLink: "", lat: 0, lng: 0);
      
      // Gehe in den Verification Screen aber im CHEF MODUS (initialChefMode = true)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MeetupVerificationScreen(
          meetup: dummyMeetup,
          initialChefMode: true, // DAS IST DER ADMIN MODUS
        )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falsches Passwort")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Organisator Login"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text("Nur für Organisatoren", style: TextStyle(color: Colors.orange, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Logge dich ein, wenn du noch nicht via Trust Score freigeschaltet bist.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 32),
            TextField(
              controller: _pwController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Passwort", filled: true, fillColor: Colors.white10),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _checkPassword, child: const Text("LOGIN")),
          ],
        ),
      ),
    );
  }
}