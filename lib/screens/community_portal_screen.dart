// ============================================
// COMMUNITY PORTAL SCREEN — Redesign v2
// ============================================
// Visuell an Einundzwanzig Brand Guidelines angepasst:
//   Farben: #F7931A, #00B4CF, #A915FF, #151515
//   Schrift: Inconsolata (via Google Fonts im Theme)
//
// Struktur:
//   1. Hero-Header mit Brand-Identität
//   2. Schnellzugriff (horizontale Kacheln)
//   3. Entdecken (2er-Grid mit großen Kacheln + 4er Grid)
//   4. Verein & Media (gruppierte Listen)
//   5. Footer
// ============================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class CommunityPortalScreen extends StatelessWidget {
  const CommunityPortalScreen({super.key});

  static const String _portalBase = 'https://portal.einundzwanzig.space';
  static const String _webBase = 'https://einundzwanzig.space';

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Konnte $url nicht öffnen"), backgroundColor: cRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      body: CustomScrollView(
        slivers: [
          // ===== COLLAPSING APP BAR =====
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: cDark,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: cOrange),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new, color: cCyan, size: 20),
                tooltip: 'Portal öffnen',
                onPressed: () => _openUrl(context, _portalBase),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(context),
            ),
          ),

          // ===== CONTENT =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ===== SCHNELLZUGRIFF =====
                _buildSectionTitle('SCHNELLZUGRIFF', cOrange),
                const SizedBox(height: 10),
                _buildQuickActions(context),

                const SizedBox(height: 28),

                // ===== ENTDECKEN =====
                _buildSectionTitle('ENTDECKEN', cCyan),
                const SizedBox(height: 10),
                _buildDiscoverGrid(context),

                const SizedBox(height: 28),

                // ===== VEREIN =====
                _buildSectionTitle('VEREIN', Colors.amber),
                const SizedBox(height: 10),
                _buildVereinSection(context),

                const SizedBox(height: 28),

                // ===== PODCAST & MEDIA =====
                _buildSectionTitle('PODCAST & MEDIA', cPurple),
                const SizedBox(height: 10),
                _buildMediaSection(context),

                const SizedBox(height: 32),

                // ===== FOOTER =====
                _buildFooter(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // HERO HEADER
  // =============================================
  Widget _buildHero(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cOrange.withOpacity(0.12),
            cDark,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Logo-Icon
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cOrange, cOrange.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('21', style: TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -1,
                      )),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EINUNDZWANZIG',
                          style: TextStyle(
                            color: cOrange, fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        Text('Community Portal',
                          style: TextStyle(
                            color: cTextSecondary, fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Login-Hinweis
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.amber.shade400, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Login via Lightning oder Nostr',
                      style: TextStyle(color: Colors.amber.shade300, fontSize: 10,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // SECTION TITLE
  // =============================================
  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(
          color: color, fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        )),
      ],
    );
  }

  // =============================================
  // SCHNELLZUGRIFF — Horizontale Kacheln
  // =============================================
  Widget _buildQuickActions(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          _quickTile(context,
            icon: Icons.login, label: 'Anmelden', color: cCyan,
            url: '$_portalBase/auth/ln'),
          _quickTile(context,
            icon: Icons.event_note, label: 'Termin\neintragen', color: cGreen,
            url: '$_portalBase/de/meetup/overview'),
          _quickTile(context,
            icon: Icons.campaign, label: 'Shoutout\nsenden', color: cOrange,
            url: 'https://shoutout.einundzwanzig.space'),
          _quickTile(context,
            icon: Icons.dashboard, label: 'Mein\nDashboard', color: cPurple,
            url: '$_portalBase/de/dashboard'),
          _quickTile(context,
            icon: Icons.favorite, label: 'Projekt\nbewerben', color: cRed,
            url: '$_portalBase/de/verein/project-proposals'),
        ],
      ),
    );
  }

  Widget _quickTile(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required String url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _openUrl(context, url),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: cTextSecondary, fontSize: 9,
                  fontWeight: FontWeight.w700, height: 1.2,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // ENTDECKEN — 2 große Kacheln + 4er Grid
  // =============================================
  Widget _buildDiscoverGrid(BuildContext context) {
    final items = [
      _DiscoverItem(Icons.map_outlined, 'Weltkarte', '288 Meetups', cCyan,
        '$_portalBase/de/map-world'),
      _DiscoverItem(Icons.location_on_outlined, 'Meetups DE', '208 Gruppen', cOrange,
        '$_portalBase/de/meetups'),
      _DiscoverItem(Icons.school_outlined, 'Kurse', 'Bitcoin lernen', cGreen,
        '$_portalBase/de/courses'),
      _DiscoverItem(Icons.auto_stories_outlined, 'Bibliothek', 'Bücher & mehr', cPurple,
        '$_portalBase/de/library/library-item'),
      _DiscoverItem(Icons.newspaper_outlined, 'News', 'Artikel', Colors.amber,
        '$_portalBase/de/news'),
      _DiscoverItem(Icons.dns_outlined, 'Services', 'Self-Hosted', Colors.teal,
        '$_portalBase/de/services'),
      _DiscoverItem(Icons.people_outline, 'Plebs', 'auf Nostr', cCyan,
        '$_portalBase/de/plebs-on-nostr'),
      _DiscoverItem(Icons.place_outlined, 'Städte', '249 Orte', cTextTertiary,
        '$_portalBase/de/cities'),
    ];

    return Column(
      children: [
        // Top 2: Große Kacheln
        Row(
          children: [
            Expanded(child: _discoverTileLarge(context, items[0])),
            const SizedBox(width: 10),
            Expanded(child: _discoverTileLarge(context, items[1])),
          ],
        ),
        const SizedBox(height: 10),
        // Rest: 4er-Grid
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
          children: items.skip(2).map((item) =>
            _discoverTileSmall(context, item)
          ).toList(),
        ),
      ],
    );
  }

  Widget _discoverTileLarge(BuildContext context, _DiscoverItem item) {
    return GestureDetector(
      onTap: () => _openUrl(context, item.url),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: item.color.withOpacity(0.2)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.color.withOpacity(0.08),
              cCard,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                Text(item.subtitle, style: TextStyle(
                  color: item.color.withOpacity(0.8), fontSize: 10,
                  fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _discoverTileSmall(BuildContext context, _DiscoverItem item) {
    return GestureDetector(
      onTap: () => _openUrl(context, item.url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(item.icon, color: item.color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(item.title, style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
            Text(item.subtitle, style: TextStyle(
              color: Colors.grey.shade600, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  // =============================================
  // VEREIN
  // =============================================
  Widget _buildVereinSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _compactRow(context,
            icon: Icons.info_outline, color: Colors.amber,
            title: 'Über den Verein',
            subtitle: 'Gegr. 21. April 2021 · Zug, Schweiz',
            url: '$_webBase/verein/',
            topRadius: true,
          ),
          Divider(height: 1, color: cBorder.withOpacity(0.5), indent: 56),
          _compactRow(context,
            icon: Icons.volunteer_activism, color: cOrange,
            title: 'Spenden',
            subtitle: 'Bitcoin-only · Lightning oder On-Chain',
            url: '$_webBase/spenden/',
            bottomRadius: true,
          ),
        ],
      ),
    );
  }

  // =============================================
  // PODCAST & MEDIA
  // =============================================
  Widget _buildMediaSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cPurple.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _compactRow(context,
            icon: Icons.podcasts, color: cPurple,
            title: 'Podcast',
            subtitle: 'News · Interviews · Lesestunde · Der Weg',
            url: '$_webBase/podcast/',
            topRadius: true,
          ),
          Divider(height: 1, color: cBorder.withOpacity(0.5), indent: 56),
          _compactRow(context,
            icon: Icons.play_circle_outline, color: Colors.red,
            title: 'YouTube',
            subtitle: 'Community-Tutorials & mehr',
            url: 'https://www.youtube.com/c/EinundzwanzigPodcast',
          ),
          Divider(height: 1, color: cBorder.withOpacity(0.5), indent: 56),
          _compactRow(context,
            icon: Icons.storefront_outlined, color: cOrange,
            title: 'Shops',
            subtitle: 'Bitcoin-Shops der Community',
            url: '$_webBase/shops/',
            bottomRadius: true,
          ),
        ],
      ),
    );
  }

  // =============================================
  // COMPACT ROW
  // =============================================
  Widget _compactRow(BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String url,
    bool topRadius = false,
    bool bottomRadius = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openUrl(context, url),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(topRadius ? 16 : 0),
          bottom: Radius.circular(bottomRadius ? 16 : 0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(subtitle, style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 10)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade700, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================
  // FOOTER
  // =============================================
  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 40, height: 2,
            decoration: BoxDecoration(
              color: cOrange.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          Text('Toximalistisches Infotainment',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11,
              fontStyle: FontStyle.italic, letterSpacing: 0.3)),
          Text('für bullishe Bitcoiner.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11,
              fontStyle: FontStyle.italic, letterSpacing: 0.3)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _openUrl(context, _webBase),
            child: Text('einundzwanzig.space',
              style: TextStyle(color: cOrange.withOpacity(0.5), fontSize: 11,
                decoration: TextDecoration.underline,
                decorationColor: cOrange.withOpacity(0.3))),
          ),
        ],
      ),
    );
  }
}

// =============================================
// DATA MODEL
// =============================================
class _DiscoverItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String url;

  _DiscoverItem(this.icon, this.title, this.subtitle, this.color, this.url);
}
