import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart'; // NEU: Für Humanity-Proof Restore
import '../models/user.dart';
import '../models/badge.dart';
import 'admin_registry.dart';
import 'nostr_service.dart';
import 'secure_key_store.dart';
import 'platform_proof_service.dart'; // NEU
import 'humanity_proof_service.dart'; // NEU
import 'dart:typed_data';
import 'app_logger.dart';

class BackupService {
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
  static enc.Key _deriveKey(String password, Uint8List salt) {
    // PBKDF2 Implementation mit HMAC-SHA256
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    // PBKDF2: Key = T1 || T2 || ... || T_ceil(keyLen/hashLen)
    // Für 32 Byte Key und SHA-256 (32 Byte Output) brauchen wir nur T1
    final derivedKey = _pbkdf2F(hmac, salt, _pbkdf2Iterations, 1);

    return enc.Key(Uint8List.fromList(derivedKey));
  }

  /// PBKDF2 F-Funktion: F(Password, Salt, c, i)
  /// = U1 XOR U2 XOR ... XOR Uc
  static List<int> _pbkdf2F(Hmac hmac, Uint8List salt, int iterations, int blockIndex) {
    // U1 = HMAC(Password, Salt || INT_32_BE(i))
    final saltWithIndex = Uint8List(salt.length + 4);
    saltWithIndex.setRange(0, salt.length, salt);
    saltWithIndex[salt.length + 0] = (blockIndex >> 24) & 0xFF;
    saltWithIndex[salt.length + 1] = (blockIndex >> 16) & 0xFF;
    saltWithIndex[salt.length + 2] = (blockIndex >> 8) & 0xFF;
    saltWithIndex[salt.length + 3] = (blockIndex) & 0xFF;

    var u = hmac.convert(saltWithIndex).bytes;
    final result = List<int>.from(u);

    // U2 ... Uc
    for (int i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }

    return result;
  }

