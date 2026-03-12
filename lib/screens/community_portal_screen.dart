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
