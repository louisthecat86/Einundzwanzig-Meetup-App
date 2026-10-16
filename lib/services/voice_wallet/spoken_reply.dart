/// Text, den die Stimme sagen darf.
///
/// Die Zahl bleibt ohne Tausenderpunkt, damit "1000" als tausend
/// gesprochen wird. Ein Cashu-Token oder ein ur-Teil wird ausgelassen.
String? spokenReply({int? amount, String? sentence}) {
  final line = _safe(sentence);
  final parts = <String>[
    if (amount != null && amount >= 0) '$amount Sats',
    ?line,
  ];
  if (parts.isEmpty) return null;
  return parts.join('. ');
}

String? _safe(String? sentence) {
  if (sentence == null) return null;
  final line = sentence.trim();
  if (line.isEmpty) return null;
  final lower = line.toLowerCase();
  if (lower.contains('cashua') ||
      lower.contains('cashub') ||
      lower.contains('ur:') ||
      lower.contains('lnbc') ||
      lower.contains('lntb') ||
      lower.contains('lnurl')) {
    return null;
  }
  return line;
}
