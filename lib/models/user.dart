import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String nickname;
  String telegramHandle;
  String nostrNpub;
  String twitterHandle;
  bool isNostrVerified; 
  bool isAdminVerified; // Identität wurde von Admin bestätigt
  bool isAdmin; // Hat Admin-Rechte (eingeloggt mit Admin-Passwort)
  String homeMeetupId;

  UserProfile({
    this.nickname = "Anon",
    this.telegramHandle = "",
    this.nostrNpub = "",
    this.twitterHandle = "",
    this.isNostrVerified = false,
    this.isAdminVerified = false,
    this.isAdmin = false,
    this.homeMeetupId = "",
  });

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      nickname: prefs.getString('nickname') ?? "Anon",
      telegramHandle: prefs.getString('telegram') ?? "",
      nostrNpub: prefs.getString('nostr') ?? "",
      twitterHandle: prefs.getString('twitter') ?? "",
      isNostrVerified: prefs.getBool('nostr_verified') ?? false,
      isAdminVerified: prefs.getBool('admin_verified') ?? false,
      isAdmin: prefs.getBool('is_admin') ?? false,
      homeMeetupId: prefs.getString('home_meetup') ?? "",
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    await prefs.setString('telegram', telegramHandle);
    await prefs.setString('nostr', nostrNpub);
    await prefs.setString('twitter', twitterHandle);
    await prefs.setBool('nostr_verified', isNostrVerified);
    await prefs.setBool('admin_verified', isAdminVerified);
    await prefs.setBool('is_admin', isAdmin);
    await prefs.setString('home_meetup', homeMeetupId);
  }

  bool get isVerified => isNostrVerified || isAdminVerified;
}