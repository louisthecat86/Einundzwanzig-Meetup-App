// GLOSSAR — SELBSTHILFE IN DER APP
// ============================================
// Die App hat inzwischen genug Eigenheiten, die man nirgends nachschlagen
// kann: Warum ein Badge nur vor Ort geht, was der Trust Score zaehlt,
// wofuer der nsec da ist. Die Tour zeigt das einmal — wer sie weggetippt
// hat oder drei Wochen spaeter fragt, stand bisher ohne da.
//
// Aufbau bewusst DATENGETRIEBEN: Die Eintraege stehen als Liste, die
// Oberflaeche baut sich daraus. Ein neuer Eintrag ist eine Zeile plus drei
// Sprachschluessel — kein Layout, keine neue Karte, kein Copy-Paste.
// ============================================

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme.dart';

/// Bereiche des Glossars. Die Reihenfolge hier ist die Reihenfolge auf dem
/// Bildschirm — von "was ist das hier" bis zu den Feinheiten.
enum GlossaryCategory {
  start,
  badges,
  reputation,
  network,
  identity,
  events,
  nostr,
  voice,
  app,
}

class GlossaryEntry {
  final GlossaryCategory category;
  final String title;
  final String body;

  const GlossaryEntry(this.category, this.title, this.body);
}

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Alle Eintraege. Die Texte kommen aus den Sprachdateien, damit das
  /// Glossar in jeder Sprache vollstaendig ist statt halb uebersetzt.
  List<GlossaryEntry> _entries(AppLocalizations t) => [
    // --- Erste Schritte ---
    GlossaryEntry(
      GlossaryCategory.start,
      t.glWhatIsAppTitle,
      t.glWhatIsAppBody,
    ),
    GlossaryEntry(GlossaryCategory.start, t.glCollectTitle, t.glCollectBody),
    GlossaryEntry(
      GlossaryCategory.start,
      t.glHomeMeetupTitle,
      t.glHomeMeetupBody,
    ),
    GlossaryEntry(GlossaryCategory.start, t.glNicknameTitle, t.glNicknameBody),
    GlossaryEntry(
      GlossaryCategory.start,
      t.glFindMeetupTitle,
      t.glFindMeetupBody,
    ),
    GlossaryEntry(GlossaryCategory.start, t.glOfflineTitle, t.glOfflineBody),

    // --- Badges ---
    GlossaryEntry(
      GlossaryCategory.badges,
      t.glBadgeProofTitle,
      t.glBadgeProofBody,
    ),
    GlossaryEntry(
      GlossaryCategory.badges,
      t.glRollingQrTitle,
      t.glRollingQrBody,
    ),
    GlossaryEntry(GlossaryCategory.badges, t.glOnSiteTitle, t.glOnSiteBody),
    GlossaryEntry(
      GlossaryCategory.badges,
      t.glBlockHeightTitle,
      t.glBlockHeightBody,
    ),
    GlossaryEntry(GlossaryCategory.badges, t.glChecksumTitle, t.glChecksumBody),
    GlossaryEntry(
      GlossaryCategory.badges,
      t.glDuplicateTitle,
      t.glDuplicateBody,
    ),
    GlossaryEntry(
      GlossaryCategory.badges,
      t.glBadgeShareTitle,
      t.glBadgeShareBody,
    ),
    GlossaryEntry(GlossaryCategory.badges, t.glWorldMapTitle, t.glWorldMapBody),

    // --- Reputation ---
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glTrustScoreTitle,
      t.glTrustScoreBody,
    ),
    GlossaryEntry(GlossaryCategory.reputation, t.glLevelsTitle, t.glLevelsBody),
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glHumanityTitle,
      t.glHumanityBody,
    ),
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glPlatformsTitle,
      t.glPlatformsBody,
    ),
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glPublishTitle,
      t.glPublishBody,
    ),
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glVerifyPersonTitle,
      t.glVerifyPersonBody,
    ),
    GlossaryEntry(
      GlossaryCategory.reputation,
      t.glRepCardTitle,
      t.glRepCardBody,
    ),

    // --- Vertrauensnetzwerk ---
    GlossaryEntry(
      GlossaryCategory.network,
      t.glEncounterTitle,
      t.glEncounterBody,
    ),
    GlossaryEntry(GlossaryCategory.network, t.glDegreesTitle, t.glDegreesBody),
    GlossaryEntry(GlossaryCategory.network, t.glVouchTitle, t.glVouchBody),
    GlossaryEntry(
      GlossaryCategory.network,
      t.glTrustPathTitle,
      t.glTrustPathBody,
    ),
    GlossaryEntry(
      GlossaryCategory.network,
      t.glEventNetTitle,
      t.glEventNetBody,
    ),
    GlossaryEntry(
      GlossaryCategory.network,
      t.glDistrustTitle,
      t.glDistrustBody,
    ),
    GlossaryEntry(
      GlossaryCategory.network,
      t.glOrganizerTitle,
      t.glOrganizerBody,
    ),

    // --- Identitaet & Schluessel ---
    GlossaryEntry(GlossaryCategory.identity, t.glKeysTitle, t.glKeysBody),
    GlossaryEntry(
      GlossaryCategory.identity,
      t.glFindKeysTitle,
      t.glFindKeysBody,
    ),
    GlossaryEntry(
      GlossaryCategory.identity,
      t.glPasswordTitle,
      t.glPasswordBody,
    ),
    GlossaryEntry(GlossaryCategory.identity, t.glSignerTitle, t.glSignerBody),
    GlossaryEntry(
      GlossaryCategory.identity,
      t.glNcryptsecTitle,
      t.glNcryptsecBody,
    ),
    GlossaryEntry(GlossaryCategory.identity, t.glPasskeyTitle, t.glPasskeyBody),
    GlossaryEntry(GlossaryCategory.identity, t.glNip05Title, t.glNip05Body),
    GlossaryEntry(GlossaryCategory.identity, t.glImportTitle, t.glImportBody),
    GlossaryEntry(GlossaryCategory.identity, t.glBackupTitle, t.glBackupBody),
    GlossaryEntry(GlossaryCategory.identity, t.glRestoreTitle, t.glRestoreBody),

    // --- Events ---
    GlossaryEntry(
      GlossaryCategory.events,
      t.glCalendarSourcesTitle,
      t.glCalendarSourcesBody,
    ),
    GlossaryEntry(
      GlossaryCategory.events,
      t.glCreateEventTitle,
      t.glCreateEventBody,
    ),
    GlossaryEntry(GlossaryCategory.events, t.glPortalTitle, t.glPortalBody),
    GlossaryEntry(
      GlossaryCategory.events,
      t.glSpecialEventTitle,
      t.glSpecialEventBody,
    ),
    GlossaryEntry(
      GlossaryCategory.events,
      t.glEventHelperTitle,
      t.glEventHelperBody,
    ),
    GlossaryEntry(
      GlossaryCategory.events,
      t.glEventWindowTitle,
      t.glEventWindowBody,
    ),

    // --- Nostr ---
    GlossaryEntry(
      GlossaryCategory.nostr,
      t.glNostrBasicsTitle,
      t.glNostrBasicsBody,
    ),
    GlossaryEntry(GlossaryCategory.nostr, t.glRelaysTitle, t.glRelaysBody),
    GlossaryEntry(GlossaryCategory.nostr, t.glPublicTitle, t.glPublicBody),
    GlossaryEntry(GlossaryCategory.nostr, t.glZapTitle, t.glZapBody),
    GlossaryEntry(GlossaryCategory.nostr, t.glNewsTitle, t.glNewsBody),
    GlossaryEntry(
      GlossaryCategory.nostr,
      t.glCommunityTitle,
      t.glCommunityBody,
    ),
    GlossaryEntry(
      GlossaryCategory.nostr,
      t.glConverterTitle,
      t.glConverterBody,
    ),

    // --- Sprach Wallet ---
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceIntroTitle,
      t.glVoiceIntroBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceBalanceTitle,
      t.glVoiceBalanceBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceScanTitle,
      t.glVoiceScanBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoicePasteTitle,
      t.glVoicePasteBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceGalleryTitle,
      t.glVoiceGalleryBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceSendTitle,
      t.glVoiceSendBody,
    ),
    GlossaryEntry(GlossaryCategory.voice, t.glVoiceYesTitle, t.glVoiceYesBody),
    GlossaryEntry(GlossaryCategory.voice, t.glVoiceNoTitle, t.glVoiceNoBody),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceHelpTitle,
      t.glVoiceHelpBody,
    ),
    GlossaryEntry(
      GlossaryCategory.voice,
      t.glVoiceOutputTitle,
      t.glVoiceOutputBody,
    ),

    // --- App & Bedienung ---
    GlossaryEntry(GlossaryCategory.app, t.glTilesTitle, t.glTilesBody),
    GlossaryEntry(GlossaryCategory.app, t.glLanguageTitle, t.glLanguageBody),
    GlossaryEntry(GlossaryCategory.app, t.glLogTitle, t.glLogBody),
    GlossaryEntry(GlossaryCategory.app, t.glResetTitle, t.glResetBody),
  ];

  String _categoryLabel(AppLocalizations t, GlossaryCategory c) => switch (c) {
    GlossaryCategory.start => t.glCatStart,
    GlossaryCategory.badges => t.glCatBadges,
    GlossaryCategory.reputation => t.glCatReputation,
    GlossaryCategory.network => t.glCatNetwork,
    GlossaryCategory.identity => t.glCatIdentity,
    GlossaryCategory.events => t.glCatEvents,
    GlossaryCategory.nostr => t.glCatNostr,
    GlossaryCategory.voice => t.glCatVoice,
    GlossaryCategory.app => t.glCatApp,
  };

  IconData _categoryIcon(GlossaryCategory c) => switch (c) {
    GlossaryCategory.start => Icons.flag_rounded,
    GlossaryCategory.badges => Icons.military_tech_rounded,
    GlossaryCategory.reputation => Icons.workspace_premium_rounded,
    GlossaryCategory.network => Icons.hub_rounded,
    GlossaryCategory.identity => Icons.key_rounded,
    GlossaryCategory.events => Icons.celebration_rounded,
    GlossaryCategory.nostr => Icons.bolt_rounded,
    GlossaryCategory.voice => Icons.mic_rounded,
    GlossaryCategory.app => Icons.tune_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final q = _query.trim().toLowerCase();

    // Gesucht wird in Titel UND Text: Wer "Zap" eintippt, findet den
    // Eintrag auch dann, wenn das Wort nur im Fliesstext vorkommt.
    final all = _entries(t);
    final hits = q.isEmpty
        ? all
        : all
              .where(
                (e) =>
                    e.title.toLowerCase().contains(q) ||
                    e.body.toLowerCase().contains(q),
              )
              .toList();

    return Scaffold(
      backgroundColor: cDark,
      appBar: AppBar(
        backgroundColor: cDark,
        elevation: 0,
        title: Text(
          t.glTitle,
          style: const TextStyle(
            color: cText,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: cText, fontSize: 15),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: t.glSearchHint,
                hintStyle: const TextStyle(color: cTextTertiary, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: cTextSecondary,
                  size: 20,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: cTextSecondary,
                          size: 18,
                        ),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _query = '';
                        }),
                      ),
                filled: true,
                fillColor: cCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kTileRadius),
                  borderSide: const BorderSide(color: cTileBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kTileRadius),
                  borderSide: const BorderSide(color: cTileBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(kTileRadius),
                  borderSide: const BorderSide(color: cOrange, width: 1.4),
                ),
              ),
            ),
          ),
          Expanded(
            child: hits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        t.glNoResults,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: cTextTertiary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      for (final c in GlossaryCategory.values)
                        if (hits.any((e) => e.category == c)) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcon(c),
                                  color: cOrange,
                                  size: 15,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _categoryLabel(t, c).toUpperCase(),
                                  style: const TextStyle(
                                    color: cOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final e in hits.where((e) => e.category == c))
                            _entryTile(e),
                        ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Ein Eintrag, aufklappbar.
  ///
  /// Zugeklappt, damit die Liste als UEBERSICHT taugt — fuenfundzwanzig
  /// ausgeklappte Absaetze waeren wieder nur eine Textwand. Bei aktiver
  /// Suche steht der Treffer sofort offen; wer sucht, will lesen und nicht
  /// noch einmal tippen.
  Widget _entryTile(GlossaryEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(kTileRadius),
        border: Border.all(color: cTileBorder, width: 0.5),
      ),
      child: Theme(
        // Ohne das zeichnet ExpansionTile die Standard-Trennlinien in
        // Materialgrau quer ueber die Karte.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey(e.title),
          initiallyExpanded: _query.trim().isNotEmpty,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: cOrange,
          collapsedIconColor: cTextTertiary,
          title: Text(
            e.title,
            style: const TextStyle(
              color: cText,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                e.body,
                style: const TextStyle(
                  color: cTextSecondary,
                  fontSize: 13.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
