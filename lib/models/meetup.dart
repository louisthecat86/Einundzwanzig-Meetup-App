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
  final String twitterUsername; // Das Feld nutzen wir
  final String nostrNpub;
  final String adminSecret;

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
  });

  // HIER IST DAS NEUE: Wir bauen das Objekt aus den Internet-Daten
  factory Meetup.fromJson(Map<String, dynamic> json) {
    return Meetup(
      id: json['id'].toString(),
      city: json['name'] ?? 'Unbekannt',
      country: _parseCountry(json),
      // Das Portal liefert Twitter manchmal als 'twitter' oder 'twitter_username'
      twitterUsername: json['twitter'] ?? json['twitter_username'] ?? '', 
      telegramLink: json['telegram'] ?? '',
      website: json['website'] ?? '',
      nostrNpub: json['nostr'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lon'] ?? 0).toDouble(),
    );
  }

  // Kleine Hilfsfunktion um das Land zu bestimmen
  static String _parseCountry(Map<String, dynamic> json) {
    if (json['country'] != null) return json['country'].toString();
    String name = (json['name'] ?? '').toString().toLowerCase();
    if (name.contains('wien') || name.contains('innsbruck') || name.contains('graz')) return 'AT';
    if (name.contains('zürich') || name.contains('bern') || name.contains('luzern')) return 'CH';
    if (name.contains('mallorca')) return 'ES';
    return 'DE';
  }
}

// Demo-Daten (Fallback, falls Internet weg ist)
List<Meetup> allMeetups = [
  Meetup(id: "m_muc", city: "München", country: "DE", telegramLink: "t.me/einundzwanzig_muc", lat: 48.1351, lng: 11.5820),
  Meetup(id: "m_hh", city: "Hamburg", country: "DE", telegramLink: "t.me/einundzwanzig_hh", lat: 53.5511, lng: 9.9937),
  Meetup(id: "m_b", city: "Berlin", country: "DE", telegramLink: "t.me/einundzwanzig_berlin", lat: 52.5200, lng: 13.4050),
];

List<Meetup> fallbackMeetups = allMeetups;