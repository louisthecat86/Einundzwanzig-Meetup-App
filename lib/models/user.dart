import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String nickname;
  String fullName; // <--- NEU
  String telegramHandle;
  String nostrPubkey; // <--- Umbenannt (vorher nostrNpub), damit es zum Edit-Screen passt
  String twitterHandle;
  bool isNostrVerified; 
  bool isAdminVerified; 
  bool isAdmin; 
  String homeMeetupId;

  UserProfile({
    this.nickname = "Anon",
    this.fullName = "", // <--- NEU
    this.telegramHandle = "",
    this.nostrPubkey = "", // <--- Geändert
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
      fullName: prefs.getString('full_name') ?? "", // <--- NEU
      telegramHandle: prefs.getString('telegram') ?? "",
      nostrPubkey: prefs.getString('nostr') ?? "", // Wir nutzen weiterhin den Key 'nostr' damit alte Daten bleiben
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
    await prefs.setString('full_name', fullName); // <--- NEU
    await prefs.setString('telegram', telegramHandle);
    await prefs.setString('nostr', nostrPubkey); // Speichert unter dem alten Key 'nostr'
    await prefs.setString('twitter', twitterHandle);
    await prefs.setBool('nostr_verified', isNostrVerified);
    await prefs.setBool('admin_verified', isAdminVerified);
    await prefs.setBool('is_admin', isAdmin);
    await prefs.setString('home_meetup', homeMeetupId);
  }

  bool get isVerified => isNostrVerified || isAdminVerified;
}