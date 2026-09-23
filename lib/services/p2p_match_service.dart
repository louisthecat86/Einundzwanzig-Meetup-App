import '../models/p2p_offer.dart';

/// Rein lokaler Matching-Kern. checkedIn ist in diesem MVP nur Selbstauskunft.
class P2pMatch {
  final P2pOffer mine, other;
  final int? minSats, maxSats;
  const P2pMatch(this.mine, this.other, this.minSats, this.maxSats);

  String get key {
    final ids = [mine.id, other.id]..sort();
    return '${mine.meetupEventId}|${ids[0]}|${ids[1]}';
  }
}

class P2pMatchService {
  const P2pMatchService();

  List<P2pMatch> findMatches({
    required String myPubkey,
    required Iterable<P2pOffer> offers,
    required DateTime now,
  }) {
    final active = offers.where((o) => o.activeAt(now)).toList();
    final mine = active.where((o) => o.authorPubkey == myPubkey);
    final others = active.where((o) => o.authorPubkey != myPubkey);
    final found = <String, P2pMatch>{};
    for (final own in mine) {
      for (final other in others) {
        if (own.meetupEventId != other.meetupEventId ||
            own.side == other.side) continue;
        final min = _maximum(own.minSats, other.minSats);
        final max = _minimum(own.maxSats, other.maxSats);
        if (min != null && max != null && min > max) continue;
        final match = P2pMatch(own, other, min, max);
        found[match.key] = match;
      }
    }
    return found.values.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  List<P2pMatch> unseen(List<P2pMatch> matches, Set<String> notifiedKeys) {
    final result = <P2pMatch>[];
    for (final match in matches) {
      if (notifiedKeys.add(match.key)) result.add(match);
    }
    return result;
  }

  static int? _maximum(int? a, int? b) =>
      a == null ? b : b == null ? a : (a > b ? a : b);
  static int? _minimum(int? a, int? b) =>
      a == null ? b : b == null ? a : (a < b ? a : b);
}
