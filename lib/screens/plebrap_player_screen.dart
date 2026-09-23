// ============================================
// PLEBRAP PLAYER — Bitcoin-Rap aus der Community
// ============================================
// Streamt die frei veroeffentlichten Songs von plebrap.de (TooBitToFail,
// JustAnotherNode, Hanspanzer u.a.). Titelliste kuratiert und fest
// eingebettet — die Seite ist ein Baukasten ohne API. Neue Songs = Liste
// hier ergaenzen. Cover kommen von plebrap.de, mit Icon-Fallback.
//
// V4V: Der ⚡-Knopf oeffnet die Value-for-Value-Seite der Kuenstler.
// TODO: Sobald deren Lightning-Adresse bestaetigt ist, auf einen direkten
// lightning:-Link umstellen (bewusst NICHT geraten).
//
// Wiedergabe laeuft, solange die App lebt; echte Hintergrund-Wiedergabe
// mit Notification ist Stufe 2 (just_audio_background + Manifest).
// ============================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/plebrap_audio.dart';


class PlebrapPlayerScreen extends StatefulWidget {
  const PlebrapPlayerScreen({super.key});
  @override
  State<PlebrapPlayerScreen> createState() => _PlebrapPlayerScreenState();
}

class _PlebrapPlayerScreenState extends State<PlebrapPlayerScreen> {
  // Alles Zustaendliche lebt im app-weiten PlebrapAudio-Service —
  // dieser Screen ist nur noch eine Ansicht darauf. KEIN dispose des
  // Players: die Musik laeuft nach Verlassen weiter (Dashboard-Mini-Player).
  AudioPlayer get _player => PlebrapAudio.player;

  /// Position unter dem Finger, solange gezogen wird. null = nicht gezogen.
  double? _dragMs;
  int? get _index => PlebrapAudio.index.value;
  bool get _loading => PlebrapAudio.loading.value;
  int _seenErrors = 0;

