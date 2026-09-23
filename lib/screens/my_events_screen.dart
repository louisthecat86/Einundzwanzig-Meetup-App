// MEINE TERMINE
// ============================================
// Alles, wofuer man zugesagt hat — mit dem Weg in den jeweiligen Chat und
// dem Hinweis, ob dort etwas Neues steht.
//
// Warum ein eigener Bildschirm und nicht der Kalender: Im Kalender steht
// ALLES, hier nur das, wo man hingeht. Das sind zwei verschiedene Fragen —
// "was gibt es?" und "was habe ich vor?" — und die zweite beantwortet sich
// schlecht in einer Liste mit hundert Terminen.
// ============================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/calendar_event.dart';
import '../services/calendar_event_service.dart';
import '../services/event_chat_service.dart';
import '../services/event_rsvp_service.dart';
import '../theme.dart';
import 'chat_screen.dart';
import 'p2p_match_screen.dart';

/// Ein anstehender Meetup-Termin aus den Favoriten.
class MyMeetupDate {
  /// Gespeicherter Favorit (Portal-ID) — Schluessel fuer den Chat.
  final String favKey;
  final String label;
  final CalendarEvent event;

  /// Teilnehmerzahl laut Portal, -1 wenn unbekannt.
  final int attendees;

  const MyMeetupDate({
    required this.favKey,
    required this.label,
    required this.event,
    this.attendees = -1,
  });
}

class MyEventsScreen extends StatefulWidget {
  /// Zugesagte Veranstaltungen, bereits nach Datum sortiert.
  final List<NostrCalendarEvent> events;

  /// Naechste Termine der Favoriten-Meetups.
  final List<MyMeetupDate> meetupDates;

  /// Oeffnet den Chatraum eines Meetups. Kommt von aussen, weil die Suche
  /// ueber das Gruppen-Relay laeuft und das Dashboard sie ohnehin kennt.
  final Future<void> Function(String favKey, String label) onOpenMeetupChat;

  /// Meldet dem Dashboard, dass sich die Zusagen geaendert haben — dieser
  /// Bildschirm bekommt seine Liste von dort und kann sie nicht selbst
  /// nachladen.
  final VoidCallback onChanged;

  const MyEventsScreen({
    super.key,
    required this.events,
    required this.meetupDates,
    required this.onOpenMeetupChat,
    required this.onChanged,
  });

