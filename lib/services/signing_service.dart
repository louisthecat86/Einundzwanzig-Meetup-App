// ============================================
// SIGNING SERVICE — Abstraktion über Key-Management
// ============================================
//
// Drei Identitäts-Quellen, EIN Signier-Interface.
//
//   1. LOCAL (generiert)  — App erzeugt das Keypair selbst.
//   2. LOCAL (importiert)  — User gibt seinen nsec ein.
//      Beide: nsec liegt im SecureKeyStore, wird ins
//      (verschlüsselte) Backup übernommen, Signatur via
//      Event.from(privkey: ...).
//
//   3. AMBER (NIP-55)     — Externer Signer. Die App sieht
//      den nsec NIEMALS. Jede Signatur geht über einen
//      Android-ContentResolver/Intent an die Amber-App.
//      Das Backup enthält KEINEN nsec, nur den npub + Modus.
//
// Alle Services die signieren rufen künftig NUR NOCH:
//
//     final signed = await SigningService.signEvent(
//       kind: 21000, tags: [...], content: '...');
//     signed.id / signed.sig / signed.pubkey / signed.createdAt
//
// statt direkt Event.from(kind: ..., privkey: ...).
//
// Die Architektur lehnt sich an die bewährte 21steps-Lösung an:
//   - abstraktes NostrSigner-Interface
//   - sealed Result-Klassen (kein null-Rätselraten)
//   - expectedPubkey-Check (erkennt "falsches Konto in Amber")
//   - Transport hinter dem Interface gekapselt → austauschbar
// ============================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nostr/nostr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_key_store.dart';
import 'app_logger.dart';
import 'nip07/nip07_bridge.dart';
import 'nip07/nip07_exception.dart';
import 'nip46/bunker_uri.dart';
import 'nip46/client_metadata.dart';
import 'nip46/nip46_client.dart';
import 'nip46/nip46_exception.dart';
import 'relay_config.dart';

// =============================================
// SIGNING MODE
// =============================================

enum SigningMode {
  local, // App besitzt den privaten Schlüssel (generiert oder importiert)
  amber, // Externer Signer via NIP-55 — nsec verlässt Amber nie
  nip07, // Externer Signer via NIP-07 (Browsererweiterung) — nur im Web
  nip46, // Externer Signer via NIP-46 (Bunker) — auf JEDER Plattform,
  // und auf iOS der einzige Weg zu einem externen Signer
}

/// Primärweg für „Schon bei Nostr“ — genau einer pro Plattform/Lage.
enum RecommendedExistingPath {
  nip07,
  amber,
  bunker,
}

// =============================================
// SIGNED EVENT — Ergebnis jeder Signatur
// =============================================
// Trägt exakt die Felder, die die Caller bisher von
// Event.from() gelesen haben: id, pubkey, createdAt, sig.
// =============================================

class SignedEvent {
  final String id;
  final String pubkey; // hex
  final int createdAt; // unix seconds
  final int kind;
  final List<List<String>> tags;
  final String content;
  final String sig;

  const SignedEvent({
    required this.id,
    required this.pubkey,
    required this.createdAt,
    required this.kind,
    required this.tags,
    required this.content,
    required this.sig,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'created_at': createdAt,
        'kind': kind,
        'tags': tags,
        'content': content,
        'sig': sig,
      };

  /// WebSocket-kompatibler EVENT-Frame für Relay-Versand.
  String toEventMessage() => jsonEncode(['EVENT', toJson()]);
}

// =============================================
// FEHLER
// =============================================

class SigningException implements Exception {
  final String message;
  const SigningException(this.message);
  @override
  String toString() => message;
}

/// Wird geworfen, wenn der User die Signatur in Amber ablehnt
/// oder den Dialog wegklickt. Caller können das gezielt fangen,
/// um eine freundliche "Abgebrochen"-Meldung zu zeigen.
class SigningCancelledException extends SigningException {
  const SigningCancelledException()
      : super('Signatur in Amber abgebrochen.');
}

/// Amber ist nicht installiert.
class SignerMissingException extends SigningException {
  const SignerMissingException()
      : super('Amber (Nostr Signer) ist nicht installiert.');
}

/// In Amber ist ein anderes Konto aktiv als das, mit dem die
/// App verbunden wurde.
class WrongAccountException extends SigningException {
  const WrongAccountException()
      : super('Amber hat mit einem anderen Konto signiert als verbunden.');
}

// =============================================
// CONNECT-RESULT (sealed) — für den Verbindungs-Flow
// =============================================

sealed class AmberConnectResult {
  const AmberConnectResult();
}

class AmberConnectSuccess extends AmberConnectResult {
  final String pubkeyHex;
  final String npub;
  const AmberConnectSuccess({required this.pubkeyHex, required this.npub});
}

class AmberConnectMissing extends AmberConnectResult {
  const AmberConnectMissing();
}

class AmberConnectCancelled extends AmberConnectResult {
  const AmberConnectCancelled();
}

class AmberConnectError extends AmberConnectResult {
  final String message;
  const AmberConnectError(this.message);
}

// =============================================
// NOSTR SIGNER — abstraktes Interface
// =============================================
// Lässt uns Local/Amber/Mock tauschen, ohne dass ein
// einziger Service-Caller das mitbekommt.
// =============================================

abstract interface class NostrSigner {
  /// hex-pubkey der aktiven Identität (oder null).
  Future<String?> pubkeyHex();

  /// Signiert ein unsigniertes Event und liefert das vollständige
  /// signierte Event zurück.
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  });
}

// =============================================
// LOCAL SIGNER — App besitzt den nsec
// =============================================

class LocalNostrSigner implements NostrSigner {
  @override
  Future<String?> pubkeyHex() async {
    final npub = await SecureKeyStore.getNpub();
    if (npub == null || npub.isEmpty) return null;
    try {
      return Nip19.decodePubkey(npub);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final privHex = await SecureKeyStore.getPrivHex();
    if (privHex == null || privHex.isEmpty) {
      throw const SigningException('Kein privater Schlüssel vorhanden.');
    }

    final event = Event.from(
      kind: kind,
      tags: tags,
      content: content,
      privkey: privHex,
    );

    return SignedEvent(
      id: event.id,
      pubkey: event.pubkey,
      createdAt: event.createdAt,
      kind: kind,
      tags: tags,
      content: content,
      sig: event.sig,
    );
  }
}

// =============================================
// AMBER SIGNER — NIP-55 über eigenen Kotlin-Channel
// =============================================
// Der Kotlin-Layer versucht ZUERST den ContentResolver
// (Hintergrund, kein Popup wenn Permission gemerkt) und
// fällt nur dann auf einen Vordergrund-Intent zurück, wenn
// noch keine Berechtigung erteilt wurde. Das verhindert die
// Popup-Hölle bei den vielen Signier-Stellen der App.
// =============================================

class AmberNostrSigner implements NostrSigner {
  static const MethodChannel _channel =
      MethodChannel('einundzwanzig/amber_signer');

