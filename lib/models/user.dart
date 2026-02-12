import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  String nickname;
  String fullName;
  String telegramHandle;
  String nostrNpub;       // Öffentlicher Schlüssel (npub1...)
  String twitterHandle;
  bool isNostrVerified;   // Hat einen gültigen Nostr-Key
  bool isAdminVerified;
  bool isAdmin;
  String homeMeetupId;
  bool hasNostrKey;       // NEU: Hat der User ein Keypair in der App?

  UserProfile({
    this.nickname = "Anon",
    this.fullName = "",
    this.telegramHandle = "",
    this.nostrNpub = "",
    this.twitterHandle = "",
    this.isNostrVerified = false,
    this.isAdminVerified = false,
    this.isAdmin = false,
    this.homeMeetupId = "",
    this.hasNostrKey = false,
  });

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prüfe ob ein Nostr-Keypair existiert
    final hasKey = prefs.getString('nostr_nsec_key') != null;

    // Wenn Keypair vorhanden, npub vom Key nehmen (hat Vorrang)
    String npub = prefs.getString('nostr') ?? "";
    if (hasKey) {
      final keyNpub = prefs.getString('nostr_npub_key');
      if (keyNpub != null && keyNpub.isNotEmpty) {
        npub = keyNpub;
      }
    }

    return UserProfile(
      nickname: prefs.getString('nickname') ?? "Anon",
      fullName: prefs.getString('full_name') ?? "",
      telegramHandle: prefs.getString('telegram') ?? "",
      nostrNpub: npub,
      twitterHandle: prefs.getString('twitter') ?? "",
      isNostrVerified: hasKey || (prefs.getBool('nostr_verified') ?? false),
      isAdminVerified: prefs.getBool('admin_verified') ?? false,
      isAdmin: prefs.getBool('is_admin') ?? false,
      homeMeetupId: prefs.getString('home_meetup') ?? "",
      hasNostrKey: hasKey,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nickname', nickname);
    await prefs.setString('full_name', fullName);
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