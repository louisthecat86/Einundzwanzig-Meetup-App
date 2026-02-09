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
  final String portalLink; // Link zum Portal
  final String twitterUsername; // Twitter
  final String nostrNpub; // Nostr npub
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
}

// Unsere Demo-Datenbank
List<Meetup> allMeetups = [
  Meetup(id: "m_muc", city: "München", country: "DE", telegramLink: "t.me/einundzwanzig_muc", lat: 48.1351, lng: 11.5820),
  Meetup(id: "m_hh", city: "Hamburg", country: "DE", telegramLink: "t.me/einundzwanzig_hh", lat: 53.5511, lng: 9.9937),
  Meetup(id: "m_b", city: "Berlin", country: "DE", telegramLink: "t.me/einundzwanzig_berlin", lat: 52.5200, lng: 13.4050),
  Meetup(id: "m_zh", city: "Zürich", country: "CH", telegramLink: "t.me/einundzwanzig_zh", lat: 47.3769, lng: 8.5417),
  Meetup(id: "m_wien", city: "Wien", country: "AT", telegramLink: "t.me/einundzwanzig_wien", lat: 48.2082, lng: 16.3738),
];

List<Meetup> fallbackMeetups = allMeetups;