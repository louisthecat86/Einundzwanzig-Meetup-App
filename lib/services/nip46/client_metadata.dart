/// Öffentliche Anzeigehinweise für Remote-Signer gemäß NIP-46.
/// Das Bild muss auch außerhalb der installierten App erreichbar sein.
abstract final class Nip46ClientMetadata {
  static const name = 'Einundzwanzig Meetup';
  static const url =
      'https://github.com/louisthecat86/Einundzwanzig-Meetup-App';
  static const image =
      'https://raw.githubusercontent.com/louisthecat86/Einundzwanzig-Meetup-App/main/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60%403x.png';

  static const values = <String, String>{
    'name': name,
    'url': url,
    'image': image,
  };
}
