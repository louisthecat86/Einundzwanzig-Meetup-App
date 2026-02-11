import 'dart:ui'; // Wichtig für den Blur-Effekt
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../models/badge.dart';
import '../models/user.dart';
import '../models/meetup.dart'; // NEU: Damit wir die Bilder laden können
import '../services/meetup_service.dart'; // NEU: Service zum Laden
import 'badge_details.dart';
import 'reputation_qr.dart';

class BadgeWalletScreen extends StatefulWidget {
  const BadgeWalletScreen({super.key});

  @override
  State<BadgeWalletScreen> createState() => _BadgeWalletScreenState();
}

class _BadgeWalletScreenState extends State<BadgeWalletScreen> {
  // Wir speichern alle Meetups hier, um die Bilder zu finden
  List<Meetup> _allMeetups = []; 

  @override
  void initState() {
    super.initState();
    _loadMeetupImages();
  }

  // Wir laden die Meetups im Hintergrund, um an die coverImagePaths zu kommen
  Future<void> _loadMeetupImages() async {
    final meetups = await MeetupService.fetchMeetups();
    if (mounted) {
      setState(() {
        _allMeetups = meetups;
      });
    }
  }

  void _shareAllBadges() async {
    if (myBadges.isEmpty) return;
    
    final user = await UserProfile.load();
    final uniqueMeetups = myBadges.map((b) => b.meetupName).toSet().length;
    
    final summary = '''
🏆 MEINE EINUNDZWANZIG REPUTATION

Total Badges: ${myBadges.length}
Meetups besucht: $uniqueMeetups
${user.nostrNpub.isNotEmpty ? 'Nostr: ${user.nostrNpub.substring(0, 24)}...' : ''}

📍 Besuchte Meetups:
${myBadges.map((b) => '  • ${b.meetupName} (${b.date.day}.${b.date.month}.${b.date.year})').join('\n')}

✅ Proof of Attendance
Verifizierbar über die Einundzwanzig Meetup App

---
Exportiert am ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}
    ''';
    
    try {
      await Share.share(
        summary,
        subject: 'Meine Einundzwanzig Meetup Reputation',
      );
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: summary));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reputation in Zwischenablage kopiert'),
            backgroundColor: cOrange,
          ),
        );
      }
    }
  }

  void _shareReputationJSON() async {
    if (myBadges.isEmpty) return;
    
    final user = await UserProfile.load();
    final json = MeetupBadge.exportBadgesForReputation(myBadges, user.nostrNpub);
    
    try {
      await Share.share(
        json,
        subject: 'Einundzwanzig Reputation (JSON)',
      );
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON-Daten in Zwischenablage kopiert'),
            backgroundColor: cOrange,
          ),
        );
      }
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "REPUTATION TEILEN",
              style: TextStyle(
                color: cOrange,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.share, color: cCyan),
              title: const Text("Als Text teilen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Lesbar für alle (wird im Web kopiert)", style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareAllBadges();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: cOrange),
              title: const Text("QR-Code anzeigen", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Zum Scannen vor Ort", style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReputationQRScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.code, color: cPurple),
              title: const Text("Als JSON exportieren", style: TextStyle(color: Colors.white)),
              subtitle: const Text("Mit Checksumme zur Verifizierung", style: TextStyle(color: cTextSecondary, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _shareReputationJSON();
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Abbrechen", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("BADGE WALLET"),
        actions: myBadges.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Reputation teilen',
                  onPressed: _showShareOptions,
                ),
              ]
            : null,
      ),
      body: myBadges.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    size: 100,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Noch keine Badges gesammelt",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: cTextSecondary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Besuche Meetups und scanne NFC-Tags um Badges zu sammeln!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85, // Etwas quadratischer für das Bild
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: myBadges.length,
              itemBuilder: (context, index) {
                final badge = myBadges[index];
                
                // Wir suchen das passende Meetup-Objekt für das Bild
                final matchingMeetup = _allMeetups.where((m) => 
                  badge.meetupName.toLowerCase().contains(m.city.toLowerCase())
                ).firstOrNull;

                return _buildBadgeCard(context, badge, matchingMeetup);
              },
            ),
    );
  }

  Widget _buildBadgeCard(BuildContext context, MeetupBadge badge, Meetup? meetup) {
    // Prüfen ob wir ein Bild haben
    final hasImage = meetup != null && meetup.coverImagePath.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BadgeDetailsScreen(badge: badge),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.hardEdge, // Damit das Bild nicht übersteht
        decoration: BoxDecoration(
          color: cCard, // Fallback Farbe
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cOrange.withOpacity(0.5),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: cOrange.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. DAS HINTERGRUNDBILD
            if (hasImage)
              Image.network(
                meetup.coverImagePath,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: cCard), // Bei Fehler dunkel bleiben
              ),

            // 2. DER WEICHZEICHNER (BLUR)
            if (hasImage)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                child: Container(
                  color: Colors.black.withOpacity(0.2), // Leichte Abdunklung
                ),
              ),

            // 3. DER GELBE/ORANGE SCHLEIER
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cOrange.withOpacity(hasImage ? 0.3 : 0.1), // Transparenter wenn Bild da ist
                    cPurple.withOpacity(hasImage ? 0.3 : 0.1),
                  ],
                ),
              ),
            ),

            // 4. DER INHALT (Text & Icon)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), // Dunklerer Hintergrund für Kontrast
                      shape: BoxShape.circle,
                      border: Border.all(color: cOrange.withOpacity(0.5))
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: cOrange,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  
                  // Meetup Name (Mit Schatten für Lesbarkeit)
                  Text(
                    badge.meetupName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  
                  // Datum
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: cOrange),
                      const SizedBox(width: 4),
                      Text(
                        "${badge.date.day}.${badge.date.month}.${badge.date.year}",
                        style: const TextStyle(
                          color: Colors.white, // Weiß liest sich auf Bildern besser
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: [
                             Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Badge-Nummer/Index
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "#${myBadges.indexOf(badge) + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}