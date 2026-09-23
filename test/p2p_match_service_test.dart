import 'package:flutter_test/flutter_test.dart';
import '../lib/models/p2p_offer.dart';
import '../lib/services/p2p_match_service.dart';

void main() {
  final now = DateTime.utc(2026, 9, 23, 18);
  P2pOffer offer(String id, String author, P2pSide side, {
    String event = 'koeln-2026-09-23',
    bool checkedIn = true,
    int? min,
    int? max,
    DateTime? expires,
  }) => P2pOffer(
    id: id, authorPubkey: author, meetupEventId: event, side: side,
    startsAt: now.subtract(const Duration(hours: 1)),
    expiresAt: expires ?? now.add(const Duration(hours: 1)),
    checkedIn: checkedIn, minSats: min, maxSats: max,
  );
  const matcher = P2pMatchService();
  List<P2pMatch> matches(List<P2pOffer> offers) => matcher.findMatches(
    myPubkey: 'ich', offers: offers, now: now,
  );

  test('kaufen und verkaufen auf demselben Termin ergibt ein Match', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell)]).length, 1);
  });
  test('kein Match bei gleicher Richtung', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.buy)]), isEmpty);
  });
  test('kein Match mit sich selbst', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','ich',P2pSide.sell)]), isEmpty);
  });
  test('keine falsche Treffpunkt-Zuordnung', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell,event:'berlin')]), isEmpty);
  });
  test('beide muessen aktiv eingecheckt sein', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell,checkedIn:false)]), isEmpty);
  });
  test('abgelaufene Angebote werden ignoriert', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell,expires:now)]), isEmpty);
  });
  test('nicht ueberlappende Betragsbereiche werden ignoriert', () {
    expect(matches([offer('a','ich',P2pSide.buy,max:1000),
      offer('b','du',P2pSide.sell,min:1001)]), isEmpty);
  });
  test('gemeinsamer Betragsbereich wird ermittelt', () {
    final match = matches([offer('a','ich',P2pSide.buy,min:100,max:1000),
      offer('b','du',P2pSide.sell,min:200,max:2000)]).single;
    expect(match.minSats,200);
    expect(match.maxSats,1000);
  });
  test('doppeltes Match wird nur einmal gemeldet', () {
    final found = matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell)]);
    final notified = <String>{};
    expect(matcher.unseen(found,notified).length,1);
    expect(matcher.unseen(found,notified),isEmpty);
  });
  test('falsche Angebote werden abgewiesen', () {
    expect(() => offer('a','ich',P2pSide.buy,min:200,max:100),
      throwsArgumentError);
  });
  test('kuenftige Angebote sind noch nicht aktiv', () {
    final future = P2pOffer(id: 'future', authorPubkey: 'du',
      meetupEventId: 'koeln-2026-09-23', side: P2pSide.sell,
      startsAt: now.add(const Duration(seconds: 1)),
      expiresAt: now.add(const Duration(hours: 1)), checkedIn: true);
    expect(matches([offer('a','ich',P2pSide.buy), future]), isEmpty);
  });
  test('eigener fehlender Check-in verhindert Match', () {
    expect(matches([offer('a','ich',P2pSide.buy,checkedIn:false),
      offer('b','du',P2pSide.sell)]), isEmpty);
  });
  test('Betragsgrenzen am Rand ergeben ein Match', () {
    final match = matches([offer('a','ich',P2pSide.buy,max:1000),
      offer('b','du',P2pSide.sell,min:1000)]).single;
    expect(match.minSats, 1000);
    expect(match.maxSats, 1000);
  });
  test('Angebotsreihenfolge veraendert Match-Schluessel nicht', () {
    final a = offer('a','ich',P2pSide.buy);
    final b = offer('b','du',P2pSide.sell);
    expect(matches([a,b]).single.key, matches([b,a]).single.key);
  });
  test('mehrere Gegenseiten werden getrennt gemeldet', () {
    expect(matches([offer('a','ich',P2pSide.buy),
      offer('b','du',P2pSide.sell),
      offer('c','dritter',P2pSide.sell)]).length, 2);
  });
  test('doppelte identische Angebote liefern nur ein Match', () {
    final a = offer('a','ich',P2pSide.buy);
    final b = offer('b','du',P2pSide.sell);
    expect(matches([a,b,b]).length, 1);
  });
  test('kein null- oder negativer Angebotsbetrag', () {
    expect(() => offer('a','ich',P2pSide.buy,min:0), throwsArgumentError);
    expect(() => offer('a','ich',P2pSide.buy,max:-1), throwsArgumentError);
  });
  test('Endzeit muss nach Beginn liegen', () {
    expect(() => P2pOffer(id: 'a',authorPubkey: 'ich',
      meetupEventId: 'koeln', side: P2pSide.buy,
      startsAt: now, expiresAt: now), throwsArgumentError);
  });
}
