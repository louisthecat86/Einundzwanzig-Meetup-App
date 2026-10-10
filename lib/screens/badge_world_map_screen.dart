import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../models/badge.dart';
import '../utils/share_origin.dart';

/// "Hier war ich überall" — Weltkarte aller Badges mit Standort.
/// Zoombar, teilbar als Bild.
class BadgeWorldMapScreen extends StatefulWidget {
  final List<MeetupBadge> badges;
  const BadgeWorldMapScreen({super.key, required this.badges});

  @override
  State<BadgeWorldMapScreen> createState() => _BadgeWorldMapScreenState();
}

class _BadgeWorldMapScreenState extends State<BadgeWorldMapScreen> {
  final MapController _mapController = MapController();
  final GlobalKey _shareKey = GlobalKey();
  bool _sharing = false;
  MeetupBadge? _selected; // angetippter Marker (zeigt Titel + Datum)
  bool _didFit = false;   // Kamera nur einmal fitten (nicht bei jedem Rebuild)

  List<MeetupBadge> get _located =>
      widget.badges.where((b) => b.lat != 0 || b.lng != 0).toList();

  int get _cityCount => _located.map((b) => b.meetupName).toSet().length;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final located = _located;

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.mapTitle,
            style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        actions: [
          if (located.isNotEmpty)
            IconButton(
              icon: _sharing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: cOrange, strokeWidth: 2))
                  : const Icon(Icons.ios_share_rounded, color: cText, size: 20),
              onPressed: _sharing ? null : _shareImage,
            ),
        ],
      ),
      body: located.isEmpty ? _buildEmpty(t) : _buildMap(t, located),
    );
  }

  Widget _buildEmpty(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.public_off_rounded, color: cTextTertiary, size: 56),
          const SizedBox(height: 20),
          Text(t.mapEmpty, textAlign: TextAlign.center,
              style: const TextStyle(color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(t.mapEmptySub, textAlign: TextAlign.center,
              style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
        ]),
      ),
    );
  }

  /// Fittet die Kamera EINMALIG auf alle Badge-Punkte, sodass alle Nadeln
  /// sichtbar sind. Danach nicht mehr (sonst würde manuelles Zoomen
  /// bei jedem Rebuild zurückgesetzt).
  void _scheduleFit(List<MeetupBadge> located) {
    if (_didFit) return;
    _didFit = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pts = located.map((b) => LatLng(b.lat, b.lng)).toList();
      if (pts.isEmpty) return;
      try {
        if (pts.length == 1) {
          _mapController.move(pts.first, 11);
        } else {
          _mapController.fitCamera(CameraFit.coordinates(
            coordinates: pts,
            padding: const EdgeInsets.all(60),
            maxZoom: 12,
          ));
        }
      } catch (_) {}
    });
  }

  Widget _buildMap(AppLocalizations t, List<MeetupBadge> located) {
    // Startzentrum grob aus dem ersten Punkt; die Kamera wird nach dem
    // ersten Frame auf alle Punkte gefittet (_fitMap), damit immer ALLE
    // Nadeln sichtbar sind — auch bei weit verstreuten Orten.
    final firstPoint = LatLng(located.first.lat, located.first.lng);

    final markers = located.map((b) => Marker(
      point: LatLng(b.lat, b.lng),
      width: 40, height: 40,
      child: GestureDetector(
        onTap: () => setState(() => _selected = b),
        child: _badgeMarker(),
      ),
    )).toList();

    _scheduleFit(located);

    return Column(children: [
      // Teilbarer Bereich: Karte + Statistik-Leiste
      Expanded(
        child: RepaintBoundary(
          key: _shareKey,
          child: Stack(children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: firstPoint,
                initialZoom: located.length == 1 ? 11 : 4,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'space.einundzwanzig.meetup',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            // Statistik-Overlay oben
            Positioned(
              top: 12, left: 12, right: 12,
              child: _buildStatsBar(t, located),
            ),
            // Info-Karte zum angetippten Marker (Titel + Datum)
            if (_selected != null)
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: _buildMarkerInfo(t, _selected!),
              ),
          ]),
        ),
      ),
      // Teilen-Button unten
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: cOrange, foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _sharing ? null : _shareImage,
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: Text(t.mapShareButton, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _buildStatsBar(AppLocalizations t, List<MeetupBadge> located) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cOrange.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _stat('${located.length}', t.mapStatMeetups),
        _statDivider(),
        _stat('$_cityCount', t.mapStatCities),
      ]),
    );
  }

  Widget _stat(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(color: cOrange, fontSize: 22, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: cText, fontSize: 11, fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _statDivider() => Container(width: 0.5, height: 32, color: cTileBorder);

  /// Info-Karte zum angetippten Marker: Titel des Meetups + Datum.
  /// Macht die Trennung klar — Position = GPS-Ort, Titel = Meetup-Name.
  Widget _buildMarkerInfo(AppLocalizations t, MeetupBadge b) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cOrange.withValues(alpha: 0.4), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12)],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: cOrange.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.bolt_rounded, color: cOrange, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.meetupName,
                style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text('${b.date.day}.${b.date.month}.${b.date.year}',
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: cTextTertiary, size: 18),
          onPressed: () => setState(() => _selected = null),
        ),
      ]),
    );
  }

  Widget _badgeMarker() {
    return Container(
      decoration: BoxDecoration(
        color: cOrange,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
      ),
      child: const Icon(Icons.bolt_rounded, color: Colors.black, size: 20),
    );
  }

  Future<void> _shareImage() async {
    // Marker-Info schließen, damit sie nicht im geteilten Bild erscheint
    setState(() { _selected = null; _sharing = true; });
    // Anker vor jeglichem await holen — warum: share_origin.dart (Issue #73).
    final shareOrigin = shareOriginFor(context);
    try {
      // kurzer Frame-Delay, damit Tiles gezeichnet sind
      await Future.delayed(const Duration(milliseconds: 300));
      final boundary = _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) { setState(() => _sharing = false); return; }
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) { setState(() => _sharing = false); return; }

      // Bytes direkt teilen statt selbst eine Datei zu schreiben —
      // path_provider hat keine Web-Implementierung. share_plus legt die
      // temporaere Datei auf iOS/Android selbst an. `name` greift im Web,
      // `fileNameOverrides` nativ.
      final fileName = 'badge_worldmap_${DateTime.now().millisecondsSinceEpoch}.png';

      if (!mounted) return;
      final t = AppLocalizations.of(context);
      await Share.shareXFiles(
        [XFile.fromData(byteData.buffer.asUint8List(), mimeType: 'image/png', name: fileName)],
        fileNameOverrides: [fileName],
        text: t.mapShareText(_located.length),
        sharePositionOrigin: shareOrigin,
      );
    } catch (_) {
      // still: kein harter Fehler beim Teilen
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
