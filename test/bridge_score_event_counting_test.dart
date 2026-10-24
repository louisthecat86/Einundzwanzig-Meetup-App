// Diskussionsvorschlag: Metadaten-Fixtures, keine Signaturprüfung.
import 'package:flutter_test/flutter_test.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/trust_score_service.dart';

MeetupBadge contribution(
  String event,
  String meetup, {
  bool organizer = false,
  String signer = 'issuer-a',
  String id = 'reused-meetup-id',
  int day = 1,
  bool largeEvent = false,
}) => MeetupBadge(
  id: id,
  meetupEventId: event,
  meetupName: meetup,
  date: DateTime.utc(2026, 10, day, 19),
  iconPath: '',
  isOrganizer: organizer,
  isEvent: largeEvent,
  delivery: organizer ? 'organizer' : 'rolling_qr',
  signerNpub: signer,
);

double bridge(List<MeetupBadge> badges) =>
    TrustScoreService.calculateBridgeScore(badges);

void main() {
  test('leerer Bestand und weniger als drei Termine bleiben ohne Score', () {
    expect(bridge([]), 0);
    expect(bridge([contribution('a1', 'A'), contribution('b1', 'B')]), 0);
  });

  test('drei echte Termine bleiben trotz gleicher Meetup-ID getrennt', () {
    expect(
      bridge([
        contribution('a1', 'A'),
        contribution('a2', 'A', day: 2),
        contribution('b1', 'B'),
      ]),
      2,
    );
  });

  test('Organisator-Marker zählen auch ohne Teilnehmer-Signaturfelder', () {
    final markers = [
      contribution('a1', 'A', organizer: true, signer: ''),
      contribution('a2', 'A', organizer: true, signer: '', day: 2),
      contribution('b1', 'B', organizer: true, signer: ''),
    ];
    expect(markers.every((badge) => !badge.isNostrSigned), isTrue);
    expect(bridge(markers), 2);
  });

  test('gemischte Teilnahme und Organisation erfüllen die Terminschwelle', () {
    expect(
      bridge([
        contribution('a1', 'A'),
        contribution('a2', 'A', day: 2),
        contribution('b1', 'B', organizer: true, signer: ''),
      ]),
      2,
    );
  });

  test('Mehrfachscans erfüllen die Drei-Termine-Schwelle nicht', () {
    final a = contribution('a1', 'A');
    expect(
      bridge([a, a.copyWith(id: 'rotating-qr'), contribution('b1', 'B')]),
      0,
    );
  });

  test(
    'mehrere Kopien eines Organisator-Markers erfüllen die Schwelle nicht',
    () {
      final a = contribution('a1', 'A', organizer: true, signer: '');
      expect(
        bridge([
          a,
          a.copyWith(id: 'copy'),
          contribution('b1', 'B', organizer: true, signer: ''),
        ]),
        0,
      );
    },
  );

  test(
    'beide Rollen desselben Termins zählen einmal, unabhängig von Reihenfolge',
    () {
      final participant = contribution('a1', 'A');
      final organizer = contribution('a1', 'A', organizer: true, signer: '');
      final other = contribution('b1', 'B');
      expect(bridge([participant, organizer, other]), 0);
      expect(bridge([organizer, other, participant]), 0);
    },
  );

  test(
    'Kopien und erneute Zusammenführungen erhöhen bestehenden Score nicht',
    () {
      final baseline = [
        contribution('a1', 'A'),
        contribution('a2', 'A', day: 2),
        contribution('b1', 'B', organizer: true, signer: 'issuer-b'),
      ];
      final copies = [for (final badge in baseline) badge.copyWith(id: 'copy')];
      final once = MeetupBadge.unionByIdentity(baseline, copies);
      final twice = MeetupBadge.unionByIdentity(once, [...baseline, ...copies]);
      expect(bridge(baseline), 4);
      expect(bridge([...baseline, ...copies, ...baseline]), 4);
      expect(bridge(once), 4);
      expect(bridge(twice), 4);
      expect(bridge([...baseline, ...copies].reversed.toList()), 4);
    },
  );

  test(
    'beide Rollen fügen weder weitere Meetup-Namen noch Aussteller hinzu',
    () {
      final baseline = [
        contribution('a1', 'A'),
        contribution('a2', 'A', day: 2),
        contribution('b1', 'B'),
      ];
      // Für dieselbe Veranstaltung ist die Teilnahme der Repräsentant.
      final marker = contribution(
        'a1',
        'abweichender Markername',
        organizer: true,
        signer: 'issuer-b',
      );
      expect(bridge(baseline), 2);
      expect(bridge([...baseline, marker]), 2);
      expect(bridge([marker, ...baseline]), 2);
    },
  );

  test(
    'Legacy-Fallback führt denselben Meetup-Tag bei anderer ID zusammen',
    () {
      final a = contribution('', 'A');
      expect(bridge([a, a.copyWith(id: 'copy'), contribution('', 'B')]), 0);
      expect(
        bridge([a, contribution('', 'A', day: 2), contribution('', 'B')]),
        2,
      );
    },
  );

  test('Signatur-ID-Fallback erkennt Kopien ohne Veranstaltungsschlüssel', () {
    final a = contribution('', 'A').copyWith(sigId: 'signature-a');
    final copy = a.copyWith(id: 'copy', meetupName: 'different display name');
    expect(bridge([a, copy, contribution('b1', 'B')]), 0);
  });

  test(
    'ein einziges Meetup bleibt auch mit mehreren organisierten Terminen null',
    () {
      expect(
        bridge([
          contribution('a1', 'A', organizer: true),
          contribution('a2', 'A', organizer: true, day: 2),
          contribution('a3', 'A', day: 3),
        ]),
        0,
      );
    },
  );

  test(
    'bestehende Großevent-Behandlung wird durch diesen Vorschlag nicht geändert',
    () {
      expect(
        bridge([
          contribution('a1', 'A'),
          contribution('b1', 'B'),
          contribution(
            'large',
            'Konferenz',
            largeEvent: true,
            signer: 'issuer-b',
          ),
        ]),
        4,
      );
    },
  );

  test('Bewertung verändert weder Badge-Bestand noch getrennte Rollen', () {
    final badges = [
      contribution('a1', 'A'),
      contribution('a1', 'A', organizer: true),
      contribution('b1', 'B'),
      contribution('a2', 'A', day: 2),
    ];
    final before = badges.map((b) => b.toJson()).toList();
    bridge(badges);
    expect(badges.map((b) => b.toJson()).toList(), before);
    expect(badges.length, 4);
    expect(badges.where((b) => b.meetupEventId == 'a1').length, 2);
  });
}
