import 'package:flutter/material.dart';
import '../services/meetup_calendar_service.dart';
import '../services/meetup_crest_lookup.dart';

/// Das Wappen des Meetups als Wasserzeichen hinter der generativen Grafik.
///
/// Warum das mehr ist als Zierrat: Bisher sahen alle Badges gleich aus —
/// dieselbe Grafik, nur mit anderem Startwert. Das Wappen macht jedes Badge
/// auf den ersten Blick zuordenbar, ohne dass man den Namen lesen muss. Und
/// es verbindet das Badge sichtbar mit der Gemeinschaft, aus der es stammt.
///
/// AUSFALLSICHER: Gibt es kein Wappen — weil das Portal keines liefert, das
/// Bild nicht laedt oder man offline ist —, bleibt schlicht nichts uebrig
/// und die generative Grafik darunter traegt die Karte allein. Niemals ein
/// leerer Kasten oder ein kaputtes Bildsymbol.
class MeetupCrestWatermark extends StatefulWidget {
  /// Meetup-Name aus dem Badge, Form "Stadt, LAND".
  final String meetupName;

  /// Deckkraft. Zurueckhaltend, damit Titel und Datum lesbar bleiben.
  final double opacity;

  /// Anteil der Kartenbreite, den das Wappen einnimmt.
  final double widthFactor;

  /// Feste Bild-URL, die Vorrang vor der Wappen-Suche hat.
  ///
  /// Fuer EVENT-BADGES: Deren Bild kommt aus dem Kalender-Event und nicht
  /// aus der Meetup-Liste des Portals. Die Suche nach "Blocktrainer Event"
  /// haette dort nie etwas gefunden, und das hochgeladene Bild waere im
  /// Badge nie aufgetaucht.
  final String? imageUrl;

  const MeetupCrestWatermark({
    super.key,
    required this.meetupName,
    this.opacity = 0.20,
    this.widthFactor = 1.05,
    this.imageUrl,
  });

  @override
  State<MeetupCrestWatermark> createState() => _MeetupCrestWatermarkState();
}

class _MeetupCrestWatermarkState extends State<MeetupCrestWatermark> {
  @override
  void initState() {
    super.initState();
    _ensureLogos();
  }

  /// Wer die App oeffnet und direkt in die Badge-Wallet geht, hat die
  /// Wappen-Listen noch leer. Das Widget holt sie dann selbst nach.
  Future<void> _ensureLogos() async {
    if ((widget.imageUrl ?? '').trim().isNotEmpty) return;
    await MeetupCrestLookup.ensureSources();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Feste URL schlaegt die Suche. Event-Badges bringen ihr Bild mit.
    String url = (widget.imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      url = MeetupCalendarService.absoluteImageUrl(url);
    } else {
      url = MeetupCrestLookup.urlFor(widget.meetupName);
    }
    if (url.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, c) {
        final side = c.maxWidth * widget.widthFactor;
        return Align(
          alignment: const Alignment(0.15, -0.25),
          child: Opacity(
            opacity: widget.opacity,
            // WEICH AUSLAUFENDE KANTEN: Ohne die Maske sass das Wappen als
            // hart begrenztes Rechteck auf der Karte und wirkte aufgeklebt.
            // Der radiale Verlauf laesst es zum Rand hin verschwinden, so
            // dass es mit der generativen Grafik darunter verschmilzt.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => const RadialGradient(
                center: Alignment.center,
                radius: 0.62,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.transparent,
                ],
                stops: [0.0, 0.55, 1.0],
              ).createShader(rect),
              child: Image.network(
                url,
                width: side,
                height: side,
                fit: BoxFit.contain,
                // Kein Platzhalter waehrend des Ladens: Ein aufblitzender
                // Kasten waere stoerender als das spaetere Erscheinen.
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : const SizedBox.shrink(),
                errorBuilder: (_, error, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Das Wappen als eigenstaendiges Bildelement — ohne Daempfung, ohne
/// Positionierung. Gedacht fuer Stellen, an denen es NICHT Hintergrund ist,
/// sondern selbst das Motiv: etwa im Medaillon der Badge-Detailansicht.
///
/// Faellt auf [fallback] zurueck, wenn kein Wappen vorliegt oder das Bild
/// nicht laedt — dort steht dann wieder das gewohnte Symbol.
class MeetupCrestFace extends StatefulWidget {
  final String meetupName;
  final Widget fallback;

  /// Bild, das dem Wappen VORGEHT.
  ///
  /// Noetig fuer Event-Badges: Die tragen ihr eigenes Bild, gehoeren aber zu
  /// keinem Meetup — die Suche ueber den Namen findet also nichts, und in der
  /// Detailansicht stand die generative Grafik, waehrend die Wallet-Karte
  /// daneben das richtige Bild zeigte. Genau dieser Widerspruch wurde
  /// gemeldet: "vorne ist es drin, im Badge fehlt es".
  final String? imageUrl;

  const MeetupCrestFace({
    super.key,
    required this.meetupName,
    required this.fallback,
    this.imageUrl,
  });

  @override
  State<MeetupCrestFace> createState() => _MeetupCrestFaceState();
}

class _MeetupCrestFaceState extends State<MeetupCrestFace> {
  @override
  void initState() {
    super.initState();
    if ((widget.imageUrl ?? '').trim().isNotEmpty) return;
    MeetupCrestLookup.ensureSources().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var url = '';
    final own = widget.imageUrl?.trim() ?? '';
    if (own.isNotEmpty) {
      url = MeetupCalendarService.absoluteImageUrl(own);
    }

    if (url.isEmpty) url = MeetupCrestLookup.urlFor(widget.meetupName);
    if (url.isEmpty) return widget.fallback;

    return Image.network(
      url,
      fit: BoxFit.contain,
      // Waehrend des Ladens das gewohnte Symbol zeigen statt einer Luecke —
      // die Karte soll nie halbfertig wirken.
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : widget.fallback,
      errorBuilder: (_, error, stack) => widget.fallback,
    );
  }
}
