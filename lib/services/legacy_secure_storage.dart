// ============================================
// ALTER SICHERER SPEICHER (Android, App bis 1.6.9)
// ============================================
// Bis 1.6.9 lagen die Werte in einer EncryptedSharedPreferences-Datei
// (flutter_secure_storage 9). Version 10 holt sie mit migrateWithBackup
// nicht herüber; nach dem Update fehlten deshalb Badge-Schlüssel und
// Identität, obwohl die alte Datei unverändert auf dem Gerät liegt.
//
// Hier werden die alten Werte einmal gelesen und nur dorthin übernommen,
// wo im neuen Speicher nichts liegt. Was seit dem Update neu entstanden
// ist, bleibt. Die alte Datei wird nie verändert.
// ============================================

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_logger.dart';

class LegacySecureStorage {
  LegacySecureStorage._();

  static const _channel =
      MethodChannel('einundzwanzig/legacy_secure_storage');

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: false,
      migrateOnAlgorithmChange: true,
      migrateWithBackup: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Liegt im sicheren Speicher, nicht in den Einstellungen: das
  /// Zurücksetzen der App leert die Einstellungen, und ohne Merker käme
  /// die alte Identität beim nächsten Start zurück.
  static const _doneKey = 'legacy_secure_storage_recovered';

  static const _badgeKey = 'badge_encryption_key';

  /// Liegt schon ein anderer Badge-Schlüssel da, kommt der alte hierher.
  /// MeetupBadge probiert beim Öffnen jeden 32-Byte-Wert im Speicher.
  static const _badgeKeyLegacy = 'badge_encryption_key_legacy';

  /// Identität samt EasyAuth-Wraps gehört zusammen: einzelne alte Werte
  /// neben einer neuen Identität ergäben ein Gemisch aus zwei Schlüsseln.
  /// Ein schon liegender Wert, der dem alten gleicht, ist dieselbe Identität:
  /// fehlende Felder werden nachgezogen. Ein abweichender Wert blockiert
  /// den ganzen Satz.
  static const _identity = [
    'nostr_nsec_key',
    'nostr_npub_key',
    'nostr_priv_hex',
    'easyauth_password_ncryptsec',
    'easyauth_password_wrap_npub',
    'easyauth_passkey_ncryptsec',
    'easyauth_passkey_credential_id',
  ];

  static const _nip46ClientKey = 'nip46_client_sk';

  /// Muss vor dem ersten Lesen der Badge-Datei laufen. Schlägt das Lesen
  /// des alten Speichers fehl, versucht es der nächste Start erneut.
  static Future<void> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final current = await _storage.readAll();
      if (current.containsKey(_doneKey)) return;
      final old = await _channel.invokeMapMethod<String, String>('read', {
            'keys': [_badgeKey, ..._identity, _nip46ClientKey],
          }) ??
          const <String, String>{};
      bool missing(String key) => (current[key] ?? '').isEmpty;
      bool has(String key) => (old[key] ?? '').isNotEmpty;
      final adopted = <String>[];

      if (has(_badgeKey) && current[_badgeKey] != old[_badgeKey]) {
        final target = missing(_badgeKey) ? _badgeKey : _badgeKeyLegacy;
        await _storage.write(key: target, value: old[_badgeKey]);
        adopted.add(target);
      }
      final sameIdentity = _identity.every(
          (key) => missing(key) || !has(key) || current[key] == old[key]);
      if (sameIdentity) {
        for (final key in _identity) {
          final value = old[key];
          if (value == null || value.isEmpty || !missing(key)) continue;
          await _storage.write(key: key, value: value);
          adopted.add(key);
        }
      }
      if (has(_nip46ClientKey) && missing(_nip46ClientKey)) {
        await _storage.write(key: _nip46ClientKey, value: old[_nip46ClientKey]);
        adopted.add(_nip46ClientKey);
      }

      await _storage.write(key: _doneKey, value: '1');
      if (adopted.isNotEmpty) {
        AppLogger.info('LegacyStorage',
            'Aus dem alten sicheren Speicher übernommen: ${adopted.join(', ')}');
      }
    } catch (e) {
      AppLogger.warn('LegacyStorage',
          'Alter sicherer Speicher nicht lesbar, der nächste Start versucht es erneut', e);
    }
  }
}
