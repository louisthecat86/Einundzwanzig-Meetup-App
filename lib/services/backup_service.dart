import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
// Importiere deine Models
import '../models/user.dart';
import '../models/badge.dart'; 

class BackupService {

  // --- EXPORT (BACKUP ERSTELLEN) ---
  static Future<void> createBackup(BuildContext context) async {
    try {
      // 1. Lade alle Daten
      final user = await UserProfile.load();
      final badges = await MeetupBadge.loadBadges(); // Wir laden sicherheitshalber frisch

      // 2. Erstelle das JSON Objekt
      Map<String, dynamic> backupData = {
        'version': 1, // Wichtig für zukünftige Updates
        'timestamp': DateTime.now().toIso8601String(),
        'app': 'Einundzwanzig Meetup App',
        'user': {
          'nickname': user.nickname,
          'homeMeetupId': user.homeMeetupId,
          'isAdmin': user.isAdmin,
          'isAdminVerified': user.isAdminVerified,
          'nostrNpub': user.nostrNpub,
          // Füge hier weitere Felder hinzu, falls dein User-Model wächst
        },
        // Wir mappen die Badges in eine Liste von Maps
        'badges': badges.map((b) => {
          'id': b.id,
          'meetupName': b.meetupName,
          'date': b.date.toIso8601String(),
          'blockHeight': b.blockHeight,
          // Weitere Badge Felder...
        }).toList(),
      };

      // 3. Konvertiere zu JSON String
      String jsonString = jsonEncode(backupData);

      // 4. Temporäre Datei speichern
      final directory = await getTemporaryDirectory();
      String dateStr = DateFormat('yyyy-MM-dd_HHmm').format(DateTime.now());
      // Dateiname: 21_backup_2024-05-12.json
      final file = File('${directory.path}/21_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      // 5. Öffne den "Teilen" Dialog (Share Sheet)
      // iOS/Android bieten dann an: "In Dateien speichern", "Per Signal senden", etc.
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Einundzwanzig App Backup',
        text: 'Hier ist dein Backup. Speichere es sicher ab!',
      );

    } catch (e) {
      print("Backup Fehler: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Backup: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // --- IMPORT (WIEDERHERSTELLEN) ---
  // Gibt true zurück, wenn erfolgreich importiert wurde
  static Future<bool> restoreBackup(BuildContext context) async {
    try {
      // 1. Datei-Auswahl Dialog öffnen
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // Nur JSON Dateien erlauben
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        // 2. JSON parsen
        Map<String, dynamic> data = jsonDecode(content);

        // 3. Sicherheits-Check: Ist es ein Backup von uns?
        if (!data.containsKey('user') || !data.containsKey('badges')) {
          throw Exception("Datei ist kein gültiges Backup oder beschädigt.");
        }

        // 4. User wiederherstellen
        var userData = data['user'];
        var user = await UserProfile.load();
        user.nickname = userData['nickname'] ?? "Anon";
        user.homeMeetupId = userData['homeMeetupId'] ?? "";
        user.isAdmin = userData['isAdmin'] ?? false;
        user.isAdminVerified = userData['isAdminVerified'] ?? false;
        user.nostrNpub = userData['nostrNpub'] ?? "";
        await user.save();

        // 5. Badges wiederherstellen
        List<dynamic> badgeList = data['badges'];
        List<MeetupBadge> restoredBadges = [];
        
        for (var b in badgeList) {
          restoredBadges.add(MeetupBadge(
            id: b['id'],
            meetupName: b['meetupName'],
            date: DateTime.parse(b['date']),
            iconPath: "assets/badge_icon.png", // Icon Pfad ist statisch, daher hardcoded setzen
            blockHeight: b['blockHeight'] ?? 0,
          ));
        }
        
        // Globale Liste und Speicher überschreiben
        // ACHTUNG: Hier wird "myBadges" referenziert. Stelle sicher, dass das importiert ist
        // oder übergib die Liste. Am saubersten ist Speichern:
        await MeetupBadge.saveBadges(restoredBadges);
        // Wir aktualisieren die globale Liste im Dashboard später per setState

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Backup erfolgreich eingespielt!"), backgroundColor: Colors.green),
        );
        return true; // Erfolg signalisieren
      } else {
        // User hat abgebrochen
        return false;
      }
    } catch (e) {
      print("Import Fehler: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Import fehlgeschlagen: $e"), backgroundColor: Colors.red),
      );
      return false;
    }
  }
}