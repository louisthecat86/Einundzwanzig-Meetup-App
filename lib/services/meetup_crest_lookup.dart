import 'meetup_calendar_service.dart';
import 'meetup_key.dart';
import 'meetup_service.dart';

/// Wappen zu einem Badge: ueber die Stadt in der Meetup-Liste, danach exakt
/// in der Termin-Registry. Am Badge-Format aendert sich dafuer nichts, die
/// Freitags-Badges tragen die Stadt schon.
class MeetupCrestLookup {
  MeetupCrestLookup._();

  /// Laeuft gerade ein Nachladen der Wappen-Quellen? Eine Zukunft fuer alle
  /// Karten, sonst fragt jede Badge-Karte die Listen selbst ab.
  static Future<void>? _sources;

  /// Termine (Name und Stadt -> Logo) und die Meetup-Liste. Die Liste kennt
  /// auch Gruppen ohne Termin in den naechsten zwei Monaten; die Termin-Registry
  /// allein wuerde deren Wappen auslassen.
  static Future<void> ensureSources() {
    if (MeetupService.cached.isNotEmpty &&
        MeetupCalendarService.portalLogos.isNotEmpty) {
      return Future<void>.value();
    }
    // Nach dem Lauf vergessen: Schlug er offline fehl, darf die naechste
    // Karte es wieder versuchen, statt bis zum Neustart ohne Wappen zu bleiben.
    return _sources ??= () async {
      if (MeetupService.cached.isEmpty) {
        try {
          await MeetupService.fetchMeetups();
        } catch (_) {}
      }
      if (MeetupCalendarService.portalLogos.isEmpty) {
        await MeetupCalendarService().fetchMeetupsPortalFirst();
      }
    }()
        .whenComplete(() => _sources = null);
  }

  /// Wappen zu einem Badge-Namen der Form "Stadt, LAND".
  ///
  /// Zuerst die Meetup-Liste ueber den Stadt-Slug und das Land.
  /// "Ostwestfalen-Lippe" und "Einundzwanzig OWL" teilen keine Zeichenfolge,
  /// der Slug der Stadt findet die Gruppe trotzdem. Kennt die Liste das
  /// Meetup, gilt die Liste: ohne Logo kein Wappen, kein Suchen nach dem
  /// Wappen einer anderen Gruppe. Nur ein Meetup, das die Liste nicht kennt,
  /// wird in der Termin-Registry unter der Stadt nachgeschlagen, exakt.
  /// Mehrere Gruppen in einer Stadt kann das Badge nicht unterscheiden; es
  /// gilt die erste in der Liste.
  static String urlFor(String meetupName) {
    final city = meetupName.split(',').first.trim();
    if (city.isEmpty) return '';
    final country = meetupName.contains(',')
        ? meetupName.split(',').sublist(1).join(',').trim()
        : '';
    final listed = MeetupService.bySlug(MeetupKey.slug(city), country);
    if (listed != null) {
      return MeetupCalendarService.absoluteImageUrl(listed.logoUrl);
    }
    return MeetupCalendarService.absoluteImageUrl(
      MeetupCalendarService.logoFor(city),
    );
  }
}