  /// Amber-Paketname (greenart7c3 = der offizielle Amber-Signer).
  static const String amberPackage = 'com.greenart7c3.nostrsigner';

  final String expectedPubkeyHex;
  const AmberNostrSigner({required this.expectedPubkeyHex});

  @override
  Future<String?> pubkeyHex() async => expectedPubkeyHex;

  /// Ist ein NIP-55 Signer (Amber) installiert?
  static Future<bool> isAvailable() async {
    try {
      final installed = await _channel.invokeMethod<bool>('isAppInstalled');
      return installed ?? false;
    } catch (e) {
      AppLogger.warn('AmberSigner', 'isAppInstalled fehlgeschlagen: $e');
      return false;
    }
  }

  /// Verbindungs-Flow: holt den pubkey aus Amber und bittet
  /// gleich um die Dauer-Berechtigung 'sign_event', damit
  /// spätere Signaturen ohne Popup laufen können.
  static Future<AmberConnectResult> connect() async {
    try {
      if (!await isAvailable()) return const AmberConnectMissing();

      final raw = await _channel.invokeMethod<String>('getPublicKey');
      if (raw == null || raw.trim().isEmpty) {
        return const AmberConnectCancelled();
      }

      // Amber kann den Schlüssel in verschiedenen Formaten zurückgeben:
      // - "npub1..."            (bech32)
      // - roher Hex-pubkey       (64 Hex-Zeichen)
      // - JSON wie {"result":"npub1..."} (manche Versionen/Sonderfälle)
      var value = raw.trim();

      // Falls JSON: das "result"/"npub"-Feld herausziehen.
      if (value.startsWith('{')) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          value = (map['result'] ?? map['npub'] ?? map['pubkey'] ?? '')
              .toString()
              .trim();
        } catch (_) {/* unten weiter versuchen */}
      }

      try {
        String hex;
        String npub;
        if (value.startsWith('npub1')) {
          // bech32 -> hex
          hex = Nip19.decodePubkey(value);
          npub = value;
        } else if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(value)) {
          // schon roher Hex-pubkey -> npub daraus bilden
          hex = value.toLowerCase();
          npub = Nip19.encodePubkey(hex);
        } else {
          return AmberConnectError('Unerwartetes Schlüsselformat von Amber.');
        }
        return AmberConnectSuccess(pubkeyHex: hex, npub: npub);
      } on Exception catch (e) {
        return AmberConnectError('Ungültiger pubkey von Amber: $e');
      }
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') return const AmberConnectCancelled();
      if (e.code == 'signer_missing') return const AmberConnectMissing();
      return AmberConnectError(e.message ?? e.code);
    } catch (e) {
      return AmberConnectError(e.toString());
    }
  }

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Unsigniertes Event so bauen, wie Amber es signieren soll.
    // pubkey + created_at + kind + tags + content müssen exakt
    // dem entsprechen, worüber Amber die id/sig berechnet.
    // WICHTIG: Im Event-Feld 'pubkey' steht HEX (NIP-01),
    // als 'current_user' erwartet NIP-55 aber den npub (bech32).
    final unsigned = <String, dynamic>{
      'pubkey': expectedPubkeyHex,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
    };

    String currentUserNpub;
    try {
      currentUserNpub = Nip19.encodePubkey(expectedPubkeyHex);
    } catch (_) {
      currentUserNpub = expectedPubkeyHex; // Fallback
    }

    final Map<dynamic, dynamic> result;
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'signEvent',
        {
          'package': amberPackage,
          'npub': currentUserNpub,
          'event': jsonEncode(unsigned),
        },
      );
      if (res == null) throw const SigningCancelledException();
      result = res;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'cancelled':
        case 'rejected':
          throw const SigningCancelledException();
        case 'signer_missing':
          throw const SignerMissingException();
        default:
          throw SigningException('Amber-Fehler: ${e.message ?? e.code}');
      }
    }

    // Amber liefert das vollständige signierte Event als JSON
    // in der Spalte/Extra "event" zurück.
    final signedJsonRaw = result['event'];
    if (signedJsonRaw is! String || signedJsonRaw.isEmpty) {
      throw const SigningException('Amber hat kein signiertes Event geliefert.');
    }

    final Map<String, dynamic> signed;
    try {
      signed = jsonDecode(signedJsonRaw) as Map<String, dynamic>;
    } catch (e) {
      throw SigningException('Amber-Antwort nicht lesbar: $e');
    }

    // Security Audit N1: Amber ist FREMDER Code wie die Browsererweiterung
    // oder der Remote-Signer. Dieselbe Prüfung anwenden — Kontowechsel,
    // veränderter Event-Typ, veränderter Inhalt — statt nur den Pubkey
    // zu vergleichen. Die Prüfung ist deckungsgleich mit NIP-07/NIP-46,
    // damit kein Signer schwächer abgesichert ist als ein anderer.
    return verifySignerResponse(
      signed: signed,
      expectedPubkeyHex: expectedPubkeyHex,
      kind: kind,
      tags: tags,
      content: content,
      fallbackCreatedAt: createdAt,
      actor: 'Amber',
    );
  }
}

// =============================================
// NIP-07 SIGNER — Browsererweiterung (Alby, nos2x, Flamingo, …)
// =============================================
// Das Gegenstück zu Amber für den Browser: der private Schlüssel liegt in
// der Erweiterung und verlässt sie nie. Im Web ist das der einzige Weg,
// bei dem der nsec NICHT in localStorage landen muss.
//
// Aufbau bewusst parallel zu AmberNostrSigner, inklusive der Prüfung auf
// Kontowechsel: wer in der Erweiterung das Konto umstellt, würde sonst
// unbemerkt mit einem fremden Schlüssel signieren.
// =============================================

class Nip07NostrSigner implements NostrSigner {
  /// Der beim Verbinden gemerkte pubkey — gegen den wird geprüft.
  final String expectedPubkeyHex;

