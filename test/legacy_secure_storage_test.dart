// Nach dem Update von 1.6.x auf 1.7.x fehlten auf Android Badge-Schlüssel
// und Identität: flutter_secure_storage 10 holte die Werte aus der alten
// EncryptedSharedPreferences-Datei nicht herüber. Die Wiederherstellung
// übernimmt alte Werte nur dorthin, wo im neuen Speicher nichts liegt.

import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:einundzwanzig_meetup_app/models/badge.dart';
import 'package:einundzwanzig_meetup_app/services/legacy_secure_storage.dart';

const _channel = MethodChannel('einundzwanzig/legacy_secure_storage');
const _blobKey = 'badges_encrypted';
const _keyAlias = 'badge_encryption_key';
const _legacyKeyAlias = 'badge_encryption_key_legacy';
const _doneKey = 'legacy_secure_storage_recovered';

MeetupBadge _badge(String id) => MeetupBadge(
      id: id,
      meetupName: 'Aschaffenburg',
      meetupEventId: id,
      date: DateTime.utc(2026, 10, 11, 19),
      iconPath: 'assets/badge_icon.png',
    );

String _hexKey() => enc.Key.fromSecureRandom(32)
    .bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0'))
    .join();

String _blob(String keyHex, List<MeetupBadge> badges) {
  final key = enc.Key(Uint8List.fromList(List.generate(
      32, (i) => int.parse(keyHex.substring(i * 2, i * 2 + 2), radix: 16))));
  final iv = enc.IV.fromSecureRandom(12);
  final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
  final encrypted = encrypter.encrypt(
      jsonEncode(badges.map((b) => b.toJson()).toList()),
      iv: iv);
  return '${iv.base64}:${encrypted.base64}';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, String> secure;
  late Map<String, String> legacy;
  late int reads;
  var legacyFails = false;

  setUp(() {
    secure = {};
    legacy = {};
    reads = 0;
    legacyFails = false;
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues(secure);
    MeetupBadge.badgesUnreadable = false;
    MeetupBadge.onBadgesSaved = null;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
      reads++;
      if (legacyFails) throw PlatformException(code: 'legacy_read_failed');
      final keys = (call.arguments as Map)['keys'] as List;
      return {
        for (final key in keys)
          if (legacy.containsKey(key)) key: legacy[key],
      };
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('alter Badge-Schlüssel öffnet die Datei nach dem Update wieder',
      () async {
    final oldKey = _hexKey();
    legacy[_keyAlias] = oldKey;
    SharedPreferences.setMockInitialValues(
        {_blobKey: _blob(oldKey, [_badge('a'), _badge('b')])});

    expect(await MeetupBadge.loadBadges(), isEmpty);
    expect(MeetupBadge.badgesUnreadable, isTrue);

    await LegacySecureStorage.recover();

    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), unorderedEquals(['a', 'b']));
    expect(MeetupBadge.badgesUnreadable, isFalse);
    expect(secure[_keyAlias], oldKey);
  });

  test('ein neuerer Badge-Schlüssel bleibt, der alte kommt daneben', () async {
    final oldKey = _hexKey();
    final newKey = _hexKey();
    legacy[_keyAlias] = oldKey;
    secure[_keyAlias] = newKey;
    SharedPreferences.setMockInitialValues(
        {_blobKey: _blob(oldKey, [_badge('a')])});

    await LegacySecureStorage.recover();

    expect(secure[_legacyKeyAlias], oldKey);
    final loaded = await MeetupBadge.loadBadges();
    expect(loaded.map((b) => b.id), ['a']);
  });

  test('alte Identität kommt zurück, wenn keine neue angelegt wurde',
      () async {
    legacy.addAll({
      'nostr_nsec_key': 'nsec-alt',
      'nostr_npub_key': 'npub-alt',
      'nostr_priv_hex': 'priv-alt',
      'nip46_client_sk': 'client-alt',
    });

    await LegacySecureStorage.recover();

    expect(secure['nostr_nsec_key'], 'nsec-alt');
    expect(secure['nostr_npub_key'], 'npub-alt');
    expect(secure['nostr_priv_hex'], 'priv-alt');
    expect(secure['nip46_client_sk'], 'client-alt');
  });

  test('eine seit dem Update angelegte Identität wird nicht überschrieben',
      () async {
    legacy.addAll({
      'nostr_nsec_key': 'nsec-alt',
      'nostr_npub_key': 'npub-alt',
      'nostr_priv_hex': 'priv-alt',
      'easyauth_password_ncryptsec': 'wrap-alt',
    });
    secure.addAll({
      'nostr_nsec_key': 'nsec-neu',
      'nostr_npub_key': 'npub-neu',
      'nostr_priv_hex': 'priv-neu',
    });

    await LegacySecureStorage.recover();

    expect(secure['nostr_nsec_key'], 'nsec-neu');
    expect(secure['nostr_npub_key'], 'npub-neu');
    expect(secure['nostr_priv_hex'], 'priv-neu');
    // Auch kein alter Wrap neben der neuen Identität.
    expect(secure.containsKey('easyauth_password_ncryptsec'), isFalse);
  });

  test('Lesefehler: nichts gilt als erledigt, der nächste Start holt nach',
      () async {
    final oldKey = _hexKey();
    legacy[_keyAlias] = oldKey;
    legacyFails = true;

    await LegacySecureStorage.recover();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(_doneKey), isNull);
    expect(secure, isEmpty);

    legacyFails = false;
    await LegacySecureStorage.recover();
    expect(secure[_keyAlias], oldKey);
    expect(prefs.getBool(_doneKey), isTrue);
  });

  test('läuft nur einmal und nur auf Android', () async {
    await LegacySecureStorage.recover();
    await LegacySecureStorage.recover();
    expect(reads, 1);

    SharedPreferences.setMockInitialValues({});
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await LegacySecureStorage.recover();
    expect(reads, 1);
  });
}
