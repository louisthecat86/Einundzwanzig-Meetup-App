// NEWS-SCREEN — Einundzwanzig Artikel lesen
// ============================================
// Eine schlanke Ansicht:
//   - Button: media.einundzwanzig.space im Browser öffnen.
//   - Darunter: Liste der NIP-23-Artikel (kind 30023) von den Relays,
//     voll lesbar in der App (Markdown gerendert), im App-Design.
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../l10n/app_localizations.dart';
import '../services/news_reactions_service.dart';
import '../services/news_service.dart';
import '../services/news_zap_service.dart';
import '../widgets/markdown_view.dart';
import '../utils/share_origin.dart';

const String _websiteUrl = 'https://media.einundzwanzig.space/s/einundzwanzig-news';

/// Ziel des "Artikel schreiben"-Knopfes. Bewusst die Startseite: Von dort
/// fuehrt die Oberflaeche selbst zum Schreiben, und ein tieferer Link wuerde
/// bei jeder Aenderung an der Webseite ins Leere zeigen.
const String _writeUrl = 'https://media.einundzwanzig.space';

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Oeffentliche Adresse eines Artikels — fuer Teilen und "im Browser lesen".
///
/// Achtung: NewsArticle.link faellt auf die guid zurueck, wenn der RSS-Feed
/// kein `<link>` mitliefert — und die guid ist `30023:<pubkey>:<d>`, also
/// KEINE URL. Frueher wurde die an die Webseitenadresse angehaengt und
/// ergab einen toten Link. Deshalb hier: nur echte http(s)-Adressen
/// verwenden, sonst die Uebersichtsseite.
String _articleUrl(NewsArticle a) {
  final link = a.link.trim();
  if (link.startsWith('http://') || link.startsWith('https://')) return link;
  return kNewsWebsiteUrl;
}

/// Wandelt einen Hex-Pubkey sicher in eine kurze npub-Anzeige um.
String _authorLabel(String author) {
  // Aus dem RSS-Feed kommt der Autor-NAME direkt (nicht mehr ein Hex-Pubkey).
  if (author.isEmpty) return 'Einundzwanzig';
  return author;
}

