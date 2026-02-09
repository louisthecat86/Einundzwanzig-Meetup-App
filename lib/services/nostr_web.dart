import 'dart:async';
import 'dart:js_util'; // Das Werkzeug für sicheren JS-Zugriff
import 'package:js/js.dart';

@JS('window')
external dynamic get window; // Wir holen uns das globale Fenster-Objekt

class NostrService {
  static Future<String?> getPublicKey() async {
    try {
      // 1. SICHERHEITS-CHECK: Gibt es 'nostr' im Window?
      // Alby injiziert das Objekt 'nostr'. Wenn es fehlt, ist die Extension nicht da.
      if (!hasProperty(window, 'nostr')) {
        print("❌ FEHLER: window.nostr nicht gefunden. Ist Alby installiert?");
        return null;
      }

      // 2. Zugriff auf das Objekt
      final nostr = getProperty(window, 'nostr');
      
      // 3. Methode aufrufen (getPublicKey)
      // Wir nutzen callMethod, das ist sicherer als direkte Bindings
      final promise = callMethod(nostr, 'getPublicKey', []);

      // 4. Das JS-Promise in ein Dart-Future umwandeln
      final result = await promiseToFuture(promise);
      
      return result.toString();
    } catch (e) {
      // Hier landen wir, wenn der User das Popup schließt oder ablehnt
      print("⚠️ Nostr Fehler: $e");
      return null;
    }
  }
}