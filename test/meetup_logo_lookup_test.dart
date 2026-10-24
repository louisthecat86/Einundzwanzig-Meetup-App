// ============================================
// UNIT TESTS: Wappen-Suche fuer Badges
// ============================================
// Ein Badge traegt die Stadt ("Ostwestfalen-Lippe, DE"), das Portal den
// Gruppennamen ("Einundzwanzig OWL"). Gesucht wird ueber die Stadt in der
// Meetup-Liste, danach exakt in der Termin-Registry. Nie ueber eine
// Teiluebereinstimmung: "Ulm" bekam sonst das Wappen von Neu-Ulm.
// ============================================

import 'package:einundzwanzig_meetup_app/models/meetup.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_calendar_service.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_service.dart';
import 'package:einundzwanzig_meetup_app/services/meetup_crest_lookup.dart';
import 'package:flutter_test/flutter_test.dart';

Meetup _m(String name, String city, {String country = 'DE', String logo = ''}) =>
    Meetup(
      id: '$name/$city',
      name: name,
      city: city,
      country: country,
      telegramLink: '',
      lat: 0,
      lng: 0,
      logoUrl: logo,
    );

void main() {
  setUp(() {
    MeetupService.cached = const [];
    MeetupCalendarService.portalLogos.clear();
  });

  group('logoFor', () {
    test('nur exakt, kein kuerzerer Schluessel gewinnt', () {
      MeetupCalendarService.rememberLogo('E', 'https://example.test/wrong.png');
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig OWL', 'https://example.test/owl.png');
      MeetupCalendarService.rememberLogo(
          'Ostwestfalen-Lippe', 'https://example.test/owl.png');

      expect(MeetupCalendarService.logoFor('Ostwestfalen-Lippe'),
          'https://example.test/owl.png');
      expect(MeetupCalendarService.logoFor('Einundzwanzig OWL'),
          'https://example.test/owl.png');
    });

    test('Teil des Gruppennamens reicht nicht', () {
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig Hildesheim', 'https://example.test/h.jpg');

      expect(MeetupCalendarService.logoFor('Hildesheim'), '');
    });

    test('leere Anfrage liefert kein Wappen', () {
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig Hildesheim', 'https://example.test/h.jpg');

      expect(MeetupCalendarService.logoFor('   '), '');
    });
  });

  group('MeetupCrestLookup.urlFor', () {
    test('Stadt findet die Gruppe, auch ohne gemeinsame Zeichenfolge', () {
      MeetupService.cached = [
        _m('Einundzwanzig OWL', 'Ostwestfalen-Lippe', logo: '/storage/owl.png'),
      ];

      expect(MeetupCrestLookup.urlFor('Ostwestfalen-Lippe, DE'),
          'https://portal.einundzwanzig.space/storage/owl.png');
    });

    test('Ulm bekommt nicht das Wappen von Neu-Ulm', () {
      MeetupService.cached = [
        _m('Einundzwanzig Ulm', 'Ulm'),
        _m('Einundzwanzig Neu-Ulm', 'Neu-Ulm', logo: 'https://x.test/neu-ulm.png'),
      ];
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig Neu-Ulm', 'https://x.test/neu-ulm.png');

      expect(MeetupCrestLookup.urlFor('Ulm, DE'), '',
          reason: 'die Liste kennt Ulm ohne Logo, also kein Wappen');
    });

    test('Au bekommt nicht das Wappen von Augsburg', () {
      MeetupService.cached = [
        _m('Einundzwanzig Augsburg', 'Augsburg', logo: 'https://x.test/a.png'),
      ];
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig Augsburg', 'https://x.test/a.png');
      MeetupCalendarService.rememberLogo('Augsburg', 'https://x.test/a.png');

      expect(MeetupCrestLookup.urlFor('Au, DE'), '');
    });

    test('mehrere Gruppen in einer Stadt: die erste der Liste', () {
      MeetupService.cached = [
        _m('Einundzwanzig Berlin Mitte', 'Berlin', logo: 'https://x.test/1.png'),
        _m('Einundzwanzig Berlin Ost', 'Berlin', logo: 'https://x.test/2.png'),
        _m('Bitcoin Berlin', 'Berlin', logo: 'https://x.test/3.png'),
        _m('Einundzwanzig Berlin West', 'Berlin', logo: 'https://x.test/4.png'),
      ];

      expect(MeetupCrestLookup.urlFor('Berlin, DE'), 'https://x.test/1.png');
    });

    test('Land trennt gleichnamige Staedte', () {
      MeetupService.cached = [
        _m('Einundzwanzig Weiden', 'Weiden', logo: 'https://x.test/de.png'),
        _m('Einundzwanzig Weiden AT', 'Weiden',
            country: 'AT', logo: 'https://x.test/at.png'),
      ];

      expect(MeetupCrestLookup.urlFor('Weiden, AT'), 'https://x.test/at.png');
      expect(MeetupCrestLookup.urlFor('Weiden, DE'), 'https://x.test/de.png');
      expect(MeetupCrestLookup.urlFor('Weiden'), 'https://x.test/de.png',
          reason: 'altes Badge ohne Land: erster Treffer');
    });

    test('unbekannt in der Liste: Termin-Registry unter der Stadt, exakt', () {
      MeetupCalendarService.rememberLogo(
          'Einundzwanzig Hildesheim', 'https://x.test/h.jpg');
      expect(MeetupCrestLookup.urlFor('Hildesheim, DE'), '');

      MeetupCalendarService.rememberLogo('Hildesheim', 'https://x.test/h.jpg');
      expect(MeetupCrestLookup.urlFor('Hildesheim, DE'), 'https://x.test/h.jpg');
    });

    test('Schreibweise aus dem Slug trifft die Portal-Stadt', () {
      MeetupService.cached = [
        _m('Einundzwanzig Neu-Ulm', 'Neu-Ulm', logo: 'https://x.test/n.png'),
      ];

      expect(MeetupCrestLookup.urlFor('Neu Ulm, DE'), 'https://x.test/n.png');
    });
  });
}
