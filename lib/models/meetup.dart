class Meetup {
  final String id;
  final String city;
  final String country;
  final String telegramLink;
  final double lat;
  final double lng;
  final String logoUrl;
  final String description;
  final String website;
  final String portalLink;
  final String twitterUsername;
  final String nostrNpub;
  final String adminSecret;
  final String coverImagePath; // <--- NEU: Das Hintergrundbild für den Badge

  Meetup({
    required this.id, 
    required this.city, 
    required this.country, 
    required this.telegramLink,
    required this.lat,
    required this.lng,
    this.logoUrl = "",
    this.description = "",
    this.website = "",
    this.portalLink = "",
    this.twitterUsername = "",
    this.nostrNpub = "",
    this.adminSecret = "21",
    this.coverImagePath = "", // <--- NEU: Standardwert leer
  });

  factory Meetup.fromJson(Map<String, dynamic> json) {
    // Wir versuchen das beste Bild zu finden (Cover > Image > Logo)
    String image = "";
    if (json['cover'] != null) {
      image = json['cover'];
    } else if (json['image'] != null) {
      image = json['image'];
    } else if (json['logo'] != null) {
      image = json['logo'];
    }

    return Meetup(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      city: json['name'] ?? 'Unbekannt',
      country: _parseCountry(json),
      twitterUsername: json['twitter'] ?? json['twitter_username'] ?? '', 
      telegramLink: json['telegram'] ?? '',
      website: json['website'] ?? '',
      nostrNpub: json['nostr'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lon'] ?? 0).toDouble(),
      coverImagePath: image, // <--- NEU: Hier weisen wir das gefundene Bild zu
    );
  }

  static String _parseCountry(Map<String, dynamic> json) {
    if (json['country'] != null) return json['country'].toString();
    String name = (json['name'] ?? '').toString().toLowerCase();
    if (name.contains('wien') || name.contains('innsbruck') || name.contains('graz')) return 'AT';
    if (name.contains('zürich') || name.contains('bern') || name.contains('luzern')) return 'CH';
    if (name.contains('mallorca')) return 'ES';
    return 'DE';
  }
}

// Fallback Daten (nur für Offline-Tests relevant)
List<Meetup> allMeetups = [
  Meetup(id: "m_muc", city: "München", country: "DE", telegramLink: "t.me/einundzwanzig_muc", lat: 48.1351, lng: 11.5820),
  Meetup(id: "m_hh", city: "Hambmurg", country: "DE", telegramLink: "t.me/einundzwanzig_hh", lat: 53.5511, lng: 9.9937),
  Meetup(id: "m_b", city: "Berlin", country: "DE", telegramLink: "t.me/einundzwanzig_berlin", lat: 52.5200, lng: 13.4050),
];

List<Meetup> fallbackMeetups = allMeetups;