Future<void> _openWebsite() async {
  final uri = Uri.parse(_websiteUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<NewsArticle> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await NewsService.fetchArticles();
    if (!mounted) return;
    setState(() { _articles = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(t.newsTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: cOrange,
        backgroundColor: cCard,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _actionTiles(t),
            const SizedBox(height: 16),
            if (_loading)
              _loadingState(t)
            else if (_articles.isEmpty)
              _emptyState(t)
            else
              ..._articles.map(_articleCard),
            const SizedBox(height: 8),
            Center(child: Text(t.newsSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Die beiden Wege nach media.einundzwanzig.space: schreiben und lesen.
  ///
  /// Nebeneinander und gleich breit, damit keiner wichtiger aussieht als der
  /// andere. IntrinsicHeight haelt beide auf derselben Hoehe, auch wenn eine
  /// Beschriftung zweizeilig umbricht.
  Widget _actionTiles(AppLocalizations t) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _actionTile(
            icon: Icons.edit_note_rounded,
            label: t.newsWriteArticle,
            onTap: () => _openUrl(_writeUrl),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionTile(
            icon: Icons.public_rounded,
            label: t.newsOpenWebsite,
            onTap: _openWebsite,
          ),
        ),
      ],
    ),
  );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2A1E0A), cCard],
            ),
            borderRadius: BorderRadius.circular(kTileRadius),
            border:
                Border.all(color: cOrange.withValues(alpha: 0.4), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: cOrange, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    color: cText, fontSize: 14, fontWeight: FontWeight.w700,
                    height: 1.25),
              ),
              const SizedBox(height: 2),
              const Text('media.einundzwanzig.space',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cTextTertiary, fontSize: 11)),
            ],
          ),
        ),
      );

  Widget _loadingState(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const CircularProgressIndicator(color: cOrange),
      const SizedBox(height: 14),
      Text(t.newsLoading, style: const TextStyle(color: cTextSecondary, fontSize: 13)),
    ]),
  );

  Widget _emptyState(AppLocalizations t) => Padding(
    padding: const EdgeInsets.only(top: 60),
    child: Column(children: [
      const Icon(Icons.article_outlined, color: cTextTertiary, size: 44),
      const SizedBox(height: 12),
      Text(t.newsEmpty, style: const TextStyle(color: cTextSecondary, fontSize: 14)),
    ]),
  );

  Widget _articleCard(NewsArticle a) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _ArticleDetail(article: a))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: cCard,
          borderRadius: BorderRadius.circular(kTileRadius),
          border: Border.all(color: cTileBorder, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (a.image.isNotEmpty)
            Image.network(
              a.image, height: 150, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
              loadingBuilder: (ctx, child, p) => p == null ? child : Container(height: 150, color: cSurface),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: const TextStyle(color: cText, fontSize: 16, fontWeight: FontWeight.w800, height: 1.3)),
              if (a.summary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(a.summary, maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: cTextSecondary, fontSize: 13, height: 1.5)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.person_outline_rounded, color: cTextTertiary, size: 13),
                const SizedBox(width: 4),
                Text(_authorLabel(a.pubkey), style: const TextStyle(color: cTextTertiary, fontSize: 11)),
                const Spacer(),
                Text('${a.date.day}.${a.date.month}.${a.date.year}', style: const TextStyle(color: cTextTertiary, fontSize: 11)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================================
//  ARTIKEL-DETAIL (voll lesbar, Markdown)
// ============================================
class _ArticleDetail extends StatefulWidget {
  final NewsArticle article;
  const _ArticleDetail({required this.article});

  @override
  State<_ArticleDetail> createState() => _ArticleDetailState();
}

class _ArticleDetailState extends State<_ArticleDetail> {
  String? _fullContent; // voller Markdown-Text aus dem Nostr-Event
  bool _loading = true;

  ArticleLikes _likes = ArticleLikes.empty;
  bool _likesLoaded = false;
  bool _liking = false;
  bool _zapping = false;

  /// Hex-Pubkey des Autors. NewsArticle.pubkey traegt den ANZEIGENAMEN aus
  /// dem RSS-Feed, nicht den Schluessel — der steckt in der guid
  /// `30023:<pubkey>:<d>`.
  String get _authorPubkey {
    final parts = widget.article.id.split(':');
    return parts.length >= 2 ? parts[1] : '';
  }

  @override
  void initState() {
    super.initState();
    _loadFullArticle();
    // Erst der Merkzettel (Millisekunden), dann die Relays (Sekunden).
    // So steht das Herz sofort richtig, statt bis zur Netzantwort leer
    // auszusehen — genau das verleitet zum zweiten Druck.
    _loadLocalLike();
    _loadLikes();
  }

  Future<void> _loadLocalLike() async {
    final liked =
        await NewsReactionsService.hasLikedLocally(widget.article.id);
    if (!mounted || !liked) return;
    setState(() {
      // Zahl bleibt offen, bis die Relays antworten — nur der Zustand des
      // eigenen Herzens ist hier schon sicher.
      _likes = ArticleLikes(count: _likes.count, mine: true);
    });
  }

  Future<void> _loadLikes() async {
    final likes = await NewsReactionsService.fetchLikes(widget.article.id);
    if (!mounted) return;
    setState(() {
      _likes = likes;
      _likesLoaded = true;
    });
  }

  Future<void> _toggleLike() async {
    // NIP-25 kennt kein Zuruecknehmen ausser ueber eine Loeschanfrage. Ein
    // bereits gesetztes Herz bleibt deshalb stehen, statt so zu tun, als
    // liesse es sich abwaehlen.
    if (_likes.mine || _liking) return;

    final messenger = ScaffoldMessenger.of(context);
    final t = AppLocalizations.of(context);
    setState(() => _liking = true);

    final ok = await NewsReactionsService.like(
      articleAddress: widget.article.id,
      authorPubkey: _authorPubkey,
    );

    if (!mounted) return;
    setState(() {
      _liking = false;
      if (ok) _likes = _likes.withMine();
    });
    if (!ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(t.newsLikeFailed),
        backgroundColor: cRed,
      ));
    }
  }

  // ---------------------------------------------------------------
  // ZAP
  // ---------------------------------------------------------------

  /// Betragsauswahl. Die Stufen folgen der 21 — das ist hier keine Spielerei,
  /// sondern spart dem Nutzer die Zifferneingabe fuer den Normalfall.
  static const List<int> _zapAmounts = [21, 210, 2100, 21000];

  Future<void> _zap() async {
    final t = AppLocalizations.of(context);
    final amount = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.newsZapTitle,
                  style: const TextStyle(
                      color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(t.newsZapBody,
                  style: const TextStyle(
                      color: cTextSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _zapAmounts
                    .map((sats) => OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext, sats),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: cOrange),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                          child: Text('$sats sat',
                              style: const TextStyle(
                                  color: cOrange,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700)),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (amount == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _zapping = true);

    final result = await NewsZapService.createZapInvoice(
      authorPubkey: _authorPubkey,
      articleAddress: widget.article.id,
      amountSats: amount,
      comment: widget.article.title,
    );

    if (!mounted) return;
    setState(() => _zapping = false);

    if (!result.ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(_zapErrorText(t, result.error)),
        backgroundColor: cRed,
      ));
      return;
    }

    // lightning:-URI: Android blendet von sich aus die Auswahl ALLER
    // installierten Wallets ein, die das Schema behandeln. Eine eigene
    // Liste zu bauen waere sowohl unvollstaendig als auch ueberfluessig.
    final opened = await _openInvoice(result.invoice!);
    if (!mounted) return;
    if (!opened) _showInvoiceFallback(t, result.invoice!);
  }

  Future<bool> _openInvoice(String invoice) async {
    final uri = Uri.parse('lightning:$invoice');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Keine Wallet gefunden: Rechnung zum Kopieren zeigen, statt den Nutzer
  /// mit einer wirkungslosen Meldung stehen zu lassen.
  void _showInvoiceFallback(AppLocalizations t, String invoice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.newsZapNoWallet,
                  style: const TextStyle(
                      color: cText, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(invoice,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: cTextSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace')),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invoice));
                    Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.copy_rounded,
                      size: 18, color: Colors.black),
                  style: ElevatedButton.styleFrom(backgroundColor: cOrange),
                  label: Text(t.newsZapCopyInvoice,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _zapErrorText(AppLocalizations t, ZapError? error) =>
      switch (error) {
        ZapError.noLightningAddress => t.newsZapNoAddress,
        ZapError.unsupportedAddress => t.newsZapUnsupportedAddress,
        ZapError.amountOutOfRange => t.newsZapAmountRange,
        _ => t.newsZapFailed,
      };

  Future<void> _share(BuildContext anchor) async {
    final a = widget.article;
    final text = '${a.title}\n\n${_articleUrl(a)}';
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Share.share(text, sharePositionOrigin: shareOriginFor(anchor));
    } catch (_) {
      // Teilen fehlgeschlagen: zumindest den Link retten.
      await Clipboard.setData(ClipboardData(text: text));
      messenger.showSnackBar(SnackBar(
          content: Text(t.newsShareCopied), backgroundColor: cOrange));
    }
  }

  /// Teilen und Herz. Steht unter dem Artikel, weil beides erst nach dem
  /// Lesen sinnvoll ist.
  Widget _actionBar(AppLocalizations t) {
    final liked = _likes.mine;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _liking ? null : _toggleLike,
            icon: _liking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cOrange))
                : Icon(liked ? Icons.favorite_rounded
                             : Icons.favorite_border_rounded,
                    size: 18, color: liked ? cOrange : cTextSecondary),
            label: Text(
              // Solange nicht geladen: nur das Symbol, keine falsche Null.
              _likesLoaded && _likes.count > 0
                  ? '${_likes.count}'
                  : t.newsLike,
              style: TextStyle(
                  color: liked ? cOrange : cTextSecondary, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: liked ? cOrange : cBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _zapping ? null : _zap,
            icon: _zapping
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cOrange))
                : const Icon(Icons.bolt_rounded, size: 18, color: cOrange),
            label: Text(t.newsZap,
                style: const TextStyle(color: cOrange, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: cOrange.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Builder(builder: (btnCtx) => OutlinedButton.icon(
            onPressed: () => _share(btnCtx),
            icon: const Icon(Icons.ios_share_rounded,
                size: 18, color: cTextSecondary),
            label: Text(t.newsShare,
                style: const TextStyle(color: cTextSecondary, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: cBorder),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          )),
        ),
      ],
    );
  }

  Future<void> _loadFullArticle() async {
    // Die guid steht in article.id ("30023:pubkey:d"). Voller Text via Nostr.
    final guid = widget.article.id;
    final content = await NewsService.fetchArticleContent(guid);
    if (!mounted) return;
    setState(() {
      _fullContent = content;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final article = widget.article;
    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark, elevation: 0,
        title: Text(t.newsTitle, style: const TextStyle(color: cText, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (article.image.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(kTileRadius),
              child: Image.network(article.image, fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
            const SizedBox(height: 18),
          ],
          Text(article.title, style: const TextStyle(color: cText, fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.person_outline_rounded, color: cTextTertiary, size: 14),
            const SizedBox(width: 5),
            Text(_authorLabel(article.pubkey), style: const TextStyle(color: cTextTertiary, fontSize: 12)),
            const SizedBox(width: 12),
            Text('${article.date.day}.${article.date.month}.${article.date.year}',
                style: const TextStyle(color: cTextTertiary, fontSize: 12)),
          ]),
          const SizedBox(height: 20),
          // Voller Artikel aus dem Nostr-Event (Markdown). Solange er lädt:
          // Zusammenfassung + Ladeindikator. Kommt nichts: Zusammenfassung.
          if (_loading) ...[
            if (article.summary.isNotEmpty)
              Text(article.summary, style: const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator(color: cOrange)),
          ] else if (_fullContent != null && _fullContent!.trim().isNotEmpty)
            _SafeArticleBody(content: _fullContent!)
          else ...[
            // Fallback: kein Volltext ladbar -> Zusammenfassung + Web-Link
            if (article.summary.isNotEmpty)
              Text(article.summary, style: const TextStyle(color: cTextSecondary, fontSize: 15, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _openUrl(_articleUrl(article)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: cOrange, borderRadius: BorderRadius.circular(kTileRadius)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.open_in_new_rounded, color: Colors.black, size: 18),
                  SizedBox(width: 8),
                  Text('Auf der Webseite lesen', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _actionBar(t),
          const SizedBox(height: 20),
          Center(child: Text(t.newsSource, style: const TextStyle(color: cTextTertiary, fontSize: 11))),
        ],
      ),
    );
  }
}

/// Rendert den Artikel-Body und fängt JEDEN Render-Fehler ab: Statt eines
/// App-Absturzes wird bei einem problematischen Artikel der reine Text
/// angezeigt. So kann ein einzelner Artikel die App nie zum Absturz bringen.
class _SafeArticleBody extends StatelessWidget {
  final String content;
  const _SafeArticleBody({required this.content});

  @override
  Widget build(BuildContext context) {
    // Lokaler Error-Handler nur für diesen Teilbaum.
    final previous = ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SelectableText(
          content,
          style: const TextStyle(color: cText, fontSize: 15, height: 1.6),
        ),
      );
    };
    // Nach dem Frame den globalen Handler wiederherstellen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ErrorWidget.builder = previous;
    });
    return MarkdownView(content);
  }
}
