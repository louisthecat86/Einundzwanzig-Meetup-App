// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Home';

  @override
  String get navWallet => 'Badges';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profil';

  @override
  String get actionSave => 'Speichern';

  @override
  String get actionCancel => 'Abbrechen';

  @override
  String get actionConfirm => 'Bestätigen';

  @override
  String get actionDelete => 'Löschen';

  @override
  String get actionContinue => 'Weiter';

  @override
  String get actionBack => 'Zurück';

  @override
  String get actionClose => 'Schließen';

  @override
  String get actionRetry => 'Erneut versuchen';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Verstanden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get reputation => 'Reputation';

  @override
  String get reputationShareQr => 'QR teilen';

  @override
  String get community => 'Community';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Home Meetup';

  @override
  String get shoutout => 'Shoutout';

  @override
  String get joinCommunity => 'Community betreten';

  @override
  String get identityVerified => 'Verifiziert';

  @override
  String get verifiedByAdmin => 'Verifiziert durch Admin';

  @override
  String get nostrVerified => 'Nostr verifiziert';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileChooseHomeMeetup => 'Wähle dein Home-Meetup';

  @override
  String get profileYourIdentity => 'Deine Identität';

  @override
  String get profileNostrKey => 'NOSTR SCHLÜSSEL';

  @override
  String get profileKeyActive => 'Schlüssel aktiv';

  @override
  String get requiredField => 'Pflichtfeld — bitte ausfüllen';

  @override
  String get requiredHomeMeetup => 'Pflichtfeld — bitte wähle dein Home-Meetup';

  @override
  String fillRequired(String fields) {
    return 'Bitte ausfüllen: $fields';
  }

  @override
  String get identityGenerateKey => 'Neuen Schlüssel erstellen';

  @override
  String get identityConnectAmber => 'Mit Amber verbinden';

  @override
  String get identityImportNsec => 'Bestehenden nsec importieren';

  @override
  String get amberConnected =>
      'Mit Amber verbunden! Dein nsec bleibt in Amber.';

  @override
  String get amberNotFound => 'Amber nicht gefunden';

  @override
  String get amberCancelled => 'Verbindung in Amber abgebrochen.';

  @override
  String get walletTitle => 'Meine Badges';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Badges',
      one: '1 Badge',
      zero: 'Keine Badges',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: '1 Tag',
      zero: 'heute',
    );
    return 'in $_temp0';
  }

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputation';

  @override
  String get tileReputationShare => 'QR teilen';

  @override
  String get tileReputationCheck => 'Prüfen';

  @override
  String get tileCommunity => 'Community';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Events';

  @override
  String get tileEventsCalendar => 'Kalender';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Senden';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Anhören';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Community';

  @override
  String get tileOrganizer => 'Organisator';

  @override
  String get tileOrganizerPanel => 'Admin-Panel';

  @override
  String get tileOrganizerNew => 'Neu via Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'HOME MEETUP';

  @override
  String get homeMeetupChoose => 'Wähle deinen Stammtisch';

  @override
  String get homeMeetupChooseSub => 'Dein regelmäßiges Meetup auswählen';

  @override
  String homeMeetupBadges(int count) {
    return '$count Badges';
  }

  @override
  String get homeMeetupToday => 'Heute!';

  @override
  String get homeMeetupTomorrow => 'Morgen';

  @override
  String homeMeetupInDays(int days) {
    return 'in $days Tagen';
  }

  @override
  String get homeMeetupNoDate => 'Kein Termin geplant';

  @override
  String get homeMeetupNextEvent => 'Nächstes Meetup';

  @override
  String get homeMeetupNoneSoon =>
      'Kein Termin in Sicht.\nWird Zeit, das zu ändern!';

  @override
  String get homeMeetupSelectFirst => 'Erst Home Meetup\nwählen!';

  @override
  String get btnEvents => 'EVENTS';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusMeetupActive => 'Meetup aktiv';

  @override
  String get loading => 'Lade...';

  @override
  String get organizerPromoted => 'Du bist jetzt ORGANISATOR!';

  @override
  String get resetTitle => 'App zurücksetzen?';

  @override
  String get resetBody => 'Alle Badges und dein Profil werden gelöscht.';

  @override
  String get resetCancel => 'Abbruch';

  @override
  String get resetConfirm => 'LÖSCHEN';

  @override
  String get settingsSectionBackup => 'DATENSICHERUNG';

  @override
  String get settingsSectionLanguage => 'SPRACHE';

  @override
  String get settingsSectionNostr => 'NOSTR-NETZWERK';

  @override
  String get settingsSectionControl => 'BEDIENUNG';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsBackup => 'Backup erstellen';

  @override
  String get settingsBackupSub => 'Sichere deinen Account';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageChoose => 'Sprache wählen';

  @override
  String get settingsRelays => 'Nostr-Relays';

  @override
  String get settingsRelaysSub => 'Relays konfigurieren';

  @override
  String get settingsHaptic => 'Vibrationsfeedback';

  @override
  String get settingsHapticOn => 'Aktiv';

  @override
  String get settingsHapticOff => 'Deaktiviert';

  @override
  String get settingsReset => 'App zurücksetzen';

  @override
  String get settingsResetSub => 'Löscht Profil und Badges';

  @override
  String get introTagline => 'DEINE BITCOIN COMMUNITY';

  @override
  String get introJoin => 'COMMUNITY BETRETEN';

  @override
  String get introLoadBackup => 'BACKUP LADEN';

  @override
  String get introSetIdentity => 'Bitte lege zuerst deine Identität fest.';

  @override
  String get navWalletTab => 'Badges';

  @override
  String get navProfileTab => 'Profil';

  @override
  String get scanBadge => 'Badge scannen';

  @override
  String get scanBadgeSub => 'QR-Code vom Meetup';

  @override
  String get scanReputation => 'Reputation prüfen';

  @override
  String get scanReputationSub =>
      'Trust Score einer anderen Person verifizieren';

  @override
  String get calendarTitle => 'MEETUP TERMINE';

  @override
  String get calendarSearch => 'Suche (z.B. München, Bitcoin...)';

  @override
  String get calendarNoEvents => 'Keine Termine gefunden.';

  @override
  String get sectionDescription => 'BESCHREIBUNG';

  @override
  String get sectionLocation => 'STANDORT';

  @override
  String get sectionDates => 'TERMINE';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get meetupRoute => 'Route';

  @override
  String get meetupNoDatesCal => 'Aktuell keine Termine im Kalender.';

  @override
  String get errorOpenLink => 'Konnte Link nicht öffnen';

  @override
  String get walletNoBadges => 'Noch keine Badges gesammelt';

  @override
  String get walletNoBadgesSub =>
      'Besuche Meetups und scanne den QR-Code, um Badges zu sammeln!';

  @override
  String get walletShareReputation => 'REPUTATION TEILEN';

  @override
  String get walletShowQr => 'QR-Code anzeigen';

  @override
  String get walletShowQrSub => 'Zum Scannen vor Ort';

  @override
  String get walletExportJson => 'Als JSON exportieren';

  @override
  String get walletExportJsonSub => 'Signierter Export mit Schnorr-Beweis';

  @override
  String get walletShareText => 'Als Text teilen';

  @override
  String get walletShareTextSub => 'Lesbar für alle (wird im Web kopiert)';

  @override
  String get walletShareTitle => 'Reputation teilen';

  @override
  String get walletJsonCopied => 'JSON-Daten in Zwischenablage kopiert';

  @override
  String get walletReputationCopied => 'Reputation in Zwischenablage kopiert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get badgeDetailsTitle => 'Badge-Details';

  @override
  String get badgeShare => 'Badge teilen';

  @override
  String get badgeShareCaps => 'BADGE TEILEN';

  @override
  String get badgeClose => 'SCHLIESSEN';

  @override
  String get badgeProofTitle => 'Kryptographischer Beweis';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Meetup-Datum';

  @override
  String get badgeMeetupId => 'Meetup-ID';

  @override
  String get badgeOrganizerNpub => 'Organisator (npub)';

  @override
  String get badgeSignatureType => 'Signaturtyp';

  @override
  String get badgeTransmission => 'Übertragungsweg';

  @override
  String get badgeTimestamp => 'Zeitstempel';

  @override
  String get badgeScanTime => 'Scan-Zeitpunkt';

  @override
  String get badgeVerificationHash => 'VERIFIKATIONS-HASH';

  @override
  String get badgeClaimBinding => 'Claim-Binding';

  @override
  String get badgeBound => 'Gebunden ✓';

  @override
  String get badgeNotBound => 'Nicht gebunden';

  @override
  String get badgeClaimedLater => 'Nachträglich geclaimed';

  @override
  String get badgeNote => 'Hinweis';

  @override
  String get badgeNoSignature => 'Keine Signatur';

  @override
  String get badgeHashCopied => 'Hash kopiert';

  @override
  String get badgeInfoCopied => 'Badge-Info in Zwischenablage kopiert';

  @override
  String get badgeNfcTag => 'NFC-Tag';

  @override
  String get badgeRollingQr => 'Rolling QR-Code';

  @override
  String get levelNew => 'NEU';

  @override
  String get levelStarter => 'STARTER';

  @override
  String get levelActive => 'AKTIV';

  @override
  String get levelEstablished => 'ETABLIERT';

  @override
  String get levelVeteran => 'VETERAN';

  @override
  String get reputationTitle => 'REPUTATION';

  @override
  String get reputationNoBadges => 'NOCH KEINE BADGES';

  @override
  String get reputationNoProofs => 'Noch keine kryptographischen Beweise';

  @override
  String get reputationBuildHint1 =>
      'Besuche ein Meetup und scanne einen Badge um ';

  @override
  String get reputationBuildHint2 => 'deine Reputation aufzubauen.';

  @override
  String get reputationScanQr => 'QR-CODE SCANNEN';

  @override
  String get reputationShareImage => 'QR ALS BILD TEILEN';

  @override
  String get reputationUpdateRelays => 'AUF RELAYS AKTUALISIEREN';

  @override
  String get reputationPublishing => 'PUBLIZIERE...';

  @override
  String get reputationBadges => 'Badges';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Signer';

  @override
  String get reputationBound => 'Gebunden';

  @override
  String get reputationSchnorrSigned => 'Schnorr-signiert';

  @override
  String get reputationSignedNoId => 'Signiert (ohne Identität)';

  @override
  String get reputationNoIdentity =>
      'Keine Identität verknüpft. Ergänze Telegram oder Nostr in deinem Profil.';

  @override
  String get reputationCheck => 'Reputation prüfen';

  @override
  String get reputationVerified => 'Meine verifizierte Meetup-Reputation';

  @override
  String get reputationCodeFrom => 'Reputationscode von';

  @override
  String get portalDiscover => 'ENTDECKEN';

  @override
  String get portalQuickAccess => 'SCHNELLZUGRIFF';

  @override
  String get portalPodcastMedia => 'PODCAST & MEDIA';

  @override
  String get portalSocialNetworks => 'SOZIALE NETZWERKE';

  @override
  String get portalAssociation => 'VEREIN';

  @override
  String get portalProfile => 'Dein Profil & Badges';

  @override
  String get portalMeetupMap => 'Meetup-Karte';

  @override
  String get portalMeetupMapSub => 'Treffen in deiner Nähe';

  @override
  String get portalBeginnerPath => 'Der Weg (Einsteiger)';

  @override
  String get portalShoutoutSend => 'Shoutout senden';

  @override
  String get portalMembership => 'Mitglied werden';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips & Sounds';

  @override
  String get portalInterviews => 'Interviews';

  @override
  String get portalMediaArticles => 'Media & Artikel';

  @override
  String get portalMerch => 'Merch & Bitcoin-Produkte';

  @override
  String get portalShop => 'Shop';

  @override
  String get portalDonate => 'Spenden';

  @override
  String get portalContact => 'Kontakt';

  @override
  String get portalPrivacy => 'Datenschutz';

  @override
  String get portalStatutes => 'Satzung (PDF)';

  @override
  String get portalAboutAssoc => 'Über den Verein';

  @override
  String get portalOpen => 'Portal öffnen';

  @override
  String get portalTagline => 'für bullishe Bitcoiner.';

  @override
  String get portalInfotainment => 'Toximalistisches Infotainment';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';

  @override
  String get profileTitle => 'DEIN PROFIL';

  @override
  String get profileEditTitle => 'PROFIL BEARBEITEN';

  @override
  String get profileSave => 'PROFIL SPEICHERN';

  @override
  String get profileIntro => 'Wähle einen Nickname und dein Home-Meetup.';

  @override
  String get profileNicknameMin => 'Mindestens 2 Zeichen';

  @override
  String get profileNicknameReq => 'Pflichtfeld — bitte ausfüllen';

  @override
  String get profileNicknameAnon =>
      'Bitte wähle einen eigenen Nickname (nicht \'Anon\')';

  @override
  String get profileHomeMeetup => 'Home Meetup';

  @override
  String get profileHomeMeetupDash => 'Home-Meetup';

  @override
  String get profileChooseMeetup => 'Wähle dein Home-Meetup';

  @override
  String get profileMeetupReq => 'Pflichtfeld — bitte wähle dein Home-Meetup';

  @override
  String get profileSearchCity => 'Stadt suchen...';

  @override
  String get profileIdentity => 'DEINE IDENTITÄT';

  @override
  String get profileStrengthen => 'IDENTITÄT STÄRKEN';

  @override
  String get profileStrengthenDesc =>
      'Verknüpfe Plattformen und beweise deine Menschlichkeit um deinen Trust Score zu erhöhen.';

  @override
  String get profileLinkPlatforms => 'Plattformen verknüpfen';

  @override
  String get profilePlatformsSub => 'Telegram, X, Kleinanzeigen';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => 'Einmal gezappt? Jetzt prüfen';

  @override
  String get profileLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get profileVerified => 'VERIFIZIERT';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'Noch kein Nostr-Key vorhanden';

  @override
  String get profileKeyActiveCaps => 'SCHLÜSSEL AKTIV';

  @override
  String get profileCreateKey => 'NOSTR KEY ERSTELLEN';

  @override
  String get profileCreateNewKey => 'NEUEN KEY ERSTELLEN';

  @override
  String get profileCreating => 'WIRD ERSTELLT...';

  @override
  String get profileNoNostrNeeded =>
      'Du brauchst kein Nostr-Konto. Die App erstellt dir einen Schlüssel — das dauert eine Sekunde.';

  @override
  String get profileKeyDesc =>
      'Dein kryptografischer Schlüssel — damit werden Badges signiert und deine Reputation verifiziert.';

  @override
  String get profileConnectAmber => 'MIT AMBER VERBINDEN';

  @override
  String get profileConnectExtension => 'MIT BROWSERERWEITERUNG VERBINDEN';

  @override
  String get profileExtensionConnected =>
      'Erweiterung verbunden! Dein Schlüssel bleibt dort.';

  @override
  String get profileExtensionAborted => 'In der Erweiterung abgelehnt.';

  @override
  String get profileExtensionNotFound =>
      'Keine Nostr-Erweiterung im Browser gefunden.';

  @override
  String get profileAmberDesc =>
      'Amber ist ein separater Signer für Android, der deinen privaten ';

  @override
  String get profileAmberConnected =>
      'Mit Amber verbunden! Dein nsec bleibt in Amber.';

  @override
  String get profileAmberNotFound => 'Amber nicht gefunden';

  @override
  String get profileAmberInstall =>
      'Schlüssel sicher verwahrt. Installiere Amber (z.B. über F-Droid ';

  @override
  String get profileAmberRetry => 'oder den Zapstore) und versuche es erneut.';

  @override
  String get profileAmberAborted => 'Verbindung in Amber abgebrochen.';

  @override
  String get profileSwitchSignerHeading => 'Anderen Signer verbinden';

  @override
  String get profileDisconnectSigner => 'SIGNER TRENNEN';

  @override
  String get profileDisconnectTitle => 'Signer trennen?';

  @override
  String get profileDisconnectBody =>
      'Die Verbindung zum Signer wird gelöst. Ist ein lokaler Schlüssel vorhanden, nutzt die App wieder ihn — sonst kann sie nicht signieren, bis du einen erstellst oder importierst.\n\nIm Signer selbst bleibt die Freigabe bestehen; die kannst du dort zusätzlich widerrufen.';

  @override
  String get profileDisconnectDone => 'Signer getrennt.';

  @override
  String get profileSignerUnusable =>
      'Signieren ist derzeit nicht möglich — verbinde den Signer neu.';

  @override
  String get profileSwitchSignerHint =>
      'Dein bisheriger Schlüssel bleibt gespeichert und im Backup.';

  @override
  String get profileSwitchSignerTitle => 'Signer wechseln?';

  @override
  String get profileSwitchSignerBody =>
      'Der Signer bringt seinen eigenen Schlüssel mit. Enthält er NICHT denselben wie bisher, wechselt deine Identität — deine Badges gehören dann weiter zum alten Schlüssel.\n\nDein bisheriger Schlüssel wird nicht gelöscht: er bleibt im Speicher und im Backup, du kannst also zurück.';

  @override
  String get profileSwitchSignerContinue => 'WEITER';

  @override
  String get profileIdentityChanged =>
      'Achtung: Der Signer nutzt eine andere Identität als bisher. Deine Badges gehören zum vorherigen Schlüssel.';

  @override
  String get profileConnectBunker => 'MIT REMOTE-SIGNER VERBINDEN';

  @override
  String get bunkerTitle => 'Mit Remote-Signer verbinden';

  @override
  String get bunkerIntro =>
      'Dein Schlüssel bleibt im Signer. Die App fragt dort nur Signaturen an — auf jedem Gerät.';

  @override
  String get bunkerModeSigner => 'Signer-App verbinden';

  @override
  String get bunkerModeSignerDesc =>
      'Die App zeigt einen QR-Code, den du im Signer scannst.';

  @override
  String get bunkerModePaste => 'bunker://-Adresse einfügen';

  @override
  String get bunkerModePasteDesc =>
      'Kopiere sie aus nsec.app, Amber oder Alby. Auf dem iPhone der zuverlässigste Weg.';

  @override
  String get bunkerPasteLabel => 'bunker://-Adresse';

  @override
  String get bunkerPasteHint => 'bunker://…?relay=wss://…';

  @override
  String get bunkerConnect => 'VERBINDEN';

  @override
  String get bunkerBack => 'ZURÜCK';

  @override
  String get bunkerWaiting => 'Warte auf die Freigabe im Signer …';

  @override
  String get bunkerWaitingHint =>
      'Das kann bis zu zwei Minuten dauern. Lass die App offen.';

  @override
  String get bunkerScanHint =>
      'Im Signer scannen — oder die Adresse dort einfügen.';

  @override
  String get bunkerCopy => 'Adresse kopieren';

  @override
  String get bunkerCopied => 'Adresse kopiert.';

  @override
  String get bunkerOpenSigner => 'Signer öffnen';

  @override
  String get bunkerNoSignerApp =>
      'Keine Signer-App gefunden. Nimm den Weg über „bunker://-Adresse einfügen“.';

  @override
  String get bunkerRecommendAndroid =>
      'Empfohlen auf Android: Amber — Signer-App mit Bunker, im Zapstore und bei F-Droid. Alternativ ein selbst betriebener Bunker (Bunker46, Signet).';

  @override
  String get bunkerRecommendIos =>
      'Empfohlen auf iOS: Clave — weckt sich per Push, um im Hintergrund zu signieren. Alternativ ein selbst betriebener Bunker (Bunker46, Signet) oder Amber auf einem Android-Gerät.';

  @override
  String get bunkerRecommendWeb =>
      'Als Gegenpart eignen sich Amber (Android), Clave (iOS) oder ein selbst betriebener Bunker wie Bunker46 oder Signet.';

  @override
  String get bunkerAuthOpen => 'Freigabe im Browser öffnen';

  @override
  String get bunkerAuthNeeded =>
      'Der Signer verlangt eine Freigabe im Browser.';

  @override
  String get bunkerAuthAction => 'ÖFFNEN';

  @override
  String get bunkerTimeout =>
      'Der Signer hat nicht geantwortet. Ist er geöffnet und online?';

  @override
  String get bunkerConnected =>
      'Remote-Signer verbunden! Dein Schlüssel bleibt dort.';

  @override
  String get bunkerDisconnected => 'Remote-Signer getrennt.';

  @override
  String get bunkerCheck => 'VERBINDUNG PRÜFEN';

  @override
  String get bunkerAlive =>
      'Signer antwortet — die Sitzung ist aktiv. Ob die Freigaben noch gelten, zeigt erst die nächste Signatur.';

  @override
  String get bunkerDead =>
      'Signer antwortet nicht. Ist er geöffnet und online? Sonst neu verbinden.';

  @override
  String get profileImportNsec => 'BESTEHENDEN NSEC IMPORTIEREN';

  @override
  String get profileImportNsecShort => 'NSEC IMPORTIEREN';

  @override
  String get keyExportEncrypted => 'VERSCHLÜSSELT EXPORTIEREN (ncryptsec)';

  @override
  String get keyExportTitle => 'Schlüssel verschlüsselt exportieren';

  @override
  String get keyExportDesc =>
      'Erzeugt ein ncryptsec — deinen Schlüssel, mit einem Passwort verschlüsselt. Den kannst du gefahrlos in einem Passwortmanager ablegen und in Amber, Clave, nsec.app oder einem eigenen Bunker importieren.';

  @override
  String get keyExportDuration =>
      'Die Verschlüsselung ist absichtlich langsam: rund eine halbe Sekunde auf dem Gerät, im Browser bis zu einer halben Minute.';

  @override
  String get keyExportAction => 'EXPORTIEREN';

  @override
  String get keyExportMismatch => 'Die Passwörter stimmen nicht überein.';

  @override
  String get keyExportNoKey => 'Kein lokaler Schlüssel vorhanden.';

  @override
  String get keyExportReadyTitle => 'Verschlüsselter Schlüssel';

  @override
  String get keyExportReadyBody =>
      'Ohne dein Passwort ist das hier wertlos — und mit deinem Passwort ist es dein voller Schlüssel. Behandle beides entsprechend.';

  @override
  String get keyExportCopy => 'KOPIEREN';

  @override
  String get keyExportCopied => 'Verschlüsselter Schlüssel kopiert.';

  @override
  String get keyExportFromVault =>
      'Das ist dein Schlüssel mit dem Passwort, das du beim Anlegen gesetzt hast — kein neues Passwort nötig.';

  @override
  String get keyExportOtherPassword => 'Mit einem anderen Passwort erzeugen';

  @override
  String get profileImport => 'IMPORTIEREN';

  @override
  String get profileEnterNsec =>
      'Gib deinen privaten Nostr-Schlüssel ein (beginnt mit nsec1...):';

  @override
  String get profileKeyImported => 'Key importiert!';

  @override
  String get profileShowNsecQ => 'NSEC ANZEIGEN?';

  @override
  String get profileShowNsecWarn =>
      'Dein privater Schlüssel wird angezeigt. Stelle sicher, dass niemand auf deinen Bildschirm schaut!';

  @override
  String get profileShow => 'ANZEIGEN';

  @override
  String get profileCopy => 'KOPIEREN';

  @override
  String get profileSecureKey => 'SICHERE DEINEN KEY!';

  @override
  String get profileSaveKeyDesc =>
      'Dies ist dein privater Schlüssel. Speichere ihn an einem sicheren Ort! ';

  @override
  String get profileKeyNotShownAgain =>
      'Dieser Key wird NICHT nochmal angezeigt!';

  @override
  String get profileKeySecured => 'ICH HAB IHN GESICHERT';

  @override
  String get profileNpubCopied => 'npub kopiert!';

  @override
  String get profileNsecCopied => 'nsec kopiert! Jetzt sicher abspeichern.';

  @override
  String get profileNsecNeverLeaves => 'Dein nsec verlässt niemals dein Gerät.';

  @override
  String get profileWhoHasKey => 'Wer diesen Key hat, HAT deine Identität.';

  @override
  String get profileBackupNsec =>
      'Wichtig: Sichere deinen nsec! Wenn du dein Gerät verlierst, ist dein Key weg.';

  @override
  String get profileNewKeypairDesc =>
      'Es wird ein neues Schlüsselpaar erstellt. Dein privater Schlüssel (nsec) wird sicher auf deinem Gerät gespeichert.\n\n';

  @override
  String get profileEdit => 'Bearbeiten';

  @override
  String get profileEditLoseStatus => 'BEARBEITEN (Status verlieren)';

  @override
  String get profileWarning => 'Achtung!';

  @override
  String get profileEditWarnDesc =>
      'Wenn du bearbeitest, verlierst du deinen \'Verifiziert\'-Status und musst neu freigeschaltet werden.';

  @override
  String get dialogCancel => 'ABBRECHEN';

  @override
  String get dialogCancelMixed => 'Abbrechen';

  @override
  String get dialogCreate => 'ERSTELLEN';

  @override
  String errorGeneric(String msg) {
    return 'Fehler: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Amber-Fehler: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Bitte ausfüllen: $fields';
  }

  @override
  String get backupEncryptTitle => 'Backup verschlüsseln';

  @override
  String get backupDecryptTitle => 'Backup entschlüsseln';

  @override
  String get backupExportDesc =>
      'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen.\n\n⚠️ Wenn du dieses Passwort vergisst, ist das Backup UNWIEDERBRINGLICH verloren!';

  @override
  String get backupImportDesc =>
      'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.';

  @override
  String get backupPassword => 'Passwort';

  @override
  String get backupPasswordConfirm => 'Passwort bestätigen';

  @override
  String get backupPasswordEmpty => 'Passwort darf nicht leer sein';

  @override
  String get backupPasswordMin => 'Mindestens 8 Zeichen';

  @override
  String get backupPasswordMismatch => 'Passwörter stimmen nicht überein';

  @override
  String get backupEncryptSave => 'Verschlüsseln & Speichern';

  @override
  String get backupDecryptLoad => 'Entschlüsseln & Laden';

  @override
  String get backupShareTitle => 'Einundzwanzig App Backup (Verschlüsselt)';

  @override
  String get backupShareText =>
      'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.';

  @override
  String backupError(String msg) {
    return 'Fehler beim Backup: $msg';
  }

  @override
  String get backupCorrupt => 'Backup-Datei ist beschädigt (Formatfehler).';

  @override
  String get backupWrongPassword => 'Falsches Passwort oder Datei beschädigt!';

  @override
  String get backupNotValid =>
      'Datei ist kein gültiges Backup oder das falsche Format.';

  @override
  String get backupNotEinundzwanzig =>
      'Datei ist kein gültiges Einundzwanzig Backup.';

  @override
  String backupLoaded(Object items) {
    return '✅ Backup geladen! $items wiederhergestellt.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Import fehlgeschlagen: $msg';
  }

  @override
  String get qrScanTitle => 'REPUTATION PRÜFEN';

  @override
  String get qrResultTitle => 'ERGEBNIS';

  @override
  String get qrScanHint => 'Scanne einen Einundzwanzig\nReputation QR-Code';

  @override
  String get qrLoadFromGallery => 'QR AUS GALERIE LADEN';

  @override
  String get qrBack => 'ZURÜCK';

  @override
  String get qrNoCodeInImage => 'Kein QR-Code im Bild gefunden';

  @override
  String get qrNotEinundzwanzig =>
      'QR-Code gefunden, aber kein Einundzwanzig-Format';

  @override
  String get qrVerified => 'VERIFIZIERT';

  @override
  String get qrVerifiedV1 => 'VERIFIZIERT (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFIZIERT (v2)';

  @override
  String get qrSigInvalid => 'SIGNATUR UNGÜLTIG';

  @override
  String get qrFormatUnknown => 'FORMAT UNBEKANNT';

  @override
  String get qrReadError => 'LESEFEHLER';

  @override
  String get qrV2Subtitle => 'Legacy-Signatur gültig — kein Badge-Proof';

  @override
  String get qrV1Subtitle => 'Älteres Format — keine Identitätsbindung';

  @override
  String get qrCantRead => 'QR-Code konnte nicht gelesen werden.';

  @override
  String qrProcessError(String msg) {
    return 'Fehler beim Verarbeiten: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTITÄT';

  @override
  String get qrNoIdentity => 'KEINE IDENTITÄT';

  @override
  String get qrNoVerifiableIdentity => 'Keine verifizierbare Identität.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'SOZIALES NETZWERK';

  @override
  String get qrSectionPlatforms => 'VERKNÜPFTE PLATTFORMEN';

  @override
  String get qrSectionMeetups => 'BESUCHTE MEETUPS';

  @override
  String get qrHumanVerified => 'Mensch verifiziert';

  @override
  String get qrLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get qrNoLightning => 'Kein Lightning-Beweis gefunden';

  @override
  String get qrNoZap => 'Keine Zap-Aktivität';

  @override
  String get qrNip05Invalid => 'NIP-05 ungültig';

  @override
  String get qrYouFollow => 'Du folgst';

  @override
  String get qrFollowsYou => 'Folgt dir';

  @override
  String get qrMutualFollow => 'Gegenseitiger Follow';

  @override
  String get qrNoDirectFollow => 'Kein direkter Follow';

  @override
  String get qrDirectConnection => 'Direkte Verbindung';

  @override
  String get qrBidirectional => 'Direkte bidirektionale Verbindung';

  @override
  String get qrOneWay => 'Einseitige Verbindung';

  @override
  String get qrViaContacts => 'Über gemeinsame Kontakte';

  @override
  String get qrStrongOverlap => 'Starke Netzwerk-Überlappung';

  @override
  String get qrPartiallyConnected => 'Teilweise verbunden';

  @override
  String get qrNoOverlap => 'Keine Überlappung';

  @override
  String get qrEndorsement => 'Endorsement von bekannten Admins';

  @override
  String get qrSigVerified => 'Signatur verifiziert';

  @override
  String get qrAnalyzingNetwork => 'Analysiere Netzwerk...';

  @override
  String get qrCheckingLightning => 'Prüfe Lightning...';

  @override
  String get qrCheckingNip05 => 'Prüfe NIP-05...';

  @override
  String get qrStatBadges => 'Badges';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Signer';

  @override
  String get qrStatBound => 'Gebunden';

  @override
  String get qrStatDays => 'Tage';

  @override
  String get qrLabelNickname => 'Nickname';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Andere';

  @override
  String get qrLinked => 'Verknüpft';

  @override
  String get qrSigVerifiedShort => 'Signatur verifiziert';

  @override
  String get qrLinkedShort => 'Verknüpft';

  @override
  String get nfcDisabled => 'NFC ist deaktiviert';

  @override
  String get nfcDisabledHint => 'NFC ist deaktiviert. Bitte einschalten.';

  @override
  String get nfcUnavailable => 'NFC nicht verfügbar';

  @override
  String get nfcOpenSettings => 'EINSTELLUNGEN ÖFFNEN';

  @override
  String get nfcEnableHint =>
      'Bitte aktiviere NFC in deinen Geräteeinstellungen, ';

  @override
  String get nfcSettingsAndroid =>
      'Android: Einstellungen → Verbindungen → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Einstellungen → NFC';

  @override
  String get verifyScanBadge => 'BADGE SCANNEN';

  @override
  String get verifyScanNfc => 'NFC TAG SCANNEN';

  @override
  String get verifyScanQr => 'QR SCANNEN';

  @override
  String get verifyScanQrCaps => 'QR-CODE SCANNEN';

  @override
  String get verifyReadyToScan => 'Bereit zum Scannen';

  @override
  String get verifyWaitingNfc => 'Warte auf NFC Tag...';

  @override
  String get verifyCheckingNfc => 'Prüfe NFC...';

  @override
  String get verifyScanInstruction =>
      'Scanne den QR-Code\ndes Meetup-Organisators.';

  @override
  String get verifyScanQrInstruction =>
      'Scanne den QR-Code\ndes Meetup-Organisators';

  @override
  String get verifyNoNfcDevice =>
      'Dieses Gerät hat kein NFC. Nutze den QR-Scanner.';

  @override
  String get verifyNoNfcLong => 'Dieses Gerät unterstützt kein NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Nutze stattdessen den QR-Code-Scanner, ';

  @override
  String get verifyToGetBadge => 'um dein Badge zu erhalten.';

  @override
  String get verifyAskScan => 'Bitte lass einen Teilnehmer deinen Tag scannen.';

  @override
  String get verifyCantSelfBadge =>
      'Du kannst dir nicht selbst ein Badge geben.\n';

  @override
  String get verifyBadgeFound => 'BADGE GEFUNDEN';

  @override
  String get verifyAlreadyCollected => 'BEREITS GESAMMELT';

  @override
  String get verifyAddToWallet => 'ZUR WALLET HINZUFÜGEN';

  @override
  String get verifyVerifiedAdmin => 'Verifizierter Admin';

  @override
  String get verifyUnknownMeetup => 'Unbekanntes Meetup';

  @override
  String get verifyNoExpiry => 'Kein Ablauf';

  @override
  String get writerReadyToWrite => 'Bereit zum Schreiben';

  @override
  String get writerNoNfcDevice =>
      'Dieses Gerät hat kein NFC. Nutze Rolling QR-Codes.';

  @override
  String get writerUseRollingQr => 'Du kannst stattdessen Rolling QR-Codes ';

  @override
  String get writerForYourMeetup => 'für dein Meetup verwenden.';

  @override
  String get writerSelectHomeFirst =>
      'Bitte erst ein Home-Meetup im Profil auswählen';

  @override
  String get writerYourHomeMeetup => 'DEIN HOME-MEETUP';

  @override
  String get writerCreateTag => 'TAG ERSTELLEN';

  @override
  String get writerCreateMeetupTag => 'MEETUP TAG ERSTELLEN';

  @override
  String get writerMeetupTag => 'MEETUP TAG';

  @override
  String get writerSuccess => 'ERFOLG!';

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Gültig für ${hours}h\n\n';
  }

  @override
  String get writerHoldTag => 'Halte Tag an das Gerät...';

  @override
  String get writerHoldTagInstruction =>
      'Halte einen NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.';

  @override
  String get writerFormatting => 'Formatiere leeren Tag...';

  @override
  String get writerFormatFailed => 'Formatierung fehlgeschlagen';

  @override
  String get writerLoadingSession => 'Lade Session-Daten...';

  @override
  String get writerJumpToQr => 'Springe zum QR-Code...';

  @override
  String get writerNoNdef => 'Kein NDEF Format möglich';

  @override
  String get writerTagReadOnly => 'Tag ist schreibgeschützt';

  @override
  String get writerCanOverwrite => 'Tag kann danach überschrieben werden';

  @override
  String get writerTagLost => 'Tag verloren während dem Schreiben';

  @override
  String get writerTagRemovedEarly =>
      'Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät';

  @override
  String get writerUseNtag215 => 'Verwende einen NTAG215 (504B) oder größer.';

  @override
  String get writerToWriteTag => 'um den Tag zu beschreiben.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Ort: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Block: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Signiert von: $signer';
  }

  @override
  String get verifyMsgProof => 'Beweis: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Tag-Ablauf: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Bereits gesammelt\n\nHeute hast du bereits ein Badge von:\n$name';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Fehler: $msg';
  }

  @override
  String writerTagTooSmall(Object data, Object max) {
    return 'Tag zu klein! Daten: ${data}B, Tag: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ MEETUP TAG geschrieben!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (kompakt)\n';
  }

  @override
  String get verifyErrNoNdef => '✗ Kein NDEF Tag';

  @override
  String get verifyErrTagEmpty => '✗ Tag ist leer';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload leer';

  @override
  String get verifyErrInvalidFormat => '✗ Ungültiges Format';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Ungültiger Tag: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Lesefehler: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ NFC Fehler: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ QR-Code abgelaufen!\n$msg\n\nBitte direkt am Bildschirm des Organisators scannen.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Start Fehler: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — passt auf NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ Kein Home-Meetup gesetzt';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Home-Meetup nicht gefunden';

  @override
  String get writerNoActiveSession =>
      '❌ Keine aktive Meetup-Session gefunden. Bitte starte das Meetup neu.';

  @override
  String get apMeetupSession => 'MEETUP SESSION';

  @override
  String get apSessionRunning => 'SESSION LÄUFT';

  @override
  String get apOpenActiveMeetup => 'AKTIVES MEETUP ÖFFNEN';

  @override
  String get apStartMeetup => 'MEETUP STARTEN';

  @override
  String get apEndMeetupEarly => 'Meetup vorzeitig beenden';

  @override
  String get apOrganizer => 'ORGANISATOR';

  @override
  String get apHowItWorks => 'SO FUNKTIONIERT\'S';

  @override
  String get apNewMeetupQ => 'Neues Meetup starten?';

  @override
  String get apSessionEndQ => 'Session beenden?';

  @override
  String get apCancel => 'Abbrechen';

  @override
  String get apStart => 'Starten';

  @override
  String get apEnd => 'Beenden';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Via Trust Score';

  @override
  String get apNewMeetupBody =>
      'Dies erstellt eine eindeutige Signatur (Blockzeit) für die nächsten 4 Stunden. In dieser Zeit ist die Erstellung neuer Sessions gesperrt.';

  @override
  String get apSessionEndBody =>
      'Damit sperrst du die aktuelle Blockzeit. Du kannst danach eine neue Session starten.';

  @override
  String get apGeneratesProof =>
      'Generiert einen neuen kryptographischen Beweis für die nächsten 4 Stunden.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'MENSCH VERIFIZIERT';

  @override
  String get humNotVerified => 'NICHT VERIFIZIERT';

  @override
  String get humVerifiedSub => 'Du bist als Mensch verifiziert';

  @override
  String get humLightningActive => 'Lightning-Beweis aktiv';

  @override
  String get humCheckNow => 'JETZT PRÜFEN';

  @override
  String get humCheckAgain => 'ERNEUT PRÜFEN';

  @override
  String get humCheckAgainShort => 'Erneut prüfen';

  @override
  String get humSearchingRelays => 'SUCHE AUF RELAYS...';

  @override
  String get humHowTitle => 'WIE FUNKTIONIERT DAS?';

  @override
  String get humIntro1 =>
      'Beweise, dass du ein Mensch bist — indem du nachweist, ';

  @override
  String get humIntro2 => 'dass du eine echte Lightning-Wallet besitzt und ';

  @override
  String get humIntro3 => 'schon einmal jemanden auf Nostr gezappt hast.';

  @override
  String get humExplain1 =>
      'Bots haben keine Lightning-Wallets. Eine einzige echte ';

  @override
  String get humExplain2 =>
      'Zahlung beweist, dass du ein Mensch mit einer echten ';

  @override
  String get humExplain3 =>
      'Wallet bist — ohne persönliche Daten preiszugeben.';

  @override
  String get humStep1 => 'Du zappst irgendjemanden auf Nostr';

  @override
  String get humStep2 => 'Der Zap erzeugt ein Receipt auf Relays';

  @override
  String get humStep3 => 'Die App findet dein Receipt';

  @override
  String get humStepInstruction =>
      'Egal wen, egal wieviel Sats. Nutze dafür einen Nostr-Client wie Damus, Amethyst oder Primal.';

  @override
  String get humCheckInstruction =>
      'Drücke den Prüfen-Button und die App sucht auf Nostr-Relays nach deinem Zap.';

  @override
  String get humZapReturn => 'Zappe irgendjemanden und komm zurück';

  @override
  String get humCryptoProof =>
      'Das ist ein kryptographischer Beweis, dass du eine echte Lightning-Zahlung geleistet hast.';

  @override
  String get humProofInEvent1 =>
      'auf dem Nostr-Netzwerk geleistet. Dieser Beweis ist in deinem ';

  @override
  String get humProofPrivacy =>
      'Der Beweis wird in dein Reputation-Event aufgenommen. Kein Betrag oder Empfänger wird gespeichert.';

  @override
  String get humReputationSaved => 'Reputation-Event gespeichert.';

  @override
  String humPaidOn(String date) {
    return 'Du hast am $date eine Lightning-Zahlung ';
  }

  @override
  String humLastCheck(String time) {
    return 'Letzte Prüfung: $time';
  }

  @override
  String get ppTitle => 'PLATTFORM-VERKNÜPFUNG';

  @override
  String get ppPlatform => 'PLATTFORM';

  @override
  String get ppUsername => 'BENUTZERNAME';

  @override
  String get ppActiveLinks => 'AKTIVE VERKNÜPFUNGEN';

  @override
  String get ppLinkPlatform => 'PLATTFORM VERKNÜPFEN';

  @override
  String get ppCreateLink => 'VERKNÜPFUNG ERSTELLEN';

  @override
  String get ppAnotherPlatform => 'WEITERE PLATTFORM';

  @override
  String get ppShareOnPlatform => 'AUF PLATTFORM TEILEN';

  @override
  String get ppUnlinkQ => 'VERKNÜPFUNG AUFHEBEN?';

  @override
  String get ppRevoke => 'WIDERRUFEN';

  @override
  String get ppCancel => 'ABBRECHEN';

  @override
  String get ppYourUsername => 'Dein Benutzername';

  @override
  String get ppPlatformName => 'Name der Plattform';

  @override
  String get ppIntro =>
      'Verknüpfe deinen Account mit einer Plattform. Der Beweis wird automatisch in deinen Reputation-QR eingebettet.';

  @override
  String get ppLinkSaved =>
      'Verknüpfung gespeichert! Wird automatisch in deinen Reputation-QR eingebettet.';

  @override
  String get ppMustUpdate =>
      'Du musst dein Reputation-Event danach aktualisieren.';

  @override
  String get ppUnlinkBody1 => 'Die Plattform-Verknüpfung für \"';

  @override
  String get ppUnlinkBody2 => 'wird gelöscht.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'Die Plattform-Verknüpfung für \"$username\" auf $platform wird gelöscht.\n\nDu musst dein Reputation-Event danach aktualisieren.';
  }

  @override
  String ppCreated(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get ppRevokeTooltip => 'Widerrufen';

  @override
  String get rqTitle => 'MEETUP QR-CODE';

  @override
  String get rqActive => 'AKTIV';

  @override
  String get rqCodeRenewing => 'Code erneuert sich...';

  @override
  String get rqNextCodeIn => 'Nächster Code in';

  @override
  String get rqEndSession => 'Session beenden';

  @override
  String get rqEndSessionQ => 'Session beenden?';

  @override
  String get rqEnd => 'BEENDEN';

  @override
  String get rqEndSessionBody =>
      'Eine beendete Session sperrt diese Blockzeit. Du kannst danach eine neue Session starten.';

  @override
  String get rqNoActiveSession => 'KEINE AKTIVE SESSION';

  @override
  String get rqNoSessionBody =>
      'Es läuft aktuell keine Meetup-Session.\nBitte starte das Meetup im Admin Panel neu.';

  @override
  String get rqBackToAdmin => 'ZURÜCK ZUM ADMIN PANEL';

  @override
  String get rsTitle => 'NOSTR-RELAYS';

  @override
  String get rsDefaultRelays => 'DEFAULT-RELAYS';

  @override
  String get rsCustomRelays => 'EIGENE RELAYS';

  @override
  String get rsAddRelay => 'RELAY HINZUFÜGEN';

  @override
  String get rsAdd => 'HINZUFÜGEN';

  @override
  String get rsNoRelaysActive => 'Keine Relays aktiv!';

  @override
  String get rsNoCustomRelays => 'Keine eigenen Relays konfiguriert.';

  @override
  String get rsAllRelaysInfo =>
      'Die App nutzt alle aktiven Relays gleichzeitig für maximale Erreichbarkeit.';

  @override
  String get rsRelaysIntro =>
      'Relays verteilen deine Reputation im Nostr-Netzwerk. ';

  @override
  String get rsRelayPlaceholder => 'wss://mein-relay.de';

  @override
  String get rdScanAdminTag => 'ADMIN TAG SCANNEN';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'BADGE ABHOLEN';

  @override
  String get rdYourReputation => 'DEINE REPUTATION';

  @override
  String get rdEditIdentity => 'Identität bearbeiten';

  @override
  String get rdLinkingIdentity => 'Identität verknüpfen...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'Noch keine Badges gesammelt.\nGeh zu einem Meetup!';

  @override
  String get rdSelfSovereign =>
      'Self-Sovereign: Diese App läuft ohne Server. Deine Badges gehören nur dir und sind auf diesem Gerät gespeichert.';

  @override
  String get rdVerifiedByAdmin => 'VERIFIZIERT DURCH ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Restzeit: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Session: $time';
  }

  @override
  String get rvTitle => 'REPUTATION PRÜFEN';

  @override
  String get rvChecking => 'PRÜFE...';

  @override
  String get rvFullyVerified => 'VOLLSTÄNDIG VERIFIZIERT';

  @override
  String get rvPartiallyVerified => 'TEILWEISE VERIFIZIERT';

  @override
  String get rvSignatureOnly => 'NUR SIGNATUR GEPRÜFT';

  @override
  String get rvInvalid => 'UNGÜLTIG';

  @override
  String get rvConfirmedInEvent => 'Im Event bestätigt';

  @override
  String get rvPlatformProof => 'Plattform-Proof';

  @override
  String get rvIntro1 => 'Füge den Verify-String oder npub einer Person ein, ';

  @override
  String get rvIntro2 => 'um ihre Reputation über alle Beweis-Layer zu prüfen.';

  @override
  String get rvCheckingSignature => 'Prüfe Signatur...';

  @override
  String get rvCheckingNostr => 'Analysiere Nostr-Netzwerk...';

  @override
  String get rvCheckingLightning => 'Prüfe Lightning-Aktivität...';

  @override
  String get rvCheckingNip05 => 'Prüfe NIP-05...';

  @override
  String get msSelectMeetup => 'MEETUP AUSWÄHLEN';

  @override
  String get msSearchMeetup => 'Meetup suchen...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Erneut versuchen';

  @override
  String get mlLoadError => 'Fehler beim Laden';

  @override
  String get mlNoMeetupsFound => 'Keine Meetups gefunden.';

  @override
  String mlNoMeetupFor(String query) {
    return 'Kein Meetup für \"$query\"';
  }

  @override
  String get cmRequestSent => 'ANFRAGE GESENDET 🚀';

  @override
  String get cmDateTime => 'DATUM & UHRZEIT';

  @override
  String get cmFoundBase => 'GRÜNDE EINE BASIS.';

  @override
  String get cmLocation => 'LOCATION / ORT';

  @override
  String get cmCityName => 'NAME DER STADT';

  @override
  String get cmTelegramGroup => 'TELEGRAM GRUPPE (OPTIONAL)';

  @override
  String get cmNewMeetup => 'NEUES MEETUP';

  @override
  String get cmDateExample => 'z.B. 21. Mai, 19:00';

  @override
  String get cmCityExample => 'z.B. Frankfurt';

  @override
  String get cmLocationExample => 'z.B. Room 77';

  @override
  String get evUpcomingEvents => 'KOMMENDE EVENTS';

  @override
  String get evDatesEvents => 'TERMINE & EVENTS';

  @override
  String get evNoMeetupsFound => 'Keine Meetups gefunden';

  @override
  String get evSearchCityCountry => 'Stadt oder Land suchen...';

  @override
  String get evIntro =>
      'Die meisten Einundzwanzig Meetups finden regelmäßig statt. Klick auf ein Meetup für mehr Infos und Termine.';

  @override
  String get rvLabelPlatform => 'Plattform';

  @override
  String get rvLabelUsername => 'Username';

  @override
  String get countryDE => 'Deutschland';

  @override
  String get countryAT => 'Österreich';

  @override
  String get countryCH => 'Schweiz';

  @override
  String get countryES => 'Spanien';

  @override
  String get countryNL => 'Niederlande';

  @override
  String get countryIT => 'Italien';

  @override
  String get countryFR => 'Frankreich';

  @override
  String get siTitle => 'DEIN TRUST SCORE';

  @override
  String get siIntro =>
      'Misst deine Vertrauenswürdigkeit. Basiert auf kryptographischen Beweisen — niemand kann ihn fälschen.';

  @override
  String get siIdentityLayer => 'IDENTITY LAYER';

  @override
  String siLinksActive(Object count) {
    return '$count Verknüpfungen aktiv';
  }

  @override
  String get siHumanitySub => 'Lightning Zap Verifikation';

  @override
  String get siNip05Sub => 'Nostr-Identität (name@domain)';

  @override
  String get siPlatformActive => 'Plattform aktiv';

  @override
  String get siPlatforms => 'Plattformen';

  @override
  String get siNoneLinked => 'Noch keine verknüpft';

  @override
  String get siTrustLevel => 'TRUST LEVEL';

  @override
  String get siLvlNew => 'Startlevel. Besuche Meetups um Badges zu sammeln.';

  @override
  String get siLvlStarter => 'Deine ersten Badges zeigen Community-Teilnahme.';

  @override
  String get siLvlActive =>
      'Regelmäßig dabei. Verschiedene Meetups und Organisatoren stärken dein Profil.';

  @override
  String get siLvlEstablished =>
      'Vertrauenswürdiges Mitglied. Breit vernetzt und lange dabei.';

  @override
  String get siLvlVeteran => 'Höchstes Level. Reputation über Monate bewiesen.';

  @override
  String get siCalculation => 'BERECHNUNG';

  @override
  String get siFacBadges => 'Meetup-Badges';

  @override
  String get siFacBadgesDesc =>
      'Basiswert pro Badge. Gut besuchte Meetups wertvoller.';

  @override
  String get siFacDiversity => 'Diversität';

  @override
  String get siFacDiversityDesc =>
      'Verschiedene Städte/Organisatoren = mehr Punkte.';

  @override
  String get siFacSigners => 'Signers';

  @override
  String get siFacSignersDesc => 'Unabhängige Organisatoren = höherer Trust.';

  @override
  String get siFacMaturity => 'Reife';

  @override
  String get siFacMaturityDesc => 'Account-Alter + Regelmäßigkeit = Bonus.';

  @override
  String get siFacFrequency => 'Frequency Cap';

  @override
  String get siFacFrequencyDesc => 'Max. 2 Badges/Woche. Anti-Farming.';

  @override
  String get siBecomeOrganizer => 'ORGANISATOR WERDEN';

  @override
  String get siBecomeOrgDesc =>
      'Automatische Beförderung ab genügend Trust Score. Dann eigene QR-Codes erstellen.';

  @override
  String siProgressLabel(Object name) {
    return 'FORTSCHRITT ($name)';
  }

  @override
  String get siAlreadyOrganizer => 'Du bist bereits Organisator!';

  @override
  String get siIncreaseScore => 'SCORE ERHÖHEN';

  @override
  String get siTip1 => 'Regelmäßig verschiedene Meetups besuchen';

  @override
  String get siTip2 => 'Badges bei Meetups in anderen Städten sammeln';

  @override
  String get siTip3 => 'Badges von verschiedenen Organisatoren';

  @override
  String get siTip4 => 'Identität mit Lightning-Zap verifizieren';

  @override
  String get siTip5 => 'NIP-05 einrichten';

  @override
  String get siTip6 => 'Plattformen verknüpfen';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get badgeUnknown => 'unbekannt';

  @override
  String get badgeBlockAtScan => '₿ Blockhöhe beim Scan';

  @override
  String get mwStartMeetup => 'MEETUP STARTEN';

  @override
  String get mwStep1Nfc => 'SCHRITT 1: NFC TAG';

  @override
  String get mwNfcIntro1 =>
      'Möchtest du physische NFC-Tags (NTAG215) für dieses Meetup auslegen? ';

  @override
  String get mwNfcIntro2 =>
      'Der kryptographische Beweis (Blockzeit & Signatur) wird darauf fixiert.';

  @override
  String get mwWriteNfcTag => 'NFC TAG BESCHREIBEN';

  @override
  String get mwSkipQrOnly => 'ÜBERSPRINGEN — NUR QR NUTZEN';

  @override
  String repAllBound(Object total) {
    return 'Alle $total Badges gebunden und verifiziert';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound von $total Badges identitätsgebunden';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified kryptographisch verifiziert)';
  }

  @override
  String repAllVerified(Object total) {
    return 'Alle $total Badges kryptographisch verifiziert (noch nicht gebunden)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified von $total Badges mit Schnorr-Beweis';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count Plattform-Verknüpfungen aktiv';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'Konnte $url nicht öffnen';
  }

  @override
  String get apHowStep3 => '3. Jeder Scan = ein Badge für den Teilnehmer\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city als Home-Meetup gesetzt';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Bekannter Organisator: $name';
  }

  @override
  String get mvUnknownSigner =>
      'Kein Eintrag gefunden\nWeder in der Organisatoren-Liste noch bei den Leadern dieses Meetups ist dieser Schlüssel hinterlegt. Das Badge selbst ist gültig — die Signatur stimmt und ist an dieses Badge gebunden.';

  @override
  String get mvAdminCheckFailed =>
      '! Nicht prüfbar — die Organisatoren-Liste war gerade nicht erreichbar. Das Badge selbst ist gültig; die Signatur stimmt.';

  @override
  String get mvLegacyBadge => '! Legacy-Badge (v1) — Signer nicht prüfbar';

  @override
  String get mvBadgeBound => '🔗 Badge gebunden';

  @override
  String get nwSelectHomeMeetup =>
      '❌ Bitte erst ein Home-Meetup im Profil auswählen!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count verschiedene Empfänger';
  }

  @override
  String get apHowStep1 => '1. Starte ein neues Meetup (Session).\n';

  @override
  String get apHowStep2 => '2. Zeige danach den QR-Code.\n';

  @override
  String get apHowStep4 =>
      '4. Badges bauen Reputation auf → mehr Reputation = neue Organisatoren';

  @override
  String get ppHowStep1 =>
      '1. Wähle eine Plattform und gib deinen Usernamen ein\n';

  @override
  String get ppHowStep2 =>
      '2. Die App erstellt einen kryptographischen Beweis\n';

  @override
  String get ppHowStep3 =>
      '3. Der Beweis wird automatisch in deinen Reputation-QR eingebettet\n';

  @override
  String get ppHowStep4 =>
      '4. Andere scannen deinen QR und sehen die verifizierte Verknüpfung';

  @override
  String homeImageLoadError(Object msg) {
    return 'Bild konnte nicht geladen werden: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count gesendet';
  }

  @override
  String repShareError(Object msg) {
    return 'Fehler beim Teilen: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ Kein Home-Meetup gesetzt';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup nicht gefunden';

  @override
  String get rlWhatMeans => 'Was bedeutet das?';

  @override
  String get rlWhyImportant => 'Warum das wichtig ist';

  @override
  String get rlWeakLabel => 'Schwaches Profil';

  @override
  String get rlWeakExpl =>
      'Nur ein Beweis-Layer aktiv. Dieser Nutzer hat kaum nachprüfbare Verbindungen. Bei größeren Transaktionen: Vorsicht.';

  @override
  String get rlWeakAdvice =>
      'Frage nach weiteren Beweisen (Lightning, NIP-05) oder triff die Person zuerst persönlich.';

  @override
  String get rlLimitedLabel => 'Eingeschränkt';

  @override
  String get rlLimitedExpl =>
      'Es gibt Meetup-Badges, aber keine weiteren unabhängigen Beweise. Der Nutzer könnte echt sein — aber es fehlt die Bestätigung durch andere Layer.';

  @override
  String get rlLimitedAdvice =>
      'Für Kleinstbeträge OK. Für größere Beträge: Abwarten bis mehr Layer aktiv sind.';

  @override
  String get rlBuildingLabel => 'Aufbauend';

  @override
  String get rlBuildingExpl =>
      'Zwei Beweis-Layer aktiv. Der Nutzer baut Reputation auf, hat aber noch nicht die volle Breite.';

  @override
  String get rlBuildingAdvice => 'Für moderate Transaktionen geeignet.';

  @override
  String get rlConnectedLabel => 'Gut vernetzt';

  @override
  String get rlConnectedExpl =>
      'Mehrere unabhängige Beweise: Meetups, Lightning-Aktivität und soziale Verbindungen. Schwer zu faken.';

  @override
  String get rlConnectedAdvice =>
      'Vertrauenswürdig für die meisten Transaktionen.';

  @override
  String get rlSolidLabel => 'Solide';

  @override
  String get rlSolidExpl =>
      'Breite Basis an Beweisen. Manipulation wäre aufwändig und teuer.';

  @override
  String get rlSolidAdvice => 'Für die meisten Zwecke vertrauenswürdig.';

  @override
  String get rlDefaultExpl => 'Einige Beweise vorhanden, aber Raum für mehr.';

  @override
  String get rlDefaultAdvice => 'Eigene Einschätzung nutzen.';

  @override
  String get rlMeetupProofs => 'Meetup-Beweise';

  @override
  String get rlMeetupGood =>
      'War bei verschiedenen Meetups mit verschiedenen Organisatoren. Das erfordert physische Anwesenheit an mehreren Orten.';

  @override
  String get rlMeetupMoreDiverse => 'Mehr Vielfalt wäre überzeugender.';

  @override
  String get rlMeetupNone =>
      'Keine Meetup-Badges vorhanden. Dieser Nutzer hat noch kein Einundzwanzig-Meetup besucht — oder nutzt die App erst seit kurzem.';

  @override
  String get rlAllBound => 'Alle kryptographisch gebunden';

  @override
  String get rlGoodSpread => 'Gute regionale Streuung';

  @override
  String get rlLowSpread => 'Wenig Streuung';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Hat Meetup-Badges, aber nur von $count Organisator(en). Mehr Vielfalt wäre überzeugender.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count Badges';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound von $total gebunden';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count verschiedene Meetups';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count Organisatoren';
  }

  @override
  String get rlConfirmedByDiff => 'Von verschiedenen Personen bestätigt';

  @override
  String get rlOneOrgOnly =>
      'Nur ein Organisator — wenig unabhängige Bestätigung';

  @override
  String rlMemberSince(Object since) {
    return 'Dabei seit $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count Tage';
  }

  @override
  String get rlLightningProof => 'Lightning-Beweis';

  @override
  String get rlLnBoth =>
      'Hat echte Lightning-Zahlungen getätigt und empfangen. Bots haben keine Lightning-Wallets — das ist ein starkes Echtheitssignal.';

  @override
  String get rlLnPaid =>
      'Hat mindestens einmal über Lightning gezahlt. Grundlegender Beweis dass eine echte Wallet existiert.';

  @override
  String get rlLnActiveOnly =>
      'Lightning-Aktivität vorhanden, aber Humanity-Proof noch nicht aktiv.';

  @override
  String get rlLnNone =>
      'Keine Lightning-Aktivität. Das heißt nicht dass der Nutzer unecht ist — vielleicht nutzt er Lightning nicht über Nostr. Aber es fehlt ein wichtiges Anti-Bot-Signal.';

  @override
  String get rlHumanVerified => 'Mensch verifiziert';

  @override
  String get rlRealLnPayment => 'Echte Lightning-Zahlung nachgewiesen';

  @override
  String rlZapsSent(Object count) {
    return '$count Zaps gesendet';
  }

  @override
  String rlToRecipients(Object count) {
    return 'An $count verschiedene Empfänger';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count Zaps empfangen';
  }

  @override
  String rlFromSenders(Object count) {
    return 'Von $count verschiedenen Sendern';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count Monate aktiv';
  }

  @override
  String get rlSocialTitle => 'Soziales Netzwerk';

  @override
  String get rlSocMutualMany =>
      'Ihr kennt euch gegenseitig auf Nostr und habt viele gemeinsame Kontakte. Starke Verbindung.';

  @override
  String get rlSocMutual => 'Gegenseitiger Follow — ihr kennt euch auf Nostr.';

  @override
  String get rlSocCommon =>
      'Viele gemeinsame Kontakte — ihr bewegt euch im selben Netzwerk.';

  @override
  String get rlSocOneSided => 'Einseitige Verbindung. Ihr kennt euch flüchtig.';

  @override
  String get rlSocOrgFollow =>
      'Bekannte Einundzwanzig-Organisatoren folgen diesem Nutzer. Das ist ein positives Signal.';

  @override
  String get rlSocDefault =>
      'Es gibt Verbindungen im Nostr-Netzwerk zu diesem Nutzer.';

  @override
  String get rlSocNone =>
      'Keine Verbindung im Nostr-Netzwerk gefunden. Das kann bedeuten: Ihr seid euch noch nie auf Nostr begegnet, oder der Nutzer ist sehr neu. Bei Fremden ist das normal — bei angeblich bekannten Gesichtern ein Warnsignal.';

  @override
  String get rlMutualFollow => 'Gegenseitiger Follow';

  @override
  String get rlYouFollow => 'Du folgst';

  @override
  String get rlFollowsYou => 'Folgt dir';

  @override
  String get rlNoFollow => 'Kein Follow';

  @override
  String get rlKnowOnNostr => 'Ihr kennt euch auf Nostr';

  @override
  String get rlNoDirectConn => 'Keine direkte Verbindung';

  @override
  String rlCommonContacts(Object count) {
    return '$count gemeinsame Kontakte';
  }

  @override
  String get rlSameNetwork => 'Gleiches Netzwerk';

  @override
  String get rlSomeOverlap => 'Einige Überlappungen';

  @override
  String get rlSeparateNetworks => 'Getrennte Netzwerke';

  @override
  String rlOrgsFollow(Object count) {
    return '$count Organisatoren folgen';
  }

  @override
  String get rlEndorsement => 'Endorsement von bekannten Admins';

  @override
  String get rlIdentityTitle => 'Identitäts-Nachweis';

  @override
  String get rlIdNip05Plat =>
      'Hat eine NIP-05-Adresse und verknüpfte Plattformen. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.';

  @override
  String get rlIdNip05Only =>
      'Hat eine NIP-05-Adresse. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.';

  @override
  String get rlIdPlatOnly =>
      'Verknüpfte Plattform-Accounts. Mehr Plattformen = mehr Aufwand für Fälscher.';

  @override
  String get rlIdNone =>
      'Keine Internet-Identifikation. Komplett anonym. Das ist für Privatsphäre OK, aber gibt auch weniger Anhaltspunkte für Vertrauen.';

  @override
  String get rlLinked => 'Verknüpft';

  @override
  String get rlNoIdentification => 'Keine Identifikation';

  @override
  String get rlAnonymous => 'Anonym';

  @override
  String get rlActive => '✓ aktiv';

  @override
  String get rlActiveShort => '✓ aktiv';

  @override
  String get rlMissingShort => '— fehlt';

  @override
  String qrReceivedCount(Object count) {
    return '$count empfangen';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count verschiedene Sender';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 Beweise';
  }

  @override
  String get navNearby => 'In der Nähe';

  @override
  String get nbTitle => 'MEETUPS IN DER NÄHE';

  @override
  String get nbRequestingLocation => 'Standort wird ermittelt...';

  @override
  String get nbLoading => 'Meetups werden geladen...';

  @override
  String get nbLocationDenied => 'Standortzugriff verweigert';

  @override
  String get nbLocationDeniedSub =>
      'Ohne Standort zeigen wir alle Meetups nach Datum sortiert. Aktiviere den Standort in den Einstellungen für Entfernungen.';

  @override
  String get nbServiceDisabled => 'Standortdienste sind deaktiviert';

  @override
  String get nbRetryLocation => 'Standort erneut versuchen';

  @override
  String get nbContinueWithout => 'Ohne Standort fortfahren';

  @override
  String get nbNoMeetups => 'Keine Meetups für diesen Zeitraum';

  @override
  String get nbNoMeetupsSub =>
      'Versuch einen anderen Filter oder ein anderes Datum.';

  @override
  String get nbFilterToday => 'Heute';

  @override
  String get nbFilterWeek => 'Diese Woche';

  @override
  String get nbFilterUpcoming => 'Alle kommenden';

  @override
  String get nbFilterAll => 'Alle';

  @override
  String get nbPickDate => 'Datum wählen';

  @override
  String nbKmAway(Object km) {
    return '$km km entfernt';
  }

  @override
  String get nbNoDate => 'Kein Termin angekündigt';

  @override
  String nbListHeader(Object count) {
    return '$count Meetups';
  }

  @override
  String get nbOpenInMaps => 'In Karten öffnen';

  @override
  String get nbYourLocation => 'Dein Standort';

  @override
  String get nbToday => 'Heute';

  @override
  String get nbTomorrow => 'Morgen';

  @override
  String get nbResetDate => 'Filter zurücksetzen';

  @override
  String get nbModeHere => 'Hier & jetzt';

  @override
  String get nbModePlanned => 'Geplant';

  @override
  String get nbRadius => 'Umkreis';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Ort suchen (z.B. Hamburg)';

  @override
  String get nbSearchingPlace => 'Suche Orte...';

  @override
  String get nbNoPlaceFound => 'Kein Ort gefunden';

  @override
  String get nbCenterHere => 'Mein Standort';

  @override
  String get nbChangePlace => 'Ort ändern';

  @override
  String get nbDateAny => 'Jederzeit';

  @override
  String get nbDateSingle => 'Datum';

  @override
  String get nbDateRange => 'Zeitraum';

  @override
  String get nbPickDay => 'Tag wählen';

  @override
  String get nbPickRange => 'Zeitraum wählen';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count Meetups im Umkreis';
  }

  @override
  String get nbNoneInRadius => 'Keine Meetups im Umkreis';

  @override
  String get nbNoneInRadiusSub =>
      'Vergrößere den Umkreis oder ändere Ort/Datum.';

  @override
  String get nbApplySearch => 'Suchen';

  @override
  String nbMoreDates(Object count) {
    return '+$count weitere Termine';
  }

  @override
  String get nbDirections => 'Route';

  @override
  String get nbDetails => 'Details';

  @override
  String get settingsSectionProfile => 'Profil';

  @override
  String get settingsProfile => 'Profil bearbeiten';

  @override
  String get settingsProfileSub => 'Name, Nostr-Schlüssel & Home-Meetup';

  @override
  String get apCreateEvent => 'Termin erstellen';

  @override
  String get apCreateEventSub => 'Im Portal eintragen';

  @override
  String get apCreateEventTitle => 'Termin im Portal erstellen';

  @override
  String get apCreateEventBody =>
      'Meetup-Termine werden zentral im Einundzwanzig-Portal verwaltet. Die App öffnet jetzt das Portal in deinem Browser — dort meldest du dich mit deinem Nostr-Schlüssel an und trägst den Termin ein. Er erscheint danach automatisch hier im Kalender.';

  @override
  String get apOpenPortal => 'Portal öffnen';

  @override
  String get apNoHomeMeetupSet =>
      'Wähle zuerst dein Home-Meetup im Profil, dann kannst du Termine dafür erstellen.';

  @override
  String get apPortalHint =>
      'Warum nicht direkt in der App? Das Portal ist die zentrale Quelle für alle Termine und braucht deine Anmeldung. Eine direkte Eintragung aus der App ist geplant, sobald das Portal das unterstützt.';

  @override
  String get rcTitle => 'Reputations-Profil';

  @override
  String get rcShareImage => 'Als Bild teilen';

  @override
  String get rcSaving => 'Bild wird erstellt...';

  @override
  String rcShareError(Object error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get rcShareText => 'Mein Einundzwanzig Trust Score & Reputation';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Level';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Städte';

  @override
  String get rcLabelSigners => 'Bürgen';

  @override
  String get rcLabelAge => 'Tage dabei';

  @override
  String get rcMember => 'Einundzwanzig Mitglied';

  @override
  String get rcNoData => 'Noch keine Reputation. Sammle Badges auf Meetups!';

  @override
  String get caOptInTitle => 'Zum Vertrauensnetzwerk beitragen?';

  @override
  String get caOptInBody =>
      'Du kannst deine Teilnahme an diesem Meetup im öffentlichen Vertrauensnetzwerk bestätigen. Andere sehen dann, dass dein npub bei diesem Meetup war — und über gemeinsame Meetups, wie ihr vernetzt seid.\n\nDas ist freiwillig. Dein Badge bekommst du auch ohne Teilnahme am Netzwerk.';

  @override
  String get caOptInPrivacy =>
      'Öffentlich & dauerhaft auf Nostr-Relays. Zeigt ein Bewegungs- und Kontaktmuster. Überleg es dir gut.';

  @override
  String get caOptInYes => 'Ja, beitragen';

  @override
  String get caOptInNo => 'Nein, privat bleiben';

  @override
  String get caPublished => 'Teilnahme im Netzwerk bestätigt';

  @override
  String get cnTitle => 'Netzwerk-Analyse';

  @override
  String get cnSubtitle =>
      'Wie ist diese Person über gemeinsame Meetups vernetzt?';

  @override
  String get cnEnterNpub => 'npub der Person eingeben';

  @override
  String get cnScan => 'Scannen';

  @override
  String get cnAnalyze => 'Analysieren';

  @override
  String get cnLoading => 'Netzwerk wird geladen...';

  @override
  String get cnSharedMeetups => 'Gemeinsame Meetups';

  @override
  String get cnMutualContacts => 'Gemeinsame Kontakte';

  @override
  String get cnReach => 'Vernetzung der Person';

  @override
  String get cnTotalMeetups => 'Meetups besucht';

  @override
  String get cnTotalContacts => 'Personen getroffen';

  @override
  String get cnNoConnection => 'Keine Verbindung gefunden';

  @override
  String get cnNoConnectionSub =>
      'Ihr wart auf keinen gemeinsamen Meetups und habt keine gemeinsamen Kontakte im Netzwerk — oder die Person nimmt nicht am Netzwerk teil.';

  @override
  String get cnDirectMet => 'Ihr habt euch direkt getroffen!';

  @override
  String get cnYou => 'Du';

  @override
  String get cnTarget => 'Diese Person';

  @override
  String cnViaShared(Object count) {
    return 'über $count gemeinsame Meetups';
  }

  @override
  String get cnTrustHint =>
      'Je mehr gemeinsame Meetups und Kontakte, desto stärker das organische Vertrauen.';

  @override
  String get cnInvalidNpub => 'Ungültiger npub';

  @override
  String get cnPrivacyNote =>
      'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in).';

  @override
  String get tileTrustNetwork => 'Vertrauensnetzwerk';

  @override
  String get tileTrustNetworkSub => 'Vernetzung prüfen';

  @override
  String get tnHubTitle => 'Vertrauensnetzwerk';

  @override
  String get tnHubIntro =>
      'Prüfe, wie vertrauenswürdig eine Person im Einundzwanzig-Netzwerk ist — über Bürgschaften und gemeinsame Meetups.';

  @override
  String get tnHubNetTitle => 'Netzwerk-Analyse';

  @override
  String get tnHubNetSub => 'Gemeinsame Meetups & Kontakte einer Person';

  @override
  String get orgBadgeCreated => 'Organisator-Teilnahme erfasst';

  @override
  String get orgBadgeLabel => 'Organisator';

  @override
  String get orgBadgeSub => 'Du hast dieses Meetup veranstaltet';

  @override
  String get mnTitle => 'Meine Vernetzung';

  @override
  String get mnIntro =>
      'Dein Vertrauensnetzwerk aus echten Meetup-Begegnungen — und wer darüber hinaus mit dir verbunden ist.';

  @override
  String get mnLoading => 'Netzwerk wird aufgebaut...';

  @override
  String get mnEmpty => 'Noch keine Vernetzung';

  @override
  String get mnEmptySub =>
      'Besuche Meetups und sammle Badges (mit Netzwerk-Teilnahme), um dein Vertrauensnetzwerk aufzubauen.';

  @override
  String get mnDegree1 => 'Direkt getroffen';

  @override
  String get mnDegree1Sub => 'Personen, die du live auf Meetups getroffen hast';

  @override
  String get mnDegree2 => 'Über Kontakte verbunden';

  @override
  String get mnDegree2Sub =>
      'Personen, die deine Kontakte auf Meetups getroffen haben';

  @override
  String get mnDegree3 => 'Erweitertes Netzwerk';

  @override
  String get mnDegree3Sub => 'Noch eine Ebene weiter im Netzwerk';

  @override
  String mnSharedMeetups(Object count) {
    return '$count gemeinsame Meetups';
  }

  @override
  String get mnOneSharedMeetup => '1 gemeinsames Meetup';

  @override
  String mnViaContacts(Object count) {
    return 'über $count Kontakte';
  }

  @override
  String get mnViaOneContact => 'über 1 Kontakt';

  @override
  String get mnReachLabel => 'Reichweite';

  @override
  String get mnDirectLabel => 'Direkt';

  @override
  String get mnIndirectLabel => 'Indirekt';

  @override
  String get mnTrustHint =>
      'Indirekte Kontakte über echte Begegnungen erhöhen dein Vertrauen schrittweise — auch ohne dass du die Person selbst getroffen hast.';

  @override
  String get mnPrivacyNote =>
      'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in beim Badge-Scan).';

  @override
  String get mnCheckPerson => 'Bestimmte Person prüfen';

  @override
  String get settingsHeaderTitle => 'Einstellungen';

  @override
  String get settingsHeaderSub => 'App & Account verwalten';

  @override
  String get settingsSecAccount => 'ACCOUNT';

  @override
  String get settingsSecData => 'DATEN & SICHERHEIT';

  @override
  String get settingsSecNetwork => 'NETZWERK';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'GEFAHRENZONE';

  @override
  String get vpTitle => 'Person prüfen';

  @override
  String get vpIntro =>
      'Prüfe über echte Meetup-Begegnungen, ob und wie diese Person mit dir verbunden ist.';

  @override
  String get vpEnterNpub => 'npub eingeben oder Reputations-QR scannen';

  @override
  String get vpScanQr => 'QR scannen';

  @override
  String get vpCheck => 'Prüfen';

  @override
  String get vpChecking => 'Verbindung wird geprüft...';

  @override
  String get vpDirectTitle => 'Direkt getroffen!';

  @override
  String vpDirectSub(Object count) {
    return 'Ihr wart gemeinsam auf $count Meetups.';
  }

  @override
  String get vpDirectSubOne => 'Ihr wart gemeinsam auf einem Meetup.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Über $count Ecken verbunden';
  }

  @override
  String get vpIndirectSub =>
      'Diese Person ist über echte Meetup-Begegnungen mit dir verbunden.';

  @override
  String get vpNoneTitle => 'Keine Verbindung gefunden';

  @override
  String get vpNoneSub =>
      'Es gibt aktuell keine bekannte Meetup-Verbindung zu dir.';

  @override
  String get vpNotInNetwork =>
      'Diese Person nimmt (noch) nicht am Netzwerk teil.';

  @override
  String get vpPathTitle => 'Verbindungspfad';

  @override
  String get vpYou => 'Du';

  @override
  String get vpTarget => 'Diese Person';

  @override
  String get vpMetAt => 'gemeinsames Meetup';

  @override
  String get vpInvalidNpub => 'Ungültiger npub';

  @override
  String get vpTrustNote =>
      'Je näher die Verbindung (kleinerer Grad), desto stärker das Vertrauen über physische Präsenz.';

  @override
  String get vpSelfTitle => 'Das bist du selbst';

  @override
  String get gpsRequired => 'Standort erforderlich';

  @override
  String get gpsRequiredOrg =>
      'Zum Erstellen eines Meetups wird dein Standort benötigt. Er legt den Ort des Meetups fest.';

  @override
  String get gpsRequiredScan =>
      'Zum Sammeln dieses Badges wird dein Standort benötigt — als Nachweis, dass du vor Ort bist.';

  @override
  String get gpsDenied =>
      'Standortzugriff verweigert. Bitte in den Einstellungen erlauben.';

  @override
  String get gpsDisabled =>
      'Standortdienste sind deaktiviert. Bitte aktivieren.';

  @override
  String get gpsError =>
      'Kein GPS-Signal erhalten. In Gebäuden dauert die Ortung oft länger – geh kurz ans Fenster oder vor die Tür und versuche es erneut.';

  @override
  String get gpsRetry => 'Erneut versuchen';

  @override
  String get gpsPickMeetup => 'Welches Meetup?';

  @override
  String get gpsPickMeetupSub =>
      'Mehrere Meetups sind in deiner Nähe. Bitte wähle das richtige.';

  @override
  String gpsDistanceKm(Object km) {
    return '$km km entfernt';
  }

  @override
  String get gpsNoMeetupNearby => 'Kein bekanntes Meetup in der Nähe gefunden.';

  @override
  String get gpsTooFar => 'Zu weit entfernt';

  @override
  String gpsTooFarSub(Object km, Object max) {
    return 'Du bist $km km vom Meetup-Ort entfernt. Badges können nur vor Ort gesammelt werden (max. $max km).';
  }

  @override
  String get mapTitle => 'Meine Badge-Weltkarte';

  @override
  String get mapButton => 'Auf der Karte ansehen';

  @override
  String get mapStatMeetups => 'Meetups';

  @override
  String get mapStatCities => 'Städte';

  @override
  String get mapStatCountries => 'Länder';

  @override
  String mapShareText(Object count) {
    return 'Hier war ich überall! 🌍 $count Meetups auf meiner Einundzwanzig Badge-Weltkarte.';
  }

  @override
  String get mapShareButton => 'Als Bild teilen';

  @override
  String get mapEmpty => 'Noch keine Badges mit Standort';

  @override
  String get mapEmptySub =>
      'Sammle Badges auf Meetups — sie erscheinen dann hier auf deiner Weltkarte.';

  @override
  String get gpsNoMeetupTitle => 'Kein Meetup in der Nähe';

  @override
  String get gpsNoMeetupBody =>
      'Im Umkreis von 10 km ist kein bekanntes Meetup eingetragen. Du kannst trotzdem eine Session starten — gib deinem Meetup einen Titel. Dein aktueller Standort wird automatisch als Veranstaltungsort auf der Karte gesetzt.';

  @override
  String get gpsMeetupNameLabel => 'Titel des Meetups';

  @override
  String get gpsMeetupNameHint => 'z. B. Bitcoin Stammtisch';

  @override
  String get gpsStartAnyway => 'Session starten';

  @override
  String get gpsNameRequired => 'Bitte gib einen Namen ein.';

  @override
  String get mnNodeDetailTitle => 'Verknüpfung';

  @override
  String get mnDegreeDirect => 'Direkt verbunden';

  @override
  String get mnDegreeSecond => '2. Grad';

  @override
  String get mnDegreeThird => '3. Grad';

  @override
  String get mnSharedMeetupsList => 'Gemeinsame Meetups';

  @override
  String get mnViaBridges => 'Verbunden über';

  @override
  String get mnNoSharedDetail => 'Keine direkten gemeinsamen Meetups';

  @override
  String get mnOpenInNostr => 'In Nostr öffnen';

  @override
  String get mnTapHint => 'Tippe auf einen Punkt für Details';

  @override
  String get mnLegendDirect => 'Direkt (1. Grad)';

  @override
  String get mnLegendSecond => '2. Grad';

  @override
  String get mnLegendThird => '3. Grad';

  @override
  String get resetBackupTitle => 'Daten sichern?';

  @override
  String get resetBackupBody =>
      'Beim Zurücksetzen werden ALLE Daten unwiderruflich gelöscht — deine Badges, dein Schlüssel und dein Profil. Ohne Backup lassen sich Badges NICHT wiederherstellen (auch nicht über Nostr). Möchtest du zuerst ein Backup erstellen?';

  @override
  String get resetBackupCreate => 'Backup erstellen';

  @override
  String get resetBackupSkip => 'Ohne Backup zurücksetzen';

  @override
  String get resetBackupDone => 'Backup erstellt. Jetzt zurücksetzen?';

  @override
  String get resetNowConfirm => 'Jetzt zurücksetzen';

  @override
  String get verifyBadgeSaved => 'Badge gespeichert ✓';

  @override
  String get tileConverter => 'Rechner';

  @override
  String get tileConverterSub => 'Kurs & Sats';

  @override
  String get convTitle => 'Wechselrechner';

  @override
  String get convYouPay => 'Betrag';

  @override
  String convRateInfo(Object price, Object cur) {
    return '1 BTC = $price $cur';
  }

  @override
  String convUpdated(Object time) {
    return 'Aktualisiert: $time';
  }

  @override
  String get convRefresh => 'Kurs aktualisieren';

  @override
  String get convOffline => 'Kurs konnte nicht geladen werden. Bist du online?';

  @override
  String get convLoading => 'Lade Kurs …';

  @override
  String get convSwap => 'Tauschen';

  @override
  String get convSelectCurrency => 'Währung wählen';

  @override
  String get convUnitSats => 'Satoshi';

  @override
  String get convUnitBtc => 'Bitcoin';

  @override
  String get convSource => 'Kurs von mempool.space';

  @override
  String get tileNews => 'News';

  @override
  String get tileNewsSub => 'Einundzwanzig Artikel lesen';

  @override
  String get newsTitle => 'News';

  @override
  String get newsEmpty => 'Keine Artikel gefunden.';

  @override
  String get newsLoading => 'Lade Artikel …';

  @override
  String get newsRefresh => 'Aktualisieren';

  @override
  String get newsSource => 'Artikel via Nostr (NIP-23)';

  @override
  String get newsOpenWebsite => 'Auf der Webseite öffnen';

  @override
  String get keyEduTitle => 'Dein Schlüssel zu Nostr';

  @override
  String get keyEduWhatNostrH => 'Was ist Nostr?';

  @override
  String get keyEduWhatNostrB =>
      'Nostr ist ein offenes, dezentrales Netzwerk – ähnlich wie das Internet selbst, aber für soziale Identität. Es gehört niemandem. Es gibt keine Firma, keinen Account und kein Passwort im klassischen Sinn. Statt dich bei einem Anbieter anzumelden, besitzt du einen kryptografischen Schlüssel, der dich überall im Netzwerk ausweist.';

  @override
  String get keyEduPairH => 'Dein Schlüsselpaar';

  @override
  String get keyEduPairB =>
      'Du bekommst gleich zwei zusammengehörige Schlüssel. Sie funktionieren wie ein Briefkasten: Der öffentliche Schlüssel ist die Adresse, die du jedem geben darfst – der private Schlüssel ist der einzige Schlüssel, der den Briefkasten öffnet.';

  @override
  String get keyEduNpubH => 'npub – dein öffentlicher Schlüssel';

  @override
  String get keyEduNpubB =>
      'Der npub (beginnt mit „npub1…“) ist deine öffentliche Identität. Du darfst ihn frei teilen – so finden dich andere, sehen deine Beiträge und können dir folgen. Er ist wie dein Benutzername, nur dass er dir wirklich gehört und niemand ihn dir wegnehmen kann.';

  @override
  String get webKeyWarnH => 'Im Browser weniger geschützt';

  @override
  String get webKeyWarnB =>
      'Die App für iPhone und Android speichert deinen Schlüssel im gesicherten Bereich des Geräts. Im Browser ist das nicht möglich — dort kann er leichter ausgelesen werden.';

  @override
  String get webKeyWarnAdvice =>
      'Nutze im Browser am besten eine eigene Test-Identität und trage hier nicht den Schlüssel ein, an dem deine Nostr-Identität hängt.';

  @override
  String get keyEduNsecH => 'nsec – dein privater Schlüssel';

  @override
  String get keyEduNsecB =>
      'Der nsec (beginnt mit „nsec1…“) ist dein Geheimnis. Wer ihn besitzt, IST du – er kann in deinem Namen posten, deine Identität übernehmen und deine Reputation missbrauchen. Gib ihn NIEMALS weiter, tippe ihn nirgends ein, wo du unsicher bist, und mache niemals ein Foto davon in einer Cloud. Es gibt kein „Passwort vergessen“: Ist der nsec weg, ist die Identität für immer verloren.';

  @override
  String get keyEduIdentityH => 'Eine Identität, viele Möglichkeiten';

  @override
  String get keyEduIdentityB =>
      'Dieses Schlüsselpaar ist nicht nur für diese App. Es ist deine Identität im gesamten Nostr-Netzwerk: dieselbe Identität kannst du in vielen anderen Nostr-Apps nutzen – für soziale Netzwerke, Blogs, Chats, Lightning-Zahlungen und mehr. In dieser App ist sie zusätzlich mit deiner Reputation, deinen Meetup-Badges und deinem Vertrauensnetzwerk verknüpft. Deshalb ist ihr Schutz so wichtig: Verlierst du den Schlüssel, verlierst du nicht nur einen Login, sondern alles, was du dir aufgebaut hast.';

  @override
  String get keyEduProtectH => 'So schützt du deinen Schlüssel';

  @override
  String get keyEduProtect1 =>
      'Sichere den nsec sofort (z. B. in einem Passwort-Manager).';

  @override
  String get keyEduProtect2 => 'Teile nur den npub – niemals den nsec.';

  @override
  String get keyEduProtect3 =>
      'Lege ein verschlüsseltes Backup an (in dieser App möglich).';

  @override
  String get keyEduProtect4 =>
      'Für mehr Sicherheit: nutze eine Signer-App wie Amber.';

  @override
  String get keyEduUnderstood => 'Verstanden, Schlüssel erstellen';

  @override
  String get keyEduCancel => 'Abbrechen';

  @override
  String get keyEduIntro =>
      'Bevor du startest: Gleich erhältst du dein eigenes Schlüsselpaar. Nimm dir kurz Zeit – es lohnt sich zu verstehen, was du da bekommst.';

  @override
  String get tilePortal => 'Meine Meetups';

  @override
  String get tilePortalSub => 'Termine im Portal verwalten';

  @override
  String get portalTitle => 'Meine Meetups';

  @override
  String get portalNotConnected => 'Mit dem Portal verbinden';

  @override
  String get portalConnectInfo =>
      'Melde dich mit deinem Nostr-Schlüssel am Einundzwanzig-Portal an, um deine Meetup-Termine direkt aus der App zu verwalten.';

  @override
  String get portalConnect => 'Anmelden';

  @override
  String get portalConnecting => 'Anmeldung läuft …';

  @override
  String get portalLogout => 'Abmelden';

  @override
  String get portalLoginFailed => 'Anmeldung fehlgeschlagen';

  @override
  String get portalLoadingMeetups => 'Lade deine Meetups …';

  @override
  String get portalNoMeetups => 'Du verwaltest noch keine Meetups im Portal.';

  @override
  String get portalLeader => 'Organisator';

  @override
  String get portalNewEvent => 'Termin anlegen';

  @override
  String get portalEventTitle => 'Neuer Termin';

  @override
  String get portalFieldStart => 'Datum & Uhrzeit';

  @override
  String get portalPickDate => 'Datum wählen';

  @override
  String get portalPickTime => 'Uhrzeit wählen';

  @override
  String get portalFieldLocation => 'Ort';

  @override
  String get portalFieldLocationHint => 'z.B. Bitcoin-Treff Café (optional)';

  @override
  String get portalFieldDescription => 'Beschreibung';

  @override
  String get portalFieldDescriptionHint => 'Worum geht es? (optional)';

  @override
  String get portalFieldLink => 'Link';

  @override
  String get portalFieldLinkHint => 'https://… (optional)';

  @override
  String get portalSave => 'Termin speichern';

  @override
  String get portalSaving => 'Wird gespeichert …';

  @override
  String get portalCreatedOk => 'Termin angelegt ✓';

  @override
  String get portalNeedStart => 'Bitte Datum & Uhrzeit wählen.';

  @override
  String get portalSource => 'Verbunden mit portal.einundzwanzig.space';

  @override
  String get evCalendarButton => 'Veranstaltungskalender';

  @override
  String get evCalendarButtonSub => 'Alle Events im Überblick';

  @override
  String get calTitle => 'Veranstaltungskalender';

  @override
  String get calViewMonth => 'Monat';

  @override
  String get calViewYear => 'Jahr';

  @override
  String get calViewList => 'Liste';

  @override
  String get calToday => 'Heute';

  @override
  String get calNoEvents => 'Keine Veranstaltungen an diesem Tag.';

  @override
  String get calNoEventsRange => 'Keine Veranstaltungen in diesem Zeitraum.';

  @override
  String get calLoading => 'Lade Veranstaltungen …';

  @override
  String get calAddEvent => 'Event eintragen';

  @override
  String get calAllDay => 'Ganztägig';

  @override
  String get calSource => 'Events via Nostr (NIP-52)';

  @override
  String get calNewEventTitle => 'Veranstaltung eintragen';

  @override
  String get calFieldTitle => 'Titel';

  @override
  String get calFieldTitleHint => 'z.B. BTC Prag, Zitadelle …';

  @override
  String get calFieldLocation => 'Ort';

  @override
  String get calFieldLocationHint => 'z.B. Prag, Tschechien';

  @override
  String get calFieldDescription => 'Beschreibung';

  @override
  String get calFieldDescriptionHint => 'Worum geht es? (optional)';

  @override
  String get calFieldAllDay => 'Ganztägige Veranstaltung';

  @override
  String get calFieldStart => 'Beginn';

  @override
  String get calFieldEnd => 'Ende (optional)';

  @override
  String get calPickDateTime => 'Datum & Uhrzeit wählen';

  @override
  String get calPickDate => 'Datum wählen';

  @override
  String get calClearEnd => 'Ende entfernen';

  @override
  String get calPublish => 'Bei Nostr veröffentlichen';

  @override
  String get calPublishing => 'Wird veröffentlicht …';

  @override
  String get calPublishFail =>
      'Veröffentlichung fehlgeschlagen. Online & angemeldet?';

  @override
  String get calNeedTitle => 'Bitte gib einen Titel ein.';

  @override
  String get calNeedStart => 'Bitte Beginn wählen.';

  @override
  String get calPublishInfo =>
      'Diese Veranstaltung wird öffentlich bei Nostr eingetragen – jeder mit dieser App sieht sie in seinem Kalender.';

  @override
  String get calMonth1 => 'Januar';

  @override
  String get calMonth2 => 'Februar';

  @override
  String get calMonth3 => 'März';

  @override
  String get calMonth4 => 'April';

  @override
  String get calMonth5 => 'Mai';

  @override
  String get calMonth6 => 'Juni';

  @override
  String get calMonth7 => 'Juli';

  @override
  String get calMonth8 => 'August';

  @override
  String get calMonth9 => 'September';

  @override
  String get calMonth10 => 'Oktober';

  @override
  String get calMonth11 => 'November';

  @override
  String get calMonth12 => 'Dezember';

  @override
  String get calWd0 => 'Mo';

  @override
  String get calWd1 => 'Di';

  @override
  String get calWd2 => 'Mi';

  @override
  String get calWd3 => 'Do';

  @override
  String get calWd4 => 'Fr';

  @override
  String get calWd5 => 'Sa';

  @override
  String get calWd6 => 'So';

  @override
  String get calTypeMeetup => 'Meetup';

  @override
  String get calTypeEvent => 'Event';

  @override
  String get calLegendMeetup => 'Meetups';

  @override
  String get calLegendEvent => 'Veranstaltungen';

  @override
  String get portalManageEvents => 'Termine verwalten';

  @override
  String get portalExistingEvents => 'Bestehende Termine';

  @override
  String get portalLoadingEvents => 'Lade Termine …';

  @override
  String get portalNoEvents => 'Noch keine Termine für dieses Meetup.';

  @override
  String get portalEditEvent => 'Termin bearbeiten';

  @override
  String get portalUpdatedOk => 'Termin aktualisiert ✓';

  @override
  String get portalUpdate => 'Änderungen speichern';

  @override
  String get portalTapToEdit => 'Zum Bearbeiten antippen';

  @override
  String get hubTitle => 'Events';

  @override
  String get hubMeetups => 'Meetups';

  @override
  String get hubMeetupsSub => 'Meetups suchen & entdecken';

  @override
  String get hubCalendar => 'Veranstaltungskalender';

  @override
  String get hubCalendarSub => 'Alle Termine im Überblick, farblich sortiert';

  @override
  String get hubExternal => 'Externe Termine';

  @override
  String get hubExternalSub => 'Konferenzen & Events der Community';

  @override
  String get extTitle => 'Externe Termine';

  @override
  String get extIntro =>
      'Von der Community eingetragene Veranstaltungen (keine Meetups) – z.B. Konferenzen wie die BTC Prag oder die Zitadelle.';

  @override
  String get extLoading => 'Lade externe Termine …';

  @override
  String get extNone => 'Noch keine externen Termine eingetragen.';

  @override
  String get extAdd => 'Event eintragen';

  @override
  String get calFilterAll => 'Alle';

  @override
  String get calFilterMeetups => 'Meetups';

  @override
  String get calFilterExternal => 'Externe';

  @override
  String get calFilterLocation => 'Ort/Land suchen …';

  @override
  String get calFilterActive => 'Filter aktiv';

  @override
  String get calFilterClear => 'Filter zurücksetzen';

  @override
  String get calFilterNoMatch => 'Keine Events für diesen Filter.';

  @override
  String get calWorldwide => 'Weltweit';

  @override
  String get calCommunityOnly => 'Nur Community';

  @override
  String get calWorldwideHint =>
      'Weltweit zeigt alle Nostr-Events – auch fremde.';

  @override
  String get chTitle => 'Community';

  @override
  String get chPortal => 'Portal';

  @override
  String get chPortalSub => 'Meetups · Events · Kurse · Karte';

  @override
  String get chNews => 'News';

  @override
  String get chNewsSub => 'Artikel lesen';

  @override
  String get chNostr => 'Nostr';

  @override
  String get chNostrSub => 'Community-Feed';

  @override
  String get chShoutout => 'Shoutout';

  @override
  String get chShoutoutSub => 'Senden';

  @override
  String get chPodcast => 'Podcast';

  @override
  String get chPodcastSub => 'Anhören';

  @override
  String get paTitle => 'Portal';

  @override
  String get paMeetups => 'Meetups';

  @override
  String get paMeetupsSub => 'Alle Meetups durchsuchen';

  @override
  String get paEvents => 'Events & Zusagen';

  @override
  String get paEventsSub => 'Termine ansehen und direkt zusagen';

  @override
  String get paCourses => 'Kurse & Dozenten';

  @override
  String get paCoursesSub => 'Das Einundzwanzig-Bildungsangebot';

  @override
  String get paMap => 'Karte';

  @override
  String get paMapSub => 'Meetups in der Nähe';

  @override
  String get paMine => 'Meine Meetups';

  @override
  String get paMineSub => 'Termine verwalten (Organisator)';

  @override
  String get paWeb => 'Portal-Webseite';

  @override
  String get paWebSub => 'portal.einundzwanzig.space im Browser';

  @override
  String get rsvpLoading => 'Lade Events …';

  @override
  String get rsvpNone => 'Keine kommenden Events gefunden.';

  @override
  String get rsvpGoing => 'Zusagen';

  @override
  String get rsvpYouGo => 'Du hast zugesagt ✓';

  @override
  String get rsvpCount => 'Zusagen';

  @override
  String get rsvpNeedLogin =>
      'Zum Zusagen bitte zuerst im Portal anmelden (Meine Meetups).';

  @override
  String rsvpFailed(String msg) {
    return 'Antwort nicht gespeichert: $msg';
  }

  @override
  String get crsLoading => 'Lade Kurse …';

  @override
  String get crsNone => 'Keine Kurse gefunden.';

  @override
  String get crsCourses => 'Kurse';

  @override
  String get crsLecturers => 'Dozenten';

  @override
  String get rsvpCancel => 'Absagen';

  @override
  String get crsAbout => 'Über den Kurs';

  @override
  String get crsUpcoming => 'Kommende Termine';

  @override
  String get crsLecturer => 'Referent';

  @override
  String get lecAbout => 'Über den Referenten';

  @override
  String get lecLinks => 'Links';

  @override
  String get crsOpenPortal => 'Im Portal öffnen';

  @override
  String get rsvpImComing => 'Ich komme';

  @override
  String get rsvpMaybe => 'Vielleicht';

  @override
  String get evOpenLink => 'Link öffnen';

  @override
  String get evShare => 'Teilen';

  @override
  String get evToCalendar => 'Zum Kalender';

  @override
  String get portalConnected => 'Portal verbunden';

  @override
  String get portalLoginPrompt =>
      'Zum Zusagen verbinden wir dich mit dem Portal.';

  @override
  String get portalTileSub => 'Für Zusagen & eigene Meetups';

  @override
  String get ldTitle => 'Organisatoren';

  @override
  String get ldManage => 'Organisatoren verwalten';

  @override
  String get ldManageSub => 'Vertraute als Leader hinzufügen';

  @override
  String get ldPickMeetup => 'Meetup wählen';

  @override
  String get ldCreator => 'Ersteller';

  @override
  String get ldAdd => 'Organisator hinzufügen';

  @override
  String get ldAddHint => 'npub des neuen Organisators';

  @override
  String get ldAddDo => 'Hinzufügen';

  @override
  String get ldRemove => 'Entfernen';

  @override
  String get ldRemoveConfirm => 'Diesen Organisator entfernen?';

  @override
  String get ldAdded => 'Organisator hinzugefügt';

  @override
  String get ldRemoved => 'Organisator entfernt';

  @override
  String get ldFailed => 'Aktion fehlgeschlagen';

  @override
  String get ldEmpty => 'Noch keine weiteren Organisatoren.';

  @override
  String get ldLoading => 'Lade Organisatoren …';

  @override
  String get ldNpubInvalid => 'Bitte einen gültigen npub eingeben.';

  @override
  String get ldAddButton => 'Admin hinzufügen';

  @override
  String get calLegendCourse => 'Kurse';

  @override
  String get calFilterCourses => 'Kurse';

  @override
  String get refreshRunning => 'Aktualisiere Daten …';

  @override
  String get refreshDone => 'Alles aktualisiert';

  @override
  String get v4vSectionTitle => 'Unterstützen';

  @override
  String get v4vSectionSubtitle =>
      'Value for Value – das Projekt mit Sats unterstützen';

  @override
  String get v4vTitle => 'Value for Value';

  @override
  String get v4vHeadline => 'Value for Value';

  @override
  String get v4vExplain1 =>
      'Diese App entsteht in echter Handarbeit für die Community – ohne Werbung, ohne Tracking, ohne Abo. Nach dem Prinzip \"Value for Value\" gibst du zurück, was dir die App wert ist.';

  @override
  String get v4vExplain2 =>
      'Deine Sats fließen direkt in die Weiterentwicklung des Projekts. Jeder Betrag hilft – vielen Dank!';

  @override
  String get v4vAmountLabel => 'Betrag';

  @override
  String get v4vDonateButton => 'Mit Lightning spenden';

  @override
  String get v4vRecipient => 'Empfänger';

  @override
  String get v4vErrInvalidAmount => 'Bitte einen gültigen Betrag eingeben.';

  @override
  String get v4vErrBelowMin => 'Betrag ist zu niedrig für diese Adresse.';

  @override
  String get v4vErrAboveMax => 'Betrag ist zu hoch für diese Adresse.';

  @override
  String get v4vErrUnreachable =>
      'Verbindung fehlgeschlagen. Bitte später erneut versuchen.';

  @override
  String get v4vErrGeneric => 'Die Invoice konnte nicht erstellt werden.';

  @override
  String get v4vNoWalletTitle => 'Keine Lightning-Wallet gefunden';

  @override
  String get v4vNoWalletBody =>
      'Es wurde keine App zum Bezahlen gefunden. Du kannst die Rechnung kopieren und in deiner Wallet einfügen.';

  @override
  String get v4vCopyInvoice => 'Rechnung kopieren';

  @override
  String get v4vCopied => 'Rechnung kopiert';

  @override
  String get convPremiumTitle => 'Auf-/Abschlag';

  @override
  String get convPremiumHint =>
      'Für Trades: Prozent-Aufschlag (+) oder Abschlag (−) auf den Kurs.';

  @override
  String get convPremiumResult => 'Mit Auf-/Abschlag';

  @override
  String get convPremiumBase => 'Basiskurs';

  @override
  String get convPremiumSats => 'Ergebnis in Sats';

  @override
  String get portalTokenMismatch =>
      'Dein Portal-Login gehört zu einem anderen Nostr-Schlüssel und wurde getrennt. Bitte verbinde das Portal neu — mit dem Schlüssel, mit dem du dort Leiter bist.';

  @override
  String get settingsLogTitle => 'Diagnose-Log';

  @override
  String get settingsLogSub => 'Ereignisse für die Fehlersuche';

  @override
  String get rsvpNoNames =>
      'Das Portal stellt für dieses Event keine Namensliste bereit.';

  @override
  String get rsvpAnon => 'Anonym';

  @override
  String get settingsMempool => 'Mempool-Server';

  @override
  String get settingsMempoolSub => 'Quelle der Bitcoin-Daten';

  @override
  String get mempoolTitle => 'Mempool-Server';

  @override
  String get mempoolIntro =>
      'Von hier holt die App Blockhöhe, Gebühren, Kurs und Lightning-Daten. Standard ist mempool.space. Wer über Tor surft, sollte die Onion-Adresse wählen — mempool.space weist Anfragen von Tor-Exit-Knoten oft ab.';

  @override
  String get mempoolClearnetTitle => 'Standard (Clearnet)';

  @override
  String get mempoolTorTitle => 'Tor / Onion';

  @override
  String get mempoolTorSub => 'Offizielle .onion von mempool.space';

  @override
  String get mempoolTorHint =>
      'Funktioniert nur, wenn Orbot im VPN-Modus läuft und diese App einschließt. Ohne Orbot ist eine .onion-Adresse nicht erreichbar. Tor ist langsamer — die Daten brauchen etwas länger.';

  @override
  String get mempoolCustomTitle => 'Eigene Instanz';

  @override
  String get mempoolCustomSub => 'Eigener Node (Umbrel, Start9, RaspiBlitz …)';

  @override
  String get mempoolSave => 'Speichern';

  @override
  String get mempoolSaved => 'Gespeichert';

  @override
  String get mempoolInvalidUrl =>
      'Das sieht nicht nach einer gültigen Adresse aus.';

  @override
  String get mempoolTest => 'Verbindung testen';

  @override
  String get mempoolTesting => 'Teste …';

  @override
  String get mempoolTestOk => 'Verbindung steht';

  @override
  String get mempoolTestFail => 'Keine Verbindung';

  @override
  String get mempoolTestBlocked =>
      'Der Server weist die Anfrage ab. Bei Tor: Onion-Adresse wählen.';

  @override
  String get mempoolTestOnionFail =>
      'Onion nicht erreichbar. Läuft Orbot im VPN-Modus und ist diese App eingeschlossen?';

  @override
  String get mempoolActive => 'Aktive Quelle';

  @override
  String get dashSource => 'Daten';

  @override
  String get dashPartial => 'Nur teilweise geladen';

  @override
  String get dashOfflineTitle => 'Keine Verbindung';

  @override
  String get dashOfflineBody =>
      'Es konnten keine Daten geladen werden. Prüfe deine Internetverbindung — oder wähle eine andere Datenquelle.';

  @override
  String get dashBlockedTitle => 'Server weist Anfragen ab';

  @override
  String get dashBlockedBody =>
      'mempool.space blockt diese IP-Adresse. Das passiert typischerweise über Tor, weil sich viele Nutzer einen Exit-Knoten teilen. Abhilfe: Onion-Adresse oder eigene Instanz verwenden.';

  @override
  String get dashChangeServer => 'Datenquelle ändern';

  @override
  String get chDuellSub => 'Quiz-Duelle um Sats — spiele gegen die Community';

  @override
  String get sdMyTurn => 'Du bist dran!';

  @override
  String get sdWaiting => 'Warten auf Gegner';

  @override
  String get sdLobby => 'offene Spiele in der Lobby';

  @override
  String get sdShortTurn => 'dran';

  @override
  String get sdShortLobby => 'in der Lobby';

  @override
  String get sdShortWait => 'warten auf Gegner';

  @override
  String get chPlebrapSub => 'Bitcoin-Rap — Plebs together strong';

  @override
  String get prV4V => 'Sats an die Künstler';

  @override
  String get prPickSong => 'Song auswählen';

  @override
  String get prLoadError => 'Song konnte nicht geladen werden';

  @override
  String get msFavoritesHint =>
      'Wähle deine Meetups — du kannst mehrere auswählen.';

  @override
  String get msSaveNone => 'Ohne Favorit speichern';

  @override
  String msSaveFavorites(int count) {
    return '$count Favoriten speichern';
  }

  @override
  String calFavAdded(String city) {
    return '$city zu Favoriten hinzugefügt ★';
  }

  @override
  String calFavRemoved(String city) {
    return '$city aus Favoriten entfernt';
  }

  @override
  String get verifyBadgeDuplicate =>
      'Dieses Badge ist bereits in deiner Wallet.';

  @override
  String get gpsOpenLocationSettings => 'Standort-Einstellungen öffnen';

  @override
  String get gpsOpenAppSettings => 'App-Einstellungen öffnen';

  @override
  String get walletSearchHint => 'Meetup suchen…';

  @override
  String get walletGroupMeetup => 'Nach Meetup';

  @override
  String get walletGroupYear => 'Nach Jahr';

  @override
  String get walletNoResults => 'Keine Badges gefunden.';

  @override
  String get walletCleanupTitle => 'Duplikate bereinigen';

  @override
  String get walletCleanupConfirm => 'Entfernen';

  @override
  String get walletCleanupNone => 'Keine Duplikate gefunden.';

  @override
  String get walletCleanupHint =>
      'Von jedem Meetup bleibt das ursprüngliche Badge erhalten. Bereits veröffentlichte Teilnahme-Nachweise im Netzwerk bleiben unverändert.';

  @override
  String walletCleanupBody(int count) {
    return '$count doppelte Badge(s) gefunden:';
  }

  @override
  String walletCleanupDone(int count) {
    return '$count Duplikate entfernt.';
  }

  @override
  String get orgGpsSoftTitle => 'Ohne Standort fortfahren?';

  @override
  String get orgGpsSoftBody =>
      'Du kannst das Meetup trotzdem erstellen und den Namen selbst eintragen. Ohne Standort können Teilnehmer allerdings nicht per Umkreis bestätigt werden — ihre Badges gelten dann als ungeprüfte Präsenz.';

  @override
  String get orgGpsSoftContinue => 'Ohne Standort';

  @override
  String get badgeUnverified => 'Präsenz ungeprüft';

  @override
  String get badgeUnverifiedInfo =>
      'Beim Sammeln war kein Standort verfügbar. Der Badge ist gültig, sein Präsenz-Nachweis aber nicht zusätzlich bestätigt.';

  @override
  String get verifyClose => 'SCHLIESSEN';

  @override
  String get verifyOpenWallet => 'ZUR WALLET';

  @override
  String get writerValidity => 'Gültig für 4 Stunden';

  @override
  String get apPickPortalTitle => 'Meetup auswählen';

  @override
  String get apPickPortalHint =>
      'Wähle das Meetup, an dem du gerade bist. Der hinterlegte Ort dient den Teilnehmern als Anhaltspunkt — ein falscher Eintrag verfälscht ihre Bestätigung.';

  @override
  String get apEnterManually => 'Name selbst eingeben';

  @override
  String get apCustomNeedsGpsTitle => 'Standort nötig';

  @override
  String get apCustomNeedsGpsBody =>
      'Ein Meetup mit eigenem Namen lässt sich nur erstellen, wenn dein Standort ermittelbar ist — er ist der einzige Bezugspunkt, an dem die Anwesenheit der Teilnehmer geprüft werden kann.\n\nDrei Wege: Geh kurz vor die Tür und versuche es erneut, wähle stattdessen ein Meetup aus dem Portal, oder lass jemand anderen vor Ort mit funktionierender Ortung das Badge erstellen.';

  @override
  String get apNoRefTitle => 'Kein Bezugspunkt';

  @override
  String get apNoRefContinue => 'Trotzdem erstellen';

  @override
  String apNoRefBody(String city) {
    return 'Für „$city“ ist im Portal kein Ort hinterlegt, und dein Standort ist nicht ermittelbar. Die Anwesenheit der Teilnehmer kann deshalb nicht bestätigt werden — ihre Badges zählen weniger.\n\nBesser: Ortung ermöglichen oder jemand anderen vor Ort das Badge erstellen lassen.';
  }

  @override
  String get apConfirmPickTitle => 'Bist du hier?';

  @override
  String get apConfirmPickBody =>
      'Dieser Name steht dauerhaft im Badge jedes Teilnehmers und lässt sich nachträglich nicht ändern. Passt der Ort nicht zu den Anwesenden, bekommen sie die Meldung „zu weit entfernt“ und kein Badge.';

  @override
  String get apConfirmPickYes => 'Ja, hier bin ich';

  @override
  String get badgeOrganizerTitle => 'ORGANISATOR-NACHWEIS';

  @override
  String get badgeOrganizerDesc =>
      'Du hast dieses Meetup selbst erstellt. Das Badge dokumentiert es, ist aber nicht signiert und zählt nicht zur Reputation — niemand kann sich selbst bestätigen. Ein zählendes Badge bekommst du, wenn ein anderer Organisator vor Ort eine eigene Session startet und du dessen Code scannst.';

  @override
  String get walletOrganizerSection => 'Von dir erstellt';

  @override
  String reputationOrganizerNote(int count) {
    return '$count Meetup(s) von dir organisiert — zählt nicht zum Score, da man sich nicht selbst bestätigen kann.';
  }

  @override
  String get apCrossConfirmTitle => 'Zweiter Organisator dabei?';

  @override
  String get apCrossConfirmBody =>
      'Für dein eigenes Meetup bekommst du kein zählendes Badge — niemand kann sich selbst bestätigen. Startet ihr beide eine Session und scannt euch gegenseitig, habt ihr beide einen echten Nachweis für diesen Abend.';

  @override
  String get tileEventsToday => 'heute im Veranstaltungskalender';

  @override
  String tileNewsUnread(int count) {
    return '$count neu seit deinem Besuch';
  }

  @override
  String get tilesAvailable => 'Verfügbar';

  @override
  String get tilesEditHint =>
      'Auf eine andere Kachel ziehen zum Verschieben · Nadel zum An- und Abheften';

  @override
  String get tilesEditDone => 'Fertig';

  @override
  String tileReputationBadges(int count) {
    return '$count gezählte Badges';
  }

  @override
  String get tileActListen => 'Zum Hören';

  @override
  String get tileActConvert => 'Umrechnen';

  @override
  String get tileActExchange => 'Austausch';

  @override
  String get tileActSend => 'Senden';

  @override
  String get tileActExplore => 'Entdecken';

  @override
  String get tileActLookup => 'Nachschlagen';

  @override
  String get tileActNetwork => 'Netzwerk';

  @override
  String get tileActEncounters => 'Begegnungen';

  @override
  String get tileActManage => 'Verwalten';

  @override
  String get emptyFindMeetup => 'Meetup finden';

  @override
  String get reputationScoreLabel => 'Vertrauenswert';

  @override
  String get reputationUnsigned => 'Nicht signiert';

  @override
  String get portalConnectForOrganizer =>
      'Nicht mit dem Portal verbunden — dein Organisator-Status kann dadurch nicht erkannt werden.';

  @override
  String get npubCopied => 'npub kopiert';

  @override
  String get idSetupTitle => 'Identität';

  @override
  String get idSetupSubtitle => 'Wie möchtest du starten?';

  @override
  String get idSetupNewCard => 'Neu hier';

  @override
  String get idSetupNewCardSub => 'Identität in der App anlegen';

  @override
  String get idSetupExistingCard => 'Schon Nostr';

  @override
  String get idSetupExistingCardSub => 'Bestehende Identität verbinden';

  @override
  String get idSetupResumeCard => 'Schon auf diesem Gerät';

  @override
  String get idSetupResumeCardSub => 'Vorhandene Identität weiter nutzen';

  @override
  String get idSetupResumeTitle => 'Weitermachen';

  @override
  String get idSetupResumeContinue => 'Weitermachen';

  @override
  String get idSetupResumeHasKey =>
      'Auf diesem Gerät liegt noch dein Schlüssel. Damit machst du weiter — nichts wird neu angelegt.';

  @override
  String get idSetupResumePasskey => 'Mit Passkey entsperren';

  @override
  String get idSetupResumePasskeyHint =>
      'Dein Schlüssel liegt verschlüsselt auf diesem Gerät. Entsperre ihn mit deinem Passkey.';

  @override
  String get idSetupResumePassword => 'Stattdessen Passwort benutzen';

  @override
  String get idSetupResumePasswordHint =>
      'Dein Schlüssel liegt verschlüsselt auf diesem Gerät. Gib das Passwort ein, mit dem du ihn angelegt hast.';

  @override
  String get idSetupResumeNeedPassword => 'Bitte das Passwort eingeben.';

  @override
  String get idSetupResumeWrongPassword =>
      'Das Passwort passt nicht zu diesem Schlüssel.';

  @override
  String get idSetupNewTitle => 'Neu anlegen';

  @override
  String get idSetupNewHint =>
      'Name und Passwort reichen. Dein Schlüssel bleibt auf dem Gerät.';

  @override
  String get idSetupNameLabel => 'Name';

  @override
  String get idSetupNameRequired => 'Bitte einen Namen wählen.';

  @override
  String get idSetupPasswordLabel => 'Passwort für deinen Schlüssel';

  @override
  String get idSetupPasswordConfirmLabel => 'Passwort bestätigen';

  @override
  String get idSetupPasswordShort =>
      'Passwort muss mindestens 8 Zeichen haben.';

  @override
  String get idSetupPasswordWarn =>
      'Dieses Passwort verschlüsselt deinen Schlüssel — nur damit lässt sich deine Sicherung wieder öffnen. Es gibt kein Zurücksetzen: ohne das Passwort ist die Sicherung wertlos.';

  @override
  String get idSetupCreate => 'Loslegen';

  @override
  String get idSetupPasskeyTitle => 'Passkey';

  @override
  String get idSetupPasskeyBody =>
      'Optional: mit Passkey (Face ID / Fingerabdruck) zusätzlich sichern.';

  @override
  String get idSetupPasskeyAction => 'Mit Passkey sichern';

  @override
  String get idSetupPasskeyLater => 'Später';

  @override
  String get idSetupPasskeyUnavailable =>
      'Passkey ist auf diesem Gerät nicht verfügbar. Du kannst mit dem Passwort weitermachen.';

  @override
  String get idSetupExistingTitle => 'Verbinden';

  @override
  String get idSetupPrimaryNip07 => 'Browsererweiterung';

  @override
  String get idSetupPrimaryNip07Sub => 'In der Erweiterung bestätigen';

  @override
  String get idSetupPrimaryAmber => 'Amber';

  @override
  String get idSetupPrimaryAmberSub => 'In Amber bestätigen';

  @override
  String get idSetupPrimaryBunker => 'Signer verbinden';

  @override
  String get idSetupPrimaryBunkerSub => 'Bunker / Clave / Amber';

  @override
  String get idSetupOtherWay => 'Anderer Weg';

  @override
  String get idSetupImportHint =>
      'nsec oder verschlüsselten Schlüssel (ncryptsec) einfügen.';

  @override
  String get idSetupImportLabel => 'Schlüssel';

  @override
  String get idSetupImportPasswordLabel => 'Passwort (nur bei ncryptsec)';

  @override
  String get idSetupImportAction => 'Importieren';

  @override
  String get idSetupImportEmpty => 'Bitte einen Schlüssel einfügen.';

  @override
  String get idSetupImportNeedPassword =>
      'Für ncryptsec brauchst du das Passwort.';

  @override
  String get idSetupNameTitle => 'Name wählen';

  @override
  String get idSetupNameOnlyHint => 'Unter welchem Namen erscheinst du?';

  @override
  String get idSetupContinue => 'Weiter';

  @override
  String get idSetupConnectFailed => 'Verbindung fehlgeschlagen.';

  @override
  String get idSetupBackupTitle => 'Schlüssel sichern?';

  @override
  String get idSetupBackupBody =>
      'Kopiere den verschlüsselten Schlüssel in deinen Passwortmanager. Ohne Passwort ist er wertlos.';

  @override
  String get idSetupBackupCopy => 'Kopieren';

  @override
  String get idSetupBackupLater => 'Später';

  @override
  String get idSetupMeetupTitle => 'Dein Meetup';

  @override
  String get idSetupMeetupHint =>
      'Welches Meetup ist deins? Du kannst später weitere hinzufügen.';

  @override
  String get idSetupMeetupPick => 'Meetup wählen';

  @override
  String get idSetupMeetupContinue => 'Weiter';

  @override
  String get idSetupMeetupLater => 'Später';

  @override
  String get idSetupMeetupLoading => 'Meetups werden geladen…';

  @override
  String get idSetupMeetupLoadError =>
      'Meetups konnten nicht geladen werden. Später im Profil nachholen.';

  @override
  String get rsInvalidUrl =>
      'Ungültige Adresse. Erwartet wird wss://host.tld ohne Pfad.';

  @override
  String get rsRelayUnreachable =>
      'Relay nicht erreichbar. Adresse prüfen oder Internetverbindung kontrollieren.';

  @override
  String get rsRelayAlreadyAdded => 'Dieses Relay ist bereits eingetragen.';

  @override
  String get rsTesting => 'Verbindung wird geprüft …';

  @override
  String get rsRelayAdded => 'Relay hinzugefügt und erreichbar.';

  @override
  String get rsEnabledHint =>
      'Eingeschaltet — bedeutet nicht, dass das Relay gerade erreichbar ist.';

  @override
  String get newsWriteArticle => 'Artikel schreiben';

  @override
  String get newsLike => 'Gefällt mir';

  @override
  String get newsShare => 'Teilen';

  @override
  String get newsLikeFailed =>
      'Reaktion konnte nicht gesendet werden. Kein Relay hat sie angenommen.';

  @override
  String get newsZap => 'Zap';

  @override
  String get newsZapTitle => 'Sats an den Autor';

  @override
  String get newsZapBody =>
      'Wähle einen Betrag. Die Rechnung wird anschließend an deine Lightning-Wallet übergeben.';

  @override
  String get newsZapNoAddress =>
      'Der Autor hat keine Lightning-Adresse im Profil hinterlegt.';

  @override
  String get newsZapUnsupportedAddress =>
      'Die Lightning-Adresse des Autors wird nicht unterstützt (nur Adressen der Form name@domain).';

  @override
  String get newsZapAmountRange =>
      'Der Betrag liegt außerhalb dessen, was der Autor annimmt.';

  @override
  String get newsZapFailed =>
      'Zap fehlgeschlagen. Einzelheiten stehen im Diagnose-Log.';

  @override
  String get newsZapNoWallet => 'Keine Lightning-Wallet gefunden';

  @override
  String get newsZapCopyInvoice => 'Rechnung kopieren';

  @override
  String get evBadgeCreate => 'Event-Badge erstellen';

  @override
  String get evBadgeCreateSub =>
      'Teilnehmer können sich vor Ort ein Badge abholen.';

  @override
  String get evBadgeNotAllowed =>
      'Nur Meetup-Organisatoren und Leader können Badges vergeben. Das Event kannst du trotzdem eintragen.';

  @override
  String get evBadgeChecking => 'Berechtigung wird geprüft …';

  @override
  String get evBadgeImage => 'Bild fürs Badge';

  @override
  String get evBadgeImageHint => 'https://…/bild.png';

  @override
  String get evBadgeLocation => 'Ort des Events';

  @override
  String get evBadgeLocationHint => 'Aktuellen Standort übernehmen';

  @override
  String get evBadgeLocationInfo =>
      'Badges lassen sich nur in der Nähe dieser Koordinaten und nur am Tag des Events ausgeben.';

  @override
  String get evBadgeNoLocation =>
      'Standort nicht ermittelbar. Ortungsdienst und Berechtigung prüfen.';

  @override
  String get evBadgeIssuers => 'Wer darf Badges ausgeben?';

  @override
  String get evBadgeIssuerHint => 'npub1… einfügen';

  @override
  String get evBadgeIssuerInfo =>
      'Du selbst darfst immer. Trage weitere Helfer ein, die vor Ort Badges verteilen sollen — sie brauchen keine eigene Organisatoren-Rolle.';

  @override
  String get evBadgeIssuerInvalid =>
      'Das ist kein gültiger npub. Erwartet wird npub1… oder ein 64-stelliger Hex-Schlüssel.';

  @override
  String get evBadgeIssuerDuplicate =>
      'Dieser Schlüssel steht bereits in der Liste.';

  @override
  String get evBadgeImageInfo =>
      'Bild aus der Galerie wählen — es wird hochgeladen, damit alle es sehen können. Eine fertige URL geht auch.';

  @override
  String get evBadgeUploading => 'Bild wird hochgeladen …';

  @override
  String evBadgeUploadFailed(String msg) {
    return 'Upload fehlgeschlagen: $msg';
  }

  @override
  String get evBadgeLocationPick => 'Auf der Karte wählen';

  @override
  String get locPickTitle => 'Ort des Events';

  @override
  String get locPickHint =>
      'Tippe auf die Karte, um den Veranstaltungsort zu setzen.';

  @override
  String get locPickHintDone => 'Tippe erneut, um den Punkt zu verschieben.';

  @override
  String get locPickJumpToMe => 'Zu meinem Standort';

  @override
  String get locPickConfirm => 'Ort übernehmen';

  @override
  String get evBadgeAvailable => 'Hier gibt es ein Badge';

  @override
  String get evBadgeAvailableSub =>
      'Vor Ort kannst du dir ein Badge abholen — am Tag des Events, in der Nähe des Veranstaltungsorts.';

  @override
  String get evBadgeYouIssue => 'Du darfst hier Badges ausgeben';

  @override
  String get evBadgeYouIssueSub =>
      'Am Tag des Events kannst du vor Ort eine Session starten und Badges verteilen.';

  @override
  String get evBadgeStartSession => 'Badge-Session starten';

  @override
  String get evSessionNoIdentity =>
      'Kein Nostr-Schlüssel vorhanden. Lege zuerst einen an.';

  @override
  String get evSessionNotIssuer =>
      'Du bist bei diesem Event nicht als Aussteller eingetragen.';

  @override
  String get evSessionOutsideWindow => 'Badges gibt es nur am Tag des Events.';

  @override
  String get evSessionNoEventLocation =>
      'Für dieses Event ist kein Ort hinterlegt. Ohne Koordinaten lässt sich nicht prüfen, ob du vor Ort bist.';

  @override
  String get evSessionNoLocation =>
      'Standort nicht ermittelbar. Ortungsdienst und Berechtigung prüfen.';

  @override
  String evSessionTooFar(String km) {
    return 'Du bist $km km vom Veranstaltungsort entfernt. Badges lassen sich nur vor Ort ausgeben.';
  }

  @override
  String get evSessionFailed =>
      'Session konnte nicht gestartet werden. Einzelheiten stehen im Diagnose-Log.';

  @override
  String mvEventIssuerOk(String event, String creator) {
    return 'Event-Badge von „$event“ — ausgegeben mit Erlaubnis von $creator.';
  }

  @override
  String mvEventSignerNotListed(String event) {
    return 'Achtung: Der Aussteller ist bei „$event“ nicht als Helfer eingetragen.';
  }

  @override
  String mvEventCreatorNotAuthorized(String event) {
    return 'Achtung: Wer „$event“ angelegt hat, ist kein eingetragener Organisator.';
  }

  @override
  String mvEventHasNoBadge(String event) {
    return 'Achtung: Für „$event“ ist gar kein Badge vorgesehen.';
  }

  @override
  String get mvEventNotFound =>
      'Das zugehörige Event ist nicht auffindbar. Ohne Netz lässt sich die Berechtigung nicht prüfen.';

  @override
  String get evBadgeShowSession => 'QR anzeigen';

  @override
  String get badgeShareTagline =>
      'Vor Ort dabei gewesen — bestätigt über Nostr.';

  @override
  String get shareCardCollectedBy => 'Gesammelt von';

  @override
  String get shareCardBlock => 'Block';

  @override
  String get shareCardScanned => 'Gescannt';

  @override
  String get shareCardChecksum => 'Prüfsumme';

  @override
  String get shareCardPromo =>
      'Einundzwanzig-Meetup besucht? Sammle dein Badge — kryptographisch belegt, dass du vor Ort warst.';

  @override
  String get backupPwShow => 'Passwort anzeigen';

  @override
  String get backupPwHide => 'Passwort verbergen';

  @override
  String backupPwRuleLength(int min) {
    return 'Mindestens $min Zeichen — eine lange Passphrase ist besser als ein kurzes, kompliziertes Passwort.';
  }

  @override
  String get backupPwRuleMatch => 'Beide Eingaben stimmen überein';

  @override
  String get idSetupOtherWaySub => 'nsec, ncryptsec, Bunker oder Backup';

  @override
  String get guideWelcomeTitle => 'Willkommen!';

  @override
  String get guideWelcomeBody =>
      'Möchtest du eine kurze Tour durch die App? Wir zeigen dir die wichtigsten Funktionen.';

  @override
  String get guideStart => 'Tour starten';

  @override
  String get guideNoThanks => 'Nein, danke';

  @override
  String get guideSkip => 'ÜBERSPRINGEN';

  @override
  String get guideFinishTour => 'Tour beenden';

  @override
  String get guideBack => 'Zurück';

  @override
  String get guideOnboardWelcomeTitle => 'Lass uns dein Profil einrichten';

  @override
  String get guideOnboardWelcomeBody =>
      'Wir führen dich Schritt für Schritt durch die Einrichtung. Es dauert nur eine Minute.';

  @override
  String get guideOnboardNicknameTitle => 'Wähle einen Nickname';

  @override
  String get guideOnboardNicknameBody =>
      'So werden dich andere Community-Mitglieder sehen. Wähle etwas Einprägsames!';

  @override
  String get guideOnboardMeetupTitle => 'Wähle dein Home-Meetup';

  @override
  String get guideOnboardMeetupBody =>
      'Dein Home-Meetup bestimmt, welche Badges du sammeln kannst und welche Events du zuerst siehst.';

  @override
  String get guideOnboardNostrTitle => 'Dein Nostr-Schlüssel';

  @override
  String get guideOnboardNostrBody =>
      'Dieser kryptografische Schlüssel signiert deine Badges und verifiziert deine Reputation. Er wird nur auf deinem Gerät gespeichert.';

  @override
  String get guideOnboardSaveTitle => 'Profil speichern';

  @override
  String get guideOnboardSaveBody =>
      'Tippe hier, wenn du fertig bist. Du kannst diese Einstellungen später jederzeit ändern.';

  @override
  String get guideHomeMeetupTitle => 'Dein Home Meetup';

  @override
  String get guideHomeMeetupBody =>
      'Deine Favoriten-Meetups und das nächste anstehende Event – direkt auf einen Blick.';

  @override
  String get guideHomeTrustScoreTitle => 'Dein Trust Score';

  @override
  String get guideHomeTrustScoreBody =>
      'Hier siehst du deinen aktuellen Stand. Tippe darauf für die Aufschlüsselung nach Vielfalt, Aktivität & Qualität.';

  @override
  String get guideHomeReputationTitle => 'Reputation';

  @override
  String get guideHomeReputationBody =>
      'Prüfe deine Reputation oder verifiziere den Trust Score einer anderen Person.';

  @override
  String get guideHomeWotTitle => 'Vertrauensnetzwerk';

  @override
  String get guideHomeWotBody =>
      'Sieh, wie du mit anderen im Web of Trust verbunden bist.';

  @override
  String get guideHomeCommunityTitle => 'Community Portal';

  @override
  String get guideHomeCommunityBody =>
      'Zugriff auf Podcast, Shoutouts, Merch und mehr.';

  @override
  String get guideHomeUmrechnerTitle => 'Umrechner';

  @override
  String get guideHomeUmrechnerBody =>
      'Schnell zwischen EUR und Sats umrechnen.';

  @override
  String get guideHomeBitcoinTitle => 'Bitcoin Kurs';

  @override
  String get guideHomeBitcoinBody =>
      'Aktueller Preis, Netzwerk-Stats und Blockhöhe.';

  @override
  String get guideHomeBadgeWalletTitle => 'Badge Wallet';

  @override
  String get guideHomeBadgeWalletBody =>
      'Alle gesammelten Badges – kryptographisch signiert und nur auf deinem Gerät gespeichert.';

  @override
  String get guideHomeScanTitle => 'Badge einfordern';

  @override
  String get guideHomeScanBody =>
      'Tippe hier, um beim Meetup den QR-Code des Organisators zu scannen oder dein Gerät per NFC anzuhalten.';

  @override
  String get guideHomeSettingsTitle => 'Einstellungen';

  @override
  String get guideHomeSettingsBody =>
      'Konfiguriere Backup, Sprache, Relays und mehr. Vergiss nicht, ein Backup zu erstellen!';

  @override
  String get guideSettingsBackupTitle => 'Erstelle ein Backup!';

  @override
  String get guideSettingsBackupBody =>
      'WICHTIG: Erstelle ein Backup, um deinen Account zu schützen. Ohne Backup sind deine Badges und dein Profil verloren, wenn du dein Gerät verlierst.';

  @override
  String get guideSettingsLanguageTitle => 'Sprache';

  @override
  String get guideSettingsLanguageBody =>
      'Wechsle zwischen Deutsch, Englisch und Spanisch.';

  @override
  String get guideSettingsRelaysTitle => 'Nostr Relays';

  @override
  String get guideSettingsRelaysBody =>
      'Konfiguriere, mit welchen Nostr-Relays sich deine App verbindet.';

  @override
  String get guideSettingsHapticTitle => 'Haptisches Feedback';

  @override
  String get guideSettingsHapticBody =>
      'Aktiviere oder deaktiviere Vibrationsfeedback.';

  @override
  String get guideSettingsResetTitle => 'App zurücksetzen';

  @override
  String get guideSettingsResetBody =>
      'Dies löscht dein Profil und alle Badges. Stelle sicher, dass du zuerst ein Backup hast!';

  @override
  String get guideEventsSearchTitle => 'Events suchen';

  @override
  String get guideEventsSearchBody =>
      'Suche nach Meetups nach Stadt oder Stichwort.';

  @override
  String get guideEventsCalendarTitle => 'Kalender';

  @override
  String get guideEventsCalendarBody =>
      'Durchsuche alle kommenden Meetup-Events.';

  @override
  String get guideEventsCardTitle => 'Event Details';

  @override
  String get guideEventsCardBody =>
      'Tippe auf ein Event, um Details, Ort und Links zu sehen.';

  @override
  String get guideEventsCreateTitle => 'Event erstellen';

  @override
  String get guideEventsCreateBody =>
      'Als Organisator kannst du hier neue Meetup-Events erstellen.';

  @override
  String get guidePortalShoutoutTitle => 'Shoutout senden';

  @override
  String get guidePortalShoutoutBody =>
      'Sende einen öffentlichen Shoutout an die Community.';

  @override
  String get guidePortalPodcastTitle => 'Podcast';

  @override
  String get guidePortalPodcastBody =>
      'Höre den Einundzwanzig Podcast direkt in der App.';

  @override
  String get guidePortalSoundboardTitle => 'Soundboard';

  @override
  String get guidePortalSoundboardBody =>
      'Spiele Clips und Sounds aus dem Podcast ab.';

  @override
  String get guidePortalMerchTitle => 'Shop';

  @override
  String get guidePortalMerchBody => 'Durchsuche Merch und Bitcoin-Produkte.';

  @override
  String get guidePortalMembershipTitle => 'Mitglied werden';

  @override
  String get guidePortalMembershipBody =>
      'Unterstütze den Verein, indem du Mitglied wirst.';

  @override
  String get guidePortalMapTitle => 'Meetup Karte';

  @override
  String get guidePortalMapBody =>
      'Finde Meetups in deiner Nähe auf der Karte.';

  @override
  String get guideWalletBadgesTitle => 'Deine Badges';

  @override
  String get guideWalletBadgesBody =>
      'Alle gesammelten Badges – kryptographisch signiert und nur auf deinem Gerät gespeichert.';

  @override
  String get guideWalletShareQrTitle => 'QR-Code teilen';

  @override
  String get guideWalletShareQrBody =>
      'Zeige deinen Reputations-QR-Code zum Scannen vor Ort.';

  @override
  String get guideWalletExportTitle => 'Als JSON exportieren';

  @override
  String get guideWalletExportBody =>
      'Signierter Export mit Schnorr-Beweis zur Verifizierung.';

  @override
  String get guideWalletShareTextTitle => 'Als Text teilen';

  @override
  String get guideWalletShareTextBody =>
      'Teile deine Reputation als lesbaren Text.';

  @override
  String get guideReputationScoreTitle => 'Dein Score';

  @override
  String get guideReputationScoreBody =>
      'Dein Trust Score wird aus Badges, Vielfalt und Aktivität berechnet.';

  @override
  String get guideReputationLevelTitle => 'Dein Level';

  @override
  String get guideReputationLevelBody =>
      'Von NEU bis VETERAN – dein Level wächst mit deiner Teilnahme.';

  @override
  String get guideReputationStatsTitle => 'Statistiken';

  @override
  String get guideReputationStatsBody =>
      'Badges, Meetups, Signer und gebundene Beweise auf einen Blick.';

  @override
  String get guideReputationShareTitle => 'Reputation teilen';

  @override
  String get guideReputationShareBody =>
      'Teile deine verifizierte Reputation per QR-Code oder Text.';

  @override
  String get guideReputationUpdateTitle => 'Auf Relays aktualisieren';

  @override
  String get guideReputationUpdateBody =>
      'Veröffentliche deine neueste Reputation im Nostr-Netzwerk.';

  @override
  String guideStepOf(int current, int total) {
    return 'Schritt $current von $total';
  }

  @override
  String get guideStepDone => 'Erledigt';

  @override
  String get guideHintNickname => 'Tippe ins Feld und gib deinen Nickname ein.';

  @override
  String get guideHintOpenPicker =>
      'Tippe auf das Feld, um die Meetup-Auswahl zu öffnen.';

  @override
  String get guideHintSearchCity =>
      'Tippe die ersten Buchstaben deiner Stadt ein.';

  @override
  String get guideHintStarMeetup => 'Tippe auf den Stern neben deinem Meetup.';

  @override
  String get guideHintConfirmSelection =>
      'Bestätige deine Auswahl mit dem Knopf unten.';

  @override
  String get guideHintNostrKey =>
      'Erstelle einen neuen Schlüssel oder importiere einen bestehenden.';

  @override
  String get guideHintSave => 'Tippe auf PROFIL SPEICHERN.';

  @override
  String get guideOnboardMeetupSearchTitle => 'Stadt suchen';

  @override
  String get guideOnboardMeetupSearchBody =>
      'Tippe den Namen deiner Stadt ein — die Liste filtert sich sofort.';

  @override
  String get guideOnboardMeetupPickTitle => 'Meetup markieren';

  @override
  String get guideOnboardMeetupPickBody =>
      'Setze den Stern bei deinem Meetup. Du kannst mehrere Favoriten wählen; der erste wird dein Home-Meetup.';

  @override
  String get guideOnboardMeetupConfirmTitle => 'Auswahl bestätigen';

  @override
  String get guideOnboardMeetupConfirmBody =>
      'Der Knopf zeigt, wie viele Favoriten du gewählt hast. Tippe darauf, um zurück zum Profil zu kommen.';

  @override
  String get guideOnboardPlatformsTitle => 'Plattformen verknüpfen';

  @override
  String get guideOnboardPlatformsBody =>
      'Hier verbindest du Konten wie Telegram, X oder Kleinanzeigen mit deiner Nostr-Identität. Jede bestätigte Plattform zahlt auf deinen Trust Score ein und zeigt anderen, dass hinter dem Profil ein gewachsener Mensch steckt.';

  @override
  String get guideHintPlatforms =>
      'Freiwillig — du kannst das jederzeit im Profil nachholen.';

  @override
  String get guideOnboardHumanityTitle => 'Proof of Humanity';

  @override
  String get guideOnboardHumanityBody =>
      'Ein einmaliger Lightning-Zap belegt, dass du eine echte Wallet bedienst — der wirksamste Schutz gegen Bot-Konten im Vertrauensnetzwerk. Hast du schon gezappt, prüfst du es hier nach.';

  @override
  String get guideHintHumanity =>
      'Freiwillig — die App funktioniert auch ohne diesen Nachweis.';

  @override
  String get guideHomeEventsTitle => 'Events';

  @override
  String get guideHomeEventsBody =>
      'Diese Kachel zeigt, ob heute etwas ansteht. Sie färbt sich orange, sobald ein Termin für den Tag eingetragen ist, und führt dich in den Kalender mit allen kommenden Treffen.';

  @override
  String get guideHomeShoutoutTitle => 'Shoutout';

  @override
  String get guideHomeShoutoutBody =>
      'Schick eine Nachricht an die Community — sie landet auf der Shoutout-Seite von Einundzwanzig. Die Kachel öffnet die Seite im Browser.';

  @override
  String get guideHomePodcastTitle => 'Podcast';

  @override
  String get guideHomePodcastBody =>
      'Der Einundzwanzig-Podcast, direkt aus der App heraus. Die Kachel öffnet die Folgenübersicht im Browser.';

  @override
  String get guideHomePortalConnectTitle => 'Portal-Verbindung';

  @override
  String get guideHomePortalConnectBody =>
      'Grün heißt verbunden, rot heißt getrennt. Mit der Verbindung zum Einundzwanzig-Portal siehst du Termine und Kurse, die dort gepflegt werden. Ein Tipp auf die Kachel schaltet um.';

  @override
  String get guideHomeNewsTitle => 'News';

  @override
  String get guideHomeNewsBody =>
      'Die jüngste Meldung aus der Community steht direkt auf der Kachel. Ein Tipp öffnet die vollständige Übersicht.';

  @override
  String get guideHomeMyMeetupsTitle => 'Meine Meetups';

  @override
  String get guideHomeMyMeetupsBody =>
      'Hier verwaltest du die Termine deiner Meetups im Portal — anlegen, ändern, absagen. Nur sinnvoll, wenn du selbst organisierst.';

  @override
  String get guideHomeMoreTitle => 'Und noch mehr';

  @override
  String get guideHomeMoreBody =>
      'Vier weitere Kacheln warten auf dem Dashboard: SatoshiDuell für Quizrunden um Sats, PlebRap für Musik aus der Community, der Portal-Bereich mit Meetups, Events, Kursen und Karte, sowie die Nostr-Kachel mit den neuesten Notizen aus deinem Netzwerk. Jede lässt sich in den Einstellungen aus- oder wieder einblenden.';

  @override
  String get guideHomeNearbyTitle => 'In der Nähe';

  @override
  String get guideHomeNearbyBody =>
      'Zeigt Meetups in deiner Umgebung — praktisch auf Reisen oder wenn du ein zweites Treffen in der Region suchst. Der Bildschirm legt sich über die App, ein Zurück bringt dich hierher.';

  @override
  String get guideHomeEventsTabTitle => 'Event-Bereich';

  @override
  String get guideHomeEventsTabBody =>
      'Der vierte Knopf führt in den vollständigen Kalender: alle Termine, filterbar nach Ort und Zeitraum, mit Erinnerungsfunktion.';

  @override
  String get guideHomeSettingsBackupHint =>
      'Geh gleich als Erstes ins Backup — ohne das ist dein Schlüssel bei Handyverlust weg.';

  @override
  String get guideHintBackup =>
      'Leg jetzt ein verschlüsseltes Backup an — es dauert eine Minute.';

  @override
  String get guideEvBadgeSwitchTitle => 'Badge für dein Event';

  @override
  String get guideEvBadgeSwitchBody =>
      'Leg den Schalter um, wenn Teilnehmer sich vor Ort ein Badge abholen können sollen. Ohne ihn bleibt es ein reiner Termin.';

  @override
  String get guideEvBadgeSwitchHint =>
      'Wenn du für dieses Event kein Badge brauchst, tippe einfach auf Weiter.';

  @override
  String get guideEvBadgeImageTitle => 'Das Bild';

  @override
  String get guideEvBadgeImageBody =>
      'Wähle ein Bild aus deiner Galerie — es wird hochgeladen und erscheint später auf jedem Badge dieses Events. Ohne Bild trägt die generative Grafik die Karte allein.';

  @override
  String get guideEvBadgeLocationTitle => 'Der Ort zählt';

  @override
  String get guideEvBadgeLocationBody =>
      'Setze den Punkt dort, wo das Event stattfindet — nicht dort, wo du gerade bist. Badges lassen sich nur in seiner Nähe und nur am Tag des Events ausgeben.';

  @override
  String get guideEvBadgeIssuersTitle => 'Deine Helfer';

  @override
  String get guideEvBadgeIssuersBody =>
      'Trage die npubs aller ein, die vor Ort Badges verteilen sollen. Sie brauchen keine Organisatoren-Rolle — die Erlaubnis steht im Termin und gilt nur für dieses Event. Du selbst darfst immer.';

  @override
  String get glTitle => 'Nachschlagen';

  @override
  String get glSearchHint => 'Suchen — z. B. Badge, Trust Score, Backup';

  @override
  String get glNoResults =>
      'Dazu findet sich nichts. Versuch ein anderes Wort — gesucht wird auch im Text der Einträge.';

  @override
  String get glCatStart => 'Erste Schritte';

  @override
  String get glCatBadges => 'Badges';

  @override
  String get glCatReputation => 'Reputation';

  @override
  String get glWhatIsAppTitle => 'Was diese App tut';

  @override
  String get glWhatIsAppBody =>
      'Sie belegt, dass du bei einem Bitcoin-Meetup wirklich vor Ort warst. Aus vielen solcher Belege entsteht mit der Zeit eine Reputation, die dir gehört und die niemand entziehen kann — sie liegt nicht auf einem Server von Einundzwanzig, sondern signiert im Nostr-Netzwerk.';

  @override
  String get glCollectTitle => 'Wie du ein Badge sammelst';

  @override
  String get glCollectBody =>
      'Geh zum Meetup und lass dir vom Organisator den QR-Code zeigen. Unten in der Leiste auf den runden Scan-Knopf tippen, Code erfassen — fertig. Das Badge liegt danach in deiner Badge-Wallet.';

  @override
  String get glHomeMeetupTitle => 'Dein Home-Meetup';

  @override
  String get glHomeMeetupBody =>
      'Das Meetup, zu dem du regelmäßig gehst. Es bestimmt, welche Termine du zuerst siehst und welches Wappen auf deinen Badges erscheint. Du kannst mehrere Favoriten wählen — der erste gilt als Home-Meetup. Ändern lässt sich das jederzeit im Profil.';

  @override
  String get glOfflineTitle => 'Was ohne Internet geht';

  @override
  String get glOfflineBody =>
      'Scannen und Badge erhalten funktioniert offline — die Prüfung der Signatur rechnet dein Gerät selbst. Ohne Netz fehlen nur die Dinge, die von außen kommen: Blockhöhe, Kurs, Termine und die Prüfung, ob der Organisator eingetragen ist.';

  @override
  String get glBadgeProofTitle => 'Was ein Badge beweist';

  @override
  String get glBadgeProofBody =>
      'Dass du zu einer bestimmten Zeit an einem bestimmten Ort warst — bestätigt von jemandem, der dort ebenfalls war. Die Bestätigung ist eine Schnorr-Signatur nach BIP-340. Fälschen kann sie niemand, auch die Entwickler nicht, weil dafür der private Schlüssel des Organisators nötig wäre.';

  @override
  String get glRollingQrTitle => 'Der Rolling QR';

  @override
  String get glRollingQrBody =>
      'Der Code des Organisators wechselt alle paar Sekunden. Ein Foto davon ist damit Minuten später wertlos — nur wer wirklich davorsteht, kann ihn erfassen. Genau deshalb lässt sich ein Badge nicht per Chat weiterreichen.';

  @override
  String get glOnSiteTitle => 'Warum nur vor Ort';

  @override
  String get glOnSiteBody =>
      'Neben dem wechselnden Code prüft die App auch die Entfernung: Wer zu weit vom Meetup entfernt ist, bekommt kein Badge. Bei Meetups sind die Grenzen weit gefasst, weil manche Gruppen ganze Regionen abdecken; bei Sondereevents ist der Ort genau gesetzt und die Grenze eng.';

  @override
  String get glBadgeShareTitle => 'Badge teilen';

  @override
  String get glBadgeShareBody =>
      'Öffne ein Badge und tippe oben rechts auf Teilen. Die App erzeugt daraus ein Bild mit Ort, Datum, Blockhöhe und Prüfsumme. Wer es sieht, kann die Angaben nachvollziehen — dein privater Schlüssel steckt nicht darin.';

  @override
  String get glTrustScoreTitle => 'Der Trust Score';

  @override
  String get glTrustScoreBody =>
      'Eine Zahl, die zusammenfasst, wie belastbar deine Anwesenheitsbelege sind. Es zählt nicht nur die Menge: Verschiedene Meetups, verschiedene Organisatoren und Regelmäßigkeit über die Zeit wiegen schwerer als zwanzig Besuche am selben Ort in derselben Woche.';

  @override
  String get glLevelsTitle => 'Die Stufen';

  @override
  String get glLevelsBody =>
      'Mit steigendem Trust Score erreichst du höhere Stufen. Ab einer bestimmten Stufe kannst du selbst Sessions starten und Badges ausgeben — das ist keine Auszeichnung, sondern eine Verantwortung: Deine Signatur steht dann unter den Badges anderer Leute.';

  @override
  String get glHumanityTitle => 'Proof of Humanity';

  @override
  String get glHumanityBody =>
      'Ein einmaliger Lightning-Zap belegt, dass hinter dem Profil jemand mit einer echten Wallet steht. Das ist der wirksamste Schutz gegen automatisch angelegte Konten im Vertrauensnetzwerk. Freiwillig — die App funktioniert auch ohne.';

  @override
  String get glPlatformsTitle => 'Plattform-Nachweise';

  @override
  String get glPlatformsBody =>
      'Du kannst Konten wie Telegram oder X mit deiner Nostr-Identität verknüpfen. Jede bestätigte Plattform zahlt auf den Trust Score ein und zeigt anderen, dass hinter dem Profil eine gewachsene Person steht. Ebenfalls freiwillig.';

  @override
  String get guideHomeGlossaryTitle => 'Zum Nachschlagen';

  @override
  String get guideHomeGlossaryBody =>
      'Hier steht alles nochmal in Ruhe erklärt — nach Themen sortiert und durchsuchbar. Wenn diese Tour vorbei ist und eine Frage bleibt, findest du die Antwort hier.';

  @override
  String get glCatNetwork => 'Vertrauensnetzwerk';

  @override
  String get glCatIdentity => 'Identität & Schlüssel';

  @override
  String get glCatEvents => 'Events';

  @override
  String get glCatNostr => 'Nostr';

  @override
  String get glEncounterTitle => 'Begegnungen';

  @override
  String get glEncounterBody =>
      'Wer beim selben Organisator am selben Tag gescannt hat, gilt als einander begegnet. Daraus entsteht ein Geflecht aus Menschen, die sich tatsächlich im selben Raum aufgehalten haben — nicht aus Leuten, die einander im Netz folgen.';

  @override
  String get glDegreesTitle => 'Grade';

  @override
  String get glDegreesBody =>
      'Ersten Grades heißt: Ihr wart beim selben Organisator. Zweiten Grades: Jemand, den du getroffen hast, hat diese Person getroffen. Waren auf einem Meetup zwei Organisatoren im Einsatz, verbindet ihr gegenseitiges Scannen beide Gruppen — dann seid ihr zweiten Grades verbunden statt ersten.';

  @override
  String get glVouchTitle => 'Bürgschaften';

  @override
  String get glVouchBody =>
      'Organisatoren können füreinander bürgen. Eine Bürgschaft ist ein öffentliches, signiertes Votum — nach dem Publizieren sieht das ganze Netzwerk, für wen du stehst. Sie lässt sich jederzeit widerrufen, aber der Widerruf ist ebenso sichtbar.';

  @override
  String get glEventNetTitle => 'Netzwerk aus Events';

  @override
  String get glEventNetBody =>
      'Sondereevents werden getrennt gezählt. Auf einem Meetup mit fünfzehn Leuten trifft man jeden — auf einem Event mit fünfhundert nicht. Beides im selben Topf würde die Aussage des Netzwerks entwerten, deshalb hat es eine eigene Kategorie.';

  @override
  String get glKeysTitle => 'nsec und npub';

  @override
  String get glKeysBody =>
      'Dein npub ist deine öffentliche Adresse — die darfst und sollst du teilen. Der nsec ist der private Schlüssel und gehört niemandem sonst: Wer ihn hat, IST du. Ein Zurücksetzen gibt es nicht. Ist der nsec weg, ist die Identität samt Reputation verloren.';

  @override
  String get glPasswordTitle => 'Die beiden Passwörter';

  @override
  String get glPasswordBody =>
      'Beim Einrichten legst du ein Passwort fest, das deinen Schlüssel auf dem Gerät verpackt. Beim Backup vergibst du ein zweites, das die Sicherungsdatei verschlüsselt. Sie dürfen gleich sein, sind aber unabhängig voneinander — und für beide gibt es kein Zurücksetzen.';

  @override
  String get glSignerTitle => 'Signer-Apps';

  @override
  String get glSignerBody =>
      'Statt den Schlüssel in dieser App zu halten, kannst du ihn einer Signer-App wie Amber anvertrauen oder über einen Bunker anbinden. Diese App fragt dann bei jeder Signatur dort nach und sieht den Schlüssel selbst nie.';

  @override
  String get glBackupTitle => 'Das Backup';

  @override
  String get glBackupBody =>
      'Sichert Schlüssel, Badges und Einstellungen in eine verschlüsselte Datei. Ohne sie ist bei Geräteverlust alles weg — Handy weg heißt sonst Reputation weg. Leg sie früh an, nicht erst wenn du sie brauchst, und bewahre die Datei getrennt vom Passwort auf.';

  @override
  String get glSpecialEventTitle => 'Sondereevents';

  @override
  String get glSpecialEventBody =>
      'Neben den regelmäßigen Meetups gibt es einmalige Veranstaltungen, für die eigene Badges vergeben werden. Sie zählen als Badge und für die Vielfalt der Aussteller, aber nicht als besuchtes Meetup — drei Großevents ersetzen keine lokale Gemeinschaft.';

  @override
  String get glEventHelperTitle => 'Helfer beim Event';

  @override
  String get glEventHelperBody =>
      'Wer ein Event mit Badge anlegt, kann beliebige npubs als Aussteller eintragen. Diese Helfer brauchen keine Organisatoren-Rolle — die Erlaubnis steht im Termin und gilt nur für dieses eine Event. Jeder Helfer zeigt dabei seinen eigenen QR-Code.';

  @override
  String get glEventWindowTitle => 'Ort und Zeitfenster';

  @override
  String get glEventWindowBody =>
      'Ein Event-Badge lässt sich nur am Tag der Veranstaltung und nur in der Nähe des eingetragenen Orts ausgeben. Beides zusammen verhindert, dass jemand von zu Hause aus Badges für eine Veranstaltung verteilt, bei der er gar nicht ist.';

  @override
  String get glRelaysTitle => 'Relays';

  @override
  String get glRelaysBody =>
      'Relays sind die Server, über die Nostr-Nachrichten laufen. Die App schreibt auf mehrere gleichzeitig, damit nichts verloren geht, wenn einer ausfällt. Du kannst in den Einstellungen eigene hinzufügen — sie werden vor dem Speichern auf Erreichbarkeit geprüft.';

  @override
  String get glPublicTitle => 'Was öffentlich ist';

  @override
  String get glPublicBody =>
      'Badges, Anwesenheiten und Bürgschaften liegen offen auf den Relays — jeder kann sie lesen und nachrechnen, das ist der Sinn der Sache. Nicht öffentlich sind dein privater Schlüssel, dein Backup-Passwort und dein genauer Standort.';

  @override
  String get glZapTitle => 'Zaps';

  @override
  String get glZapBody =>
      'Ein Zap ist eine kleine Lightning-Zahlung mit einer Nostr-Quittung daran. In den News kannst du damit Autoren direkt etwas zukommen lassen; die Rechnung übergibt die App an deine Wallet. Ein einmaliger Zap dient außerdem als Proof of Humanity.';

  @override
  String get guideEvBasicsTitle => 'Titel und Ort';

  @override
  String get guideEvBasicsBody =>
      'Der Titel steht später in der Terminliste und auf dem Badge, falls du eines vergibst. Der Ort ist die Anschrift zum Vorlesen — die Koordinaten für die Badge-Ausgabe setzt du weiter unten getrennt auf der Karte.';

  @override
  String get guideEvWhenWhereTitle => 'Wann es stattfindet';

  @override
  String get guideEvWhenWhereBody =>
      'Start ist Pflicht, das Ende darfst du weglassen. Bei einem Event mit Badge zählt der Kalendertag: Badges lassen sich nur an diesem Tag ausgeben, von Mitternacht bis Mitternacht.';

  @override
  String get glCatApp => 'App & Bedienung';

  @override
  String get glTilesTitle => 'Dashboard anpassen';

  @override
  String get glTilesBody =>
      'Halte eine Kachel lange gedrückt, um sie zu verschieben oder auszublenden. Trust Score und Home-Meetup bleiben immer sichtbar, alles andere kannst du loslösen. Ausgeblendete Kacheln landen in der Verwaltung und lassen sich jederzeit zurückholen.';

  @override
  String get glLanguageTitle => 'Sprache';

  @override
  String get glLanguageBody =>
      'Die App gibt es auf Deutsch, Englisch und Spanisch. Ohne eigene Wahl folgt sie der Systemsprache. Umstellen kannst du sie in den Einstellungen; die Änderung greift sofort, ein Neustart ist nicht nötig.';

  @override
  String get glLogTitle => 'Diagnose-Log';

  @override
  String get glLogBody =>
      'Ein Protokoll dessen, was die App im Hintergrund tut — welche Relays geantwortet haben, warum ein Scan abgelehnt wurde. Wenn etwas klemmt, ist das die erste Anlaufstelle. Es bleibt auf dem Gerät und wird nirgends hochgeladen.';

  @override
  String get glResetTitle => 'App zurücksetzen';

  @override
  String get glResetBody =>
      'Löscht Profil, Schlüssel und alle Badges vom Gerät — endgültig. Ohne Backup ist deine Identität danach weg, auch wenn die Badges auf den Relays weiterleben: Ohne den passenden Schlüssel kannst du sie niemandem mehr zuordnen. Mach vorher ein Backup.';

  @override
  String get glNicknameTitle => 'Dein Anzeigename';

  @override
  String get glNicknameBody =>
      'Der Name, unter dem du im Netzwerk erscheinst. Er ist frei wählbar, muss nicht dein echter sein und lässt sich jederzeit ändern — deine Identität hängt am Schlüssel, nicht am Namen.';

  @override
  String get glFindMeetupTitle => 'Meetups finden';

  @override
  String get glFindMeetupBody =>
      'Über die Meetup-Suche kommst du an alle eingetragenen Gruppen. In der Nähe zeigt dir stattdessen, was rund um deinen aktuellen Standort liegt — nützlich auf Reisen oder wenn du eine zweite Gruppe in der Region suchst.';

  @override
  String get glBlockHeightTitle => 'Die Blockhöhe';

  @override
  String get glBlockHeightBody =>
      'Jedes Badge trägt die Nummer des Bitcoin-Blocks, der beim Scan gerade aktuell war. Sie wirkt wie ein Zeitstempel, den niemand nachträglich verschieben kann — anders als die Uhr eines Handys, die sich beliebig stellen lässt.';

  @override
  String get glChecksumTitle => 'Die Prüfsumme';

  @override
  String get glChecksumBody =>
      'Ein kurzer Fingerabdruck über den gesamten Badge-Inhalt. Zwei Menschen können ihre Badges vom selben Meetup vergleichen: Stimmen die Prüfsummen überein, haben beide dieselben Daten erhalten. Sie steht in den Badge-Details und auf dem geteilten Bild.';

  @override
  String get glWorldMapTitle => 'Die Badge-Weltkarte';

  @override
  String get glWorldMapBody =>
      'Zeigt deine gesammelten Badges dort, wo du sie bekommen hast. Aus einer Liste von Namen wird so eine Landkarte deiner Meetup-Besuche — praktisch, um zu sehen, wo noch weiße Flecken sind.';

  @override
  String get glDuplicateTitle => 'Doppelte Badges';

  @override
  String get glDuplicateBody =>
      'Pro Meetup und Tag gibt es genau ein Badge. Wer denselben Code zweimal scannt, bekommt kein zweites — das ist Absicht: Ein Badge steht für einen Besuch, nicht für einen Scan.';

  @override
  String get glVerifyPersonTitle => 'Jemanden prüfen';

  @override
  String get glVerifyPersonBody =>
      'Lass dir den Reputations-QR der anderen Person zeigen und scanne ihn. Die App rechnet nach, ob die Angaben zu den signierten Badges passen, und zeigt dir, wie ihr im Netzwerk verbunden seid. Nützlich vor einem Handel unter Fremden.';

  @override
  String get glRepCardTitle => 'Die Reputationskarte';

  @override
  String get glRepCardBody =>
      'Eine teilbare Übersicht deiner Reputation als Bild — Stufe, Anzahl der Meetups, Zeitraum. Sie enthält keinen privaten Schlüssel und lässt sich bedenkenlos posten.';

  @override
  String get glPublishTitle => 'Reputation veröffentlichen';

  @override
  String get glPublishBody =>
      'Damit andere deine Reputation prüfen können, muss sie auf den Relays liegen. Die App veröffentlicht sie signiert; ohne diesen Schritt sieht ein Gegenüber nur, was du ihm direkt zeigst.';

  @override
  String get glTrustPathTitle => 'Vertrauenspfad';

  @override
  String get glTrustPathBody =>
      'Zeigt die Kette, über die du mit einer anderen Person verbunden bist — wer wen wo getroffen hat. Aus einer abstrakten Zahl wird damit eine nachvollziehbare Aussage: nicht nur dass ihr verbunden seid, sondern worüber.';

  @override
  String get glDistrustTitle => 'Meldungen und Suspendierung';

  @override
  String get glDistrustBody =>
      'Organisatoren können Missbrauch melden. Häufen sich Meldungen gegen jemanden, wird er im Netzwerk als suspendiert markiert — seine Badges verschwinden nicht, aber sie tragen diese Warnung. Auch eine Meldung ist signiert und damit dem Melder zuzuordnen.';

  @override
  String get glOrganizerTitle => 'Organisator werden';

  @override
  String get glOrganizerBody =>
      'Ab einem bestimmten Trust Score kannst du selbst Sessions starten. Zusätzlich brauchst du in der Regel Bürgschaften bestehender Organisatoren — die Rolle wird nicht vergeben, sie wächst aus dem Netzwerk.';

  @override
  String get glNcryptsecTitle => 'ncryptsec';

  @override
  String get glNcryptsecBody =>
      'Ein nsec, der mit einem Passwort verschlüsselt ist (NIP-49). Die Zeichenfolge beginnt mit ncryptsec1 und ist ohne Passwort wertlos — sie lässt sich also gefahrloser transportieren als ein blanker nsec. Genau so liegt dein Schlüssel auch auf dem Gerät.';

  @override
  String get glPasskeyTitle => 'Passkey';

  @override
  String get glPasskeyBody =>
      'Zusätzlicher Schutz per Fingerabdruck oder Gesichtserkennung. Der Passkey ersetzt dein Passwort nicht, er legt sich davor. Freiwillig, und nur auf diesem Gerät — auf einem neuen brauchst du wieder Passwort oder Backup.';

  @override
  String get glNip05Title => 'NIP-05-Adresse';

  @override
  String get glNip05Body =>
      'Eine lesbare Adresse der Form name@domain, die auf deinen Schlüssel zeigt — wie ein Namensschild fürs Netzwerk. Sie beweist, dass jemand mit Zugriff auf diese Domain für dich bürgt, ersetzt aber keine der anderen Prüfungen.';

  @override
  String get glImportTitle => 'Schlüssel mitbringen';

  @override
  String get glImportBody =>
      'Wer schon eine Nostr-Identität hat, kann sie hier einsetzen — als nsec, als ncryptsec oder über einen Bunker. Deine bestehenden Kontakte und dein Profil bleiben dabei erhalten; die App legt nur Badges und Reputation dazu.';

  @override
  String get glRestoreTitle => 'Backup einspielen';

  @override
  String get glRestoreBody =>
      'Beim Einrichten kannst du statt eines neuen Schlüssels ein Backup laden. Du brauchst die Datei UND das Passwort, mit dem sie verschlüsselt wurde — eines allein genügt nicht. Danach ist die Identität samt Badges wieder da.';

  @override
  String get glCalendarSourcesTitle => 'Woher die Termine kommen';

  @override
  String get glCalendarSourcesBody =>
      'Der Kalender führt zwei Quellen zusammen: Termine aus dem Einundzwanzig-Portal und Veranstaltungen, die jemand über Nostr eingetragen hat. Die Farbe unterscheidet sie — Portal-Meetups orange, Nostr-Termine türkis.';

  @override
  String get glPortalTitle => 'Die Portal-Verbindung';

  @override
  String get glPortalBody =>
      'Mit deinem Nostr-Schlüssel kannst du dich am Einundzwanzig-Portal anmelden. Danach siehst du dort gepflegte Termine und Kurse und kannst als Leader eigene Termine anlegen. Ohne Verbindung funktioniert alles andere weiterhin.';

  @override
  String get glCreateEventTitle => 'Termin anlegen';

  @override
  String get glCreateEventBody =>
      'Jeder kann einen Termin eintragen — er wird signiert auf Nostr veröffentlicht und erscheint bei allen im Kalender. Ein Badge dazu vergeben dürfen allerdings nur Organisatoren und Leader.';

  @override
  String get glNostrBasicsTitle => 'Was Nostr ist';

  @override
  String get glNostrBasicsBody =>
      'Ein offenes Protokoll für Nachrichten, die ihr Absender selbst signiert. Es gibt kein Unternehmen dahinter und kein Konto, das gesperrt werden könnte — nur Schlüssel und Relays. Deine Identität aus dieser App funktioniert deshalb auch in anderen Nostr-Anwendungen.';

  @override
  String get glNewsTitle => 'Der News-Bereich';

  @override
  String get glNewsBody =>
      'Die Artikel stammen aus dem Einundzwanzig-Magazin und liegen als Nostr-Langtexte vor. Du kannst sie in der App lesen, mit einem Herz versehen, teilen und den Autoren Sats zappen — alles über dieselbe Identität.';

  @override
  String get glConverterTitle => 'Umrechner und Kurs';

  @override
  String get glConverterBody =>
      'Rechnet Euro in Sats um und zurück. Der Kurs und die Blockhöhe kommen von einer Mempool-Instanz; welche das ist, kannst du in den Einstellungen ändern — etwa auf deine eigene Node.';

  @override
  String get glCommunityTitle => 'Community-Bereich';

  @override
  String get glCommunityBody =>
      'Sammelpunkt für alles rund um Einundzwanzig, was nicht direkt mit Badges zu tun hat: Podcast, Shoutouts, PlebRap, SatoshiDuell und die Meetup-Karte. Vieles davon öffnet sich im Browser.';

  @override
  String get settingsRestartGuide => 'Tour wiederholen';

  @override
  String get settingsRestartGuideSub => 'Alle Spotlight-Touren erneut anzeigen';

  @override
  String get settingsGuideReset =>
      'Touren zurückgesetzt — sie starten beim nächsten Öffnen der Bereiche.';

  @override
  String get guideSettingsRestartTitle => 'Tour wiederholen';

  @override
  String get guideSettingsRestartBody =>
      'Setzt alle Spotlight-Touren zurück. Sie starten dann wieder, sobald du den jeweiligen Bereich das nächste Mal öffnest — nützlich, wenn du etwas noch einmal sehen willst.';

  @override
  String get guideWalletMapTitle => 'Weltkarte';

  @override
  String get guideWalletMapBody =>
      'Zeigt deine Badges dort, wo du sie eingesammelt hast. Aus einer Liste wird eine Landkarte deiner Meetup-Besuche.';

  @override
  String get guideWalletViewTitle => 'Ansicht wechseln';

  @override
  String get guideWalletViewBody =>
      'Umschalten zwischen großen Karten und einer kompakten Übersicht. Bei vielen Badges ist die kompakte Ansicht schneller zu überblicken.';

  @override
  String get guideCommunityPortalTitle => 'Das Portal';

  @override
  String get guideCommunityPortalBody =>
      'Der Zugang zu Meetups, Terminen, Kursen und der Karte auf einundzwanzig.space. Vieles davon öffnet sich im Browser.';

  @override
  String get guideCommunityNewsTitle => 'News und Nostr';

  @override
  String get guideCommunityNewsBody =>
      'Artikel aus dem Einundzwanzig-Magazin und die neuesten Notizen aus deinem Nostr-Netzwerk — beides direkt in der App lesbar.';

  @override
  String get guideCommunityFunTitle => 'Zum Mitmachen';

  @override
  String get guideCommunityFunBody =>
      'SatoshiDuell für Quizrunden um Sats und PlebRap für Musik aus der Community. Beides braucht nichts weiter als deine Identität.';

  @override
  String get guideMyMeetupsListTitle => 'Deine Meetups';

  @override
  String get guideMyMeetupsListBody =>
      'Die Meetups, für die du im Portal eingetragen bist. Tippe eines an, um seine Termine zu sehen und zu pflegen — dort legst du mit dem Knopf unten auch neue an.';

  @override
  String get guideMyMeetupsCreateTitle => 'Termin anlegen';

  @override
  String get guideMyMeetupsCreateBody =>
      'Trägt einen neuen Termin im Portal ein. Er erscheint danach im Kalender aller, die dieses Meetup als Favorit haben.';

  @override
  String get guideWotTabsTitle => 'Die drei Ansichten';

  @override
  String get guideWotTabsBody =>
      'Netzwerk zeigt, wer mit wem verbunden ist. Bürgen zeigt, für wen du stehst und wer für dich. Meldungen sammelt die Warnungen aus dem Netzwerk.';

  @override
  String get guideWotRefreshTitle => 'Neu laden';

  @override
  String get guideWotRefreshBody =>
      'Holt den aktuellen Stand von den Relays. Das Netzwerk wächst mit jedem Meetup — ohne Nachladen siehst du den Stand vom letzten Öffnen.';

  @override
  String get guideHomeCustomizeTitle => 'Dein Dashboard';

  @override
  String get guideHomeCustomizeBody =>
      'Unter dieser Überschrift liegen die Kacheln, die du gerade nicht angeheftet hast — sie sind nicht weg, nur zurückgestellt. Halte eine Kachel lange gedrückt, um sie anzuheften, zu lösen oder zu verschieben. So bekommst du oben genau das, was du wirklich benutzt.';

  @override
  String get guidePaMeetupsTitle => 'Meetups und Termine';

  @override
  String get guidePaMeetupsBody =>
      'Beide führen in den Kalender: das eine zu den Gruppen, das andere zu den nächsten Terminen. Was du dort siehst, hängt an deinen Favoriten — mit mehr Favoriten wird die Liste voller.';

  @override
  String get guidePaCoursesTitle => 'Kurse';

  @override
  String get guidePaCoursesBody =>
      'Die Bildungsangebote von Einundzwanzig samt Dozenten — vom Einsteigerabend bis zur mehrteiligen Reihe. Ein Tipp auf einen Kurs zeigt Inhalt, Termine und wer ihn hält.';

  @override
  String get guidePaMapTitle => 'Die Karte';

  @override
  String get guidePaMapBody =>
      'Zeigt Meetups in deiner Umgebung auf einer Landkarte. Praktisch auf Reisen — oder wenn du wissen willst, was es außer deinem Home-Meetup noch in der Region gibt.';

  @override
  String get guidePaMineTitle => 'Meine Meetups';

  @override
  String get guidePaMineBody =>
      'Nur für Organisatoren interessant: Hier pflegst du die Termine der Meetups, für die du im Portal eingetragen bist. Wer keines betreut, findet hier eine leere Liste.';

  @override
  String get guideSettingsProfileTitle => 'Profil und Schlüssel';

  @override
  String get guideSettingsProfileBody =>
      'Hier änderst du deinen Namen und dein Home-Meetup — und hier liegen deine Nostr-Schlüssel. Ganz unten kannst du den npub kopieren und dir den nsec anzeigen lassen. Wenn die App dir einen Schlüssel erstellt hat, ist das der Ort, an dem du ihn findest.';

  @override
  String get glFindKeysTitle => 'Wo finde ich meine Schlüssel?';

  @override
  String get glFindKeysBody =>
      'Einstellungen → Profil, ganz unten. Dort kopierst du den npub mit einem Tipp und lässt dir den nsec anzeigen — letzteres nur nach einer Warnung, denn wer den nsec sieht, hat deine Identität. Nutzt du Amber, eine Browsererweiterung oder einen Bunker, gibt es hier keinen nsec: Der liegt dann dort und nicht in dieser App.';

  @override
  String get idSetupSecureTitle => 'Identität erstellt — jetzt sichern';

  @override
  String get idSetupSecureBody =>
      'Es gibt zwei Arten zu sichern — sie können unterschiedliche Dinge. Am besten machst du beides.';

  @override
  String get idSetupSecureBackup => 'Backup erstellen';

  @override
  String get idSetupSecureCopy => 'Schlüssel in die Zwischenablage';

  @override
  String get idSetupSecureWhere =>
      'Deine Schlüssel findest du jederzeit unter Einstellungen → Profil.';

  @override
  String get idSetupSecureBackupTitle => 'Backup-Datei';

  @override
  String get idSetupSecureBackupBody =>
      'Enthält alles: Schlüssel, Badges, Reputation und Einstellungen. Damit steht deine App auf einem neuen Gerät wieder genau so da. Die Datei ist mit einem eigenen Passwort verschlüsselt.';

  @override
  String get idSetupSecureKeyTitle => 'Verschlüsselter Schlüssel';

  @override
  String get idSetupSecureKeyBody =>
      'Zum Schluss noch dein Nostr-Schlüssel allein, mit deinem Passwort verpackt (ncryptsec). Er rettet deine Identität, aber keine Badges — dafür veraltet er nie und passt in jeden Passwortmanager.';

  @override
  String get idSetupSecureRepeat =>
      'Wiederhole das Backup ab und zu unter Einstellungen → Backup. Eine Datei von heute kennt die Badges von morgen nicht — was danach dazukommt, wäre bei einem Geräteverlust weg.';

  @override
  String get idSetupSecureKeySave => 'Als Datei speichern';

  @override
  String get idSetupSecureKeySaved => 'Schlüsseldatei gespeichert.';

  @override
  String get idSetupSecureSkip => 'Überspringen';

  @override
  String get idSetupSecureFileHeader =>
      'Einundzwanzig Meetup App — verschlüsselter Nostr-Schlüssel (ncryptsec, NIP-49). Ohne das zugehörige Passwort ist diese Datei wertlos. Bewahre beides getrennt auf.';

  @override
  String get chatRelayHint => 'Gruppen-Relay von Einundzwanzig';

  @override
  String get chatEmpty =>
      'Noch keine Nachrichten. Schreib die erste — der Raum liegt offen auf dem Relay und ist auch aus anderen Nostr-Apps erreichbar.';

  @override
  String get chatPlaceholder => 'Nachricht schreiben …';

  @override
  String get chatJoin => 'Dem Raum beitreten';

  @override
  String get chatJoinHint =>
      'Mitlesen kannst du hier ohne Weiteres. Zum Mitschreiben musst du dem Raum beitreten — die Mitgliederliste führt das Relay.';

  @override
  String chatJoinFailed(String msg) {
    return 'Beitritt abgelehnt: $msg';
  }

  @override
  String chatSendFailed(String msg) {
    return 'Nachricht nicht angekommen: $msg';
  }

  @override
  String get chatSearching => 'Chatraum wird gesucht …';

  @override
  String chatNoRoom(String city) {
    return 'Für $city gibt es auf dem Gruppen-Relay noch keinen Chatraum. Einzelheiten stehen im Diagnose-Log.';
  }

  @override
  String get chatEventOpen => 'Chat zum Termin';

  @override
  String get chatEventFailed =>
      'Der Chatraum konnte nicht geöffnet werden. Einzelheiten stehen im Diagnose-Log.';

  @override
  String get btnChat => 'Chat';

  @override
  String get btnInfo => 'Info';

  @override
  String get chatEventHint => 'Beiträge zum Termin · öffentlich auf Nostr';

  @override
  String get chatEventEmpty =>
      'Noch nichts geschrieben. Teile hier Infos zum Termin — Treffpunkt, Änderungen, Fragen. Die Beiträge hängen am Termin selbst und sind aus jeder Nostr-App zu sehen.';

  @override
  String get chatMemberHint =>
      'Der Beitritt setzt eine Mitgliedschaft im Einundzwanzig-Verein voraus. Ohne sie lehnt das Relay den Beitritt ab — du bleibst dann stiller Mitleser.';

  @override
  String get chatMemberLink => 'Zum Verein';

  @override
  String walletSince(String month) {
    return 'seit $month';
  }

  @override
  String walletLastVisit(String ago) {
    return 'zuletzt $ago';
  }

  @override
  String get walletAgoToday => 'heute';

  @override
  String get walletAgoYesterday => 'gestern';

  @override
  String walletAgoDays(int days) {
    return 'vor $days Tagen';
  }

  @override
  String walletAgoMonths(int months) {
    return 'vor $months Monaten';
  }

  @override
  String walletAgoYears(int years) {
    return 'vor $years Jahren';
  }

  @override
  String walletCollectionCount(int count) {
    return '$count Badges';
  }

  @override
  String get rsvpYes => 'Ich komme';

  @override
  String get rsvpNo => 'Ich komme nicht';

  @override
  String get tileEventChats => 'Meine Termine';

  @override
  String get tileEventChatsSub => 'Zusagen & Chats';

  @override
  String get eventChatsTitle => 'Meine Termine';

  @override
  String get eventChatsEmpty =>
      'Hier stehen die nächsten Termine deiner Meetups und alle Veranstaltungen, für die du zugesagt hast. Wähle ein Meetup als Favorit oder sage im Kalender zu.';

  @override
  String tileEventChatsUnread(int count) {
    return '$count neue Nachrichten';
  }

  @override
  String get chatYou => 'Du';

  @override
  String get chatCopyNpub => 'npub kopieren';

  @override
  String get chatNpubCopied => 'npub kopiert.';

  @override
  String get eventChatsMeetups => 'Meine Meetups';

  @override
  String get eventChatsEvents => 'Zugesagte Veranstaltungen';

  @override
  String get tileEventChatsNone => 'Nichts geplant';

  @override
  String rsvpAttendees(int count) {
    return '$count dabei';
  }

  @override
  String get rsvpWithdrawTitle => 'Zusage zurücknehmen?';

  @override
  String rsvpWithdrawBody(String title) {
    return '„$title“ verschwindet dann aus deinen Terminen. Der Veranstalter sieht eine Absage — der Chat bleibt über den Kalender erreichbar.';
  }

  @override
  String get rsvpWithdrawConfirm => 'Absagen';

  @override
  String get evBadgeNeedLocation =>
      'Für ein Badge braucht der Termin einen Ort auf der Karte — daran wird geprüft, wer vor Ort ist.';

  @override
  String get evBadgeNoLocationSet =>
      'Für diesen Termin ist kein Ort auf der Karte hinterlegt — dadurch lässt sich hier kein Badge ausgeben oder abholen.';

  @override
  String mvPortalOrganizer(String meetup) {
    return '✓ Organisator von $meetup\nIm Einundzwanzig-Portal als Leader dieses Meetups eingetragen.';
  }

  @override
  String get evCancelAction => 'Termin absagen';

  @override
  String get evCancelTitle => 'Termin absagen?';

  @override
  String evCancelBody(String title) {
    return '„$title“ verschwindet aus allen Kalendern. Nostr kennt kein echtes Löschen — der Termin wird als abgesagt markiert und zusätzlich zur Entfernung gebeten. Rückgängig geht das nicht; du müsstest ihn neu anlegen.';
  }

  @override
  String get evCancelConfirm => 'Absagen';

  @override
  String get evCancelDone => 'Termin abgesagt.';

  @override
  String get evCancelFailed =>
      'Absage nicht angekommen — kein Relay hat sie angenommen.';
}
