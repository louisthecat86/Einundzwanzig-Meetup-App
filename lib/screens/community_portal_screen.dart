// ============================================
// COMMUNITY PORTAL SCREEN — Brücke zum Portal
// ============================================
// Bietet direkten Zugang zu allen Funktionen des
// Einundzwanzig-Portals (portal.einundzwanzig.space)
// und der Hauptwebseite (einundzwanzig.space).
//
// Aktuell: Deep-Links die im Browser öffnen
// Zukunft: Native API-Anbindung wenn verfügbar
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class CommunityPortalScreen extends StatelessWidget {
  const CommunityPortalScreen({super.key});

  // =============================================
  // PORTAL URLS
  // =============================================
  static const String _portalBase = 'https://portal.einundzwanzig.space';
  static const String _webBase = 'https://einundzwanzig.space';

  // =============================================
  // URL ÖFFNEN
  // =============================================
  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Konnte $url nicht öffnen"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: const Text("COMMUNITY"),
        actions: [
          // Direkt zum Portal
          IconButton(
            icon: const Icon(Icons.open_in_new, color: cCyan, size: 20),
            tooltip: 'Portal öffnen',
            onPressed: () => _openUrl(context, _portalBase),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cOrange.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: cOrange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hub, color: cOrange, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text("Einundzwanzig Portal",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(
                    "Dein Zugang zur Bitcoin-Community im DACH-Raum",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  // Login-Hinweis
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Icon(Icons.bolt, color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        "Login via Lightning oder Nostr — deine Schlüssel, dein Account",
                        style: TextStyle(color: Colors.amber.shade300, fontSize: 10),
                      )),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== AKTIONEN (Login nötig) =====
            _sectionHeader(Icons.flash_on, "AKTIONEN", Colors.green,
              subtitle: "Login nötig — öffnet im Browser"),
            const SizedBox(height: 10),

            _actionTile(
              context,
              icon: Icons.login,
              color: cCyan,
              title: "Anmelden",
              subtitle: "Lightning oder Nostr Login",
              url: '$_portalBase/auth/ln',
            ),
            _actionTile(
              context,
              icon: Icons.add_circle_outline,
              color: Colors.green,
              title: "Meetup-Termin eintragen",
              subtitle: "Neuen Termin für dein Meetup erstellen",
              url: '$_portalBase/de/meetup/overview',
              loginRequired: true,
            ),
            _actionTile(
              context,
              icon: Icons.campaign,
              color: Colors.amber,
              title: "Shoutout senden",
              subtitle: "5.000 Sats — wird im Podcast vorgelesen",
              url: 'https://shoutout.einundzwanzig.space',
            ),
            _actionTile(
              context,
              icon: Icons.favorite,
              color: Colors.red,
              title: "Projekt für Förderung bewerben",
              subtitle: "Verein unterstützt Bitcoin-Projekte",
              url: '$_portalBase/de/verein/project-proposals',
              loginRequired: true,
            ),
            _actionTile(
              context,
              icon: Icons.dashboard,
              color: cPurple,
              title: "Mein Portal-Dashboard",
              subtitle: "Dein Profil, deine Meetups, deine Termine",
              url: '$_portalBase/de/dashboard',
              loginRequired: true,
            ),

            const SizedBox(height: 24),

            // ===== ENTDECKEN (öffentlich) =====
            _sectionHeader(Icons.explore, "ENTDECKEN", cCyan,
              subtitle: "Kein Login nötig"),
            const SizedBox(height: 10),

            // 2er-Grid für Entdecken
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _gridTile(context, Icons.map, "Weltkarte", "288 Meetups", cCyan,
                  '$_portalBase/de/map-world'),
                _gridTile(context, Icons.location_on, "Meetups DE", "208 Gruppen", cOrange,
                  '$_portalBase/de/meetups'),
                _gridTile(context, Icons.school, "Kurse", "Bitcoin lernen", Colors.green,
                  '$_portalBase/de/courses'),
                _gridTile(context, Icons.menu_book, "Bibliothek", "Bücher & mehr", cPurple,
                  '$_portalBase/de/library/library-item'),
                _gridTile(context, Icons.article, "News", "Community-Artikel", Colors.amber,
                  '$_portalBase/de/news'),
                _gridTile(context, Icons.dns, "Services", "Self-Hosted", Colors.teal,
                  '$_portalBase/de/services'),
                _gridTile(context, Icons.people, "Plebs", "auf Nostr", Colors.blue,
                  '$_portalBase/de/plebs-on-nostr'),
                _gridTile(context, Icons.place, "Städte", "249 Orte", Colors.grey,
                  '$_portalBase/de/cities'),
              ],
            ),

            const SizedBox(height: 24),

            // ===== VEREIN =====
            _sectionHeader(Icons.account_balance, "VEREIN EINUNDZWANZIG", Colors.amber,
              subtitle: "Gegründet 21. April 2021 · Zug, Schweiz"),
            const SizedBox(height: 10),

            _actionTile(
              context,
              icon: Icons.info_outline,
              color: Colors.amber,
              title: "Über den Verein",
              subtitle: "Zweck: Vorbereitung auf die Hyperbitcoinization",
              url: '$_webBase/verein/',
            ),
            _actionTile(
              context,
              icon: Icons.volunteer_activism,
              color: Colors.red,
              title: "Spenden",
              subtitle: "Bitcoin-only via Lightning oder On-Chain",
              url: '$_webBase/spenden/',
            ),

            const SizedBox(height: 24),

            // ===== PODCAST & MEDIA =====
            _sectionHeader(Icons.headphones, "PODCAST & MEDIA", cPurple),
            const SizedBox(height: 10),

            _actionTile(
              context,
              icon: Icons.podcasts,
              color: cPurple,
              title: "Podcast",
              subtitle: "News, Interviews, Lesestunde, Der Weg",
              url: '$_webBase/podcast/',
            ),
            _actionTile(
              context,
              icon: Icons.play_circle,
              color: Colors.red,
              title: "YouTube",
              subtitle: "Community-Tutorials & mehr",
              url: 'https://www.youtube.com/c/EinundzwanzigPodcast',
            ),
            _actionTile(
              context,
              icon: Icons.shopping_bag,
              color: cOrange,
              title: "Shops",
              subtitle: "Bitcoin-Shops der Community",
              url: '$_webBase/shops/',
            ),

            const SizedBox(height: 24),

            // ===== FOOTER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                Text("Toximalistisches Infotainment",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic)),
                Text("für bullishe Bitcoiner.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _openUrl(context, _webBase),
                  child: Text("einundzwanzig.space",
                    style: TextStyle(color: cOrange.withOpacity(0.6), fontSize: 11, decoration: TextDecoration.underline)),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================
  // SECTION HEADER
  // =============================================
  Widget _sectionHeader(IconData icon, String title, Color color, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            if (subtitle != null)
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
          ],
        )),
      ],
    );
  }

  // =============================================
  // ACTION TILE (listenform, volle Breite)
  // =============================================
  Widget _actionTile(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String url,
    bool loginRequired = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(context, url),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cBorder),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    if (loginRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.bolt, color: Colors.amber.shade300, size: 10),
                          const SizedBox(width: 2),
                          Text("Login", style: TextStyle(color: Colors.amber.shade300, fontSize: 9, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              )),
              Icon(Icons.open_in_new, color: Colors.grey.shade700, size: 16),
            ]),
          ),
        ),
      ),
    );
  }

  // =============================================
  // GRID TILE (kompakt, 2er-Grid)
  // =============================================
  Widget _gridTile(BuildContext context, IconData icon, String title, String subtitle, Color color, String url) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUrl(context, url),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}