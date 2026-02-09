import 'package:flutter/material.dart';
import '../theme.dart'; // Zugriff auf unsere Farben (cOrange, cCard etc.)

class CreateMeetupScreen extends StatelessWidget {
  const CreateMeetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NEUES MEETUP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("GRÜNDE EINE BASIS.", style: TextStyle(color: cOrange, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 20),

            _brutalInput("NAME DER STADT", "z.B. Frankfurt"),
            const SizedBox(height: 20),
            _brutalInput("LOCATION / ORT", "z.B. Room 77"),
            const SizedBox(height: 20),
            _brutalInput("DATUM & UHRZEIT", "z.B. 21. Mai, 19:00"),
            const SizedBox(height: 20),
            _brutalInput("TELEGRAM GRUPPE (OPTIONAL)", "t.me/..."),

            const SizedBox(height: 40),
            
            // Der Speicher-Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Hier würde später das Speichern passieren
                  Navigator.pop(context); // Geht zurück zur Liste
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ANFRAGE GESENDET 🚀")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(), // Eckig
                  elevation: 0,
                ),
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text("MEETUP STARTEN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ein eigenes Widget für brutalistische Eingabefelder
  Widget _brutalInput(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          cursorColor: cOrange,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: cCard, // Dunkelgrauer Hintergrund
            // Harter Rahmen, kein Radius
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: cOrange, width: 2), // Orange bei Fokus
              borderRadius: BorderRadius.zero,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}