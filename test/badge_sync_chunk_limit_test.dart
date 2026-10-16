import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_codec.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_format.dart';
import 'package:einundzwanzig_meetup_app/services/badge_sync_service.dart';
import 'package:einundzwanzig_meetup_app/services/signing_service.dart';

const generation = 1792157000;

List<MeetupBadge> collection(int count) {
  final random = Random(91);
  return List.generate(
    count,
    (i) => MeetupBadge(
      id: 'badge-$i',
      meetupEventId: 'event-$i',
      meetupName: 'Meetup ${i % 5}',
      date: DateTime.utc(2026, 1, 1).add(Duration(days: i)),
      iconPath: '',
      sigContent: List.generate(
        4000,
        (_) => String.fromCharCode(33 + random.nextInt(94)),
      ).join(),
    ),
  );
}

int measuredChunks(List<MeetupBadge> badges) => BadgeSyncFormat.plaintexts(
  badges,
  generation,
  (plain) =>
      BadgeSyncFormat.payloadCharsForGzip(BadgeSyncCodec.deflate(plain).length),
).length;

class TransportCalls {
  int encryptions = 0;
  int signatures = 0;
  final published = <Map<String, dynamic>>[];

  Future<bool> upload(List<MeetupBadge> badges) =>
      BadgeSyncService.uploadChunks(
        'fixture',
        badges,
        0,
        encrypt: (_, _) async {
          encryptions++;
          return 'sealed';
        },
        sign: ({required kind, required tags, required content}) async {
          signatures++;
          return SignedEvent(
            id: 'test-$signatures',
            pubkey: 'fixture',
            createdAt: generation,
            kind: kind,
            tags: tags,
            content: content,
            sig: 'test-signature',
          );
        },
        publish: (_, event) async {
          published.add(event);
          return true;
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'badge_sync_last_gen': generation,
      'badge_sync_chunk_hashes': ['previous-hash'],
      'badge_sync_dirty': true,
    });
    BadgeSyncService.debugResetProcess();
  });

  test(
    '17 tatsächliche Chunks brechen vor Verschlüsselung, Signieren und Upload ab',
    () async {
      final badges = collection(65);
      // Die bisherige Vorprüfung lässt diesen Bestand fälschlich passieren.
      expect(
        BadgeSyncFormat.chunkBadges(badges, (plain) => plain.length).length,
        lessThanOrEqualTo(BadgeSyncFormat.maxChunks),
      );
      expect(measuredChunks(badges), 17);
      final prefs = await SharedPreferences.getInstance();
      final before = {for (final key in prefs.getKeys()) key: prefs.get(key)};
      final transport = TransportCalls();
      expect(await transport.upload(badges), isFalse);
      expect(transport.encryptions, 0);
      expect(transport.signatures, 0);
      expect(transport.published, isEmpty);
      expect({for (final key in prefs.getKeys()) key: prefs.get(key)}, before);
    },
  );

  test(
    'genau 16 tatsächliche Chunks werden vollständig veröffentlicht',
    () async {
      final badges = collection(64);
      expect(measuredChunks(badges), 16);
      final transport = TransportCalls();
      expect(await transport.upload(badges), isTrue);
      expect(transport.encryptions, 16);
      expect(transport.signatures, 16);
      expect(transport.published, hasLength(16));
      expect(
        transport.published.map((event) => (event['tags'] as List).first[1]),
        List.generate(16, BadgeSyncFormat.dTag),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('badge_sync_chunk_hashes'), hasLength(16));
    },
  );
}
