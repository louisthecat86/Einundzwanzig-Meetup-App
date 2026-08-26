// MEETUP VERIFICATION — Badge Scanner
// ============================================
// Scannt NFC-Tags und Rolling-QR-Codes.
// Unterstützt sowohl Kompakt-Format (v2c) als auch Legacy.
//
// Ablauf:
//   1. NFC oder QR lesen
//   2. Format erkennen (kompakt vs. legacy)
//   3. BadgeSecurity.verify() → Schnorr-Check + Ablauf
//   4. AdminRegistry.checkAdminByPubkey() → Signer bekannt?
//   5. Normalisieren (kompakt → volle Feldnamen)
//   6. Badge MIT kryptographischem Beweis speichern
//   7. NEU: Claim-Signatur erstellen (Badge-Binding)
//   8. NEU: Reputation auf Relays aktualisieren (Auto-Publish)
//
// SICHERHEIT:
//   - Signatur allein reicht NICHT — der Signer-Pubkey
//     wird gegen die Admin Registry geprüft.
//   - Unbekannte Signer werden deutlich als ✗ markiert.
//   - Legacy v1 Badges werden als unsicher gekennzeichnet.
//   - NFC-Simulation ENTFERNT — kein Fake-Badge mehr möglich.
// ============================================

import 'package:flutter/material.dart';
import '../services/app_logger.dart';
import 'dart:convert';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';    // Ndef (cross-platform)
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:nostr/nostr.dart';
import '../theme.dart';
import '../widgets/scanner_overlay.dart';
import '../l10n/app_localizations.dart';
import '../features.dart';
import '../services/coattendance_service.dart';
import '../services/event_badge_chain_service.dart';
import '../services/meetup_location_service.dart';
import '../services/meetup_service.dart';
import '../services/portal_leader_service.dart';
import '../models/badge.dart';
import '../models/meetup.dart';
import '../services/badge_security.dart';
import '../services/badge_claim_service.dart';               // NEU: Claim-Binding
import '../services/reputation_publisher.dart';              // NEU: Auto-Publish
import 'badge_wallet.dart';                                  // für direkten Sprung in die Wallet
import '../services/nostr_service.dart';
import '../services/mempool.dart';
import '../services/rolling_qr_service.dart';
import '../services/admin_registry.dart';

class MeetupVerificationScreen extends StatefulWidget {
  final Meetup meetup;
  const MeetupVerificationScreen({super.key, required this.meetup});

  @override
  State<MeetupVerificationScreen> createState() => _MeetupVerificationScreenState();
}

class _MeetupVerificationScreenState extends State<MeetupVerificationScreen> with SingleTickerProviderStateMixin {
  bool _tagProcessing = false; // Sperre gegen Mehrfach-Erkennung desselben Tags

  bool _success = false;
  bool _isUnknownSigner = false; // Flag für unbekannten Signer
  String? _statusText;
  MeetupBadge? _pendingBadge; // Badge wartet auf Bestätigung
  // Organisator-Standort aus dem gescannten QR (unsignierte Felder la/lo).
  // Referenzpunkt für den 5km-Präsenz-Check des Teilnehmers.
  double _pendingOrgLat = 0;
  double _pendingOrgLng = 0;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _statusText ??= AppLocalizations.of(context).verifyReadyToScan;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // =============================================
  // NFC LESEN
  // =============================================
  // FIX: Bei fehlendem/deaktiviertem NFC wird jetzt ein
  // Dialog angezeigt statt einen Fake-Badge zu erstellen.
  // =============================================

