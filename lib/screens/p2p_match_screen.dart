// Beispiel-Code fuer Issue #62: kein OS-Push und kein Anwesenheitsbeweis.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/p2p_offer.dart';
import '../services/p2p_match_service.dart';
import '../services/p2p_nostr_service.dart';
import '../services/signing_service.dart';
import '../theme.dart';

class P2pMatchScreen extends StatefulWidget {
  final String eventAddress, eventTitle;
  final DateTime eventStart;
  const P2pMatchScreen({super.key, required this.eventAddress,
    required this.eventTitle, required this.eventStart});

  @override
  State<P2pMatchScreen> createState() => _P2pMatchScreenState();
}

class _P2pMatchScreenState extends State<P2pMatchScreen> {
  final _network = const P2pNostrService();
  final _matcher = const P2pMatchService();
  Timer? _timer;
  String? _me, _error;
  bool _busy = false, _polling = false, _notifying = false;
  List<P2pMatch> _matches = [];
  P2pSide? _mine;

  @override
  void initState() {
    super.initState();
    _init();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _key =>
      'p2p-notified|$_me|${P2pNostrService.dTag(widget.eventAddress)}';

  Future<void> _init() async {
    try {
      final me = await SigningService.pubkeyHex();
      if (!mounted) return;
      setState(() => _me = me);
      await _refresh();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  bool get _withinWindow {
    final now = DateTime.now();
    return !now.isBefore(widget.eventStart.subtract(const Duration(minutes: 90))) &&
        now.isBefore(widget.eventStart.add(const Duration(hours: 4)));
  }

  Future<void> _refresh() async {
    if (_polling || _me == null || !mounted) return;
    _polling = true;
    try {
      final offers = await _network.load(widget.eventAddress, DateTime.now());
      if (!mounted) return;
      final myOffer = offers.where((o) => o.authorPubkey == _me).firstOrNull;
      final matches = _matcher.findMatches(
        myPubkey: _me!, offers: offers, now: DateTime.now());
      setState(() { _mine = myOffer?.side; _matches = matches; _error = null; });
      if (matches.isNotEmpty && !_notifying) {
        final prefs = await SharedPreferences.getInstance();
        final seen = prefs.getStringList(_key)?.toSet() ?? <String>{};
        final newMatches = _matcher.unseen(matches, seen);
        if (newMatches.isNotEmpty && mounted) {
          // Vor dem Dialog speichern; App-Abbruch soll kein zweites Pop-up
          // fuer dasselbe unveraenderte Match ausloesen.
          await prefs.setStringList(_key, seen.toList());
          _notifying = true;
          try {
            if (!mounted) return;
            await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
              title: const Text('⚡ Bitcoin P2P Match!'),
              content: Text('Auf diesem Meetup gibt es ${newMatches.length} '
                  'neue passende Kauf-/Verkaufsinteressen.'),
              actions: [TextButton(onPressed: () => Navigator.pop(ctx),
                  child: const Text('Matches ansehen'))],
            ));
          } finally { _notifying = false; }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Relay-Abfrage fehlgeschlagen: $e');
    } finally { _polling = false; }
  }

  Future<void> _setSide(P2pSide? side) async {
    if (_busy || _me == null || (side != null && !_withinWindow)) return;
    if (side != null) {
      final agreed = await showDialog<bool>(context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Freiwilliges P2P-Interesse'),
          content: const Text('Du bestaetigst selbst, dass du vor Ort bist. '
              'Deine Nostr-Identitaet, deine Kauf-/Verkaufsrichtung und '
              'der Meetup-Termin sind auf oeffentlichen Relays sichtbar. '
              'Alte Events koennen dort gespeichert bleiben. Keine Betraege '
              'oder Wallet-Daten werden veroeffentlicht. Fortfahren?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen')),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Freiwillig aktivieren')),
          ],
        ));
      if (agreed != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final eventEnd = widget.eventStart.add(const Duration(hours: 4));
      final proposed = now.add(const Duration(hours: 2));
      final expiresAt = proposed.isBefore(eventEnd) ? proposed : eventEnd;
      final err = await _network.publish(eventAddress: widget.eventAddress,
          side: side, expiresAt: expiresAt);
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
      } else {
        setState(() { _mine = side; _error = null; });
        await _refresh();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(title: const Text('Bitcoin P2P Matchmaker'),
          backgroundColor: cDark,
          actions: [IconButton(onPressed: _refresh,
              icon: const Icon(Icons.refresh), tooltip: 'Aktualisieren')]),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Text(widget.eventTitle, style: const TextStyle(
            color: cText, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Freiwilliger Check-in · kein Anwesenheitsbeweis · '
            'keine Verwahrung oder Handelsausfuehrung',
            style: TextStyle(color: cTextSecondary)),
        if (!_withinWindow) const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Aktivierung ab 90 Minuten vor bis 4 Stunden nach '
              'Terminbeginn moeglich.', style: TextStyle(color: cOrange)),
        ),
        if (_error != null) Padding(padding: const EdgeInsets.all(8),
            child: Text(_error!, style: const TextStyle(color: cRed))),
        const SizedBox(height: 22),
        Text('Mein Interesse: ${_mine == P2pSide.buy ? 'Kaufen' : _mine == P2pSide.sell ? 'Verkaufen' : 'Aus'}',
            style: const TextStyle(color: cText, fontSize: 16)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _busy || !_withinWindow || _me == null ? null
            : () => _setSide(P2pSide.buy),
            child: const Text('🟢 Bitcoin kaufen')),
        ElevatedButton(onPressed: _busy || !_withinWindow || _me == null ? null
            : () => _setSide(P2pSide.sell),
            child: const Text('🔴 Bitcoin verkaufen')),
        OutlinedButton(onPressed: _busy || _me == null ? null
            : () => _setSide(null),
            child: const Text('P2P-Interesse deaktivieren')),
        const SizedBox(height: 24),
        Text('Matches (${_matches.length})',
            style: const TextStyle(color: cText, fontSize: 18)),
        const SizedBox(height: 10),
        if (_matches.isEmpty) const Text('Noch kein passendes aktives Interesse. '
            'Die Liste aktualisiert sich bei geoeffneter Ansicht.',
            style: TextStyle(color: cTextSecondary)),
        for (final m in _matches)
          Card(color: cCard, child: ListTile(
            leading: const Icon(Icons.currency_bitcoin, color: cOrange),
            title: Text(m.other.side == P2pSide.sell
                ? 'Jemand moechte Bitcoin verkaufen'
                : 'Jemand moechte Bitcoin kaufen',
                style: const TextStyle(color: cText)),
            subtitle: SelectableText('Nostr-Pubkey: ${m.other.authorPubkey}',
                style: const TextStyle(color: cTextSecondary)),
            trailing: IconButton(icon: const Icon(Icons.copy, color: cOrange),
                tooltip: 'Pubkey kopieren', onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: m.other.authorPubkey));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Nostr-Pubkey kopiert.')));
                  }
                }),
          )),
        const SizedBox(height: 16),
        const Text('Keine Push-Zustellung bei geschlossener App. '
            'Kontaktaufnahme vorerst ueber den angezeigten Nostr-Pubkey; '
            'ein verschluesselter Direktchat folgt separat.',
            style: TextStyle(color: cTextSecondary)),
      ]),
    );
  }
}