  void _onChange() {
    if (!mounted) return;
    if (PlebrapAudio.loadErrors.value != _seenErrors) {
      _seenErrors = PlebrapAudio.loadErrors.value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).prLoadError),
        backgroundColor: cRed, behavior: SnackBarBehavior.floating,
      ));
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    PlebrapAudio.ensureWired();
    _seenErrors = PlebrapAudio.loadErrors.value;
    PlebrapAudio.index.addListener(_onChange);
    PlebrapAudio.loading.addListener(_onChange);
    PlebrapAudio.loadErrors.addListener(_onChange);
  }

  @override
  void dispose() {
    PlebrapAudio.index.removeListener(_onChange);
    PlebrapAudio.loading.removeListener(_onChange);
    PlebrapAudio.loadErrors.removeListener(_onChange);
    super.dispose();
  }

  Future<void> _playIndex(int i) => PlebrapAudio.playIndex(i);
  void _next() { PlebrapAudio.next(); }
  void _prev() { PlebrapAudio.prev(); }

  Future<void> _openV4V() async {
    try { await launchUrl(Uri.parse('https://plebrap.de/V4V/'), mode: LaunchMode.externalApplication); } catch (_) {}
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Widget _coverBox(PlebSong? s, double size) => ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: s == null
            ? Container(width: size, height: size, color: cOrange.withValues(alpha: 0.12),
                child: const Icon(Icons.graphic_eq_rounded, color: cOrange, size: 24))
            : Image.network(s.cover, width: size, height: size, fit: BoxFit.cover,
                errorBuilder: (_, e, st) => Container(width: size, height: size,
                    color: cOrange.withValues(alpha: 0.12),
                    child: const Icon(Icons.graphic_eq_rounded, color: cOrange, size: 24))),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final song = _index != null ? kPlebSongs[_index!] : null;

    final albums = <String, List<int>>{};
    for (var i = 0; i < kPlebSongs.length; i++) {
      albums.putIfAbsent(kPlebSongs[i].album, () => []).add(i);
    }

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: const Text('PlebRap', style: TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          TextButton.icon(
            onPressed: _openV4V,
            icon: const Icon(Icons.bolt_rounded, color: cOrange, size: 18),
            label: Text(t.prV4V, style: const TextStyle(color: cOrange, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [
        // ============ NOW PLAYING (Cover als Wasserzeichen, App-Stil) ============
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius + 2),
            border: Border.all(color: cTileBorder, width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kTileRadius + 2),
            child: Stack(children: [
              if (song != null)
                Positioned(right: -20, bottom: -30,
                  child: Opacity(opacity: 0.10,
                    child: Image.network(song.cover, width: 180, height: 180, fit: BoxFit.cover,
                        errorBuilder: (_, e, st) => const SizedBox.shrink()))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  Row(children: [
                    _coverBox(song, 52),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(song?.title ?? t.prPickSong,
                          style: const TextStyle(color: cText, fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(song?.artist ?? 'Plebs together strong',
                          style: const TextStyle(color: cTextSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                  ]),
                  const SizedBox(height: 10),
                  // Zwei Stroeme: DAUER aussen, POSITION innen.
                  //
                  // Vorher wurde die Dauer nur nebenbei gelesen, wenn die
                  // Position sich aenderte. Bei pausiertem Lied kommt aber
                  // keine Position — eine inzwischen bekannte Dauer wurde nie
                  // uebernommen, und der Balken blieb gesperrt. Jetzt zeichnet
                  // er neu, sobald die Dauer feststeht.
                  StreamBuilder<Duration?>(
                    stream: _player.durationStream,
                    initialData: _player.duration,
                    builder: (_, durSnap) => StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (_, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final total = durSnap.data ?? Duration.zero;
                      final max = total.inMilliseconds.toDouble();
                      return Column(children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: cOrange, inactiveTrackColor: cSurface, thumbColor: cOrange,
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          ),
                          // Waehrend des Ziehens zeigt der Balken den WERT UNTER DEM
                          // FINGER, nicht die Position vom Player — gesprungen wird
                          // erst beim Loslassen.
                          //
                          // Vorher loeste jeder Ziehschritt einen seek aus. Die
                          // Position vom Player hinkt aber hinterher, der Balken
                          // wurde bei jedem Neuzeichnen darauf zurueckgesetzt, und
                          // der Daumen sprang zurueck. Mit der Wiedergabeliste ist
                          // der Versatz groesser geworden; ziehen ging praktisch
                          // gar nicht mehr.
                          child: Slider(
                            value: max > 0
                                ? (_dragMs ?? pos.inMilliseconds.toDouble())
                                    .clamp(0, max)
                                    .toDouble()
                                : 0,
                            max: max > 0 ? max : 1,
                            onChanged: max > 0
                                ? (v) => setState(() => _dragMs = v)
                                : null,
                            onChangeEnd: max > 0
                                ? (v) async {
                                    await _player.seek(
                                        Duration(milliseconds: v.round()));
                                    if (mounted) setState(() => _dragMs = null);
                                  }
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(_fmt(_dragMs != null ? Duration(milliseconds: _dragMs!.round()) : pos), style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono)),
                            Text(_fmt(total), style: const TextStyle(color: cTextTertiary, fontSize: 11).copyWith(fontFamily: fontMono)),
                          ]),
                        ),
                        // Solange die Dauer fehlt, laedt das Lied noch in den
                        // Speicher. Sagen, dass das der Grund fuer den
                        // gesperrten Balken ist — und wie weit es ist.
                        if (max <= 0 && song != null)
                          ValueListenableBuilder<double>(
                            valueListenable: PlebrapAudio.cacheProgress,
                            builder: (_, p, _) => Padding(
                              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                              child: Column(children: [
                                LinearProgressIndicator(
                                  value: p > 0 ? p : null,
                                  minHeight: 2,
                                  color: cOrange,
                                  backgroundColor: cSurface,
                                ),
                                const SizedBox(height: 5),
                                Text(t.prCaching((p * 100).round()),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: cTextTertiary,
                                        fontSize: 11,
                                        height: 1.35)),
                              ]),
                            ),
                          ),
                      ]);
                    },
                  ),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    IconButton(icon: const Icon(Icons.skip_previous_rounded, color: cText, size: 30),
                        onPressed: _index != null && _index! > 0 ? _prev : null),
                    const SizedBox(width: 8),
                    StreamBuilder<PlayerState>(
                      stream: _player.playerStateStream,
                      builder: (_, snap) {
                        final playing = snap.data?.playing ?? false;
                        return GestureDetector(
                          onTap: PlebrapAudio.toggle,
                          child: Container(
                            width: 54, height: 54,
                            decoration: const BoxDecoration(color: cOrange, shape: BoxShape.circle),
                            child: _loading
                                ? const Padding(padding: EdgeInsets.all(15),
                                    child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                                : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 32),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.skip_next_rounded, color: cText, size: 30),
                        onPressed: _index != null && _index! < kPlebSongs.length - 1 ? _next : null),
                  ]),
                ]),
              ),
            ]),
          ),
        ),
        // ============ TITELLISTE ============
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            for (final entry in albums.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                child: Row(children: [
                  const Icon(Icons.album_rounded, color: cOrange, size: 15),
                  const SizedBox(width: 7),
                  Text(entry.key.toUpperCase(),
                      style: const TextStyle(color: cOrange, fontSize: 11.5, letterSpacing: 1.5, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 0.5, color: cTileBorder)),
                ]),
              ),
              for (final i in entry.value) _songRow(i),
            ],
          ],
        )),
      ]),
    );
  }

  Widget _songRow(int i) {
    final s = kPlebSongs[i];
    final active = i == _index;
    return GestureDetector(
      onTap: () => _playIndex(i),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? cOrange.withValues(alpha: 0.10) : cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: active ? cOrange.withValues(alpha: 0.5) : cTileBorder, width: active ? 1 : 0.5),
        ),
        child: Row(children: [
          Icon(active ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
              color: active ? cOrange : cTextTertiary, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: TextStyle(color: active ? cOrange : cText, fontSize: 13.5, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 1),
            Text(s.artist, style: const TextStyle(color: cTextTertiary, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
  }
}