  /// NFC-Lesen. Bleibt im Code, wird aber nicht mehr aufgerufen, solange
  /// [kNfcEnabled] false ist — siehe lib/features.dart.
  // ignore: unused_element
  void _startNfcRead() async {
    setState(() => _statusText = AppLocalizations.of(context).verifyCheckingNfc);

    final availability = await NfcManager.instance.checkAvailability();

    if (availability != NfcAvailability.enabled) {
      // ── NFC nicht verfügbar → Dialog ──
      if (!mounted) return;

      // NFC könnte deaktiviert oder nicht unterstützt sein
      // availability.toString() enthält den Enum-Wert
      final bool isNotSupported = availability.toString().toLowerCase().contains('not');

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: cCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(
            Icons.nfc_rounded,
            size: 48,
            color: isNotSupported ? Colors.red : cOrange,
          ),
          title: Text(
            isNotSupported ? AppLocalizations.of(context).nfcUnavailable : AppLocalizations.of(context).nfcDisabled,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isNotSupported
                ? AppLocalizations.of(context).verifyNoNfcLong +
                  AppLocalizations.of(context).verifyUseQrInstead +
                  AppLocalizations.of(context).verifyToGetBadge
                : "${AppLocalizations.of(context).nfcEnableHint}${AppLocalizations.of(context).verifyToGetBadge}\n\n${AppLocalizations.of(context).nfcSettingsAndroid}\n${AppLocalizations.of(context).nfcSettingsIos}",
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          actions: [
            if (!isNotSupported)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).nfcOpenSettings,
                    style: const TextStyle(color: Colors.grey)),
              ),
            if (isNotSupported)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startQRScan(); // Direkt QR-Scanner starten
                },
                child: Text(AppLocalizations.of(context).verifyScanQrCaps,
                    style: const TextStyle(color: cCyan)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: cOrange)),
            ),
          ],
        ),
      );

      setState(() {
        _statusText = isNotSupported
            ? AppLocalizations.of(context).verifyNoNfcDevice
            : AppLocalizations.of(context).nfcDisabledHint;
      });
      return;
    }

    // ── NFC verfügbar → Normal scannen ──
    setState(() => _statusText = AppLocalizations.of(context).verifyWaitingNfc);

    try {
      await NfcManager.instance.startSession(
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        onDiscovered: (NfcTag tag) async {
          // DEBOUNCE (Feldtest): Android meldet denselben Tag beim Auflegen
          // oft mehrfach. Ohne Sperre lief die Verarbeitung zwei- bis
          // dreimal parallel — daher die beobachteten Doppel-/Dreifachscans.
          if (_tagProcessing) return;
          _tagProcessing = true;
          AppLogger.section('NFC-SCAN');
          try {
            final ndef = Ndef.from(tag);
            AppLogger.info('NFC',
                'Tag erkannt · NDEF ${ndef == null ? "NICHT lesbar" : "lesbar"}');
            if (ndef == null) {
              await NfcManager.instance.stopSession();
              AppLogger.warn('NFC',
                  'Tag unterstuetzt kein NDEF — falscher Tag-Typ oder beschaedigt.');
              setState(() => _statusText = AppLocalizations.of(context).verifyErrNoNdef);
              return;
            }

            final ndefMessage = await ndef.read();
            if (ndefMessage == null || ndefMessage.records.isEmpty) {
              // GRUND mitschreiben statt nur "leer": Ein unbeschriebener Tag
              // ist etwas anderes als ein Tag, dessen Inhalt das System schon
              // abgegriffen hat (App-Auswahldialog) oder der zu frueh vom
              // Geraet genommen wurde.
              AppLogger.warn('NFC',
                  'Tag ohne Inhalt — ${ndefMessage == null ? "Lesen lieferte NICHTS zurueck (Tag zu frueh entfernt oder vom System bereits verarbeitet)" : "NDEF vorhanden, aber 0 Datensaetze (Tag unbeschrieben)"}.');
              await NfcManager.instance.stopSession();
              setState(() => _statusText = AppLocalizations.of(context).verifyErrTagEmpty);
              return;
            }
            AppLogger.info('NFC',
                'NDEF gelesen: ${ndefMessage.records.length} Datensatz/-saetze, '
                '${ndefMessage.records.first.payload.length} Byte');

            final payload = ndefMessage.records.first.payload;
            if (payload.isEmpty) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = AppLocalizations.of(context).verifyErrPayloadEmpty);
              return;
            }

            final languageCodeLength = payload.first & 0x3F;
            final textStart = 1 + languageCodeLength;
            if (payload.length <= textStart) {
              await NfcManager.instance.stopSession();
              setState(() => _statusText = AppLocalizations.of(context).verifyErrInvalidFormat);
              return;
            }

            final jsonString = utf8.decode(payload.sublist(textStart));

            try {
              final Map<String, dynamic> tagData = json.decode(jsonString) as Map<String, dynamic>;
              await NfcManager.instance.stopSession();

              // SICHERHEITS-CHECK (Kompakt + Legacy)
              final result = BadgeSecurity.verify(tagData);
              AppLogger.info('NFC',
                  'Signaturpruefung: ${result.isValid ? "gueltig" : "UNGUELTIG"} '
                  '(Version ${result.version})${result.isValid ? "" : " — ${result.message}"}');
              if (!result.isValid) {
                setState(() {
                  _statusText = AppLocalizations.of(context).verifyErrPrefix(result.message);
                  _success = false;
                });
                return;
              }

              // Admin-Info für Anzeige
              if (result.version >= 2 && result.adminNpub.isNotEmpty) {
                tagData['_verified_by'] = NostrService.shortenNpub(result.adminNpub);
              }

              tagData['delivery'] = 'nfc';
              _processFoundTagData(tagData: tagData, verifyResult: result);

            } catch (e, st) {
              AppLogger.error('NFC', 'Tag-Inhalt nicht auswertbar (kein gueltiges JSON?)', e, st);
              await NfcManager.instance.stopSession();
              setState(() => _statusText = AppLocalizations.of(context).verifyErrInvalidTag(e.toString()));
            }
          } catch (e, st) {
            AppLogger.error('NFC', 'Lesefehler beim Tag', e, st);
            await NfcManager.instance.stopSession();
            setState(() => _statusText = AppLocalizations.of(context).verifyErrReadError(e.toString()));
          } finally {
            // Sperre nach kurzer Karenz wieder oeffnen: Die Mehrfach-
            // Meldungen EINES Auflegens verpuffen damit, ein bewusster
            // zweiter Scan (z.B. nach einem Lesefehler) bleibt moeglich.
            Future.delayed(const Duration(milliseconds: 1500),
                () => _tagProcessing = false);
          }
        },
      );
    } catch (e) {
      setState(() => _statusText = AppLocalizations.of(context).verifyErrNfcError(e.toString()));
    }
  }

  // =============================================
  // QR LESEN (Rolling QR)
  // =============================================

  void _startQRScan() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const _QRScannerScreen()),
    );

    if (result != null) {
      // Nonce-Check für Rolling QR
      if (result.containsKey('n') || result.containsKey('qr_nonce')) {
        final nonceResult = RollingQRService.validateNonce(result);
        if (!nonceResult.isValid) {
          setState(() {
            _statusText = AppLocalizations.of(context).verifyErrQrExpired(nonceResult.message);
            _success = false;
          });
          return;
        }
      }

      // Sicherheits-Check
      // WICHTIG: Rolling-QR-Felder (n, ts, d) werden vor dem Signatur-Check
      // entfernt, da sie NACH dem Signieren angehängt werden und sonst
      // den Hash verfälschen würden ("Invalid event").
      final dataToVerify = Map<String, dynamic>.from(result);
      dataToVerify.remove('n');
      dataToVerify.remove('ts');
      dataToVerify.remove('d');
      dataToVerify.remove('qr_nonce');
      dataToVerify.remove('qr_time_step');

      final verifyResult = BadgeSecurity.verify(dataToVerify);
      if (!verifyResult.isValid) {
        setState(() {
          _statusText = AppLocalizations.of(context).verifyErrPrefix(verifyResult.message);
          _success = false;
        });
        return;
      }

      if (verifyResult.version >= 2 && verifyResult.adminNpub.isNotEmpty) {
        result['_verified_by'] = NostrService.shortenNpub(verifyResult.adminNpub);
      }

      if (!result.containsKey('delivery')) result['delivery'] = 'rolling_qr';
      _processFoundTagData(tagData: result, verifyResult: verifyResult);
    }
  }

  // =============================================
  // TAG VERARBEITEN → Badge speichern
  // =============================================

  void _processFoundTagData({
    required Map<String, dynamic> tagData,
    VerifyResult? verifyResult,
  }) async {
    if (!mounted) return;

    // Uebersetzungen EINMAL vorab greifen. Danach folgen Netzabrufe
    // (Blockhoehe, Admin-Pruefung, Badge-Bindung) von mehreren Sekunden;
    // der Bildschirm kann in der Zeit geschlossen worden sein, und der
    // fertige Meldungstext wird ohnehin erst am Ende zusammengesetzt.
    final tr = AppLocalizations.of(context);

    // Kompakt-Format normalisieren
    final normalized = BadgeSecurity.normalize(tagData);

    final String meetupName = normalized['meetup_name'] ?? tr.verifyUnknownMeetup;
    final String meetupCountry = normalized['meetup_country'] ?? '';
    final String meetupId = normalized['meetup_id'] ?? DateTime.now().toString();

    // Block Height
    // Immer aktuelle Blockhöhe von Mempool.space holen (frischer Scan-Zeitstempel)
    int currentBlockHeight = 0;
    try { currentBlockHeight = await MempoolService.getBlockHeight(); } catch (_) {}
    // Einmaliger Retry
    if (currentBlockHeight == 0) {
      try {
        await Future.delayed(const Duration(seconds: 1));
        currentBlockHeight = await MempoolService.getBlockHeight();
      } catch (_) {}
    }
    // Fallback: Blockhöhe aus Tag nehmen wenn Mempool offline
    if (currentBlockHeight == 0) {
      currentBlockHeight = (normalized['block_height'] as int?) ?? 0;
    }

    // Duplikat-Check (ein Badge pro Meetup pro Tag)
    final fullName = meetupCountry.isNotEmpty ? "$meetupName, $meetupCountry" : meetupName;

    // DUPLIKAT-CHECK beim Scannen — gegen den GESPEICHERTEN Bestand, nicht
    // gegen die Liste im Arbeitsspeicher (die kann veraltet sein). Geprueft
    // wird gegen dieselbe Identitaet, die auch beim Speichern gilt:
    // primaer die Event-ID (Meetup + Tag), ersatzweise Name + Kalendertag.
    final storedNow = await MeetupBadge.loadBadges();
    myBadges = storedNow; // Speicheransicht gleich mit auffrischen
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final prospectiveEventId =
        '${meetupName.toLowerCase().replaceAll(' ', '-')}-$todayStr';
    // WICHTIG: Organisator-Marker sind KEINE gesammelten Badges. Sie tragen
    // aber dieselbe meetupEventId wie ein echtes Badge desselben Meetups.
    // Ohne diesen Ausschluss blockiert der eigene, unsignierte Marker das
    // echte, signierte Badge — genau der Fall, wenn zwei Organisatoren sich
    // auf demselben Meetup gegenseitig bestaetigen (Kempten, Aug. 2026).
    final collectible = storedNow.where((b) => !b.isOrganizer);
    final bool alreadyCollected = collectible.any((b) =>
        (b.meetupEventId.isNotEmpty && b.meetupEventId == prospectiveEventId) ||
        (b.meetupName == fullName &&
            b.date.year == DateTime.now().year &&
            b.date.month == DateTime.now().month &&
            b.date.day == DateTime.now().day));
    if (alreadyCollected) {
      AppLogger.diag('Scan',
          'Bereits gesammelt: "$fullName" ($prospectiveEventId) — Scan abgelehnt.');
    }

    // ============================================
// PATCH 02: meetup_verification.dart
// Self-Scan-Prevention
// ============================================
//
// ÄNDERUNG: Verhindert dass ein Admin sich selbst
// ein Badge gibt (Scanner-Pubkey == Signer-Pubkey).
//
// WO EINFÜGEN:
//   In lib/screens/meetup_verification.dart,
//   in der Methode _processFoundTagData(),
//   NACH dem Block "// Duplikat-Check" und
//   VOR dem Block "if (!alreadyCollected) {"
//
// ============================================

// EINFÜGEN nach Zeile:
//   bool alreadyCollected = myBadges.any((b) => ...);
//
// UND VOR Zeile:
//   String msg;
//
// ---- NEUER CODE: ----

    // =============================================
    // SELF-SCAN PREVENTION (Security Audit 2026-03)
    // =============================================
    // Ein Admin darf sich nicht selbst ein Badge geben.
    // Das wäre wie sich selbst eine Urkunde ausstellen.
    // =============================================
    final adminPubkeyForSelfCheck = normalized['admin_pubkey'] as String?
        ?? tagData['p'] as String?
        ?? '';

    if (adminPubkeyForSelfCheck.isNotEmpty) {
      try {
        final myNpub = await NostrService.getNpub();
        final signerNpub = normalized['admin_npub'] as String? ?? '';

        // Vergleich über npub (wenn vorhanden)
        bool isSelfScan = false;
        if (myNpub != null && signerNpub.isNotEmpty && myNpub == signerNpub) {
          isSelfScan = true;
        }

        // Fallback: Vergleich über Hex-Pubkey
        if (!isSelfScan && myNpub != null) {
          try {
            final myPubkeyHex = Nip19.decodePubkey(myNpub);
            if (myPubkeyHex == adminPubkeyForSelfCheck) {
              isSelfScan = true;
            }
          } catch (_) {}
        }

        if (isSelfScan) {
          setState(() {
            _success = false;
            _statusText = "✗ ${tr.verifyCantSelfBadge}${tr.verifyAskScan}";
          });
          return; // ← Abbruch, kein Badge wird gespeichert
        }
      } catch (_) {
        // Fehler bei der Prüfung → Badge trotzdem erlauben
        // (Fail-open: besser ein Badge zu viel als User frustrieren)
      }
    }

// ---- ENDE NEUER CODE ----
//
// Danach geht der bestehende Code normal weiter:
//   String msg;
//   if (!alreadyCollected) { ...

    String msg;

    if (!alreadyCollected) {
      // Signer-Info
      final signerNpub = normalized['admin_npub'] as String? ?? '';
      final delivery = normalized['delivery'] as String? ?? tagData['delivery'] as String? ?? 'nfc';
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);

      // KENNUNG NUR AUS EINEM ECHTEN NAMEN BILDEN.
      //
      // Fehlerbild (August 2026): Traegt ein Tag keinen Meetup-Namen, war
      // `meetupName` ein LEERER String — und weil leer nicht null ist, griff
      // die Ersatzbezeichnung nicht. Die Kennung wurde dann zu "-2026-02-25":
      // nicht leer, also durch alle Filter, und fuer JEDEN auf der Welt
      // gleich, der an dem Tag einen namenlosen Tag scannte. Im
      // Vertrauensnetz erschienen dadurch wildfremde Leute als "direkt
      // getroffen" — etwa jemand aus Koblenz bei einem Aschaffenburger.
      //
      // Ohne belastbaren Namen gibt es deshalb GAR KEINE Kennung. Das Badge
      // bleibt gueltig, es wird nur keine Anwesenheit veroeffentlicht —
      // besser keine Verknuepfung als eine falsche.
      final nameSlug = meetupName.trim().toLowerCase().replaceAll(' ', '-');
      final unknownSlug = tr
          .verifyUnknownMeetup
          .trim()
          .toLowerCase()
          .replaceAll(' ', '-');
      final usableName = nameSlug.isNotEmpty &&
          nameSlug != unknownSlug &&
          nameSlug.replaceAll('-', '').isNotEmpty;
      final meetupEventId = usableName ? '$nameSlug-$dateStr' : '';
      if (!usableName) {
        AppLogger.warn('Scan',
            'Tag ohne verwertbaren Meetup-Namen — keine Kennung vergeben, '
            'Anwesenheit wird nicht veroeffentlicht.');
      }

      // Kryptographischen Beweis extrahieren
      final sig = normalized['sig'] as String? ?? tagData['s'] as String? ?? '';
      final sigId = normalized['sig_id'] as String? ?? '';
      final adminPubkey = normalized['admin_pubkey'] as String? ?? tagData['p'] as String? ?? '';
      final sigVersion = sig.length == 128 ? 2 : (sig.isNotEmpty ? 1 : 0);

      // =============================================
      // ADMIN-REGISTRY CHECK — Ist der Signer bekannt?
      // =============================================
      bool isKnownAdmin = false;
      String adminCheckInfo = '';

      // Event-Badge? Dann steht die Berechtigung nicht in der Registry,
      // sondern im Kalender-Event. Die Adresse dafuer kommt aus dem
      // signierten Payload.
      final String? eventAddress = BadgeSecurity.eventAddressOf(normalized);

      /// Bild des Event-Badges — kommt aus dem Kalender-Event und wandert
      /// gleich mit ins Badge.
      String eventBadgeImage = '';

      if (verifyResult != null && verifyResult.version >= 2 && adminPubkey.isNotEmpty) {
        if (eventAddress != null) {
          final chain = await EventBadgeChainService.verify(
            eventAddress: eventAddress,
            signerPubkey: adminPubkey,
          );
          isKnownAdmin = chain.ok;
          eventBadgeImage = chain.badgeImageUrl;
          adminCheckInfo = switch (chain.status) {
            EventChainStatus.verified => tr.mvEventIssuerOk(
                chain.eventTitle, chain.creatorName ?? tr.verifyVerifiedAdmin),
            EventChainStatus.signerNotListed =>
              tr.mvEventSignerNotListed(chain.eventTitle),
            EventChainStatus.creatorNotAuthorized =>
              tr.mvEventCreatorNotAuthorized(chain.eventTitle),
            EventChainStatus.eventHasNoBadge =>
              tr.mvEventHasNoBadge(chain.eventTitle),
            EventChainStatus.eventNotFound => tr.mvEventNotFound,
          };
        } else {
          try {
            final adminResult = await AdminRegistry.checkAdminByPubkey(adminPubkey);
            isKnownAdmin = adminResult.isAdmin;
            if (isKnownAdmin) {
              final adminName = adminResult.name ?? adminResult.meetup ?? tr.verifyVerifiedAdmin;
              adminCheckInfo = tr.mvKnownOrganizer(adminName);
            } else if (adminResult.source == 'unavailable') {
              // Die Registry war nicht erreichbar. Das ist eine Aussage ueber
              // das NETZ, nicht ueber die Person — und muss anders klingen
              // als ein Fremder.
              adminCheckInfo = tr.mvAdminCheckFailed;
            } else {
              // ZWEITE Quelle: die Leader-Liste des Portals.
              //
              // Geprueft wird gegen die npubs GENAU DIESES Meetups. Eine
              // flache Pruefung ueber alle waere ein Scheunentor: Wer im
              // Portal ein Meetup anlegt, wird dessen Leader, und anlegen
              // darf jeder. Ueber alle geprueft koennte sich also jeder
              // selbst den Haken holen und danach Badges fuer FREMDE Meetups
              // ausgeben.
              final ownMeetup = MeetupService.resolveFavorite(meetupName) ??
                  MeetupService.byName(meetupName);
              if (ownMeetup != null) {
                final id = int.tryParse(ownMeetup.id);
                if (id != null) {
                  // Das Portal fuehrt npubs, der Scanner hat hex.
                  String signerNpub = '';
                  try {
                    signerNpub = NostrService.hexToNpub(adminPubkey);
                  } catch (_) {}

                  final leads = signerNpub.isEmpty
                      ? null
                      : await PortalLeaderService.isLeaderOf(id, signerNpub);
                  if (leads == true) {
                    isKnownAdmin = true;
                    adminCheckInfo = tr.mvPortalOrganizer(
                        ownMeetup.name.isNotEmpty
                            ? ownMeetup.name
                            : ownMeetup.city);
                  } else if (leads == null) {
                    // Keine Auskunft — nicht dasselbe wie ein Nein.
                    adminCheckInfo = tr.mvAdminCheckFailed;
                  }
                }
              }

              if (adminCheckInfo.isEmpty && !isKnownAdmin) {
              // DRITTE Quelle: das nostr-Feld am Meetup.
              //
              // Nur noch Rueckfall. Ben hat ausdruecklich darauf
              // hingewiesen, dass es die schwaechere Quelle ist: Es ist nur
              // gefuellt, wenn sich jemand per Nostr angemeldet hat — frueher
              // lief die Anmeldung ueber Lightning, daher die vielen Luecken.
              //
              // Die Registry kennt in der Anfangsphase nur die Liste des
              // Super-Admins. Wer sein Meetup im Portal betreut, steht dort
              // aber mit seinem Schluessel — und ist damit genauso belegt
              // wie ein Eintrag in der Registry, nur ueber einen anderen Weg.
              // Ohne diese Pruefung meldete die App echte Organisatoren als
              // Unbekannte, was gleich mehrere Tester zu Recht irritiert hat.
              final portalMeetup =
                  await MeetupService.organizerMeetupFor(adminPubkey);
              if (portalMeetup != null) {
                isKnownAdmin = true;
                adminCheckInfo = tr.mvPortalOrganizer(
                    portalMeetup.name.isNotEmpty
                        ? portalMeetup.name
                        : portalMeetup.city);
              } else {
                adminCheckInfo = tr.mvUnknownSigner;
              }
              }
            }
          } catch (e) {
            // Offline: Cache-Miss → Warnung anzeigen
            adminCheckInfo = tr.mvAdminCheckFailed;
          }
        }
      } else if (verifyResult != null && verifyResult.version == 1) {
        // Legacy v1: Shared Secret, per Definition nicht vertrauenswürdig
        adminCheckInfo = tr.mvLegacyBadge;
      }

      // Originalen signierten Content für Re-Verifikation
      final contentData = Map<String, dynamic>.from(tagData);
      contentData.remove('_verified_by');
      final sigContent = jsonEncode(contentData);

      // =============================================
      // NEU: CLAIM-SIGNATUR ERSTELLEN (Badge-Binding)
      // Bindet das Badge kryptographisch an den Sammler.
      // Passiert automatisch im Hintergrund.
      // =============================================
      String claimSig = '';
      String claimEventId = '';
      String claimPubkey = '';
      int claimTimestamp = 0;
      String claimInfo = '';

      if (sig.isNotEmpty && sigVersion >= 2) {
        final claimResult = await BadgeClaimService.createClaim(
          orgSig: sig,
          orgEventId: sigId,
          orgPubkey: adminPubkey,
          blockHeight: currentBlockHeight,
        );

        if (claimResult.success) {
          claimSig = claimResult.claimSig;
          claimEventId = claimResult.claimEventId;
          claimPubkey = claimResult.claimPubkey;
          claimTimestamp = claimResult.claimTimestamp;
          claimInfo = tr.mvBadgeBound;
        } else {
          claimInfo = '⚠ Binding: ${claimResult.message}';
        }
      }

      // Badge vorbereiten — noch NICHT speichern (erst nach Bestätigung)
      // Organisator-Standort aus den unsignierten QR-Feldern la/lo lesen
      // (Referenz für den 5km-Check beim Bestätigen).
      _pendingOrgLat = (tagData['la'] as num?)?.toDouble()
          ?? (normalized['la'] as num?)?.toDouble() ?? 0;
      _pendingOrgLng = (tagData['lo'] as num?)?.toDouble()
          ?? (normalized['lo'] as num?)?.toDouble() ?? 0;

      _pendingBadge = MeetupBadge(
        id: meetupId,
        meetupName: fullName,
        date: DateTime.now(),
        iconPath: "assets/badge_icon.png",
        blockHeight: currentBlockHeight,
        signerNpub: signerNpub,
        meetupEventId: meetupEventId,
        delivery: delivery,
        sig: sig,
        sigId: sigId,
        adminPubkey: adminPubkey,
        sigVersion: sigVersion,
        sigContent: sigContent,
        claimSig: claimSig,
        claimEventId: claimEventId,
        claimPubkey: claimPubkey,
        claimTimestamp: claimTimestamp,
        isRetroactive: false,
        // Event-Badge: wirkt im Trust Score und im Vertrauensnetzwerk
        // anders als ein Meetup-Badge.
        isEvent: eventAddress != null,
        coverUrl: eventBadgeImage,
      );

      msg = "${tr.verifyBadgeFound}\n\n";
      msg += "${tr.verifyMsgLocation(fullName)}\n";
      if (currentBlockHeight > 0) msg += "${tr.verifyMsgBlock(currentBlockHeight)}\n";
      if (tagData['_verified_by'] != null) msg += "${tr.verifyMsgSignedBy(tagData['_verified_by'].toString())}\n";
      if (sigVersion == 2) msg += "${tr.verifyMsgProof}\n";
      if (claimInfo.isNotEmpty) msg += claimInfo;

      if (adminCheckInfo.isNotEmpty) {
        msg += "\n\n$adminCheckInfo";
      }

      final expiryStr = BadgeSecurity.expiryInfo(tagData);
      if (expiryStr != tr.verifyNoExpiry) msg += "\n\n${tr.verifyMsgTagExpiry(expiryStr)}";

      if (!isKnownAdmin && verifyResult != null && verifyResult.version >= 2 && adminPubkey.isNotEmpty) {
        _isUnknownSigner = true;
      }

    } else {
      msg = tr.verifyAlreadyToday(fullName);
      _pendingBadge = null;
      _pendingOrgLat = 0;
      _pendingOrgLng = 0;
    }

    setState(() {
      _success = true;
      _statusText = msg;
    });
    // Kein Auto-Dismiss — Nutzer muss aktiv bestätigen
  }

  // Badge in Wallet speichern (nach Bestätigung)

  /// Sucht die Koordinaten des Meetups, zu dem DIESES Badge gehoert.
  ///
  /// Hintergrund (Feldtest Juli 2026): Der Umkreis-Schutz griff faktisch nie,
  /// weil NFC-Tags keine Koordinaten tragen und der zentrale Scan-Knopf ein
  /// Platzhalter-Meetup ohne Koordinaten uebergibt. Statt aufzugeben, leiten
  /// wir die Referenz jetzt aus dem Badge selbst ab: sein Meetup-Name wird
  /// gegen die Portal-Meetup-Liste aufgeloest.
  ///
  /// Der Badge-Name hat die Form "Stadt, LAND" — fuer den Abgleich zaehlt
  /// nur der Teil vor dem Komma.
  Future<Meetup?> _lookupMeetupForBadge(String badgeMeetupName) async {
    final city = badgeMeetupName.split(',').first.trim().toLowerCase();
    if (city.isEmpty) return null;

    List<Meetup> list = const [];
    try {
      list = await MeetupService.fetchMeetups();
    } catch (_) {
      // Offline/Portal-Stoerung -> eingebaute Liste als Rueckfallebene
    }
    if (list.isEmpty) list = allMeetups;

    for (final m in list) {
      if (m.lat == 0 && m.lng == 0) continue; // ohne Koordinaten nutzlos
      final c = m.city.trim().toLowerCase();
      if (c == city || c.contains(city) || city.contains(c)) return m;
    }
    return null;
  }


  Future<void> _confirmSaveBadge() async {
    if (_pendingBadge == null) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    var badge = _pendingBadge!;
    AppLogger.diag('Scan',
        'Claim gestartet: "${badge.meetupName}" · Zustellung=${badge.delivery} '
        '· sigVersion=${badge.sigVersion} · Key=${MeetupBadge.identityKey(badge)}');

    // ---- GPS-PFLICHT beim Sammeln: Standort als Präsenz-Nachweis ----
    // Lade-Anzeige
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: cOrange)),
    );
    final loc = await MeetupLocationService.resolveLocation();
    if (mounted) Navigator.pop(context);

    // WEICHE PRUEFUNG (Feldtest Juli 2026):
    // Frueher galt "kein Standort = kein Badge". Das hat ehrliche Teilnehmer
    // ausgesperrt, deren Geraet keine Netzwerkortung hat (z.B. GrapheneOS
    // ohne Google Play Services) — drinnen kommt dort kein Satellitenfix
    // zustande. Wer betruegen will, faelscht den Standort ohnehin per
    // Mock-Location; eine Huerde, die nur die Ehrlichen trifft, ist keine.
    //
    // Neue Regel — der Unterschied ist entscheidend:
    //   Standort NICHT messbar      -> Badge, aber als ungeprueft markiert
    //   Standort messbar UND zu weit -> Badge verweigert (Gegenbeweis!)
    // Fehlender Beweis ist etwas anderes als Beweis des Gegenteils.
    var presenceVerified = false;

    if (loc.status != GpsStatus.ok) {
      AppLogger.warn('Scan',
          'Standort nicht ermittelbar (${loc.status.name}) — Badge wird als '
          'UNGEPRUEFTE Praesenz vergeben.');
    } else {
      AppLogger.diag('Scan', 'Standort ermittelt (Status ok).');
    }

    // Radius-Check: Teilnehmer muss nah am ERFASSTEN ORGANISATOR-STANDORT sein.
    // Primäre Referenz: Organisator-Koordinaten aus dem QR (la/lo) — das ist
    // der echte Veranstaltungsort. Fallback: Portal-Koordinaten DIESES Meetups
    // (z.B. bei NFC-Tags ohne Standort). Ist für DIESES Meetup nichts bekannt,
    // entfällt der Check bewusst — wir erfinden KEINE Referenz aus einem
    // fremden, nur zufällig nahen Meetup (das würde echte Teilnehmer fälschlich
    // ablehnen oder den Check sinnlos machen).
    double refLat = _pendingOrgLat;
    double refLng = _pendingOrgLng;
    // HERKUNFT der Referenz ist entscheidend fuer die Strenge der Pruefung:
    //   gemessen  = Organisator stand beim Erstellen VOR ORT (QR-Felder la/lo)
    //   abgeleitet = aus der Portal-Meetupliste erschlossen
    // Eine abgeleitete Referenz kann schlicht falsch sein — etwa wenn ein
    // Organisator ohne Ortung versehentlich das falsche Meetup aus der Liste
    // waehlt (Aschaffenburg vs. Muenchen). Darauf darf NIEMAND ausgesperrt
    // werden, deshalb wird bei abgeleiteter Referenz nie hart abgelehnt.
    var refMeasured = !(refLat == 0 && refLng == 0);
    if (refLat == 0 && refLng == 0) {
      refLat = widget.meetup.lat;
      refLng = widget.meetup.lng;
    }
    // STUFE 3 (Feldtest-Fix): Immer noch keine Referenz? Dann das Meetup
    // ueber den Namen IM BADGE aufloesen. Das ist der Normalfall beim Scan
    // ueber den zentralen Scan-Knopf, der ein Platzhalter-Meetup mitgibt.
    if (refLat == 0 && refLng == 0) {
      final resolved = await _lookupMeetupForBadge(badge.meetupName);
      if (resolved != null) {
        refLat = resolved.lat;
        refLng = resolved.lng;
        AppLogger.diag('Scan',
            'Referenzkoordinaten aus Meetup-Liste aufgeloest: "${resolved.city}".');
      }
    }
    if (loc.status == GpsStatus.ok && !(refLat == 0 && refLng == 0)) {
      final dist = MeetupLocationService.distanceKm(loc.lat, loc.lng, refLat, refLng);
      // RADIUS RICHTET SICH NACH DER GENAUIGKEIT DER REFERENZ:
      //   gemessen (Organisator stand vor Ort) -> 5 km, streng
      //   abgeleitet (Portal-Koordinate)       -> 50 km, weil Regional-
      //     Meetups wie "Westerwald" oder "Vulkaneifel" nur EINEN Punkt fuer
      //     ein grosses Gebiet haben. Ein Fehlgriff in der Liste (~300 km)
      //     wird davon trotzdem sicher erfasst.
      final allowed = refMeasured
          ? MeetupLocationService.participantRadiusKm
          : MeetupLocationService.derivedRadiusKm;
      AppLogger.diag('Scan',
          'Umkreis-Pruefung: ${dist.toStringAsFixed(1)} km '
          '(erlaubt $allowed km, Referenz ${refMeasured ? "gemessen" : "abgeleitet"}).');
      if (dist > allowed) {
        // ABLEHNUNG IN BEIDEN FAELLEN — und das ist Absicht: Die Meldung
        // "zu weit entfernt" ist der Rueckkanal zum Organisator. Wenn beim
        // Meetup mehrere Leute dieselbe Meldung sehen, merkt er, dass etwas
        // mit dem Badge nicht stimmt, und kann seine Auswahl korrigieren.
        // Ein stillschweigend abgewertetes Badge wuerde niemandem auffallen.
        AppLogger.warn('Scan',
            'Zu weit entfernt: ${dist.toStringAsFixed(1)} km > $allowed km '
            '(Referenz ${refMeasured ? "gemessen" : "abgeleitet aus \"${badge.meetupName}\""}) '
            '— Badge abgelehnt.${refMeasured ? "" : " Moeglicherweise wurde beim Erstellen das falsche Meetup gewaehlt."}');
        if (mounted) _showTooFar(dist);
        return;
      }
      presenceVerified = true; // im zulaessigen Umkreis
      if (!refMeasured) {
        AppLogger.diag('Scan',
            'Referenz abgeleitet, Abstand plausibel — Praesenz bestaetigt.');
      }
    } else {
      // RESTFALL: Auch ueber den Badge-Namen war nichts aufloesbar (Meetup
      // im Portal ohne Koordinaten oder unbekannter Name). Bewusste
      // Entscheidung: Badge wird vergeben, statt vor Ort ein ganzes Meetup
      // auszusperren — aber die fehlende Pruefung wird klar protokolliert.
      AppLogger.warn('Scan',
          'Umkreis-Pruefung UEBERSPRUNGEN — keine Referenzkoordinaten fuer '
          '"${badge.meetupName}" (Tag: $_pendingOrgLat/$_pendingOrgLng, '
          'Meetup: ${widget.meetup.lat}/${widget.meetup.lng}). '
          'Badge gilt als UNGEPRUEFTE Praesenz.');
    }

    // Koordinaten ins Badge schreiben (Präsenz-Nachweis + Weltkarte)
    badge = badge.copyWith(
      lat: loc.lat,
      lng: loc.lng,
      presenceVerified: presenceVerified,
    );
    AppLogger.diag('Scan',
        'Praesenz ${presenceVerified ? "GEPRUEFT" : "UNGEPRUEFT"} — Badge wird gespeichert.');
    if (!presenceVerified && mounted) {
      // Kein Blocker mehr, aber der Teilnehmer soll wissen, woran er ist.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).badgeUnverifiedInfo),
        backgroundColor: cSurface,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ));
    }

    // ============================================
    // DUPLIKAT-SCHUTZ (Feldtest Juli 2026)
    // ============================================
    // Der Duplikat-Check beim SCANNEN schuetzt nur den Scan-Vorgang selbst.
    // Wer den Knopf "Zur Wallet hinzufuegen" erneut drueckt, lief bisher
    // daran vorbei (_pendingBadge ist ja noch gesetzt) — dadurch landete
    // derselbe Badge bis zu dreimal in der Wallet und hat den Trust Score
    // vervielfacht. Deshalb hier, unmittelbar vor dem Speichern, die
    // verbindliche Pruefung gegen den TATSAECHLICHEN Speicherstand
    // (nicht nur gegen die evtl. veraltete Liste im Speicher).
    final stored = await MeetupBadge.loadBadges();
    final key = MeetupBadge.identityKey(badge);
    // Organisator-Marker vom Vergleich ausnehmen (siehe oben): Ein eigener
    // Marker darf das echte Badge desselben Meetups nicht verdraengen.
    if (stored.where((b) => !b.isOrganizer)
        .any((b) => MeetupBadge.identityKey(b) == key)) {
      AppLogger.warn('Scan', 'Duplikat abgewiesen ($key) — Badge bereits in der Wallet.');
      _pendingBadge = null; // verhindert weitere Versuche mit demselben Badge
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).verifyBadgeDuplicate),
            backgroundColor: cOrange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BadgeWalletScreen()),
        );
      }
      return;
    }

    stored.add(badge);
    await MeetupBadge.saveBadges(stored);
    myBadges = stored; // globale Liste synchron halten
    _pendingBadge = null; // Badge ist verbucht — kein zweites Hinzufuegen
    AppLogger.diag('Scan', 'Badge gespeichert ($key). Wallet: ${stored.length} Badge(s).');
    ReputationPublisher.publishInBackground(stored);

    // Klares Erfolgs-Feedback (unabhängig vom Einstiegspunkt)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).verifyBadgeSaved),
          backgroundColor: cGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Opt-in fürs Co-Attendance-Netzwerk — nur bei echten, signierten Badges
    if (badge.isNostrSigned && badge.meetupEventId.isNotEmpty && mounted) {
      await _askCoAttendanceOptIn(badge);
    }

    // Direkt in die Wallet wechseln. Wir verlassen uns NICHT auf den
    // Aufrufer (der je nach Einstiegspunkt unterschiedlich reagierte) —
    // dieser Screen ersetzt sich selbst durch die Wallet. So landet man
    // IMMER zuverlässig dort, unabhängig vom Scan-Einstieg.
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BadgeWalletScreen()),
      );
    }
  }


  void _showTooFar(double distKm) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.wrong_location_rounded, color: cRed, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(t.gpsTooFar, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Text(
          t.gpsTooFarSub(distKm.toStringAsFixed(1), MeetupLocationService.participantRadiusKm.toStringAsFixed(0)),
          style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.4)),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: const TextStyle(color: cOrange)))],
      ),
    );
  }

  /// Fragt den Nutzer, ob die Teilnahme zum Vertrauensnetzwerk beitragen soll.
  /// Standard = Opt-in (muss aktiv zustimmen).
  Future<void> _askCoAttendanceOptIn(MeetupBadge badge) async {
    final t = AppLocalizations.of(context);
    final agree = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.hub_rounded, color: cCyan, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(t.caOptInTitle,
                style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.caOptInBody,
                style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cOrange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cOrange.withValues(alpha: 0.25), width: 0.5),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: cOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(t.caOptInPrivacy,
                      style: const TextStyle(color: cOrange, fontSize: 11, height: 1.4)),
                ),
              ]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.caOptInNo, style: const TextStyle(color: cTextSecondary)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: cCyan, foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.hub_rounded, size: 16),
            label: Text(t.caOptInYes),
          ),
        ],
      ),
    );

    if (agree == true) {
      final count = await CoAttendanceService.publishAttendance(badge);
      if (mounted && count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).caPublished),
            backgroundColor: cGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // =============================================
  // _simulateScan() ENTFERNT — Sicherheitslücke geschlossen
  // =============================================

  // =============================================
  // UI
  // =============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(AppLocalizations.of(context).verifyScanBadge)),
      body: Center(
        child: _success
            ? _buildConfirmationView()
            : _buildScannerView(),
      ),
    );
  }

  // =============================================
  // BESTÄTIGUNGS-ANSICHT
  // =============================================
  Widget _buildConfirmationView() {
    final bool isAlreadyCollected = _pendingBadge == null;
    final Color accentColor = isAlreadyCollected
        ? cTextSecondary
        : _isUnknownSigner ? cOrange : cGreen;
    final IconData icon = isAlreadyCollected
        ? Icons.inventory_2_rounded
        : _isUnknownSigner ? Icons.warning_amber_rounded : Icons.military_tech_rounded;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
      child: Column(
        children: [
          // ── Badge-Icon ──
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.1),
              border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.5),
            ),
            child: Icon(icon, color: accentColor, size: 36),
          ),
          const SizedBox(height: 20),

          // ── Titel ──
          Text(
            isAlreadyCollected ? AppLocalizations.of(context).verifyAlreadyCollected : AppLocalizations.of(context).verifyBadgeFound,
            style: TextStyle(
              color: accentColor, fontSize: 11,
              fontWeight: FontWeight.w800, letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // ── Info-Karte ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cCard,
              borderRadius: BorderRadius.circular(kTileRadius),
              border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Text(
              _statusText ?? AppLocalizations.of(context).verifyReadyToScan,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: cText, fontWeight: FontWeight.w500,
                fontSize: 13, height: 1.75, letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Bereits gesammelt: direkt zur Wallet, damit man sein
          //    vorhandenes Badge sehen kann (statt in der Sackgasse zu enden).
          if (isAlreadyCollected) ...[
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const BadgeWalletScreen())),
                icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.black, size: 18),
                label: Text(
                  AppLocalizations.of(context).verifyOpenWallet,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800,
                      fontSize: 13, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kTileRadius)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Bestätigen-Button (nur bei neuem Badge) ──
          if (!isAlreadyCollected) ...[
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmSaveBadge,
                icon: const Icon(Icons.add_rounded, color: Colors.black),
                label: Text(
                  AppLocalizations.of(context).verifyAddToWallet,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800,
                      fontSize: 13, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cOrange,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kTileRadius)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Schließen/Abbrechen ──
          SizedBox(
            width: double.infinity, height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: cTextSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kTileRadius),
                  side: const BorderSide(color: cTileBorder, width: 0.5),
                ),
              ),
              child: Text(
                isAlreadyCollected ? AppLocalizations.of(context).verifyClose : AppLocalizations.of(context).dialogCancel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================
  // SCANNER-ANSICHT
  // =============================================
  Widget _buildScannerView() {
    return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _animation,
                    child: Container(
                      width: 200, height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cOrange, width: 4),
                        boxShadow: [BoxShadow(color: cOrange.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                      ),
                      // Symbol folgt der Funktion: Ohne NFC wird hier nur
                      // noch der QR gescannt, und ein NFC-Zeichen liesse
                      // Leute nach einem Tag suchen, den es nicht gibt.
                      child: Center(
                          child: Icon(
                              kNfcEnabled
                                  ? Icons.nfc
                                  : Icons.qr_code_scanner_rounded,
                              size: 80,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(AppLocalizations.of(context).verifyScanBadge,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(AppLocalizations.of(context).verifyScanInstruction,
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
                  ),
                  const SizedBox(height: 40),

                  // NFC Button — abgeschaltet, siehe lib/features.dart
                  if (kNfcEnabled) ...[
                    SizedBox(
                      width: 250, height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _startNfcRead,
                        icon: const Icon(Icons.nfc, color: Colors.white),
                        label: Text(AppLocalizations.of(context).verifyScanNfc, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // QR Button — ohne NFC der einzige Weg, deshalb gefuellt
                  // statt umrandet.
                  SizedBox(
                    width: 250, height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _startQRScan,
                      icon: const Icon(Icons.qr_code_scanner, color: cCyan),
                      label: Text(AppLocalizations.of(context).verifyScanQrCaps, style: const TextStyle(color: cCyan, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: cCyan, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(_statusText ?? AppLocalizations.of(context).verifyReadyToScan, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ],
              );
  }
}

// ============================================
// QR SCANNER HELPER SCREEN
// ============================================
class _QRScannerScreen extends StatefulWidget {
  const _QRScannerScreen();

  @override
  State<_QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<_QRScannerScreen> {
  bool _isScanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    for (final barcode in capture.barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        try {
          final data = json.decode(code) as Map<String, dynamic>;
          // Ist es ein Meetup-Badge-Tag? (Kompakt oder Legacy)
          if (data.containsKey('t') || data.containsKey('type')) {
            setState(() => _isScanned = true);
            Navigator.pop(context, data);
            return;
          }
        } catch (_) {
          // Kein JSON — ignorieren
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: Text(AppLocalizations.of(context).verifyScanQr)),
      body: Stack(children: [
        MobileScanner(onDetect: _onDetect),
        // Rahmen mit Suchlinie: gibt die Zielgroesse vor und zeigt,
        // dass die App tatsaechlich sucht.
        const ScannerOverlay(),
        Positioned(
          bottom: 60, left: 40, right: 40,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(12)),
            child: Text(AppLocalizations.of(context).verifyScanQrInstruction,
              style: const TextStyle(color: Colors.white, fontSize: 14), textAlign: TextAlign.center),
          ),
        ),
      ]),
    );
  }
}


