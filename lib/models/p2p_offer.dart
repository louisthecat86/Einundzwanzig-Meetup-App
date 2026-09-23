/// Freiwilliges P2P-Interesse; keine Wallet- oder Zahlungsdaten.
enum P2pSide { buy, sell }

class P2pOffer {
  final String id, authorPubkey, meetupEventId;
  final P2pSide side;
  final DateTime startsAt, expiresAt;
  final int? minSats, maxSats;
  final bool checkedIn;

  P2pOffer({
    required this.id,
    required this.authorPubkey,
    required this.meetupEventId,
    required this.side,
    required this.startsAt,
    required this.expiresAt,
    this.minSats,
    this.maxSats,
    this.checkedIn = false,
  }) {
    if (id.trim().isEmpty || authorPubkey.trim().isEmpty ||
        meetupEventId.trim().isEmpty) {
      throw ArgumentError('ID, Pubkey und Termin-ID duerfen nicht leer sein.');
    }
    if (!expiresAt.isAfter(startsAt)) {
      throw ArgumentError('Ablauf muss nach Beginn liegen.');
    }
    if ((minSats != null && minSats! <= 0) ||
        (maxSats != null && maxSats! <= 0) ||
        (minSats != null && maxSats != null && minSats! > maxSats!)) {
      throw ArgumentError('Ungueltiger Betragsbereich.');
    }
  }

  bool activeAt(DateTime now) =>
      checkedIn && !now.isBefore(startsAt) && now.isBefore(expiresAt);
}