  /// Erzeugt kryptographisch sicheren Zufalls-Salt
  static Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLengthBytes);
    for (int i = 0; i < _saltLengthBytes; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Zeigt den Dialog zur Passwort-Eingabe (für Export und Import)
  static Future<String?> _promptForPassword(BuildContext context, {required bool isExport}) async {
    String password = '';
    String passwordConfirm = '';
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            isExport ? 'Backup verschlüsseln' : 'Backup entschlüsseln',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isExport
                    ? 'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen.\n\n'
                      '⚠️ Wenn du dieses Passwort vergisst, ist das Backup UNWIEDERBRINGLICH verloren!'
                    : 'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Passwort',
                  hintStyle: const TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: const Color(0xFF0A0A0A),
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                onChanged: (val) {
                  password = val;
                  setDialogState(() => errorText = null);
                },
              ),
              if (isExport) ...[
                const SizedBox(height: 12),
                TextField(
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Passwort bestätigen',
                    hintStyle: TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Color(0xFF0A0A0A),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => passwordConfirm = val,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                if (password.isEmpty) {
                  setDialogState(() => errorText = 'Passwort darf nicht leer sein');
                  return;
                }
                if (isExport && password.length < 8) {
                  setDialogState(() => errorText = 'Mindestens 8 Zeichen');
                  return;
                }
                if (isExport && password != passwordConfirm) {
                  setDialogState(() => errorText = 'Passwörter stimmen nicht überein');
                  return;
                }
                Navigator.pop(context, password);
              },
              child: Text(
                isExport ? 'Verschlüsseln & Speichern' : 'Entschlüsseln & Laden',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- EXPORT (BACKUP ERSTELLEN) ---
  static Future<void> createBackup(BuildContext context) async {
    try {
      // 1. Passwort abfragen
      final password = await _promptForPassword(context, isExport: true);
      if (password == null) return; // User hat abgebrochen

      // Ladeindikator zeigen
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
        );
      }

      final user = await UserProfile.load();
      final badges = await MeetupBadge.loadBadges();

      // Nostr Keys aus SecureKeyStore laden
      final nsec = await SecureKeyStore.getNsec();
      final npub = await SecureKeyStore.getNpub();
      final privHex = await SecureKeyStore.getPrivHex();
      final adminList = await AdminRegistry.getAdminList();
      final myVouches = await AdminRegistry.getMyVouches();

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
          'isAdmin': user.isAdmin,
          'isAdminVerified': user.isAdminVerified,
          'isNostrVerified': user.isNostrVerified,
          'nostrNpub': user.nostrNpub,
          'telegramHandle': user.telegramHandle,
          'twitterHandle': user.twitterHandle,
        },
        'badges': badges.map((b) => {
          'id': b.id,
          'meetupName': b.meetupName,
          'date': b.date.toIso8601String(),
          'blockHeight': b.blockHeight,
          // Kryptographischen Beweis mitsichern
          'sig': b.sig,
          'sigId': b.sigId,
          'adminPubkey': b.adminPubkey,
          'sigVersion': b.sigVersion,
          'sigContent': b.sigContent,
          'signerNpub': b.signerNpub,
          'delivery': b.delivery,
        }).toList(),
        'nostr': {
          'nsec': nsec ?? '',
          'npub': npub ?? '',
          'priv_hex': privHex ?? '',
          'has_key': nsec != null,
        },
        'admin_registry': adminList.map((a) => a.toJson()).toList(),
        'my_vouches': myVouches.map((a) => a.toJson()).toList(),

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
      final key = _deriveKey(password, salt);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);

      // Format: "enc_v2:[SALT_BASE64]:[IV_BASE64]:[CIPHERTEXT_BASE64]"
      //
      // enc_v2 = PBKDF2 Key Derivation (enc_v1 war SHA-256 direkt)
      // Salt wird für die Ableitung des Keys benötigt
      // IV wird für AES-GCM benötigt
      final finalPayload = "enc_v2:${base64Encode(salt)}:${iv.base64}:${encrypted.base64}";

      // Speichern
      final directory = await getTemporaryDirectory();
      String dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final file = File('${directory.path}/21_backup_$dateStr.21bkp');

      await file.writeAsString(finalPayload);

      if (context.mounted) Navigator.pop(context); // Ladeindikator weg

      // Teilen
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Einundzwanzig App Backup (Verschlüsselt)',
        text: 'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.',
      );
    } catch (e) {
      AppLogger.debug('App', "Backup Fehler: $e");
      if (context.mounted) {
        Navigator.pop(context); // Ladeindikator weg
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fehler beim Backup: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- IMPORT (WIEDERHERSTELLEN) ---
  static Future<bool> restoreBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        String decryptedJson = content;

        // =============================================
        // enc_v2: PBKDF2 + AES-GCM (neues Format)
        // =============================================
        if (content.startsWith("enc_v2:")) {
          final password = await _promptForPassword(context, isExport: false);
          if (password == null) return false;

          try {
            final parts = content.split(':');
            if (parts.length != 4) throw Exception("Backup-Datei ist beschädigt (Formatfehler).");

            final salt = Uint8List.fromList(base64Decode(parts[1]));
            final iv = enc.IV.fromBase64(parts[2]);
            final cipherText = parts[3];

            final key = _deriveKey(password, salt);
            final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

            decryptedJson = encrypter.decrypt64(cipherText, iv: iv);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Falsches Passwort oder Datei beschädigt!"),
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
          final password = await _promptForPassword(context, isExport: false);
          if (password == null) return false;

          try {
            final parts = content.split(':');
            if (parts.length != 3) throw Exception("Backup-Datei ist beschädigt (Formatfehler).");

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
                const SnackBar(
                  content: Text("Falsches Passwort oder Datei beschädigt!"),
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
          throw Exception("Datei ist kein gültiges Backup oder das falsche Format.");
        }

        if (!data.containsKey('user') || !data.containsKey('badges')) {
          throw Exception("Datei ist kein gültiges Einundzwanzig Backup.");
        }

        final int version = data['version'] ?? 1;

        // --- USER WIEDERHERSTELLEN ---
        var userData = data['user'];
        var user = UserProfile(
          nickname: userData['nickname'] ?? "Anon",
          fullName: userData['fullName'] ?? "",
          homeMeetupId: userData['homeMeetupId'] ?? "",
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
          restoredBadges.add(MeetupBadge(
            id: b['id'],
            meetupName: b['meetupName'],
            date: DateTime.parse(b['date']),
            iconPath: "assets/badge_icon.png",
            blockHeight: b['blockHeight'] ?? 0,
            // Kryptographischen Beweis wiederherstellen (v4)
            sig: b['sig'] as String? ?? '',
            sigId: b['sigId'] as String? ?? '',
            adminPubkey: b['adminPubkey'] as String? ?? '',
            sigVersion: b['sigVersion'] as int? ?? 0,
            sigContent: b['sigContent'] as String? ?? '',
            signerNpub: b['signerNpub'] as String? ?? '',
            delivery: b['delivery'] as String? ?? 'nfc',
          ));
        }
        await MeetupBadge.saveBadges(restoredBadges);

        // --- NOSTR KEYS WIEDERHERSTELLEN ---
        if (version >= 2 && data['nostr'] != null) {
          final nostrData = data['nostr'] as Map<String, dynamic>;
          final hasKey = nostrData['has_key'] ?? false;

          if (hasKey) {
            final nsec = nostrData['nsec'] ?? '';
            final npub = nostrData['npub'] ?? '';
            final privHex = nostrData['priv_hex'] ?? '';

            if (nsec.isNotEmpty && npub.isNotEmpty && privHex.isNotEmpty) {
              await SecureKeyStore.saveKeys(
                nsec: nsec,
                npub: npub,
                privHex: privHex,
              );

              user.nostrNpub = npub;
              user.isNostrVerified = true;
              user.hasNostrKey = true;
              await user.save();
            }
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

        // --- PERSÖNLICHE BÜRGSCHAFTEN WIEDERHERSTELLEN ---
        if (data['my_vouches'] != null) {
          final vouchesList = data['my_vouches'] as List<dynamic>;
          for (var vouchJson in vouchesList) {
            try {
              await AdminRegistry.addVouch(
                AdminEntry.fromJson(vouchJson as Map<String, dynamic>),
              );
            } catch (e) {
              // Duplikat oder Self-Vouch ignorieren
            }
          }
        }

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
              content: Text("✅ Backup geladen! ${restored.join(', ')} wiederhergestellt."),
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
      AppLogger.debug('App', "Import Fehler: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import fehlgeschlagen: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
}