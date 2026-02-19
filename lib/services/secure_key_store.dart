// ============================================
// SECURE KEY STORE — Hardware-verschlüsselt
// ============================================
//
// Zentraler Wrapper für flutter_secure_storage.
// Ersetzt alle SharedPreferences-Zugriffe auf
// private Schlüssel (nsec, npub, privHex).
//
// Android: nutzt Android Keystore (StrongBox wenn verfügbar)
// iOS:     nutzt iOS Keychain (kSecAttrAccessibleWhenUnlocked)
//
// MIGRATION:
//   Beim ersten Aufruf werden vorhandene Keys aus
//   SharedPreferences in SecureStorage migriert und
//   anschließend aus SharedPreferences gelöscht.
// ============================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureKeyStore {
  // Singleton
  static final SecureKeyStore _instance = SecureKeyStore._internal();
  factory SecureKeyStore() => _instance;
  SecureKeyStore._internal();

  // flutter_secure_storage Instanz mit sicheren Optionen
  // AndroidOptions: encryptedSharedPreferences nutzt EncryptedSharedPreferences
  // (API 23+). Auf älteren Geräten (API < 23) fällt die Library auf
  // AES-Verschlüsselung mit RSA-wrapped Key im AndroidKeyStore zurück.
  // minSdkVersion 21 wird unterstützt.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // API 23+ → EncryptedSharedPreferences
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys (gleiche Namen wie vorher für einfache Migration)
  static const String _nsecKey = 'nostr_nsec_key';
  static const String _npubKey = 'nostr_npub_key';
  static const String _privHexKey = 'nostr_priv_hex';

  // Flag ob Migration bereits durchgeführt
  static const String _migrationDoneKey = 'secure_migration_done';

  // =============================================
  // MIGRATION: SharedPreferences → SecureStorage
  // Wird einmalig beim ersten Zugriff ausgeführt.
  // =============================================
  static bool _migrated = false;

  static Future<void> ensureMigrated() async {
    if (_migrated) return;

    final prefs = await SharedPreferences.getInstance();
    final alreadyDone = prefs.getBool(_migrationDoneKey) ?? false;

    if (!alreadyDone) {
      // Alte Keys aus SharedPreferences lesen
      final nsec = prefs.getString(_nsecKey);
      final npub = prefs.getString(_npubKey);
      final privHex = prefs.getString(_privHexKey);

      // In SecureStorage schreiben (wenn vorhanden)
      if (nsec != null && nsec.isNotEmpty) {
        await _storage.write(key: _nsecKey, value: nsec);
      }
      if (npub != null && npub.isNotEmpty) {
        await _storage.write(key: _npubKey, value: npub);
      }
      if (privHex != null && privHex.isNotEmpty) {
        await _storage.write(key: _privHexKey, value: privHex);
      }

      // Alte Keys aus SharedPreferences LÖSCHEN
      await prefs.remove(_nsecKey);
      await prefs.remove(_npubKey);
      await prefs.remove(_privHexKey);

      // Migration als erledigt markieren
      await prefs.setBool(_migrationDoneKey, true);

      if (nsec != null) {
        print('[SecureKeyStore] Migration abgeschlossen: Keys aus SharedPreferences entfernt.');
      }
    }

    _migrated = true;
  }

  // =============================================
  // KEYS SPEICHERN
  // =============================================
  static Future<void> saveKeys({
    required String nsec,
    required String npub,
    required String privHex,
  }) async {
    await ensureMigrated();
    await _storage.write(key: _nsecKey, value: nsec);
    await _storage.write(key: _npubKey, value: npub);
    await _storage.write(key: _privHexKey, value: privHex);
  }

  // =============================================
  // KEYS LADEN
  // =============================================
  static Future<String?> getNsec() async {
    await ensureMigrated();
    return await _storage.read(key: _nsecKey);
  }

  static Future<String?> getNpub() async {
    await ensureMigrated();
    return await _storage.read(key: _npubKey);
  }

  static Future<String?> getPrivHex() async {
    await ensureMigrated();
    return await _storage.read(key: _privHexKey);
  }

  // =============================================
  // KEYPAIR LADEN (nsec + npub)
  // =============================================
  static Future<Map<String, String>?> loadKeys() async {
    await ensureMigrated();
    final nsec = await _storage.read(key: _nsecKey);
    final npub = await _storage.read(key: _npubKey);

    if (nsec == null || npub == null) return null;

    return {
      'nsec': nsec,
      'npub': npub,
    };
  }

  // =============================================
  // HAT DER USER EINEN KEY?
  // =============================================
  static Future<bool> hasKey() async {
    await ensureMigrated();
    final nsec = await _storage.read(key: _nsecKey);
    return nsec != null && nsec.isNotEmpty;
  }

  // =============================================
  // KEYS LÖSCHEN (GEFÄHRLICH!)
  // =============================================
  static Future<void> deleteKeys() async {
    await ensureMigrated();
    await _storage.delete(key: _nsecKey);
    await _storage.delete(key: _npubKey);
    await _storage.delete(key: _privHexKey);
  }
}