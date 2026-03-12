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
import 'package:flutter_svg/flutter_svg.dart';
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
          SliverAppBar(
            pinned: true,
            backgroundColor: cDark,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: cTextSecondary),
              onPressed: () => Navigator.pop(context),
            ),
            title: SvgPicture.asset('assets/images/einundzwanzig_logo.svg', height: 16),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, color: cTextSecondary, size: 18),
                tooltip: 'Portal öffnen',
                onPressed: () => _openUrl(context, _portalBase),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(0.5),
              child: Container(height: 0.5, color: cBorder),
            ),
          ),

          // ===== CONTENT =====
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ===== SCHNELLZUGRIFF =====
                _buildSectionTitle('SCHNELLZUGRIFF'),
                const SizedBox(height: 10),
                _buildQuickActions(context),

                const SizedBox(height: 28),

                // ===== ENTDECKEN =====
                _buildSectionTitle('ENTDECKEN'),
                const SizedBox(height: 10),
                _buildDiscoverGrid(context),

                const SizedBox(height: 28),

                // ===== VEREIN =====
                _buildSectionTitle('VEREIN'),
                const SizedBox(height: 10),
                _buildVereinSection(context),

                const SizedBox(height: 28),

                // ===== PODCAST & MEDIA =====
                _buildSectionTitle('PODCAST & MEDIA'),
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
  // SECTION TITLE
  // =============================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: cTextTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  // =============================================
  // SCHNELLZUGRIFF
  // =============================================
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(Icons.person_outline, 'Profil', '$_portalBase/profile'),
      _QuickAction(Icons.event_outlined, 'Meetups', '$_portalBase/meetups'),
      _QuickAction(Icons.military_tech_outlined, 'Badges', '$_portalBase/badges'),
      _QuickAction(Icons.hub_outlined, 'Netzwerk', '$_portalBase/network'),
    ];

    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final a = actions[i];
          return GestureDetector(
            onTap: () => _openUrl(context, a.url),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(a.icon, color: cOrange, size: 22),
                  const SizedBox(height: 6),
                  Text(a.label, style: const TextStyle(color: cTextSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // =============================================
  // ENTDECKEN GRID
  // =============================================
  Widget _buildDiscoverGrid(BuildContext context) {
    final items = [
      _DiscoverItem(Icons.map_outlined, 'Meetup-Karte', 'Finde Treffen in deiner Nähe', cOrange, '$_webBase/map'),
      _DiscoverItem(Icons.bar_chart_outlined, 'Statistiken', 'Community Zahlen & Fakten', cCyan, '$_webBase/stats'),
      _DiscoverItem(Icons.school_outlined, 'Lernen', 'Bitcoin Grundlagen', cPurple, '$_webBase/learn'),
      _DiscoverItem(Icons.store_outlined, 'Shop', 'Merchandise & mehr', cOrange, '$_webBase/shop'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _openUrl(context, item.url),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: item.color.withOpacity(0.2), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.color, size: 20),
                const Spacer(),
                Text(item.title, style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle, style: const TextStyle(color: cTextTertiary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================
  // VEREIN SECTION
  // =============================================
  Widget _buildVereinSection(BuildContext context) {
    final links = [
      _LinkItem('Über uns', '$_webBase/about'),
      _LinkItem('Mitglied werden', '$_webBase/membership'),
      _LinkItem('Satzung', '$_webBase/statute'),
      _LinkItem('Impressum', '$_webBase/imprint'),
    ];
    return _buildLinkList(context, links);
  }

  // =============================================
  // MEDIA SECTION
  // =============================================
  Widget _buildMediaSection(BuildContext context) {
    final links = [
      _LinkItem('Podcast', '$_webBase/podcast'),
      _LinkItem('YouTube', 'https://youtube.com/@einundzwanzig'),
      _LinkItem('Nostr', 'https://njump.me/npub1w0rthyjyp2f5gful0gm2500pwyxfrx93a85289xdz0sd6hyef33s6cjnt'),
      _LinkItem('Telegram', 'https://t.me/einundzwanzig'),
    ];
    return _buildLinkList(context, links);
  }

  Widget _buildLinkList(BuildContext context, List<_LinkItem> links) {
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(
        children: links.asMap().entries.map((entry) {
          final i = entry.key;
          final link = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () => _openUrl(context, link.url),
                borderRadius: BorderRadius.circular(kTileRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(
                    children: [
                      Text(link.label, style: const TextStyle(color: cText, fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.open_in_new_rounded, color: cTextTertiary, size: 14),
                    ],
                  ),
                ),
              ),
              if (i < links.length - 1)
                const Divider(height: 0, color: cBorder, thickness: 0.5, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
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
// DATA MODELS
// =============================================
class _DiscoverItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String url;

  _DiscoverItem(this.icon, this.title, this.subtitle, this.color, this.url);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String url;

  _QuickAction(this.icon, this.label, this.url);
}

class _LinkItem {
  final String label;
  final String url;

  _LinkItem(this.label, this.url);
}
