import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';

class BadgeDetailsScreen extends StatefulWidget {
  final MeetupBadge badge;

  const BadgeDetailsScreen({super.key, required this.badge});

  @override
  State<BadgeDetailsScreen> createState() => _BadgeDetailsScreenState();
}

class _BadgeDetailsScreenState extends State<BadgeDetailsScreen> {
  void _shareBadge() async {
    final user = await UserProfile.load();
    final reputationText = widget.badge.toReputationString();
    final hash = widget.badge.getVerificationHash();
    
    final shareText = '''
🏆 EINUNDZWANZIG MEETUP BADGE

$reputationText

Hash: $hash
${user.nostrNpub.isNotEmpty ? 'Npub: ${user.nostrNpub.substring(0, 20)}...' : ''}

✅ Proof of Attendance
Verifizierbar über die Einundzwanzig Meetup App
    ''';
    
    try {
      await Share.share(
        shareText,
        subject: 'Mein Einundzwanzig Badge - ${widget.badge.meetupName}',
      );
    } catch (e) {
      // Fallback für Web: In Zwischenablage kopieren
      await Clipboard.setData(ClipboardData(text: shareText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Badge-Info in Zwischenablage kopiert'),
            backgroundColor: cOrange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.badge.meetupName.toUpperCase()),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Badge teilen (oder kopieren)',
            onPressed: _shareBadge,
          ),
        ],
      ),
      backgroundColor: cDark,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- HEADER: DAS BADGE ---
              Container(
                margin: const EdgeInsets.all(20),
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cCard,
                  border: Border.all(color: cOrange.withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: cOrange.withOpacity(0.15),
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    )
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Das Icon (verified)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cOrange.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified, size: 80, color: cOrange),
                    ),
                    const SizedBox(height: 30),
                    
                    // Name des Meetups
                    Text(
                      widget.badge.meetupName.toUpperCase(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 20),

                    // Datum
                    Text(
                      "BLOCKZEIT (DATUM)",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cTextSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${widget.badge.date.day}.${widget.badge.date.month}.${widget.badge.date.year}",
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    // Erklärungstext
                    const Text(
                      "PROOF OF ATTENDANCE",
                      style: TextStyle(color: cOrange, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst. Es ist lokal in deiner App gespeichert.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              
              // Share Button
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareBadge,
                  icon: const Icon(Icons.share),
                  label: const Text('BADGE TEILEN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              
              // Schließen Button
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text("SCHLIESSEN", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}