  /// NUR für Tests: ersetzt den Weg zur Erweiterung.
  ///
  /// Ohne diese Naht wären die drei Sicherheitsprüfungen in signEvent
  /// (Kontowechsel, veränderter Event-Typ, veränderter Inhalt) nicht
  /// automatisiert prüfbar: nip07SignEvent ist eine Top-Level-Funktion hinter
  /// einem bedingten Export und lässt sich nicht ersetzen. Genau diese drei
  /// Prüfungen sind der sicherheitsrelevante Teil des Signers — die sollten
  /// nicht ungetestet bleiben.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
      debugSignFn;

  const Nip07NostrSigner({required this.expectedPubkeyHex, this.debugSignFn});

  /// Ist eine NIP-07-Erweiterung vorhanden? Ausserhalb des Browsers false.
  static Future<bool> isAvailable() => nip07Available();

  /// Verbindungs-Flow: holt den pubkey aus der Erweiterung.
  static Future<Nip07ConnectResult> connect() async {
    try {
      if (!await nip07Available()) return const Nip07ConnectMissing();
      final hex = await nip07GetPublicKey();
      final npub = Nip19.encodePubkey(hex);
      return Nip07ConnectSuccess(pubkeyHex: hex, npub: npub);
    } on Nip07RejectedException {
      return const Nip07ConnectRejected();
    } on Nip07Exception catch (e) {
      return Nip07ConnectError(e.message);
    } catch (e) {
      return Nip07ConnectError(e.toString());
    }
  }

  @override
  Future<String?> pubkeyHex() async => expectedPubkeyHex;

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Ohne 'pubkey': NIP-07 schreibt vor, dass die Erweiterung ihn selbst
    // setzt. Manche Erweiterungen lehnen ein mitgeliefertes Feld ab, wenn es
    // vom aktiven Konto abweicht.
    final unsigned = <String, dynamic>{
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
    };

    final Map<String, dynamic> signed;
    try {
      signed = await (debugSignFn ?? nip07SignEvent)(unsigned);
    } on Nip07RejectedException {
      throw const SigningCancelledException();
    } on Nip07Exception catch (e) {
      throw SigningException(e.message);
    }

    return verifySignerResponse(
      signed: signed,
      expectedPubkeyHex: expectedPubkeyHex,
      kind: kind,
      tags: tags,
      content: content,
      fallbackCreatedAt: createdAt,
      actor: 'Die Erweiterung',
    );
  }
}

// =============================================
// PRÜFUNG DER SIGNER-ANTWORT — gemeinsam für NIP-07 und NIP-46
// =============================================
// Beide reden mit FREMDEM Code: eine Browsererweiterung oder eine
// Signer-App/Website. Die Prüfungen müssen bei beiden deckungsgleich sein —
// zweimal geschrieben würden sie unweigerlich auseinanderlaufen, und das
// wäre eine Sicherheitslücke, die man am Diff nicht sieht.
// =============================================

/// Prüft die Antwort eines externen Signers und baut daraus das Ergebnis.
///
/// [actor] geht in die Fehlertexte ein („Die Erweiterung …" / „Der Signer …"),
/// damit der Nutzer weiß, welche Gegenstelle sich falsch verhält.
@visibleForTesting
SignedEvent verifySignerResponse({
  required Map<String, dynamic> signed,
  required String expectedPubkeyHex,
  required int kind,
  required List<List<String>> tags,
  required String content,
  required int fallbackCreatedAt,
  required String actor,
}) {
  final signedPubkey = (signed['pubkey'] ?? '').toString();
  // Schutz wie bei Amber: Kontowechsel in der Gegenstelle darf keine
  // fremde Signatur durchlassen.
  if (signedPubkey.toLowerCase() != expectedPubkeyHex.toLowerCase()) {
    throw const WrongAccountException();
  }

  final sig = (signed['sig'] ?? '').toString();
  if (sig.isEmpty) {
    throw SigningException('$actor hat kein signiertes Event geliefert.');
  }

  // kind und content dürfen sich NICHT ändern.
  //
  // Bei tags ist die Übernahme richtig: id und sig sind nach NIP-01 darüber
  // berechnet, und Normalisierung durch die Gegenstelle (Sortierung,
  // Zusatzfelder) ist legitim — eine Caller-Kopie würde das Event ungültig
  // machen und Relays würden es verwerfen.
  //
  // Für kind und content gilt das nicht. Würden sie ungeprüft übernommen,
  // veröffentlichte die App Inhalte, die sie nicht verfasst hat, unter dem
  // Namen des Nutzers — und ihre eigene Logik (Reputations-Payload,
  // Badge-Proofs) rechnete danach mit verändertem Inhalt weiter. Eine
  // Gegenstelle, die hier abweicht, ist defekt; das will man sehen, nicht
  // stillschweigend übernehmen.
  if (signed['kind'] is int && signed['kind'] as int != kind) {
    throw SigningException('$actor hat einen anderen Event-Typ signiert '
        '(${signed['kind']} statt $kind).');
  }
  if (signed.containsKey('content') &&
      (signed['content'] ?? '').toString() != content) {
    throw SigningException('$actor hat den Inhalt des Events verändert.');
  }

  final id = (signed['id'] ?? '').toString();
  // created_at der Gegenstelle gewinnt: id und sig sind darüber
  // berechnet, ein abweichender Wert würde das Event ungültig machen.
  final createdAt = signed['created_at'] is int
      ? signed['created_at'] as int
      : fallbackCreatedAt;
  final parsedTags = _tagsFromSigned(signed['tags'], tags);

  // Die Felder oben können stimmen und die Signatur trotzdem nicht dazu
  // gehören. Eine nicht leere Platzhalter-Signatur reicht nicht.
  var signatureOk = false;
  try {
    final event = Event(
      id,
      signedPubkey,
      createdAt,
      kind,
      parsedTags,
      content,
      sig,
      verify: false,
    );
    signatureOk = event.isValid();
  } catch (_) {
    signatureOk = false;
  }
  if (!signatureOk) {
    throw SigningException('$actor hat keine gültige Signatur geliefert.');
  }

  return SignedEvent(
    id: id,
    pubkey: signedPubkey,
    createdAt: createdAt,
    // kind und content stammen aus dem Aufruf, nicht aus der Antwort — die
    // Prüfung oben stellt sicher, dass beides übereinstimmt. So steht die
    // Invariante im Code, statt sie aus zwei Stellen erschliessen zu müssen.
    kind: kind,
    tags: parsedTags,
    content: content,
    sig: sig,
  );
}

