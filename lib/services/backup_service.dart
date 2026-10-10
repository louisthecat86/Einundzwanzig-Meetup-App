import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'
    show compute, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart'; // NEU: Für Humanity-Proof Restore
import 'package:nostr/nostr.dart' show Keychain, Nip19;
import '../features.dart';
import '../models/user.dart';
import '../models/badge.dart';
import 'admin_registry.dart';
import 'nostr_service.dart';
import 'secure_key_store.dart';
import 'signing_service.dart';
import 'platform_proof_service.dart'; // NEU
import 'humanity_proof_service.dart'; // NEU
import 'pbkdf2/pbkdf2_dart.dart';
import 'pbkdf2/pbkdf2_fast.dart';
import 'app_logger.dart';
import '../utils/share_origin.dart';

class BackupService {
  /// Laeuft gerade ein Export oder ein Import?
  ///
  /// Die Schluesselableitung dauert gemessen ~1,7 s auf dem Geraet und ueber
  /// 100 s im Browser. Solange sie den Event-Loop blockiert, wirkt die App
  /// eingefroren — Nutzer tippen dann mehrfach, und JEDER Tipp startete
  /// bisher einen weiteren vollen Durchlauf. Beim Import bedeutete das
  /// mehrere gleichzeitige Wiederherstellungen auf denselben Datenbestand.
  ///
  /// Statisch und nicht pro Widget, weil Export und Import von
  /// verschiedenen Stellen aus angestossen werden (Startseite und
  /// Intro-Screen).
  static bool _busy = false;

  // =============================================
  // PBKDF2-HMAC-SHA256 KEY DERIVATION
  // =============================================
  //
  // VORHER (UNSICHER):
  //   sha256(password) → 1 Iteration, kein Salt
  //   → Milliarden Versuche/Sekunde auf GPU
  //
  // JETZT (SICHER):
  //   PBKDF2-HMAC-SHA256(password, salt, 600000 Iterationen)
  //   → ~0.3 Sekunden pro Versuch auf moderner Hardware
  //   → Brute-Force wirtschaftlich sinnlos
  //
  // OWASP Empfehlung 2024: ≥600.000 Iterationen für PBKDF2-SHA256
  // =============================================
  static const int _pbkdf2Iterations = 600000;
  static const int _saltLengthBytes = 32;
  static const int _keyLengthBytes = 32; // AES-256

  /// PBKDF2-HMAC-SHA256 Key Derivation
  /// Erzeugt einen 256-Bit AES-Key aus Passwort + Salt
  ///
  /// ASYNCHRON, weil die Rechnung teuer ist — 600.000 HMAC-Runden. Zwei Wege,
  /// beide mit demselben Ergebnis:
  ///
  ///   Web:   WebCrypto (`crypto.subtle`). In Dart brauchte dasselbe unter
  ///          dart2js rund 100 Sekunden, und die Oberfläche stand dabei.
  ///          Nutzer hielten die App für hängend und tippten mehrfach.
  ///   Nativ: dieselbe Dart-Rechnung, aber in einem Isolate. Die Dauer bleibt
  ///          (Sekunden, nicht Minuten), die Oberfläche bleibt bedienbar.
  ///
  /// Bitgleichheit ist Pflicht, nicht Kür: ein abweichender Schlüssel machte
  /// jedes bestehende Backup unlesbar. PBKDF2-HMAC-SHA256 ist vollständig
  /// spezifiziert, und beide Wege sind gegeneinander geprüft
  /// (test/pbkdf2_equality_test.dart und test/pbkdf2_web_equality_test.dart).
  static Future<enc.Key> _deriveKey(String password, Uint8List salt) async {
    final passwordBytes = utf8.encode(password);

    final fast = await pbkdf2Fast(
      password: passwordBytes,
      salt: salt,
      iterations: _pbkdf2Iterations,
      keyBytes: _keyLengthBytes,
    );
    if (fast != null) return enc.Key(fast);

    // Kein WebCrypto: selbst rechnen, aber nicht auf dem UI-Thread.
    // Im Browser läuft compute() ohne Isolate direkt durch — dort ist das
    // aber auch nur der Notfallweg (unsicherer Kontext ohne crypto.subtle).
    final bytes = await compute(
      pbkdf2Dart,
      Pbkdf2Request(
        password: passwordBytes,
        salt: salt,
        iterations: _pbkdf2Iterations,
        keyBytes: _keyLengthBytes,
      ),
    );
    return enc.Key(bytes);
  }

  // Der Rechenkern liegt jetzt in pbkdf2/pbkdf2_dart.dart — compute() braucht
  // eine Top-Level-Funktion, und dort ist er gegen eine unabhaengige
  // Implementierung testbar.

