import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meetup.dart';

class MeetupService {
  static const String _url = "https://portal.einundzwanzig.space/api/meetups";

  static Future<List<Meetup>> fetchMeetups() async {
    try {
      final response = await http.get(Uri.parse(_url));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          return Meetup(
            id: json['id']?.toString() ?? json['name'] ?? "unknown",
            city: json['city'] ?? json['name'] ?? "Unbekannt",
            country: json['country'] ?? "DE",
            telegramLink: json['url'] ?? "",
            logoUrl: json['logo'] ?? "",
            description: json['intro'] ?? "",
            website: json['website'] ?? "",
            portalLink: json['portalLink'] ?? "",
            twitterUsername: json['twitter_username'] ?? "",
            nostrNpub: json['nostr'] ?? "",
            lat: (json['latitude'] as num?)?.toDouble() ?? 0.0,
            lng: (json['longitude'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Fehler beim Laden der Meetups: $e");
      return [];
    }
  }
}