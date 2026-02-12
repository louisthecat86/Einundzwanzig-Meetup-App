import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/badge.dart';
import 'admin_registry.dart';

class BackupService {

  // --- EXPORT (BACKUP ERSTELLEN) ---
  static Future<void> createBackup(BuildContext context) async {
    try {
      final user = await UserProfile.load();
      final badges = await MeetupBadge.loadBadges();
      final prefs = await SharedPreferences.getInstance();

      // Nostr Keys laden (wenn vorhanden)
      final nsec = prefs.getString('nostr_nsec_key');
      final npub = prefs.getString('nostr_npub_key');
      final privHex = prefs.getString('nostr_priv_hex');

      // Admin-Registry laden
      final adminList = await AdminRegistry.getAdminList();

      Map<String, dynamic> backupData = {
        'version': 2, // v2: mit Nostr Keys + Admin Registry
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'Einundzwanzig Meetup App',
        
        // User Profil
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

        // Badges
        'badges': badges.map((b) => {
          'id': b.id,
          'meetupName': b.meetupName,
          'date': b.date.toIso8601String(),
          'blockHeight': b.blockHeight,
        }).toList(),

        // NEU: Nostr Schlüssel
        'nostr': {
          'nsec': nsec ?? '',
          'npub': npub ?? '',
          'priv_hex': privHex ?? '',
          'has_key': nsec != null,
        },

        // NEU: Admin Registry (lokaler Cache)
        'admin_registry': adminList.map((a) => a.toJson()).toList(),
      };

      String jsonString = jsonEncode(backupData);

      final directory = await getTemporaryDirectory();
      String dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      final file = File('${directory.path}/21_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Einundzwanzig App Backup',
        text: 'Backup enthält deine Nostr-Identität. Sicher aufbewahren!',
      );

    } catch (e) {
      print("Backup Fehler: $e");
      if (context.mounted) {
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
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(content);

        if (!data.containsKey('user') || !data.containsKey('badges')) {
          throw Exception("Datei ist kein gültiges Backup oder beschädigt.");
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

        // --- v2: NOSTR KEYS WIEDERHERSTELLEN ---
        if (version >= 2 && data['nostr'] != null) {
          final nostrData = data['nostr'] as Map<String, dynamic>;
          final hasKey = nostrData['has_key'] ?? false;

          if (hasKey) {
            final prefs = await SharedPreferences.getInstance();
            final nsec = nostrData['nsec'] ?? '';
            final npub = nostrData['npub'] ?? '';
            final privHex = nostrData['priv_hex'] ?? '';

            if (nsec.isNotEmpty && npub.isNotEmpty && privHex.isNotEmpty) {
              await prefs.setString('nostr_nsec_key', nsec);
              await prefs.setString('nostr_npub_key', npub);
              await prefs.setString('nostr_priv_hex', privHex);

              // npub auch im User-Profil aktualisieren
              user.nostrNpub = npub;
              user.isNostrVerified = true;
              user.hasNostrKey = true;
              await user.save();
            }
          }
        }

        // --- v2: ADMIN REGISTRY WIEDERHERSTELLEN ---
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
                    ? "✅ Backup eingespielt! Nostr-Key wiederhergestellt."
                    : "✅ Backup eingespielt!",
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