/// Parst tags aus der Signer-Antwort; bei kaputtem Format Fallback.
List<List<String>> _tagsFromSigned(
  dynamic raw,
  List<List<String>> fallback,
) {
  if (raw is! List) return fallback;
  try {
    final out = <List<String>>[];
    for (final tag in raw) {
      if (tag is! List) return fallback;
      out.add([for (final e in tag) e.toString()]);
    }
    return out;
  } catch (_) {
    return fallback;
  }
}

/// Ergebnis des NIP-07-Verbindungsversuchs.
sealed class Nip07ConnectResult {
  const Nip07ConnectResult();
}

class Nip07ConnectSuccess extends Nip07ConnectResult {
  final String pubkeyHex;
  final String npub;
  const Nip07ConnectSuccess({required this.pubkeyHex, required this.npub});
}

/// Keine Erweiterung im Browser (oder gar kein Browser).
class Nip07ConnectMissing extends Nip07ConnectResult {
  const Nip07ConnectMissing();
}

/// Nutzer hat in der Erweiterung abgelehnt — kein Fehler.
class Nip07ConnectRejected extends Nip07ConnectResult {
  const Nip07ConnectRejected();
}

class Nip07ConnectError extends Nip07ConnectResult {
  final String message;
  const Nip07ConnectError(this.message);
}

// =============================================
// NIP-46 SIGNER — Remote-Signer (Bunker)
// =============================================
// Signiert über eine fremde App oder Website. Aufbau bewusst parallel zum
// NIP-07-Signer, inklusive derselben Prüfungen (gemeinsame Funktion oben).
//
// Den Client liefert der SigningService, weil er über App-Aufrufe hinweg
// GEHALTEN werden muss: pro Signatur neue WebSockets zu öffnen wäre langsam
// und würde bei jeder Anfrage erneut abonnieren.
// =============================================

class Nip46NostrSigner implements NostrSigner {
  /// pubkey des NUTZERS, der beim Verbinden gemerkt wurde.
  final String expectedPubkeyHex;

  /// Liefert die laufende Sitzung (stellt sie bei Bedarf wieder her).
  final Future<Nip46Client> Function() clientProvider;

  /// NUR für Tests — gleiche Naht wie beim NIP-07-Signer, damit die
  /// Sicherheitsprüfungen ohne echten Signer geprüft werden können.
  @visibleForTesting
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
      debugSignFn;

  const Nip46NostrSigner({
    required this.expectedPubkeyHex,
    required this.clientProvider,
    this.debugSignFn,
  });

  @override
  Future<String?> pubkeyHex() async => expectedPubkeyHex;

  @override
  Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final createdAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Anders als bei NIP-07 wird 'pubkey' mitgeschickt: NIP-46 überträgt das
    // Event als JSON-String, und viele Signer prüfen damit, ob die Anfrage
    // zum freigegebenen Konto gehört.
    final unsigned = <String, dynamic>{
      'pubkey': expectedPubkeyHex,
      'created_at': createdAt,
      'kind': kind,
      'tags': tags,
      'content': content,
    };

    final Map<String, dynamic> signed;
    try {
      final sign = debugSignFn;
      signed = sign != null
          ? await sign(unsigned)
          : await (await clientProvider()).signEvent(unsigned);
    } on Nip46TimeoutException {
      throw const SigningException(
          'Der Signer hat nicht geantwortet. Ist die Signer-App geöffnet '
          'und die Freigabe bestätigt?');
    } on Nip46RemoteException catch (e) {
      throw SigningException('Der Signer hat abgelehnt: ${e.message}');
    } on Nip46Exception catch (e) {
      throw SigningException(e.message);
    }

    return verifySignerResponse(
      signed: signed,
      expectedPubkeyHex: expectedPubkeyHex,
      kind: kind,
      tags: tags,
      content: content,
      fallbackCreatedAt: createdAt,
      actor: 'Der Signer',
    );
  }
}

/// Ergebnis eines NIP-46-Verbindungsversuchs.
sealed class Nip46ConnectResult {
  const Nip46ConnectResult();
}

class Nip46ConnectSuccess extends Nip46ConnectResult {
  final String pubkeyHex;
  final String npub;
  const Nip46ConnectSuccess({required this.pubkeyHex, required this.npub});
}

/// Der Signer hat innerhalb der Frist nicht geantwortet — der häufigste Fall.
class Nip46ConnectTimeout extends Nip46ConnectResult {
  const Nip46ConnectTimeout();
}

class Nip46ConnectError extends Nip46ConnectResult {
  final String message;
  const Nip46ConnectError(this.message);
}

/// Eine laufende Kopplung über `nostrconnect://`.
///
/// Die UI zeigt [uri] als QR-Code und Text an und wartet dann auf
/// [SigningService.completeNip46Pairing]. Bei Abbruch muss [cancel] gerufen
/// werden, sonst bleiben Relay-Verbindungen offen.
class Nip46Pairing {
  final String uri;
  final String secret;
  final String clientSecretKeyHex;
  final List<String> relays;
  final Nip46Client client;

  const Nip46Pairing({
    required this.uri,
    required this.secret,
    required this.clientSecretKeyHex,
    required this.relays,
    required this.client,
  });

  Future<void> cancel() => client.close();
}

// =============================================
// SIGNING SERVICE — die Fassade für die ganze App
// =============================================

class SigningService {
  static const String _modeKey = 'signing_mode';
  static const String _amberPubkeyHexKey = 'amber_pubkey_hex';
  static const String _amberNpubKey = 'amber_npub';
  static const String _nip07PubkeyHexKey = 'nip07_pubkey_hex';
  static const String _nip07NpubKey = 'nip07_npub';
  // Drei Felder tragen eine Bunker-Sitzung: der pubkey des Nutzers, seine
  // npub-Form für die Anzeige und die Adresse des Signers. Der vierte Teil —
  // der Sitzungsschlüssel der App — liegt im sicheren Speicher.
  static const String _nip46PubkeyHexKey = 'nip46_pubkey_hex';
  static const String _nip46NpubKey = 'nip46_npub';
  static const String _nip46BunkerUriKey = 'nip46_bunker_uri';

  // =============================================
  // MODUS
  // =============================================

