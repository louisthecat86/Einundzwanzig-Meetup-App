import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig Meetup'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In de, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWallet.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get navWallet;

  /// No description provided for @navEvents.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @actionSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get actionCancel;

  /// No description provided for @actionConfirm.
  ///
  /// In de, this message translates to:
  /// **'Bestätigen'**
  String get actionConfirm;

  /// No description provided for @actionDelete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get actionDelete;

  /// No description provided for @actionContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get actionContinue;

  /// No description provided for @actionBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get actionBack;

  /// No description provided for @actionClose.
  ///
  /// In de, this message translates to:
  /// **'Schließen'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get actionRetry;

  /// No description provided for @actionOk.
  ///
  /// In de, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// No description provided for @actionUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden'**
  String get actionUnderstood;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// No description provided for @trustScore.
  ///
  /// In de, this message translates to:
  /// **'Trust Score'**
  String get trustScore;

  /// No description provided for @reputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get reputation;

  /// No description provided for @reputationShareQr.
  ///
  /// In de, this message translates to:
  /// **'QR teilen'**
  String get reputationShareQr;

  /// No description provided for @community.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @communityPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get communityPortal;

  /// No description provided for @homeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Home Meetup'**
  String get homeMeetup;

  /// No description provided for @shoutout.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get shoutout;

  /// No description provided for @joinCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community betreten'**
  String get joinCommunity;

  /// No description provided for @identityVerified.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert'**
  String get identityVerified;

  /// No description provided for @verifiedByAdmin.
  ///
  /// In de, this message translates to:
  /// **'Verifiziert durch Admin'**
  String get verifiedByAdmin;

  /// No description provided for @nostrVerified.
  ///
  /// In de, this message translates to:
  /// **'Nostr verifiziert'**
  String get nostrVerified;

  /// No description provided for @profileNickname.
  ///
  /// In de, this message translates to:
  /// **'Nickname'**
  String get profileNickname;

  /// No description provided for @profileChooseHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Home-Meetup'**
  String get profileChooseHomeMeetup;

  /// No description provided for @profileYourIdentity.
  ///
  /// In de, this message translates to:
  /// **'Deine Identität'**
  String get profileYourIdentity;

  /// No description provided for @profileNostrKey.
  ///
  /// In de, this message translates to:
  /// **'NOSTR SCHLÜSSEL'**
  String get profileNostrKey;

  /// No description provided for @profileKeyActive.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel aktiv'**
  String get profileKeyActive;

  /// No description provided for @requiredField.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte ausfüllen'**
  String get requiredField;

  /// No description provided for @requiredHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte wähle dein Home-Meetup'**
  String get requiredHomeMeetup;

  /// No description provided for @fillRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen: {fields}'**
  String fillRequired(String fields);

  /// No description provided for @identityGenerateKey.
  ///
  /// In de, this message translates to:
  /// **'Neuen Schlüssel erstellen'**
  String get identityGenerateKey;

  /// No description provided for @identityConnectAmber.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbinden'**
  String get identityConnectAmber;

  /// No description provided for @identityImportNsec.
  ///
  /// In de, this message translates to:
  /// **'Bestehenden nsec importieren'**
  String get identityImportNsec;

  /// No description provided for @amberConnected.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbunden! Dein nsec bleibt in Amber.'**
  String get amberConnected;

  /// No description provided for @amberNotFound.
  ///
  /// In de, this message translates to:
  /// **'Amber nicht gefunden'**
  String get amberNotFound;

  /// No description provided for @amberCancelled.
  ///
  /// In de, this message translates to:
  /// **'Verbindung in Amber abgebrochen.'**
  String get amberCancelled;

  /// No description provided for @walletTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Badges'**
  String get walletTitle;

  /// No description provided for @badgesCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Badges} =1{1 Badge} other{{count} Badges}}'**
  String badgesCount(int count);

  /// No description provided for @eventInDays.
  ///
  /// In de, this message translates to:
  /// **'in {days, plural, =0{heute} =1{1 Tag} other{{days} Tagen}}'**
  String eventInDays(int days);

  /// No description provided for @tileTrustScore.
  ///
  /// In de, this message translates to:
  /// **'Trust Score'**
  String get tileTrustScore;

  /// No description provided for @tileReputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get tileReputation;

  /// No description provided for @tileReputationShare.
  ///
  /// In de, this message translates to:
  /// **'QR teilen'**
  String get tileReputationShare;

  /// No description provided for @tileReputationCheck.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get tileReputationCheck;

  /// No description provided for @tileCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get tileCommunity;

  /// No description provided for @tileCommunityPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get tileCommunityPortal;

  /// No description provided for @tileEvents.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get tileEvents;

  /// No description provided for @tileEventsCalendar.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get tileEventsCalendar;

  /// No description provided for @tileShoutout.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get tileShoutout;

  /// No description provided for @tileShoutoutSend.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get tileShoutoutSend;

  /// No description provided for @tilePodcast.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get tilePodcast;

  /// No description provided for @tilePodcastListen.
  ///
  /// In de, this message translates to:
  /// **'Anhören'**
  String get tilePodcastListen;

  /// No description provided for @tileNostr.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get tileNostr;

  /// No description provided for @tileNostrCommunity.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get tileNostrCommunity;

  /// No description provided for @tileOrganizer.
  ///
  /// In de, this message translates to:
  /// **'Organisator'**
  String get tileOrganizer;

  /// No description provided for @tileOrganizerPanel.
  ///
  /// In de, this message translates to:
  /// **'Admin-Panel'**
  String get tileOrganizerPanel;

  /// No description provided for @tileOrganizerNew.
  ///
  /// In de, this message translates to:
  /// **'Neu via Trust Score'**
  String get tileOrganizerNew;

  /// No description provided for @tileWot.
  ///
  /// In de, this message translates to:
  /// **'WoT'**
  String get tileWot;

  /// No description provided for @tileWotSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Web of Trust'**
  String get tileWotSubtitle;

  /// No description provided for @homeMeetupLabel.
  ///
  /// In de, this message translates to:
  /// **'HOME MEETUP'**
  String get homeMeetupLabel;

  /// No description provided for @homeMeetupChoose.
  ///
  /// In de, this message translates to:
  /// **'Wähle deinen Stammtisch'**
  String get homeMeetupChoose;

  /// No description provided for @homeMeetupChooseSub.
  ///
  /// In de, this message translates to:
  /// **'Dein regelmäßiges Meetup auswählen'**
  String get homeMeetupChooseSub;

  /// No description provided for @homeMeetupBadges.
  ///
  /// In de, this message translates to:
  /// **'{count} Badges'**
  String homeMeetupBadges(int count);

  /// No description provided for @homeMeetupToday.
  ///
  /// In de, this message translates to:
  /// **'Heute!'**
  String get homeMeetupToday;

  /// No description provided for @homeMeetupTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get homeMeetupTomorrow;

  /// No description provided for @homeMeetupInDays.
  ///
  /// In de, this message translates to:
  /// **'in {days} Tagen'**
  String homeMeetupInDays(int days);

  /// No description provided for @homeMeetupNoDate.
  ///
  /// In de, this message translates to:
  /// **'Kein Termin geplant'**
  String get homeMeetupNoDate;

  /// No description provided for @homeMeetupNextEvent.
  ///
  /// In de, this message translates to:
  /// **'Nächstes Meetup'**
  String get homeMeetupNextEvent;

  /// No description provided for @homeMeetupNoneSoon.
  ///
  /// In de, this message translates to:
  /// **'Kein Termin in Sicht.\nWird Zeit, das zu ändern!'**
  String get homeMeetupNoneSoon;

  /// No description provided for @homeMeetupSelectFirst.
  ///
  /// In de, this message translates to:
  /// **'Erst Home Meetup\nwählen!'**
  String get homeMeetupSelectFirst;

  /// No description provided for @btnEvents.
  ///
  /// In de, this message translates to:
  /// **'EVENTS'**
  String get btnEvents;

  /// No description provided for @statusLive.
  ///
  /// In de, this message translates to:
  /// **'LIVE'**
  String get statusLive;

  /// No description provided for @statusMeetupActive.
  ///
  /// In de, this message translates to:
  /// **'Meetup aktiv'**
  String get statusMeetupActive;

  /// No description provided for @loading.
  ///
  /// In de, this message translates to:
  /// **'Lade...'**
  String get loading;

  /// No description provided for @organizerPromoted.
  ///
  /// In de, this message translates to:
  /// **'Du bist jetzt ORGANISATOR!'**
  String get organizerPromoted;

  /// No description provided for @resetTitle.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen?'**
  String get resetTitle;

  /// No description provided for @resetBody.
  ///
  /// In de, this message translates to:
  /// **'Alle Badges und dein Profil werden gelöscht.'**
  String get resetBody;

  /// No description provided for @resetCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbruch'**
  String get resetCancel;

  /// No description provided for @resetConfirm.
  ///
  /// In de, this message translates to:
  /// **'LÖSCHEN'**
  String get resetConfirm;

  /// No description provided for @settingsSectionBackup.
  ///
  /// In de, this message translates to:
  /// **'DATENSICHERUNG'**
  String get settingsSectionBackup;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In de, this message translates to:
  /// **'SPRACHE'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionNostr.
  ///
  /// In de, this message translates to:
  /// **'NOSTR-NETZWERK'**
  String get settingsSectionNostr;

  /// No description provided for @settingsSectionControl.
  ///
  /// In de, this message translates to:
  /// **'BEDIENUNG'**
  String get settingsSectionControl;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In de, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSectionAccount;

  /// No description provided for @settingsBackup.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellen'**
  String get settingsBackup;

  /// No description provided for @settingsBackupSub.
  ///
  /// In de, this message translates to:
  /// **'Sichere deinen Account'**
  String get settingsBackupSub;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageChoose.
  ///
  /// In de, this message translates to:
  /// **'Sprache wählen'**
  String get settingsLanguageChoose;

  /// No description provided for @settingsRelays.
  ///
  /// In de, this message translates to:
  /// **'Nostr-Relays'**
  String get settingsRelays;

  /// No description provided for @settingsRelaysSub.
  ///
  /// In de, this message translates to:
  /// **'Relays konfigurieren'**
  String get settingsRelaysSub;

  /// No description provided for @settingsHaptic.
  ///
  /// In de, this message translates to:
  /// **'Vibrationsfeedback'**
  String get settingsHaptic;

  /// No description provided for @settingsHapticOn.
  ///
  /// In de, this message translates to:
  /// **'Aktiv'**
  String get settingsHapticOn;

  /// No description provided for @settingsHapticOff.
  ///
  /// In de, this message translates to:
  /// **'Deaktiviert'**
  String get settingsHapticOff;

  /// No description provided for @settingsReset.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen'**
  String get settingsReset;

  /// No description provided for @settingsResetSub.
  ///
  /// In de, this message translates to:
  /// **'Löscht Profil und Badges'**
  String get settingsResetSub;

  /// No description provided for @introTagline.
  ///
  /// In de, this message translates to:
  /// **'DEINE BITCOIN COMMUNITY'**
  String get introTagline;

  /// No description provided for @introJoin.
  ///
  /// In de, this message translates to:
  /// **'COMMUNITY BETRETEN'**
  String get introJoin;

  /// No description provided for @introLoadBackup.
  ///
  /// In de, this message translates to:
  /// **'BACKUP LADEN'**
  String get introLoadBackup;

  /// No description provided for @introSetIdentity.
  ///
  /// In de, this message translates to:
  /// **'Bitte lege zuerst deine Identität fest.'**
  String get introSetIdentity;

  /// No description provided for @navWalletTab.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get navWalletTab;

  /// No description provided for @navProfileTab.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get navProfileTab;

  /// No description provided for @scanBadge.
  ///
  /// In de, this message translates to:
  /// **'Badge scannen'**
  String get scanBadge;

  /// No description provided for @scanBadgeSub.
  ///
  /// In de, this message translates to:
  /// **'QR-Code vom Meetup'**
  String get scanBadgeSub;

  /// No description provided for @scanReputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation prüfen'**
  String get scanReputation;

  /// No description provided for @scanReputationSub.
  ///
  /// In de, this message translates to:
  /// **'Trust Score einer anderen Person verifizieren'**
  String get scanReputationSub;

  /// No description provided for @calendarTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TERMINE'**
  String get calendarTitle;

  /// No description provided for @calendarSearch.
  ///
  /// In de, this message translates to:
  /// **'Suche (z.B. München, Bitcoin...)'**
  String get calendarSearch;

  /// No description provided for @calendarNoEvents.
  ///
  /// In de, this message translates to:
  /// **'Keine Termine gefunden.'**
  String get calendarNoEvents;

  /// No description provided for @sectionDescription.
  ///
  /// In de, this message translates to:
  /// **'BESCHREIBUNG'**
  String get sectionDescription;

  /// No description provided for @sectionLocation.
  ///
  /// In de, this message translates to:
  /// **'STANDORT'**
  String get sectionLocation;

  /// No description provided for @sectionDates.
  ///
  /// In de, this message translates to:
  /// **'TERMINE'**
  String get sectionDates;

  /// No description provided for @sectionLinks.
  ///
  /// In de, this message translates to:
  /// **'LINKS'**
  String get sectionLinks;

  /// No description provided for @meetupRoute.
  ///
  /// In de, this message translates to:
  /// **'Route'**
  String get meetupRoute;

  /// No description provided for @meetupNoDatesCal.
  ///
  /// In de, this message translates to:
  /// **'Aktuell keine Termine im Kalender.'**
  String get meetupNoDatesCal;

  /// No description provided for @errorOpenLink.
  ///
  /// In de, this message translates to:
  /// **'Konnte Link nicht öffnen'**
  String get errorOpenLink;

  /// No description provided for @walletNoBadges.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Badges gesammelt'**
  String get walletNoBadges;

  /// No description provided for @walletNoBadgesSub.
  ///
  /// In de, this message translates to:
  /// **'Besuche Meetups und scanne den QR-Code, um Badges zu sammeln!'**
  String get walletNoBadgesSub;

  /// No description provided for @walletShareReputation.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION TEILEN'**
  String get walletShareReputation;

  /// No description provided for @walletShowQr.
  ///
  /// In de, this message translates to:
  /// **'QR-Code anzeigen'**
  String get walletShowQr;

  /// No description provided for @walletShowQrSub.
  ///
  /// In de, this message translates to:
  /// **'Zum Scannen vor Ort'**
  String get walletShowQrSub;

  /// No description provided for @walletExportJson.
  ///
  /// In de, this message translates to:
  /// **'Als JSON exportieren'**
  String get walletExportJson;

  /// No description provided for @walletExportJsonSub.
  ///
  /// In de, this message translates to:
  /// **'Signierter Export mit Schnorr-Beweis'**
  String get walletExportJsonSub;

  /// No description provided for @walletShareText.
  ///
  /// In de, this message translates to:
  /// **'Als Text teilen'**
  String get walletShareText;

  /// No description provided for @walletShareTextSub.
  ///
  /// In de, this message translates to:
  /// **'Lesbar für alle (wird im Web kopiert)'**
  String get walletShareTextSub;

  /// No description provided for @walletShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputation teilen'**
  String get walletShareTitle;

  /// No description provided for @walletJsonCopied.
  ///
  /// In de, this message translates to:
  /// **'JSON-Daten in Zwischenablage kopiert'**
  String get walletJsonCopied;

  /// No description provided for @walletReputationCopied.
  ///
  /// In de, this message translates to:
  /// **'Reputation in Zwischenablage kopiert'**
  String get walletReputationCopied;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @badgeDetailsTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge-Details'**
  String get badgeDetailsTitle;

  /// No description provided for @badgeShare.
  ///
  /// In de, this message translates to:
  /// **'Badge teilen'**
  String get badgeShare;

  /// No description provided for @badgeShareCaps.
  ///
  /// In de, this message translates to:
  /// **'BADGE TEILEN'**
  String get badgeShareCaps;

  /// No description provided for @badgeClose.
  ///
  /// In de, this message translates to:
  /// **'SCHLIESSEN'**
  String get badgeClose;

  /// No description provided for @badgeProofTitle.
  ///
  /// In de, this message translates to:
  /// **'Kryptographischer Beweis'**
  String get badgeProofTitle;

  /// No description provided for @badgeProofOfAttendance.
  ///
  /// In de, this message translates to:
  /// **'PROOF OF ATTENDANCE'**
  String get badgeProofOfAttendance;

  /// No description provided for @badgeProofDesc.
  ///
  /// In de, this message translates to:
  /// **'Dieses Badge bestätigt kryptografisch, dass du physisch vor Ort warst.'**
  String get badgeProofDesc;

  /// No description provided for @badgeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup'**
  String get badgeMeetup;

  /// No description provided for @badgeMeetupDate.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Datum'**
  String get badgeMeetupDate;

  /// No description provided for @badgeMeetupId.
  ///
  /// In de, this message translates to:
  /// **'Meetup-ID'**
  String get badgeMeetupId;

  /// No description provided for @badgeOrganizerNpub.
  ///
  /// In de, this message translates to:
  /// **'Organisator (npub)'**
  String get badgeOrganizerNpub;

  /// No description provided for @badgeSignatureType.
  ///
  /// In de, this message translates to:
  /// **'Signaturtyp'**
  String get badgeSignatureType;

  /// No description provided for @badgeTransmission.
  ///
  /// In de, this message translates to:
  /// **'Übertragungsweg'**
  String get badgeTransmission;

  /// No description provided for @badgeTimestamp.
  ///
  /// In de, this message translates to:
  /// **'Zeitstempel'**
  String get badgeTimestamp;

  /// No description provided for @badgeScanTime.
  ///
  /// In de, this message translates to:
  /// **'Scan-Zeitpunkt'**
  String get badgeScanTime;

  /// No description provided for @badgeVerificationHash.
  ///
  /// In de, this message translates to:
  /// **'VERIFIKATIONS-HASH'**
  String get badgeVerificationHash;

  /// No description provided for @badgeClaimBinding.
  ///
  /// In de, this message translates to:
  /// **'Claim-Binding'**
  String get badgeClaimBinding;

  /// No description provided for @badgeBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden ✓'**
  String get badgeBound;

  /// No description provided for @badgeNotBound.
  ///
  /// In de, this message translates to:
  /// **'Nicht gebunden'**
  String get badgeNotBound;

  /// No description provided for @badgeClaimedLater.
  ///
  /// In de, this message translates to:
  /// **'Nachträglich geclaimed'**
  String get badgeClaimedLater;

  /// No description provided for @badgeNote.
  ///
  /// In de, this message translates to:
  /// **'Hinweis'**
  String get badgeNote;

  /// No description provided for @badgeNoSignature.
  ///
  /// In de, this message translates to:
  /// **'Keine Signatur'**
  String get badgeNoSignature;

  /// No description provided for @badgeHashCopied.
  ///
  /// In de, this message translates to:
  /// **'Hash kopiert'**
  String get badgeHashCopied;

  /// No description provided for @badgeInfoCopied.
  ///
  /// In de, this message translates to:
  /// **'Badge-Info in Zwischenablage kopiert'**
  String get badgeInfoCopied;

  /// No description provided for @badgeNfcTag.
  ///
  /// In de, this message translates to:
  /// **'NFC-Tag'**
  String get badgeNfcTag;

  /// No description provided for @badgeRollingQr.
  ///
  /// In de, this message translates to:
  /// **'Rolling QR-Code'**
  String get badgeRollingQr;

  /// No description provided for @levelNew.
  ///
  /// In de, this message translates to:
  /// **'NEU'**
  String get levelNew;

  /// No description provided for @levelStarter.
  ///
  /// In de, this message translates to:
  /// **'STARTER'**
  String get levelStarter;

  /// No description provided for @levelActive.
  ///
  /// In de, this message translates to:
  /// **'AKTIV'**
  String get levelActive;

  /// No description provided for @levelEstablished.
  ///
  /// In de, this message translates to:
  /// **'ETABLIERT'**
  String get levelEstablished;

  /// No description provided for @levelVeteran.
  ///
  /// In de, this message translates to:
  /// **'VETERAN'**
  String get levelVeteran;

  /// No description provided for @reputationTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION'**
  String get reputationTitle;

  /// No description provided for @reputationNoBadges.
  ///
  /// In de, this message translates to:
  /// **'NOCH KEINE BADGES'**
  String get reputationNoBadges;

  /// No description provided for @reputationNoProofs.
  ///
  /// In de, this message translates to:
  /// **'Noch keine kryptographischen Beweise'**
  String get reputationNoProofs;

  /// No description provided for @reputationBuildHint1.
  ///
  /// In de, this message translates to:
  /// **'Besuche ein Meetup und scanne einen Badge um '**
  String get reputationBuildHint1;

  /// No description provided for @reputationBuildHint2.
  ///
  /// In de, this message translates to:
  /// **'deine Reputation aufzubauen.'**
  String get reputationBuildHint2;

  /// No description provided for @reputationScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR-CODE SCANNEN'**
  String get reputationScanQr;

  /// No description provided for @reputationShareImage.
  ///
  /// In de, this message translates to:
  /// **'QR ALS BILD TEILEN'**
  String get reputationShareImage;

  /// No description provided for @reputationUpdateRelays.
  ///
  /// In de, this message translates to:
  /// **'AUF RELAYS AKTUALISIEREN'**
  String get reputationUpdateRelays;

  /// No description provided for @reputationPublishing.
  ///
  /// In de, this message translates to:
  /// **'PUBLIZIERE...'**
  String get reputationPublishing;

  /// No description provided for @reputationBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get reputationBadges;

  /// No description provided for @reputationMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get reputationMeetups;

  /// No description provided for @reputationSigners.
  ///
  /// In de, this message translates to:
  /// **'Signer'**
  String get reputationSigners;

  /// No description provided for @reputationBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden'**
  String get reputationBound;

  /// No description provided for @reputationSchnorrSigned.
  ///
  /// In de, this message translates to:
  /// **'Schnorr-signiert'**
  String get reputationSchnorrSigned;

  /// No description provided for @reputationSignedNoId.
  ///
  /// In de, this message translates to:
  /// **'Signiert (ohne Identität)'**
  String get reputationSignedNoId;

  /// No description provided for @reputationNoIdentity.
  ///
  /// In de, this message translates to:
  /// **'Keine Identität verknüpft. Ergänze Telegram oder Nostr in deinem Profil.'**
  String get reputationNoIdentity;

  /// No description provided for @reputationCheck.
  ///
  /// In de, this message translates to:
  /// **'Reputation prüfen'**
  String get reputationCheck;

  /// No description provided for @reputationVerified.
  ///
  /// In de, this message translates to:
  /// **'Meine verifizierte Meetup-Reputation'**
  String get reputationVerified;

  /// No description provided for @reputationCodeFrom.
  ///
  /// In de, this message translates to:
  /// **'Reputationscode von'**
  String get reputationCodeFrom;

  /// No description provided for @portalDiscover.
  ///
  /// In de, this message translates to:
  /// **'ENTDECKEN'**
  String get portalDiscover;

  /// No description provided for @portalQuickAccess.
  ///
  /// In de, this message translates to:
  /// **'SCHNELLZUGRIFF'**
  String get portalQuickAccess;

  /// No description provided for @portalPodcastMedia.
  ///
  /// In de, this message translates to:
  /// **'PODCAST & MEDIA'**
  String get portalPodcastMedia;

  /// No description provided for @portalSocialNetworks.
  ///
  /// In de, this message translates to:
  /// **'SOZIALE NETZWERKE'**
  String get portalSocialNetworks;

  /// No description provided for @portalAssociation.
  ///
  /// In de, this message translates to:
  /// **'VEREIN'**
  String get portalAssociation;

  /// No description provided for @portalProfile.
  ///
  /// In de, this message translates to:
  /// **'Dein Profil & Badges'**
  String get portalProfile;

  /// No description provided for @portalMeetupMap.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Karte'**
  String get portalMeetupMap;

  /// No description provided for @portalMeetupMapSub.
  ///
  /// In de, this message translates to:
  /// **'Treffen in deiner Nähe'**
  String get portalMeetupMapSub;

  /// No description provided for @portalBeginnerPath.
  ///
  /// In de, this message translates to:
  /// **'Der Weg (Einsteiger)'**
  String get portalBeginnerPath;

  /// No description provided for @portalShoutoutSend.
  ///
  /// In de, this message translates to:
  /// **'Shoutout senden'**
  String get portalShoutoutSend;

  /// No description provided for @portalMembership.
  ///
  /// In de, this message translates to:
  /// **'Mitglied werden'**
  String get portalMembership;

  /// No description provided for @portalSoundboard.
  ///
  /// In de, this message translates to:
  /// **'Soundboard'**
  String get portalSoundboard;

  /// No description provided for @portalClipsSounds.
  ///
  /// In de, this message translates to:
  /// **'Clips & Sounds'**
  String get portalClipsSounds;

  /// No description provided for @portalInterviews.
  ///
  /// In de, this message translates to:
  /// **'Interviews'**
  String get portalInterviews;

  /// No description provided for @portalMediaArticles.
  ///
  /// In de, this message translates to:
  /// **'Media & Artikel'**
  String get portalMediaArticles;

  /// No description provided for @portalMerch.
  ///
  /// In de, this message translates to:
  /// **'Merch & Bitcoin-Produkte'**
  String get portalMerch;

  /// No description provided for @portalShop.
  ///
  /// In de, this message translates to:
  /// **'Shop'**
  String get portalShop;

  /// No description provided for @portalDonate.
  ///
  /// In de, this message translates to:
  /// **'Spenden'**
  String get portalDonate;

  /// No description provided for @portalContact.
  ///
  /// In de, this message translates to:
  /// **'Kontakt'**
  String get portalContact;

  /// No description provided for @portalPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get portalPrivacy;

  /// No description provided for @portalStatutes.
  ///
  /// In de, this message translates to:
  /// **'Satzung (PDF)'**
  String get portalStatutes;

  /// No description provided for @portalAboutAssoc.
  ///
  /// In de, this message translates to:
  /// **'Über den Verein'**
  String get portalAboutAssoc;

  /// No description provided for @portalOpen.
  ///
  /// In de, this message translates to:
  /// **'Portal öffnen'**
  String get portalOpen;

  /// No description provided for @portalTagline.
  ///
  /// In de, this message translates to:
  /// **'für bullishe Bitcoiner.'**
  String get portalTagline;

  /// No description provided for @portalInfotainment.
  ///
  /// In de, this message translates to:
  /// **'Toximalistisches Infotainment'**
  String get portalInfotainment;

  /// No description provided for @portalPodcast.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get portalPodcast;

  /// No description provided for @portalProfile2.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get portalProfile2;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'DEIN PROFIL'**
  String get profileTitle;

  /// No description provided for @profileEditTitle.
  ///
  /// In de, this message translates to:
  /// **'PROFIL BEARBEITEN'**
  String get profileEditTitle;

  /// No description provided for @profileSave.
  ///
  /// In de, this message translates to:
  /// **'PROFIL SPEICHERN'**
  String get profileSave;

  /// No description provided for @profileIntro.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Nickname und dein Home-Meetup.'**
  String get profileIntro;

  /// No description provided for @profileNicknameMin.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 2 Zeichen'**
  String get profileNicknameMin;

  /// No description provided for @profileNicknameReq.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte ausfüllen'**
  String get profileNicknameReq;

  /// No description provided for @profileNicknameAnon.
  ///
  /// In de, this message translates to:
  /// **'Bitte wähle einen eigenen Nickname (nicht \'Anon\')'**
  String get profileNicknameAnon;

  /// No description provided for @profileHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Home Meetup'**
  String get profileHomeMeetup;

  /// No description provided for @profileHomeMeetupDash.
  ///
  /// In de, this message translates to:
  /// **'Home-Meetup'**
  String get profileHomeMeetupDash;

  /// No description provided for @profileChooseMeetup.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Home-Meetup'**
  String get profileChooseMeetup;

  /// No description provided for @profileMeetupReq.
  ///
  /// In de, this message translates to:
  /// **'Pflichtfeld — bitte wähle dein Home-Meetup'**
  String get profileMeetupReq;

  /// No description provided for @profileSearchCity.
  ///
  /// In de, this message translates to:
  /// **'Stadt suchen...'**
  String get profileSearchCity;

  /// No description provided for @profileIdentity.
  ///
  /// In de, this message translates to:
  /// **'DEINE IDENTITÄT'**
  String get profileIdentity;

  /// No description provided for @profileStrengthen.
  ///
  /// In de, this message translates to:
  /// **'IDENTITÄT STÄRKEN'**
  String get profileStrengthen;

  /// No description provided for @profileStrengthenDesc.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfe Plattformen und beweise deine Menschlichkeit um deinen Trust Score zu erhöhen.'**
  String get profileStrengthenDesc;

  /// No description provided for @profileLinkPlatforms.
  ///
  /// In de, this message translates to:
  /// **'Plattformen verknüpfen'**
  String get profileLinkPlatforms;

  /// No description provided for @profilePlatformsSub.
  ///
  /// In de, this message translates to:
  /// **'Telegram, X, Kleinanzeigen'**
  String get profilePlatformsSub;

  /// No description provided for @profileProofHumanity.
  ///
  /// In de, this message translates to:
  /// **'Proof of Humanity'**
  String get profileProofHumanity;

  /// No description provided for @profileZapCheck.
  ///
  /// In de, this message translates to:
  /// **'Einmal gezappt? Jetzt prüfen'**
  String get profileZapCheck;

  /// No description provided for @profileLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get profileLightningActive;

  /// No description provided for @profileVerified.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT'**
  String get profileVerified;

  /// No description provided for @profileNostrKeyShort.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get profileNostrKeyShort;

  /// No description provided for @profileNoKey.
  ///
  /// In de, this message translates to:
  /// **'Noch kein Nostr-Key vorhanden'**
  String get profileNoKey;

  /// No description provided for @profileKeyActiveCaps.
  ///
  /// In de, this message translates to:
  /// **'SCHLÜSSEL AKTIV'**
  String get profileKeyActiveCaps;

  /// No description provided for @profileCreateKey.
  ///
  /// In de, this message translates to:
  /// **'NOSTR KEY ERSTELLEN'**
  String get profileCreateKey;

  /// No description provided for @profileCreateNewKey.
  ///
  /// In de, this message translates to:
  /// **'NEUEN KEY ERSTELLEN'**
  String get profileCreateNewKey;

  /// No description provided for @profileCreating.
  ///
  /// In de, this message translates to:
  /// **'WIRD ERSTELLT...'**
  String get profileCreating;

  /// No description provided for @profileNoNostrNeeded.
  ///
  /// In de, this message translates to:
  /// **'Du brauchst kein Nostr-Konto. Die App erstellt dir einen Schlüssel — das dauert eine Sekunde.'**
  String get profileNoNostrNeeded;

  /// No description provided for @profileKeyDesc.
  ///
  /// In de, this message translates to:
  /// **'Dein kryptografischer Schlüssel — damit werden Badges signiert und deine Reputation verifiziert.'**
  String get profileKeyDesc;

  /// No description provided for @profileConnectAmber.
  ///
  /// In de, this message translates to:
  /// **'MIT AMBER VERBINDEN'**
  String get profileConnectAmber;

  /// No description provided for @profileConnectExtension.
  ///
  /// In de, this message translates to:
  /// **'MIT BROWSERERWEITERUNG VERBINDEN'**
  String get profileConnectExtension;

  /// No description provided for @profileExtensionConnected.
  ///
  /// In de, this message translates to:
  /// **'Erweiterung verbunden! Dein Schlüssel bleibt dort.'**
  String get profileExtensionConnected;

  /// No description provided for @profileExtensionAborted.
  ///
  /// In de, this message translates to:
  /// **'In der Erweiterung abgelehnt.'**
  String get profileExtensionAborted;

  /// No description provided for @profileExtensionNotFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Nostr-Erweiterung im Browser gefunden.'**
  String get profileExtensionNotFound;

  /// No description provided for @profileAmberDesc.
  ///
  /// In de, this message translates to:
  /// **'Amber ist ein separater Signer für Android, der deinen privaten '**
  String get profileAmberDesc;

  /// No description provided for @profileAmberConnected.
  ///
  /// In de, this message translates to:
  /// **'Mit Amber verbunden! Dein nsec bleibt in Amber.'**
  String get profileAmberConnected;

  /// No description provided for @profileAmberNotFound.
  ///
  /// In de, this message translates to:
  /// **'Amber nicht gefunden'**
  String get profileAmberNotFound;

  /// No description provided for @profileAmberInstall.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel sicher verwahrt. Installiere Amber (z.B. über F-Droid '**
  String get profileAmberInstall;

  /// No description provided for @profileAmberRetry.
  ///
  /// In de, this message translates to:
  /// **'oder den Zapstore) und versuche es erneut.'**
  String get profileAmberRetry;

  /// No description provided for @profileAmberAborted.
  ///
  /// In de, this message translates to:
  /// **'Verbindung in Amber abgebrochen.'**
  String get profileAmberAborted;

  /// No description provided for @profileSwitchSignerHeading.
  ///
  /// In de, this message translates to:
  /// **'Anderen Signer verbinden'**
  String get profileSwitchSignerHeading;

  /// No description provided for @profileDisconnectSigner.
  ///
  /// In de, this message translates to:
  /// **'SIGNER TRENNEN'**
  String get profileDisconnectSigner;

  /// No description provided for @profileDisconnectTitle.
  ///
  /// In de, this message translates to:
  /// **'Signer trennen?'**
  String get profileDisconnectTitle;

  /// No description provided for @profileDisconnectBody.
  ///
  /// In de, this message translates to:
  /// **'Die Verbindung zum Signer wird gelöst. Ist ein lokaler Schlüssel vorhanden, nutzt die App wieder ihn — sonst kann sie nicht signieren, bis du einen erstellst oder importierst.\n\nIm Signer selbst bleibt die Freigabe bestehen; die kannst du dort zusätzlich widerrufen.'**
  String get profileDisconnectBody;

  /// No description provided for @profileDisconnectDone.
  ///
  /// In de, this message translates to:
  /// **'Signer getrennt.'**
  String get profileDisconnectDone;

  /// No description provided for @profileSignerUnusable.
  ///
  /// In de, this message translates to:
  /// **'Signieren ist derzeit nicht möglich — verbinde den Signer neu.'**
  String get profileSignerUnusable;

  /// No description provided for @profileSwitchSignerHint.
  ///
  /// In de, this message translates to:
  /// **'Dein bisheriger Schlüssel bleibt gespeichert und im Backup.'**
  String get profileSwitchSignerHint;

  /// No description provided for @profileSwitchSignerTitle.
  ///
  /// In de, this message translates to:
  /// **'Signer wechseln?'**
  String get profileSwitchSignerTitle;

  /// No description provided for @profileSwitchSignerBody.
  ///
  /// In de, this message translates to:
  /// **'Der Signer bringt seinen eigenen Schlüssel mit. Enthält er NICHT denselben wie bisher, wechselt deine Identität — deine Badges gehören dann weiter zum alten Schlüssel.\n\nDein bisheriger Schlüssel wird nicht gelöscht: er bleibt im Speicher und im Backup, du kannst also zurück.'**
  String get profileSwitchSignerBody;

  /// No description provided for @profileSwitchSignerContinue.
  ///
  /// In de, this message translates to:
  /// **'WEITER'**
  String get profileSwitchSignerContinue;

  /// No description provided for @profileIdentityChanged.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Der Signer nutzt eine andere Identität als bisher. Deine Badges gehören zum vorherigen Schlüssel.'**
  String get profileIdentityChanged;

  /// No description provided for @profileConnectBunker.
  ///
  /// In de, this message translates to:
  /// **'MIT REMOTE-SIGNER VERBINDEN'**
  String get profileConnectBunker;

  /// No description provided for @bunkerTitle.
  ///
  /// In de, this message translates to:
  /// **'Mit Remote-Signer verbinden'**
  String get bunkerTitle;

  /// No description provided for @bunkerIntro.
  ///
  /// In de, this message translates to:
  /// **'Dein Schlüssel bleibt im Signer. Die App fragt dort nur Signaturen an — auf jedem Gerät.'**
  String get bunkerIntro;

  /// No description provided for @bunkerModeSigner.
  ///
  /// In de, this message translates to:
  /// **'Signer-App verbinden'**
  String get bunkerModeSigner;

  /// No description provided for @bunkerModeSignerDesc.
  ///
  /// In de, this message translates to:
  /// **'Die App zeigt einen QR-Code, den du im Signer scannst.'**
  String get bunkerModeSignerDesc;

  /// No description provided for @bunkerModePaste.
  ///
  /// In de, this message translates to:
  /// **'bunker://-Adresse einfügen'**
  String get bunkerModePaste;

  /// No description provided for @bunkerModePasteDesc.
  ///
  /// In de, this message translates to:
  /// **'Kopiere sie aus nsec.app, Amber oder Alby. Auf dem iPhone der zuverlässigste Weg.'**
  String get bunkerModePasteDesc;

  /// No description provided for @bunkerPasteLabel.
  ///
  /// In de, this message translates to:
  /// **'bunker://-Adresse'**
  String get bunkerPasteLabel;

  /// No description provided for @bunkerPasteHint.
  ///
  /// In de, this message translates to:
  /// **'bunker://…?relay=wss://…'**
  String get bunkerPasteHint;

  /// No description provided for @bunkerConnect.
  ///
  /// In de, this message translates to:
  /// **'VERBINDEN'**
  String get bunkerConnect;

  /// No description provided for @bunkerBack.
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK'**
  String get bunkerBack;

  /// No description provided for @bunkerWaiting.
  ///
  /// In de, this message translates to:
  /// **'Warte auf die Freigabe im Signer …'**
  String get bunkerWaiting;

  /// No description provided for @bunkerWaitingHint.
  ///
  /// In de, this message translates to:
  /// **'Das kann bis zu zwei Minuten dauern. Lass die App offen.'**
  String get bunkerWaitingHint;

  /// No description provided for @bunkerScanHint.
  ///
  /// In de, this message translates to:
  /// **'Im Signer scannen — oder die Adresse dort einfügen.'**
  String get bunkerScanHint;

  /// No description provided for @bunkerCopy.
  ///
  /// In de, this message translates to:
  /// **'Adresse kopieren'**
  String get bunkerCopy;

  /// No description provided for @bunkerCopied.
  ///
  /// In de, this message translates to:
  /// **'Adresse kopiert.'**
  String get bunkerCopied;

  /// No description provided for @bunkerOpenSigner.
  ///
  /// In de, this message translates to:
  /// **'Signer öffnen'**
  String get bunkerOpenSigner;

  /// No description provided for @bunkerNoSignerApp.
  ///
  /// In de, this message translates to:
  /// **'Keine Signer-App gefunden. Nimm den Weg über „bunker://-Adresse einfügen“.'**
  String get bunkerNoSignerApp;

  /// No description provided for @bunkerRecommendAndroid.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen auf Android: Amber — Signer-App mit Bunker, im Zapstore und bei F-Droid. Alternativ ein selbst betriebener Bunker (Bunker46, Signet).'**
  String get bunkerRecommendAndroid;

  /// No description provided for @bunkerRecommendIos.
  ///
  /// In de, this message translates to:
  /// **'Empfohlen auf iOS: Clave — weckt sich per Push, um im Hintergrund zu signieren. Alternativ ein selbst betriebener Bunker (Bunker46, Signet) oder Amber auf einem Android-Gerät.'**
  String get bunkerRecommendIos;

  /// No description provided for @bunkerRecommendWeb.
  ///
  /// In de, this message translates to:
  /// **'Als Gegenpart eignen sich Amber (Android), Clave (iOS) oder ein selbst betriebener Bunker wie Bunker46 oder Signet.'**
  String get bunkerRecommendWeb;

  /// No description provided for @bunkerAuthOpen.
  ///
  /// In de, this message translates to:
  /// **'Freigabe im Browser öffnen'**
  String get bunkerAuthOpen;

  /// No description provided for @bunkerAuthNeeded.
  ///
  /// In de, this message translates to:
  /// **'Der Signer verlangt eine Freigabe im Browser.'**
  String get bunkerAuthNeeded;

  /// No description provided for @bunkerAuthAction.
  ///
  /// In de, this message translates to:
  /// **'ÖFFNEN'**
  String get bunkerAuthAction;

  /// No description provided for @bunkerTimeout.
  ///
  /// In de, this message translates to:
  /// **'Der Signer hat nicht geantwortet. Ist er geöffnet und online?'**
  String get bunkerTimeout;

  /// No description provided for @bunkerConnected.
  ///
  /// In de, this message translates to:
  /// **'Remote-Signer verbunden! Dein Schlüssel bleibt dort.'**
  String get bunkerConnected;

  /// No description provided for @bunkerDisconnected.
  ///
  /// In de, this message translates to:
  /// **'Remote-Signer getrennt.'**
  String get bunkerDisconnected;

  /// No description provided for @bunkerCheck.
  ///
  /// In de, this message translates to:
  /// **'VERBINDUNG PRÜFEN'**
  String get bunkerCheck;

  /// No description provided for @bunkerAlive.
  ///
  /// In de, this message translates to:
  /// **'Signer antwortet — die Sitzung ist aktiv. Ob die Freigaben noch gelten, zeigt erst die nächste Signatur.'**
  String get bunkerAlive;

  /// No description provided for @bunkerDead.
  ///
  /// In de, this message translates to:
  /// **'Signer antwortet nicht. Ist er geöffnet und online? Sonst neu verbinden.'**
  String get bunkerDead;

  /// No description provided for @profileImportNsec.
  ///
  /// In de, this message translates to:
  /// **'BESTEHENDEN NSEC IMPORTIEREN'**
  String get profileImportNsec;

  /// No description provided for @profileImportNsecShort.
  ///
  /// In de, this message translates to:
  /// **'NSEC IMPORTIEREN'**
  String get profileImportNsecShort;

  /// No description provided for @keyExportEncrypted.
  ///
  /// In de, this message translates to:
  /// **'VERSCHLÜSSELT EXPORTIEREN (ncryptsec)'**
  String get keyExportEncrypted;

  /// No description provided for @keyExportTitle.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel verschlüsselt exportieren'**
  String get keyExportTitle;

  /// No description provided for @keyExportDesc.
  ///
  /// In de, this message translates to:
  /// **'Erzeugt ein ncryptsec — deinen Schlüssel, mit einem Passwort verschlüsselt. Den kannst du gefahrlos in einem Passwortmanager ablegen und in Amber, Clave, nsec.app oder einem eigenen Bunker importieren.'**
  String get keyExportDesc;

  /// No description provided for @keyExportDuration.
  ///
  /// In de, this message translates to:
  /// **'Die Verschlüsselung ist absichtlich langsam: rund eine halbe Sekunde auf dem Gerät, im Browser bis zu einer halben Minute.'**
  String get keyExportDuration;

  /// No description provided for @keyExportAction.
  ///
  /// In de, this message translates to:
  /// **'EXPORTIEREN'**
  String get keyExportAction;

  /// No description provided for @keyExportMismatch.
  ///
  /// In de, this message translates to:
  /// **'Die Passwörter stimmen nicht überein.'**
  String get keyExportMismatch;

  /// No description provided for @keyExportNoKey.
  ///
  /// In de, this message translates to:
  /// **'Kein lokaler Schlüssel vorhanden.'**
  String get keyExportNoKey;

  /// No description provided for @keyExportReadyTitle.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsselter Schlüssel'**
  String get keyExportReadyTitle;

  /// No description provided for @keyExportReadyBody.
  ///
  /// In de, this message translates to:
  /// **'Ohne dein Passwort ist das hier wertlos — und mit deinem Passwort ist es dein voller Schlüssel. Behandle beides entsprechend.'**
  String get keyExportReadyBody;

  /// No description provided for @keyExportCopy.
  ///
  /// In de, this message translates to:
  /// **'KOPIEREN'**
  String get keyExportCopy;

  /// No description provided for @keyExportCopied.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsselter Schlüssel kopiert.'**
  String get keyExportCopied;

  /// No description provided for @keyExportFromVault.
  ///
  /// In de, this message translates to:
  /// **'Das ist dein Schlüssel mit dem Passwort, das du beim Anlegen gesetzt hast — kein neues Passwort nötig.'**
  String get keyExportFromVault;

  /// No description provided for @keyExportOtherPassword.
  ///
  /// In de, this message translates to:
  /// **'Mit einem anderen Passwort erzeugen'**
  String get keyExportOtherPassword;

  /// No description provided for @profileImport.
  ///
  /// In de, this message translates to:
  /// **'IMPORTIEREN'**
  String get profileImport;

  /// No description provided for @profileEnterNsec.
  ///
  /// In de, this message translates to:
  /// **'Gib deinen privaten Nostr-Schlüssel ein (beginnt mit nsec1...):'**
  String get profileEnterNsec;

  /// No description provided for @profileKeyImported.
  ///
  /// In de, this message translates to:
  /// **'Key importiert!'**
  String get profileKeyImported;

  /// No description provided for @profileShowNsecQ.
  ///
  /// In de, this message translates to:
  /// **'NSEC ANZEIGEN?'**
  String get profileShowNsecQ;

  /// No description provided for @profileShowNsecWarn.
  ///
  /// In de, this message translates to:
  /// **'Dein privater Schlüssel wird angezeigt. Stelle sicher, dass niemand auf deinen Bildschirm schaut!'**
  String get profileShowNsecWarn;

  /// No description provided for @profileShow.
  ///
  /// In de, this message translates to:
  /// **'ANZEIGEN'**
  String get profileShow;

  /// No description provided for @profileCopy.
  ///
  /// In de, this message translates to:
  /// **'KOPIEREN'**
  String get profileCopy;

  /// No description provided for @profileSecureKey.
  ///
  /// In de, this message translates to:
  /// **'SICHERE DEINEN KEY!'**
  String get profileSecureKey;

  /// No description provided for @profileSaveKeyDesc.
  ///
  /// In de, this message translates to:
  /// **'Dies ist dein privater Schlüssel. Speichere ihn an einem sicheren Ort! '**
  String get profileSaveKeyDesc;

  /// No description provided for @profileKeyNotShownAgain.
  ///
  /// In de, this message translates to:
  /// **'Dieser Key wird NICHT nochmal angezeigt!'**
  String get profileKeyNotShownAgain;

  /// No description provided for @profileKeySecured.
  ///
  /// In de, this message translates to:
  /// **'ICH HAB IHN GESICHERT'**
  String get profileKeySecured;

  /// No description provided for @profileNpubCopied.
  ///
  /// In de, this message translates to:
  /// **'npub kopiert!'**
  String get profileNpubCopied;

  /// No description provided for @profileNsecCopied.
  ///
  /// In de, this message translates to:
  /// **'nsec kopiert! Jetzt sicher abspeichern.'**
  String get profileNsecCopied;

  /// No description provided for @profileNsecNeverLeaves.
  ///
  /// In de, this message translates to:
  /// **'Dein nsec verlässt niemals dein Gerät.'**
  String get profileNsecNeverLeaves;

  /// No description provided for @profileWhoHasKey.
  ///
  /// In de, this message translates to:
  /// **'Wer diesen Key hat, HAT deine Identität.'**
  String get profileWhoHasKey;

  /// No description provided for @profileBackupNsec.
  ///
  /// In de, this message translates to:
  /// **'Wichtig: Sichere deinen nsec! Wenn du dein Gerät verlierst, ist dein Key weg.'**
  String get profileBackupNsec;

  /// No description provided for @profileNewKeypairDesc.
  ///
  /// In de, this message translates to:
  /// **'Es wird ein neues Schlüsselpaar erstellt. Dein privater Schlüssel (nsec) wird sicher auf deinem Gerät gespeichert.\n\n'**
  String get profileNewKeypairDesc;

  /// No description provided for @profileEdit.
  ///
  /// In de, this message translates to:
  /// **'Bearbeiten'**
  String get profileEdit;

  /// No description provided for @profileEditLoseStatus.
  ///
  /// In de, this message translates to:
  /// **'BEARBEITEN (Status verlieren)'**
  String get profileEditLoseStatus;

  /// No description provided for @profileWarning.
  ///
  /// In de, this message translates to:
  /// **'Achtung!'**
  String get profileWarning;

  /// No description provided for @profileEditWarnDesc.
  ///
  /// In de, this message translates to:
  /// **'Wenn du bearbeitest, verlierst du deinen \'Verifiziert\'-Status und musst neu freigeschaltet werden.'**
  String get profileEditWarnDesc;

  /// No description provided for @dialogCancel.
  ///
  /// In de, this message translates to:
  /// **'ABBRECHEN'**
  String get dialogCancel;

  /// No description provided for @dialogCancelMixed.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get dialogCancelMixed;

  /// No description provided for @dialogCreate.
  ///
  /// In de, this message translates to:
  /// **'ERSTELLEN'**
  String get dialogCreate;

  /// No description provided for @errorGeneric.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {msg}'**
  String errorGeneric(String msg);

  /// No description provided for @errorAmber.
  ///
  /// In de, this message translates to:
  /// **'Amber-Fehler: {msg}'**
  String errorAmber(String msg);

  /// No description provided for @profileFillIn.
  ///
  /// In de, this message translates to:
  /// **'Bitte ausfüllen: {fields}'**
  String profileFillIn(Object fields);

  /// No description provided for @backupEncryptTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup verschlüsseln'**
  String get backupEncryptTitle;

  /// No description provided for @backupDecryptTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup entschlüsseln'**
  String get backupDecryptTitle;

  /// No description provided for @backupExportDesc.
  ///
  /// In de, this message translates to:
  /// **'Vergib ein Passwort, um deinen privaten Schlüssel (nsec) im Backup zu schützen.\n\n⚠️ Wenn du dieses Passwort vergisst, ist das Backup UNWIEDERBRINGLICH verloren!'**
  String get backupExportDesc;

  /// No description provided for @backupImportDesc.
  ///
  /// In de, this message translates to:
  /// **'Dieses Backup ist verschlüsselt. Bitte gib das Passwort ein.'**
  String get backupImportDesc;

  /// No description provided for @backupPassword.
  ///
  /// In de, this message translates to:
  /// **'Passwort'**
  String get backupPassword;

  /// No description provided for @backupPasswordConfirm.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get backupPasswordConfirm;

  /// No description provided for @backupPasswordEmpty.
  ///
  /// In de, this message translates to:
  /// **'Passwort darf nicht leer sein'**
  String get backupPasswordEmpty;

  /// No description provided for @backupPasswordMin.
  ///
  /// In de, this message translates to:
  /// **'Mindestens 8 Zeichen'**
  String get backupPasswordMin;

  /// No description provided for @backupPasswordMismatch.
  ///
  /// In de, this message translates to:
  /// **'Passwörter stimmen nicht überein'**
  String get backupPasswordMismatch;

  /// No description provided for @backupEncryptSave.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsseln & Speichern'**
  String get backupEncryptSave;

  /// No description provided for @backupDecryptLoad.
  ///
  /// In de, this message translates to:
  /// **'Entschlüsseln & Laden'**
  String get backupDecryptLoad;

  /// No description provided for @backupShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig App Backup (Verschlüsselt)'**
  String get backupShareTitle;

  /// No description provided for @backupShareText.
  ///
  /// In de, this message translates to:
  /// **'Dein verschlüsseltes Backup. Halte dein Passwort bereit, um es wiederherzustellen.'**
  String get backupShareText;

  /// No description provided for @backupError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Backup: {msg}'**
  String backupError(String msg);

  /// No description provided for @backupCorrupt.
  ///
  /// In de, this message translates to:
  /// **'Backup-Datei ist beschädigt (Formatfehler).'**
  String get backupCorrupt;

  /// No description provided for @backupWrongPassword.
  ///
  /// In de, this message translates to:
  /// **'Falsches Passwort oder Datei beschädigt!'**
  String get backupWrongPassword;

  /// No description provided for @backupNotValid.
  ///
  /// In de, this message translates to:
  /// **'Datei ist kein gültiges Backup oder das falsche Format.'**
  String get backupNotValid;

  /// No description provided for @backupNotEinundzwanzig.
  ///
  /// In de, this message translates to:
  /// **'Datei ist kein gültiges Einundzwanzig Backup.'**
  String get backupNotEinundzwanzig;

  /// No description provided for @backupLoaded.
  ///
  /// In de, this message translates to:
  /// **'✅ Backup geladen! {items} wiederhergestellt.'**
  String backupLoaded(Object items);

  /// No description provided for @backupImportFailed.
  ///
  /// In de, this message translates to:
  /// **'Import fehlgeschlagen: {msg}'**
  String backupImportFailed(String msg);

  /// No description provided for @qrScanTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION PRÜFEN'**
  String get qrScanTitle;

  /// No description provided for @qrResultTitle.
  ///
  /// In de, this message translates to:
  /// **'ERGEBNIS'**
  String get qrResultTitle;

  /// No description provided for @qrScanHint.
  ///
  /// In de, this message translates to:
  /// **'Scanne einen Einundzwanzig\nReputation QR-Code'**
  String get qrScanHint;

  /// No description provided for @qrLoadFromGallery.
  ///
  /// In de, this message translates to:
  /// **'QR AUS GALERIE LADEN'**
  String get qrLoadFromGallery;

  /// No description provided for @qrBack.
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK'**
  String get qrBack;

  /// No description provided for @qrNoCodeInImage.
  ///
  /// In de, this message translates to:
  /// **'Kein QR-Code im Bild gefunden'**
  String get qrNoCodeInImage;

  /// No description provided for @qrNotEinundzwanzig.
  ///
  /// In de, this message translates to:
  /// **'QR-Code gefunden, aber kein Einundzwanzig-Format'**
  String get qrNotEinundzwanzig;

  /// No description provided for @qrVerified.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT'**
  String get qrVerified;

  /// No description provided for @qrVerifiedV1.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT (v1)'**
  String get qrVerifiedV1;

  /// No description provided for @qrVerifiedV2.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT (v2)'**
  String get qrVerifiedV2;

  /// No description provided for @qrSigInvalid.
  ///
  /// In de, this message translates to:
  /// **'SIGNATUR UNGÜLTIG'**
  String get qrSigInvalid;

  /// No description provided for @qrFormatUnknown.
  ///
  /// In de, this message translates to:
  /// **'FORMAT UNBEKANNT'**
  String get qrFormatUnknown;

  /// No description provided for @qrReadError.
  ///
  /// In de, this message translates to:
  /// **'LESEFEHLER'**
  String get qrReadError;

  /// No description provided for @qrV2Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Legacy-Signatur gültig — kein Badge-Proof'**
  String get qrV2Subtitle;

  /// No description provided for @qrV1Subtitle.
  ///
  /// In de, this message translates to:
  /// **'Älteres Format — keine Identitätsbindung'**
  String get qrV1Subtitle;

  /// No description provided for @qrCantRead.
  ///
  /// In de, this message translates to:
  /// **'QR-Code konnte nicht gelesen werden.'**
  String get qrCantRead;

  /// No description provided for @qrProcessError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Verarbeiten: {msg}'**
  String qrProcessError(String msg);

  /// No description provided for @qrSectionIdentity.
  ///
  /// In de, this message translates to:
  /// **'IDENTITÄT'**
  String get qrSectionIdentity;

  /// No description provided for @qrNoIdentity.
  ///
  /// In de, this message translates to:
  /// **'KEINE IDENTITÄT'**
  String get qrNoIdentity;

  /// No description provided for @qrNoVerifiableIdentity.
  ///
  /// In de, this message translates to:
  /// **'Keine verifizierbare Identität.'**
  String get qrNoVerifiableIdentity;

  /// No description provided for @qrSectionLightning.
  ///
  /// In de, this message translates to:
  /// **'LIGHTNING'**
  String get qrSectionLightning;

  /// No description provided for @qrSectionSocial.
  ///
  /// In de, this message translates to:
  /// **'SOZIALES NETZWERK'**
  String get qrSectionSocial;

  /// No description provided for @qrSectionPlatforms.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFTE PLATTFORMEN'**
  String get qrSectionPlatforms;

  /// No description provided for @qrSectionMeetups.
  ///
  /// In de, this message translates to:
  /// **'BESUCHTE MEETUPS'**
  String get qrSectionMeetups;

  /// No description provided for @qrHumanVerified.
  ///
  /// In de, this message translates to:
  /// **'Mensch verifiziert'**
  String get qrHumanVerified;

  /// No description provided for @qrLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get qrLightningActive;

  /// No description provided for @qrNoLightning.
  ///
  /// In de, this message translates to:
  /// **'Kein Lightning-Beweis gefunden'**
  String get qrNoLightning;

  /// No description provided for @qrNoZap.
  ///
  /// In de, this message translates to:
  /// **'Keine Zap-Aktivität'**
  String get qrNoZap;

  /// No description provided for @qrNip05Invalid.
  ///
  /// In de, this message translates to:
  /// **'NIP-05 ungültig'**
  String get qrNip05Invalid;

  /// No description provided for @qrYouFollow.
  ///
  /// In de, this message translates to:
  /// **'Du folgst'**
  String get qrYouFollow;

  /// No description provided for @qrFollowsYou.
  ///
  /// In de, this message translates to:
  /// **'Folgt dir'**
  String get qrFollowsYou;

  /// No description provided for @qrMutualFollow.
  ///
  /// In de, this message translates to:
  /// **'Gegenseitiger Follow'**
  String get qrMutualFollow;

  /// No description provided for @qrNoDirectFollow.
  ///
  /// In de, this message translates to:
  /// **'Kein direkter Follow'**
  String get qrNoDirectFollow;

  /// No description provided for @qrDirectConnection.
  ///
  /// In de, this message translates to:
  /// **'Direkte Verbindung'**
  String get qrDirectConnection;

  /// No description provided for @qrBidirectional.
  ///
  /// In de, this message translates to:
  /// **'Direkte bidirektionale Verbindung'**
  String get qrBidirectional;

  /// No description provided for @qrOneWay.
  ///
  /// In de, this message translates to:
  /// **'Einseitige Verbindung'**
  String get qrOneWay;

  /// No description provided for @qrViaContacts.
  ///
  /// In de, this message translates to:
  /// **'Über gemeinsame Kontakte'**
  String get qrViaContacts;

  /// No description provided for @qrStrongOverlap.
  ///
  /// In de, this message translates to:
  /// **'Starke Netzwerk-Überlappung'**
  String get qrStrongOverlap;

  /// No description provided for @qrPartiallyConnected.
  ///
  /// In de, this message translates to:
  /// **'Teilweise verbunden'**
  String get qrPartiallyConnected;

  /// No description provided for @qrNoOverlap.
  ///
  /// In de, this message translates to:
  /// **'Keine Überlappung'**
  String get qrNoOverlap;

  /// No description provided for @qrEndorsement.
  ///
  /// In de, this message translates to:
  /// **'Endorsement von bekannten Admins'**
  String get qrEndorsement;

  /// No description provided for @qrSigVerified.
  ///
  /// In de, this message translates to:
  /// **'Signatur verifiziert'**
  String get qrSigVerified;

  /// No description provided for @qrAnalyzingNetwork.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Netzwerk...'**
  String get qrAnalyzingNetwork;

  /// No description provided for @qrCheckingLightning.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Lightning...'**
  String get qrCheckingLightning;

  /// No description provided for @qrCheckingNip05.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NIP-05...'**
  String get qrCheckingNip05;

  /// No description provided for @qrStatBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get qrStatBadges;

  /// No description provided for @qrStatMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get qrStatMeetups;

  /// No description provided for @qrStatSigners.
  ///
  /// In de, this message translates to:
  /// **'Signer'**
  String get qrStatSigners;

  /// No description provided for @qrStatBound.
  ///
  /// In de, this message translates to:
  /// **'Gebunden'**
  String get qrStatBound;

  /// No description provided for @qrStatDays.
  ///
  /// In de, this message translates to:
  /// **'Tage'**
  String get qrStatDays;

  /// No description provided for @qrLabelNickname.
  ///
  /// In de, this message translates to:
  /// **'Nickname'**
  String get qrLabelNickname;

  /// No description provided for @qrLabelTwitter.
  ///
  /// In de, this message translates to:
  /// **'Twitter/X'**
  String get qrLabelTwitter;

  /// No description provided for @qrPlatformOther.
  ///
  /// In de, this message translates to:
  /// **'Andere'**
  String get qrPlatformOther;

  /// No description provided for @qrLinked.
  ///
  /// In de, this message translates to:
  /// **'Verknüpft'**
  String get qrLinked;

  /// No description provided for @qrSigVerifiedShort.
  ///
  /// In de, this message translates to:
  /// **'Signatur verifiziert'**
  String get qrSigVerifiedShort;

  /// No description provided for @qrLinkedShort.
  ///
  /// In de, this message translates to:
  /// **'Verknüpft'**
  String get qrLinkedShort;

  /// No description provided for @nfcDisabled.
  ///
  /// In de, this message translates to:
  /// **'NFC ist deaktiviert'**
  String get nfcDisabled;

  /// No description provided for @nfcDisabledHint.
  ///
  /// In de, this message translates to:
  /// **'NFC ist deaktiviert. Bitte einschalten.'**
  String get nfcDisabledHint;

  /// No description provided for @nfcUnavailable.
  ///
  /// In de, this message translates to:
  /// **'NFC nicht verfügbar'**
  String get nfcUnavailable;

  /// No description provided for @nfcOpenSettings.
  ///
  /// In de, this message translates to:
  /// **'EINSTELLUNGEN ÖFFNEN'**
  String get nfcOpenSettings;

  /// No description provided for @nfcEnableHint.
  ///
  /// In de, this message translates to:
  /// **'Bitte aktiviere NFC in deinen Geräteeinstellungen, '**
  String get nfcEnableHint;

  /// No description provided for @nfcSettingsAndroid.
  ///
  /// In de, this message translates to:
  /// **'Android: Einstellungen → Verbindungen → NFC'**
  String get nfcSettingsAndroid;

  /// No description provided for @nfcSettingsIos.
  ///
  /// In de, this message translates to:
  /// **'iOS: Einstellungen → NFC'**
  String get nfcSettingsIos;

  /// No description provided for @verifyScanBadge.
  ///
  /// In de, this message translates to:
  /// **'BADGE SCANNEN'**
  String get verifyScanBadge;

  /// No description provided for @verifyScanNfc.
  ///
  /// In de, this message translates to:
  /// **'NFC TAG SCANNEN'**
  String get verifyScanNfc;

  /// No description provided for @verifyScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR SCANNEN'**
  String get verifyScanQr;

  /// No description provided for @verifyScanQrCaps.
  ///
  /// In de, this message translates to:
  /// **'QR-CODE SCANNEN'**
  String get verifyScanQrCaps;

  /// No description provided for @verifyReadyToScan.
  ///
  /// In de, this message translates to:
  /// **'Bereit zum Scannen'**
  String get verifyReadyToScan;

  /// No description provided for @verifyWaitingNfc.
  ///
  /// In de, this message translates to:
  /// **'Warte auf NFC Tag...'**
  String get verifyWaitingNfc;

  /// No description provided for @verifyCheckingNfc.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NFC...'**
  String get verifyCheckingNfc;

  /// No description provided for @verifyScanInstruction.
  ///
  /// In de, this message translates to:
  /// **'Scanne den QR-Code\ndes Meetup-Organisators.'**
  String get verifyScanInstruction;

  /// No description provided for @verifyScanQrInstruction.
  ///
  /// In de, this message translates to:
  /// **'Scanne den QR-Code\ndes Meetup-Organisators'**
  String get verifyScanQrInstruction;

  /// No description provided for @verifyNoNfcDevice.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät hat kein NFC. Nutze den QR-Scanner.'**
  String get verifyNoNfcDevice;

  /// No description provided for @verifyNoNfcLong.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät unterstützt kein NFC.\n\n'**
  String get verifyNoNfcLong;

  /// No description provided for @verifyUseQrInstead.
  ///
  /// In de, this message translates to:
  /// **'Nutze stattdessen den QR-Code-Scanner, '**
  String get verifyUseQrInstead;

  /// No description provided for @verifyToGetBadge.
  ///
  /// In de, this message translates to:
  /// **'um dein Badge zu erhalten.'**
  String get verifyToGetBadge;

  /// No description provided for @verifyAskScan.
  ///
  /// In de, this message translates to:
  /// **'Bitte lass einen Teilnehmer deinen Tag scannen.'**
  String get verifyAskScan;

  /// No description provided for @verifyCantSelfBadge.
  ///
  /// In de, this message translates to:
  /// **'Du kannst dir nicht selbst ein Badge geben.\n'**
  String get verifyCantSelfBadge;

  /// No description provided for @verifyBadgeFound.
  ///
  /// In de, this message translates to:
  /// **'BADGE GEFUNDEN'**
  String get verifyBadgeFound;

  /// No description provided for @verifyAlreadyCollected.
  ///
  /// In de, this message translates to:
  /// **'BEREITS GESAMMELT'**
  String get verifyAlreadyCollected;

  /// No description provided for @verifyAddToWallet.
  ///
  /// In de, this message translates to:
  /// **'ZUR WALLET HINZUFÜGEN'**
  String get verifyAddToWallet;

  /// No description provided for @verifyVerifiedAdmin.
  ///
  /// In de, this message translates to:
  /// **'Verifizierter Admin'**
  String get verifyVerifiedAdmin;

  /// No description provided for @verifyUnknownMeetup.
  ///
  /// In de, this message translates to:
  /// **'Unbekanntes Meetup'**
  String get verifyUnknownMeetup;

  /// No description provided for @verifyNoExpiry.
  ///
  /// In de, this message translates to:
  /// **'Kein Ablauf'**
  String get verifyNoExpiry;

  /// No description provided for @writerReadyToWrite.
  ///
  /// In de, this message translates to:
  /// **'Bereit zum Schreiben'**
  String get writerReadyToWrite;

  /// No description provided for @writerNoNfcDevice.
  ///
  /// In de, this message translates to:
  /// **'Dieses Gerät hat kein NFC. Nutze Rolling QR-Codes.'**
  String get writerNoNfcDevice;

  /// No description provided for @writerUseRollingQr.
  ///
  /// In de, this message translates to:
  /// **'Du kannst stattdessen Rolling QR-Codes '**
  String get writerUseRollingQr;

  /// No description provided for @writerForYourMeetup.
  ///
  /// In de, this message translates to:
  /// **'für dein Meetup verwenden.'**
  String get writerForYourMeetup;

  /// No description provided for @writerSelectHomeFirst.
  ///
  /// In de, this message translates to:
  /// **'Bitte erst ein Home-Meetup im Profil auswählen'**
  String get writerSelectHomeFirst;

  /// No description provided for @writerYourHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'DEIN HOME-MEETUP'**
  String get writerYourHomeMeetup;

  /// No description provided for @writerCreateTag.
  ///
  /// In de, this message translates to:
  /// **'TAG ERSTELLEN'**
  String get writerCreateTag;

  /// No description provided for @writerCreateMeetupTag.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TAG ERSTELLEN'**
  String get writerCreateMeetupTag;

  /// No description provided for @writerMeetupTag.
  ///
  /// In de, this message translates to:
  /// **'MEETUP TAG'**
  String get writerMeetupTag;

  /// No description provided for @writerSuccess.
  ///
  /// In de, this message translates to:
  /// **'ERFOLG!'**
  String get writerSuccess;

  /// No description provided for @writerValidHours.
  ///
  /// In de, this message translates to:
  /// **'⏱️ Gültig für {hours}h\n\n'**
  String writerValidHours(Object hours);

  /// No description provided for @writerHoldTag.
  ///
  /// In de, this message translates to:
  /// **'Halte Tag an das Gerät...'**
  String get writerHoldTag;

  /// No description provided for @writerHoldTagInstruction.
  ///
  /// In de, this message translates to:
  /// **'Halte einen NFC Tag an das Gerät.\nTeilnehmer scannen diesen Tag um ein Badge zu sammeln.'**
  String get writerHoldTagInstruction;

  /// No description provided for @writerFormatting.
  ///
  /// In de, this message translates to:
  /// **'Formatiere leeren Tag...'**
  String get writerFormatting;

  /// No description provided for @writerFormatFailed.
  ///
  /// In de, this message translates to:
  /// **'Formatierung fehlgeschlagen'**
  String get writerFormatFailed;

  /// No description provided for @writerLoadingSession.
  ///
  /// In de, this message translates to:
  /// **'Lade Session-Daten...'**
  String get writerLoadingSession;

  /// No description provided for @writerJumpToQr.
  ///
  /// In de, this message translates to:
  /// **'Springe zum QR-Code...'**
  String get writerJumpToQr;

  /// No description provided for @writerNoNdef.
  ///
  /// In de, this message translates to:
  /// **'Kein NDEF Format möglich'**
  String get writerNoNdef;

  /// No description provided for @writerTagReadOnly.
  ///
  /// In de, this message translates to:
  /// **'Tag ist schreibgeschützt'**
  String get writerTagReadOnly;

  /// No description provided for @writerCanOverwrite.
  ///
  /// In de, this message translates to:
  /// **'Tag kann danach überschrieben werden'**
  String get writerCanOverwrite;

  /// No description provided for @writerTagLost.
  ///
  /// In de, this message translates to:
  /// **'Tag verloren während dem Schreiben'**
  String get writerTagLost;

  /// No description provided for @writerTagRemovedEarly.
  ///
  /// In de, this message translates to:
  /// **'Tag zu früh entfernt — halte ihn ruhig 2–3 Sekunden ans Gerät'**
  String get writerTagRemovedEarly;

  /// No description provided for @writerUseNtag215.
  ///
  /// In de, this message translates to:
  /// **'Verwende einen NTAG215 (504B) oder größer.'**
  String get writerUseNtag215;

  /// No description provided for @writerToWriteTag.
  ///
  /// In de, this message translates to:
  /// **'um den Tag zu beschreiben.\n\n'**
  String get writerToWriteTag;

  /// No description provided for @verifyMsgLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort: {name}'**
  String verifyMsgLocation(String name);

  /// No description provided for @verifyMsgBlock.
  ///
  /// In de, this message translates to:
  /// **'Block: {height}'**
  String verifyMsgBlock(Object height);

  /// No description provided for @verifyMsgSignedBy.
  ///
  /// In de, this message translates to:
  /// **'Signiert von: {signer}'**
  String verifyMsgSignedBy(String signer);

  /// No description provided for @verifyMsgProof.
  ///
  /// In de, this message translates to:
  /// **'Beweis: Schnorr (BIP-340)'**
  String get verifyMsgProof;

  /// No description provided for @verifyMsgTagExpiry.
  ///
  /// In de, this message translates to:
  /// **'Tag-Ablauf: {expiry}'**
  String verifyMsgTagExpiry(String expiry);

  /// No description provided for @verifyAlreadyToday.
  ///
  /// In de, this message translates to:
  /// **'Bereits gesammelt\n\nHeute hast du bereits ein Badge von:\n{name}'**
  String verifyAlreadyToday(String name);

  /// No description provided for @wotErrorShort.
  ///
  /// In de, this message translates to:
  /// **'Fehler: {msg}'**
  String wotErrorShort(String msg);

  /// No description provided for @writerTagTooSmall.
  ///
  /// In de, this message translates to:
  /// **'Tag zu klein! Daten: {data}B, Tag: {max}B.\n'**
  String writerTagTooSmall(Object data, Object max);

  /// No description provided for @writerTagWritten.
  ///
  /// In de, this message translates to:
  /// **'✅ MEETUP TAG geschrieben!\n\n'**
  String get writerTagWritten;

  /// No description provided for @writerCompactSize.
  ///
  /// In de, this message translates to:
  /// **'📦 {size}B (kompakt)\n'**
  String writerCompactSize(Object size);

  /// No description provided for @verifyErrNoNdef.
  ///
  /// In de, this message translates to:
  /// **'✗ Kein NDEF Tag'**
  String get verifyErrNoNdef;

  /// No description provided for @verifyErrTagEmpty.
  ///
  /// In de, this message translates to:
  /// **'✗ Tag ist leer'**
  String get verifyErrTagEmpty;

  /// No description provided for @verifyErrPayloadEmpty.
  ///
  /// In de, this message translates to:
  /// **'✗ Payload leer'**
  String get verifyErrPayloadEmpty;

  /// No description provided for @verifyErrInvalidFormat.
  ///
  /// In de, this message translates to:
  /// **'✗ Ungültiges Format'**
  String get verifyErrInvalidFormat;

  /// No description provided for @verifyErrInvalidTag.
  ///
  /// In de, this message translates to:
  /// **'✗ Ungültiger Tag: {msg}'**
  String verifyErrInvalidTag(String msg);

  /// No description provided for @verifyErrReadError.
  ///
  /// In de, this message translates to:
  /// **'✗ Lesefehler: {msg}'**
  String verifyErrReadError(String msg);

  /// No description provided for @verifyErrNfcError.
  ///
  /// In de, this message translates to:
  /// **'✗ NFC Fehler: {msg}'**
  String verifyErrNfcError(String msg);

  /// No description provided for @verifyErrQrExpired.
  ///
  /// In de, this message translates to:
  /// **'✗ QR-Code abgelaufen!\n{msg}\n\nBitte direkt am Bildschirm des Organisators scannen.'**
  String verifyErrQrExpired(String msg);

  /// No description provided for @verifyErrPrefix.
  ///
  /// In de, this message translates to:
  /// **'✗ {msg}'**
  String verifyErrPrefix(String msg);

  /// No description provided for @writerStartError.
  ///
  /// In de, this message translates to:
  /// **'❌ Start Fehler: {msg}'**
  String writerStartError(String msg);

  /// No description provided for @writerFitsNtag215.
  ///
  /// In de, this message translates to:
  /// **'~{size}B — passt auf NTAG215 (492B)'**
  String writerFitsNtag215(Object size);

  /// No description provided for @writerNoHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Kein Home-Meetup gesetzt'**
  String get writerNoHomeMeetup;

  /// No description provided for @writerHomeMeetupNotFound.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Home-Meetup nicht gefunden'**
  String get writerHomeMeetupNotFound;

  /// No description provided for @writerNoActiveSession.
  ///
  /// In de, this message translates to:
  /// **'❌ Keine aktive Meetup-Session gefunden. Bitte starte das Meetup neu.'**
  String get writerNoActiveSession;

  /// No description provided for @apMeetupSession.
  ///
  /// In de, this message translates to:
  /// **'MEETUP SESSION'**
  String get apMeetupSession;

  /// No description provided for @apSessionRunning.
  ///
  /// In de, this message translates to:
  /// **'SESSION LÄUFT'**
  String get apSessionRunning;

  /// No description provided for @apOpenActiveMeetup.
  ///
  /// In de, this message translates to:
  /// **'AKTIVES MEETUP ÖFFNEN'**
  String get apOpenActiveMeetup;

  /// No description provided for @apStartMeetup.
  ///
  /// In de, this message translates to:
  /// **'MEETUP STARTEN'**
  String get apStartMeetup;

  /// No description provided for @apEndMeetupEarly.
  ///
  /// In de, this message translates to:
  /// **'Meetup vorzeitig beenden'**
  String get apEndMeetupEarly;

  /// No description provided for @apOrganizer.
  ///
  /// In de, this message translates to:
  /// **'ORGANISATOR'**
  String get apOrganizer;

  /// No description provided for @apHowItWorks.
  ///
  /// In de, this message translates to:
  /// **'SO FUNKTIONIERT\'S'**
  String get apHowItWorks;

  /// No description provided for @apNewMeetupQ.
  ///
  /// In de, this message translates to:
  /// **'Neues Meetup starten?'**
  String get apNewMeetupQ;

  /// No description provided for @apSessionEndQ.
  ///
  /// In de, this message translates to:
  /// **'Session beenden?'**
  String get apSessionEndQ;

  /// No description provided for @apCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get apCancel;

  /// No description provided for @apStart.
  ///
  /// In de, this message translates to:
  /// **'Starten'**
  String get apStart;

  /// No description provided for @apEnd.
  ///
  /// In de, this message translates to:
  /// **'Beenden'**
  String get apEnd;

  /// No description provided for @apSeedAdmin.
  ///
  /// In de, this message translates to:
  /// **'Seed Admin'**
  String get apSeedAdmin;

  /// No description provided for @apViaTrustScore.
  ///
  /// In de, this message translates to:
  /// **'Via Trust Score'**
  String get apViaTrustScore;

  /// No description provided for @apNewMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Dies erstellt eine eindeutige Signatur (Blockzeit) für die nächsten 4 Stunden. In dieser Zeit ist die Erstellung neuer Sessions gesperrt.'**
  String get apNewMeetupBody;

  /// No description provided for @apSessionEndBody.
  ///
  /// In de, this message translates to:
  /// **'Damit sperrst du die aktuelle Blockzeit. Du kannst danach eine neue Session starten.'**
  String get apSessionEndBody;

  /// No description provided for @apGeneratesProof.
  ///
  /// In de, this message translates to:
  /// **'Generiert einen neuen kryptographischen Beweis für die nächsten 4 Stunden.'**
  String get apGeneratesProof;

  /// No description provided for @humTitle.
  ///
  /// In de, this message translates to:
  /// **'PROOF OF HUMANITY'**
  String get humTitle;

  /// No description provided for @humVerified.
  ///
  /// In de, this message translates to:
  /// **'MENSCH VERIFIZIERT'**
  String get humVerified;

  /// No description provided for @humNotVerified.
  ///
  /// In de, this message translates to:
  /// **'NICHT VERIFIZIERT'**
  String get humNotVerified;

  /// No description provided for @humVerifiedSub.
  ///
  /// In de, this message translates to:
  /// **'Du bist als Mensch verifiziert'**
  String get humVerifiedSub;

  /// No description provided for @humLightningActive.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis aktiv'**
  String get humLightningActive;

  /// No description provided for @humCheckNow.
  ///
  /// In de, this message translates to:
  /// **'JETZT PRÜFEN'**
  String get humCheckNow;

  /// No description provided for @humCheckAgain.
  ///
  /// In de, this message translates to:
  /// **'ERNEUT PRÜFEN'**
  String get humCheckAgain;

  /// No description provided for @humCheckAgainShort.
  ///
  /// In de, this message translates to:
  /// **'Erneut prüfen'**
  String get humCheckAgainShort;

  /// No description provided for @humSearchingRelays.
  ///
  /// In de, this message translates to:
  /// **'SUCHE AUF RELAYS...'**
  String get humSearchingRelays;

  /// No description provided for @humHowTitle.
  ///
  /// In de, this message translates to:
  /// **'WIE FUNKTIONIERT DAS?'**
  String get humHowTitle;

  /// No description provided for @humIntro1.
  ///
  /// In de, this message translates to:
  /// **'Beweise, dass du ein Mensch bist — indem du nachweist, '**
  String get humIntro1;

  /// No description provided for @humIntro2.
  ///
  /// In de, this message translates to:
  /// **'dass du eine echte Lightning-Wallet besitzt und '**
  String get humIntro2;

  /// No description provided for @humIntro3.
  ///
  /// In de, this message translates to:
  /// **'schon einmal jemanden auf Nostr gezappt hast.'**
  String get humIntro3;

  /// No description provided for @humExplain1.
  ///
  /// In de, this message translates to:
  /// **'Bots haben keine Lightning-Wallets. Eine einzige echte '**
  String get humExplain1;

  /// No description provided for @humExplain2.
  ///
  /// In de, this message translates to:
  /// **'Zahlung beweist, dass du ein Mensch mit einer echten '**
  String get humExplain2;

  /// No description provided for @humExplain3.
  ///
  /// In de, this message translates to:
  /// **'Wallet bist — ohne persönliche Daten preiszugeben.'**
  String get humExplain3;

  /// No description provided for @humStep1.
  ///
  /// In de, this message translates to:
  /// **'Du zappst irgendjemanden auf Nostr'**
  String get humStep1;

  /// No description provided for @humStep2.
  ///
  /// In de, this message translates to:
  /// **'Der Zap erzeugt ein Receipt auf Relays'**
  String get humStep2;

  /// No description provided for @humStep3.
  ///
  /// In de, this message translates to:
  /// **'Die App findet dein Receipt'**
  String get humStep3;

  /// No description provided for @humStepInstruction.
  ///
  /// In de, this message translates to:
  /// **'Egal wen, egal wieviel Sats. Nutze dafür einen Nostr-Client wie Damus, Amethyst oder Primal.'**
  String get humStepInstruction;

  /// No description provided for @humCheckInstruction.
  ///
  /// In de, this message translates to:
  /// **'Drücke den Prüfen-Button und die App sucht auf Nostr-Relays nach deinem Zap.'**
  String get humCheckInstruction;

  /// No description provided for @humZapReturn.
  ///
  /// In de, this message translates to:
  /// **'Zappe irgendjemanden und komm zurück'**
  String get humZapReturn;

  /// No description provided for @humCryptoProof.
  ///
  /// In de, this message translates to:
  /// **'Das ist ein kryptographischer Beweis, dass du eine echte Lightning-Zahlung geleistet hast.'**
  String get humCryptoProof;

  /// No description provided for @humProofInEvent1.
  ///
  /// In de, this message translates to:
  /// **'auf dem Nostr-Netzwerk geleistet. Dieser Beweis ist in deinem '**
  String get humProofInEvent1;

  /// No description provided for @humProofPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Der Beweis wird in dein Reputation-Event aufgenommen. Kein Betrag oder Empfänger wird gespeichert.'**
  String get humProofPrivacy;

  /// No description provided for @humReputationSaved.
  ///
  /// In de, this message translates to:
  /// **'Reputation-Event gespeichert.'**
  String get humReputationSaved;

  /// No description provided for @humPaidOn.
  ///
  /// In de, this message translates to:
  /// **'Du hast am {date} eine Lightning-Zahlung '**
  String humPaidOn(String date);

  /// No description provided for @humLastCheck.
  ///
  /// In de, this message translates to:
  /// **'Letzte Prüfung: {time}'**
  String humLastCheck(String time);

  /// No description provided for @ppTitle.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM-VERKNÜPFUNG'**
  String get ppTitle;

  /// No description provided for @ppPlatform.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM'**
  String get ppPlatform;

  /// No description provided for @ppUsername.
  ///
  /// In de, this message translates to:
  /// **'BENUTZERNAME'**
  String get ppUsername;

  /// No description provided for @ppActiveLinks.
  ///
  /// In de, this message translates to:
  /// **'AKTIVE VERKNÜPFUNGEN'**
  String get ppActiveLinks;

  /// No description provided for @ppLinkPlatform.
  ///
  /// In de, this message translates to:
  /// **'PLATTFORM VERKNÜPFEN'**
  String get ppLinkPlatform;

  /// No description provided for @ppCreateLink.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFUNG ERSTELLEN'**
  String get ppCreateLink;

  /// No description provided for @ppAnotherPlatform.
  ///
  /// In de, this message translates to:
  /// **'WEITERE PLATTFORM'**
  String get ppAnotherPlatform;

  /// No description provided for @ppShareOnPlatform.
  ///
  /// In de, this message translates to:
  /// **'AUF PLATTFORM TEILEN'**
  String get ppShareOnPlatform;

  /// No description provided for @ppUnlinkQ.
  ///
  /// In de, this message translates to:
  /// **'VERKNÜPFUNG AUFHEBEN?'**
  String get ppUnlinkQ;

  /// No description provided for @ppRevoke.
  ///
  /// In de, this message translates to:
  /// **'WIDERRUFEN'**
  String get ppRevoke;

  /// No description provided for @ppCancel.
  ///
  /// In de, this message translates to:
  /// **'ABBRECHEN'**
  String get ppCancel;

  /// No description provided for @ppYourUsername.
  ///
  /// In de, this message translates to:
  /// **'Dein Benutzername'**
  String get ppYourUsername;

  /// No description provided for @ppPlatformName.
  ///
  /// In de, this message translates to:
  /// **'Name der Plattform'**
  String get ppPlatformName;

  /// No description provided for @ppIntro.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfe deinen Account mit einer Plattform. Der Beweis wird automatisch in deinen Reputation-QR eingebettet.'**
  String get ppIntro;

  /// No description provided for @ppLinkSaved.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfung gespeichert! Wird automatisch in deinen Reputation-QR eingebettet.'**
  String get ppLinkSaved;

  /// No description provided for @ppMustUpdate.
  ///
  /// In de, this message translates to:
  /// **'Du musst dein Reputation-Event danach aktualisieren.'**
  String get ppMustUpdate;

  /// No description provided for @ppUnlinkBody1.
  ///
  /// In de, this message translates to:
  /// **'Die Plattform-Verknüpfung für \"'**
  String get ppUnlinkBody1;

  /// No description provided for @ppUnlinkBody2.
  ///
  /// In de, this message translates to:
  /// **'wird gelöscht.\n\n'**
  String get ppUnlinkBody2;

  /// No description provided for @ppUnlinkBody.
  ///
  /// In de, this message translates to:
  /// **'Die Plattform-Verknüpfung für \"{username}\" auf {platform} wird gelöscht.\n\nDu musst dein Reputation-Event danach aktualisieren.'**
  String ppUnlinkBody(String username, String platform);

  /// No description provided for @ppCreated.
  ///
  /// In de, this message translates to:
  /// **'Erstellt: {date}'**
  String ppCreated(String date);

  /// No description provided for @ppRevokeTooltip.
  ///
  /// In de, this message translates to:
  /// **'Widerrufen'**
  String get ppRevokeTooltip;

  /// No description provided for @rqTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUP QR-CODE'**
  String get rqTitle;

  /// No description provided for @rqActive.
  ///
  /// In de, this message translates to:
  /// **'AKTIV'**
  String get rqActive;

  /// No description provided for @rqCodeRenewing.
  ///
  /// In de, this message translates to:
  /// **'Code erneuert sich...'**
  String get rqCodeRenewing;

  /// No description provided for @rqNextCodeIn.
  ///
  /// In de, this message translates to:
  /// **'Nächster Code in'**
  String get rqNextCodeIn;

  /// No description provided for @rqEndSession.
  ///
  /// In de, this message translates to:
  /// **'Session beenden'**
  String get rqEndSession;

  /// No description provided for @rqEndSessionQ.
  ///
  /// In de, this message translates to:
  /// **'Session beenden?'**
  String get rqEndSessionQ;

  /// No description provided for @rqEnd.
  ///
  /// In de, this message translates to:
  /// **'BEENDEN'**
  String get rqEnd;

  /// No description provided for @rqEndSessionBody.
  ///
  /// In de, this message translates to:
  /// **'Eine beendete Session sperrt diese Blockzeit. Du kannst danach eine neue Session starten.'**
  String get rqEndSessionBody;

  /// No description provided for @rqNoActiveSession.
  ///
  /// In de, this message translates to:
  /// **'KEINE AKTIVE SESSION'**
  String get rqNoActiveSession;

  /// No description provided for @rqNoSessionBody.
  ///
  /// In de, this message translates to:
  /// **'Es läuft aktuell keine Meetup-Session.\nBitte starte das Meetup im Admin Panel neu.'**
  String get rqNoSessionBody;

  /// No description provided for @rqBackToAdmin.
  ///
  /// In de, this message translates to:
  /// **'ZURÜCK ZUM ADMIN PANEL'**
  String get rqBackToAdmin;

  /// No description provided for @rsTitle.
  ///
  /// In de, this message translates to:
  /// **'NOSTR-RELAYS'**
  String get rsTitle;

  /// No description provided for @rsDefaultRelays.
  ///
  /// In de, this message translates to:
  /// **'DEFAULT-RELAYS'**
  String get rsDefaultRelays;

  /// No description provided for @rsCustomRelays.
  ///
  /// In de, this message translates to:
  /// **'EIGENE RELAYS'**
  String get rsCustomRelays;

  /// No description provided for @rsAddRelay.
  ///
  /// In de, this message translates to:
  /// **'RELAY HINZUFÜGEN'**
  String get rsAddRelay;

  /// No description provided for @rsAdd.
  ///
  /// In de, this message translates to:
  /// **'HINZUFÜGEN'**
  String get rsAdd;

  /// No description provided for @rsNoRelaysActive.
  ///
  /// In de, this message translates to:
  /// **'Keine Relays aktiv!'**
  String get rsNoRelaysActive;

  /// No description provided for @rsNoCustomRelays.
  ///
  /// In de, this message translates to:
  /// **'Keine eigenen Relays konfiguriert.'**
  String get rsNoCustomRelays;

  /// No description provided for @rsAllRelaysInfo.
  ///
  /// In de, this message translates to:
  /// **'Die App nutzt alle aktiven Relays gleichzeitig für maximale Erreichbarkeit.'**
  String get rsAllRelaysInfo;

  /// No description provided for @rsRelaysIntro.
  ///
  /// In de, this message translates to:
  /// **'Relays verteilen deine Reputation im Nostr-Netzwerk. '**
  String get rsRelaysIntro;

  /// No description provided for @rsRelayPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'wss://mein-relay.de'**
  String get rsRelayPlaceholder;

  /// No description provided for @rdScanAdminTag.
  ///
  /// In de, this message translates to:
  /// **'ADMIN TAG SCANNEN'**
  String get rdScanAdminTag;

  /// No description provided for @rdAnon.
  ///
  /// In de, this message translates to:
  /// **'ANON'**
  String get rdAnon;

  /// No description provided for @rdCollectBadge.
  ///
  /// In de, this message translates to:
  /// **'BADGE ABHOLEN'**
  String get rdCollectBadge;

  /// No description provided for @rdYourReputation.
  ///
  /// In de, this message translates to:
  /// **'DEINE REPUTATION'**
  String get rdYourReputation;

  /// No description provided for @rdEditIdentity.
  ///
  /// In de, this message translates to:
  /// **'Identität bearbeiten'**
  String get rdEditIdentity;

  /// No description provided for @rdLinkingIdentity.
  ///
  /// In de, this message translates to:
  /// **'Identität verknüpfen...'**
  String get rdLinkingIdentity;

  /// No description provided for @rdNostrVerified.
  ///
  /// In de, this message translates to:
  /// **'NOSTR VERIFIED'**
  String get rdNostrVerified;

  /// No description provided for @rdNoBadges.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Badges gesammelt.\nGeh zu einem Meetup!'**
  String get rdNoBadges;

  /// No description provided for @rdSelfSovereign.
  ///
  /// In de, this message translates to:
  /// **'Self-Sovereign: Diese App läuft ohne Server. Deine Badges gehören nur dir und sind auf diesem Gerät gespeichert.'**
  String get rdSelfSovereign;

  /// No description provided for @rdVerifiedByAdmin.
  ///
  /// In de, this message translates to:
  /// **'VERIFIZIERT DURCH ADMIN'**
  String get rdVerifiedByAdmin;

  /// No description provided for @rqRemainingTime.
  ///
  /// In de, this message translates to:
  /// **'Restzeit: {time}\n\n'**
  String rqRemainingTime(String time);

  /// No description provided for @rqSessionRemaining.
  ///
  /// In de, this message translates to:
  /// **'Session: {time}'**
  String rqSessionRemaining(String time);

  /// No description provided for @rvTitle.
  ///
  /// In de, this message translates to:
  /// **'REPUTATION PRÜFEN'**
  String get rvTitle;

  /// No description provided for @rvChecking.
  ///
  /// In de, this message translates to:
  /// **'PRÜFE...'**
  String get rvChecking;

  /// No description provided for @rvFullyVerified.
  ///
  /// In de, this message translates to:
  /// **'VOLLSTÄNDIG VERIFIZIERT'**
  String get rvFullyVerified;

  /// No description provided for @rvPartiallyVerified.
  ///
  /// In de, this message translates to:
  /// **'TEILWEISE VERIFIZIERT'**
  String get rvPartiallyVerified;

  /// No description provided for @rvSignatureOnly.
  ///
  /// In de, this message translates to:
  /// **'NUR SIGNATUR GEPRÜFT'**
  String get rvSignatureOnly;

  /// No description provided for @rvInvalid.
  ///
  /// In de, this message translates to:
  /// **'UNGÜLTIG'**
  String get rvInvalid;

  /// No description provided for @rvConfirmedInEvent.
  ///
  /// In de, this message translates to:
  /// **'Im Event bestätigt'**
  String get rvConfirmedInEvent;

  /// No description provided for @rvPlatformProof.
  ///
  /// In de, this message translates to:
  /// **'Plattform-Proof'**
  String get rvPlatformProof;

  /// No description provided for @rvIntro1.
  ///
  /// In de, this message translates to:
  /// **'Füge den Verify-String oder npub einer Person ein, '**
  String get rvIntro1;

  /// No description provided for @rvIntro2.
  ///
  /// In de, this message translates to:
  /// **'um ihre Reputation über alle Beweis-Layer zu prüfen.'**
  String get rvIntro2;

  /// No description provided for @rvCheckingSignature.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Signatur...'**
  String get rvCheckingSignature;

  /// No description provided for @rvCheckingNostr.
  ///
  /// In de, this message translates to:
  /// **'Analysiere Nostr-Netzwerk...'**
  String get rvCheckingNostr;

  /// No description provided for @rvCheckingLightning.
  ///
  /// In de, this message translates to:
  /// **'Prüfe Lightning-Aktivität...'**
  String get rvCheckingLightning;

  /// No description provided for @rvCheckingNip05.
  ///
  /// In de, this message translates to:
  /// **'Prüfe NIP-05...'**
  String get rvCheckingNip05;

  /// No description provided for @msSelectMeetup.
  ///
  /// In de, this message translates to:
  /// **'MEETUP AUSWÄHLEN'**
  String get msSelectMeetup;

  /// No description provided for @msSearchMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup suchen...'**
  String get msSearchMeetup;

  /// No description provided for @mlTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUPS'**
  String get mlTitle;

  /// No description provided for @mlRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get mlRetry;

  /// No description provided for @mlLoadError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Laden'**
  String get mlLoadError;

  /// No description provided for @mlNoMeetupsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups gefunden.'**
  String get mlNoMeetupsFound;

  /// No description provided for @mlNoMeetupFor.
  ///
  /// In de, this message translates to:
  /// **'Kein Meetup für \"{query}\"'**
  String mlNoMeetupFor(String query);

  /// No description provided for @cmRequestSent.
  ///
  /// In de, this message translates to:
  /// **'ANFRAGE GESENDET 🚀'**
  String get cmRequestSent;

  /// No description provided for @cmDateTime.
  ///
  /// In de, this message translates to:
  /// **'DATUM & UHRZEIT'**
  String get cmDateTime;

  /// No description provided for @cmFoundBase.
  ///
  /// In de, this message translates to:
  /// **'GRÜNDE EINE BASIS.'**
  String get cmFoundBase;

  /// No description provided for @cmLocation.
  ///
  /// In de, this message translates to:
  /// **'LOCATION / ORT'**
  String get cmLocation;

  /// No description provided for @cmCityName.
  ///
  /// In de, this message translates to:
  /// **'NAME DER STADT'**
  String get cmCityName;

  /// No description provided for @cmTelegramGroup.
  ///
  /// In de, this message translates to:
  /// **'TELEGRAM GRUPPE (OPTIONAL)'**
  String get cmTelegramGroup;

  /// No description provided for @cmNewMeetup.
  ///
  /// In de, this message translates to:
  /// **'NEUES MEETUP'**
  String get cmNewMeetup;

  /// No description provided for @cmDateExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. 21. Mai, 19:00'**
  String get cmDateExample;

  /// No description provided for @cmCityExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. Frankfurt'**
  String get cmCityExample;

  /// No description provided for @cmLocationExample.
  ///
  /// In de, this message translates to:
  /// **'z.B. Room 77'**
  String get cmLocationExample;

  /// No description provided for @evUpcomingEvents.
  ///
  /// In de, this message translates to:
  /// **'KOMMENDE EVENTS'**
  String get evUpcomingEvents;

  /// No description provided for @evDatesEvents.
  ///
  /// In de, this message translates to:
  /// **'TERMINE & EVENTS'**
  String get evDatesEvents;

  /// No description provided for @evNoMeetupsFound.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups gefunden'**
  String get evNoMeetupsFound;

  /// No description provided for @evSearchCityCountry.
  ///
  /// In de, this message translates to:
  /// **'Stadt oder Land suchen...'**
  String get evSearchCityCountry;

  /// No description provided for @evIntro.
  ///
  /// In de, this message translates to:
  /// **'Die meisten Einundzwanzig Meetups finden regelmäßig statt. Klick auf ein Meetup für mehr Infos und Termine.'**
  String get evIntro;

  /// No description provided for @rvLabelPlatform.
  ///
  /// In de, this message translates to:
  /// **'Plattform'**
  String get rvLabelPlatform;

  /// No description provided for @rvLabelUsername.
  ///
  /// In de, this message translates to:
  /// **'Username'**
  String get rvLabelUsername;

  /// No description provided for @countryDE.
  ///
  /// In de, this message translates to:
  /// **'Deutschland'**
  String get countryDE;

  /// No description provided for @countryAT.
  ///
  /// In de, this message translates to:
  /// **'Österreich'**
  String get countryAT;

  /// No description provided for @countryCH.
  ///
  /// In de, this message translates to:
  /// **'Schweiz'**
  String get countryCH;

  /// No description provided for @countryES.
  ///
  /// In de, this message translates to:
  /// **'Spanien'**
  String get countryES;

  /// No description provided for @countryNL.
  ///
  /// In de, this message translates to:
  /// **'Niederlande'**
  String get countryNL;

  /// No description provided for @countryIT.
  ///
  /// In de, this message translates to:
  /// **'Italien'**
  String get countryIT;

  /// No description provided for @countryFR.
  ///
  /// In de, this message translates to:
  /// **'Frankreich'**
  String get countryFR;

  /// No description provided for @siTitle.
  ///
  /// In de, this message translates to:
  /// **'DEIN TRUST SCORE'**
  String get siTitle;

  /// No description provided for @siIntro.
  ///
  /// In de, this message translates to:
  /// **'Misst deine Vertrauenswürdigkeit. Basiert auf kryptographischen Beweisen — niemand kann ihn fälschen.'**
  String get siIntro;

  /// No description provided for @siIdentityLayer.
  ///
  /// In de, this message translates to:
  /// **'IDENTITY LAYER'**
  String get siIdentityLayer;

  /// No description provided for @siLinksActive.
  ///
  /// In de, this message translates to:
  /// **'{count} Verknüpfungen aktiv'**
  String siLinksActive(Object count);

  /// No description provided for @siHumanitySub.
  ///
  /// In de, this message translates to:
  /// **'Lightning Zap Verifikation'**
  String get siHumanitySub;

  /// No description provided for @siNip05Sub.
  ///
  /// In de, this message translates to:
  /// **'Nostr-Identität (name@domain)'**
  String get siNip05Sub;

  /// No description provided for @siPlatformActive.
  ///
  /// In de, this message translates to:
  /// **'Plattform aktiv'**
  String get siPlatformActive;

  /// No description provided for @siPlatforms.
  ///
  /// In de, this message translates to:
  /// **'Plattformen'**
  String get siPlatforms;

  /// No description provided for @siNoneLinked.
  ///
  /// In de, this message translates to:
  /// **'Noch keine verknüpft'**
  String get siNoneLinked;

  /// No description provided for @siTrustLevel.
  ///
  /// In de, this message translates to:
  /// **'TRUST LEVEL'**
  String get siTrustLevel;

  /// No description provided for @siLvlNew.
  ///
  /// In de, this message translates to:
  /// **'Startlevel. Besuche Meetups um Badges zu sammeln.'**
  String get siLvlNew;

  /// No description provided for @siLvlStarter.
  ///
  /// In de, this message translates to:
  /// **'Deine ersten Badges zeigen Community-Teilnahme.'**
  String get siLvlStarter;

  /// No description provided for @siLvlActive.
  ///
  /// In de, this message translates to:
  /// **'Regelmäßig dabei. Verschiedene Meetups und Organisatoren stärken dein Profil.'**
  String get siLvlActive;

  /// No description provided for @siLvlEstablished.
  ///
  /// In de, this message translates to:
  /// **'Vertrauenswürdiges Mitglied. Breit vernetzt und lange dabei.'**
  String get siLvlEstablished;

  /// No description provided for @siLvlVeteran.
  ///
  /// In de, this message translates to:
  /// **'Höchstes Level. Reputation über Monate bewiesen.'**
  String get siLvlVeteran;

  /// No description provided for @siCalculation.
  ///
  /// In de, this message translates to:
  /// **'BERECHNUNG'**
  String get siCalculation;

  /// No description provided for @siFacBadges.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Badges'**
  String get siFacBadges;

  /// No description provided for @siFacBadgesDesc.
  ///
  /// In de, this message translates to:
  /// **'Basiswert pro Badge. Gut besuchte Meetups wertvoller.'**
  String get siFacBadgesDesc;

  /// No description provided for @siFacDiversity.
  ///
  /// In de, this message translates to:
  /// **'Diversität'**
  String get siFacDiversity;

  /// No description provided for @siFacDiversityDesc.
  ///
  /// In de, this message translates to:
  /// **'Verschiedene Städte/Organisatoren = mehr Punkte.'**
  String get siFacDiversityDesc;

  /// No description provided for @siFacSigners.
  ///
  /// In de, this message translates to:
  /// **'Signers'**
  String get siFacSigners;

  /// No description provided for @siFacSignersDesc.
  ///
  /// In de, this message translates to:
  /// **'Unabhängige Organisatoren = höherer Trust.'**
  String get siFacSignersDesc;

  /// No description provided for @siFacMaturity.
  ///
  /// In de, this message translates to:
  /// **'Reife'**
  String get siFacMaturity;

  /// No description provided for @siFacMaturityDesc.
  ///
  /// In de, this message translates to:
  /// **'Account-Alter + Regelmäßigkeit = Bonus.'**
  String get siFacMaturityDesc;

  /// No description provided for @siFacFrequency.
  ///
  /// In de, this message translates to:
  /// **'Frequency Cap'**
  String get siFacFrequency;

  /// No description provided for @siFacFrequencyDesc.
  ///
  /// In de, this message translates to:
  /// **'Max. 2 Badges/Woche. Anti-Farming.'**
  String get siFacFrequencyDesc;

  /// No description provided for @siBecomeOrganizer.
  ///
  /// In de, this message translates to:
  /// **'ORGANISATOR WERDEN'**
  String get siBecomeOrganizer;

  /// No description provided for @siBecomeOrgDesc.
  ///
  /// In de, this message translates to:
  /// **'Automatische Beförderung ab genügend Trust Score. Dann eigene QR-Codes erstellen.'**
  String get siBecomeOrgDesc;

  /// No description provided for @siProgressLabel.
  ///
  /// In de, this message translates to:
  /// **'FORTSCHRITT ({name})'**
  String siProgressLabel(Object name);

  /// No description provided for @siAlreadyOrganizer.
  ///
  /// In de, this message translates to:
  /// **'Du bist bereits Organisator!'**
  String get siAlreadyOrganizer;

  /// No description provided for @siIncreaseScore.
  ///
  /// In de, this message translates to:
  /// **'SCORE ERHÖHEN'**
  String get siIncreaseScore;

  /// No description provided for @siTip1.
  ///
  /// In de, this message translates to:
  /// **'Regelmäßig verschiedene Meetups besuchen'**
  String get siTip1;

  /// No description provided for @siTip2.
  ///
  /// In de, this message translates to:
  /// **'Badges bei Meetups in anderen Städten sammeln'**
  String get siTip2;

  /// No description provided for @siTip3.
  ///
  /// In de, this message translates to:
  /// **'Badges von verschiedenen Organisatoren'**
  String get siTip3;

  /// No description provided for @siTip4.
  ///
  /// In de, this message translates to:
  /// **'Identität mit Lightning-Zap verifizieren'**
  String get siTip4;

  /// No description provided for @siTip5.
  ///
  /// In de, this message translates to:
  /// **'NIP-05 einrichten'**
  String get siTip5;

  /// No description provided for @siTip6.
  ///
  /// In de, this message translates to:
  /// **'Plattformen verknüpfen'**
  String get siTip6;

  /// No description provided for @siProgressRow.
  ///
  /// In de, this message translates to:
  /// **'{label}: {current}/{required}'**
  String siProgressRow(Object label, Object current, Object required);

  /// No description provided for @badgeUnknown.
  ///
  /// In de, this message translates to:
  /// **'unbekannt'**
  String get badgeUnknown;

  /// No description provided for @badgeBlockAtScan.
  ///
  /// In de, this message translates to:
  /// **'₿ Blockhöhe beim Scan'**
  String get badgeBlockAtScan;

  /// No description provided for @mwStartMeetup.
  ///
  /// In de, this message translates to:
  /// **'MEETUP STARTEN'**
  String get mwStartMeetup;

  /// No description provided for @mwStep1Nfc.
  ///
  /// In de, this message translates to:
  /// **'SCHRITT 1: NFC TAG'**
  String get mwStep1Nfc;

  /// No description provided for @mwNfcIntro1.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du physische NFC-Tags (NTAG215) für dieses Meetup auslegen? '**
  String get mwNfcIntro1;

  /// No description provided for @mwNfcIntro2.
  ///
  /// In de, this message translates to:
  /// **'Der kryptographische Beweis (Blockzeit & Signatur) wird darauf fixiert.'**
  String get mwNfcIntro2;

  /// No description provided for @mwWriteNfcTag.
  ///
  /// In de, this message translates to:
  /// **'NFC TAG BESCHREIBEN'**
  String get mwWriteNfcTag;

  /// No description provided for @mwSkipQrOnly.
  ///
  /// In de, this message translates to:
  /// **'ÜBERSPRINGEN — NUR QR NUTZEN'**
  String get mwSkipQrOnly;

  /// No description provided for @repAllBound.
  ///
  /// In de, this message translates to:
  /// **'Alle {total} Badges gebunden und verifiziert'**
  String repAllBound(Object total);

  /// No description provided for @repBoundOf.
  ///
  /// In de, this message translates to:
  /// **'{bound} von {total} Badges identitätsgebunden'**
  String repBoundOf(Object total, Object bound);

  /// No description provided for @repBoundExtra.
  ///
  /// In de, this message translates to:
  /// **' ({verified} kryptographisch verifiziert)'**
  String repBoundExtra(Object verified);

  /// No description provided for @repAllVerified.
  ///
  /// In de, this message translates to:
  /// **'Alle {total} Badges kryptographisch verifiziert (noch nicht gebunden)'**
  String repAllVerified(Object total);

  /// No description provided for @repVerifiedSchnorr.
  ///
  /// In de, this message translates to:
  /// **'{verified} von {total} Badges mit Schnorr-Beweis'**
  String repVerifiedSchnorr(Object total, Object verified);

  /// No description provided for @repPlatformLinksActive.
  ///
  /// In de, this message translates to:
  /// **'{count} Plattform-Verknüpfungen aktiv'**
  String repPlatformLinksActive(Object count);

  /// No description provided for @homeCouldNotOpen.
  ///
  /// In de, this message translates to:
  /// **'Konnte {url} nicht öffnen'**
  String homeCouldNotOpen(Object url);

  /// No description provided for @apHowStep3.
  ///
  /// In de, this message translates to:
  /// **'3. Jeder Scan = ein Badge für den Teilnehmer\n'**
  String get apHowStep3;

  /// No description provided for @badgeSchnorrSig.
  ///
  /// In de, this message translates to:
  /// **'Schnorr (Nostr v2) ✓'**
  String get badgeSchnorrSig;

  /// No description provided for @msHomeMeetupSet.
  ///
  /// In de, this message translates to:
  /// **'✅ {city} als Home-Meetup gesetzt'**
  String msHomeMeetupSet(Object city);

  /// No description provided for @mvKnownOrganizer.
  ///
  /// In de, this message translates to:
  /// **'✓ Bekannter Organisator: {name}'**
  String mvKnownOrganizer(Object name);

  /// No description provided for @mvUnknownSigner.
  ///
  /// In de, this message translates to:
  /// **'Kein Eintrag gefunden\nWeder in der Organisatoren-Liste noch bei den Leadern dieses Meetups ist dieser Schlüssel hinterlegt. Das Badge selbst ist gültig — die Signatur stimmt und ist an dieses Badge gebunden.'**
  String get mvUnknownSigner;

  /// No description provided for @mvAdminCheckFailed.
  ///
  /// In de, this message translates to:
  /// **'! Nicht prüfbar — die Organisatoren-Liste war gerade nicht erreichbar. Das Badge selbst ist gültig; die Signatur stimmt.'**
  String get mvAdminCheckFailed;

  /// No description provided for @mvLegacyBadge.
  ///
  /// In de, this message translates to:
  /// **'! Legacy-Badge (v1) — Signer nicht prüfbar'**
  String get mvLegacyBadge;

  /// No description provided for @mvBadgeBound.
  ///
  /// In de, this message translates to:
  /// **'🔗 Badge gebunden'**
  String get mvBadgeBound;

  /// No description provided for @nwSelectHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'❌ Bitte erst ein Home-Meetup im Profil auswählen!'**
  String get nwSelectHomeMeetup;

  /// No description provided for @qrUniqueRecipients.
  ///
  /// In de, this message translates to:
  /// **'{count} verschiedene Empfänger'**
  String qrUniqueRecipients(Object count);

  /// No description provided for @apHowStep1.
  ///
  /// In de, this message translates to:
  /// **'1. Starte ein neues Meetup (Session).\n'**
  String get apHowStep1;

  /// No description provided for @apHowStep2.
  ///
  /// In de, this message translates to:
  /// **'2. Zeige danach den QR-Code.\n'**
  String get apHowStep2;

  /// No description provided for @apHowStep4.
  ///
  /// In de, this message translates to:
  /// **'4. Badges bauen Reputation auf → mehr Reputation = neue Organisatoren'**
  String get apHowStep4;

  /// No description provided for @ppHowStep1.
  ///
  /// In de, this message translates to:
  /// **'1. Wähle eine Plattform und gib deinen Usernamen ein\n'**
  String get ppHowStep1;

  /// No description provided for @ppHowStep2.
  ///
  /// In de, this message translates to:
  /// **'2. Die App erstellt einen kryptographischen Beweis\n'**
  String get ppHowStep2;

  /// No description provided for @ppHowStep3.
  ///
  /// In de, this message translates to:
  /// **'3. Der Beweis wird automatisch in deinen Reputation-QR eingebettet\n'**
  String get ppHowStep3;

  /// No description provided for @ppHowStep4.
  ///
  /// In de, this message translates to:
  /// **'4. Andere scannen deinen QR und sehen die verifizierte Verknüpfung'**
  String get ppHowStep4;

  /// No description provided for @homeImageLoadError.
  ///
  /// In de, this message translates to:
  /// **'Bild konnte nicht geladen werden: {msg}'**
  String homeImageLoadError(Object msg);

  /// No description provided for @qrSentCount.
  ///
  /// In de, this message translates to:
  /// **'{count} gesendet'**
  String qrSentCount(Object count);

  /// No description provided for @repShareError.
  ///
  /// In de, this message translates to:
  /// **'Fehler beim Teilen: {msg}'**
  String repShareError(Object msg);

  /// No description provided for @rqNoHomeMeetup.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Kein Home-Meetup gesetzt'**
  String get rqNoHomeMeetup;

  /// No description provided for @rqMeetupNotFound.
  ///
  /// In de, this message translates to:
  /// **'⚠️ Meetup nicht gefunden'**
  String get rqMeetupNotFound;

  /// No description provided for @rlWhatMeans.
  ///
  /// In de, this message translates to:
  /// **'Was bedeutet das?'**
  String get rlWhatMeans;

  /// No description provided for @rlWhyImportant.
  ///
  /// In de, this message translates to:
  /// **'Warum das wichtig ist'**
  String get rlWhyImportant;

  /// No description provided for @rlWeakLabel.
  ///
  /// In de, this message translates to:
  /// **'Schwaches Profil'**
  String get rlWeakLabel;

  /// No description provided for @rlWeakExpl.
  ///
  /// In de, this message translates to:
  /// **'Nur ein Beweis-Layer aktiv. Dieser Nutzer hat kaum nachprüfbare Verbindungen. Bei größeren Transaktionen: Vorsicht.'**
  String get rlWeakExpl;

  /// No description provided for @rlWeakAdvice.
  ///
  /// In de, this message translates to:
  /// **'Frage nach weiteren Beweisen (Lightning, NIP-05) oder triff die Person zuerst persönlich.'**
  String get rlWeakAdvice;

  /// No description provided for @rlLimitedLabel.
  ///
  /// In de, this message translates to:
  /// **'Eingeschränkt'**
  String get rlLimitedLabel;

  /// No description provided for @rlLimitedExpl.
  ///
  /// In de, this message translates to:
  /// **'Es gibt Meetup-Badges, aber keine weiteren unabhängigen Beweise. Der Nutzer könnte echt sein — aber es fehlt die Bestätigung durch andere Layer.'**
  String get rlLimitedExpl;

  /// No description provided for @rlLimitedAdvice.
  ///
  /// In de, this message translates to:
  /// **'Für Kleinstbeträge OK. Für größere Beträge: Abwarten bis mehr Layer aktiv sind.'**
  String get rlLimitedAdvice;

  /// No description provided for @rlBuildingLabel.
  ///
  /// In de, this message translates to:
  /// **'Aufbauend'**
  String get rlBuildingLabel;

  /// No description provided for @rlBuildingExpl.
  ///
  /// In de, this message translates to:
  /// **'Zwei Beweis-Layer aktiv. Der Nutzer baut Reputation auf, hat aber noch nicht die volle Breite.'**
  String get rlBuildingExpl;

  /// No description provided for @rlBuildingAdvice.
  ///
  /// In de, this message translates to:
  /// **'Für moderate Transaktionen geeignet.'**
  String get rlBuildingAdvice;

  /// No description provided for @rlConnectedLabel.
  ///
  /// In de, this message translates to:
  /// **'Gut vernetzt'**
  String get rlConnectedLabel;

  /// No description provided for @rlConnectedExpl.
  ///
  /// In de, this message translates to:
  /// **'Mehrere unabhängige Beweise: Meetups, Lightning-Aktivität und soziale Verbindungen. Schwer zu faken.'**
  String get rlConnectedExpl;

  /// No description provided for @rlConnectedAdvice.
  ///
  /// In de, this message translates to:
  /// **'Vertrauenswürdig für die meisten Transaktionen.'**
  String get rlConnectedAdvice;

  /// No description provided for @rlSolidLabel.
  ///
  /// In de, this message translates to:
  /// **'Solide'**
  String get rlSolidLabel;

  /// No description provided for @rlSolidExpl.
  ///
  /// In de, this message translates to:
  /// **'Breite Basis an Beweisen. Manipulation wäre aufwändig und teuer.'**
  String get rlSolidExpl;

  /// No description provided for @rlSolidAdvice.
  ///
  /// In de, this message translates to:
  /// **'Für die meisten Zwecke vertrauenswürdig.'**
  String get rlSolidAdvice;

  /// No description provided for @rlDefaultExpl.
  ///
  /// In de, this message translates to:
  /// **'Einige Beweise vorhanden, aber Raum für mehr.'**
  String get rlDefaultExpl;

  /// No description provided for @rlDefaultAdvice.
  ///
  /// In de, this message translates to:
  /// **'Eigene Einschätzung nutzen.'**
  String get rlDefaultAdvice;

  /// No description provided for @rlMeetupProofs.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Beweise'**
  String get rlMeetupProofs;

  /// No description provided for @rlMeetupGood.
  ///
  /// In de, this message translates to:
  /// **'War bei verschiedenen Meetups mit verschiedenen Organisatoren. Das erfordert physische Anwesenheit an mehreren Orten.'**
  String get rlMeetupGood;

  /// No description provided for @rlMeetupMoreDiverse.
  ///
  /// In de, this message translates to:
  /// **'Mehr Vielfalt wäre überzeugender.'**
  String get rlMeetupMoreDiverse;

  /// No description provided for @rlMeetupNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetup-Badges vorhanden. Dieser Nutzer hat noch kein Einundzwanzig-Meetup besucht — oder nutzt die App erst seit kurzem.'**
  String get rlMeetupNone;

  /// No description provided for @rlAllBound.
  ///
  /// In de, this message translates to:
  /// **'Alle kryptographisch gebunden'**
  String get rlAllBound;

  /// No description provided for @rlGoodSpread.
  ///
  /// In de, this message translates to:
  /// **'Gute regionale Streuung'**
  String get rlGoodSpread;

  /// No description provided for @rlLowSpread.
  ///
  /// In de, this message translates to:
  /// **'Wenig Streuung'**
  String get rlLowSpread;

  /// No description provided for @rlPhysGoodDiversity.
  ///
  /// In de, this message translates to:
  /// **'Hat Meetup-Badges, aber nur von {count} Organisator(en). Mehr Vielfalt wäre überzeugender.'**
  String rlPhysGoodDiversity(Object count);

  /// No description provided for @rlBadgeCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Badges'**
  String rlBadgeCount(Object count);

  /// No description provided for @rlBoundOf.
  ///
  /// In de, this message translates to:
  /// **'{bound} von {total} gebunden'**
  String rlBoundOf(Object bound, Object total);

  /// No description provided for @rlDiffMeetups.
  ///
  /// In de, this message translates to:
  /// **'{count} verschiedene Meetups'**
  String rlDiffMeetups(Object count);

  /// No description provided for @rlOrganizers.
  ///
  /// In de, this message translates to:
  /// **'{count} Organisatoren'**
  String rlOrganizers(Object count);

  /// No description provided for @rlConfirmedByDiff.
  ///
  /// In de, this message translates to:
  /// **'Von verschiedenen Personen bestätigt'**
  String get rlConfirmedByDiff;

  /// No description provided for @rlOneOrgOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur ein Organisator — wenig unabhängige Bestätigung'**
  String get rlOneOrgOnly;

  /// No description provided for @rlMemberSince.
  ///
  /// In de, this message translates to:
  /// **'Dabei seit {since}'**
  String rlMemberSince(Object since);

  /// No description provided for @rlDaysCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Tage'**
  String rlDaysCount(Object count);

  /// No description provided for @rlLightningProof.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Beweis'**
  String get rlLightningProof;

  /// No description provided for @rlLnBoth.
  ///
  /// In de, this message translates to:
  /// **'Hat echte Lightning-Zahlungen getätigt und empfangen. Bots haben keine Lightning-Wallets — das ist ein starkes Echtheitssignal.'**
  String get rlLnBoth;

  /// No description provided for @rlLnPaid.
  ///
  /// In de, this message translates to:
  /// **'Hat mindestens einmal über Lightning gezahlt. Grundlegender Beweis dass eine echte Wallet existiert.'**
  String get rlLnPaid;

  /// No description provided for @rlLnActiveOnly.
  ///
  /// In de, this message translates to:
  /// **'Lightning-Aktivität vorhanden, aber Humanity-Proof noch nicht aktiv.'**
  String get rlLnActiveOnly;

  /// No description provided for @rlLnNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Lightning-Aktivität. Das heißt nicht dass der Nutzer unecht ist — vielleicht nutzt er Lightning nicht über Nostr. Aber es fehlt ein wichtiges Anti-Bot-Signal.'**
  String get rlLnNone;

  /// No description provided for @rlHumanVerified.
  ///
  /// In de, this message translates to:
  /// **'Mensch verifiziert'**
  String get rlHumanVerified;

  /// No description provided for @rlRealLnPayment.
  ///
  /// In de, this message translates to:
  /// **'Echte Lightning-Zahlung nachgewiesen'**
  String get rlRealLnPayment;

  /// No description provided for @rlZapsSent.
  ///
  /// In de, this message translates to:
  /// **'{count} Zaps gesendet'**
  String rlZapsSent(Object count);

  /// No description provided for @rlToRecipients.
  ///
  /// In de, this message translates to:
  /// **'An {count} verschiedene Empfänger'**
  String rlToRecipients(Object count);

  /// No description provided for @rlZapsReceived.
  ///
  /// In de, this message translates to:
  /// **'{count} Zaps empfangen'**
  String rlZapsReceived(Object count);

  /// No description provided for @rlFromSenders.
  ///
  /// In de, this message translates to:
  /// **'Von {count} verschiedenen Sendern'**
  String rlFromSenders(Object count);

  /// No description provided for @rlMonthsActive.
  ///
  /// In de, this message translates to:
  /// **'{count} Monate aktiv'**
  String rlMonthsActive(Object count);

  /// No description provided for @rlSocialTitle.
  ///
  /// In de, this message translates to:
  /// **'Soziales Netzwerk'**
  String get rlSocialTitle;

  /// No description provided for @rlSocMutualMany.
  ///
  /// In de, this message translates to:
  /// **'Ihr kennt euch gegenseitig auf Nostr und habt viele gemeinsame Kontakte. Starke Verbindung.'**
  String get rlSocMutualMany;

  /// No description provided for @rlSocMutual.
  ///
  /// In de, this message translates to:
  /// **'Gegenseitiger Follow — ihr kennt euch auf Nostr.'**
  String get rlSocMutual;

  /// No description provided for @rlSocCommon.
  ///
  /// In de, this message translates to:
  /// **'Viele gemeinsame Kontakte — ihr bewegt euch im selben Netzwerk.'**
  String get rlSocCommon;

  /// No description provided for @rlSocOneSided.
  ///
  /// In de, this message translates to:
  /// **'Einseitige Verbindung. Ihr kennt euch flüchtig.'**
  String get rlSocOneSided;

  /// No description provided for @rlSocOrgFollow.
  ///
  /// In de, this message translates to:
  /// **'Bekannte Einundzwanzig-Organisatoren folgen diesem Nutzer. Das ist ein positives Signal.'**
  String get rlSocOrgFollow;

  /// No description provided for @rlSocDefault.
  ///
  /// In de, this message translates to:
  /// **'Es gibt Verbindungen im Nostr-Netzwerk zu diesem Nutzer.'**
  String get rlSocDefault;

  /// No description provided for @rlSocNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung im Nostr-Netzwerk gefunden. Das kann bedeuten: Ihr seid euch noch nie auf Nostr begegnet, oder der Nutzer ist sehr neu. Bei Fremden ist das normal — bei angeblich bekannten Gesichtern ein Warnsignal.'**
  String get rlSocNone;

  /// No description provided for @rlMutualFollow.
  ///
  /// In de, this message translates to:
  /// **'Gegenseitiger Follow'**
  String get rlMutualFollow;

  /// No description provided for @rlYouFollow.
  ///
  /// In de, this message translates to:
  /// **'Du folgst'**
  String get rlYouFollow;

  /// No description provided for @rlFollowsYou.
  ///
  /// In de, this message translates to:
  /// **'Folgt dir'**
  String get rlFollowsYou;

  /// No description provided for @rlNoFollow.
  ///
  /// In de, this message translates to:
  /// **'Kein Follow'**
  String get rlNoFollow;

  /// No description provided for @rlKnowOnNostr.
  ///
  /// In de, this message translates to:
  /// **'Ihr kennt euch auf Nostr'**
  String get rlKnowOnNostr;

  /// No description provided for @rlNoDirectConn.
  ///
  /// In de, this message translates to:
  /// **'Keine direkte Verbindung'**
  String get rlNoDirectConn;

  /// No description provided for @rlCommonContacts.
  ///
  /// In de, this message translates to:
  /// **'{count} gemeinsame Kontakte'**
  String rlCommonContacts(Object count);

  /// No description provided for @rlSameNetwork.
  ///
  /// In de, this message translates to:
  /// **'Gleiches Netzwerk'**
  String get rlSameNetwork;

  /// No description provided for @rlSomeOverlap.
  ///
  /// In de, this message translates to:
  /// **'Einige Überlappungen'**
  String get rlSomeOverlap;

  /// No description provided for @rlSeparateNetworks.
  ///
  /// In de, this message translates to:
  /// **'Getrennte Netzwerke'**
  String get rlSeparateNetworks;

  /// No description provided for @rlOrgsFollow.
  ///
  /// In de, this message translates to:
  /// **'{count} Organisatoren folgen'**
  String rlOrgsFollow(Object count);

  /// No description provided for @rlEndorsement.
  ///
  /// In de, this message translates to:
  /// **'Endorsement von bekannten Admins'**
  String get rlEndorsement;

  /// No description provided for @rlIdentityTitle.
  ///
  /// In de, this message translates to:
  /// **'Identitäts-Nachweis'**
  String get rlIdentityTitle;

  /// No description provided for @rlIdNip05Plat.
  ///
  /// In de, this message translates to:
  /// **'Hat eine NIP-05-Adresse und verknüpfte Plattformen. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.'**
  String get rlIdNip05Plat;

  /// No description provided for @rlIdNip05Only.
  ///
  /// In de, this message translates to:
  /// **'Hat eine NIP-05-Adresse. Das verknüpft die Nostr-Identität mit einer Domain — schwerer zu faken als ein anonymer Account.'**
  String get rlIdNip05Only;

  /// No description provided for @rlIdPlatOnly.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfte Plattform-Accounts. Mehr Plattformen = mehr Aufwand für Fälscher.'**
  String get rlIdPlatOnly;

  /// No description provided for @rlIdNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Internet-Identifikation. Komplett anonym. Das ist für Privatsphäre OK, aber gibt auch weniger Anhaltspunkte für Vertrauen.'**
  String get rlIdNone;

  /// No description provided for @rlLinked.
  ///
  /// In de, this message translates to:
  /// **'Verknüpft'**
  String get rlLinked;

  /// No description provided for @rlNoIdentification.
  ///
  /// In de, this message translates to:
  /// **'Keine Identifikation'**
  String get rlNoIdentification;

  /// No description provided for @rlAnonymous.
  ///
  /// In de, this message translates to:
  /// **'Anonym'**
  String get rlAnonymous;

  /// No description provided for @rlActive.
  ///
  /// In de, this message translates to:
  /// **'✓ aktiv'**
  String get rlActive;

  /// No description provided for @rlActiveShort.
  ///
  /// In de, this message translates to:
  /// **'✓ aktiv'**
  String get rlActiveShort;

  /// No description provided for @rlMissingShort.
  ///
  /// In de, this message translates to:
  /// **'— fehlt'**
  String get rlMissingShort;

  /// No description provided for @qrReceivedCount.
  ///
  /// In de, this message translates to:
  /// **'{count} empfangen'**
  String qrReceivedCount(Object count);

  /// No description provided for @qrUniqueSenders.
  ///
  /// In de, this message translates to:
  /// **'{count} verschiedene Sender'**
  String qrUniqueSenders(Object count);

  /// No description provided for @rlProofsOfFour.
  ///
  /// In de, this message translates to:
  /// **'{count} / 4 Beweise'**
  String rlProofsOfFour(Object count);

  /// No description provided for @navNearby.
  ///
  /// In de, this message translates to:
  /// **'In der Nähe'**
  String get navNearby;

  /// No description provided for @nbTitle.
  ///
  /// In de, this message translates to:
  /// **'MEETUPS IN DER NÄHE'**
  String get nbTitle;

  /// No description provided for @nbRequestingLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort wird ermittelt...'**
  String get nbRequestingLocation;

  /// No description provided for @nbLoading.
  ///
  /// In de, this message translates to:
  /// **'Meetups werden geladen...'**
  String get nbLoading;

  /// No description provided for @nbLocationDenied.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff verweigert'**
  String get nbLocationDenied;

  /// No description provided for @nbLocationDeniedSub.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort zeigen wir alle Meetups nach Datum sortiert. Aktiviere den Standort in den Einstellungen für Entfernungen.'**
  String get nbLocationDeniedSub;

  /// No description provided for @nbServiceDisabled.
  ///
  /// In de, this message translates to:
  /// **'Standortdienste sind deaktiviert'**
  String get nbServiceDisabled;

  /// No description provided for @nbRetryLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort erneut versuchen'**
  String get nbRetryLocation;

  /// No description provided for @nbContinueWithout.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort fortfahren'**
  String get nbContinueWithout;

  /// No description provided for @nbNoMeetups.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups für diesen Zeitraum'**
  String get nbNoMeetups;

  /// No description provided for @nbNoMeetupsSub.
  ///
  /// In de, this message translates to:
  /// **'Versuch einen anderen Filter oder ein anderes Datum.'**
  String get nbNoMeetupsSub;

  /// No description provided for @nbFilterToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get nbFilterToday;

  /// No description provided for @nbFilterWeek.
  ///
  /// In de, this message translates to:
  /// **'Diese Woche'**
  String get nbFilterWeek;

  /// No description provided for @nbFilterUpcoming.
  ///
  /// In de, this message translates to:
  /// **'Alle kommenden'**
  String get nbFilterUpcoming;

  /// No description provided for @nbFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get nbFilterAll;

  /// No description provided for @nbPickDate.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get nbPickDate;

  /// No description provided for @nbKmAway.
  ///
  /// In de, this message translates to:
  /// **'{km} km entfernt'**
  String nbKmAway(Object km);

  /// No description provided for @nbNoDate.
  ///
  /// In de, this message translates to:
  /// **'Kein Termin angekündigt'**
  String get nbNoDate;

  /// No description provided for @nbListHeader.
  ///
  /// In de, this message translates to:
  /// **'{count} Meetups'**
  String nbListHeader(Object count);

  /// No description provided for @nbOpenInMaps.
  ///
  /// In de, this message translates to:
  /// **'In Karten öffnen'**
  String get nbOpenInMaps;

  /// No description provided for @nbYourLocation.
  ///
  /// In de, this message translates to:
  /// **'Dein Standort'**
  String get nbYourLocation;

  /// No description provided for @nbToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get nbToday;

  /// No description provided for @nbTomorrow.
  ///
  /// In de, this message translates to:
  /// **'Morgen'**
  String get nbTomorrow;

  /// No description provided for @nbResetDate.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get nbResetDate;

  /// No description provided for @nbModeHere.
  ///
  /// In de, this message translates to:
  /// **'Hier & jetzt'**
  String get nbModeHere;

  /// No description provided for @nbModePlanned.
  ///
  /// In de, this message translates to:
  /// **'Geplant'**
  String get nbModePlanned;

  /// No description provided for @nbRadius.
  ///
  /// In de, this message translates to:
  /// **'Umkreis'**
  String get nbRadius;

  /// No description provided for @nbRadiusValue.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String nbRadiusValue(Object km);

  /// No description provided for @nbSearchPlace.
  ///
  /// In de, this message translates to:
  /// **'Ort suchen (z.B. Hamburg)'**
  String get nbSearchPlace;

  /// No description provided for @nbSearchingPlace.
  ///
  /// In de, this message translates to:
  /// **'Suche Orte...'**
  String get nbSearchingPlace;

  /// No description provided for @nbNoPlaceFound.
  ///
  /// In de, this message translates to:
  /// **'Kein Ort gefunden'**
  String get nbNoPlaceFound;

  /// No description provided for @nbCenterHere.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get nbCenterHere;

  /// No description provided for @nbChangePlace.
  ///
  /// In de, this message translates to:
  /// **'Ort ändern'**
  String get nbChangePlace;

  /// No description provided for @nbDateAny.
  ///
  /// In de, this message translates to:
  /// **'Jederzeit'**
  String get nbDateAny;

  /// No description provided for @nbDateSingle.
  ///
  /// In de, this message translates to:
  /// **'Datum'**
  String get nbDateSingle;

  /// No description provided for @nbDateRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum'**
  String get nbDateRange;

  /// No description provided for @nbPickDay.
  ///
  /// In de, this message translates to:
  /// **'Tag wählen'**
  String get nbPickDay;

  /// No description provided for @nbPickRange.
  ///
  /// In de, this message translates to:
  /// **'Zeitraum wählen'**
  String get nbPickRange;

  /// No description provided for @nbDateFromTo.
  ///
  /// In de, this message translates to:
  /// **'{from} – {to}'**
  String nbDateFromTo(Object from, Object to);

  /// No description provided for @nbResultsHeader.
  ///
  /// In de, this message translates to:
  /// **'{count} Meetups im Umkreis'**
  String nbResultsHeader(Object count);

  /// No description provided for @nbNoneInRadius.
  ///
  /// In de, this message translates to:
  /// **'Keine Meetups im Umkreis'**
  String get nbNoneInRadius;

  /// No description provided for @nbNoneInRadiusSub.
  ///
  /// In de, this message translates to:
  /// **'Vergrößere den Umkreis oder ändere Ort/Datum.'**
  String get nbNoneInRadiusSub;

  /// No description provided for @nbApplySearch.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get nbApplySearch;

  /// No description provided for @nbMoreDates.
  ///
  /// In de, this message translates to:
  /// **'+{count} weitere Termine'**
  String nbMoreDates(Object count);

  /// No description provided for @nbDirections.
  ///
  /// In de, this message translates to:
  /// **'Route'**
  String get nbDirections;

  /// No description provided for @nbDetails.
  ///
  /// In de, this message translates to:
  /// **'Details'**
  String get nbDetails;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil'**
  String get settingsSectionProfile;

  /// No description provided for @settingsProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil bearbeiten'**
  String get settingsProfile;

  /// No description provided for @settingsProfileSub.
  ///
  /// In de, this message translates to:
  /// **'Name, Nostr-Schlüssel & Home-Meetup'**
  String get settingsProfileSub;

  /// No description provided for @apCreateEvent.
  ///
  /// In de, this message translates to:
  /// **'Termin erstellen'**
  String get apCreateEvent;

  /// No description provided for @apCreateEventSub.
  ///
  /// In de, this message translates to:
  /// **'Im Portal eintragen'**
  String get apCreateEventSub;

  /// No description provided for @apCreateEventTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin im Portal erstellen'**
  String get apCreateEventTitle;

  /// No description provided for @apCreateEventBody.
  ///
  /// In de, this message translates to:
  /// **'Meetup-Termine werden zentral im Einundzwanzig-Portal verwaltet. Die App öffnet jetzt das Portal in deinem Browser — dort meldest du dich mit deinem Nostr-Schlüssel an und trägst den Termin ein. Er erscheint danach automatisch hier im Kalender.'**
  String get apCreateEventBody;

  /// No description provided for @apOpenPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal öffnen'**
  String get apOpenPortal;

  /// No description provided for @apNoHomeMeetupSet.
  ///
  /// In de, this message translates to:
  /// **'Wähle zuerst dein Home-Meetup im Profil, dann kannst du Termine dafür erstellen.'**
  String get apNoHomeMeetupSet;

  /// No description provided for @apPortalHint.
  ///
  /// In de, this message translates to:
  /// **'Warum nicht direkt in der App? Das Portal ist die zentrale Quelle für alle Termine und braucht deine Anmeldung. Eine direkte Eintragung aus der App ist geplant, sobald das Portal das unterstützt.'**
  String get apPortalHint;

  /// No description provided for @rcTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputations-Profil'**
  String get rcTitle;

  /// No description provided for @rcShareImage.
  ///
  /// In de, this message translates to:
  /// **'Als Bild teilen'**
  String get rcShareImage;

  /// No description provided for @rcSaving.
  ///
  /// In de, this message translates to:
  /// **'Bild wird erstellt...'**
  String get rcSaving;

  /// No description provided for @rcShareError.
  ///
  /// In de, this message translates to:
  /// **'Teilen fehlgeschlagen: {error}'**
  String rcShareError(Object error);

  /// No description provided for @rcShareText.
  ///
  /// In de, this message translates to:
  /// **'Mein Einundzwanzig Trust Score & Reputation'**
  String get rcShareText;

  /// No description provided for @rcLabelScore.
  ///
  /// In de, this message translates to:
  /// **'Trust Score'**
  String get rcLabelScore;

  /// No description provided for @rcLabelLevel.
  ///
  /// In de, this message translates to:
  /// **'Level'**
  String get rcLabelLevel;

  /// No description provided for @rcLabelBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get rcLabelBadges;

  /// No description provided for @rcLabelMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get rcLabelMeetups;

  /// No description provided for @rcLabelCities.
  ///
  /// In de, this message translates to:
  /// **'Städte'**
  String get rcLabelCities;

  /// No description provided for @rcLabelSigners.
  ///
  /// In de, this message translates to:
  /// **'Bürgen'**
  String get rcLabelSigners;

  /// No description provided for @rcLabelAge.
  ///
  /// In de, this message translates to:
  /// **'Tage dabei'**
  String get rcLabelAge;

  /// No description provided for @rcMember.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig Mitglied'**
  String get rcMember;

  /// No description provided for @rcNoData.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Reputation. Sammle Badges auf Meetups!'**
  String get rcNoData;

  /// No description provided for @caOptInTitle.
  ///
  /// In de, this message translates to:
  /// **'Zum Vertrauensnetzwerk beitragen?'**
  String get caOptInTitle;

  /// No description provided for @caOptInBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst deine Teilnahme an diesem Meetup im öffentlichen Vertrauensnetzwerk bestätigen. Andere sehen dann, dass dein npub bei diesem Meetup war — und über gemeinsame Meetups, wie ihr vernetzt seid.\n\nDas ist freiwillig. Dein Badge bekommst du auch ohne Teilnahme am Netzwerk.'**
  String get caOptInBody;

  /// No description provided for @caOptInPrivacy.
  ///
  /// In de, this message translates to:
  /// **'Öffentlich & dauerhaft auf Nostr-Relays. Zeigt ein Bewegungs- und Kontaktmuster. Überleg es dir gut.'**
  String get caOptInPrivacy;

  /// No description provided for @caOptInYes.
  ///
  /// In de, this message translates to:
  /// **'Ja, beitragen'**
  String get caOptInYes;

  /// No description provided for @caOptInNo.
  ///
  /// In de, this message translates to:
  /// **'Nein, privat bleiben'**
  String get caOptInNo;

  /// No description provided for @caPublished.
  ///
  /// In de, this message translates to:
  /// **'Teilnahme im Netzwerk bestätigt'**
  String get caPublished;

  /// No description provided for @cnTitle.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk-Analyse'**
  String get cnTitle;

  /// No description provided for @cnSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wie ist diese Person über gemeinsame Meetups vernetzt?'**
  String get cnSubtitle;

  /// No description provided for @cnEnterNpub.
  ///
  /// In de, this message translates to:
  /// **'npub der Person eingeben'**
  String get cnEnterNpub;

  /// No description provided for @cnScan.
  ///
  /// In de, this message translates to:
  /// **'Scannen'**
  String get cnScan;

  /// No description provided for @cnAnalyze.
  ///
  /// In de, this message translates to:
  /// **'Analysieren'**
  String get cnAnalyze;

  /// No description provided for @cnLoading.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk wird geladen...'**
  String get cnLoading;

  /// No description provided for @cnSharedMeetups.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Meetups'**
  String get cnSharedMeetups;

  /// No description provided for @cnMutualContacts.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Kontakte'**
  String get cnMutualContacts;

  /// No description provided for @cnReach.
  ///
  /// In de, this message translates to:
  /// **'Vernetzung der Person'**
  String get cnReach;

  /// No description provided for @cnTotalMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups besucht'**
  String get cnTotalMeetups;

  /// No description provided for @cnTotalContacts.
  ///
  /// In de, this message translates to:
  /// **'Personen getroffen'**
  String get cnTotalContacts;

  /// No description provided for @cnNoConnection.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung gefunden'**
  String get cnNoConnection;

  /// No description provided for @cnNoConnectionSub.
  ///
  /// In de, this message translates to:
  /// **'Ihr wart auf keinen gemeinsamen Meetups und habt keine gemeinsamen Kontakte im Netzwerk — oder die Person nimmt nicht am Netzwerk teil.'**
  String get cnNoConnectionSub;

  /// No description provided for @cnDirectMet.
  ///
  /// In de, this message translates to:
  /// **'Ihr habt euch direkt getroffen!'**
  String get cnDirectMet;

  /// No description provided for @cnYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get cnYou;

  /// No description provided for @cnTarget.
  ///
  /// In de, this message translates to:
  /// **'Diese Person'**
  String get cnTarget;

  /// No description provided for @cnViaShared.
  ///
  /// In de, this message translates to:
  /// **'über {count} gemeinsame Meetups'**
  String cnViaShared(Object count);

  /// No description provided for @cnTrustHint.
  ///
  /// In de, this message translates to:
  /// **'Je mehr gemeinsame Meetups und Kontakte, desto stärker das organische Vertrauen.'**
  String get cnTrustHint;

  /// No description provided for @cnInvalidNpub.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger npub'**
  String get cnInvalidNpub;

  /// No description provided for @cnPrivacyNote.
  ///
  /// In de, this message translates to:
  /// **'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in).'**
  String get cnPrivacyNote;

  /// No description provided for @tileTrustNetwork.
  ///
  /// In de, this message translates to:
  /// **'Vertrauensnetzwerk'**
  String get tileTrustNetwork;

  /// No description provided for @tileTrustNetworkSub.
  ///
  /// In de, this message translates to:
  /// **'Vernetzung prüfen'**
  String get tileTrustNetworkSub;

  /// No description provided for @tnHubTitle.
  ///
  /// In de, this message translates to:
  /// **'Vertrauensnetzwerk'**
  String get tnHubTitle;

  /// No description provided for @tnHubIntro.
  ///
  /// In de, this message translates to:
  /// **'Prüfe, wie vertrauenswürdig eine Person im Einundzwanzig-Netzwerk ist — über Bürgschaften und gemeinsame Meetups.'**
  String get tnHubIntro;

  /// No description provided for @tnHubNetTitle.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk-Analyse'**
  String get tnHubNetTitle;

  /// No description provided for @tnHubNetSub.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Meetups & Kontakte einer Person'**
  String get tnHubNetSub;

  /// No description provided for @orgBadgeCreated.
  ///
  /// In de, this message translates to:
  /// **'Organisator-Teilnahme erfasst'**
  String get orgBadgeCreated;

  /// No description provided for @orgBadgeLabel.
  ///
  /// In de, this message translates to:
  /// **'Organisator'**
  String get orgBadgeLabel;

  /// No description provided for @orgBadgeSub.
  ///
  /// In de, this message translates to:
  /// **'Du hast dieses Meetup veranstaltet'**
  String get orgBadgeSub;

  /// No description provided for @mnTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Vernetzung'**
  String get mnTitle;

  /// No description provided for @mnIntro.
  ///
  /// In de, this message translates to:
  /// **'Dein Vertrauensnetzwerk aus echten Meetup-Begegnungen — und wer darüber hinaus mit dir verbunden ist.'**
  String get mnIntro;

  /// No description provided for @mnLoading.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk wird aufgebaut...'**
  String get mnLoading;

  /// No description provided for @mnEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Vernetzung'**
  String get mnEmpty;

  /// No description provided for @mnEmptySub.
  ///
  /// In de, this message translates to:
  /// **'Besuche Meetups und sammle Badges (mit Netzwerk-Teilnahme), um dein Vertrauensnetzwerk aufzubauen.'**
  String get mnEmptySub;

  /// No description provided for @mnDegree1.
  ///
  /// In de, this message translates to:
  /// **'Direkt getroffen'**
  String get mnDegree1;

  /// No description provided for @mnDegree1Sub.
  ///
  /// In de, this message translates to:
  /// **'Personen, die du live auf Meetups getroffen hast'**
  String get mnDegree1Sub;

  /// No description provided for @mnDegree2.
  ///
  /// In de, this message translates to:
  /// **'Über Kontakte verbunden'**
  String get mnDegree2;

  /// No description provided for @mnDegree2Sub.
  ///
  /// In de, this message translates to:
  /// **'Personen, die deine Kontakte auf Meetups getroffen haben'**
  String get mnDegree2Sub;

  /// No description provided for @mnDegree3.
  ///
  /// In de, this message translates to:
  /// **'Erweitertes Netzwerk'**
  String get mnDegree3;

  /// No description provided for @mnDegree3Sub.
  ///
  /// In de, this message translates to:
  /// **'Noch eine Ebene weiter im Netzwerk'**
  String get mnDegree3Sub;

  /// No description provided for @mnSharedMeetups.
  ///
  /// In de, this message translates to:
  /// **'{count} gemeinsame Meetups'**
  String mnSharedMeetups(Object count);

  /// No description provided for @mnOneSharedMeetup.
  ///
  /// In de, this message translates to:
  /// **'1 gemeinsames Meetup'**
  String get mnOneSharedMeetup;

  /// No description provided for @mnViaContacts.
  ///
  /// In de, this message translates to:
  /// **'über {count} Kontakte'**
  String mnViaContacts(Object count);

  /// No description provided for @mnViaOneContact.
  ///
  /// In de, this message translates to:
  /// **'über 1 Kontakt'**
  String get mnViaOneContact;

  /// No description provided for @mnReachLabel.
  ///
  /// In de, this message translates to:
  /// **'Reichweite'**
  String get mnReachLabel;

  /// No description provided for @mnDirectLabel.
  ///
  /// In de, this message translates to:
  /// **'Direkt'**
  String get mnDirectLabel;

  /// No description provided for @mnIndirectLabel.
  ///
  /// In de, this message translates to:
  /// **'Indirekt'**
  String get mnIndirectLabel;

  /// No description provided for @mnTrustHint.
  ///
  /// In de, this message translates to:
  /// **'Indirekte Kontakte über echte Begegnungen erhöhen dein Vertrauen schrittweise — auch ohne dass du die Person selbst getroffen hast.'**
  String get mnTrustHint;

  /// No description provided for @mnPrivacyNote.
  ///
  /// In de, this message translates to:
  /// **'Zeigt nur Personen, die am Netzwerk teilnehmen (Opt-in beim Badge-Scan).'**
  String get mnPrivacyNote;

  /// No description provided for @mnCheckPerson.
  ///
  /// In de, this message translates to:
  /// **'Bestimmte Person prüfen'**
  String get mnCheckPerson;

  /// No description provided for @settingsHeaderTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsHeaderTitle;

  /// No description provided for @settingsHeaderSub.
  ///
  /// In de, this message translates to:
  /// **'App & Account verwalten'**
  String get settingsHeaderSub;

  /// No description provided for @settingsSecAccount.
  ///
  /// In de, this message translates to:
  /// **'ACCOUNT'**
  String get settingsSecAccount;

  /// No description provided for @settingsSecData.
  ///
  /// In de, this message translates to:
  /// **'DATEN & SICHERHEIT'**
  String get settingsSecData;

  /// No description provided for @settingsSecNetwork.
  ///
  /// In de, this message translates to:
  /// **'NETZWERK'**
  String get settingsSecNetwork;

  /// No description provided for @settingsSecApp.
  ///
  /// In de, this message translates to:
  /// **'APP'**
  String get settingsSecApp;

  /// No description provided for @settingsSecDanger.
  ///
  /// In de, this message translates to:
  /// **'GEFAHRENZONE'**
  String get settingsSecDanger;

  /// No description provided for @vpTitle.
  ///
  /// In de, this message translates to:
  /// **'Person prüfen'**
  String get vpTitle;

  /// No description provided for @vpIntro.
  ///
  /// In de, this message translates to:
  /// **'Prüfe über echte Meetup-Begegnungen, ob und wie diese Person mit dir verbunden ist.'**
  String get vpIntro;

  /// No description provided for @vpEnterNpub.
  ///
  /// In de, this message translates to:
  /// **'npub eingeben oder Reputations-QR scannen'**
  String get vpEnterNpub;

  /// No description provided for @vpScanQr.
  ///
  /// In de, this message translates to:
  /// **'QR scannen'**
  String get vpScanQr;

  /// No description provided for @vpCheck.
  ///
  /// In de, this message translates to:
  /// **'Prüfen'**
  String get vpCheck;

  /// No description provided for @vpChecking.
  ///
  /// In de, this message translates to:
  /// **'Verbindung wird geprüft...'**
  String get vpChecking;

  /// No description provided for @vpDirectTitle.
  ///
  /// In de, this message translates to:
  /// **'Direkt getroffen!'**
  String get vpDirectTitle;

  /// No description provided for @vpDirectSub.
  ///
  /// In de, this message translates to:
  /// **'Ihr wart gemeinsam auf {count} Meetups.'**
  String vpDirectSub(Object count);

  /// No description provided for @vpDirectSubOne.
  ///
  /// In de, this message translates to:
  /// **'Ihr wart gemeinsam auf einem Meetup.'**
  String get vpDirectSubOne;

  /// No description provided for @vpIndirectTitle.
  ///
  /// In de, this message translates to:
  /// **'Über {count} Ecken verbunden'**
  String vpIndirectTitle(Object count);

  /// No description provided for @vpIndirectSub.
  ///
  /// In de, this message translates to:
  /// **'Diese Person ist über echte Meetup-Begegnungen mit dir verbunden.'**
  String get vpIndirectSub;

  /// No description provided for @vpNoneTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung gefunden'**
  String get vpNoneTitle;

  /// No description provided for @vpNoneSub.
  ///
  /// In de, this message translates to:
  /// **'Es gibt aktuell keine bekannte Meetup-Verbindung zu dir.'**
  String get vpNoneSub;

  /// No description provided for @vpNotInNetwork.
  ///
  /// In de, this message translates to:
  /// **'Diese Person nimmt (noch) nicht am Netzwerk teil.'**
  String get vpNotInNetwork;

  /// No description provided for @vpPathTitle.
  ///
  /// In de, this message translates to:
  /// **'Verbindungspfad'**
  String get vpPathTitle;

  /// No description provided for @vpYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get vpYou;

  /// No description provided for @vpTarget.
  ///
  /// In de, this message translates to:
  /// **'Diese Person'**
  String get vpTarget;

  /// No description provided for @vpMetAt.
  ///
  /// In de, this message translates to:
  /// **'gemeinsames Meetup'**
  String get vpMetAt;

  /// No description provided for @vpInvalidNpub.
  ///
  /// In de, this message translates to:
  /// **'Ungültiger npub'**
  String get vpInvalidNpub;

  /// No description provided for @vpTrustNote.
  ///
  /// In de, this message translates to:
  /// **'Je näher die Verbindung (kleinerer Grad), desto stärker das Vertrauen über physische Präsenz.'**
  String get vpTrustNote;

  /// No description provided for @vpSelfTitle.
  ///
  /// In de, this message translates to:
  /// **'Das bist du selbst'**
  String get vpSelfTitle;

  /// No description provided for @gpsRequired.
  ///
  /// In de, this message translates to:
  /// **'Standort erforderlich'**
  String get gpsRequired;

  /// No description provided for @gpsRequiredOrg.
  ///
  /// In de, this message translates to:
  /// **'Zum Erstellen eines Meetups wird dein Standort benötigt. Er legt den Ort des Meetups fest.'**
  String get gpsRequiredOrg;

  /// No description provided for @gpsRequiredScan.
  ///
  /// In de, this message translates to:
  /// **'Zum Sammeln dieses Badges wird dein Standort benötigt — als Nachweis, dass du vor Ort bist.'**
  String get gpsRequiredScan;

  /// No description provided for @gpsDenied.
  ///
  /// In de, this message translates to:
  /// **'Standortzugriff verweigert. Bitte in den Einstellungen erlauben.'**
  String get gpsDenied;

  /// No description provided for @gpsDisabled.
  ///
  /// In de, this message translates to:
  /// **'Standortdienste sind deaktiviert. Bitte aktivieren.'**
  String get gpsDisabled;

  /// No description provided for @gpsError.
  ///
  /// In de, this message translates to:
  /// **'Kein GPS-Signal erhalten. In Gebäuden dauert die Ortung oft länger – geh kurz ans Fenster oder vor die Tür und versuche es erneut.'**
  String get gpsError;

  /// No description provided for @gpsRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get gpsRetry;

  /// No description provided for @gpsPickMeetup.
  ///
  /// In de, this message translates to:
  /// **'Welches Meetup?'**
  String get gpsPickMeetup;

  /// No description provided for @gpsPickMeetupSub.
  ///
  /// In de, this message translates to:
  /// **'Mehrere Meetups sind in deiner Nähe. Bitte wähle das richtige.'**
  String get gpsPickMeetupSub;

  /// No description provided for @gpsDistanceKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km entfernt'**
  String gpsDistanceKm(Object km);

  /// No description provided for @gpsNoMeetupNearby.
  ///
  /// In de, this message translates to:
  /// **'Kein bekanntes Meetup in der Nähe gefunden.'**
  String get gpsNoMeetupNearby;

  /// No description provided for @gpsTooFar.
  ///
  /// In de, this message translates to:
  /// **'Zu weit entfernt'**
  String get gpsTooFar;

  /// No description provided for @gpsTooFarSub.
  ///
  /// In de, this message translates to:
  /// **'Du bist {km} km vom Meetup-Ort entfernt. Badges können nur vor Ort gesammelt werden (max. {max} km).'**
  String gpsTooFarSub(Object km, Object max);

  /// No description provided for @mapTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Badge-Weltkarte'**
  String get mapTitle;

  /// No description provided for @mapButton.
  ///
  /// In de, this message translates to:
  /// **'Auf der Karte ansehen'**
  String get mapButton;

  /// No description provided for @mapStatMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get mapStatMeetups;

  /// No description provided for @mapStatCities.
  ///
  /// In de, this message translates to:
  /// **'Städte'**
  String get mapStatCities;

  /// No description provided for @mapStatCountries.
  ///
  /// In de, this message translates to:
  /// **'Länder'**
  String get mapStatCountries;

  /// No description provided for @mapShareText.
  ///
  /// In de, this message translates to:
  /// **'Hier war ich überall! 🌍 {count} Meetups auf meiner Einundzwanzig Badge-Weltkarte.'**
  String mapShareText(Object count);

  /// No description provided for @mapShareButton.
  ///
  /// In de, this message translates to:
  /// **'Als Bild teilen'**
  String get mapShareButton;

  /// No description provided for @mapEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Badges mit Standort'**
  String get mapEmpty;

  /// No description provided for @mapEmptySub.
  ///
  /// In de, this message translates to:
  /// **'Sammle Badges auf Meetups — sie erscheinen dann hier auf deiner Weltkarte.'**
  String get mapEmptySub;

  /// No description provided for @gpsNoMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Meetup in der Nähe'**
  String get gpsNoMeetupTitle;

  /// No description provided for @gpsNoMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Im Umkreis von 10 km ist kein bekanntes Meetup eingetragen. Du kannst trotzdem eine Session starten — gib deinem Meetup einen Titel. Dein aktueller Standort wird automatisch als Veranstaltungsort auf der Karte gesetzt.'**
  String get gpsNoMeetupBody;

  /// No description provided for @gpsMeetupNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Titel des Meetups'**
  String get gpsMeetupNameLabel;

  /// No description provided for @gpsMeetupNameHint.
  ///
  /// In de, this message translates to:
  /// **'z. B. Bitcoin Stammtisch'**
  String get gpsMeetupNameHint;

  /// No description provided for @gpsStartAnyway.
  ///
  /// In de, this message translates to:
  /// **'Session starten'**
  String get gpsStartAnyway;

  /// No description provided for @gpsNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Namen ein.'**
  String get gpsNameRequired;

  /// No description provided for @mnNodeDetailTitle.
  ///
  /// In de, this message translates to:
  /// **'Verknüpfung'**
  String get mnNodeDetailTitle;

  /// No description provided for @mnDegreeDirect.
  ///
  /// In de, this message translates to:
  /// **'Direkt verbunden'**
  String get mnDegreeDirect;

  /// No description provided for @mnDegreeSecond.
  ///
  /// In de, this message translates to:
  /// **'2. Grad'**
  String get mnDegreeSecond;

  /// No description provided for @mnDegreeThird.
  ///
  /// In de, this message translates to:
  /// **'3. Grad'**
  String get mnDegreeThird;

  /// No description provided for @mnSharedMeetupsList.
  ///
  /// In de, this message translates to:
  /// **'Gemeinsame Meetups'**
  String get mnSharedMeetupsList;

  /// No description provided for @mnViaBridges.
  ///
  /// In de, this message translates to:
  /// **'Verbunden über'**
  String get mnViaBridges;

  /// No description provided for @mnNoSharedDetail.
  ///
  /// In de, this message translates to:
  /// **'Keine direkten gemeinsamen Meetups'**
  String get mnNoSharedDetail;

  /// No description provided for @mnOpenInNostr.
  ///
  /// In de, this message translates to:
  /// **'In Nostr öffnen'**
  String get mnOpenInNostr;

  /// No description provided for @mnTapHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf einen Punkt für Details'**
  String get mnTapHint;

  /// No description provided for @mnLegendDirect.
  ///
  /// In de, this message translates to:
  /// **'Direkt (1. Grad)'**
  String get mnLegendDirect;

  /// No description provided for @mnLegendSecond.
  ///
  /// In de, this message translates to:
  /// **'2. Grad'**
  String get mnLegendSecond;

  /// No description provided for @mnLegendThird.
  ///
  /// In de, this message translates to:
  /// **'3. Grad'**
  String get mnLegendThird;

  /// No description provided for @resetBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Daten sichern?'**
  String get resetBackupTitle;

  /// No description provided for @resetBackupBody.
  ///
  /// In de, this message translates to:
  /// **'Beim Zurücksetzen werden ALLE Daten unwiderruflich gelöscht — deine Badges, dein Schlüssel und dein Profil. Ohne Backup lassen sich Badges NICHT wiederherstellen (auch nicht über Nostr). Möchtest du zuerst ein Backup erstellen?'**
  String get resetBackupBody;

  /// No description provided for @resetBackupCreate.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellen'**
  String get resetBackupCreate;

  /// No description provided for @resetBackupSkip.
  ///
  /// In de, this message translates to:
  /// **'Ohne Backup zurücksetzen'**
  String get resetBackupSkip;

  /// No description provided for @resetBackupDone.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellt. Jetzt zurücksetzen?'**
  String get resetBackupDone;

  /// No description provided for @resetNowConfirm.
  ///
  /// In de, this message translates to:
  /// **'Jetzt zurücksetzen'**
  String get resetNowConfirm;

  /// No description provided for @verifyBadgeSaved.
  ///
  /// In de, this message translates to:
  /// **'Badge gespeichert ✓'**
  String get verifyBadgeSaved;

  /// No description provided for @tileConverter.
  ///
  /// In de, this message translates to:
  /// **'Rechner'**
  String get tileConverter;

  /// No description provided for @tileConverterSub.
  ///
  /// In de, this message translates to:
  /// **'Kurs & Sats'**
  String get tileConverterSub;

  /// No description provided for @convTitle.
  ///
  /// In de, this message translates to:
  /// **'Wechselrechner'**
  String get convTitle;

  /// No description provided for @convYouPay.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get convYouPay;

  /// No description provided for @convRateInfo.
  ///
  /// In de, this message translates to:
  /// **'1 BTC = {price} {cur}'**
  String convRateInfo(Object price, Object cur);

  /// No description provided for @convUpdated.
  ///
  /// In de, this message translates to:
  /// **'Aktualisiert: {time}'**
  String convUpdated(Object time);

  /// No description provided for @convRefresh.
  ///
  /// In de, this message translates to:
  /// **'Kurs aktualisieren'**
  String get convRefresh;

  /// No description provided for @convOffline.
  ///
  /// In de, this message translates to:
  /// **'Kurs konnte nicht geladen werden. Bist du online?'**
  String get convOffline;

  /// No description provided for @convLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Kurs …'**
  String get convLoading;

  /// No description provided for @convSwap.
  ///
  /// In de, this message translates to:
  /// **'Tauschen'**
  String get convSwap;

  /// No description provided for @convSelectCurrency.
  ///
  /// In de, this message translates to:
  /// **'Währung wählen'**
  String get convSelectCurrency;

  /// No description provided for @convUnitSats.
  ///
  /// In de, this message translates to:
  /// **'Satoshi'**
  String get convUnitSats;

  /// No description provided for @convUnitBtc.
  ///
  /// In de, this message translates to:
  /// **'Bitcoin'**
  String get convUnitBtc;

  /// No description provided for @convSource.
  ///
  /// In de, this message translates to:
  /// **'Kurs von mempool.space'**
  String get convSource;

  /// No description provided for @tileNews.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get tileNews;

  /// No description provided for @tileNewsSub.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig Artikel lesen'**
  String get tileNewsSub;

  /// No description provided for @newsTitle.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get newsTitle;

  /// No description provided for @newsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Keine Artikel gefunden.'**
  String get newsEmpty;

  /// No description provided for @newsLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Artikel …'**
  String get newsLoading;

  /// No description provided for @newsRefresh.
  ///
  /// In de, this message translates to:
  /// **'Aktualisieren'**
  String get newsRefresh;

  /// No description provided for @newsSource.
  ///
  /// In de, this message translates to:
  /// **'Artikel via Nostr (NIP-23)'**
  String get newsSource;

  /// No description provided for @newsOpenWebsite.
  ///
  /// In de, this message translates to:
  /// **'Auf der Webseite öffnen'**
  String get newsOpenWebsite;

  /// No description provided for @keyEduTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Schlüssel zu Nostr'**
  String get keyEduTitle;

  /// No description provided for @keyEduWhatNostrH.
  ///
  /// In de, this message translates to:
  /// **'Was ist Nostr?'**
  String get keyEduWhatNostrH;

  /// No description provided for @keyEduWhatNostrB.
  ///
  /// In de, this message translates to:
  /// **'Nostr ist ein offenes, dezentrales Netzwerk – ähnlich wie das Internet selbst, aber für soziale Identität. Es gehört niemandem. Es gibt keine Firma, keinen Account und kein Passwort im klassischen Sinn. Statt dich bei einem Anbieter anzumelden, besitzt du einen kryptografischen Schlüssel, der dich überall im Netzwerk ausweist.'**
  String get keyEduWhatNostrB;

  /// No description provided for @keyEduPairH.
  ///
  /// In de, this message translates to:
  /// **'Dein Schlüsselpaar'**
  String get keyEduPairH;

  /// No description provided for @keyEduPairB.
  ///
  /// In de, this message translates to:
  /// **'Du bekommst gleich zwei zusammengehörige Schlüssel. Sie funktionieren wie ein Briefkasten: Der öffentliche Schlüssel ist die Adresse, die du jedem geben darfst – der private Schlüssel ist der einzige Schlüssel, der den Briefkasten öffnet.'**
  String get keyEduPairB;

  /// No description provided for @keyEduNpubH.
  ///
  /// In de, this message translates to:
  /// **'npub – dein öffentlicher Schlüssel'**
  String get keyEduNpubH;

  /// No description provided for @keyEduNpubB.
  ///
  /// In de, this message translates to:
  /// **'Der npub (beginnt mit „npub1…“) ist deine öffentliche Identität. Du darfst ihn frei teilen – so finden dich andere, sehen deine Beiträge und können dir folgen. Er ist wie dein Benutzername, nur dass er dir wirklich gehört und niemand ihn dir wegnehmen kann.'**
  String get keyEduNpubB;

  /// No description provided for @webKeyWarnH.
  ///
  /// In de, this message translates to:
  /// **'Im Browser weniger geschützt'**
  String get webKeyWarnH;

  /// No description provided for @webKeyWarnB.
  ///
  /// In de, this message translates to:
  /// **'Die App für iPhone und Android speichert deinen Schlüssel im gesicherten Bereich des Geräts. Im Browser ist das nicht möglich — dort kann er leichter ausgelesen werden.'**
  String get webKeyWarnB;

  /// No description provided for @webKeyWarnAdvice.
  ///
  /// In de, this message translates to:
  /// **'Nutze im Browser am besten eine eigene Test-Identität und trage hier nicht den Schlüssel ein, an dem deine Nostr-Identität hängt.'**
  String get webKeyWarnAdvice;

  /// No description provided for @keyEduNsecH.
  ///
  /// In de, this message translates to:
  /// **'nsec – dein privater Schlüssel'**
  String get keyEduNsecH;

  /// No description provided for @keyEduNsecB.
  ///
  /// In de, this message translates to:
  /// **'Der nsec (beginnt mit „nsec1…“) ist dein Geheimnis. Wer ihn besitzt, IST du – er kann in deinem Namen posten, deine Identität übernehmen und deine Reputation missbrauchen. Gib ihn NIEMALS weiter, tippe ihn nirgends ein, wo du unsicher bist, und mache niemals ein Foto davon in einer Cloud. Es gibt kein „Passwort vergessen“: Ist der nsec weg, ist die Identität für immer verloren.'**
  String get keyEduNsecB;

  /// No description provided for @keyEduIdentityH.
  ///
  /// In de, this message translates to:
  /// **'Eine Identität, viele Möglichkeiten'**
  String get keyEduIdentityH;

  /// No description provided for @keyEduIdentityB.
  ///
  /// In de, this message translates to:
  /// **'Dieses Schlüsselpaar ist nicht nur für diese App. Es ist deine Identität im gesamten Nostr-Netzwerk: dieselbe Identität kannst du in vielen anderen Nostr-Apps nutzen – für soziale Netzwerke, Blogs, Chats, Lightning-Zahlungen und mehr. In dieser App ist sie zusätzlich mit deiner Reputation, deinen Meetup-Badges und deinem Vertrauensnetzwerk verknüpft. Deshalb ist ihr Schutz so wichtig: Verlierst du den Schlüssel, verlierst du nicht nur einen Login, sondern alles, was du dir aufgebaut hast.'**
  String get keyEduIdentityB;

  /// No description provided for @keyEduProtectH.
  ///
  /// In de, this message translates to:
  /// **'So schützt du deinen Schlüssel'**
  String get keyEduProtectH;

  /// No description provided for @keyEduProtect1.
  ///
  /// In de, this message translates to:
  /// **'Sichere den nsec sofort (z. B. in einem Passwort-Manager).'**
  String get keyEduProtect1;

  /// No description provided for @keyEduProtect2.
  ///
  /// In de, this message translates to:
  /// **'Teile nur den npub – niemals den nsec.'**
  String get keyEduProtect2;

  /// No description provided for @keyEduProtect3.
  ///
  /// In de, this message translates to:
  /// **'Lege ein verschlüsseltes Backup an (in dieser App möglich).'**
  String get keyEduProtect3;

  /// No description provided for @keyEduProtect4.
  ///
  /// In de, this message translates to:
  /// **'Für mehr Sicherheit: nutze eine Signer-App wie Amber.'**
  String get keyEduProtect4;

  /// No description provided for @keyEduUnderstood.
  ///
  /// In de, this message translates to:
  /// **'Verstanden, Schlüssel erstellen'**
  String get keyEduUnderstood;

  /// No description provided for @keyEduCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get keyEduCancel;

  /// No description provided for @keyEduIntro.
  ///
  /// In de, this message translates to:
  /// **'Bevor du startest: Gleich erhältst du dein eigenes Schlüsselpaar. Nimm dir kurz Zeit – es lohnt sich zu verstehen, was du da bekommst.'**
  String get keyEduIntro;

  /// No description provided for @tilePortal.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get tilePortal;

  /// No description provided for @tilePortalSub.
  ///
  /// In de, this message translates to:
  /// **'Termine im Portal verwalten'**
  String get tilePortalSub;

  /// No description provided for @portalTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get portalTitle;

  /// No description provided for @portalNotConnected.
  ///
  /// In de, this message translates to:
  /// **'Mit dem Portal verbinden'**
  String get portalNotConnected;

  /// No description provided for @portalConnectInfo.
  ///
  /// In de, this message translates to:
  /// **'Melde dich mit deinem Nostr-Schlüssel am Einundzwanzig-Portal an, um deine Meetup-Termine direkt aus der App zu verwalten.'**
  String get portalConnectInfo;

  /// No description provided for @portalConnect.
  ///
  /// In de, this message translates to:
  /// **'Anmelden'**
  String get portalConnect;

  /// No description provided for @portalConnecting.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung läuft …'**
  String get portalConnecting;

  /// No description provided for @portalLogout.
  ///
  /// In de, this message translates to:
  /// **'Abmelden'**
  String get portalLogout;

  /// No description provided for @portalLoginFailed.
  ///
  /// In de, this message translates to:
  /// **'Anmeldung fehlgeschlagen'**
  String get portalLoginFailed;

  /// No description provided for @portalLoadingMeetups.
  ///
  /// In de, this message translates to:
  /// **'Lade deine Meetups …'**
  String get portalLoadingMeetups;

  /// No description provided for @portalNoMeetups.
  ///
  /// In de, this message translates to:
  /// **'Du verwaltest noch keine Meetups im Portal.'**
  String get portalNoMeetups;

  /// No description provided for @portalLeader.
  ///
  /// In de, this message translates to:
  /// **'Organisator'**
  String get portalLeader;

  /// No description provided for @portalNewEvent.
  ///
  /// In de, this message translates to:
  /// **'Termin anlegen'**
  String get portalNewEvent;

  /// No description provided for @portalEventTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuer Termin'**
  String get portalEventTitle;

  /// No description provided for @portalFieldStart.
  ///
  /// In de, this message translates to:
  /// **'Datum & Uhrzeit'**
  String get portalFieldStart;

  /// No description provided for @portalPickDate.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get portalPickDate;

  /// No description provided for @portalPickTime.
  ///
  /// In de, this message translates to:
  /// **'Uhrzeit wählen'**
  String get portalPickTime;

  /// No description provided for @portalFieldLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get portalFieldLocation;

  /// No description provided for @portalFieldLocationHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Bitcoin-Treff Café (optional)'**
  String get portalFieldLocationHint;

  /// No description provided for @portalFieldDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get portalFieldDescription;

  /// No description provided for @portalFieldDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'Worum geht es? (optional)'**
  String get portalFieldDescriptionHint;

  /// No description provided for @portalFieldLink.
  ///
  /// In de, this message translates to:
  /// **'Link'**
  String get portalFieldLink;

  /// No description provided for @portalFieldLinkHint.
  ///
  /// In de, this message translates to:
  /// **'https://… (optional)'**
  String get portalFieldLinkHint;

  /// No description provided for @portalSave.
  ///
  /// In de, this message translates to:
  /// **'Termin speichern'**
  String get portalSave;

  /// No description provided for @portalSaving.
  ///
  /// In de, this message translates to:
  /// **'Wird gespeichert …'**
  String get portalSaving;

  /// No description provided for @portalCreatedOk.
  ///
  /// In de, this message translates to:
  /// **'Termin angelegt ✓'**
  String get portalCreatedOk;

  /// No description provided for @portalNeedStart.
  ///
  /// In de, this message translates to:
  /// **'Bitte Datum & Uhrzeit wählen.'**
  String get portalNeedStart;

  /// No description provided for @portalSource.
  ///
  /// In de, this message translates to:
  /// **'Verbunden mit portal.einundzwanzig.space'**
  String get portalSource;

  /// No description provided for @evCalendarButton.
  ///
  /// In de, this message translates to:
  /// **'Veranstaltungskalender'**
  String get evCalendarButton;

  /// No description provided for @evCalendarButtonSub.
  ///
  /// In de, this message translates to:
  /// **'Alle Events im Überblick'**
  String get evCalendarButtonSub;

  /// No description provided for @calTitle.
  ///
  /// In de, this message translates to:
  /// **'Veranstaltungskalender'**
  String get calTitle;

  /// No description provided for @calViewMonth.
  ///
  /// In de, this message translates to:
  /// **'Monat'**
  String get calViewMonth;

  /// No description provided for @calViewYear.
  ///
  /// In de, this message translates to:
  /// **'Jahr'**
  String get calViewYear;

  /// No description provided for @calViewList.
  ///
  /// In de, this message translates to:
  /// **'Liste'**
  String get calViewList;

  /// No description provided for @calToday.
  ///
  /// In de, this message translates to:
  /// **'Heute'**
  String get calToday;

  /// No description provided for @calNoEvents.
  ///
  /// In de, this message translates to:
  /// **'Keine Veranstaltungen an diesem Tag.'**
  String get calNoEvents;

  /// No description provided for @calNoEventsRange.
  ///
  /// In de, this message translates to:
  /// **'Keine Veranstaltungen in diesem Zeitraum.'**
  String get calNoEventsRange;

  /// No description provided for @calLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Veranstaltungen …'**
  String get calLoading;

  /// No description provided for @calAddEvent.
  ///
  /// In de, this message translates to:
  /// **'Event eintragen'**
  String get calAddEvent;

  /// No description provided for @calAllDay.
  ///
  /// In de, this message translates to:
  /// **'Ganztägig'**
  String get calAllDay;

  /// No description provided for @calSource.
  ///
  /// In de, this message translates to:
  /// **'Events via Nostr (NIP-52)'**
  String get calSource;

  /// No description provided for @calNewEventTitle.
  ///
  /// In de, this message translates to:
  /// **'Veranstaltung eintragen'**
  String get calNewEventTitle;

  /// No description provided for @calFieldTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel'**
  String get calFieldTitle;

  /// No description provided for @calFieldTitleHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. BTC Prag, Zitadelle …'**
  String get calFieldTitleHint;

  /// No description provided for @calFieldLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get calFieldLocation;

  /// No description provided for @calFieldLocationHint.
  ///
  /// In de, this message translates to:
  /// **'z.B. Prag, Tschechien'**
  String get calFieldLocationHint;

  /// No description provided for @calFieldDescription.
  ///
  /// In de, this message translates to:
  /// **'Beschreibung'**
  String get calFieldDescription;

  /// No description provided for @calFieldDescriptionHint.
  ///
  /// In de, this message translates to:
  /// **'Worum geht es? (optional)'**
  String get calFieldDescriptionHint;

  /// No description provided for @calFieldAllDay.
  ///
  /// In de, this message translates to:
  /// **'Ganztägige Veranstaltung'**
  String get calFieldAllDay;

  /// No description provided for @calFieldStart.
  ///
  /// In de, this message translates to:
  /// **'Beginn'**
  String get calFieldStart;

  /// No description provided for @calFieldEnd.
  ///
  /// In de, this message translates to:
  /// **'Ende (optional)'**
  String get calFieldEnd;

  /// No description provided for @calPickDateTime.
  ///
  /// In de, this message translates to:
  /// **'Datum & Uhrzeit wählen'**
  String get calPickDateTime;

  /// No description provided for @calPickDate.
  ///
  /// In de, this message translates to:
  /// **'Datum wählen'**
  String get calPickDate;

  /// No description provided for @calClearEnd.
  ///
  /// In de, this message translates to:
  /// **'Ende entfernen'**
  String get calClearEnd;

  /// No description provided for @calPublish.
  ///
  /// In de, this message translates to:
  /// **'Bei Nostr veröffentlichen'**
  String get calPublish;

  /// No description provided for @calPublishing.
  ///
  /// In de, this message translates to:
  /// **'Wird veröffentlicht …'**
  String get calPublishing;

  /// No description provided for @calPublishFail.
  ///
  /// In de, this message translates to:
  /// **'Veröffentlichung fehlgeschlagen. Online & angemeldet?'**
  String get calPublishFail;

  /// No description provided for @calNeedTitle.
  ///
  /// In de, this message translates to:
  /// **'Bitte gib einen Titel ein.'**
  String get calNeedTitle;

  /// No description provided for @calNeedStart.
  ///
  /// In de, this message translates to:
  /// **'Bitte Beginn wählen.'**
  String get calNeedStart;

  /// No description provided for @calPublishInfo.
  ///
  /// In de, this message translates to:
  /// **'Diese Veranstaltung wird öffentlich bei Nostr eingetragen – jeder mit dieser App sieht sie in seinem Kalender.'**
  String get calPublishInfo;

  /// No description provided for @calMonth1.
  ///
  /// In de, this message translates to:
  /// **'Januar'**
  String get calMonth1;

  /// No description provided for @calMonth2.
  ///
  /// In de, this message translates to:
  /// **'Februar'**
  String get calMonth2;

  /// No description provided for @calMonth3.
  ///
  /// In de, this message translates to:
  /// **'März'**
  String get calMonth3;

  /// No description provided for @calMonth4.
  ///
  /// In de, this message translates to:
  /// **'April'**
  String get calMonth4;

  /// No description provided for @calMonth5.
  ///
  /// In de, this message translates to:
  /// **'Mai'**
  String get calMonth5;

  /// No description provided for @calMonth6.
  ///
  /// In de, this message translates to:
  /// **'Juni'**
  String get calMonth6;

  /// No description provided for @calMonth7.
  ///
  /// In de, this message translates to:
  /// **'Juli'**
  String get calMonth7;

  /// No description provided for @calMonth8.
  ///
  /// In de, this message translates to:
  /// **'August'**
  String get calMonth8;

  /// No description provided for @calMonth9.
  ///
  /// In de, this message translates to:
  /// **'September'**
  String get calMonth9;

  /// No description provided for @calMonth10.
  ///
  /// In de, this message translates to:
  /// **'Oktober'**
  String get calMonth10;

  /// No description provided for @calMonth11.
  ///
  /// In de, this message translates to:
  /// **'November'**
  String get calMonth11;

  /// No description provided for @calMonth12.
  ///
  /// In de, this message translates to:
  /// **'Dezember'**
  String get calMonth12;

  /// No description provided for @calWd0.
  ///
  /// In de, this message translates to:
  /// **'Mo'**
  String get calWd0;

  /// No description provided for @calWd1.
  ///
  /// In de, this message translates to:
  /// **'Di'**
  String get calWd1;

  /// No description provided for @calWd2.
  ///
  /// In de, this message translates to:
  /// **'Mi'**
  String get calWd2;

  /// No description provided for @calWd3.
  ///
  /// In de, this message translates to:
  /// **'Do'**
  String get calWd3;

  /// No description provided for @calWd4.
  ///
  /// In de, this message translates to:
  /// **'Fr'**
  String get calWd4;

  /// No description provided for @calWd5.
  ///
  /// In de, this message translates to:
  /// **'Sa'**
  String get calWd5;

  /// No description provided for @calWd6.
  ///
  /// In de, this message translates to:
  /// **'So'**
  String get calWd6;

  /// No description provided for @calTypeMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup'**
  String get calTypeMeetup;

  /// No description provided for @calTypeEvent.
  ///
  /// In de, this message translates to:
  /// **'Event'**
  String get calTypeEvent;

  /// No description provided for @calLegendMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get calLegendMeetup;

  /// No description provided for @calLegendEvent.
  ///
  /// In de, this message translates to:
  /// **'Veranstaltungen'**
  String get calLegendEvent;

  /// No description provided for @portalManageEvents.
  ///
  /// In de, this message translates to:
  /// **'Termine verwalten'**
  String get portalManageEvents;

  /// No description provided for @portalExistingEvents.
  ///
  /// In de, this message translates to:
  /// **'Bestehende Termine'**
  String get portalExistingEvents;

  /// No description provided for @portalLoadingEvents.
  ///
  /// In de, this message translates to:
  /// **'Lade Termine …'**
  String get portalLoadingEvents;

  /// No description provided for @portalNoEvents.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Termine für dieses Meetup.'**
  String get portalNoEvents;

  /// No description provided for @portalEditEvent.
  ///
  /// In de, this message translates to:
  /// **'Termin bearbeiten'**
  String get portalEditEvent;

  /// No description provided for @portalUpdatedOk.
  ///
  /// In de, this message translates to:
  /// **'Termin aktualisiert ✓'**
  String get portalUpdatedOk;

  /// No description provided for @portalUpdate.
  ///
  /// In de, this message translates to:
  /// **'Änderungen speichern'**
  String get portalUpdate;

  /// No description provided for @portalTapToEdit.
  ///
  /// In de, this message translates to:
  /// **'Zum Bearbeiten antippen'**
  String get portalTapToEdit;

  /// No description provided for @hubTitle.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get hubTitle;

  /// No description provided for @hubMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get hubMeetups;

  /// No description provided for @hubMeetupsSub.
  ///
  /// In de, this message translates to:
  /// **'Meetups suchen & entdecken'**
  String get hubMeetupsSub;

  /// No description provided for @hubCalendar.
  ///
  /// In de, this message translates to:
  /// **'Veranstaltungskalender'**
  String get hubCalendar;

  /// No description provided for @hubCalendarSub.
  ///
  /// In de, this message translates to:
  /// **'Alle Termine im Überblick, farblich sortiert'**
  String get hubCalendarSub;

  /// No description provided for @hubExternal.
  ///
  /// In de, this message translates to:
  /// **'Externe Termine'**
  String get hubExternal;

  /// No description provided for @hubExternalSub.
  ///
  /// In de, this message translates to:
  /// **'Konferenzen & Events der Community'**
  String get hubExternalSub;

  /// No description provided for @extTitle.
  ///
  /// In de, this message translates to:
  /// **'Externe Termine'**
  String get extTitle;

  /// No description provided for @extIntro.
  ///
  /// In de, this message translates to:
  /// **'Von der Community eingetragene Veranstaltungen (keine Meetups) – z.B. Konferenzen wie die BTC Prag oder die Zitadelle.'**
  String get extIntro;

  /// No description provided for @extLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade externe Termine …'**
  String get extLoading;

  /// No description provided for @extNone.
  ///
  /// In de, this message translates to:
  /// **'Noch keine externen Termine eingetragen.'**
  String get extNone;

  /// No description provided for @extAdd.
  ///
  /// In de, this message translates to:
  /// **'Event eintragen'**
  String get extAdd;

  /// No description provided for @calFilterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get calFilterAll;

  /// No description provided for @calFilterMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get calFilterMeetups;

  /// No description provided for @calFilterExternal.
  ///
  /// In de, this message translates to:
  /// **'Externe'**
  String get calFilterExternal;

  /// No description provided for @calFilterLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort/Land suchen …'**
  String get calFilterLocation;

  /// No description provided for @calFilterActive.
  ///
  /// In de, this message translates to:
  /// **'Filter aktiv'**
  String get calFilterActive;

  /// No description provided for @calFilterClear.
  ///
  /// In de, this message translates to:
  /// **'Filter zurücksetzen'**
  String get calFilterClear;

  /// No description provided for @calFilterNoMatch.
  ///
  /// In de, this message translates to:
  /// **'Keine Events für diesen Filter.'**
  String get calFilterNoMatch;

  /// No description provided for @calWorldwide.
  ///
  /// In de, this message translates to:
  /// **'Weltweit'**
  String get calWorldwide;

  /// No description provided for @calCommunityOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Community'**
  String get calCommunityOnly;

  /// No description provided for @calWorldwideHint.
  ///
  /// In de, this message translates to:
  /// **'Weltweit zeigt alle Nostr-Events – auch fremde.'**
  String get calWorldwideHint;

  /// No description provided for @chTitle.
  ///
  /// In de, this message translates to:
  /// **'Community'**
  String get chTitle;

  /// No description provided for @chPortal.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get chPortal;

  /// No description provided for @chPortalSub.
  ///
  /// In de, this message translates to:
  /// **'Meetups · Events · Kurse · Karte'**
  String get chPortalSub;

  /// No description provided for @chNews.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get chNews;

  /// No description provided for @chNewsSub.
  ///
  /// In de, this message translates to:
  /// **'Artikel lesen'**
  String get chNewsSub;

  /// No description provided for @chNostr.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get chNostr;

  /// No description provided for @chNostrSub.
  ///
  /// In de, this message translates to:
  /// **'Community-Feed'**
  String get chNostrSub;

  /// No description provided for @chShoutout.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get chShoutout;

  /// No description provided for @chShoutoutSub.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get chShoutoutSub;

  /// No description provided for @chPodcast.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get chPodcast;

  /// No description provided for @chPodcastSub.
  ///
  /// In de, this message translates to:
  /// **'Anhören'**
  String get chPodcastSub;

  /// No description provided for @paTitle.
  ///
  /// In de, this message translates to:
  /// **'Portal'**
  String get paTitle;

  /// No description provided for @paMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meetups'**
  String get paMeetups;

  /// No description provided for @paMeetupsSub.
  ///
  /// In de, this message translates to:
  /// **'Alle Meetups durchsuchen'**
  String get paMeetupsSub;

  /// No description provided for @paEvents.
  ///
  /// In de, this message translates to:
  /// **'Events & Zusagen'**
  String get paEvents;

  /// No description provided for @paEventsSub.
  ///
  /// In de, this message translates to:
  /// **'Termine ansehen und direkt zusagen'**
  String get paEventsSub;

  /// No description provided for @paCourses.
  ///
  /// In de, this message translates to:
  /// **'Kurse & Dozenten'**
  String get paCourses;

  /// No description provided for @paCoursesSub.
  ///
  /// In de, this message translates to:
  /// **'Das Einundzwanzig-Bildungsangebot'**
  String get paCoursesSub;

  /// No description provided for @paMap.
  ///
  /// In de, this message translates to:
  /// **'Karte'**
  String get paMap;

  /// No description provided for @paMapSub.
  ///
  /// In de, this message translates to:
  /// **'Meetups in der Nähe'**
  String get paMapSub;

  /// No description provided for @paMine.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get paMine;

  /// No description provided for @paMineSub.
  ///
  /// In de, this message translates to:
  /// **'Termine verwalten (Organisator)'**
  String get paMineSub;

  /// No description provided for @paWeb.
  ///
  /// In de, this message translates to:
  /// **'Portal-Webseite'**
  String get paWeb;

  /// No description provided for @paWebSub.
  ///
  /// In de, this message translates to:
  /// **'portal.einundzwanzig.space im Browser'**
  String get paWebSub;

  /// No description provided for @rsvpLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Events …'**
  String get rsvpLoading;

  /// No description provided for @rsvpNone.
  ///
  /// In de, this message translates to:
  /// **'Keine kommenden Events gefunden.'**
  String get rsvpNone;

  /// No description provided for @rsvpGoing.
  ///
  /// In de, this message translates to:
  /// **'Zusagen'**
  String get rsvpGoing;

  /// No description provided for @rsvpYouGo.
  ///
  /// In de, this message translates to:
  /// **'Du hast zugesagt ✓'**
  String get rsvpYouGo;

  /// No description provided for @rsvpCount.
  ///
  /// In de, this message translates to:
  /// **'Zusagen'**
  String get rsvpCount;

  /// No description provided for @rsvpNeedLogin.
  ///
  /// In de, this message translates to:
  /// **'Zum Zusagen bitte zuerst im Portal anmelden (Meine Meetups).'**
  String get rsvpNeedLogin;

  /// No description provided for @rsvpFailed.
  ///
  /// In de, this message translates to:
  /// **'Antwort nicht gespeichert: {msg}'**
  String rsvpFailed(String msg);

  /// No description provided for @crsLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Kurse …'**
  String get crsLoading;

  /// No description provided for @crsNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Kurse gefunden.'**
  String get crsNone;

  /// No description provided for @crsCourses.
  ///
  /// In de, this message translates to:
  /// **'Kurse'**
  String get crsCourses;

  /// No description provided for @crsLecturers.
  ///
  /// In de, this message translates to:
  /// **'Dozenten'**
  String get crsLecturers;

  /// No description provided for @rsvpCancel.
  ///
  /// In de, this message translates to:
  /// **'Absagen'**
  String get rsvpCancel;

  /// No description provided for @crsAbout.
  ///
  /// In de, this message translates to:
  /// **'Über den Kurs'**
  String get crsAbout;

  /// No description provided for @crsUpcoming.
  ///
  /// In de, this message translates to:
  /// **'Kommende Termine'**
  String get crsUpcoming;

  /// No description provided for @crsLecturer.
  ///
  /// In de, this message translates to:
  /// **'Referent'**
  String get crsLecturer;

  /// No description provided for @lecAbout.
  ///
  /// In de, this message translates to:
  /// **'Über den Referenten'**
  String get lecAbout;

  /// No description provided for @lecLinks.
  ///
  /// In de, this message translates to:
  /// **'Links'**
  String get lecLinks;

  /// No description provided for @crsOpenPortal.
  ///
  /// In de, this message translates to:
  /// **'Im Portal öffnen'**
  String get crsOpenPortal;

  /// No description provided for @rsvpImComing.
  ///
  /// In de, this message translates to:
  /// **'Ich komme'**
  String get rsvpImComing;

  /// No description provided for @rsvpMaybe.
  ///
  /// In de, this message translates to:
  /// **'Vielleicht'**
  String get rsvpMaybe;

  /// No description provided for @evOpenLink.
  ///
  /// In de, this message translates to:
  /// **'Link öffnen'**
  String get evOpenLink;

  /// No description provided for @evShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get evShare;

  /// No description provided for @evToCalendar.
  ///
  /// In de, this message translates to:
  /// **'Zum Kalender'**
  String get evToCalendar;

  /// No description provided for @portalConnected.
  ///
  /// In de, this message translates to:
  /// **'Portal verbunden'**
  String get portalConnected;

  /// No description provided for @portalLoginPrompt.
  ///
  /// In de, this message translates to:
  /// **'Zum Zusagen verbinden wir dich mit dem Portal.'**
  String get portalLoginPrompt;

  /// No description provided for @portalTileSub.
  ///
  /// In de, this message translates to:
  /// **'Für Zusagen & eigene Meetups'**
  String get portalTileSub;

  /// No description provided for @ldTitle.
  ///
  /// In de, this message translates to:
  /// **'Organisatoren'**
  String get ldTitle;

  /// No description provided for @ldManage.
  ///
  /// In de, this message translates to:
  /// **'Organisatoren verwalten'**
  String get ldManage;

  /// No description provided for @ldManageSub.
  ///
  /// In de, this message translates to:
  /// **'Vertraute als Leader hinzufügen'**
  String get ldManageSub;

  /// No description provided for @ldPickMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup wählen'**
  String get ldPickMeetup;

  /// No description provided for @ldCreator.
  ///
  /// In de, this message translates to:
  /// **'Ersteller'**
  String get ldCreator;

  /// No description provided for @ldAdd.
  ///
  /// In de, this message translates to:
  /// **'Organisator hinzufügen'**
  String get ldAdd;

  /// No description provided for @ldAddHint.
  ///
  /// In de, this message translates to:
  /// **'npub des neuen Organisators'**
  String get ldAddHint;

  /// No description provided for @ldAddDo.
  ///
  /// In de, this message translates to:
  /// **'Hinzufügen'**
  String get ldAddDo;

  /// No description provided for @ldRemove.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get ldRemove;

  /// No description provided for @ldRemoveConfirm.
  ///
  /// In de, this message translates to:
  /// **'Diesen Organisator entfernen?'**
  String get ldRemoveConfirm;

  /// No description provided for @ldAdded.
  ///
  /// In de, this message translates to:
  /// **'Organisator hinzugefügt'**
  String get ldAdded;

  /// No description provided for @ldRemoved.
  ///
  /// In de, this message translates to:
  /// **'Organisator entfernt'**
  String get ldRemoved;

  /// No description provided for @ldFailed.
  ///
  /// In de, this message translates to:
  /// **'Aktion fehlgeschlagen'**
  String get ldFailed;

  /// No description provided for @ldEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine weiteren Organisatoren.'**
  String get ldEmpty;

  /// No description provided for @ldLoading.
  ///
  /// In de, this message translates to:
  /// **'Lade Organisatoren …'**
  String get ldLoading;

  /// No description provided for @ldNpubInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen npub eingeben.'**
  String get ldNpubInvalid;

  /// No description provided for @ldAddButton.
  ///
  /// In de, this message translates to:
  /// **'Admin hinzufügen'**
  String get ldAddButton;

  /// No description provided for @calLegendCourse.
  ///
  /// In de, this message translates to:
  /// **'Kurse'**
  String get calLegendCourse;

  /// No description provided for @calFilterCourses.
  ///
  /// In de, this message translates to:
  /// **'Kurse'**
  String get calFilterCourses;

  /// No description provided for @refreshRunning.
  ///
  /// In de, this message translates to:
  /// **'Aktualisiere Daten …'**
  String get refreshRunning;

  /// No description provided for @refreshDone.
  ///
  /// In de, this message translates to:
  /// **'Alles aktualisiert'**
  String get refreshDone;

  /// No description provided for @v4vSectionTitle.
  ///
  /// In de, this message translates to:
  /// **'Unterstützen'**
  String get v4vSectionTitle;

  /// No description provided for @v4vSectionSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Value for Value – das Projekt mit Sats unterstützen'**
  String get v4vSectionSubtitle;

  /// No description provided for @v4vTitle.
  ///
  /// In de, this message translates to:
  /// **'Value for Value'**
  String get v4vTitle;

  /// No description provided for @v4vHeadline.
  ///
  /// In de, this message translates to:
  /// **'Value for Value'**
  String get v4vHeadline;

  /// No description provided for @v4vExplain1.
  ///
  /// In de, this message translates to:
  /// **'Diese App entsteht in echter Handarbeit für die Community – ohne Werbung, ohne Tracking, ohne Abo. Nach dem Prinzip \"Value for Value\" gibst du zurück, was dir die App wert ist.'**
  String get v4vExplain1;

  /// No description provided for @v4vExplain2.
  ///
  /// In de, this message translates to:
  /// **'Deine Sats fließen direkt in die Weiterentwicklung des Projekts. Jeder Betrag hilft – vielen Dank!'**
  String get v4vExplain2;

  /// No description provided for @v4vAmountLabel.
  ///
  /// In de, this message translates to:
  /// **'Betrag'**
  String get v4vAmountLabel;

  /// No description provided for @v4vDonateButton.
  ///
  /// In de, this message translates to:
  /// **'Mit Lightning spenden'**
  String get v4vDonateButton;

  /// No description provided for @v4vRecipient.
  ///
  /// In de, this message translates to:
  /// **'Empfänger'**
  String get v4vRecipient;

  /// No description provided for @v4vErrInvalidAmount.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen gültigen Betrag eingeben.'**
  String get v4vErrInvalidAmount;

  /// No description provided for @v4vErrBelowMin.
  ///
  /// In de, this message translates to:
  /// **'Betrag ist zu niedrig für diese Adresse.'**
  String get v4vErrBelowMin;

  /// No description provided for @v4vErrAboveMax.
  ///
  /// In de, this message translates to:
  /// **'Betrag ist zu hoch für diese Adresse.'**
  String get v4vErrAboveMax;

  /// No description provided for @v4vErrUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen. Bitte später erneut versuchen.'**
  String get v4vErrUnreachable;

  /// No description provided for @v4vErrGeneric.
  ///
  /// In de, this message translates to:
  /// **'Die Invoice konnte nicht erstellt werden.'**
  String get v4vErrGeneric;

  /// No description provided for @v4vNoWalletTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Lightning-Wallet gefunden'**
  String get v4vNoWalletTitle;

  /// No description provided for @v4vNoWalletBody.
  ///
  /// In de, this message translates to:
  /// **'Es wurde keine App zum Bezahlen gefunden. Du kannst die Rechnung kopieren und in deiner Wallet einfügen.'**
  String get v4vNoWalletBody;

  /// No description provided for @v4vCopyInvoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung kopieren'**
  String get v4vCopyInvoice;

  /// No description provided for @v4vCopied.
  ///
  /// In de, this message translates to:
  /// **'Rechnung kopiert'**
  String get v4vCopied;

  /// No description provided for @convPremiumTitle.
  ///
  /// In de, this message translates to:
  /// **'Auf-/Abschlag'**
  String get convPremiumTitle;

  /// No description provided for @convPremiumHint.
  ///
  /// In de, this message translates to:
  /// **'Für Trades: Prozent-Aufschlag (+) oder Abschlag (−) auf den Kurs.'**
  String get convPremiumHint;

  /// No description provided for @convPremiumResult.
  ///
  /// In de, this message translates to:
  /// **'Mit Auf-/Abschlag'**
  String get convPremiumResult;

  /// No description provided for @convPremiumBase.
  ///
  /// In de, this message translates to:
  /// **'Basiskurs'**
  String get convPremiumBase;

  /// No description provided for @convPremiumSats.
  ///
  /// In de, this message translates to:
  /// **'Ergebnis in Sats'**
  String get convPremiumSats;

  /// No description provided for @portalTokenMismatch.
  ///
  /// In de, this message translates to:
  /// **'Dein Portal-Login gehört zu einem anderen Nostr-Schlüssel und wurde getrennt. Bitte verbinde das Portal neu — mit dem Schlüssel, mit dem du dort Leiter bist.'**
  String get portalTokenMismatch;

  /// No description provided for @settingsLogTitle.
  ///
  /// In de, this message translates to:
  /// **'Diagnose-Log'**
  String get settingsLogTitle;

  /// No description provided for @settingsLogSub.
  ///
  /// In de, this message translates to:
  /// **'Ereignisse für die Fehlersuche'**
  String get settingsLogSub;

  /// No description provided for @rsvpNoNames.
  ///
  /// In de, this message translates to:
  /// **'Das Portal stellt für dieses Event keine Namensliste bereit.'**
  String get rsvpNoNames;

  /// No description provided for @rsvpAnon.
  ///
  /// In de, this message translates to:
  /// **'Anonym'**
  String get rsvpAnon;

  /// No description provided for @settingsMempool.
  ///
  /// In de, this message translates to:
  /// **'Mempool-Server'**
  String get settingsMempool;

  /// No description provided for @settingsMempoolSub.
  ///
  /// In de, this message translates to:
  /// **'Quelle der Bitcoin-Daten'**
  String get settingsMempoolSub;

  /// No description provided for @mempoolTitle.
  ///
  /// In de, this message translates to:
  /// **'Mempool-Server'**
  String get mempoolTitle;

  /// No description provided for @mempoolIntro.
  ///
  /// In de, this message translates to:
  /// **'Von hier holt die App Blockhöhe, Gebühren, Kurs und Lightning-Daten. Standard ist mempool.space. Wer über Tor surft, sollte die Onion-Adresse wählen — mempool.space weist Anfragen von Tor-Exit-Knoten oft ab.'**
  String get mempoolIntro;

  /// No description provided for @mempoolClearnetTitle.
  ///
  /// In de, this message translates to:
  /// **'Standard (Clearnet)'**
  String get mempoolClearnetTitle;

  /// No description provided for @mempoolTorTitle.
  ///
  /// In de, this message translates to:
  /// **'Tor / Onion'**
  String get mempoolTorTitle;

  /// No description provided for @mempoolTorSub.
  ///
  /// In de, this message translates to:
  /// **'Offizielle .onion von mempool.space'**
  String get mempoolTorSub;

  /// No description provided for @mempoolTorHint.
  ///
  /// In de, this message translates to:
  /// **'Funktioniert nur, wenn Orbot im VPN-Modus läuft und diese App einschließt. Ohne Orbot ist eine .onion-Adresse nicht erreichbar. Tor ist langsamer — die Daten brauchen etwas länger.'**
  String get mempoolTorHint;

  /// No description provided for @mempoolCustomTitle.
  ///
  /// In de, this message translates to:
  /// **'Eigene Instanz'**
  String get mempoolCustomTitle;

  /// No description provided for @mempoolCustomSub.
  ///
  /// In de, this message translates to:
  /// **'Eigener Node (Umbrel, Start9, RaspiBlitz …)'**
  String get mempoolCustomSub;

  /// No description provided for @mempoolSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get mempoolSave;

  /// No description provided for @mempoolSaved.
  ///
  /// In de, this message translates to:
  /// **'Gespeichert'**
  String get mempoolSaved;

  /// No description provided for @mempoolInvalidUrl.
  ///
  /// In de, this message translates to:
  /// **'Das sieht nicht nach einer gültigen Adresse aus.'**
  String get mempoolInvalidUrl;

  /// No description provided for @mempoolTest.
  ///
  /// In de, this message translates to:
  /// **'Verbindung testen'**
  String get mempoolTest;

  /// No description provided for @mempoolTesting.
  ///
  /// In de, this message translates to:
  /// **'Teste …'**
  String get mempoolTesting;

  /// No description provided for @mempoolTestOk.
  ///
  /// In de, this message translates to:
  /// **'Verbindung steht'**
  String get mempoolTestOk;

  /// No description provided for @mempoolTestFail.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get mempoolTestFail;

  /// No description provided for @mempoolTestBlocked.
  ///
  /// In de, this message translates to:
  /// **'Der Server weist die Anfrage ab. Bei Tor: Onion-Adresse wählen.'**
  String get mempoolTestBlocked;

  /// No description provided for @mempoolTestOnionFail.
  ///
  /// In de, this message translates to:
  /// **'Onion nicht erreichbar. Läuft Orbot im VPN-Modus und ist diese App eingeschlossen?'**
  String get mempoolTestOnionFail;

  /// No description provided for @mempoolActive.
  ///
  /// In de, this message translates to:
  /// **'Aktive Quelle'**
  String get mempoolActive;

  /// No description provided for @dashSource.
  ///
  /// In de, this message translates to:
  /// **'Daten'**
  String get dashSource;

  /// No description provided for @dashPartial.
  ///
  /// In de, this message translates to:
  /// **'Nur teilweise geladen'**
  String get dashPartial;

  /// No description provided for @dashOfflineTitle.
  ///
  /// In de, this message translates to:
  /// **'Keine Verbindung'**
  String get dashOfflineTitle;

  /// No description provided for @dashOfflineBody.
  ///
  /// In de, this message translates to:
  /// **'Es konnten keine Daten geladen werden. Prüfe deine Internetverbindung — oder wähle eine andere Datenquelle.'**
  String get dashOfflineBody;

  /// No description provided for @dashBlockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Server weist Anfragen ab'**
  String get dashBlockedTitle;

  /// No description provided for @dashBlockedBody.
  ///
  /// In de, this message translates to:
  /// **'mempool.space blockt diese IP-Adresse. Das passiert typischerweise über Tor, weil sich viele Nutzer einen Exit-Knoten teilen. Abhilfe: Onion-Adresse oder eigene Instanz verwenden.'**
  String get dashBlockedBody;

  /// No description provided for @dashChangeServer.
  ///
  /// In de, this message translates to:
  /// **'Datenquelle ändern'**
  String get dashChangeServer;

  /// No description provided for @chDuellSub.
  ///
  /// In de, this message translates to:
  /// **'Quiz-Duelle um Sats — spiele gegen die Community'**
  String get chDuellSub;

  /// No description provided for @sdMyTurn.
  ///
  /// In de, this message translates to:
  /// **'Du bist dran!'**
  String get sdMyTurn;

  /// No description provided for @sdWaiting.
  ///
  /// In de, this message translates to:
  /// **'Warten auf Gegner'**
  String get sdWaiting;

  /// No description provided for @sdLobby.
  ///
  /// In de, this message translates to:
  /// **'offene Spiele in der Lobby'**
  String get sdLobby;

  /// No description provided for @sdShortTurn.
  ///
  /// In de, this message translates to:
  /// **'dran'**
  String get sdShortTurn;

  /// No description provided for @sdShortLobby.
  ///
  /// In de, this message translates to:
  /// **'in der Lobby'**
  String get sdShortLobby;

  /// No description provided for @sdShortWait.
  ///
  /// In de, this message translates to:
  /// **'warten auf Gegner'**
  String get sdShortWait;

  /// No description provided for @chPlebrapSub.
  ///
  /// In de, this message translates to:
  /// **'Bitcoin-Rap — Plebs together strong'**
  String get chPlebrapSub;

  /// No description provided for @prV4V.
  ///
  /// In de, this message translates to:
  /// **'Sats an die Künstler'**
  String get prV4V;

  /// No description provided for @prPickSong.
  ///
  /// In de, this message translates to:
  /// **'Song auswählen'**
  String get prPickSong;

  /// No description provided for @prLoadError.
  ///
  /// In de, this message translates to:
  /// **'Song konnte nicht geladen werden'**
  String get prLoadError;

  /// No description provided for @msFavoritesHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle deine Meetups — du kannst mehrere auswählen.'**
  String get msFavoritesHint;

  /// No description provided for @msSaveNone.
  ///
  /// In de, this message translates to:
  /// **'Ohne Favorit speichern'**
  String get msSaveNone;

  /// No description provided for @msSaveFavorites.
  ///
  /// In de, this message translates to:
  /// **'{count} Favoriten speichern'**
  String msSaveFavorites(int count);

  /// No description provided for @calFavAdded.
  ///
  /// In de, this message translates to:
  /// **'{city} zu Favoriten hinzugefügt ★'**
  String calFavAdded(String city);

  /// No description provided for @calFavRemoved.
  ///
  /// In de, this message translates to:
  /// **'{city} aus Favoriten entfernt'**
  String calFavRemoved(String city);

  /// No description provided for @verifyBadgeDuplicate.
  ///
  /// In de, this message translates to:
  /// **'Dieses Badge ist bereits in deiner Wallet.'**
  String get verifyBadgeDuplicate;

  /// No description provided for @gpsOpenLocationSettings.
  ///
  /// In de, this message translates to:
  /// **'Standort-Einstellungen öffnen'**
  String get gpsOpenLocationSettings;

  /// No description provided for @gpsOpenAppSettings.
  ///
  /// In de, this message translates to:
  /// **'App-Einstellungen öffnen'**
  String get gpsOpenAppSettings;

  /// No description provided for @walletSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Meetup suchen…'**
  String get walletSearchHint;

  /// No description provided for @walletGroupMeetup.
  ///
  /// In de, this message translates to:
  /// **'Nach Meetup'**
  String get walletGroupMeetup;

  /// No description provided for @walletGroupYear.
  ///
  /// In de, this message translates to:
  /// **'Nach Jahr'**
  String get walletGroupYear;

  /// No description provided for @walletNoResults.
  ///
  /// In de, this message translates to:
  /// **'Keine Badges gefunden.'**
  String get walletNoResults;

  /// No description provided for @walletCleanupTitle.
  ///
  /// In de, this message translates to:
  /// **'Duplikate bereinigen'**
  String get walletCleanupTitle;

  /// No description provided for @walletCleanupConfirm.
  ///
  /// In de, this message translates to:
  /// **'Entfernen'**
  String get walletCleanupConfirm;

  /// No description provided for @walletCleanupNone.
  ///
  /// In de, this message translates to:
  /// **'Keine Duplikate gefunden.'**
  String get walletCleanupNone;

  /// No description provided for @walletCleanupHint.
  ///
  /// In de, this message translates to:
  /// **'Von jedem Meetup bleibt das ursprüngliche Badge erhalten. Bereits veröffentlichte Teilnahme-Nachweise im Netzwerk bleiben unverändert.'**
  String get walletCleanupHint;

  /// No description provided for @walletCleanupBody.
  ///
  /// In de, this message translates to:
  /// **'{count} doppelte Badge(s) gefunden:'**
  String walletCleanupBody(int count);

  /// No description provided for @walletCleanupDone.
  ///
  /// In de, this message translates to:
  /// **'{count} Duplikate entfernt.'**
  String walletCleanupDone(int count);

  /// No description provided for @orgGpsSoftTitle.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort fortfahren?'**
  String get orgGpsSoftTitle;

  /// No description provided for @orgGpsSoftBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst das Meetup trotzdem erstellen und den Namen selbst eintragen. Ohne Standort können Teilnehmer allerdings nicht per Umkreis bestätigt werden — ihre Badges gelten dann als ungeprüfte Präsenz.'**
  String get orgGpsSoftBody;

  /// No description provided for @orgGpsSoftContinue.
  ///
  /// In de, this message translates to:
  /// **'Ohne Standort'**
  String get orgGpsSoftContinue;

  /// No description provided for @badgeUnverified.
  ///
  /// In de, this message translates to:
  /// **'Präsenz ungeprüft'**
  String get badgeUnverified;

  /// No description provided for @badgeUnverifiedInfo.
  ///
  /// In de, this message translates to:
  /// **'Beim Sammeln war kein Standort verfügbar. Der Badge ist gültig, sein Präsenz-Nachweis aber nicht zusätzlich bestätigt.'**
  String get badgeUnverifiedInfo;

  /// No description provided for @verifyClose.
  ///
  /// In de, this message translates to:
  /// **'SCHLIESSEN'**
  String get verifyClose;

  /// No description provided for @verifyOpenWallet.
  ///
  /// In de, this message translates to:
  /// **'ZUR WALLET'**
  String get verifyOpenWallet;

  /// No description provided for @writerValidity.
  ///
  /// In de, this message translates to:
  /// **'Gültig für 4 Stunden'**
  String get writerValidity;

  /// No description provided for @apPickPortalTitle.
  ///
  /// In de, this message translates to:
  /// **'Meetup auswählen'**
  String get apPickPortalTitle;

  /// No description provided for @apPickPortalHint.
  ///
  /// In de, this message translates to:
  /// **'Wähle das Meetup, an dem du gerade bist. Der hinterlegte Ort dient den Teilnehmern als Anhaltspunkt — ein falscher Eintrag verfälscht ihre Bestätigung.'**
  String get apPickPortalHint;

  /// No description provided for @apEnterManually.
  ///
  /// In de, this message translates to:
  /// **'Name selbst eingeben'**
  String get apEnterManually;

  /// No description provided for @apCustomNeedsGpsTitle.
  ///
  /// In de, this message translates to:
  /// **'Standort nötig'**
  String get apCustomNeedsGpsTitle;

  /// No description provided for @apCustomNeedsGpsBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Meetup mit eigenem Namen lässt sich nur erstellen, wenn dein Standort ermittelbar ist — er ist der einzige Bezugspunkt, an dem die Anwesenheit der Teilnehmer geprüft werden kann.\n\nDrei Wege: Geh kurz vor die Tür und versuche es erneut, wähle stattdessen ein Meetup aus dem Portal, oder lass jemand anderen vor Ort mit funktionierender Ortung das Badge erstellen.'**
  String get apCustomNeedsGpsBody;

  /// No description provided for @apNoRefTitle.
  ///
  /// In de, this message translates to:
  /// **'Kein Bezugspunkt'**
  String get apNoRefTitle;

  /// No description provided for @apNoRefContinue.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem erstellen'**
  String get apNoRefContinue;

  /// No description provided for @apNoRefBody.
  ///
  /// In de, this message translates to:
  /// **'Für „{city}“ ist im Portal kein Ort hinterlegt, und dein Standort ist nicht ermittelbar. Die Anwesenheit der Teilnehmer kann deshalb nicht bestätigt werden — ihre Badges zählen weniger.\n\nBesser: Ortung ermöglichen oder jemand anderen vor Ort das Badge erstellen lassen.'**
  String apNoRefBody(String city);

  /// No description provided for @apConfirmPickTitle.
  ///
  /// In de, this message translates to:
  /// **'Bist du hier?'**
  String get apConfirmPickTitle;

  /// No description provided for @apConfirmPickBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Name steht dauerhaft im Badge jedes Teilnehmers und lässt sich nachträglich nicht ändern. Passt der Ort nicht zu den Anwesenden, bekommen sie die Meldung „zu weit entfernt“ und kein Badge.'**
  String get apConfirmPickBody;

  /// No description provided for @apConfirmPickYes.
  ///
  /// In de, this message translates to:
  /// **'Ja, hier bin ich'**
  String get apConfirmPickYes;

  /// No description provided for @badgeOrganizerTitle.
  ///
  /// In de, this message translates to:
  /// **'ORGANISATOR-NACHWEIS'**
  String get badgeOrganizerTitle;

  /// No description provided for @badgeOrganizerDesc.
  ///
  /// In de, this message translates to:
  /// **'Du hast dieses Meetup selbst erstellt. Das Badge dokumentiert es, ist aber nicht signiert und zählt nicht zur Reputation — niemand kann sich selbst bestätigen. Ein zählendes Badge bekommst du, wenn ein anderer Organisator vor Ort eine eigene Session startet und du dessen Code scannst.'**
  String get badgeOrganizerDesc;

  /// No description provided for @walletOrganizerSection.
  ///
  /// In de, this message translates to:
  /// **'Von dir erstellt'**
  String get walletOrganizerSection;

  /// No description provided for @reputationOrganizerNote.
  ///
  /// In de, this message translates to:
  /// **'{count} Meetup(s) von dir organisiert — zählt nicht zum Score, da man sich nicht selbst bestätigen kann.'**
  String reputationOrganizerNote(int count);

  /// No description provided for @apCrossConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Zweiter Organisator dabei?'**
  String get apCrossConfirmTitle;

  /// No description provided for @apCrossConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Für dein eigenes Meetup bekommst du kein zählendes Badge — niemand kann sich selbst bestätigen. Startet ihr beide eine Session und scannt euch gegenseitig, habt ihr beide einen echten Nachweis für diesen Abend.'**
  String get apCrossConfirmBody;

  /// No description provided for @tileEventsToday.
  ///
  /// In de, this message translates to:
  /// **'heute im Veranstaltungskalender'**
  String get tileEventsToday;

  /// No description provided for @tileNewsUnread.
  ///
  /// In de, this message translates to:
  /// **'{count} neu seit deinem Besuch'**
  String tileNewsUnread(int count);

  /// No description provided for @tilesAvailable.
  ///
  /// In de, this message translates to:
  /// **'Verfügbar'**
  String get tilesAvailable;

  /// No description provided for @tilesEditHint.
  ///
  /// In de, this message translates to:
  /// **'Auf eine andere Kachel ziehen zum Verschieben · Nadel zum An- und Abheften'**
  String get tilesEditHint;

  /// No description provided for @tilesEditDone.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get tilesEditDone;

  /// No description provided for @tileReputationBadges.
  ///
  /// In de, this message translates to:
  /// **'{count} gezählte Badges'**
  String tileReputationBadges(int count);

  /// No description provided for @tileActListen.
  ///
  /// In de, this message translates to:
  /// **'Zum Hören'**
  String get tileActListen;

  /// No description provided for @tileActConvert.
  ///
  /// In de, this message translates to:
  /// **'Umrechnen'**
  String get tileActConvert;

  /// No description provided for @tileActExchange.
  ///
  /// In de, this message translates to:
  /// **'Austausch'**
  String get tileActExchange;

  /// No description provided for @tileActSend.
  ///
  /// In de, this message translates to:
  /// **'Senden'**
  String get tileActSend;

  /// No description provided for @tileActExplore.
  ///
  /// In de, this message translates to:
  /// **'Entdecken'**
  String get tileActExplore;

  /// No description provided for @tileActLookup.
  ///
  /// In de, this message translates to:
  /// **'Nachschlagen'**
  String get tileActLookup;

  /// No description provided for @tileActNetwork.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk'**
  String get tileActNetwork;

  /// No description provided for @tileActEncounters.
  ///
  /// In de, this message translates to:
  /// **'Begegnungen'**
  String get tileActEncounters;

  /// No description provided for @tileActManage.
  ///
  /// In de, this message translates to:
  /// **'Verwalten'**
  String get tileActManage;

  /// No description provided for @emptyFindMeetup.
  ///
  /// In de, this message translates to:
  /// **'Meetup finden'**
  String get emptyFindMeetup;

  /// No description provided for @reputationScoreLabel.
  ///
  /// In de, this message translates to:
  /// **'Vertrauenswert'**
  String get reputationScoreLabel;

  /// No description provided for @reputationUnsigned.
  ///
  /// In de, this message translates to:
  /// **'Nicht signiert'**
  String get reputationUnsigned;

  /// No description provided for @portalConnectForOrganizer.
  ///
  /// In de, this message translates to:
  /// **'Nicht mit dem Portal verbunden — dein Organisator-Status kann dadurch nicht erkannt werden.'**
  String get portalConnectForOrganizer;

  /// No description provided for @npubCopied.
  ///
  /// In de, this message translates to:
  /// **'npub kopiert'**
  String get npubCopied;

  /// No description provided for @idSetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Identität'**
  String get idSetupTitle;

  /// No description provided for @idSetupSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Wie möchtest du starten?'**
  String get idSetupSubtitle;

  /// No description provided for @idSetupNewCard.
  ///
  /// In de, this message translates to:
  /// **'Neu hier'**
  String get idSetupNewCard;

  /// No description provided for @idSetupNewCardSub.
  ///
  /// In de, this message translates to:
  /// **'Identität in der App anlegen'**
  String get idSetupNewCardSub;

  /// No description provided for @idSetupExistingCard.
  ///
  /// In de, this message translates to:
  /// **'Schon Nostr'**
  String get idSetupExistingCard;

  /// No description provided for @idSetupExistingCardSub.
  ///
  /// In de, this message translates to:
  /// **'Bestehende Identität verbinden'**
  String get idSetupExistingCardSub;

  /// No description provided for @idSetupResumeCard.
  ///
  /// In de, this message translates to:
  /// **'Schon auf diesem Gerät'**
  String get idSetupResumeCard;

  /// No description provided for @idSetupResumeCardSub.
  ///
  /// In de, this message translates to:
  /// **'Vorhandene Identität weiter nutzen'**
  String get idSetupResumeCardSub;

  /// No description provided for @idSetupResumeTitle.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get idSetupResumeTitle;

  /// No description provided for @idSetupResumeContinue.
  ///
  /// In de, this message translates to:
  /// **'Weitermachen'**
  String get idSetupResumeContinue;

  /// No description provided for @idSetupResumeHasKey.
  ///
  /// In de, this message translates to:
  /// **'Auf diesem Gerät liegt noch dein Schlüssel. Damit machst du weiter — nichts wird neu angelegt.'**
  String get idSetupResumeHasKey;

  /// No description provided for @idSetupResumePasskey.
  ///
  /// In de, this message translates to:
  /// **'Mit Passkey entsperren'**
  String get idSetupResumePasskey;

  /// No description provided for @idSetupResumePasskeyHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Schlüssel liegt verschlüsselt auf diesem Gerät. Entsperre ihn mit deinem Passkey.'**
  String get idSetupResumePasskeyHint;

  /// No description provided for @idSetupResumePassword.
  ///
  /// In de, this message translates to:
  /// **'Stattdessen Passwort benutzen'**
  String get idSetupResumePassword;

  /// No description provided for @idSetupResumePasswordHint.
  ///
  /// In de, this message translates to:
  /// **'Dein Schlüssel liegt verschlüsselt auf diesem Gerät. Gib das Passwort ein, mit dem du ihn angelegt hast.'**
  String get idSetupResumePasswordHint;

  /// No description provided for @idSetupResumeNeedPassword.
  ///
  /// In de, this message translates to:
  /// **'Bitte das Passwort eingeben.'**
  String get idSetupResumeNeedPassword;

  /// No description provided for @idSetupResumeWrongPassword.
  ///
  /// In de, this message translates to:
  /// **'Das Passwort passt nicht zu diesem Schlüssel.'**
  String get idSetupResumeWrongPassword;

  /// No description provided for @idSetupNewTitle.
  ///
  /// In de, this message translates to:
  /// **'Neu anlegen'**
  String get idSetupNewTitle;

  /// No description provided for @idSetupNewHint.
  ///
  /// In de, this message translates to:
  /// **'Name und Passwort reichen. Dein Schlüssel bleibt auf dem Gerät.'**
  String get idSetupNewHint;

  /// No description provided for @idSetupNameLabel.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get idSetupNameLabel;

  /// No description provided for @idSetupNameRequired.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Namen wählen.'**
  String get idSetupNameRequired;

  /// No description provided for @idSetupPasswordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort für deinen Schlüssel'**
  String get idSetupPasswordLabel;

  /// No description provided for @idSetupPasswordConfirmLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort bestätigen'**
  String get idSetupPasswordConfirmLabel;

  /// No description provided for @idSetupPasswordShort.
  ///
  /// In de, this message translates to:
  /// **'Passwort muss mindestens 8 Zeichen haben.'**
  String get idSetupPasswordShort;

  /// No description provided for @idSetupPasswordWarn.
  ///
  /// In de, this message translates to:
  /// **'Dieses Passwort verschlüsselt deinen Schlüssel — nur damit lässt sich deine Sicherung wieder öffnen. Es gibt kein Zurücksetzen: ohne das Passwort ist die Sicherung wertlos.'**
  String get idSetupPasswordWarn;

  /// No description provided for @idSetupCreate.
  ///
  /// In de, this message translates to:
  /// **'Loslegen'**
  String get idSetupCreate;

  /// No description provided for @idSetupPasskeyTitle.
  ///
  /// In de, this message translates to:
  /// **'Passkey'**
  String get idSetupPasskeyTitle;

  /// No description provided for @idSetupPasskeyBody.
  ///
  /// In de, this message translates to:
  /// **'Optional: mit Passkey (Face ID / Fingerabdruck) zusätzlich sichern.'**
  String get idSetupPasskeyBody;

  /// No description provided for @idSetupPasskeyAction.
  ///
  /// In de, this message translates to:
  /// **'Mit Passkey sichern'**
  String get idSetupPasskeyAction;

  /// No description provided for @idSetupPasskeyLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get idSetupPasskeyLater;

  /// No description provided for @idSetupPasskeyUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Passkey ist auf diesem Gerät nicht verfügbar. Du kannst mit dem Passwort weitermachen.'**
  String get idSetupPasskeyUnavailable;

  /// No description provided for @idSetupExistingTitle.
  ///
  /// In de, this message translates to:
  /// **'Verbinden'**
  String get idSetupExistingTitle;

  /// No description provided for @idSetupPrimaryNip07.
  ///
  /// In de, this message translates to:
  /// **'Browsererweiterung'**
  String get idSetupPrimaryNip07;

  /// No description provided for @idSetupPrimaryNip07Sub.
  ///
  /// In de, this message translates to:
  /// **'In der Erweiterung bestätigen'**
  String get idSetupPrimaryNip07Sub;

  /// No description provided for @idSetupPrimaryAmber.
  ///
  /// In de, this message translates to:
  /// **'Amber'**
  String get idSetupPrimaryAmber;

  /// No description provided for @idSetupPrimaryAmberSub.
  ///
  /// In de, this message translates to:
  /// **'In Amber bestätigen'**
  String get idSetupPrimaryAmberSub;

  /// No description provided for @idSetupPrimaryBunker.
  ///
  /// In de, this message translates to:
  /// **'Signer verbinden'**
  String get idSetupPrimaryBunker;

  /// No description provided for @idSetupPrimaryBunkerSub.
  ///
  /// In de, this message translates to:
  /// **'Bunker / Clave / Amber'**
  String get idSetupPrimaryBunkerSub;

  /// No description provided for @idSetupOtherWay.
  ///
  /// In de, this message translates to:
  /// **'Anderer Weg'**
  String get idSetupOtherWay;

  /// No description provided for @idSetupImportHint.
  ///
  /// In de, this message translates to:
  /// **'nsec oder verschlüsselten Schlüssel (ncryptsec) einfügen.'**
  String get idSetupImportHint;

  /// No description provided for @idSetupImportLabel.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel'**
  String get idSetupImportLabel;

  /// No description provided for @idSetupImportPasswordLabel.
  ///
  /// In de, this message translates to:
  /// **'Passwort (nur bei ncryptsec)'**
  String get idSetupImportPasswordLabel;

  /// No description provided for @idSetupImportAction.
  ///
  /// In de, this message translates to:
  /// **'Importieren'**
  String get idSetupImportAction;

  /// No description provided for @idSetupImportEmpty.
  ///
  /// In de, this message translates to:
  /// **'Bitte einen Schlüssel einfügen.'**
  String get idSetupImportEmpty;

  /// No description provided for @idSetupImportNeedPassword.
  ///
  /// In de, this message translates to:
  /// **'Für ncryptsec brauchst du das Passwort.'**
  String get idSetupImportNeedPassword;

  /// No description provided for @idSetupNameTitle.
  ///
  /// In de, this message translates to:
  /// **'Name wählen'**
  String get idSetupNameTitle;

  /// No description provided for @idSetupNameOnlyHint.
  ///
  /// In de, this message translates to:
  /// **'Unter welchem Namen erscheinst du?'**
  String get idSetupNameOnlyHint;

  /// No description provided for @idSetupContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get idSetupContinue;

  /// No description provided for @idSetupConnectFailed.
  ///
  /// In de, this message translates to:
  /// **'Verbindung fehlgeschlagen.'**
  String get idSetupConnectFailed;

  /// No description provided for @idSetupBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel sichern?'**
  String get idSetupBackupTitle;

  /// No description provided for @idSetupBackupBody.
  ///
  /// In de, this message translates to:
  /// **'Kopiere den verschlüsselten Schlüssel in deinen Passwortmanager. Ohne Passwort ist er wertlos.'**
  String get idSetupBackupBody;

  /// No description provided for @idSetupBackupCopy.
  ///
  /// In de, this message translates to:
  /// **'Kopieren'**
  String get idSetupBackupCopy;

  /// No description provided for @idSetupBackupLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get idSetupBackupLater;

  /// No description provided for @idSetupMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Meetup'**
  String get idSetupMeetupTitle;

  /// No description provided for @idSetupMeetupHint.
  ///
  /// In de, this message translates to:
  /// **'Welches Meetup ist deins? Du kannst später weitere hinzufügen.'**
  String get idSetupMeetupHint;

  /// No description provided for @idSetupMeetupPick.
  ///
  /// In de, this message translates to:
  /// **'Meetup wählen'**
  String get idSetupMeetupPick;

  /// No description provided for @idSetupMeetupContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get idSetupMeetupContinue;

  /// No description provided for @idSetupMeetupLater.
  ///
  /// In de, this message translates to:
  /// **'Später'**
  String get idSetupMeetupLater;

  /// No description provided for @idSetupMeetupLoading.
  ///
  /// In de, this message translates to:
  /// **'Meetups werden geladen…'**
  String get idSetupMeetupLoading;

  /// No description provided for @idSetupMeetupLoadError.
  ///
  /// In de, this message translates to:
  /// **'Meetups konnten nicht geladen werden. Später im Profil nachholen.'**
  String get idSetupMeetupLoadError;

  /// No description provided for @rsInvalidUrl.
  ///
  /// In de, this message translates to:
  /// **'Ungültige Adresse. Erwartet wird wss://host.tld ohne Pfad.'**
  String get rsInvalidUrl;

  /// No description provided for @rsRelayUnreachable.
  ///
  /// In de, this message translates to:
  /// **'Relay nicht erreichbar. Adresse prüfen oder Internetverbindung kontrollieren.'**
  String get rsRelayUnreachable;

  /// No description provided for @rsRelayAlreadyAdded.
  ///
  /// In de, this message translates to:
  /// **'Dieses Relay ist bereits eingetragen.'**
  String get rsRelayAlreadyAdded;

  /// No description provided for @rsTesting.
  ///
  /// In de, this message translates to:
  /// **'Verbindung wird geprüft …'**
  String get rsTesting;

  /// No description provided for @rsRelayAdded.
  ///
  /// In de, this message translates to:
  /// **'Relay hinzugefügt und erreichbar.'**
  String get rsRelayAdded;

  /// No description provided for @rsEnabledHint.
  ///
  /// In de, this message translates to:
  /// **'Eingeschaltet — bedeutet nicht, dass das Relay gerade erreichbar ist.'**
  String get rsEnabledHint;

  /// No description provided for @newsWriteArticle.
  ///
  /// In de, this message translates to:
  /// **'Artikel schreiben'**
  String get newsWriteArticle;

  /// No description provided for @newsLike.
  ///
  /// In de, this message translates to:
  /// **'Gefällt mir'**
  String get newsLike;

  /// No description provided for @newsShare.
  ///
  /// In de, this message translates to:
  /// **'Teilen'**
  String get newsShare;

  /// No description provided for @newsLikeFailed.
  ///
  /// In de, this message translates to:
  /// **'Reaktion konnte nicht gesendet werden. Kein Relay hat sie angenommen.'**
  String get newsLikeFailed;

  /// No description provided for @newsZap.
  ///
  /// In de, this message translates to:
  /// **'Zap'**
  String get newsZap;

  /// No description provided for @newsZapTitle.
  ///
  /// In de, this message translates to:
  /// **'Sats an den Autor'**
  String get newsZapTitle;

  /// No description provided for @newsZapBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Betrag. Die Rechnung wird anschließend an deine Lightning-Wallet übergeben.'**
  String get newsZapBody;

  /// No description provided for @newsZapNoAddress.
  ///
  /// In de, this message translates to:
  /// **'Der Autor hat keine Lightning-Adresse im Profil hinterlegt.'**
  String get newsZapNoAddress;

  /// No description provided for @newsZapUnsupportedAddress.
  ///
  /// In de, this message translates to:
  /// **'Die Lightning-Adresse des Autors wird nicht unterstützt (nur Adressen der Form name@domain).'**
  String get newsZapUnsupportedAddress;

  /// No description provided for @newsZapAmountRange.
  ///
  /// In de, this message translates to:
  /// **'Der Betrag liegt außerhalb dessen, was der Autor annimmt.'**
  String get newsZapAmountRange;

  /// No description provided for @newsZapFailed.
  ///
  /// In de, this message translates to:
  /// **'Zap fehlgeschlagen. Einzelheiten stehen im Diagnose-Log.'**
  String get newsZapFailed;

  /// No description provided for @newsZapNoWallet.
  ///
  /// In de, this message translates to:
  /// **'Keine Lightning-Wallet gefunden'**
  String get newsZapNoWallet;

  /// No description provided for @newsZapCopyInvoice.
  ///
  /// In de, this message translates to:
  /// **'Rechnung kopieren'**
  String get newsZapCopyInvoice;

  /// No description provided for @evBadgeCreate.
  ///
  /// In de, this message translates to:
  /// **'Event-Badge erstellen'**
  String get evBadgeCreate;

  /// No description provided for @evBadgeCreateSub.
  ///
  /// In de, this message translates to:
  /// **'Teilnehmer können sich vor Ort ein Badge abholen.'**
  String get evBadgeCreateSub;

  /// No description provided for @evBadgeNotAllowed.
  ///
  /// In de, this message translates to:
  /// **'Nur Meetup-Organisatoren und Leader können Badges vergeben. Das Event kannst du trotzdem eintragen.'**
  String get evBadgeNotAllowed;

  /// No description provided for @evBadgeChecking.
  ///
  /// In de, this message translates to:
  /// **'Berechtigung wird geprüft …'**
  String get evBadgeChecking;

  /// No description provided for @evBadgeImage.
  ///
  /// In de, this message translates to:
  /// **'Bild fürs Badge'**
  String get evBadgeImage;

  /// No description provided for @evBadgeImageHint.
  ///
  /// In de, this message translates to:
  /// **'https://…/bild.png'**
  String get evBadgeImageHint;

  /// No description provided for @evBadgeLocation.
  ///
  /// In de, this message translates to:
  /// **'Ort des Events'**
  String get evBadgeLocation;

  /// No description provided for @evBadgeLocationHint.
  ///
  /// In de, this message translates to:
  /// **'Aktuellen Standort übernehmen'**
  String get evBadgeLocationHint;

  /// No description provided for @evBadgeLocationInfo.
  ///
  /// In de, this message translates to:
  /// **'Badges lassen sich nur in der Nähe dieser Koordinaten und nur am Tag des Events ausgeben.'**
  String get evBadgeLocationInfo;

  /// No description provided for @evBadgeNoLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht ermittelbar. Ortungsdienst und Berechtigung prüfen.'**
  String get evBadgeNoLocation;

  /// No description provided for @evBadgeIssuers.
  ///
  /// In de, this message translates to:
  /// **'Wer darf Badges ausgeben?'**
  String get evBadgeIssuers;

  /// No description provided for @evBadgeIssuerHint.
  ///
  /// In de, this message translates to:
  /// **'npub1… einfügen'**
  String get evBadgeIssuerHint;

  /// No description provided for @evBadgeIssuerInfo.
  ///
  /// In de, this message translates to:
  /// **'Du selbst darfst immer. Trage weitere Helfer ein, die vor Ort Badges verteilen sollen — sie brauchen keine eigene Organisatoren-Rolle.'**
  String get evBadgeIssuerInfo;

  /// No description provided for @evBadgeIssuerInvalid.
  ///
  /// In de, this message translates to:
  /// **'Das ist kein gültiger npub. Erwartet wird npub1… oder ein 64-stelliger Hex-Schlüssel.'**
  String get evBadgeIssuerInvalid;

  /// No description provided for @evBadgeIssuerDuplicate.
  ///
  /// In de, this message translates to:
  /// **'Dieser Schlüssel steht bereits in der Liste.'**
  String get evBadgeIssuerDuplicate;

  /// No description provided for @evBadgeImageInfo.
  ///
  /// In de, this message translates to:
  /// **'Bild aus der Galerie wählen — es wird hochgeladen, damit alle es sehen können. Eine fertige URL geht auch.'**
  String get evBadgeImageInfo;

  /// No description provided for @evBadgeUploading.
  ///
  /// In de, this message translates to:
  /// **'Bild wird hochgeladen …'**
  String get evBadgeUploading;

  /// No description provided for @evBadgeUploadFailed.
  ///
  /// In de, this message translates to:
  /// **'Upload fehlgeschlagen: {msg}'**
  String evBadgeUploadFailed(String msg);

  /// No description provided for @evBadgeLocationPick.
  ///
  /// In de, this message translates to:
  /// **'Auf der Karte wählen'**
  String get evBadgeLocationPick;

  /// No description provided for @locPickTitle.
  ///
  /// In de, this message translates to:
  /// **'Ort des Events'**
  String get locPickTitle;

  /// No description provided for @locPickHint.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf die Karte, um den Veranstaltungsort zu setzen.'**
  String get locPickHint;

  /// No description provided for @locPickHintDone.
  ///
  /// In de, this message translates to:
  /// **'Tippe erneut, um den Punkt zu verschieben.'**
  String get locPickHintDone;

  /// No description provided for @locPickJumpToMe.
  ///
  /// In de, this message translates to:
  /// **'Zu meinem Standort'**
  String get locPickJumpToMe;

  /// No description provided for @locPickConfirm.
  ///
  /// In de, this message translates to:
  /// **'Ort übernehmen'**
  String get locPickConfirm;

  /// No description provided for @evBadgeAvailable.
  ///
  /// In de, this message translates to:
  /// **'Hier gibt es ein Badge'**
  String get evBadgeAvailable;

  /// No description provided for @evBadgeAvailableSub.
  ///
  /// In de, this message translates to:
  /// **'Vor Ort kannst du dir ein Badge abholen — am Tag des Events, in der Nähe des Veranstaltungsorts.'**
  String get evBadgeAvailableSub;

  /// No description provided for @evBadgeYouIssue.
  ///
  /// In de, this message translates to:
  /// **'Du darfst hier Badges ausgeben'**
  String get evBadgeYouIssue;

  /// No description provided for @evBadgeYouIssueSub.
  ///
  /// In de, this message translates to:
  /// **'Am Tag des Events kannst du vor Ort eine Session starten und Badges verteilen.'**
  String get evBadgeYouIssueSub;

  /// No description provided for @evBadgeStartSession.
  ///
  /// In de, this message translates to:
  /// **'Badge-Session starten'**
  String get evBadgeStartSession;

  /// No description provided for @evSessionNoIdentity.
  ///
  /// In de, this message translates to:
  /// **'Kein Nostr-Schlüssel vorhanden. Lege zuerst einen an.'**
  String get evSessionNoIdentity;

  /// No description provided for @evSessionNotIssuer.
  ///
  /// In de, this message translates to:
  /// **'Du bist bei diesem Event nicht als Aussteller eingetragen.'**
  String get evSessionNotIssuer;

  /// No description provided for @evSessionOutsideWindow.
  ///
  /// In de, this message translates to:
  /// **'Badges gibt es nur am Tag des Events.'**
  String get evSessionOutsideWindow;

  /// No description provided for @evSessionNoEventLocation.
  ///
  /// In de, this message translates to:
  /// **'Für dieses Event ist kein Ort hinterlegt. Ohne Koordinaten lässt sich nicht prüfen, ob du vor Ort bist.'**
  String get evSessionNoEventLocation;

  /// No description provided for @evSessionNoLocation.
  ///
  /// In de, this message translates to:
  /// **'Standort nicht ermittelbar. Ortungsdienst und Berechtigung prüfen.'**
  String get evSessionNoLocation;

  /// No description provided for @evSessionTooFar.
  ///
  /// In de, this message translates to:
  /// **'Du bist {km} km vom Veranstaltungsort entfernt. Badges lassen sich nur vor Ort ausgeben.'**
  String evSessionTooFar(String km);

  /// No description provided for @evSessionFailed.
  ///
  /// In de, this message translates to:
  /// **'Session konnte nicht gestartet werden. Einzelheiten stehen im Diagnose-Log.'**
  String get evSessionFailed;

  /// No description provided for @mvEventIssuerOk.
  ///
  /// In de, this message translates to:
  /// **'Event-Badge von „{event}“ — ausgegeben mit Erlaubnis von {creator}.'**
  String mvEventIssuerOk(String event, String creator);

  /// No description provided for @mvEventSignerNotListed.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Der Aussteller ist bei „{event}“ nicht als Helfer eingetragen.'**
  String mvEventSignerNotListed(String event);

  /// No description provided for @mvEventCreatorNotAuthorized.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Wer „{event}“ angelegt hat, ist kein eingetragener Organisator.'**
  String mvEventCreatorNotAuthorized(String event);

  /// No description provided for @mvEventHasNoBadge.
  ///
  /// In de, this message translates to:
  /// **'Achtung: Für „{event}“ ist gar kein Badge vorgesehen.'**
  String mvEventHasNoBadge(String event);

  /// No description provided for @mvEventNotFound.
  ///
  /// In de, this message translates to:
  /// **'Das zugehörige Event ist nicht auffindbar. Ohne Netz lässt sich die Berechtigung nicht prüfen.'**
  String get mvEventNotFound;

  /// No description provided for @evBadgeShowSession.
  ///
  /// In de, this message translates to:
  /// **'QR anzeigen'**
  String get evBadgeShowSession;

  /// No description provided for @badgeShareTagline.
  ///
  /// In de, this message translates to:
  /// **'Vor Ort dabei gewesen — bestätigt über Nostr.'**
  String get badgeShareTagline;

  /// No description provided for @shareCardCollectedBy.
  ///
  /// In de, this message translates to:
  /// **'Gesammelt von'**
  String get shareCardCollectedBy;

  /// No description provided for @shareCardBlock.
  ///
  /// In de, this message translates to:
  /// **'Block'**
  String get shareCardBlock;

  /// No description provided for @shareCardScanned.
  ///
  /// In de, this message translates to:
  /// **'Gescannt'**
  String get shareCardScanned;

  /// No description provided for @shareCardChecksum.
  ///
  /// In de, this message translates to:
  /// **'Prüfsumme'**
  String get shareCardChecksum;

  /// No description provided for @shareCardPromo.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig-Meetup besucht? Sammle dein Badge — kryptographisch belegt, dass du vor Ort warst.'**
  String get shareCardPromo;

  /// No description provided for @backupPwShow.
  ///
  /// In de, this message translates to:
  /// **'Passwort anzeigen'**
  String get backupPwShow;

  /// No description provided for @backupPwHide.
  ///
  /// In de, this message translates to:
  /// **'Passwort verbergen'**
  String get backupPwHide;

  /// No description provided for @backupPwRuleLength.
  ///
  /// In de, this message translates to:
  /// **'Mindestens {min} Zeichen — eine lange Passphrase ist besser als ein kurzes, kompliziertes Passwort.'**
  String backupPwRuleLength(int min);

  /// No description provided for @backupPwRuleMatch.
  ///
  /// In de, this message translates to:
  /// **'Beide Eingaben stimmen überein'**
  String get backupPwRuleMatch;

  /// No description provided for @idSetupOtherWaySub.
  ///
  /// In de, this message translates to:
  /// **'nsec, ncryptsec, Bunker oder Backup'**
  String get idSetupOtherWaySub;

  /// No description provided for @guideWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Willkommen!'**
  String get guideWelcomeTitle;

  /// No description provided for @guideWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du eine kurze Tour durch die App? Wir zeigen dir die wichtigsten Funktionen.'**
  String get guideWelcomeBody;

  /// No description provided for @guideStart.
  ///
  /// In de, this message translates to:
  /// **'Tour starten'**
  String get guideStart;

  /// No description provided for @guideNoThanks.
  ///
  /// In de, this message translates to:
  /// **'Nein, danke'**
  String get guideNoThanks;

  /// No description provided for @guideSkip.
  ///
  /// In de, this message translates to:
  /// **'ÜBERSPRINGEN'**
  String get guideSkip;

  /// No description provided for @guideFinishTour.
  ///
  /// In de, this message translates to:
  /// **'Tour beenden'**
  String get guideFinishTour;

  /// No description provided for @guideBack.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get guideBack;

  /// No description provided for @guideOnboardWelcomeTitle.
  ///
  /// In de, this message translates to:
  /// **'Lass uns dein Profil einrichten'**
  String get guideOnboardWelcomeTitle;

  /// No description provided for @guideOnboardWelcomeBody.
  ///
  /// In de, this message translates to:
  /// **'Wir führen dich Schritt für Schritt durch die Einrichtung. Es dauert nur eine Minute.'**
  String get guideOnboardWelcomeBody;

  /// No description provided for @guideOnboardNicknameTitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle einen Nickname'**
  String get guideOnboardNicknameTitle;

  /// No description provided for @guideOnboardNicknameBody.
  ///
  /// In de, this message translates to:
  /// **'So werden dich andere Community-Mitglieder sehen. Wähle etwas Einprägsames!'**
  String get guideOnboardNicknameBody;

  /// No description provided for @guideOnboardMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Wähle dein Home-Meetup'**
  String get guideOnboardMeetupTitle;

  /// No description provided for @guideOnboardMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Home-Meetup bestimmt, welche Badges du sammeln kannst und welche Events du zuerst siehst.'**
  String get guideOnboardMeetupBody;

  /// No description provided for @guideOnboardNostrTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Nostr-Schlüssel'**
  String get guideOnboardNostrTitle;

  /// No description provided for @guideOnboardNostrBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser kryptografische Schlüssel signiert deine Badges und verifiziert deine Reputation. Er wird nur auf deinem Gerät gespeichert.'**
  String get guideOnboardNostrBody;

  /// No description provided for @guideOnboardSaveTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil speichern'**
  String get guideOnboardSaveTitle;

  /// No description provided for @guideOnboardSaveBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe hier, wenn du fertig bist. Du kannst diese Einstellungen später jederzeit ändern.'**
  String get guideOnboardSaveBody;

  /// No description provided for @guideHomeMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Home Meetup'**
  String get guideHomeMeetupTitle;

  /// No description provided for @guideHomeMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Deine Favoriten-Meetups und das nächste anstehende Event – direkt auf einen Blick.'**
  String get guideHomeMeetupBody;

  /// No description provided for @guideHomeTrustScoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Trust Score'**
  String get guideHomeTrustScoreTitle;

  /// No description provided for @guideHomeTrustScoreBody.
  ///
  /// In de, this message translates to:
  /// **'Hier siehst du deinen aktuellen Stand. Tippe darauf für die Aufschlüsselung nach Vielfalt, Aktivität & Qualität.'**
  String get guideHomeTrustScoreBody;

  /// No description provided for @guideHomeReputationTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get guideHomeReputationTitle;

  /// No description provided for @guideHomeReputationBody.
  ///
  /// In de, this message translates to:
  /// **'Prüfe deine Reputation oder verifiziere den Trust Score einer anderen Person.'**
  String get guideHomeReputationBody;

  /// No description provided for @guideHomeWotTitle.
  ///
  /// In de, this message translates to:
  /// **'Vertrauensnetzwerk'**
  String get guideHomeWotTitle;

  /// No description provided for @guideHomeWotBody.
  ///
  /// In de, this message translates to:
  /// **'Sieh, wie du mit anderen im Web of Trust verbunden bist.'**
  String get guideHomeWotBody;

  /// No description provided for @guideHomeCommunityTitle.
  ///
  /// In de, this message translates to:
  /// **'Community Portal'**
  String get guideHomeCommunityTitle;

  /// No description provided for @guideHomeCommunityBody.
  ///
  /// In de, this message translates to:
  /// **'Zugriff auf Podcast, Shoutouts, Merch und mehr.'**
  String get guideHomeCommunityBody;

  /// No description provided for @guideHomeUmrechnerTitle.
  ///
  /// In de, this message translates to:
  /// **'Umrechner'**
  String get guideHomeUmrechnerTitle;

  /// No description provided for @guideHomeUmrechnerBody.
  ///
  /// In de, this message translates to:
  /// **'Schnell zwischen EUR und Sats umrechnen.'**
  String get guideHomeUmrechnerBody;

  /// No description provided for @guideHomeBitcoinTitle.
  ///
  /// In de, this message translates to:
  /// **'Bitcoin Kurs'**
  String get guideHomeBitcoinTitle;

  /// No description provided for @guideHomeBitcoinBody.
  ///
  /// In de, this message translates to:
  /// **'Aktueller Preis, Netzwerk-Stats und Blockhöhe.'**
  String get guideHomeBitcoinBody;

  /// No description provided for @guideHomeBadgeWalletTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge Wallet'**
  String get guideHomeBadgeWalletTitle;

  /// No description provided for @guideHomeBadgeWalletBody.
  ///
  /// In de, this message translates to:
  /// **'Alle gesammelten Badges – kryptographisch signiert und nur auf deinem Gerät gespeichert.'**
  String get guideHomeBadgeWalletBody;

  /// No description provided for @guideHomeScanTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge einfordern'**
  String get guideHomeScanTitle;

  /// No description provided for @guideHomeScanBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe hier, um beim Meetup den QR-Code des Organisators zu scannen oder dein Gerät per NFC anzuhalten.'**
  String get guideHomeScanBody;

  /// No description provided for @guideHomeSettingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get guideHomeSettingsTitle;

  /// No description provided for @guideHomeSettingsBody.
  ///
  /// In de, this message translates to:
  /// **'Konfiguriere Backup, Sprache, Relays und mehr. Vergiss nicht, ein Backup zu erstellen!'**
  String get guideHomeSettingsBody;

  /// No description provided for @guideSettingsBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Erstelle ein Backup!'**
  String get guideSettingsBackupTitle;

  /// No description provided for @guideSettingsBackupBody.
  ///
  /// In de, this message translates to:
  /// **'WICHTIG: Erstelle ein Backup, um deinen Account zu schützen. Ohne Backup sind deine Badges und dein Profil verloren, wenn du dein Gerät verlierst.'**
  String get guideSettingsBackupBody;

  /// No description provided for @guideSettingsLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get guideSettingsLanguageTitle;

  /// No description provided for @guideSettingsLanguageBody.
  ///
  /// In de, this message translates to:
  /// **'Wechsle zwischen Deutsch, Englisch und Spanisch.'**
  String get guideSettingsLanguageBody;

  /// No description provided for @guideSettingsRelaysTitle.
  ///
  /// In de, this message translates to:
  /// **'Nostr Relays'**
  String get guideSettingsRelaysTitle;

  /// No description provided for @guideSettingsRelaysBody.
  ///
  /// In de, this message translates to:
  /// **'Konfiguriere, mit welchen Nostr-Relays sich deine App verbindet.'**
  String get guideSettingsRelaysBody;

  /// No description provided for @guideSettingsHapticTitle.
  ///
  /// In de, this message translates to:
  /// **'Haptisches Feedback'**
  String get guideSettingsHapticTitle;

  /// No description provided for @guideSettingsHapticBody.
  ///
  /// In de, this message translates to:
  /// **'Aktiviere oder deaktiviere Vibrationsfeedback.'**
  String get guideSettingsHapticBody;

  /// No description provided for @guideSettingsResetTitle.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen'**
  String get guideSettingsResetTitle;

  /// No description provided for @guideSettingsResetBody.
  ///
  /// In de, this message translates to:
  /// **'Dies löscht dein Profil und alle Badges. Stelle sicher, dass du zuerst ein Backup hast!'**
  String get guideSettingsResetBody;

  /// No description provided for @guideEventsSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Events suchen'**
  String get guideEventsSearchTitle;

  /// No description provided for @guideEventsSearchBody.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Meetups nach Stadt oder Stichwort.'**
  String get guideEventsSearchBody;

  /// No description provided for @guideEventsCalendarTitle.
  ///
  /// In de, this message translates to:
  /// **'Kalender'**
  String get guideEventsCalendarTitle;

  /// No description provided for @guideEventsCalendarBody.
  ///
  /// In de, this message translates to:
  /// **'Durchsuche alle kommenden Meetup-Events.'**
  String get guideEventsCalendarBody;

  /// No description provided for @guideEventsCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Event Details'**
  String get guideEventsCardTitle;

  /// No description provided for @guideEventsCardBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf ein Event, um Details, Ort und Links zu sehen.'**
  String get guideEventsCardBody;

  /// No description provided for @guideEventsCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Event erstellen'**
  String get guideEventsCreateTitle;

  /// No description provided for @guideEventsCreateBody.
  ///
  /// In de, this message translates to:
  /// **'Als Organisator kannst du hier neue Meetup-Events erstellen.'**
  String get guideEventsCreateBody;

  /// No description provided for @guidePortalShoutoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Shoutout senden'**
  String get guidePortalShoutoutTitle;

  /// No description provided for @guidePortalShoutoutBody.
  ///
  /// In de, this message translates to:
  /// **'Sende einen öffentlichen Shoutout an die Community.'**
  String get guidePortalShoutoutBody;

  /// No description provided for @guidePortalPodcastTitle.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get guidePortalPodcastTitle;

  /// No description provided for @guidePortalPodcastBody.
  ///
  /// In de, this message translates to:
  /// **'Höre den Einundzwanzig Podcast direkt in der App.'**
  String get guidePortalPodcastBody;

  /// No description provided for @guidePortalSoundboardTitle.
  ///
  /// In de, this message translates to:
  /// **'Soundboard'**
  String get guidePortalSoundboardTitle;

  /// No description provided for @guidePortalSoundboardBody.
  ///
  /// In de, this message translates to:
  /// **'Spiele Clips und Sounds aus dem Podcast ab.'**
  String get guidePortalSoundboardBody;

  /// No description provided for @guidePortalMerchTitle.
  ///
  /// In de, this message translates to:
  /// **'Shop'**
  String get guidePortalMerchTitle;

  /// No description provided for @guidePortalMerchBody.
  ///
  /// In de, this message translates to:
  /// **'Durchsuche Merch und Bitcoin-Produkte.'**
  String get guidePortalMerchBody;

  /// No description provided for @guidePortalMembershipTitle.
  ///
  /// In de, this message translates to:
  /// **'Mitglied werden'**
  String get guidePortalMembershipTitle;

  /// No description provided for @guidePortalMembershipBody.
  ///
  /// In de, this message translates to:
  /// **'Unterstütze den Verein, indem du Mitglied wirst.'**
  String get guidePortalMembershipBody;

  /// No description provided for @guidePortalMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Meetup Karte'**
  String get guidePortalMapTitle;

  /// No description provided for @guidePortalMapBody.
  ///
  /// In de, this message translates to:
  /// **'Finde Meetups in deiner Nähe auf der Karte.'**
  String get guidePortalMapBody;

  /// No description provided for @guideWalletBadgesTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Badges'**
  String get guideWalletBadgesTitle;

  /// No description provided for @guideWalletBadgesBody.
  ///
  /// In de, this message translates to:
  /// **'Alle gesammelten Badges – kryptographisch signiert und nur auf deinem Gerät gespeichert.'**
  String get guideWalletBadgesBody;

  /// No description provided for @guideWalletShareQrTitle.
  ///
  /// In de, this message translates to:
  /// **'QR-Code teilen'**
  String get guideWalletShareQrTitle;

  /// No description provided for @guideWalletShareQrBody.
  ///
  /// In de, this message translates to:
  /// **'Zeige deinen Reputations-QR-Code zum Scannen vor Ort.'**
  String get guideWalletShareQrBody;

  /// No description provided for @guideWalletExportTitle.
  ///
  /// In de, this message translates to:
  /// **'Als JSON exportieren'**
  String get guideWalletExportTitle;

  /// No description provided for @guideWalletExportBody.
  ///
  /// In de, this message translates to:
  /// **'Signierter Export mit Schnorr-Beweis zur Verifizierung.'**
  String get guideWalletExportBody;

  /// No description provided for @guideWalletShareTextTitle.
  ///
  /// In de, this message translates to:
  /// **'Als Text teilen'**
  String get guideWalletShareTextTitle;

  /// No description provided for @guideWalletShareTextBody.
  ///
  /// In de, this message translates to:
  /// **'Teile deine Reputation als lesbaren Text.'**
  String get guideWalletShareTextBody;

  /// No description provided for @guideReputationScoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Score'**
  String get guideReputationScoreTitle;

  /// No description provided for @guideReputationScoreBody.
  ///
  /// In de, this message translates to:
  /// **'Dein Trust Score wird aus Badges, Vielfalt und Aktivität berechnet.'**
  String get guideReputationScoreBody;

  /// No description provided for @guideReputationLevelTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Level'**
  String get guideReputationLevelTitle;

  /// No description provided for @guideReputationLevelBody.
  ///
  /// In de, this message translates to:
  /// **'Von NEU bis VETERAN – dein Level wächst mit deiner Teilnahme.'**
  String get guideReputationLevelBody;

  /// No description provided for @guideReputationStatsTitle.
  ///
  /// In de, this message translates to:
  /// **'Statistiken'**
  String get guideReputationStatsTitle;

  /// No description provided for @guideReputationStatsBody.
  ///
  /// In de, this message translates to:
  /// **'Badges, Meetups, Signer und gebundene Beweise auf einen Blick.'**
  String get guideReputationStatsBody;

  /// No description provided for @guideReputationShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputation teilen'**
  String get guideReputationShareTitle;

  /// No description provided for @guideReputationShareBody.
  ///
  /// In de, this message translates to:
  /// **'Teile deine verifizierte Reputation per QR-Code oder Text.'**
  String get guideReputationShareBody;

  /// No description provided for @guideReputationUpdateTitle.
  ///
  /// In de, this message translates to:
  /// **'Auf Relays aktualisieren'**
  String get guideReputationUpdateTitle;

  /// No description provided for @guideReputationUpdateBody.
  ///
  /// In de, this message translates to:
  /// **'Veröffentliche deine neueste Reputation im Nostr-Netzwerk.'**
  String get guideReputationUpdateBody;

  /// No description provided for @guideStepOf.
  ///
  /// In de, this message translates to:
  /// **'Schritt {current} von {total}'**
  String guideStepOf(int current, int total);

  /// No description provided for @guideStepDone.
  ///
  /// In de, this message translates to:
  /// **'Erledigt'**
  String get guideStepDone;

  /// No description provided for @guideHintNickname.
  ///
  /// In de, this message translates to:
  /// **'Tippe ins Feld und gib deinen Nickname ein.'**
  String get guideHintNickname;

  /// No description provided for @guideHintOpenPicker.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf das Feld, um die Meetup-Auswahl zu öffnen.'**
  String get guideHintOpenPicker;

  /// No description provided for @guideHintSearchCity.
  ///
  /// In de, this message translates to:
  /// **'Tippe die ersten Buchstaben deiner Stadt ein.'**
  String get guideHintSearchCity;

  /// No description provided for @guideHintStarMeetup.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf den Stern neben deinem Meetup.'**
  String get guideHintStarMeetup;

  /// No description provided for @guideHintConfirmSelection.
  ///
  /// In de, this message translates to:
  /// **'Bestätige deine Auswahl mit dem Knopf unten.'**
  String get guideHintConfirmSelection;

  /// No description provided for @guideHintNostrKey.
  ///
  /// In de, this message translates to:
  /// **'Erstelle einen neuen Schlüssel oder importiere einen bestehenden.'**
  String get guideHintNostrKey;

  /// No description provided for @guideHintSave.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf PROFIL SPEICHERN.'**
  String get guideHintSave;

  /// No description provided for @guideOnboardMeetupSearchTitle.
  ///
  /// In de, this message translates to:
  /// **'Stadt suchen'**
  String get guideOnboardMeetupSearchTitle;

  /// No description provided for @guideOnboardMeetupSearchBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe den Namen deiner Stadt ein — die Liste filtert sich sofort.'**
  String get guideOnboardMeetupSearchBody;

  /// No description provided for @guideOnboardMeetupPickTitle.
  ///
  /// In de, this message translates to:
  /// **'Meetup markieren'**
  String get guideOnboardMeetupPickTitle;

  /// No description provided for @guideOnboardMeetupPickBody.
  ///
  /// In de, this message translates to:
  /// **'Setze den Stern bei deinem Meetup. Du kannst mehrere Favoriten wählen; der erste wird dein Home-Meetup.'**
  String get guideOnboardMeetupPickBody;

  /// No description provided for @guideOnboardMeetupConfirmTitle.
  ///
  /// In de, this message translates to:
  /// **'Auswahl bestätigen'**
  String get guideOnboardMeetupConfirmTitle;

  /// No description provided for @guideOnboardMeetupConfirmBody.
  ///
  /// In de, this message translates to:
  /// **'Der Knopf zeigt, wie viele Favoriten du gewählt hast. Tippe darauf, um zurück zum Profil zu kommen.'**
  String get guideOnboardMeetupConfirmBody;

  /// No description provided for @guideOnboardPlatformsTitle.
  ///
  /// In de, this message translates to:
  /// **'Plattformen verknüpfen'**
  String get guideOnboardPlatformsTitle;

  /// No description provided for @guideOnboardPlatformsBody.
  ///
  /// In de, this message translates to:
  /// **'Hier verbindest du Konten wie Telegram, X oder Kleinanzeigen mit deiner Nostr-Identität. Jede bestätigte Plattform zahlt auf deinen Trust Score ein und zeigt anderen, dass hinter dem Profil ein gewachsener Mensch steckt.'**
  String get guideOnboardPlatformsBody;

  /// No description provided for @guideHintPlatforms.
  ///
  /// In de, this message translates to:
  /// **'Freiwillig — du kannst das jederzeit im Profil nachholen.'**
  String get guideHintPlatforms;

  /// No description provided for @guideOnboardHumanityTitle.
  ///
  /// In de, this message translates to:
  /// **'Proof of Humanity'**
  String get guideOnboardHumanityTitle;

  /// No description provided for @guideOnboardHumanityBody.
  ///
  /// In de, this message translates to:
  /// **'Ein einmaliger Lightning-Zap belegt, dass du eine echte Wallet bedienst — der wirksamste Schutz gegen Bot-Konten im Vertrauensnetzwerk. Hast du schon gezappt, prüfst du es hier nach.'**
  String get guideOnboardHumanityBody;

  /// No description provided for @guideHintHumanity.
  ///
  /// In de, this message translates to:
  /// **'Freiwillig — die App funktioniert auch ohne diesen Nachweis.'**
  String get guideHintHumanity;

  /// No description provided for @guideHomeEventsTitle.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get guideHomeEventsTitle;

  /// No description provided for @guideHomeEventsBody.
  ///
  /// In de, this message translates to:
  /// **'Diese Kachel zeigt, ob heute etwas ansteht. Sie färbt sich orange, sobald ein Termin für den Tag eingetragen ist, und führt dich in den Kalender mit allen kommenden Treffen.'**
  String get guideHomeEventsBody;

  /// No description provided for @guideHomeShoutoutTitle.
  ///
  /// In de, this message translates to:
  /// **'Shoutout'**
  String get guideHomeShoutoutTitle;

  /// No description provided for @guideHomeShoutoutBody.
  ///
  /// In de, this message translates to:
  /// **'Schick eine Nachricht an die Community — sie landet auf der Shoutout-Seite von Einundzwanzig. Die Kachel öffnet die Seite im Browser.'**
  String get guideHomeShoutoutBody;

  /// No description provided for @guideHomePodcastTitle.
  ///
  /// In de, this message translates to:
  /// **'Podcast'**
  String get guideHomePodcastTitle;

  /// No description provided for @guideHomePodcastBody.
  ///
  /// In de, this message translates to:
  /// **'Der Einundzwanzig-Podcast, direkt aus der App heraus. Die Kachel öffnet die Folgenübersicht im Browser.'**
  String get guideHomePodcastBody;

  /// No description provided for @guideHomePortalConnectTitle.
  ///
  /// In de, this message translates to:
  /// **'Portal-Verbindung'**
  String get guideHomePortalConnectTitle;

  /// No description provided for @guideHomePortalConnectBody.
  ///
  /// In de, this message translates to:
  /// **'Grün heißt verbunden, rot heißt getrennt. Mit der Verbindung zum Einundzwanzig-Portal siehst du Termine und Kurse, die dort gepflegt werden. Ein Tipp auf die Kachel schaltet um.'**
  String get guideHomePortalConnectBody;

  /// No description provided for @guideHomeNewsTitle.
  ///
  /// In de, this message translates to:
  /// **'News'**
  String get guideHomeNewsTitle;

  /// No description provided for @guideHomeNewsBody.
  ///
  /// In de, this message translates to:
  /// **'Die jüngste Meldung aus der Community steht direkt auf der Kachel. Ein Tipp öffnet die vollständige Übersicht.'**
  String get guideHomeNewsBody;

  /// No description provided for @guideHomeMyMeetupsTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get guideHomeMyMeetupsTitle;

  /// No description provided for @guideHomeMyMeetupsBody.
  ///
  /// In de, this message translates to:
  /// **'Hier verwaltest du die Termine deiner Meetups im Portal — anlegen, ändern, absagen. Nur sinnvoll, wenn du selbst organisierst.'**
  String get guideHomeMyMeetupsBody;

  /// No description provided for @guideHomeMoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Und noch mehr'**
  String get guideHomeMoreTitle;

  /// No description provided for @guideHomeMoreBody.
  ///
  /// In de, this message translates to:
  /// **'Vier weitere Kacheln warten auf dem Dashboard: SatoshiDuell für Quizrunden um Sats, PlebRap für Musik aus der Community, der Portal-Bereich mit Meetups, Events, Kursen und Karte, sowie die Nostr-Kachel mit den neuesten Notizen aus deinem Netzwerk. Jede lässt sich in den Einstellungen aus- oder wieder einblenden.'**
  String get guideHomeMoreBody;

  /// No description provided for @guideHomeNearbyTitle.
  ///
  /// In de, this message translates to:
  /// **'In der Nähe'**
  String get guideHomeNearbyTitle;

  /// No description provided for @guideHomeNearbyBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt Meetups in deiner Umgebung — praktisch auf Reisen oder wenn du ein zweites Treffen in der Region suchst. Der Bildschirm legt sich über die App, ein Zurück bringt dich hierher.'**
  String get guideHomeNearbyBody;

  /// No description provided for @guideHomeEventsTabTitle.
  ///
  /// In de, this message translates to:
  /// **'Event-Bereich'**
  String get guideHomeEventsTabTitle;

  /// No description provided for @guideHomeEventsTabBody.
  ///
  /// In de, this message translates to:
  /// **'Der vierte Knopf führt in den vollständigen Kalender: alle Termine, filterbar nach Ort und Zeitraum, mit Erinnerungsfunktion.'**
  String get guideHomeEventsTabBody;

  /// No description provided for @guideHomeSettingsBackupHint.
  ///
  /// In de, this message translates to:
  /// **'Geh gleich als Erstes ins Backup — ohne das ist dein Schlüssel bei Handyverlust weg.'**
  String get guideHomeSettingsBackupHint;

  /// No description provided for @guideHintBackup.
  ///
  /// In de, this message translates to:
  /// **'Leg jetzt ein verschlüsseltes Backup an — es dauert eine Minute.'**
  String get guideHintBackup;

  /// No description provided for @guideEvBadgeSwitchTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge für dein Event'**
  String get guideEvBadgeSwitchTitle;

  /// No description provided for @guideEvBadgeSwitchBody.
  ///
  /// In de, this message translates to:
  /// **'Leg den Schalter um, wenn Teilnehmer sich vor Ort ein Badge abholen können sollen. Ohne ihn bleibt es ein reiner Termin.'**
  String get guideEvBadgeSwitchBody;

  /// No description provided for @guideEvBadgeSwitchHint.
  ///
  /// In de, this message translates to:
  /// **'Wenn du für dieses Event kein Badge brauchst, tippe einfach auf Weiter.'**
  String get guideEvBadgeSwitchHint;

  /// No description provided for @guideEvBadgeImageTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Bild'**
  String get guideEvBadgeImageTitle;

  /// No description provided for @guideEvBadgeImageBody.
  ///
  /// In de, this message translates to:
  /// **'Wähle ein Bild aus deiner Galerie — es wird hochgeladen und erscheint später auf jedem Badge dieses Events. Ohne Bild trägt die generative Grafik die Karte allein.'**
  String get guideEvBadgeImageBody;

  /// No description provided for @guideEvBadgeLocationTitle.
  ///
  /// In de, this message translates to:
  /// **'Der Ort zählt'**
  String get guideEvBadgeLocationTitle;

  /// No description provided for @guideEvBadgeLocationBody.
  ///
  /// In de, this message translates to:
  /// **'Setze den Punkt dort, wo das Event stattfindet — nicht dort, wo du gerade bist. Badges lassen sich nur in seiner Nähe und nur am Tag des Events ausgeben.'**
  String get guideEvBadgeLocationBody;

  /// No description provided for @guideEvBadgeIssuersTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Helfer'**
  String get guideEvBadgeIssuersTitle;

  /// No description provided for @guideEvBadgeIssuersBody.
  ///
  /// In de, this message translates to:
  /// **'Trage die npubs aller ein, die vor Ort Badges verteilen sollen. Sie brauchen keine Organisatoren-Rolle — die Erlaubnis steht im Termin und gilt nur für dieses Event. Du selbst darfst immer.'**
  String get guideEvBadgeIssuersBody;

  /// No description provided for @glTitle.
  ///
  /// In de, this message translates to:
  /// **'Nachschlagen'**
  String get glTitle;

  /// No description provided for @glSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Suchen — z. B. Badge, Trust Score, Backup'**
  String get glSearchHint;

  /// No description provided for @glNoResults.
  ///
  /// In de, this message translates to:
  /// **'Dazu findet sich nichts. Versuch ein anderes Wort — gesucht wird auch im Text der Einträge.'**
  String get glNoResults;

  /// No description provided for @glCatStart.
  ///
  /// In de, this message translates to:
  /// **'Erste Schritte'**
  String get glCatStart;

  /// No description provided for @glCatBadges.
  ///
  /// In de, this message translates to:
  /// **'Badges'**
  String get glCatBadges;

  /// No description provided for @glCatReputation.
  ///
  /// In de, this message translates to:
  /// **'Reputation'**
  String get glCatReputation;

  /// No description provided for @glWhatIsAppTitle.
  ///
  /// In de, this message translates to:
  /// **'Was diese App tut'**
  String get glWhatIsAppTitle;

  /// No description provided for @glWhatIsAppBody.
  ///
  /// In de, this message translates to:
  /// **'Sie belegt, dass du bei einem Bitcoin-Meetup wirklich vor Ort warst. Aus vielen solcher Belege entsteht mit der Zeit eine Reputation, die dir gehört und die niemand entziehen kann — sie liegt nicht auf einem Server von Einundzwanzig, sondern signiert im Nostr-Netzwerk.'**
  String get glWhatIsAppBody;

  /// No description provided for @glCollectTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie du ein Badge sammelst'**
  String get glCollectTitle;

  /// No description provided for @glCollectBody.
  ///
  /// In de, this message translates to:
  /// **'Geh zum Meetup und lass dir vom Organisator den QR-Code zeigen. Unten in der Leiste auf den runden Scan-Knopf tippen, Code erfassen — fertig. Das Badge liegt danach in deiner Badge-Wallet.'**
  String get glCollectBody;

  /// No description provided for @glHomeMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Home-Meetup'**
  String get glHomeMeetupTitle;

  /// No description provided for @glHomeMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Das Meetup, zu dem du regelmäßig gehst. Es bestimmt, welche Termine du zuerst siehst und welches Wappen auf deinen Badges erscheint. Du kannst mehrere Favoriten wählen — der erste gilt als Home-Meetup. Ändern lässt sich das jederzeit im Profil.'**
  String get glHomeMeetupBody;

  /// No description provided for @glOfflineTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ohne Internet geht'**
  String get glOfflineTitle;

  /// No description provided for @glOfflineBody.
  ///
  /// In de, this message translates to:
  /// **'Scannen und Badge erhalten funktioniert offline — die Prüfung der Signatur rechnet dein Gerät selbst. Ohne Netz fehlen nur die Dinge, die von außen kommen: Blockhöhe, Kurs, Termine und die Prüfung, ob der Organisator eingetragen ist.'**
  String get glOfflineBody;

  /// No description provided for @glBadgeProofTitle.
  ///
  /// In de, this message translates to:
  /// **'Was ein Badge beweist'**
  String get glBadgeProofTitle;

  /// No description provided for @glBadgeProofBody.
  ///
  /// In de, this message translates to:
  /// **'Dass du zu einer bestimmten Zeit an einem bestimmten Ort warst — bestätigt von jemandem, der dort ebenfalls war. Die Bestätigung ist eine Schnorr-Signatur nach BIP-340. Fälschen kann sie niemand, auch die Entwickler nicht, weil dafür der private Schlüssel des Organisators nötig wäre.'**
  String get glBadgeProofBody;

  /// No description provided for @glRollingQrTitle.
  ///
  /// In de, this message translates to:
  /// **'Der Rolling QR'**
  String get glRollingQrTitle;

  /// No description provided for @glRollingQrBody.
  ///
  /// In de, this message translates to:
  /// **'Der Code des Organisators wechselt alle paar Sekunden. Ein Foto davon ist damit Minuten später wertlos — nur wer wirklich davorsteht, kann ihn erfassen. Genau deshalb lässt sich ein Badge nicht per Chat weiterreichen.'**
  String get glRollingQrBody;

  /// No description provided for @glOnSiteTitle.
  ///
  /// In de, this message translates to:
  /// **'Warum nur vor Ort'**
  String get glOnSiteTitle;

  /// No description provided for @glOnSiteBody.
  ///
  /// In de, this message translates to:
  /// **'Neben dem wechselnden Code prüft die App auch die Entfernung: Wer zu weit vom Meetup entfernt ist, bekommt kein Badge. Bei Meetups sind die Grenzen weit gefasst, weil manche Gruppen ganze Regionen abdecken; bei Sondereevents ist der Ort genau gesetzt und die Grenze eng.'**
  String get glOnSiteBody;

  /// No description provided for @glBadgeShareTitle.
  ///
  /// In de, this message translates to:
  /// **'Badge teilen'**
  String get glBadgeShareTitle;

  /// No description provided for @glBadgeShareBody.
  ///
  /// In de, this message translates to:
  /// **'Öffne ein Badge und tippe oben rechts auf Teilen. Die App erzeugt daraus ein Bild mit Ort, Datum, Blockhöhe und Prüfsumme. Wer es sieht, kann die Angaben nachvollziehen — dein privater Schlüssel steckt nicht darin.'**
  String get glBadgeShareBody;

  /// No description provided for @glTrustScoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Der Trust Score'**
  String get glTrustScoreTitle;

  /// No description provided for @glTrustScoreBody.
  ///
  /// In de, this message translates to:
  /// **'Eine Zahl, die zusammenfasst, wie belastbar deine Anwesenheitsbelege sind. Es zählt nicht nur die Menge: Verschiedene Meetups, verschiedene Organisatoren und Regelmäßigkeit über die Zeit wiegen schwerer als zwanzig Besuche am selben Ort in derselben Woche.'**
  String get glTrustScoreBody;

  /// No description provided for @glLevelsTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Stufen'**
  String get glLevelsTitle;

  /// No description provided for @glLevelsBody.
  ///
  /// In de, this message translates to:
  /// **'Mit steigendem Trust Score erreichst du höhere Stufen. Ab einer bestimmten Stufe kannst du selbst Sessions starten und Badges ausgeben — das ist keine Auszeichnung, sondern eine Verantwortung: Deine Signatur steht dann unter den Badges anderer Leute.'**
  String get glLevelsBody;

  /// No description provided for @glHumanityTitle.
  ///
  /// In de, this message translates to:
  /// **'Proof of Humanity'**
  String get glHumanityTitle;

  /// No description provided for @glHumanityBody.
  ///
  /// In de, this message translates to:
  /// **'Ein einmaliger Lightning-Zap belegt, dass hinter dem Profil jemand mit einer echten Wallet steht. Das ist der wirksamste Schutz gegen automatisch angelegte Konten im Vertrauensnetzwerk. Freiwillig — die App funktioniert auch ohne.'**
  String get glHumanityBody;

  /// No description provided for @glPlatformsTitle.
  ///
  /// In de, this message translates to:
  /// **'Plattform-Nachweise'**
  String get glPlatformsTitle;

  /// No description provided for @glPlatformsBody.
  ///
  /// In de, this message translates to:
  /// **'Du kannst Konten wie Telegram oder X mit deiner Nostr-Identität verknüpfen. Jede bestätigte Plattform zahlt auf den Trust Score ein und zeigt anderen, dass hinter dem Profil eine gewachsene Person steht. Ebenfalls freiwillig.'**
  String get glPlatformsBody;

  /// No description provided for @guideHomeGlossaryTitle.
  ///
  /// In de, this message translates to:
  /// **'Zum Nachschlagen'**
  String get guideHomeGlossaryTitle;

  /// No description provided for @guideHomeGlossaryBody.
  ///
  /// In de, this message translates to:
  /// **'Hier steht alles nochmal in Ruhe erklärt — nach Themen sortiert und durchsuchbar. Wenn diese Tour vorbei ist und eine Frage bleibt, findest du die Antwort hier.'**
  String get guideHomeGlossaryBody;

  /// No description provided for @glCatNetwork.
  ///
  /// In de, this message translates to:
  /// **'Vertrauensnetzwerk'**
  String get glCatNetwork;

  /// No description provided for @glCatIdentity.
  ///
  /// In de, this message translates to:
  /// **'Identität & Schlüssel'**
  String get glCatIdentity;

  /// No description provided for @glCatEvents.
  ///
  /// In de, this message translates to:
  /// **'Events'**
  String get glCatEvents;

  /// No description provided for @glCatNostr.
  ///
  /// In de, this message translates to:
  /// **'Nostr'**
  String get glCatNostr;

  /// No description provided for @glEncounterTitle.
  ///
  /// In de, this message translates to:
  /// **'Begegnungen'**
  String get glEncounterTitle;

  /// No description provided for @glEncounterBody.
  ///
  /// In de, this message translates to:
  /// **'Wer beim selben Organisator am selben Tag gescannt hat, gilt als einander begegnet. Daraus entsteht ein Geflecht aus Menschen, die sich tatsächlich im selben Raum aufgehalten haben — nicht aus Leuten, die einander im Netz folgen.'**
  String get glEncounterBody;

  /// No description provided for @glDegreesTitle.
  ///
  /// In de, this message translates to:
  /// **'Grade'**
  String get glDegreesTitle;

  /// No description provided for @glDegreesBody.
  ///
  /// In de, this message translates to:
  /// **'Ersten Grades heißt: Ihr wart beim selben Organisator. Zweiten Grades: Jemand, den du getroffen hast, hat diese Person getroffen. Waren auf einem Meetup zwei Organisatoren im Einsatz, verbindet ihr gegenseitiges Scannen beide Gruppen — dann seid ihr zweiten Grades verbunden statt ersten.'**
  String get glDegreesBody;

  /// No description provided for @glVouchTitle.
  ///
  /// In de, this message translates to:
  /// **'Bürgschaften'**
  String get glVouchTitle;

  /// No description provided for @glVouchBody.
  ///
  /// In de, this message translates to:
  /// **'Organisatoren können füreinander bürgen. Eine Bürgschaft ist ein öffentliches, signiertes Votum — nach dem Publizieren sieht das ganze Netzwerk, für wen du stehst. Sie lässt sich jederzeit widerrufen, aber der Widerruf ist ebenso sichtbar.'**
  String get glVouchBody;

  /// No description provided for @glEventNetTitle.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk aus Events'**
  String get glEventNetTitle;

  /// No description provided for @glEventNetBody.
  ///
  /// In de, this message translates to:
  /// **'Sondereevents werden getrennt gezählt. Auf einem Meetup mit fünfzehn Leuten trifft man jeden — auf einem Event mit fünfhundert nicht. Beides im selben Topf würde die Aussage des Netzwerks entwerten, deshalb hat es eine eigene Kategorie.'**
  String get glEventNetBody;

  /// No description provided for @glKeysTitle.
  ///
  /// In de, this message translates to:
  /// **'nsec und npub'**
  String get glKeysTitle;

  /// No description provided for @glKeysBody.
  ///
  /// In de, this message translates to:
  /// **'Dein npub ist deine öffentliche Adresse — die darfst und sollst du teilen. Der nsec ist der private Schlüssel und gehört niemandem sonst: Wer ihn hat, IST du. Ein Zurücksetzen gibt es nicht. Ist der nsec weg, ist die Identität samt Reputation verloren.'**
  String get glKeysBody;

  /// No description provided for @glPasswordTitle.
  ///
  /// In de, this message translates to:
  /// **'Die beiden Passwörter'**
  String get glPasswordTitle;

  /// No description provided for @glPasswordBody.
  ///
  /// In de, this message translates to:
  /// **'Beim Einrichten legst du ein Passwort fest, das deinen Schlüssel auf dem Gerät verpackt. Beim Backup vergibst du ein zweites, das die Sicherungsdatei verschlüsselt. Sie dürfen gleich sein, sind aber unabhängig voneinander — und für beide gibt es kein Zurücksetzen.'**
  String get glPasswordBody;

  /// No description provided for @glSignerTitle.
  ///
  /// In de, this message translates to:
  /// **'Signer-Apps'**
  String get glSignerTitle;

  /// No description provided for @glSignerBody.
  ///
  /// In de, this message translates to:
  /// **'Statt den Schlüssel in dieser App zu halten, kannst du ihn einer Signer-App wie Amber anvertrauen oder über einen Bunker anbinden. Diese App fragt dann bei jeder Signatur dort nach und sieht den Schlüssel selbst nie.'**
  String get glSignerBody;

  /// No description provided for @glBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Backup'**
  String get glBackupTitle;

  /// No description provided for @glBackupBody.
  ///
  /// In de, this message translates to:
  /// **'Sichert Schlüssel, Badges und Einstellungen in eine verschlüsselte Datei. Ohne sie ist bei Geräteverlust alles weg — Handy weg heißt sonst Reputation weg. Leg sie früh an, nicht erst wenn du sie brauchst, und bewahre die Datei getrennt vom Passwort auf.'**
  String get glBackupBody;

  /// No description provided for @glSpecialEventTitle.
  ///
  /// In de, this message translates to:
  /// **'Sondereevents'**
  String get glSpecialEventTitle;

  /// No description provided for @glSpecialEventBody.
  ///
  /// In de, this message translates to:
  /// **'Neben den regelmäßigen Meetups gibt es einmalige Veranstaltungen, für die eigene Badges vergeben werden. Sie zählen als Badge und für die Vielfalt der Aussteller, aber nicht als besuchtes Meetup — drei Großevents ersetzen keine lokale Gemeinschaft.'**
  String get glSpecialEventBody;

  /// No description provided for @glEventHelperTitle.
  ///
  /// In de, this message translates to:
  /// **'Helfer beim Event'**
  String get glEventHelperTitle;

  /// No description provided for @glEventHelperBody.
  ///
  /// In de, this message translates to:
  /// **'Wer ein Event mit Badge anlegt, kann beliebige npubs als Aussteller eintragen. Diese Helfer brauchen keine Organisatoren-Rolle — die Erlaubnis steht im Termin und gilt nur für dieses eine Event. Jeder Helfer zeigt dabei seinen eigenen QR-Code.'**
  String get glEventHelperBody;

  /// No description provided for @glEventWindowTitle.
  ///
  /// In de, this message translates to:
  /// **'Ort und Zeitfenster'**
  String get glEventWindowTitle;

  /// No description provided for @glEventWindowBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Event-Badge lässt sich nur am Tag der Veranstaltung und nur in der Nähe des eingetragenen Orts ausgeben. Beides zusammen verhindert, dass jemand von zu Hause aus Badges für eine Veranstaltung verteilt, bei der er gar nicht ist.'**
  String get glEventWindowBody;

  /// No description provided for @glRelaysTitle.
  ///
  /// In de, this message translates to:
  /// **'Relays'**
  String get glRelaysTitle;

  /// No description provided for @glRelaysBody.
  ///
  /// In de, this message translates to:
  /// **'Relays sind die Server, über die Nostr-Nachrichten laufen. Die App schreibt auf mehrere gleichzeitig, damit nichts verloren geht, wenn einer ausfällt. Du kannst in den Einstellungen eigene hinzufügen — sie werden vor dem Speichern auf Erreichbarkeit geprüft.'**
  String get glRelaysBody;

  /// No description provided for @glPublicTitle.
  ///
  /// In de, this message translates to:
  /// **'Was öffentlich ist'**
  String get glPublicTitle;

  /// No description provided for @glPublicBody.
  ///
  /// In de, this message translates to:
  /// **'Badges, Anwesenheiten und Bürgschaften liegen offen auf den Relays — jeder kann sie lesen und nachrechnen, das ist der Sinn der Sache. Nicht öffentlich sind dein privater Schlüssel, dein Backup-Passwort und dein genauer Standort.'**
  String get glPublicBody;

  /// No description provided for @glZapTitle.
  ///
  /// In de, this message translates to:
  /// **'Zaps'**
  String get glZapTitle;

  /// No description provided for @glZapBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Zap ist eine kleine Lightning-Zahlung mit einer Nostr-Quittung daran. In den News kannst du damit Autoren direkt etwas zukommen lassen; die Rechnung übergibt die App an deine Wallet. Ein einmaliger Zap dient außerdem als Proof of Humanity.'**
  String get glZapBody;

  /// No description provided for @guideEvBasicsTitle.
  ///
  /// In de, this message translates to:
  /// **'Titel und Ort'**
  String get guideEvBasicsTitle;

  /// No description provided for @guideEvBasicsBody.
  ///
  /// In de, this message translates to:
  /// **'Der Titel steht später in der Terminliste und auf dem Badge, falls du eines vergibst. Der Ort ist die Anschrift zum Vorlesen — die Koordinaten für die Badge-Ausgabe setzt du weiter unten getrennt auf der Karte.'**
  String get guideEvBasicsBody;

  /// No description provided for @guideEvWhenWhereTitle.
  ///
  /// In de, this message translates to:
  /// **'Wann es stattfindet'**
  String get guideEvWhenWhereTitle;

  /// No description provided for @guideEvWhenWhereBody.
  ///
  /// In de, this message translates to:
  /// **'Start ist Pflicht, das Ende darfst du weglassen. Bei einem Event mit Badge zählt der Kalendertag: Badges lassen sich nur an diesem Tag ausgeben, von Mitternacht bis Mitternacht.'**
  String get guideEvWhenWhereBody;

  /// No description provided for @glCatApp.
  ///
  /// In de, this message translates to:
  /// **'App & Bedienung'**
  String get glCatApp;

  /// No description provided for @glTilesTitle.
  ///
  /// In de, this message translates to:
  /// **'Dashboard anpassen'**
  String get glTilesTitle;

  /// No description provided for @glTilesBody.
  ///
  /// In de, this message translates to:
  /// **'Halte eine Kachel lange gedrückt, um sie zu verschieben oder auszublenden. Trust Score und Home-Meetup bleiben immer sichtbar, alles andere kannst du loslösen. Ausgeblendete Kacheln landen in der Verwaltung und lassen sich jederzeit zurückholen.'**
  String get glTilesBody;

  /// No description provided for @glLanguageTitle.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get glLanguageTitle;

  /// No description provided for @glLanguageBody.
  ///
  /// In de, this message translates to:
  /// **'Die App gibt es auf Deutsch, Englisch und Spanisch. Ohne eigene Wahl folgt sie der Systemsprache. Umstellen kannst du sie in den Einstellungen; die Änderung greift sofort, ein Neustart ist nicht nötig.'**
  String get glLanguageBody;

  /// No description provided for @glLogTitle.
  ///
  /// In de, this message translates to:
  /// **'Diagnose-Log'**
  String get glLogTitle;

  /// No description provided for @glLogBody.
  ///
  /// In de, this message translates to:
  /// **'Ein Protokoll dessen, was die App im Hintergrund tut — welche Relays geantwortet haben, warum ein Scan abgelehnt wurde. Wenn etwas klemmt, ist das die erste Anlaufstelle. Es bleibt auf dem Gerät und wird nirgends hochgeladen.'**
  String get glLogBody;

  /// No description provided for @glResetTitle.
  ///
  /// In de, this message translates to:
  /// **'App zurücksetzen'**
  String get glResetTitle;

  /// No description provided for @glResetBody.
  ///
  /// In de, this message translates to:
  /// **'Löscht Profil, Schlüssel und alle Badges vom Gerät — endgültig. Ohne Backup ist deine Identität danach weg, auch wenn die Badges auf den Relays weiterleben: Ohne den passenden Schlüssel kannst du sie niemandem mehr zuordnen. Mach vorher ein Backup.'**
  String get glResetBody;

  /// No description provided for @glNicknameTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Anzeigename'**
  String get glNicknameTitle;

  /// No description provided for @glNicknameBody.
  ///
  /// In de, this message translates to:
  /// **'Der Name, unter dem du im Netzwerk erscheinst. Er ist frei wählbar, muss nicht dein echter sein und lässt sich jederzeit ändern — deine Identität hängt am Schlüssel, nicht am Namen.'**
  String get glNicknameBody;

  /// No description provided for @glFindMeetupTitle.
  ///
  /// In de, this message translates to:
  /// **'Meetups finden'**
  String get glFindMeetupTitle;

  /// No description provided for @glFindMeetupBody.
  ///
  /// In de, this message translates to:
  /// **'Über die Meetup-Suche kommst du an alle eingetragenen Gruppen. In der Nähe zeigt dir stattdessen, was rund um deinen aktuellen Standort liegt — nützlich auf Reisen oder wenn du eine zweite Gruppe in der Region suchst.'**
  String get glFindMeetupBody;

  /// No description provided for @glBlockHeightTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Blockhöhe'**
  String get glBlockHeightTitle;

  /// No description provided for @glBlockHeightBody.
  ///
  /// In de, this message translates to:
  /// **'Jedes Badge trägt die Nummer des Bitcoin-Blocks, der beim Scan gerade aktuell war. Sie wirkt wie ein Zeitstempel, den niemand nachträglich verschieben kann — anders als die Uhr eines Handys, die sich beliebig stellen lässt.'**
  String get glBlockHeightBody;

  /// No description provided for @glChecksumTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Prüfsumme'**
  String get glChecksumTitle;

  /// No description provided for @glChecksumBody.
  ///
  /// In de, this message translates to:
  /// **'Ein kurzer Fingerabdruck über den gesamten Badge-Inhalt. Zwei Menschen können ihre Badges vom selben Meetup vergleichen: Stimmen die Prüfsummen überein, haben beide dieselben Daten erhalten. Sie steht in den Badge-Details und auf dem geteilten Bild.'**
  String get glChecksumBody;

  /// No description provided for @glWorldMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Badge-Weltkarte'**
  String get glWorldMapTitle;

  /// No description provided for @glWorldMapBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt deine gesammelten Badges dort, wo du sie bekommen hast. Aus einer Liste von Namen wird so eine Landkarte deiner Meetup-Besuche — praktisch, um zu sehen, wo noch weiße Flecken sind.'**
  String get glWorldMapBody;

  /// No description provided for @glDuplicateTitle.
  ///
  /// In de, this message translates to:
  /// **'Doppelte Badges'**
  String get glDuplicateTitle;

  /// No description provided for @glDuplicateBody.
  ///
  /// In de, this message translates to:
  /// **'Pro Meetup und Tag gibt es genau ein Badge. Wer denselben Code zweimal scannt, bekommt kein zweites — das ist Absicht: Ein Badge steht für einen Besuch, nicht für einen Scan.'**
  String get glDuplicateBody;

  /// No description provided for @glVerifyPersonTitle.
  ///
  /// In de, this message translates to:
  /// **'Jemanden prüfen'**
  String get glVerifyPersonTitle;

  /// No description provided for @glVerifyPersonBody.
  ///
  /// In de, this message translates to:
  /// **'Lass dir den Reputations-QR der anderen Person zeigen und scanne ihn. Die App rechnet nach, ob die Angaben zu den signierten Badges passen, und zeigt dir, wie ihr im Netzwerk verbunden seid. Nützlich vor einem Handel unter Fremden.'**
  String get glVerifyPersonBody;

  /// No description provided for @glRepCardTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Reputationskarte'**
  String get glRepCardTitle;

  /// No description provided for @glRepCardBody.
  ///
  /// In de, this message translates to:
  /// **'Eine teilbare Übersicht deiner Reputation als Bild — Stufe, Anzahl der Meetups, Zeitraum. Sie enthält keinen privaten Schlüssel und lässt sich bedenkenlos posten.'**
  String get glRepCardBody;

  /// No description provided for @glPublishTitle.
  ///
  /// In de, this message translates to:
  /// **'Reputation veröffentlichen'**
  String get glPublishTitle;

  /// No description provided for @glPublishBody.
  ///
  /// In de, this message translates to:
  /// **'Damit andere deine Reputation prüfen können, muss sie auf den Relays liegen. Die App veröffentlicht sie signiert; ohne diesen Schritt sieht ein Gegenüber nur, was du ihm direkt zeigst.'**
  String get glPublishBody;

  /// No description provided for @glTrustPathTitle.
  ///
  /// In de, this message translates to:
  /// **'Vertrauenspfad'**
  String get glTrustPathTitle;

  /// No description provided for @glTrustPathBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt die Kette, über die du mit einer anderen Person verbunden bist — wer wen wo getroffen hat. Aus einer abstrakten Zahl wird damit eine nachvollziehbare Aussage: nicht nur dass ihr verbunden seid, sondern worüber.'**
  String get glTrustPathBody;

  /// No description provided for @glDistrustTitle.
  ///
  /// In de, this message translates to:
  /// **'Meldungen und Suspendierung'**
  String get glDistrustTitle;

  /// No description provided for @glDistrustBody.
  ///
  /// In de, this message translates to:
  /// **'Organisatoren können Missbrauch melden. Häufen sich Meldungen gegen jemanden, wird er im Netzwerk als suspendiert markiert — seine Badges verschwinden nicht, aber sie tragen diese Warnung. Auch eine Meldung ist signiert und damit dem Melder zuzuordnen.'**
  String get glDistrustBody;

  /// No description provided for @glOrganizerTitle.
  ///
  /// In de, this message translates to:
  /// **'Organisator werden'**
  String get glOrganizerTitle;

  /// No description provided for @glOrganizerBody.
  ///
  /// In de, this message translates to:
  /// **'Ab einem bestimmten Trust Score kannst du selbst Sessions starten. Zusätzlich brauchst du in der Regel Bürgschaften bestehender Organisatoren — die Rolle wird nicht vergeben, sie wächst aus dem Netzwerk.'**
  String get glOrganizerBody;

  /// No description provided for @glNcryptsecTitle.
  ///
  /// In de, this message translates to:
  /// **'ncryptsec'**
  String get glNcryptsecTitle;

  /// No description provided for @glNcryptsecBody.
  ///
  /// In de, this message translates to:
  /// **'Ein nsec, der mit einem Passwort verschlüsselt ist (NIP-49). Die Zeichenfolge beginnt mit ncryptsec1 und ist ohne Passwort wertlos — sie lässt sich also gefahrloser transportieren als ein blanker nsec. Genau so liegt dein Schlüssel auch auf dem Gerät.'**
  String get glNcryptsecBody;

  /// No description provided for @glPasskeyTitle.
  ///
  /// In de, this message translates to:
  /// **'Passkey'**
  String get glPasskeyTitle;

  /// No description provided for @glPasskeyBody.
  ///
  /// In de, this message translates to:
  /// **'Zusätzlicher Schutz per Fingerabdruck oder Gesichtserkennung. Der Passkey ersetzt dein Passwort nicht, er legt sich davor. Freiwillig, und nur auf diesem Gerät — auf einem neuen brauchst du wieder Passwort oder Backup.'**
  String get glPasskeyBody;

  /// No description provided for @glNip05Title.
  ///
  /// In de, this message translates to:
  /// **'NIP-05-Adresse'**
  String get glNip05Title;

  /// No description provided for @glNip05Body.
  ///
  /// In de, this message translates to:
  /// **'Eine lesbare Adresse der Form name@domain, die auf deinen Schlüssel zeigt — wie ein Namensschild fürs Netzwerk. Sie beweist, dass jemand mit Zugriff auf diese Domain für dich bürgt, ersetzt aber keine der anderen Prüfungen.'**
  String get glNip05Body;

  /// No description provided for @glImportTitle.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel mitbringen'**
  String get glImportTitle;

  /// No description provided for @glImportBody.
  ///
  /// In de, this message translates to:
  /// **'Wer schon eine Nostr-Identität hat, kann sie hier einsetzen — als nsec, als ncryptsec oder über einen Bunker. Deine bestehenden Kontakte und dein Profil bleiben dabei erhalten; die App legt nur Badges und Reputation dazu.'**
  String get glImportBody;

  /// No description provided for @glRestoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup einspielen'**
  String get glRestoreTitle;

  /// No description provided for @glRestoreBody.
  ///
  /// In de, this message translates to:
  /// **'Beim Einrichten kannst du statt eines neuen Schlüssels ein Backup laden. Du brauchst die Datei UND das Passwort, mit dem sie verschlüsselt wurde — eines allein genügt nicht. Danach ist die Identität samt Badges wieder da.'**
  String get glRestoreBody;

  /// No description provided for @glCalendarSourcesTitle.
  ///
  /// In de, this message translates to:
  /// **'Woher die Termine kommen'**
  String get glCalendarSourcesTitle;

  /// No description provided for @glCalendarSourcesBody.
  ///
  /// In de, this message translates to:
  /// **'Der Kalender führt zwei Quellen zusammen: Termine aus dem Einundzwanzig-Portal und Veranstaltungen, die jemand über Nostr eingetragen hat. Die Farbe unterscheidet sie — Portal-Meetups orange, Nostr-Termine türkis.'**
  String get glCalendarSourcesBody;

  /// No description provided for @glPortalTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Portal-Verbindung'**
  String get glPortalTitle;

  /// No description provided for @glPortalBody.
  ///
  /// In de, this message translates to:
  /// **'Mit deinem Nostr-Schlüssel kannst du dich am Einundzwanzig-Portal anmelden. Danach siehst du dort gepflegte Termine und Kurse und kannst als Leader eigene Termine anlegen. Ohne Verbindung funktioniert alles andere weiterhin.'**
  String get glPortalBody;

  /// No description provided for @glCreateEventTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin anlegen'**
  String get glCreateEventTitle;

  /// No description provided for @glCreateEventBody.
  ///
  /// In de, this message translates to:
  /// **'Jeder kann einen Termin eintragen — er wird signiert auf Nostr veröffentlicht und erscheint bei allen im Kalender. Ein Badge dazu vergeben dürfen allerdings nur Organisatoren und Leader.'**
  String get glCreateEventBody;

  /// No description provided for @glNostrBasicsTitle.
  ///
  /// In de, this message translates to:
  /// **'Was Nostr ist'**
  String get glNostrBasicsTitle;

  /// No description provided for @glNostrBasicsBody.
  ///
  /// In de, this message translates to:
  /// **'Ein offenes Protokoll für Nachrichten, die ihr Absender selbst signiert. Es gibt kein Unternehmen dahinter und kein Konto, das gesperrt werden könnte — nur Schlüssel und Relays. Deine Identität aus dieser App funktioniert deshalb auch in anderen Nostr-Anwendungen.'**
  String get glNostrBasicsBody;

  /// No description provided for @glNewsTitle.
  ///
  /// In de, this message translates to:
  /// **'Der News-Bereich'**
  String get glNewsTitle;

  /// No description provided for @glNewsBody.
  ///
  /// In de, this message translates to:
  /// **'Die Artikel stammen aus dem Einundzwanzig-Magazin und liegen als Nostr-Langtexte vor. Du kannst sie in der App lesen, mit einem Herz versehen, teilen und den Autoren Sats zappen — alles über dieselbe Identität.'**
  String get glNewsBody;

  /// No description provided for @glConverterTitle.
  ///
  /// In de, this message translates to:
  /// **'Umrechner und Kurs'**
  String get glConverterTitle;

  /// No description provided for @glConverterBody.
  ///
  /// In de, this message translates to:
  /// **'Rechnet Euro in Sats um und zurück. Der Kurs und die Blockhöhe kommen von einer Mempool-Instanz; welche das ist, kannst du in den Einstellungen ändern — etwa auf deine eigene Node.'**
  String get glConverterBody;

  /// No description provided for @glCommunityTitle.
  ///
  /// In de, this message translates to:
  /// **'Community-Bereich'**
  String get glCommunityTitle;

  /// No description provided for @glCommunityBody.
  ///
  /// In de, this message translates to:
  /// **'Sammelpunkt für alles rund um Einundzwanzig, was nicht direkt mit Badges zu tun hat: Podcast, Shoutouts, PlebRap, SatoshiDuell und die Meetup-Karte. Vieles davon öffnet sich im Browser.'**
  String get glCommunityBody;

  /// No description provided for @settingsRestartGuide.
  ///
  /// In de, this message translates to:
  /// **'Tour wiederholen'**
  String get settingsRestartGuide;

  /// No description provided for @settingsRestartGuideSub.
  ///
  /// In de, this message translates to:
  /// **'Alle Spotlight-Touren erneut anzeigen'**
  String get settingsRestartGuideSub;

  /// No description provided for @settingsGuideReset.
  ///
  /// In de, this message translates to:
  /// **'Touren zurückgesetzt — sie starten beim nächsten Öffnen der Bereiche.'**
  String get settingsGuideReset;

  /// No description provided for @guideSettingsRestartTitle.
  ///
  /// In de, this message translates to:
  /// **'Tour wiederholen'**
  String get guideSettingsRestartTitle;

  /// No description provided for @guideSettingsRestartBody.
  ///
  /// In de, this message translates to:
  /// **'Setzt alle Spotlight-Touren zurück. Sie starten dann wieder, sobald du den jeweiligen Bereich das nächste Mal öffnest — nützlich, wenn du etwas noch einmal sehen willst.'**
  String get guideSettingsRestartBody;

  /// No description provided for @guideWalletMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Weltkarte'**
  String get guideWalletMapTitle;

  /// No description provided for @guideWalletMapBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt deine Badges dort, wo du sie eingesammelt hast. Aus einer Liste wird eine Landkarte deiner Meetup-Besuche.'**
  String get guideWalletMapBody;

  /// No description provided for @guideWalletViewTitle.
  ///
  /// In de, this message translates to:
  /// **'Ansicht wechseln'**
  String get guideWalletViewTitle;

  /// No description provided for @guideWalletViewBody.
  ///
  /// In de, this message translates to:
  /// **'Umschalten zwischen großen Karten und einer kompakten Übersicht. Bei vielen Badges ist die kompakte Ansicht schneller zu überblicken.'**
  String get guideWalletViewBody;

  /// No description provided for @guideCommunityPortalTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Portal'**
  String get guideCommunityPortalTitle;

  /// No description provided for @guideCommunityPortalBody.
  ///
  /// In de, this message translates to:
  /// **'Der Zugang zu Meetups, Terminen, Kursen und der Karte auf einundzwanzig.space. Vieles davon öffnet sich im Browser.'**
  String get guideCommunityPortalBody;

  /// No description provided for @guideCommunityNewsTitle.
  ///
  /// In de, this message translates to:
  /// **'News und Nostr'**
  String get guideCommunityNewsTitle;

  /// No description provided for @guideCommunityNewsBody.
  ///
  /// In de, this message translates to:
  /// **'Artikel aus dem Einundzwanzig-Magazin und die neuesten Notizen aus deinem Nostr-Netzwerk — beides direkt in der App lesbar.'**
  String get guideCommunityNewsBody;

  /// No description provided for @guideCommunityFunTitle.
  ///
  /// In de, this message translates to:
  /// **'Zum Mitmachen'**
  String get guideCommunityFunTitle;

  /// No description provided for @guideCommunityFunBody.
  ///
  /// In de, this message translates to:
  /// **'SatoshiDuell für Quizrunden um Sats und PlebRap für Musik aus der Community. Beides braucht nichts weiter als deine Identität.'**
  String get guideCommunityFunBody;

  /// No description provided for @guideMyMeetupsListTitle.
  ///
  /// In de, this message translates to:
  /// **'Deine Meetups'**
  String get guideMyMeetupsListTitle;

  /// No description provided for @guideMyMeetupsListBody.
  ///
  /// In de, this message translates to:
  /// **'Die Meetups, für die du im Portal eingetragen bist. Tippe eines an, um seine Termine zu sehen und zu pflegen — dort legst du mit dem Knopf unten auch neue an.'**
  String get guideMyMeetupsListBody;

  /// No description provided for @guideMyMeetupsCreateTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin anlegen'**
  String get guideMyMeetupsCreateTitle;

  /// No description provided for @guideMyMeetupsCreateBody.
  ///
  /// In de, this message translates to:
  /// **'Trägt einen neuen Termin im Portal ein. Er erscheint danach im Kalender aller, die dieses Meetup als Favorit haben.'**
  String get guideMyMeetupsCreateBody;

  /// No description provided for @guideWotTabsTitle.
  ///
  /// In de, this message translates to:
  /// **'Die drei Ansichten'**
  String get guideWotTabsTitle;

  /// No description provided for @guideWotTabsBody.
  ///
  /// In de, this message translates to:
  /// **'Netzwerk zeigt, wer mit wem verbunden ist. Bürgen zeigt, für wen du stehst und wer für dich. Meldungen sammelt die Warnungen aus dem Netzwerk.'**
  String get guideWotTabsBody;

  /// No description provided for @guideWotRefreshTitle.
  ///
  /// In de, this message translates to:
  /// **'Neu laden'**
  String get guideWotRefreshTitle;

  /// No description provided for @guideWotRefreshBody.
  ///
  /// In de, this message translates to:
  /// **'Holt den aktuellen Stand von den Relays. Das Netzwerk wächst mit jedem Meetup — ohne Nachladen siehst du den Stand vom letzten Öffnen.'**
  String get guideWotRefreshBody;

  /// No description provided for @guideHomeCustomizeTitle.
  ///
  /// In de, this message translates to:
  /// **'Dein Dashboard'**
  String get guideHomeCustomizeTitle;

  /// No description provided for @guideHomeCustomizeBody.
  ///
  /// In de, this message translates to:
  /// **'Unter dieser Überschrift liegen die Kacheln, die du gerade nicht angeheftet hast — sie sind nicht weg, nur zurückgestellt. Halte eine Kachel lange gedrückt, um sie anzuheften, zu lösen oder zu verschieben. So bekommst du oben genau das, was du wirklich benutzt.'**
  String get guideHomeCustomizeBody;

  /// No description provided for @guidePaMeetupsTitle.
  ///
  /// In de, this message translates to:
  /// **'Meetups und Termine'**
  String get guidePaMeetupsTitle;

  /// No description provided for @guidePaMeetupsBody.
  ///
  /// In de, this message translates to:
  /// **'Beide führen in den Kalender: das eine zu den Gruppen, das andere zu den nächsten Terminen. Was du dort siehst, hängt an deinen Favoriten — mit mehr Favoriten wird die Liste voller.'**
  String get guidePaMeetupsBody;

  /// No description provided for @guidePaCoursesTitle.
  ///
  /// In de, this message translates to:
  /// **'Kurse'**
  String get guidePaCoursesTitle;

  /// No description provided for @guidePaCoursesBody.
  ///
  /// In de, this message translates to:
  /// **'Die Bildungsangebote von Einundzwanzig samt Dozenten — vom Einsteigerabend bis zur mehrteiligen Reihe. Ein Tipp auf einen Kurs zeigt Inhalt, Termine und wer ihn hält.'**
  String get guidePaCoursesBody;

  /// No description provided for @guidePaMapTitle.
  ///
  /// In de, this message translates to:
  /// **'Die Karte'**
  String get guidePaMapTitle;

  /// No description provided for @guidePaMapBody.
  ///
  /// In de, this message translates to:
  /// **'Zeigt Meetups in deiner Umgebung auf einer Landkarte. Praktisch auf Reisen — oder wenn du wissen willst, was es außer deinem Home-Meetup noch in der Region gibt.'**
  String get guidePaMapBody;

  /// No description provided for @guidePaMineTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get guidePaMineTitle;

  /// No description provided for @guidePaMineBody.
  ///
  /// In de, this message translates to:
  /// **'Nur für Organisatoren interessant: Hier pflegst du die Termine der Meetups, für die du im Portal eingetragen bist. Wer keines betreut, findet hier eine leere Liste.'**
  String get guidePaMineBody;

  /// No description provided for @guideSettingsProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Profil und Schlüssel'**
  String get guideSettingsProfileTitle;

  /// No description provided for @guideSettingsProfileBody.
  ///
  /// In de, this message translates to:
  /// **'Hier änderst du deinen Namen und dein Home-Meetup — und hier liegen deine Nostr-Schlüssel. Ganz unten kannst du den npub kopieren und dir den nsec anzeigen lassen. Wenn die App dir einen Schlüssel erstellt hat, ist das der Ort, an dem du ihn findest.'**
  String get guideSettingsProfileBody;

  /// No description provided for @glFindKeysTitle.
  ///
  /// In de, this message translates to:
  /// **'Wo finde ich meine Schlüssel?'**
  String get glFindKeysTitle;

  /// No description provided for @glFindKeysBody.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen → Profil, ganz unten. Dort kopierst du den npub mit einem Tipp und lässt dir den nsec anzeigen — letzteres nur nach einer Warnung, denn wer den nsec sieht, hat deine Identität. Nutzt du Amber, eine Browsererweiterung oder einen Bunker, gibt es hier keinen nsec: Der liegt dann dort und nicht in dieser App.'**
  String get glFindKeysBody;

  /// No description provided for @idSetupSecureTitle.
  ///
  /// In de, this message translates to:
  /// **'Identität erstellt — jetzt sichern'**
  String get idSetupSecureTitle;

  /// No description provided for @idSetupSecureBody.
  ///
  /// In de, this message translates to:
  /// **'Es gibt zwei Arten zu sichern — sie können unterschiedliche Dinge. Am besten machst du beides.'**
  String get idSetupSecureBody;

  /// No description provided for @idSetupSecureBackup.
  ///
  /// In de, this message translates to:
  /// **'Backup erstellen'**
  String get idSetupSecureBackup;

  /// No description provided for @idSetupSecureCopy.
  ///
  /// In de, this message translates to:
  /// **'Schlüssel in die Zwischenablage'**
  String get idSetupSecureCopy;

  /// No description provided for @idSetupSecureWhere.
  ///
  /// In de, this message translates to:
  /// **'Deine Schlüssel findest du jederzeit unter Einstellungen → Profil.'**
  String get idSetupSecureWhere;

  /// No description provided for @idSetupSecureBackupTitle.
  ///
  /// In de, this message translates to:
  /// **'Backup-Datei'**
  String get idSetupSecureBackupTitle;

  /// No description provided for @idSetupSecureBackupBody.
  ///
  /// In de, this message translates to:
  /// **'Enthält alles: Schlüssel, Badges, Reputation und Einstellungen. Damit steht deine App auf einem neuen Gerät wieder genau so da. Die Datei ist mit einem eigenen Passwort verschlüsselt.'**
  String get idSetupSecureBackupBody;

  /// No description provided for @idSetupSecureKeyTitle.
  ///
  /// In de, this message translates to:
  /// **'Verschlüsselter Schlüssel'**
  String get idSetupSecureKeyTitle;

  /// No description provided for @idSetupSecureKeyBody.
  ///
  /// In de, this message translates to:
  /// **'Zum Schluss noch dein Nostr-Schlüssel allein, mit deinem Passwort verpackt (ncryptsec). Er rettet deine Identität, aber keine Badges — dafür veraltet er nie und passt in jeden Passwortmanager.'**
  String get idSetupSecureKeyBody;

  /// No description provided for @idSetupSecureRepeat.
  ///
  /// In de, this message translates to:
  /// **'Wiederhole das Backup ab und zu unter Einstellungen → Backup. Eine Datei von heute kennt die Badges von morgen nicht — was danach dazukommt, wäre bei einem Geräteverlust weg.'**
  String get idSetupSecureRepeat;

  /// No description provided for @idSetupSecureKeySave.
  ///
  /// In de, this message translates to:
  /// **'Als Datei speichern'**
  String get idSetupSecureKeySave;

  /// No description provided for @idSetupSecureKeySaved.
  ///
  /// In de, this message translates to:
  /// **'Schlüsseldatei gespeichert.'**
  String get idSetupSecureKeySaved;

  /// No description provided for @idSetupSecureSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get idSetupSecureSkip;

  /// No description provided for @idSetupSecureFileHeader.
  ///
  /// In de, this message translates to:
  /// **'Einundzwanzig Meetup App — verschlüsselter Nostr-Schlüssel (ncryptsec, NIP-49). Ohne das zugehörige Passwort ist diese Datei wertlos. Bewahre beides getrennt auf.'**
  String get idSetupSecureFileHeader;

  /// No description provided for @chatRelayHint.
  ///
  /// In de, this message translates to:
  /// **'Gruppen-Relay von Einundzwanzig'**
  String get chatRelayHint;

  /// No description provided for @chatEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Nachrichten. Schreib die erste — der Raum liegt offen auf dem Relay und ist auch aus anderen Nostr-Apps erreichbar.'**
  String get chatEmpty;

  /// No description provided for @chatPlaceholder.
  ///
  /// In de, this message translates to:
  /// **'Nachricht schreiben …'**
  String get chatPlaceholder;

  /// No description provided for @chatJoin.
  ///
  /// In de, this message translates to:
  /// **'Dem Raum beitreten'**
  String get chatJoin;

  /// No description provided for @chatJoinHint.
  ///
  /// In de, this message translates to:
  /// **'Mitlesen kannst du hier ohne Weiteres. Zum Mitschreiben musst du dem Raum beitreten — die Mitgliederliste führt das Relay.'**
  String get chatJoinHint;

  /// No description provided for @chatJoinFailed.
  ///
  /// In de, this message translates to:
  /// **'Beitritt abgelehnt: {msg}'**
  String chatJoinFailed(String msg);

  /// No description provided for @chatSendFailed.
  ///
  /// In de, this message translates to:
  /// **'Nachricht nicht angekommen: {msg}'**
  String chatSendFailed(String msg);

  /// No description provided for @chatSearching.
  ///
  /// In de, this message translates to:
  /// **'Chatraum wird gesucht …'**
  String get chatSearching;

  /// No description provided for @chatNoRoom.
  ///
  /// In de, this message translates to:
  /// **'Für {city} gibt es auf dem Gruppen-Relay noch keinen Chatraum. Einzelheiten stehen im Diagnose-Log.'**
  String chatNoRoom(String city);

  /// No description provided for @chatEventOpen.
  ///
  /// In de, this message translates to:
  /// **'Chat zum Termin'**
  String get chatEventOpen;

  /// No description provided for @chatEventFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Chatraum konnte nicht geöffnet werden. Einzelheiten stehen im Diagnose-Log.'**
  String get chatEventFailed;

  /// No description provided for @btnChat.
  ///
  /// In de, this message translates to:
  /// **'Chat'**
  String get btnChat;

  /// No description provided for @btnInfo.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get btnInfo;

  /// No description provided for @chatEventHint.
  ///
  /// In de, this message translates to:
  /// **'Beiträge zum Termin · öffentlich auf Nostr'**
  String get chatEventHint;

  /// No description provided for @chatEventEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch nichts geschrieben. Teile hier Infos zum Termin — Treffpunkt, Änderungen, Fragen. Die Beiträge hängen am Termin selbst und sind aus jeder Nostr-App zu sehen.'**
  String get chatEventEmpty;

  /// No description provided for @chatMemberHint.
  ///
  /// In de, this message translates to:
  /// **'Der Beitritt setzt eine Mitgliedschaft im Einundzwanzig-Verein voraus. Ohne sie lehnt das Relay den Beitritt ab — du bleibst dann stiller Mitleser.'**
  String get chatMemberHint;

  /// No description provided for @chatMemberLink.
  ///
  /// In de, this message translates to:
  /// **'Zum Verein'**
  String get chatMemberLink;

  /// No description provided for @walletSince.
  ///
  /// In de, this message translates to:
  /// **'seit {month}'**
  String walletSince(String month);

  /// No description provided for @walletLastVisit.
  ///
  /// In de, this message translates to:
  /// **'zuletzt {ago}'**
  String walletLastVisit(String ago);

  /// No description provided for @walletAgoToday.
  ///
  /// In de, this message translates to:
  /// **'heute'**
  String get walletAgoToday;

  /// No description provided for @walletAgoYesterday.
  ///
  /// In de, this message translates to:
  /// **'gestern'**
  String get walletAgoYesterday;

  /// No description provided for @walletAgoDays.
  ///
  /// In de, this message translates to:
  /// **'vor {days} Tagen'**
  String walletAgoDays(int days);

  /// No description provided for @walletAgoMonths.
  ///
  /// In de, this message translates to:
  /// **'vor {months} Monaten'**
  String walletAgoMonths(int months);

  /// No description provided for @walletAgoYears.
  ///
  /// In de, this message translates to:
  /// **'vor {years} Jahren'**
  String walletAgoYears(int years);

  /// No description provided for @walletCollectionCount.
  ///
  /// In de, this message translates to:
  /// **'{count} Badges'**
  String walletCollectionCount(int count);

  /// No description provided for @rsvpYes.
  ///
  /// In de, this message translates to:
  /// **'Ich komme'**
  String get rsvpYes;

  /// No description provided for @rsvpNo.
  ///
  /// In de, this message translates to:
  /// **'Ich komme nicht'**
  String get rsvpNo;

  /// No description provided for @tileEventChats.
  ///
  /// In de, this message translates to:
  /// **'Meine Termine'**
  String get tileEventChats;

  /// No description provided for @tileEventChatsSub.
  ///
  /// In de, this message translates to:
  /// **'Zusagen & Chats'**
  String get tileEventChatsSub;

  /// No description provided for @eventChatsTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Termine'**
  String get eventChatsTitle;

  /// No description provided for @eventChatsEmpty.
  ///
  /// In de, this message translates to:
  /// **'Hier stehen die nächsten Termine deiner Meetups und alle Veranstaltungen, für die du zugesagt hast. Wähle ein Meetup als Favorit oder sage im Kalender zu.'**
  String get eventChatsEmpty;

  /// No description provided for @tileEventChatsUnread.
  ///
  /// In de, this message translates to:
  /// **'{count} neue Nachrichten'**
  String tileEventChatsUnread(int count);

  /// No description provided for @chatYou.
  ///
  /// In de, this message translates to:
  /// **'Du'**
  String get chatYou;

  /// No description provided for @chatCopyNpub.
  ///
  /// In de, this message translates to:
  /// **'npub kopieren'**
  String get chatCopyNpub;

  /// No description provided for @chatNpubCopied.
  ///
  /// In de, this message translates to:
  /// **'npub kopiert.'**
  String get chatNpubCopied;

  /// No description provided for @eventChatsMeetups.
  ///
  /// In de, this message translates to:
  /// **'Meine Meetups'**
  String get eventChatsMeetups;

  /// No description provided for @eventChatsEvents.
  ///
  /// In de, this message translates to:
  /// **'Zugesagte Veranstaltungen'**
  String get eventChatsEvents;

  /// No description provided for @tileEventChatsNone.
  ///
  /// In de, this message translates to:
  /// **'Nichts geplant'**
  String get tileEventChatsNone;

  /// No description provided for @rsvpAttendees.
  ///
  /// In de, this message translates to:
  /// **'{count} dabei'**
  String rsvpAttendees(int count);

  /// No description provided for @rsvpWithdrawTitle.
  ///
  /// In de, this message translates to:
  /// **'Zusage zurücknehmen?'**
  String get rsvpWithdrawTitle;

  /// No description provided for @rsvpWithdrawBody.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ verschwindet dann aus deinen Terminen. Der Veranstalter sieht eine Absage — der Chat bleibt über den Kalender erreichbar.'**
  String rsvpWithdrawBody(String title);

  /// No description provided for @rsvpWithdrawConfirm.
  ///
  /// In de, this message translates to:
  /// **'Absagen'**
  String get rsvpWithdrawConfirm;

  /// No description provided for @evBadgeNeedLocation.
  ///
  /// In de, this message translates to:
  /// **'Für ein Badge braucht der Termin einen Ort auf der Karte — daran wird geprüft, wer vor Ort ist.'**
  String get evBadgeNeedLocation;

  /// No description provided for @evBadgeNoLocationSet.
  ///
  /// In de, this message translates to:
  /// **'Für diesen Termin ist kein Ort auf der Karte hinterlegt — dadurch lässt sich hier kein Badge ausgeben oder abholen.'**
  String get evBadgeNoLocationSet;

  /// No description provided for @mvPortalOrganizer.
  ///
  /// In de, this message translates to:
  /// **'✓ Organisator von {meetup}\nIm Einundzwanzig-Portal als Leader dieses Meetups eingetragen.'**
  String mvPortalOrganizer(String meetup);

  /// No description provided for @evCancelAction.
  ///
  /// In de, this message translates to:
  /// **'Termin absagen'**
  String get evCancelAction;

  /// No description provided for @evCancelTitle.
  ///
  /// In de, this message translates to:
  /// **'Termin absagen?'**
  String get evCancelTitle;

  /// No description provided for @evCancelBody.
  ///
  /// In de, this message translates to:
  /// **'„{title}“ verschwindet aus allen Kalendern. Nostr kennt kein echtes Löschen — der Termin wird als abgesagt markiert und zusätzlich zur Entfernung gebeten. Rückgängig geht das nicht; du müsstest ihn neu anlegen.'**
  String evCancelBody(String title);

  /// No description provided for @evCancelConfirm.
  ///
  /// In de, this message translates to:
  /// **'Absagen'**
  String get evCancelConfirm;

  /// No description provided for @evCancelDone.
  ///
  /// In de, this message translates to:
  /// **'Termin abgesagt.'**
  String get evCancelDone;

  /// No description provided for @evCancelFailed.
  ///
  /// In de, this message translates to:
  /// **'Absage nicht angekommen — kein Relay hat sie angenommen.'**
  String get evCancelFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
