/// Beste Stimme aus der Liste des iPhones.
///
/// Premium und Enhanced klingen voller. Die kleine Compact-Stimme und
/// die Eloquence-Stimmen bleiben liegen, wenn es etwas Besseres gibt.
class PhoneVoice {
  final String identifier;
  final String name;
  final String locale;

  const PhoneVoice({
    required this.identifier,
    required this.name,
    required this.locale,
  });
}

PhoneVoice? pickPhoneVoice(Object? voices, String language) {
  if (voices is! List) return null;
  final want = language.toLowerCase().replaceAll('_', '-');
  PhoneVoice? best;
  var bestScore = -1;
  for (final item in voices) {
    if (item is! Map) continue;
    final locale = '${item['locale']}'.toLowerCase().replaceAll('_', '-');
    if (!locale.startsWith(want)) continue;
    final identifier = '${item['identifier']}';
    if (identifier.isEmpty || identifier == 'null') continue;
    final score = _score(identifier, '${item['quality']}');
    if (score > bestScore) {
      bestScore = score;
      best = PhoneVoice(
        identifier: identifier,
        name: '${item['name']}',
        locale: '${item['locale']}',
      );
    }
  }
  return best;
}

int _score(String identifier, String quality) {
  final id = identifier.toLowerCase();
  if (id.contains('eloquence')) return -1;
  var score = switch (quality.toLowerCase()) {
    'premium' => 30,
    'enhanced' => 20,
    _ => 10,
  };
  if (id.contains('compact')) score -= 8;
  if (id.contains('siri')) score += 5;
  return score;
}