  static Future<SigningMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final storedMode = prefs.getString(_modeKey);
    // Amber-Daten bleiben für eine spätere Nutzung auf Android erhalten,
    // werden auf Plattformen ohne Amber-Transport aber nicht als aktiver
    // Modus verwendet. So kann iOS/Web weder Amber-Signierung vortäuschen
    // noch versehentlich den Android-MethodChannel ansprechen.
    if (storedMode == 'amber' && !isAmberSupported) {
      return SigningMode.local;
    }
    // default deckt null UND unbekannte Altwerte ab — bestehende
    // Installationen haben 'amber' oder 'local' gespeichert und bleiben
    // dadurch unveraendert.
    return switch (storedMode) {
      'amber' => SigningMode.amber,
      'nip07' => SigningMode.nip07,
      'nip46' => SigningMode.nip46,
      _ => SigningMode.local,
    };
  }

  static Future<void> _setMode(SigningMode mode) async {
    // Verlassen von nip46: Sitzung sofort raeumen. Sonst blieben nach
    // connectAmber / connectNip07 / useLocalMode der Sitzungsschluessel und
    // offene Relay-Subscriptions liegen — disconnectNip46() raeumt korrekt,
    // der Wechsel-Pfad tat es vorher nicht.
    if (mode != SigningMode.nip46) {
      await _clearNip46Artifacts();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, switch (mode) {
      SigningMode.amber => 'amber',
      SigningMode.nip07 => 'nip07',
      SigningMode.nip46 => 'nip46',
      SigningMode.local => 'local',
    });
  }

  static Future<bool> get isAmber async =>
      (await getMode()) == SigningMode.amber;

  /// Amber ist nur über den nativen Android-MethodChannel verfügbar.
  /// Der plattformübergreifende Weg zu einem externen Signer ist NIP-46.
  static bool get isAmberSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Welcher bestehende-Identität-Weg als Primär-CTA gezeigt werden soll.
  ///
  /// Web mit Extension → NIP-07; Android mit Amber installiert → Amber;
  /// sonst Bunker (iOS, Web ohne Ext, Android ohne Amber).
  static Future<RecommendedExistingPath> recommendedExistingPath() async {
    if (kIsWeb && await nip07ExtensionAvailable()) {
      return RecommendedExistingPath.nip07;
    }
    if (isAmberSupported && await AmberNostrSigner.isAvailable()) {
      return RecommendedExistingPath.amber;
    }
    return RecommendedExistingPath.bunker;
  }

  static Future<bool> get isNip07 async =>
      (await getMode()) == SigningMode.nip07;

  static Future<bool> get isNip46 async =>
      (await getMode()) == SigningMode.nip46;

  /// Signiert ein EXTERNER Signer (Amber, Browsererweiterung oder Bunker)?
  ///
  /// Fuer alles, wo es nur darauf ankommt, dass die App den privaten
  /// Schluessel NICHT besitzt: kein nsec im Backup, npub vom Service statt
  /// aus dem Keystore, und kein stilles Signieren beim App-Start — jede
  /// Signatur loest bei allen dreien eine Rueckfrage aus.
  static Future<bool> get isExternalSigner async {
    final mode = await getMode();
    return mode == SigningMode.amber ||
        mode == SigningMode.nip07 ||
        mode == SigningMode.nip46;
  }

  // =============================================
  // AKTIVEN SIGNER AUFLÖSEN
  // =============================================

  static Future<NostrSigner> _resolveSigner() async {
    switch (await getMode()) {
      case SigningMode.amber:
        if (!isAmberSupported) {
          throw const SigningException(
              'Amber ist nur in der nativen Android-App verfügbar.');
        }
        final prefs = await SharedPreferences.getInstance();
        final hex = prefs.getString(_amberPubkeyHexKey);
        if (hex == null || hex.isEmpty) {
          throw const SigningException(
              'Amber-Modus aktiv, aber kein verbundener Schlüssel. '
              'Bitte Amber erneut verbinden.');
        }
        return AmberNostrSigner(expectedPubkeyHex: hex);
      case SigningMode.nip07:
        final prefs = await SharedPreferences.getInstance();
        final hex = prefs.getString(_nip07PubkeyHexKey);
        if (hex == null || hex.isEmpty) {
          throw const SigningException(
              'Erweiterungs-Modus aktiv, aber kein verbundener Schlüssel. '
              'Bitte die Browsererweiterung erneut verbinden.');
        }
        return Nip07NostrSigner(expectedPubkeyHex: hex);
      case SigningMode.nip46:
        final prefs = await SharedPreferences.getInstance();
        final hex = prefs.getString(_nip46PubkeyHexKey);
        if (hex == null || hex.isEmpty) {
          throw const SigningException(
              'Bunker-Modus aktiv, aber kein verbundener Schlüssel. '
              'Bitte den Signer erneut verbinden.');
        }
        return Nip46NostrSigner(
            expectedPubkeyHex: hex, clientProvider: _nip46Session);
      case SigningMode.local:
        return LocalNostrSigner();
    }
  }

  // =============================================
  // ZENTRALE SIGNIER-FUNKTION
  // =============================================
  // Der EINZIGE Weg, auf dem die App künftig signiert.
  // =============================================

  static Future<SignedEvent> signEvent({
    required int kind,
    required List<List<String>> tags,
    required String content,
  }) async {
    final signer = await _resolveSigner();
    return signer.signEvent(kind: kind, tags: tags, content: content);
  }

  /// pubkey (hex) der aktiven Identität — unabhängig vom Modus.
  static Future<String?> pubkeyHex() async {
    final signer = await _resolveSigner();
    return signer.pubkeyHex();
  }

  /// npub der aktiven Identität — Amber-npub, Erweiterungs-npub oder
  /// lokaler npub.
  static Future<String?> npub() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (await getMode()) {
      SigningMode.amber => prefs.getString(_amberNpubKey),
      SigningMode.nip07 => prefs.getString(_nip07NpubKey),
      SigningMode.nip46 => prefs.getString(_nip46NpubKey),
      SigningMode.local => SecureKeyStore.getNpub(),
    };
  }

  /// Kann die App aktuell überhaupt signieren?
  static Future<bool> canSign() async {
    final prefs = await SharedPreferences.getInstance();
    switch (await getMode()) {
      case SigningMode.amber:
        if (!isAmberSupported) return false;
        final hex = prefs.getString(_amberPubkeyHexKey);
        return hex != null && hex.isNotEmpty;
      case SigningMode.nip07:
        final hex = prefs.getString(_nip07PubkeyHexKey);
        // Zusaetzlich pruefen, ob die Erweiterung ueberhaupt noch da ist:
        // sie kann seit dem Verbinden deinstalliert oder deaktiviert worden
        // sein, und ein gemerkter pubkey allein hilft dann nicht.
        if (hex == null || hex.isEmpty) return false;
        return nip07Available();
      case SigningMode.nip46:
        // Bewusst OHNE ping: canSign() liegt in heissen Pfaden (unter anderem
        // beim App-Start), eine Relay-Runde pro Aufruf waere dort falsch.
        // Ob die Sitzung noch lebt, prueft nip46SessionAlive() auf Anfrage.
        final hex = prefs.getString(_nip46PubkeyHexKey);
        if (hex == null || hex.isEmpty) return false;
        if ((prefs.getString(_nip46BunkerUriKey) ?? '').isEmpty) return false;
        final clientKey = await SecureKeyStore.getNip46ClientKey();
        return clientKey != null && clientKey.isNotEmpty;
      case SigningMode.local:
        final priv = await SecureKeyStore.getPrivHex();
        return priv != null && priv.isNotEmpty;
    }
  }

  // =============================================
  // AMBER VERBINDEN / TRENNEN
  // =============================================

  /// Startet den Amber-Verbindungs-Flow und persistiert den
  /// pubkey + Modus bei Erfolg.
  static Future<AmberConnectResult> connectAmber() async {
    final result = await AmberNostrSigner.connect();
    if (result is AmberConnectSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_amberPubkeyHexKey, result.pubkeyHex);
      await prefs.setString(_amberNpubKey, result.npub);
      await _setMode(SigningMode.amber);
      AppLogger.security('SigningService',
          'Amber verbunden: ${_short(result.npub)} — nsec bleibt in Amber.');
    }
    return result;
  }

  /// Aktiviert den lokalen Modus (nach Key-Generierung/Import).
  static Future<void> useLocalMode() async {
    await _setMode(SigningMode.local);
  }

  /// Stellt den Amber-Modus aus einem Backup wieder her.
  /// Im Backup liegt nur der npub (kein nsec — der bleibt in Amber).
  static Future<void> restoreAmber(String npub) async {
    final hex = Nip19.decodePubkey(npub.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_amberPubkeyHexKey, hex);
    await prefs.setString(_amberNpubKey, npub.trim());
    await _setMode(SigningMode.amber);
  }

  /// Trennt Amber und löscht den gemerkten pubkey.
  static Future<void> disconnectAmber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_amberPubkeyHexKey);
    await prefs.remove(_amberNpubKey);
    await _setMode(SigningMode.local);
  }

  // =============================================
  // BROWSERERWEITERUNG (NIP-07) VERBINDEN / TRENNEN
  // =============================================

  /// Ist eine NIP-07-Erweiterung vorhanden? Ausserhalb des Browsers false.
  static Future<bool> nip07ExtensionAvailable() =>
      Nip07NostrSigner.isAvailable();

  /// Startet den Verbindungs-Flow mit der Browsererweiterung und
  /// persistiert pubkey + Modus bei Erfolg.
  ///
  /// Ein vorhandener lokaler nsec wird BEWUSST NICHT gelöscht.
  ///
  /// Hier stand kurzzeitig ein `SecureKeyStore.deleteKeys()`, um den
  /// gemischten Zustand "lokaler Schlüssel plus Erweiterungs-Modus" zu
  /// vermeiden. Das war ein Datenverlust-Pfad: ein Tipp auf "Mit
  /// Browsererweiterung verbinden" plus Freigabe in der Erweiterung hätte den
  /// nsec unwiderruflich gelöscht — ohne Warnung, ohne Rückfrage, und wer
  /// kein Backup hatte, wäre seine Identität für immer los gewesen.
  /// connectAmber() löscht ebenfalls nicht, die beiden Knöpfe nebeneinander
  /// hätten sich also grundlegend verschieden verhalten.
  ///
  /// Der gemischte Zustand ist stattdessen dort entschärft, wo er wehtat: das
  /// Backup sichert Schlüssel nach ihrer tatsächlichen EXISTENZ statt nach dem
  /// Modus (siehe backup_service). Damit geht nichts verloren, egal in welcher
  /// Reihenfolge jemand Schlüssel anlegt und Signer verbindet.
  static Future<Nip07ConnectResult> connectNip07() async {
    final result = await Nip07NostrSigner.connect();
    if (result is Nip07ConnectSuccess) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nip07PubkeyHexKey, result.pubkeyHex);
      await prefs.setString(_nip07NpubKey, result.npub);
      await _setMode(SigningMode.nip07);
      AppLogger.security('SigningService',
          'Browsererweiterung verbunden: ${_short(result.npub)} — '
          'der Schlüssel bleibt in der Erweiterung.');
    }
    return result;
  }

  /// Stellt den Erweiterungs-Modus aus einem Backup wieder her.
  /// Im Backup liegt nur der npub — der Schlüssel bleibt in der Erweiterung.
  static Future<void> restoreNip07(String npub) async {
    final hex = Nip19.decodePubkey(npub.trim());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nip07PubkeyHexKey, hex);
    await prefs.setString(_nip07NpubKey, npub.trim());
    await _setMode(SigningMode.nip07);
  }

  /// Trennt die Erweiterung und löscht den gemerkten pubkey.
  static Future<void> disconnectNip07() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nip07PubkeyHexKey);
    await prefs.remove(_nip07NpubKey);
    await _setMode(SigningMode.local);
  }

  // =============================================
  // REMOTE-SIGNER (NIP-46) VERBINDEN / TRENNEN
  // =============================================

  /// Die laufende Sitzung. Wird GEHALTEN: pro Signatur neue WebSockets zu
  /// öffnen wäre langsam und würde bei jeder Anfrage erneut abonnieren.
  static Nip46Client? _nip46;

  /// Verhindert, dass zwei gleichzeitige Signier-Anfragen nach einem
  /// App-Neustart zwei Sitzungen aufbauen.
  static Completer<Nip46Client>? _nip46Rehydrating;

  /// Wird gerufen, wenn der Signer erst eine Freigabe im Browser verlangt
  /// (`auth_url`). Die UI setzt das und zeigt einen KNOPF — ein automatisch
  /// geöffnetes Fenster blockiert der Browser, weil keine Nutzer-Gestik
  /// vorliegt.
  static void Function(String url)? onNip46AuthUrl;

  /// Liefert die Sitzung, stellt sie bei Bedarf aus dem Gespeicherten her.
  static Future<Nip46Client> _nip46Session() async {
    final existing = _nip46;
    if (existing != null) return existing;

    final running = _nip46Rehydrating;
    if (running != null) return running.future;

    final completer = Completer<Nip46Client>();
    _nip46Rehydrating = completer;
    try {
      final clientKey = await SecureKeyStore.getNip46ClientKey();
      final prefs = await SharedPreferences.getInstance();
      final uri = prefs.getString(_nip46BunkerUriKey) ?? '';
      if (clientKey == null || clientKey.isEmpty || uri.isEmpty) {
        throw const SigningException(
            'Es ist keine Signer-Sitzung gespeichert. '
            'Bitte den Signer erneut verbinden.');
      }
      final client = Nip46Client.fromPointer(
        clientSecretKeyHex: clientKey,
        pointer: BunkerPointer.parse(uri),
        onAuthUrl: (url) => onNip46AuthUrl?.call(url),
      );
      _nip46 = client;
      completer.complete(client);
    } catch (e) {
      completer.completeError(e);
    } finally {
      _nip46Rehydrating = null;
    }
    return completer.future;
  }

  /// Tauscht die Sitzung und schliesst die alte — sonst blieben deren
  /// Subscriptions als Zombies offen und lieferten weiter Ereignisse.
  static Future<void> _swapNip46Session(Nip46Client? next) async {
    final old = _nip46;
    _nip46 = next;
    if (old != null && !identical(old, next)) {
      try {
        await old.close();
      } catch (_) {}
    }
  }

  /// Schliesst laufende Sitzung + loescht Sitzungsschluessel und
  /// Bunker-Prefs. Ohne Mode-Wechsel — den setzt der Aufrufer.
  ///
  /// Idempotent: auch aufrufbar, wenn gar keine nip46-Sitzung existiert.
  static Future<void> _clearNip46Artifacts() async {
    await _swapNip46Session(null);
    try {
      await SecureKeyStore.deleteNip46ClientKey();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nip46PubkeyHexKey);
    await prefs.remove(_nip46NpubKey);
    await prefs.remove(_nip46BunkerUriKey);
  }

  /// Verbindet über eine eingefügte `bunker://`-Adresse.
  ///
  /// Auf iOS ist das der Hauptweg: dort gibt es weder Amber noch eine
  /// Browsererweiterung, und ob eine App `nostrconnect://` beantwortet, ist
  /// nicht verlässlich.
  ///
  /// Ein vorhandener lokaler nsec wird BEWUSST NICHT gelöscht — gleiche
  /// Begründung wie bei connectNip07().
  static Future<Nip46ConnectResult> connectNip46Bunker(String bunkerUri) async {
    Nip46Client? client;
    try {
      final pointer = BunkerPointer.parse(bunkerUri);
      final clientKey = Nip46Client.generateClientKey();
      client = Nip46Client.fromPointer(
        clientSecretKeyHex: clientKey,
        pointer: pointer,
        onAuthUrl: (url) => onNip46AuthUrl?.call(url),
      );

      await client.connect(secret: pointer.secret);
      final userPubkeyHex = await client.getPublicKey();

      await _persistNip46Session(
        clientSecretKeyHex: clientKey,
        userPubkeyHex: userPubkeyHex,
        // Ohne secret speichern: es ist einmalig verwendbar.
        bunkerUri: pointer.toBunkerUri(),
      );
      await _swapNip46Session(client);
      final npub = Nip19.encodePubkey(userPubkeyHex);
      AppLogger.security(
          'SigningService',
          'Remote-Signer verbunden: ${_short(npub)} — '
              'der Schlüssel bleibt im Signer.');
      return Nip46ConnectSuccess(pubkeyHex: userPubkeyHex, npub: npub);
    } on Nip46TimeoutException {
      await client?.close();
      return const Nip46ConnectTimeout();
    } on Nip46Exception catch (e) {
      await client?.close();
      return Nip46ConnectError(e.message);
    } catch (e) {
      await client?.close();
      return Nip46ConnectError(e.toString());
    }
  }

  /// Startet den client-initiierten Weg: die App gibt eine Adresse aus, der
  /// Signer meldet sich darauf. Danach [completeNip46Pairing] rufen.
  static Future<Nip46Pairing> startNip46Pairing() async {
    final relays = await nip46PairingRelays();
    final clientKey = Nip46Client.generateClientKey();
    final secret = Nip46Client.generateSecret();
    final client = Nip46Client(
      clientSecretKeyHex: clientKey,
      relays: relays,
      onAuthUrl: (url) => onNip46AuthUrl?.call(url),
    );
    return Nip46Pairing(
      uri: BunkerPointer.buildNostrConnectUri(
        clientPubkeyHex: client.clientPubkeyHex,
        relays: relays,
        secret: secret,
        perms: Nip46Client.requestedPerms,
        appName: Nip46ClientMetadata.name,
        appUrl: Nip46ClientMetadata.url,
        appImage: Nip46ClientMetadata.image,
      ),
      secret: secret,
      clientSecretKeyHex: clientKey,
      relays: relays,
      client: client,
    );
  }

  /// Wartet, bis der Signer sich gemeldet hat, und übernimmt die Sitzung.
  static Future<Nip46ConnectResult> completeNip46Pairing(
      Nip46Pairing pairing) async {
    try {
      final signerPubkey =
          await pairing.client.awaitPairing(secret: pairing.secret);
      final userPubkeyHex = await pairing.client.getPublicKey();

      // Immer als bunker:// ablegen, auch wenn die Kopplung mit
      // nostrconnect:// begann — so gibt es beim Neustart nur EINEN
      // Wiederherstellungs-Pfad statt zwei.
      final pointer = BunkerPointer(
        remoteSignerPubkey: signerPubkey,
        relays: pairing.relays,
      );
      await _persistNip46Session(
        clientSecretKeyHex: pairing.clientSecretKeyHex,
        userPubkeyHex: userPubkeyHex,
        bunkerUri: pointer.toBunkerUri(),
      );
      await _swapNip46Session(pairing.client);
      final npub = Nip19.encodePubkey(userPubkeyHex);
      AppLogger.security(
          'SigningService',
          'Remote-Signer gekoppelt: ${_short(npub)} — '
              'der Schlüssel bleibt im Signer.');
      return Nip46ConnectSuccess(pubkeyHex: userPubkeyHex, npub: npub);
    } on Nip46TimeoutException {
      await pairing.cancel();
      return const Nip46ConnectTimeout();
    } on Nip46Exception catch (e) {
      await pairing.cancel();
      return Nip46ConnectError(e.message);
    } catch (e) {
      await pairing.cancel();
      return Nip46ConnectError(e.toString());
    }
  }

  static Future<void> _persistNip46Session({
    required String clientSecretKeyHex,
    required String userPubkeyHex,
    required String bunkerUri,
  }) async {
    await SecureKeyStore.saveNip46ClientKey(clientSecretKeyHex);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nip46PubkeyHexKey, userPubkeyHex);
    await prefs.setString(
        _nip46NpubKey, Nip19.encodePubkey(userPubkeyHex));
    await prefs.setString(_nip46BunkerUriKey, bunkerUri);
    await _setMode(SigningMode.nip46);
  }

  /// Relays für die Kopplung. Beim client-initiierten Weg gibt die APP die
  /// Relays vor, deshalb bewusst wenige: jedes weitere verlängert den Aufbau,
  /// ohne die Erfolgsaussicht zu verbessern.
  ///
  /// Hier stand zuerst ein fest verdrahtetes `wss://relay.damus.io` als immer
  /// erstes Relay. Das war falsch, aus zwei Gründen, die sich in der Praxis
  /// gezeigt haben:
  ///
  /// 1. Es hat die Relay-Einstellungen des Nutzers übergangen — wer damus
  ///    bewusst abgewählt hatte, bekam es hier trotzdem.
  /// 2. Der Signer ÜBERNIMMT diese Liste und merkt sie sich für die Sitzung.
  ///    Ein einzelnes ausgefallenes Relay in der Kopplungsadresse pflanzt sich
  ///    damit in die Gegenstelle fort und ist dort nicht mehr wegzukriegen,
  ///    ohne die Verbindung neu aufzubauen.
  ///
  /// Jetzt gelten die aktiven Relays der App. Der Rückfall greift nur, wenn
  /// der Nutzer alle abgeschaltet hat — ohne Relay gibt es keine Kopplung.
  @visibleForTesting
  static Future<List<String>> nip46PairingRelays() async {
    final active = await RelayConfig.getActiveRelays();
    final chosen = active.take(3).toList();
    return chosen.isNotEmpty
        ? chosen
        : RelayConfig.defaultRelays.take(2).toList();
  }

  /// Lebt die Sitzung noch? Kostet eine Relay-Runde, daher nur auf Anfrage —
  /// etwa im Profil oder nach einem fehlgeschlagenen Signieren. Damit fällt
  /// ein im Signer widerrufener ZUGANG auf, statt sich als Zeitüberschreitung
  /// zu tarnen.
  ///
  /// WAS DAS NICHT PRÜFT: ob noch Signier-RECHTE bestehen. `ping` ist in
  /// NIP-46 nicht rechtebehaftet — ein Signer antwortet auch dann mit `pong`,
  /// wenn er jede Signatur ablehnen würde. Beim Test aufgefallen: nach dem
  /// Widerruf der Rechte (Verbindung weiter aktiv) meldete die Prüfung grün,
  /// und der Text behauptete „Signieren ist möglich" — das war zu viel
  /// versprochen. Zwei verschiedene Zustände:
  ///
  ///   Verbindung widerrufen  → jede Methode scheitert → hier false
  ///   Rechte widerrufen      → ping klappt, sign_event nicht → hier true
  ///
  /// Ein „kann ich signieren?" gibt es im NIP nicht; das zeigt erst die
  /// nächste echte Signatur. Der Text sagt das jetzt so.
  static Future<bool> nip46SessionAlive() async {
    if (!await isNip46) return false;
    try {
      return await (await _nip46Session()).ping();
    } catch (_) {
      return false;
    }
  }

  /// Die Bunker-Adresse für das Backup — oder null.
  ///
  /// Der SITZUNGSSCHLÜSSEL bleibt bewusst zurück. Er ist die Berechtigung, mit
  /// der der Signer Anfragen dieser App annimmt; läge er im Backup, wäre die
  /// Datei für Bunker-Nutzer eine Signier-Berechtigung. Genau für die gilt
  /// sonst der Satz „mit externem Signer liegt kein Schlüssel im Backup" — und
  /// der soll stimmen.
  ///
  /// Preis: nach dem Wiederherstellen muss der Signer neu verbunden werden.
  /// Das ist zumutbar, denn wer einen Remote-Signer nutzt, HAT ihn — und eine
  /// Sitzung neu zu koppeln kostet einen Handgriff. Die Identität bleibt
  /// dennoch erhalten (npub + Modus), wie bei einem Amber-Backup auf iOS.
  static Future<Map<String, String>?> nip46SessionForBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final uri = prefs.getString(_nip46BunkerUriKey) ?? '';
    if (uri.isEmpty) return null;
    return {'bunker_uri': uri};
  }

  /// Stellt Identität und Bunker-Adresse aus einem Backup wieder her.
  ///
  /// [clientSecretKeyHex] ist absichtlich optional: Backups enthalten den
  /// Sitzungsschlüssel NICHT (siehe [nip46SessionForBackup]). Ohne ihn wird der
  /// Modus samt npub wiederhergestellt, `canSign()` meldet aber korrekt false —
  /// die App täuscht keine Signier-Fähigkeit vor, und der Nutzer verbindet den
  /// Signer über „Anderen Signer verbinden" neu.
  ///
  /// Ein zuvor gespeicherter Sitzungsschlüssel wird dabei GELÖSCHT. Sonst
  /// bliebe nach dem Wiederherstellen ein alter Schlüssel liegen, der nicht zur
  /// wiederhergestellten Adresse gehört — die App hielte sich für
  /// signierfähig und scheiterte erst bei der ersten Anfrage.
  static Future<void> restoreNip46({
    required String npub,
    required String bunkerUri,
    String? clientSecretKeyHex,
  }) async {
    final hex = Nip19.decodePubkey(npub.trim());
    // Wirft bei Müll, bevor irgendwas gespeichert wird.
    BunkerPointer.parse(bunkerUri);
    await _swapNip46Session(null);

    final clientKey = clientSecretKeyHex?.trim() ?? '';
    if (clientKey.isEmpty) {
      await SecureKeyStore.deleteNip46ClientKey();
    } else {
      await SecureKeyStore.saveNip46ClientKey(clientKey);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nip46PubkeyHexKey, hex);
    await prefs.setString(_nip46NpubKey, Nip19.encodePubkey(hex));
    await prefs.setString(_nip46BunkerUriKey, bunkerUri.trim());
    await _setMode(SigningMode.nip46);
  }

  /// Trennt den Remote-Signer und räumt die Sitzung ab.
  static Future<void> disconnectNip46() async {
    // _setMode(local) raeumt die Artefakte; hier vorab, damit auch ein
    // Fehlschlag beim Prefs-Schreiben den In-Memory-Client nicht uebrig laesst.
    await _clearNip46Artifacts();
    await _setMode(SigningMode.local);
  }

  static String _short(String npub) =>
      npub.length < 16 ? npub : '${npub.substring(0, 12)}…${npub.substring(npub.length - 4)}';
}
