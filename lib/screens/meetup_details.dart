import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models/meetup.dart';

class MeetupDetailsScreen extends StatelessWidget {
  final Meetup meetup;

  const MeetupDetailsScreen({super.key, required this.meetup});

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiert'),
        backgroundColor: cOrange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        title: Text(meetup.city.toUpperCase()),
        actions: [
          if (meetup.portalLink.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Im Portal öffnen',
              onPressed: () {
                // TODO: URL launcher für portalLink
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Logo
            if (meetup.logoUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: cCard,
                  border: Border(
                    bottom: BorderSide(color: cBorder, width: 1),
                  ),
                ),
                child: Image.network(
                  meetup.logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported, 
                      size: 80, color: cTextTertiary);
                  },
                ),
              ),

            // Titel & Standort
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: cOrange),
                        ),
                        child: Text(
                          meetup.country,
                          style: const TextStyle(
                            color: cOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    meetup.city,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (meetup.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      meetup.description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: cTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Termine Info
            _buildInfoCard(
              context,
              icon: Icons.event,
              iconColor: cCyan,
              title: 'TERMINE',
              children: [
                Text(
                  'Aktuelle Termine findest du in der Telegram-Gruppe oder auf der Website des Meetups.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cTextSecondary,
                  ),
                ),
              ],
            ),

            // Links & Kontakte
            _buildInfoCard(
              context,
              icon: Icons.link,
              iconColor: cOrange,
              title: 'LINKS & KONTAKTE',
              children: [
                if (meetup.telegramLink.isNotEmpty)
                  _buildLinkTile(
                    context,
                    icon: Icons.send,
                    label: 'Telegram',
                    value: meetup.telegramLink,
                    onTap: () {
                      // TODO: URL launcher
                    },
                  ),
                if (meetup.website.isNotEmpty)
                  _buildLinkTile(
                    context,
                    icon: Icons.language,
                    label: 'Website',
                    value: meetup.website,
                    onTap: () {
                      // TODO: URL launcher
                    },
                  ),
                if (meetup.twitterUsername.isNotEmpty)
                  _buildLinkTile(
                    context,
                    icon: Icons.alternate_email,
                    label: 'Twitter',
                    value: '@${meetup.twitterUsername}',
                    onTap: () {
                      // TODO: URL launcher zu Twitter
                    },
                  ),
                if (meetup.nostrNpub.isNotEmpty)
                  _buildLinkTile(
                    context,
                    icon: Icons.key,
                    label: 'Nostr',
                    value: meetup.nostrNpub.substring(0, 20) + '...',
                    onTap: () {
                      _copyToClipboard(context, meetup.nostrNpub, 'Nostr npub');
                    },
                  ),
                if (meetup.telegramLink.isEmpty && 
                    meetup.website.isEmpty && 
                    meetup.twitterUsername.isEmpty &&
                    meetup.nostrNpub.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Keine Kontaktdaten verfügbar',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cTextTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),

            // Standort
            if (meetup.lat != 0.0 && meetup.lng != 0.0)
              _buildInfoCard(
                context,
                icon: Icons.location_on,
                iconColor: Colors.red,
                title: 'STANDORT',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.map, color: cTextSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '${meetup.lat.toStringAsFixed(4)}, ${meetup.lng.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                            color: cTextSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Google Maps öffnen
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Route'),
                          style: TextButton.styleFrom(
                            foregroundColor: cCyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLinkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: cBorder)),
        ),
        child: Row(
          children: [
            Icon(icon, color: cTextSecondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cTextTertiary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cCyan,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: cTextTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}