  /// Erzeugt kryptographisch sicheren Zufalls-Salt
  static Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLengthBytes);
    for (int i = 0; i < _saltLengthBytes; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Mindestlaenge fuer das Backup-Passwort.
  ///
  /// Bewusst nur die Laenge und keine Zeichenklassen: Ein erzwungenes
  /// Sonderzeichen macht Passwoerter erfahrungsgemaess nicht stark, sondern
  /// nur schwer merkbar — und ein vergessenes Backup-Passwort bedeutet hier
  /// den endgueltigen Verlust der Identitaet. Wer eine lange Passphrase
  /// nimmt, faehrt besser.
  static const int minPasswordLength = 8;

  /// Zeigt den Dialog zur Passwort-Eingabe (für Export und Import).
  ///
  /// Die Bedingungen stehen SICHTBAR unter dem Feld und werden beim Tippen
  /// mitgeprueft. Vorher erfuhr man von der Mindestlaenge erst, wenn man
  /// sie unterschritten hatte und auf Speichern drueckte — man wurde also
  /// fuer etwas getadelt, das nie jemand gesagt hatte.
  static Future<String?> _promptForPassword(BuildContext context, {required bool isExport}) async {
    String password = '';
    String passwordConfirm = '';
    String? errorText;
    bool obscure = true;
    bool obscureConfirm = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final t = AppLocalizations.of(context);

          // --- Bedingungen, live ausgewertet ---
          final longEnough = password.length >= minPasswordLength;
          final matches = password.isNotEmpty && password == passwordConfirm;
          // Beim IMPORT gibt es nichts zu pruefen: Ob das Passwort stimmt,
          // zeigt sich erst beim Entschluesseln. Eine Laengenpruefung waere
          // dort sogar falsch — alte Backups koennen kuerzere haben.
          final allOk = !isExport || (longEnough && matches);

          Color borderFor(bool ok, bool touched) {
            if (!touched) return const Color(0xFF2A2A2A);
            return ok ? Colors.green : Colors.red;
          }

          InputDecoration deco({
            required String hint,
            required bool obscured,
            required VoidCallback onToggle,
            required Color border,
            String? error,
          }) =>
              InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0A0A0A),
                errorText: error,
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: border, width: 1.2)),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: border, width: 1.6)),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white54,
                      size: 20),
                  tooltip: obscured ? t.backupPwShow : t.backupPwHide,
                  onPressed: onToggle,
                ),
              );

          Widget rule(bool ok, String text) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(ok ? Icons.check_circle : Icons.circle_outlined,
                      size: 15, color: ok ? Colors.green : Colors.white38),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(text,
                        style: TextStyle(
                            color: ok ? Colors.green : Colors.white54,
                            fontSize: 12,
                            height: 1.35)),
                  ),
                ]),
              );

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              isExport ? t.backupEncryptTitle : t.backupDecryptTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isExport ? t.backupExportDesc : t.backupImportDesc,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    obscureText: obscure,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: deco(
                      hint: t.backupPassword,
                      obscured: obscure,
                      onToggle: () => setDialogState(() => obscure = !obscure),
                      border: isExport
                          ? borderFor(longEnough, password.isNotEmpty)
                          : const Color(0xFF2A2A2A),
                      error: errorText,
                    ),
                    onChanged: (val) => setDialogState(() {
                      password = val;
                      errorText = null;
                    }),
                  ),
                  if (isExport) ...[
                    const SizedBox(height: 12),
                    TextField(
                      obscureText: obscureConfirm,
                      style: const TextStyle(color: Colors.white),
                      decoration: deco(
                        hint: t.backupPasswordConfirm,
                        obscured: obscureConfirm,
                        onToggle: () => setDialogState(
                            () => obscureConfirm = !obscureConfirm),
                        border:
                            borderFor(matches, passwordConfirm.isNotEmpty),
                      ),
                      onChanged: (val) =>
                          setDialogState(() => passwordConfirm = val),
                    ),
                    const SizedBox(height: 14),
                    rule(longEnough, t.backupPwRuleLength(minPasswordLength)),
                    rule(matches, t.backupPwRuleMatch),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(t.dialogCancelMixed, style: const TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                ),
                // Gesperrt, solange die Bedingungen offen sind. Zusammen mit
                // der Liste darunter ist damit jederzeit sichtbar, WARUM.
                onPressed: !allOk
                    ? null
                    : () {
                        if (password.isEmpty) {
                          setDialogState(() => errorText = t.backupPasswordEmpty);
                          return;
                        }
                        Navigator.pop(context, password);
                      },
                child: Text(
                  isExport ? t.backupEncryptSave : t.backupDecryptLoad,
                  style: TextStyle(
                      color: allOk ? Colors.black : Colors.white38,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- EXPORT (BACKUP ERSTELLEN) ---
  static Future<bool> createBackup(BuildContext context) async {
    if (_busy) return false; // Doppelklick waehrend der Ableitung ignorieren
    _busy = true;
    // SCHWARZE SEITE (Issue #18): Der Ladeindikator wurde unten mit
    // `Navigator.pop(context)` geschlossen und im catch NOCHMAL. Beim zweiten
    // Mal war der Dialog schon weg, also traf es die Seite DARUNTER —
    // Passwort bestaetigen, dann schwarz.
    //
    // Deshalb ein Merker plus eine Funktion, die nur schliesst, wenn noch
    // etwas offen ist. Beide stehen VOR dem try, damit der catch sie sieht.
    // Das allein behebt die schwarze Seite.
    //
    // `rootNavigator: true` ist zusaetzlich und nur vorsorglich: es passt zu
    // showDialog, das standardmaessig auf dem Root-Navigator landet. Aktuell
    // macht es keinen Unterschied — die App hat keine verschachtelten
    // Navigatoren, AppShell nutzt einen IndexedStack. Kommt spaeter einer
    // dazu, bleibt diese Stelle richtig.
    var loadingOpen = false;
    void closeLoading() {
      if (!loadingOpen) return;
      loadingOpen = false;
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    }

    try {
      // 1. Passwort abfragen
      final password = await _promptForPassword(context, isExport: true);
      if (password == null) return false; // User hat abgebrochen
      if (!context.mounted) return false;

      loadingOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
      );

      final user = await UserProfile.load();
      final badges = await MeetupBadge.loadBadges();

      // Nostr Keys aus SecureKeyStore laden
      final nsec = await SecureKeyStore.getNsec();
      final npub = await SecureKeyStore.getNpub();
      final privHex = await SecureKeyStore.getPrivHex();
      // Welche Schluessel ins Backup wandern, haengt an der tatsaechlichen
      // Existenz — nicht am Signing-Modus. Amber/NIP-07 allein: kein nsec,
      // Felder bleiben leer. Mischzustand (lokaler Schluessel + externer
      // Modus): der nsec wird mitgesichert.
      //
      // signing_mode + active_npub: damit der Import den Modus auch dann
      // wiederherstellen kann, wenn zusaetzlich ein lokaler Schluessel
      // vorliegt (Mischzustand). Ohne active_npub wuerde nur der
      // Keystore-npub existieren — der kann von der Amber-/Erweiterungs-
      // Identitaet abweichen.
      final signingMode = await SigningService.getMode();
      final String? activeNpub = await SigningService.npub();
      // Eine Definition, nicht zwei: sonst wuerde ein neuer externer Modus
      // hier vergessen und der Mischzustand still falsch gesichert.
      final bool isExternal = await SigningService.isExternalSigner;
      final nip46Session = await SigningService.nip46SessionForBackup();
      // nsec und npub MUESSEN zusammengehoeren. activeNpub ist im
      // Amber/NIP-07-Modus die externe Identitaet — die darf nie als
      // Keystore-npub neben einem lokalen nsec landen.
      final bool hasLocalKey = nsec != null && nsec.isNotEmpty;
      final String backupNpub = hasLocalKey
          ? (npub ?? '')
          : (activeNpub ?? npub ?? '');
      // Nur im Mischzustand noetig: lokaler Key + anderer aktiver Signer.
      final String backupActiveNpub =
          (isExternal && hasLocalKey) ? (activeNpub ?? '') : '';
      final adminList = await AdminRegistry.getAdminList();

      // =============================================
      // NEU: Platform Proofs & Humanity Proof laden
      // =============================================
      final platformProofs = await PlatformProofService.getSavedProofs();
      final humanityStatus = await HumanityProofService.getStatus();

      Map<String, dynamic> backupData = {
        'version': 5, // v5: + Platform Proofs + Humanity Proof
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'Einundzwanzig Meetup App',

        'user': {
          'nickname': user.nickname,
          'fullName': user.fullName,
          'homeMeetupId': user.homeMeetupId,
          'favoriteMeetupIds': user.favoriteMeetupIds,
          'isAdmin': user.isAdmin,
          'isAdminVerified': user.isAdminVerified,
          'isNostrVerified': user.isNostrVerified,
          'nostrNpub': user.nostrNpub,
          'telegramHandle': user.telegramHandle,
          'twitterHandle': user.twitterHandle,
        },
        // Badges vollständig über toJson sichern (enthält ALLE Felder:
        // Signatur, Claim-Binding, iconPath, lat/lng, isOrganizer ...).
        // So gehen beim Wiederherstellen keine Felder mehr verloren.
        'badges': badges.map((b) => b.toJson()).toList(),
        'nostr': {
          // An der tatsaechlichen EXISTENZ aufgehaengt, nicht am Modus.
          //
          // Vorher stand hier `isExternal ? '' : nsec` — der Modus war ein
          // Stellvertreter fuer "gibt es ueberhaupt einen nsec". In reinem
          // Amber- oder Erweiterungs-Modus ist nsec ohnehin null, die
          // Bedingung war dort also wirkungslos. Wirkung hatte sie nur im
          // gemischten Fall: wer einen lokalen Schluessel hatte und dann
          // Amber verband, behielt den Schluessel — das Backup liess ihn aber
          // weg, und beim Wiederherstellen war er still verschwunden.
          //
          // Diese Fassung sichert, was da ist. Damit muss auch niemand einen
          // vorhandenen Schluessel loeschen, um Konsistenz herzustellen.
          // npub: bei lokalem Schluessel immer der Keystore-npub (siehe oben).
          'nsec': nsec ?? '',
          'npub': backupNpub,
          'priv_hex': hasLocalKey ? (privHex ?? '') : '',
          'has_key': hasLocalKey,
          // mode.name liefert 'local' / 'amber' / 'nip07' — fuer die beiden
          // alten Werte identisch zu vorher, also aufwaertskompatibel.
          'signing_mode': signingMode.name,
          // Leer ausser im Mischzustand. Alte Backups ohne dieses Feld
          // bleiben lesbar (Import faellt auf npub zurueck).
          'active_npub': backupActiveNpub,
          // Bunker-ADRESSE (NIP-46) — bewusst OHNE Sitzungsschluessel.
          //
          // Der Sitzungsschluessel ist die Berechtigung, mit der der Signer
          // Anfragen dieser App annimmt. Laege er im Backup, waere die Datei
          // fuer Bunker-Nutzer eine Signier-Berechtigung: wer sie hat und das
          // Passwort bricht, koennte bis zum Widerruf Signaturen anfragen.
          // Genau fuer diese Nutzer soll aber gelten, dass im Backup KEIN
          // Schluessel liegt — das ist der Sinn eines externen Signers.
          //
          // Folge: nach dem Wiederherstellen bleibt die Identitaet erhalten
          // (npub + Modus), signieren geht erst nach erneutem Verbinden.
          // canSign() meldet das korrekt mit false — dieselbe Lage wie bei
          // einem Amber-Backup auf iOS.
          'nip46_bunker_uri': nip46Session?['bunker_uri'] ?? '',
        },
        'admin_registry': adminList.map((a) => a.toJson()).toList(),

        // =============================================
        // NEU: Platform Proofs sichern
        // =============================================
        // Enthält alle verknüpften Plattform-Accounts mit
        // signierten Verify-Strings. Ohne diese müsste der
        // User nach dem Restore alle Plattformen neu verknüpfen.
        // =============================================
        'platform_proofs': platformProofs.map((p) => {
          'platform': p.platform,
          'username': p.username,
          'proof_sig': p.proofSig,
          'created_at': p.createdAt,
        }).toList(),

        // =============================================
        // NEU: Humanity Proof sichern
        // =============================================
        // Der Humanity-Proof beweist, dass der Nutzer eine
        // echte Lightning-Zahlung getätigt hat. Ohne Backup
        // muss er nach Restore erneut auf Relays gesucht
        // werden — was unnötig lange dauert und evtl. fehlschlägt.
        // =============================================
        'humanity_proof': {
          'verified': humanityStatus.verified,
          'first_zap_at': humanityStatus.firstZapAt,
          'receipt_event_id': humanityStatus.receiptEventId,
          'checked_at': humanityStatus.lastCheckedAt,
        },
      };

      String jsonString = jsonEncode(backupData);

      // =============================================
      // VERSCHLÜSSELUNG: PBKDF2-HMAC-SHA256 + AES-256-GCM
      // =============================================
      final salt = _generateSalt();

      // Einen echten Frame durchlassen, bevor die Ableitung den Event-Loop
      // fuer ~1,7 s (Geraet) bzw. ueber 100 s (Browser) blockiert.
      //
      // Der Ladeindikator wird oben schon per showDialog angefordert, war aber
      // trotzdem nicht zu sehen: die await-Aufrufe dazwischen loesen sich aus
      // dem Cache ueber MICROTASKS auf, und Microtasks laufen VOR dem
      // Zeichnen. Ohne Rueckkehr in den Event-Loop kam Flutter also nie zum
      // Frame — die App wirkte, als passiere nichts. Ein Timer (auch mit 0)
      // erzwingt diese Rueckkehr, 50 ms geben zuverlaessig Zeit fuers Malen.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final key = await _deriveKey(password, salt);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      // Format: "enc_v2:[SALT_BASE64]:[IV_BASE64]:[CIPHERTEXT_BASE64]"
      //
      // enc_v2 = PBKDF2 Key Derivation (enc_v1 war SHA-256 direkt)
      // Salt wird für die Ableitung des Keys benötigt
      // IV wird für AES-GCM benötigt
      final finalPayload = "enc_v2:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}";

      // Dateiname
      String dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      // Nickname für den Dateinamen bereinigen (nur sichere Zeichen),
      // damit man bei mehreren Profilen die Backups auseinanderhält.
      final safeNick = user.nickname.trim().isEmpty
          ? 'Anon'
          : user.nickname.trim().replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      // Format: Backup_<Datum>_21MeetupApp_<Nickname>.21bkp
      final fileName = 'Backup_${dateStr}_21MeetupApp_$safeNick.21bkp';

      // Die Bytes direkt teilen, statt selbst eine Datei in
      // getTemporaryDirectory() zu schreiben: path_provider hat KEINE
      // Web-Implementierung (das Paket deklariert nur android, ios, linux,
      // macos, windows). Im Browser endete das Sichern deshalb mit einer
      // MissingPluginException — Backup war dort vollstaendig funktionslos.
      //
      // share_plus legt die temporaere Datei auf iOS/Android selbst an, wenn
      // die XFile keinen Pfad hat. `name` greift im Web, `fileNameOverrides`
      // nativ — nur so behaelt die Datei ihre .21bkp-Endung, die share_plus
      // sonst aus dem mimeType ableiten wuerde.
      final bytes = Uint8List.fromList(utf8.encode(finalPayload));

      if (!context.mounted) {
        closeLoading();
        return false;
      }
      // Texte VOR dem Schliessen des Dialogs holen: danach ist context
      // moeglicherweise nicht mehr verwendbar.
      final shareTitle = AppLocalizations.of(context).backupShareTitle;
      final shareText = AppLocalizations.of(context).backupShareText;

      closeLoading();

      // ERST der Speicherdialog des Systems, dann als Rueckfall das Teilen.
      //
      // Warum ueberhaupt zwei Wege: Ueber das Teilen-Blatt landet die Datei
      // in irgendeiner App — Mail, Messenger, Cloud. Wer sie schlicht auf
      // dem Geraet ablegen will, musste hoffen, dass unter den Zielen ein
      // Dateimanager auftaucht. saveFile oeffnet stattdessen direkt die
      // Ordnerauswahl des Systems.
      try {
        final savedPath = await FilePicker.platform.saveFile(
          dialogTitle: shareTitle,
          fileName: fileName,
          bytes: bytes,
        );
        if (savedPath != null) {
          AppLogger.info('App', 'Backup gespeichert: $savedPath');
          return true;
        }
        // null heisst abgebrochen — dann NICHT still aufgeben, sondern das
        // Teilen anbieten. Auf Plattformen ohne Speicherdialog kommt man
        // ohnehin nur so weiter.
      } catch (e) {
        AppLogger.debug('App', 'Speicherdialog nicht verfuegbar: $e');
      }

      // Anker erst hier. Passwort, Ableitung und der Speicherdialog liegen
      // dazwischen; ein frueher festgehaltenes Rechteck liegt nach einer
      // Drehung ausserhalb der Ansicht, und iOS 26 wirft dann wieder.
      // Ist die Seite weg, nicht teilen: true wuerde beim Reset die
      // Schluessel loeschen, obwohl nirgends eine Datei liegt.
      if (!context.mounted) return false;
      final shareOrigin = shareOriginFor(context);

      final shareResult = await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/octet-stream', name: fileName)],
        fileNameOverrides: [fileName],
        subject: shareTitle,
        text: shareText,
        sharePositionOrigin: shareOrigin,
      );

      // Abbruch des Teilen-Blatts ist kein FEHLER, aber auch kein Erfolg —
      // und der Unterschied ist hier gefaehrlich:
      //
      // _resetApp() in home_screen ruft createBackup() und loescht bei
      // Rueckgabe true die App-Daten, inklusive SecureKeyStore.deleteKeys().
      // Wer das Teilen abbricht, hat NIRGENDS eine Datei — share_plus legt
      // nativ nur eine Datei im temporaeren Verzeichnis an, an die der Nutzer
      // nicht herankommt. Mit true haette die App "Backup erstellt" gemeldet
      // und angeboten, die Schluessel zu loeschen.
      //
      // Deshalb: nur explizites Verwerfen gilt als "nicht erledigt".
      // `unavailable` bleibt true, weil manche Plattformen den Status gar
      // nicht melden und ein Fehlalarm dort schlimmer waere.
      return shareResult.status != ShareResultStatus.dismissed;
    } catch (e) {
      AppLogger.warn('App', "Backup Fehler: $e");
      // Schliesst NUR, wenn der Ladeindikator noch offen ist — sonst wuerde
      // hier die Seite darunter verschwinden (Issue #18).
      closeLoading();
      // Auf manchen iOS-Staenden wirft shareXFiles beim Abbrechen statt
      // ShareResultStatus.dismissed. Dann KEINE rote Fehlermeldung zeigen —
      // aber auch NICHT true melden: der Reset-Flow loescht bei true die
      // Schluessel, und gespeichert ist in diesem Fall nichts (s.o.).
      if (_isShareDismissed(e)) {
        return false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).backupError(e.toString())), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      // MUSS auf jedem Ausgang zurueckgesetzt werden — sonst blockiert ein
      // einziger Lauf die Funktion bis zum App-Neustart.
      _busy = false;
    }
  }

  /// True, wenn der Nutzer das Teilen-Blatt abgebrochen hat (kein echter Fehler).
  static bool _isShareDismissed(Object e) {
    if (e is! PlatformException) return false;
    final hay = '${e.code} ${e.message} ${e.details}'.toLowerCase();
    return hay.contains('dismiss') ||
        hay.contains('cancel') ||
        hay.contains('aborted') ||
        hay.contains('user cancelled') ||
        hay.contains('user canceled');
  }

  // --- IMPORT (WIEDERHERSTELLEN) ---
  static Future<bool> restoreBackup(BuildContext context) async {
    if (_busy) return false;
    _busy = true;

    // Uebersetzungen VOR dem ersten await greifen. Danach kann das Widget
    // laengst weg sein — der Dateiwaehler und die Schluesselableitung
    // dauern zusammen mehrere Sekunden. Das AppLocalizations-Objekt selbst
    // bleibt gueltig, auch wenn der Context es nicht mehr ist.
    final t = AppLocalizations.of(context);

    try {
      // withData: true, damit die Bytes auf ALLEN Plattformen mitkommen.
      //
      // Vorher wurde nur `result.files.single.path` ausgewertet. Im Browser
      // ist der Pfad immer null — der Dateiwaehler liefert dort ausschliesslich
      // Bytes. Die Bedingung war damit im Web nie erfuellt und das
      // Wiederherstellen tat lautlos gar nichts: kein Fehler, keine Meldung.
      //
      // Backup-Dateien sind wenige Kilobyte gross, das Laden in den Speicher
      // ist also auch auf dem Telefon unproblematisch.
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      final picked = result?.files.single;
      if (picked != null && (picked.bytes != null || picked.path != null)) {
        // Bytes bevorzugen (einziger Weg im Web); Pfad als Rueckfallebene,
        // falls eine Plattform trotz withData keine Bytes liefert.
        final String content = picked.bytes != null
            ? utf8.decode(picked.bytes!)
            : await File(picked.path!).readAsString();

        String decryptedJson = content;

        // =============================================
        // enc_v2: PBKDF2 + AES-GCM (neues Format)
        // =============================================
        if (content.startsWith("enc_v2:")) {
          // Statische Methode ohne State: context.mounted statt mounted.
          if (!context.mounted) return false;
          final password = await _promptForPassword(context, isExport: false);
          if (password == null) return false;

          try {
            final parts = content.split(':');
            if (parts.length != 4) throw Exception(t.backupCorrupt);

            final salt = Uint8List.fromList(base64Decode(parts[1]));
            final iv = enc.IV.fromBase64(parts[2]);
            final cipherText = parts[3];

            // Ladeindikator: die Ableitung dauert gemessen ~1,7 s auf dem
            // Geraet und ueber 100 s im Browser (600.000 Iterationen, in
            // dart2js reines Dart). Vorher gab es hier GAR KEINE Rueckmeldung
            // — die Oberflaeche stand einfach, und Nutzer haben mehrfach
            // getippt, was jedes Mal einen weiteren Durchlauf startete.
            if (context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
              );
            }
            // Einen Frame durchlassen, damit der Indikator gezeichnet ist,
            // bevor die synchrone Ableitung den Event-Loop blockiert.
            await Future<void>.delayed(const Duration(milliseconds: 50));

            final enc.Key key;
            try {
              key = await _deriveKey(password, salt);
            } finally {
              if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
            }
            final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

            decryptedJson = encrypter.decrypt64(cipherText, iv: iv);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).backupWrongPassword),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        }
        // =============================================
        // enc_v1: Legacy SHA-256 + AES-GCM (altes Format)
        // Rückwärtskompatibilität — wird trotzdem entschlüsselt
        // =============================================
        else if (content.startsWith("enc_v1:")) {
          if (!context.mounted) return false;
          final password = await _promptForPassword(context, isExport: false);
          if (password == null) return false;

          try {
            final parts = content.split(':');
            if (parts.length != 3) throw Exception(t.backupCorrupt);

            final iv = enc.IV.fromBase64(parts[1]);
            final cipherText = parts[2];

            // Legacy: SHA-256 direkt (kein Salt, keine Iterationen)
            final bytes = utf8.encode(password);
            final digest = sha256.convert(bytes);
            final key = enc.Key(Uint8List.fromList(digest.bytes));
            final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

            decryptedJson = encrypter.decrypt64(cipherText, iv: iv);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context).backupWrongPassword),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        }

        // --- JSON PARSEN UND VERARBEITEN ---
        Map<String, dynamic> data;
        try {
          data = jsonDecode(decryptedJson);
        } catch (e) {
          throw Exception(t.backupNotValid);
        }

        if (!data.containsKey('user') || !data.containsKey('badges')) {
          throw Exception(t.backupNotEinundzwanzig);
        }

        final int version = data['version'] ?? 1;

        // --- USER WIEDERHERSTELLEN ---
        var userData = data['user'];
        var user = UserProfile(
          nickname: userData['nickname'] ?? "Anon",
          fullName: userData['fullName'] ?? "",
          homeMeetupId: userData['homeMeetupId'] ?? "",
          // Favoriten wiederherstellen; aeltere Backups ohne das Feld
          // fallen auf das Einzel-Home-Meetup zurueck (kein Datenverlust).
          favoriteMeetupIds: (userData['favoriteMeetupIds'] as List?)?.map((e) => e.toString()).toList()
              ?? ((userData['homeMeetupId'] ?? '').toString().isNotEmpty ? [userData['homeMeetupId'].toString()] : <String>[]),
          isAdmin: userData['isAdmin'] ?? false,
          isAdminVerified: userData['isAdminVerified'] ?? false,
          isNostrVerified: userData['isNostrVerified'] ?? false,
          nostrNpub: userData['nostrNpub'] ?? "",
          telegramHandle: userData['telegramHandle'] ?? "",
          twitterHandle: userData['twitterHandle'] ?? "",
        );
        await user.save();

        // --- BADGES WIEDERHERSTELLEN ---
        List<dynamic> badgeList = data['badges'];
        List<MeetupBadge> restoredBadges = [];
        for (var b in badgeList) {
          final map = Map<String, dynamic>.from(b as Map);
          // iconPath für alte Backups absichern (wurde früher nicht
          // mitgesichert -> fromJson würde sonst auf null fehlschlagen).
          if (map['iconPath'] == null || (map['iconPath'] as String).isEmpty) {
            map['iconPath'] = 'assets/badge_icon.png';
          }
          // Vollständig über fromJson rekonstruieren: stellt ALLE Felder
          // wieder her, inkl. lat/lng (Weltkugel/Standort) und Claim-Binding.
          restoredBadges.add(MeetupBadge.fromJson(map));
        }
        await MeetupBadge.saveBadges(restoredBadges);

        // --- NOSTR KEYS WIEDERHERSTELLEN ---
        if (version >= 2 && data['nostr'] != null) {
          final nostrData = data['nostr'] as Map<String, dynamic>;
          final hasKey = nostrData['has_key'] ?? false;
          final mode = '${nostrData['signing_mode'] ?? 'local'}';
          var restoredLocalKey = false;

          if (hasKey) {
            final nsec = nostrData['nsec'] ?? '';
            final npub = nostrData['npub'] ?? '';
            final privHex = nostrData['priv_hex'] ?? '';

            // Security Audit H4: im Browser den nsec nicht in den
            // Speicher schreiben. Profil und Badges bleiben erhalten.
            final allowLocalKey = !kIsWeb || kWebLocalNsecLoginEnabled;
            if (!allowLocalKey && nsec.isNotEmpty) {
              AppLogger.warn('BackupService',
                  'Lokaler nsec aus dem Backup im Web nicht übernommen.');
            }
            if (allowLocalKey &&
                nsec.isNotEmpty &&
                npub.isNotEmpty &&
                privHex.isNotEmpty) {
              // Security Audit N3: Konsistenz erzwingen, bevor etwas in den
              // Keystore wandert. Ein manipuliertes Backup könnte sonst eine
              // Identität anzeigen (npub), die zu einem anderen privaten
              // Schlüssel signiert. nsec und priv_hex müssen denselben
              // Schlüssel ergeben, und dessen pubkey muss dem npub
              // entsprechen.
              if (!_backupKeyConsistent(nsec, npub, privHex)) {
                AppLogger.security('BackupService',
                    'Backup-Schlüssel inkonsistent (nsec/npub/priv_hex '
                    'gehören nicht zusammen) — nicht übernommen.');
                // Das Profil wurde oben schon mit dem npub aus dem Backup
                // gespeichert. Der bleibt sonst stehen, während der
                // vorhandene Schlüssel ein anderer ist.
                await _alignNostrIdentityWithKeystore(user);
              } else {
                await SecureKeyStore.saveKeys(
                  nsec: nsec,
                  npub: npub,
                  privHex: privHex,
                );
                restoredLocalKey = true;
              }
            }
          }

          // signing_mode gewinnt fuer den aktiven Signer — auch wenn ein
          // lokaler Schluessel mitkam (Mischzustand). Der nsec bleibt im
          // Keystore; signiert wird weiter ueber Amber/Erweiterung.
          //
          // Hinweis zur Plattform: ein Amber-Backup auf iOS oder ein
          // NIP-07-Backup auf dem Telefon stellt die IDENTITAET wieder her,
          // signieren kann die App dort aber nicht — Amber gibt es nur auf
          // Android, NIP-07 nur im Browser. canSign() meldet das korrekt
          // mit false, statt einen Schluessel vorzutaeuschen.
          var externalRestored = false;
          if (mode == 'amber' || mode == 'nip07' || mode == 'nip46') {
            // active_npub: externe Identitaet im Mischzustand.
            // Fallback npub: reine Amber/NIP-07/Bunker-Backups und aeltere
            // Misch-Backups ohne das neue Feld.
            final activeRaw = '${nostrData['active_npub'] ?? ''}';
            final externalNpub = activeRaw.isNotEmpty
                ? activeRaw
                : '${nostrData['npub'] ?? ''}';
            if (externalNpub.isNotEmpty) {
              try {
                if (mode == 'nip07') {
                  await SigningService.restoreNip07(externalNpub);
                } else if (mode == 'nip46') {
                  // OHNE Sitzungsschluessel — der reist nicht mit. Ein
                  // 'nip46_client_sk' aus einem aelteren Test-Backup wird
                  // absichtlich IGNORIERT: sonst haette die Entscheidung
                  // "die Sitzung reist nicht mit" ein Hintertuerchen.
                  await SigningService.restoreNip46(
                    npub: externalNpub,
                    bunkerUri: '${nostrData['nip46_bunker_uri'] ?? ''}',
                  );
                } else {
                  await SigningService.restoreAmber(externalNpub);
                }
                user.nostrNpub = externalNpub;
                user.isNostrVerified = true;
                // Lokaler Key kann zusaetzlich liegen — hasNostrKey spiegelt
                // nur den Keystore, nicht den aktiven Signer.
                user.hasNostrKey = restoredLocalKey;
                await user.save();
                externalRestored = true;
              } catch (e) {
                // Vorher wurde das stillschweigend verworfen. Bei einem
                // Bunker-Backup ist das der wahrscheinlichste Fehlerfall
                // (Sitzungsfelder fehlen oder sind kaputt), und ohne Meldung
                // stand die App danach ohne aktiven Signer da.
                AppLogger.warn(
                    'BackupService',
                    'Externer Signer ($mode) aus dem Backup nicht '
                        'wiederherstellbar',
                    e);
              }
            }
          }

          // Fallback: der externe Signer liess sich nicht wiederherstellen,
          // ein lokaler Schluessel kam aber mit. Ohne diesen Zweig bliebe die
          // App ohne nutzbaren Signier-Modus zurueck, obwohl der Schluessel
          // im Keystore liegt.
          if (!externalRestored && restoredLocalKey) {
            await SigningService.useLocalMode();
            final npub = '${nostrData['npub'] ?? ''}';
            user.nostrNpub = npub;
            user.isNostrVerified = true;
            user.hasNostrKey = true;
            await user.save();
          }
        }

        // --- ADMIN REGISTRY WIEDERHERSTELLEN (MIT VALIDIERUNG) ---
        // Security Audit 2, Fund #1: Backup könnte manipulierte npubs enthalten.
        // Wir validieren das npub-Format und erzwingen danach eine Relay-Prüfung.
        if (version >= 2 && data['admin_registry'] != null) {
          final registryList = data['admin_registry'] as List<dynamic>;
          int restoredAdmins = 0;
          int rejectedAdmins = 0;

          for (var adminJson in registryList) {
            try {
              final entry = AdminEntry.fromJson(adminJson as Map<String, dynamic>);

              // npub-Format validieren
              if (!NostrService.isValidNpub(entry.npub)) {
                rejectedAdmins++;
                continue;
              }

              await AdminRegistry.addAdmin(entry);
              restoredAdmins++;
            } catch (e) {
              rejectedAdmins++;
            }
          }

          // Nach Restore sofort Relay-Validierung erzwingen.
          // Einträge die NICHT von signierten Events auf Relays bestätigt werden,
          // werden beim nächsten Merge verworfen.
          try {
            await AdminRegistry.forceRefresh();
            AppLogger.debug('Backup',
              'Admin-Registry revalidiert. Restored: $restoredAdmins, Rejected: $rejectedAdmins');
          } catch (e) {
            AppLogger.warn('Backup',
              'Admin-Registry Revalidierung fehlgeschlagen (offline?). '
              'Einträge werden beim nächsten Online-Start geprüft.');
          }
        }

        // Bürgschaften werden nicht mehr wiederhergestellt.
        //
        // Aeltere Sicherungen enthalten noch ein Feld `my_vouches`. Es wird
        // stillschweigend uebergangen: Bürgschaften haben in dieser Fassung
        // keine Wirkung mehr, und etwas wiederherzustellen, das nichts tut,
        // waere nur Ballast.

        // =============================================
        // PLATFORM PROOFS WIEDERHERSTELLEN (MIT VALIDIERUNG)
        // =============================================
        // Security Audit 2, Fund #4: Nur Proofs mit gültiger Signatur
        // akzeptieren. Leere oder ungültige Signaturen werden verworfen.
        if (data['platform_proofs'] != null) {
          final proofList = data['platform_proofs'] as List<dynamic>;
          if (proofList.isNotEmpty) {
            final validatedProofs = <dynamic>[];

            for (final proof in proofList) {
              try {
                final proofMap = proof as Map<String, dynamic>;
                final proofSig = proofMap['proof_sig'] as String? ?? '';

                // Leere Signaturen ablehnen
                if (proofSig.isEmpty) continue;

                // Signatur-Format prüfen (128 hex chars = 64 bytes Schnorr)
                if (proofSig.length == 128 &&
                    RegExp(r'^[0-9a-fA-F]+$').hasMatch(proofSig)) {
                  validatedProofs.add(proof);
                }
              } catch (_) {
                // Ungültiges Format → überspringen
              }
            }

            if (validatedProofs.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('platform_proofs', jsonEncode(validatedProofs));
            }
          }
        }

        // =============================================
        // HUMANITY PROOF: Als "needs_reverification" markieren
        // =============================================
        // Security Audit 2, Fund #4: NICHT direkt als verified setzen!
        // Stattdessen Receipt-Daten speichern und als "pending" markieren.
        // HumanityProofService prüft beim nächsten Start auf Relays
        // ob der Zap-Receipt tatsächlich existiert.
        if (data['humanity_proof'] != null) {
          final hp = data['humanity_proof'] as Map<String, dynamic>;
          final hpVerified = hp['verified'] as bool? ?? false;

          if (hpVerified) {
            final prefs = await SharedPreferences.getInstance();
            // NICHT: await prefs.setBool('humanity_verified', true);
            // Stattdessen: als "pending reverification" markieren
            await prefs.setBool('humanity_verified', false);
            await prefs.setBool('humanity_needs_reverification', true);

            final receiptId = hp['receipt_event_id'] as String? ?? '';
            if (receiptId.isNotEmpty) {
              await prefs.setString('humanity_receipt_id', receiptId);
            }
            final firstZapAt = hp['first_zap_at'] as int? ?? 0;
            if (firstZapAt > 0) {
              await prefs.setInt('humanity_first_zap_at', firstZapAt);
            }
            final checkedAt = hp['checked_at'] as int? ?? 0;
            if (checkedAt > 0) {
              await prefs.setInt('humanity_checked_at', checkedAt);
            }

            AppLogger.debug('Backup',
              'Humanity-Proof als pending_reverification markiert. '
              'Receipt: ${receiptId.isNotEmpty ? "vorhanden" : "fehlt"}');
          }
        }

        // --- ERFOLGSMELDUNG ---
        if (context.mounted) {
          // Zähle was wiederhergestellt wurde
          final hasNostr = version >= 2 && data['nostr'] != null && (data['nostr']['has_key'] ?? false);
          final hasPlatformProofs = data['platform_proofs'] != null &&
              (data['platform_proofs'] as List<dynamic>).isNotEmpty;
          final hasHumanity = data['humanity_proof'] != null &&
              (data['humanity_proof']['verified'] as bool? ?? false);

          // Detaillierte Erfolgsmeldung
          final List<String> restored = ['Profil', '${restoredBadges.length} Badges'];
          if (hasNostr) restored.add('Nostr-Key');
          if (hasPlatformProofs) {
            final count = (data['platform_proofs'] as List<dynamic>).length;
            restored.add('$count Plattform-Proofs');
          }
          if (hasHumanity) restored.add('Humanity-Proof');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).backupLoaded(restored.join(', '))),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      AppLogger.warn('App', "Import Fehler: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).backupImportFailed(e.toString())), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      _busy = false;
    }
  }

  /// Angezeigte Nostr-Identität an den Schlüssel hängen, der wirklich
  /// im Keystore liegt. Nach einem abgelehnten Backup-Schlüssel darf
  /// das Profil nicht den npub aus dem Backup behalten.
  static Future<void> _alignNostrIdentityWithKeystore(UserProfile user) async {
    final existing = await SecureKeyStore.getNpub();
    if (existing != null && existing.isNotEmpty) {
      user.nostrNpub = existing;
      user.isNostrVerified = true;
      user.hasNostrKey = true;
    } else {
      user.nostrNpub = '';
      user.isNostrVerified = false;
      user.hasNostrKey = false;
    }
    await user.save();
  }

  /// Security Audit N3: Gehören nsec, npub und priv_hex eines Backups
  /// zusammen? nsec muss denselben privaten Schlüssel dekodieren wie
  /// priv_hex angibt, und der zugehörige pubkey muss dem npub entsprechen.
  @visibleForTesting
  static bool backupKeyConsistent(String nsec, String npub, String privHex) =>
      _backupKeyConsistent(nsec, npub, privHex);

  static bool _backupKeyConsistent(String nsec, String npub, String privHex) {
    try {
      final privFromNsec = Nip19.decodePrivkey(nsec.trim()).toLowerCase();
      final priv = privHex.trim().toLowerCase();
      if (privFromNsec != priv) return false;
      if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(priv)) return false;
      final derivedNpub = Nip19.encodePubkey(Keychain(priv).public);
      return derivedNpub == npub.trim();
    } catch (_) {
      return false;
    }
  }
}


