import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../models/user.dart';

class ProfileReviewScreen extends StatelessWidget {
  final UserProfile user;
  final VoidCallback onConfirm; // Hier kommt deine alte NFC-Logik rein

  const ProfileReviewScreen({
    super.key, 
    required this.user, 
    required this.onConfirm
  });

  Future<void> _launch(String url, BuildContext context) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Konnte Link nicht öffnen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("DATEN PRÜFEN"),
        backgroundColor: cDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PROFIL ZUSAMMENFASSUNG",
              style: TextStyle(color: cOrange, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Admin: Tippe auf die Zeilen, um die Apps zu öffnen und den Login zu prüfen.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

            // DATEN KARTE
            Container(
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  _buildRow("Nickname", user.nickname, Icons.person, null),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRow(
                    "Telegram", 
                    user.telegram, 
                    Icons.send, 
                    user.telegram.isNotEmpty 
                      ? () => _launch("https://t.me/${user.telegram.replaceAll('@','')}", context) 
                      : null
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRow(
                    "Twitter / X", 
                    user.twitter, 
                    Icons.alternate_email, 
                    user.twitter.isNotEmpty 
                      ? () => _launch("https://twitter.com/${user.twitter.replaceAll('@','')}", context) 
                      : null
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  _buildRow(
                    "Nostr (npub)", 
                    user.nostr.length > 10 ? "${user.nostr.substring(0,10)}..." : user.nostr, 
                    Icons.key, 
                    user.nostr.isNotEmpty 
                      ? () => _launch("https://njump.me/${user.nostr}", context) 
                      : null
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // BESTÄTIGEN BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onConfirm, // Führt deine existierende Logik aus
                child: const Text(
                  "DATEN SIND KORREKT -> SCANNEN",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon, VoidCallback? onTap) {
    bool isLink = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: isLink ? cOrange : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    value.isEmpty ? "-" : value, 
                    style: TextStyle(color: isLink ? cCyan : Colors.white, fontSize: 16)
                  ),
                ],
              ),
            ),
            if (isLink) const Icon(Icons.open_in_new, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}