  @override
  State<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends State<MyEventsScreen> {
  Map<String, int> _unread = {};

  /// Eigene, veraenderbare Kopie der Liste.
  ///
  /// Die uebergebene Liste gehoert dem Dashboard. Nach einer Absage soll der
  /// Termin SOFORT verschwinden — ohne dass dieser Bildschirm geschlossen und
  /// neu aufgebaut werden muss. Deshalb eine eigene Kopie, die hier gepflegt
  /// wird; das Dashboard erfaehrt es ueber onChanged und laedt fuer sich neu.
  late List<NostrCalendarEvent> _events;

  @override
  void initState() {
    super.initState();
    _events = List.of(widget.events);
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (_events.isEmpty) return;
    final counts = await EventChatService.unreadCounts(
        _events.map((e) => e.address).toList());
    if (mounted) setState(() => _unread = counts);
  }

  @override
  void didUpdateWidget(MyEventsScreen old) {
    super.didUpdateWidget(old);
    // Kommt eine neue Liste von aussen, uebernehmen — sonst zeigte dieser
    // Bildschirm nach einem Neuladen des Dashboards weiter den alten Stand.
    if (!identical(old.events, widget.events)) {
      _events = List.of(widget.events);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.eventChatsTitle,
            style: const TextStyle(
                color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      // Ziehen zum Aktualisieren — hier holt es die ungelesenen Beitraege
      // neu. Auch ueber dem Leer-Hinweis, denn gerade dort will man es
      // versuchen.
      body: RefreshIndicator(
        onRefresh: _loadUnread,
        color: cOrange,
        backgroundColor: cCard,
        child: _events.isEmpty && widget.meetupDates.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.eventChatsEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: cTextTertiary, fontSize: 14, height: 1.55)),
              ),
                  ),
                ),
              ],
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Meetups zuerst: Das sind die regelmaessigen Termine, zu
                // denen man ohnehin geht. Veranstaltungen sind die Ausnahme
                // und stehen darunter.
                if (widget.meetupDates.isNotEmpty) ...[
                  _sectionLabel(t.eventChatsMeetups),
                  ...widget.meetupDates.map((m) => _meetupCard(t, m)),
                ],
                if (_events.isNotEmpty) ...[
                  _sectionLabel(t.eventChatsEvents),
                  ..._events.map((e) => _card(t, e)),
                ],
              ],
            ),
      ),
    );
  }

  /// Fragt nach, bevor die Zusage zurueckgenommen wird.
  Future<void> _confirmWithdraw(
      AppLocalizations t, NostrCalendarEvent event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: cTileBorder, width: 0.5)),
        title: Text(t.rsvpWithdrawTitle,
            style: const TextStyle(
                color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
        content: Text(t.rsvpWithdrawBody(event.title),
            style: const TextStyle(
                color: cTextSecondary, fontSize: 14, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.actionCancel,
                style: const TextStyle(color: cTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.rsvpWithdrawConfirm,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // "declined" statt loeschen: Nostr kennt kein Loeschen, nur Ersetzen.
    // Eine Absage ist ohnehin die ehrlichere Auskunft an den Veranstalter
    // als ein spurloses Verschwinden.
    final err = await EventRsvpService.setStatus(
      eventAddress: event.address,
      eventAuthorPubkey: event.pubkey,
      status: RsvpStatus.declined,
    );
    if (!mounted) return;
    if (err != null) {
      messenger.showSnackBar(SnackBar(
          content: Text(t.rsvpFailed(err)), backgroundColor: cRed));
      return;
    }
    // Aus der eigenen Liste nehmen statt den Bildschirm zu schliessen.
    //
    // Vorher wurde hier zurueckgesprungen — das ergab ein schwarzes Bild,
    // weil zugleich das Dashboard neu lud und die Route darunter wegzog. Und
    // es war auch als Bedienung falsch: Wer zwei Termine absagen will,
    // muesste den Bildschirm zweimal oeffnen.
    setState(() => _events.removeWhere((e) => e.address == event.address));
    widget.onChanged();
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 10),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: cTextTertiary,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800)),
      );

  /// Ein Meetup-Termin, fuer den man im Portal zugesagt hat.
  Widget _meetupCard(AppLocalizations t, MyMeetupDate m) {
    final d = m.event.startTime;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: cText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Row(children: [
                    const Icon(Icons.event_rounded,
                        color: cTextTertiary, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                          '${d.day}.${d.month}.${d.year} · '
                          '${d.hour.toString().padLeft(2, '0')}:'
                          '${d.minute.toString().padLeft(2, '0')}'
                          // Teilnehmerzahl nur, wenn das Portal sie kennt —
                          // "0 Teilnehmer" bei fehlender Angabe waere eine
                          // falsche Auskunft.
                          '${m.attendees >= 0 ? ' · ${t.rsvpAttendees(m.attendees)}' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: cTextTertiary, fontSize: 12)),
                    ),
                  ]),
                ]),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => widget.onOpenMeetupChat(m.favKey, m.label),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: cNostr.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.forum_rounded, color: cNostr, size: 19),
            ),
          ),
          IconButton(
            tooltip: 'Bitcoin P2P Matchmaker (Beispiel)',
            icon: const Icon(Icons.currency_bitcoin, color: cOrange),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => P2pMatchScreen(
                eventAddress: m.event.portalEventId != null
                    ? 'portal-event:${m.event.portalEventId}'
                    : 'meetup:${m.favKey}:${m.event.startTime.toUtc().millisecondsSinceEpoch ~/ 1000}',
                eventTitle: m.label,
                eventStart: m.event.startTime,
              ),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _card(AppLocalizations t, NostrCalendarEvent event) {
    final unread = _unread[event.address] ?? 0;
    final days = event.start.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        // Langdruck: Zusage zuruecknehmen. Damit verschwindet der Termin aus
        // dieser Liste — er ist der einzige Grund, warum er hier steht.
        //
        // Kein Wisch-Loeschen: Ein Wisch ist eine schnelle Bewegung, und die
        // Zusage ist eine Aussage gegenueber dem Veranstalter. Sie soll man
        // nicht im Vorbeigehen zuruecknehmen.
        onLongPress: () => _confirmWithdraw(t, event),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen.event(
                eventAddress: event.address,
                eventAuthor: event.pubkey,
                title: event.title,
              ),
            ),
          );
          // Zurueck aus dem Chat: Der Lesestand hat sich geaendert, also neu
          // zaehlen — sonst bliebe der Punkt stehen.
          if (mounted) _loadUnread();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(kTileRadius),
            border: Border.all(
                color: unread > 0
                    ? cNostr.withValues(alpha: 0.5)
                    : cTileBorder,
                width: 0.5),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: cText,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            height: 1.25)),
                    const SizedBox(height: 5),
                    Row(children: [
                      Icon(Icons.event_rounded,
                          color: days <= 0
                              ? cOrange
                              : days <= 3
                                  ? cOrange.withValues(alpha: 0.8)
                                  : cTextTertiary,
                          size: 13),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                            '${event.start.day}.${event.start.month}.${event.start.year}'
                            '${event.location.isEmpty ? '' : ' · ${event.location}'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: cTextTertiary, fontSize: 12)),
                      ),
                    ]),
                  ]),
            ),
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Bitcoin P2P Matchmaker (Beispiel)',
              icon: const Icon(Icons.currency_bitcoin, color: cOrange),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => P2pMatchScreen(
                  eventAddress: event.address,
                  eventTitle: event.title,
                  eventStart: event.start,
                ),
              )),
            ),
            // Die Sprechblase traegt den Zaehler. Ohne Neues bleibt sie
            // blass — sichtbar genug, um den Weg zu zeigen, ruhig genug, um
            // nicht nach Aufmerksamkeit zu rufen.
            Stack(clipBehavior: Clip.none, children: [
              Icon(Icons.forum_rounded,
                  color: unread > 0 ? cNostr : cTextTertiary, size: 22),
              if (unread > 0)
                Positioned(
                  right: -6,
                  top: -5,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 14),
                    decoration: BoxDecoration(
                      color: cOrange,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(unread > 99 ? '99+' : '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            height: 1.3)),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
