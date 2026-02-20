import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc; // Das neue Verschlüsselungspaket
import '../models/user.dart';
import '../models/badge.dart';
import 'admin_registry.dart';
import 'secure_key_store.dart';
import 'dart:typed_data';

class BackupService {
  // --- HILFSFUNKTIONEN FÜR VERSCHLÜSSELUNG ---

  /// Leitet aus dem Nutzerpasswort einen 32-Byte (256 Bit) AES-Schlüssel ab.
  static enc.Key _deriveKey(String password) {
    // SHA-256 erzeugt immer genau 32 Bytes
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Zeigt den Dialog zur Passwort-Eingabe (für Export und Import)
  static Future<String?> _promptForPassword(BuildContext context, {required bool isExport}) async {
    String password = '';
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
                  ? 'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen. Wenn du dieses Passwort vergisst, ist das Backup wertlos!'
                  : 'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Passwort',
                hintStyle: TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Color(0xFF0A0A0A),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => password = val,
            ),
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
              if (password.isNotEmpty) {
                Navigator.pop(context, password);
              }
            },
            child: Text(isExport ? 'Verschlüsseln & Speichern' : 'Entschlüsseln & Laden', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
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

      Map<String, dynamic> backupData = {
        'version': 3, // v3: AES Encrypted
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
        }).toList(),
        'nostr': {
          'nsec': nsec ?? '',
          'npub': npub ?? '',
          'priv_hex': privHex ?? '',
          'has_key': nsec != null,
        },
        'admin_registry': adminList.map((a) => a.toJson()).toList(),
      };

      String jsonString = jsonEncode(backupData);

      // --- VERSCHLÜSSELUNG (AES-GCM) ---
      final key = _deriveKey(password);
      final iv = enc.IV.fromLength(16); // Initialization Vector
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      
      // Wir speichern das IV zusammen mit dem verschlüsselten Base64 String
      // Format: "enc_v1:[IV_BASE64]:[CIPHERTEXT_BASE64]"
      final finalPayload = "enc_v1:${iv.base64}:${encrypted.base64}";

      // Speichern
      final directory = await getTemporaryDirectory();
      String dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final file = File('${directory.path}/21_backup_$dateStr.21bkp'); // Eigene Endung optional, hier zur Unterscheidung

      await file.writeAsString(finalPayload);

      if (context.mounted) Navigator.pop(context); // Ladeindikator weg

      // Teilen
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Einundzwanzig App Backup (Verschlüsselt)',
        text: 'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.',
      );

    } catch (e) {
      print("Backup Fehler: $e");
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
        type: FileType.any, // Erlaubt auch die neue Endung
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        String decryptedJson = content;

        // Prüfen, ob es ein verschlüsseltes Backup (v3) ist
        if (content.startsWith("enc_v1:")) {
          final password = await _promptForPassword(context, isExport: false);
          if (password == null) return false; // Abgebrochen

          try {
            final parts = content.split(':');
            if (parts.length != 3) throw Exception("Backup-Datei ist beschädigt (Formatfehler).");

            final iv = enc.IV.fromBase64(parts[1]);
            final cipherText = parts[2];

            final key = _deriveKey(password);
            final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));

            decryptedJson = encrypter.decrypt64(cipherText, iv: iv);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Falsches Passwort oder Datei beschädigt!"), backgroundColor: Colors.red),
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

        // --- ADMIN REGISTRY WIEDERHERSTELLEN ---
        if (version >= 2 && data['admin_registry'] != null) {
          final registryList = data['admin_registry'] as List<dynamic>;
          for (var adminJson in registryList) {
            try {
              await AdminRegistry.addAdmin(
                AdminEntry.fromJson(adminJson as Map<String, dynamic>),
              );
            } catch (e) {
              // Duplikat-Fehler ignorieren
            }
          }
        }

        if (context.mounted) {
          final hasNostr = version >= 2 && data['nostr'] != null && (data['nostr']['has_key'] ?? false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                hasNostr
                    ? "✅ Verschlüsseltes Backup geladen! Nostr-Key wiederhergestellt."
                    : "✅ Backup erfolgreich eingespielt!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Import Fehler: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Import fehlgeschlagen: $e"), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
}