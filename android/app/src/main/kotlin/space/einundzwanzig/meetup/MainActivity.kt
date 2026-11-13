package space.einundzwanzig.meetup

import android.app.Activity
import android.content.Intent
import android.content.pm.ActivityInfo
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

// ============================================
// NIP-55 Amber Signer Bridge
// ============================================
//
// Implementiert den Android-Teil des Signer-Layers.
//
//   get_public_key → Vordergrund-Intent (einmalig beim Verbinden)
//   sign_event     → ZUERST ContentResolver (Hintergrund, kein
//                    Popup wenn die Berechtigung gemerkt wurde),
//                    sonst Fallback auf Vordergrund-Intent.
//
// Der private Schlüssel verlässt Amber dabei niemals.
// ============================================

// local_auth verlangt eine FragmentActivity. FlutterActivity allein
// liefert auf Android no_fragment_activity, und die Schlüsselanzeige
// bricht dann still ab (ScreenSecure.authenticate gibt false zurück).
class MainActivity : FlutterFragmentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        applyPhoneOrientation(resources.configuration)
        super.onCreate(savedInstanceState)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyPhoneOrientation(newConfig)
    }

    private fun applyPhoneOrientation(configuration: Configuration) {
        // Kleinste Breite bleibt beim Drehen stabil. Ab 600 dp (Tablet bzw.
        // aufgeklapptes großes Foldable) gilt weiterhin die Systemausrichtung.
        val orientation = if (configuration.smallestScreenWidthDp in 1..599) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }
        if (requestedOrientation != orientation) {
            requestedOrientation = orientation
        }
    }

    private val channelName = "einundzwanzig/amber_signer"
    private val amberPackage = "com.greenart7c3.nostrsigner"

    // ── Widget-Klick-Routing ──
    // Das Ziel wird NICHT aus dem Intent dieser Activity gelesen (MIUI
    // spielt beim Wiederöffnen aus dem Task-Speicher den ALTEN Intent
    // erneut ab — deshalb kam bisher fast immer das falsche Ziel an).
    // Stattdessen schreibt die WidgetRouterActivity das Ziel in den
    // lokalen Speicher; Dart fragt es bei jedem Aufwachen hier ab.
    private val widgetChannelName = "einundzwanzig/widget"
    private val screenChannelName = "einundzwanzig/screen"
    private val legacyStorageChannelName = "einundzwanzig/legacy_secure_storage"

    // Request-Codes für die Vordergrund-Intents
    private val reqGetPublicKey = 9551
    private val reqSignEvent = 9552
    private val reqNip44 = 9553

    // Pending Flutter-Result, das auf onActivityResult wartet
    private var pendingResult: MethodChannel.Result? = null
    private var pendingType: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Widget-Kanal: liefert das vom Router gespeicherte Ziel (einmalig).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, widgetChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLaunchTarget" -> {
                        val prefs = getSharedPreferences("e21_widget", MODE_PRIVATE)
                        val t = prefs.getString("pending_target", null)
                        if (t != null) prefs.edit().remove("pending_target").commit()
                        result.success(t)
                    }
                    else -> result.notImplemented()
                }
            }

        // Screenshot-Sperre, solange ein nsec oder ncryptsec auf dem Schirm steht.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, screenChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val on = call.argument<Boolean>("on") == true
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Alter sicherer Speicher (bis 1.6.9), nur lesen. Keystore und Tink
        // brauchen spürbar Zeit, deshalb nicht auf dem UI-Thread.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, legacyStorageChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "read" -> {
                        val keys = call.argument<List<String>>("keys") ?: emptyList()
                        Thread {
                            try {
                                val values = LegacySecureStorage.read(applicationContext, keys)
                                runOnUiThread { result.success(values) }
                            } catch (e: Exception) {
                                runOnUiThread {
                                    result.error("legacy_read_failed", e.toString(), null)
                                }
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAppInstalled" -> result.success(isAmberInstalled())

                    "getPublicKey" -> startGetPublicKey(result)

                    "signEvent" -> {
                        val eventJson = call.argument<String>("event")
                        val npub = call.argument<String>("npub")
                        if (eventJson == null || npub == null) {
                            result.error("bad_args", "event/npub fehlen", null)
                        } else {
                            signEvent(eventJson, npub, result)
                        }
                    }

                    "nip44Encrypt" -> {
                        val pubkey = call.argument<String>("pubkey")
                        val plaintext = call.argument<String>("plaintext")
                        val npub = call.argument<String>("npub")
                        if (pubkey == null || plaintext == null || npub == null) {
                            result.error("bad_args", "pubkey/plaintext/npub fehlen", null)
                        } else {
                            nip44("nip44_encrypt", pubkey, plaintext, npub, result)
                        }
                    }

                    "nip44Decrypt" -> {
                        val pubkey = call.argument<String>("pubkey")
                        val payload = call.argument<String>("plaintext")
                        val npub = call.argument<String>("npub")
                        if (pubkey == null || payload == null || npub == null) {
                            result.error("bad_args", "pubkey/plaintext/npub fehlen", null)
                        } else {
                            nip44("nip44_decrypt", pubkey, payload, npub, result)
                        }
                    }

                    // V4V: Lightning-Invoice mit SYSTEM-CHOOSER öffnen.
                    // Intent.createChooser erzwingt die App-Auswahlliste,
                    // statt direkt die Standard-Wallet zu starten.
                    "payLightningInvoice" -> {
                        val invoice = call.argument<String>("invoice")
                        if (invoice == null) {
                            result.error("bad_args", "invoice fehlt", null)
                        } else {
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("lightning:$invoice"))
                                // Gibt es überhaupt eine App dafür?
                                if (intent.resolveActivity(packageManager) == null) {
                                    result.success(false)
                                } else {
                                    val chooser = Intent.createChooser(intent, "Lightning-Wallet wählen")
                                    startActivity(chooser)
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                result.success(false)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // =============================================
    // INSTALLATIONS-CHECK
    // =============================================
    private fun isAmberInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo(amberPackage, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    // =============================================
    // GET PUBLIC KEY (Vordergrund-Intent)
    // =============================================
    private fun startGetPublicKey(result: MethodChannel.Result) {
        if (!isAmberInstalled()) {
            result.error("signer_missing", "Amber nicht installiert", null)
            return
        }
        if (pendingResult != null) {
            result.error("busy", "Eine Signer-Anfrage läuft bereits", null)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("nostrsigner:"))
        intent.`package` = amberPackage
        intent.putExtra("type", "get_public_key")

        // Dauer-Berechtigung anfragen → spätere Signaturen ohne Popup.
        // nip44_encrypt/decrypt gehören dazu, sonst schlägt der Badge-Sync
        // mit "Keine Berechtigung für diese Methode" fehl.
        val perms = JSONArray()
            .put(JSONObject().put("type", "sign_event"))
            .put(JSONObject().put("type", "nip44_encrypt"))
            .put(JSONObject().put("type", "nip44_decrypt"))
        intent.putExtra("permissions", perms.toString())

        pendingResult = result
        pendingType = "get_public_key"
        try {
            startActivityForResult(intent, reqGetPublicKey)
        } catch (e: Exception) {
            clearPending()
            result.error("launch_failed", e.message, null)
        }
    }

    // =============================================
    // SIGN EVENT — ContentResolver zuerst, dann Intent
    // =============================================
    private fun signEvent(eventJson: String, npub: String, result: MethodChannel.Result) {
        if (!isAmberInstalled()) {
            result.error("signer_missing", "Amber nicht installiert", null)
            return
        }

        // 1) HINTERGRUND-PFAD: ContentResolver
        //    Liefert nur dann ein Ergebnis, wenn der User die
        //    sign_event-Berechtigung dauerhaft erteilt hat.
        try {
            val uri = Uri.parse("content://$amberPackage.SIGN_EVENT")
            val cursor = contentResolver.query(
                uri,
                arrayOf(eventJson, "", npub),
                null, null, null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val rejectedIdx = it.getColumnIndex("rejected")
                    if (rejectedIdx >= 0 && !it.isNull(rejectedIdx)) {
                        result.error("rejected", "User hat dauerhaft abgelehnt", null)
                        return
                    }
                    val eventIdx = it.getColumnIndex("event")
                    val resultIdx = it.getColumnIndex("result")
                    val signedEvent = if (eventIdx >= 0) it.getString(eventIdx) else null
                    val sig = if (resultIdx >= 0) it.getString(resultIdx) else null
                    if (signedEvent != null) {
                        result.success(mapOf("event" to signedEvent, "result" to sig))
                        return
                    }
                }
            }
            // cursor == null → keine gemerkte Berechtigung → Fallback
        } catch (e: Exception) {
            // ContentResolver nicht verfügbar → Fallback auf Intent
        }

        // 2) VORDERGRUND-PFAD: Intent (zeigt Amber-Popup, einmalig)
        if (pendingResult != null) {
            result.error("busy", "Eine Signer-Anfrage läuft bereits", null)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("nostrsigner:$eventJson"))
        intent.`package` = amberPackage
        intent.putExtra("type", "sign_event")
        intent.putExtra("current_user", npub)

        pendingResult = result
        pendingType = "sign_event"
        try {
            startActivityForResult(intent, reqSignEvent)
        } catch (e: Exception) {
            clearPending()
            result.error("launch_failed", e.message, null)
        }
    }

    // =============================================
    // NIP-44 — verschlüsselt für den Badge-Sync, selbes Muster wie sign_event
    // =============================================
    private fun nip44(type: String, pubkey: String, value: String, npub: String, result: MethodChannel.Result) {
        if (!isAmberInstalled()) {
            result.error("signer_missing", "Amber nicht installiert", null)
            return
        }

        // 1) HINTERGRUND-PFAD: ContentResolver, wenn die Berechtigung gemerkt ist.
        val resolverType = if (type == "nip44_encrypt") "NIP44_ENCRYPT" else "NIP44_DECRYPT"
        try {
            val uri = Uri.parse("content://$amberPackage.$resolverType")
            val cursor = contentResolver.query(
                uri,
                arrayOf(value, pubkey, npub),
                null, null, null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val rejectedIdx = it.getColumnIndex("rejected")
                    if (rejectedIdx >= 0 && !it.isNull(rejectedIdx)) {
                        result.error("rejected", "User hat dauerhaft abgelehnt", null)
                        return
                    }
                    val resultIdx = it.getColumnIndex("result")
                    if (resultIdx >= 0) {
                        val out = it.getString(resultIdx)
                        if (out != null) {
                            result.success(out)
                            return
                        }
                    }
                }
            }
        } catch (e: Exception) {
            // kein Resolver-Weg → Intent
        }

        // 2) VORDERGRUND-PFAD: Intent
        if (pendingResult != null) {
            result.error("busy", "Eine Signer-Anfrage läuft bereits", null)
            return
        }
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("nostrsigner:$value"))
        intent.`package` = amberPackage
        intent.putExtra("type", type)
        intent.putExtra("pubkey", pubkey)
        intent.putExtra("current_user", npub)

        pendingResult = result
        pendingType = type
        try {
            startActivityForResult(intent, reqNip44)
        } catch (e: Exception) {
            clearPending()
            result.error("launch_failed", e.message, null)
        }
    }

    // =============================================
    // INTENT-ERGEBNISSE
    // =============================================
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        val res = pendingResult
        val type = pendingType
        clearPending()
        if (res == null) return

        if (resultCode != Activity.RESULT_OK || data == null) {
            res.error("cancelled", "Anfrage abgebrochen", null)
            return
        }

        when (type) {
            "get_public_key" -> {
                // Amber legt den npub in "result" ab
                val npub = data.getStringExtra("result")
                    ?: data.getStringExtra("signature")
                if (npub.isNullOrBlank()) {
                    res.error("cancelled", "Kein pubkey erhalten", null)
                } else {
                    res.success(npub)
                }
            }

            "sign_event" -> {
                val signedEvent = data.getStringExtra("event")
                val sig = data.getStringExtra("result") ?: data.getStringExtra("signature")
                if (signedEvent.isNullOrBlank()) {
                    res.error("cancelled", "Kein signiertes Event erhalten", null)
                } else {
                    res.success(mapOf("event" to signedEvent, "result" to sig))
                }
            }

            "nip44_encrypt", "nip44_decrypt" -> {
                val out = data.getStringExtra("result") ?: data.getStringExtra("signature")
                if (out.isNullOrBlank()) {
                    res.error("cancelled", "Kein NIP-44-Ergebnis erhalten", null)
                } else {
                    res.success(out)
                }
            }

            else -> res.error("unknown", "Unbekannter Anfrage-Typ", null)
        }
    }

    private fun clearPending() {
        pendingResult = null
        pendingType = null
    }
}
