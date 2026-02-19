import 'package:shared_preferences/shared_preferences.dart';
import '../services/secure_key_store.dart';

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
  bool hasNostrKey;       // Hat der User ein Keypair in der App?
  String promotionSource; // Wie wurde Admin? 'trust_score', 'seed_admin', ''

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
    this.promotionSource = "",
  });

  static Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Prüfe ob ein Nostr-Keypair existiert (über SecureKeyStore)
    final hasKey = await SecureKeyStore.hasKey();

    // Wenn Keypair vorhanden, npub aus SecureKeyStore nehmen (hat Vorrang)
    String npub = prefs.getString('nostr') ?? "";
    if (hasKey) {
      final keyNpub = await SecureKeyStore.getNpub();
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
      promotionSource: prefs.getString('promotion_source') ?? "",
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
    await prefs.setString('promotion_source', promotionSource);
  }

  bool get isVerified => isNostrVerified || isAdminVerified;
}