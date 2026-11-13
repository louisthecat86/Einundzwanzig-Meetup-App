package space.einundzwanzig.meetup

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import com.it_nomads.fluttersecurestorage.crypto.EncryptedSharedPreferences
import com.it_nomads.fluttersecurestorage.crypto.MasterKey
import java.security.KeyStore

// ============================================
// Alter sicherer Speicher (App bis 1.6.9) — nur lesen
// ============================================
//
// Bis 1.6.9 schrieb flutter_secure_storage 9 in eine
// EncryptedSharedPreferences-Datei. Version 10 holt diese Werte mit
// migrateWithBackup nicht herüber: der Umzug wird übersprungen, weil die
// Datei für das Plugin wie eine frische Installation aussieht. Die Werte
// liegen weiter unverändert in der Datei.
//
// Hier wird nur gelesen. Es entsteht kein Schlüssel und kein Keyset, und
// nichts wird entfernt. Gelesen wird je Name: getAll() bricht ab, sobald
// in derselben Datei schon Einträge des neuen Speichers liegen.
// ============================================
object LegacySecureStorage {
    private const val FILE = "FlutterSecureStorage"
    private const val KEY_PREFIX = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIHNlY3VyZSBzdG9yYWdlCg"
    private const val KEY_KEYSET = "__androidx_security_crypto_encrypted_prefs_key_keyset__"
    private const val VALUE_KEYSET = "__androidx_security_crypto_encrypted_prefs_value_keyset__"

    /**
     * Leere Map, wenn die alte Datei keine Keysets hat.
     * Sind Keysets da, der Hauptschlüssel im Keystore aber nicht, wird
     * geworfen. Eine leere Map hielte Dart für „nichts zu holen“ und
     * würde die Wiederherstellung nicht wiederholen.
     */
    fun read(context: Context, keys: List<String>): Map<String, String> {
        val raw = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
        // Ohne diese Prüfungen würde das Öffnen Keysets und Hauptschlüssel
        // neu anlegen.
        if (!raw.contains(KEY_KEYSET) || !raw.contains(VALUE_KEYSET)) return emptyMap()
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        if (!keyStore.containsAlias(MasterKey.DEFAULT_MASTER_KEY_ALIAS)) {
            throw IllegalStateException(
                "Alter Speicher hat Keysets, der Hauptschlüssel fehlt"
            )
        }

        // Dieselben Parameter wie im Plugin, sonst passt der Schlüssel nicht.
        val masterKey = MasterKey.Builder(context)
            .setKeyGenParameterSpec(
                KeyGenParameterSpec.Builder(
                    MasterKey.DEFAULT_MASTER_KEY_ALIAS,
                    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
                )
                    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                    .setKeySize(256)
                    .build()
            )
            .build()
        val legacy = EncryptedSharedPreferences.create(
            context,
            FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
        val out = HashMap<String, String>()
        for (key in keys) {
            val value = legacy.getString(KEY_PREFIX + "_" + key, null)
            if (value != null) out[key] = value
        }
        return out
    }
}
