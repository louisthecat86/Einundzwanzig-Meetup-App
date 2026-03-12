// ============================================
// COMMUNITY PORTAL SCREEN — Redesign v2
// ============================================
// Einundzwanzig Brand: #F7931A, #00B4CF, #A915FF, #151515
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';

class CommunityPortalScreen extends StatelessWidget {
  const CommunityPortalScreen({super.key});

  static const String _portalBase  = 'https://portal.einundzwanzig.space';
  static const String _webBase     = 'https://einundzwanzig.space';

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Konnte $url nicht öffnen"),
            backgroundColor: cRed,
          ),
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── SCHNELLZUGRIFF ──
                _buildSectionTitle('SCHNELLZUGRIFF'),
                const SizedBox(height: 10),
                _buildQuickActions(context),

                const SizedBox(height: 28),

                // ── ENTDECKEN ──
                _buildSectionTitle('ENTDECKEN'),
                const SizedBox(height: 10),
                _buildDiscoverGrid(context),

                const SizedBox(height: 28),

                // ── VEREIN ──
                _buildSectionTitle('VEREIN'),
                const SizedBox(height: 10),
                _buildVereinSection(context),

                const SizedBox(height: 28),

                // ── PODCAST & MEDIA ──
                _buildSectionTitle('PODCAST & MEDIA'),
                const SizedBox(height: 10),
                _buildMediaSection(context),

                const SizedBox(height: 28),

                // ── SOZIALE NETZWERKE ──
                _buildSectionTitle('SOZIALE NETZWERKE'),
                const SizedBox(height: 10),
                _buildSocialSection(context),

                const SizedBox(height: 40),

                _buildFooter(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // SECTION TITLE
  // ─────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        title,
        style: const TextStyle(
          color: cTextTertiary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // SCHNELLZUGRIFF — horizontale Kacheln
  // ─────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    final items = [
      _QuickItem(Icons.person_outline_rounded, 'Profil',    '$_portalBase/'),
      _QuickItem(Icons.event_rounded,          'Meetups',   '$_webBase/meetups/'),
      _QuickItem(Icons.podcasts_rounded,       'Podcast',   '$_webBase/podcast/'),
      _QuickItem(Icons.campaign_rounded,       'Shoutout',  'https://shoutout.einundzwanzig.space'),
      _QuickItem(Icons.favorite_rounded,       'Spenden',   '$_webBase/spenden/'),
    ];

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () => _openUrl(ctx, item.url),
            child: Container(
              width: 68,
              decoration: BoxDecoration(
                color: cCard,
                borderRadius: BorderRadius.circular(kTileRadius),
                border: Border.all(color: cTileBorder, width: 0.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: cOrange, size: 20),
                  const SizedBox(height: 6),
                  Text(item.label,
                    style: const TextStyle(color: cTextSecondary, fontSize: 9.5, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // ENTDECKEN — 2-spaltiges Grid
  // ─────────────────────────────────────────
  Widget _buildDiscoverGrid(BuildContext context) {
    final items = [
      _GridItem(Icons.map_outlined,         'Meetup-Karte',   'Treffen in deiner Nähe',   cOrange,  '$_webBase/meetups/'),
      _GridItem(Icons.store_outlined,       'Shop',           'Merch & Bitcoin-Produkte', cCyan,    '$_webBase/shops/'),
      _GridItem(Icons.hub_outlined,         'Portal',         'Dein Profil & Badges',     cPurple,  '$_portalBase/'),
      _GridItem(Icons.record_voice_over_rounded, 'Soundboard','Clips & Sounds',           cOrange,  '$_webBase/soundboard/'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.65,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () => _openUrl(ctx, item.url),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: item.color.withOpacity(0.18), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.color, size: 18),
                const Spacer(),
                Text(item.title,
                  style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(item.subtitle,
                  style: const TextStyle(color: cTextTertiary, fontSize: 10),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // VEREIN
  // ─────────────────────────────────────────
  Widget _buildVereinSection(BuildContext context) {
    return _buildLinkList(context, [
      _LinkItem('Über den Verein',     '$_webBase/verein/'),
      _LinkItem('Mitglied werden',     'https://verein.einundzwanzig.space/'),
      _LinkItem('Satzung (PDF)',       '$_webBase/files/Statuten_v1.3.pdf'),
      _LinkItem('Kontakt',             '$_webBase/kontakt/'),
      _LinkItem('Datenschutz',         '$_webBase/datenschutz/'),
    ]);
  }

  // ─────────────────────────────────────────
  // PODCAST & MEDIA
  // ─────────────────────────────────────────
  Widget _buildMediaSection(BuildContext context) {
    return _buildLinkList(context, [
      _LinkItem('Podcast',             '$_webBase/podcast/'),
      _LinkItem('Der Weg (Einsteiger)','$_webBase/podcast/der-weg/'),
      _LinkItem('Interviews',          '$_webBase/podcast/interviews/'),
      _LinkItem('YouTube',             'https://www.youtube.com/c/EinundzwanzigPodcast'),
      _LinkItem('Media & Artikel',     '$_webBase/media/'),
      _LinkItem('Soundcloud',          'https://soundcloud.com/einundzwanzig_beats'),
    ]);
  }

  // ─────────────────────────────────────────
  // SOZIALE NETZWERKE
  // ─────────────────────────────────────────
  Widget _buildSocialSection(BuildContext context) {
    return _buildLinkList(context, [
      _LinkItem('Nostr',       'https://njump.me/npub1qv02xpsc3lhxxx5x7xswf88w3u7kykft9ea7t78tz7ywxf7mxs9qrxujnc'),
      _LinkItem('X / Twitter', 'https://x.com/_einundzwanzig_'),
      _LinkItem('Instagram',   'https://www.instagram.com/einundzwanzig_podcast'),
      _LinkItem('Shoutout senden', 'https://shoutout.einundzwanzig.space'),
    ]);
  }

  // ─────────────────────────────────────────
  // LINK-LISTE (generisch)
  // ─────────────────────────────────────────
  Widget _buildLinkList(BuildContext context, List<_LinkItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(children: [
            InkWell(
              onTap: () => _openUrl(context, item.url),
              borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(kTileRadius))
                : i == items.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(kTileRadius))
                    : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Text(item.label,
                    style: const TextStyle(color: cText, fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  const Icon(Icons.open_in_new_rounded, color: cTextTertiary, size: 13),
                ]),
              ),
            ),
            if (i < items.length - 1)
              const Divider(height: 0, thickness: 0.5, color: cBorder, indent: 16, endIndent: 0),
          ]);
        }).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────
  // FOOTER
  // ─────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Column(children: [
        Container(
          width: 40, height: 2,
          decoration: BoxDecoration(
            color: cOrange.withOpacity(0.25),
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
            style: TextStyle(
              color: cOrange.withOpacity(0.5),
              fontSize: 11,
              decoration: TextDecoration.underline,
              decorationColor: cOrange.withOpacity(0.25),
            )),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────
class _QuickItem {
  final IconData icon;
  final String label;
  final String url;
  _QuickItem(this.icon, this.label, this.url);
}

class _GridItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String url;
  _GridItem(this.icon, this.title, this.subtitle, this.color, this.url);
}

class _LinkItem {
  final String label;
  final String url;
  _LinkItem(this.label, this.url);
}
