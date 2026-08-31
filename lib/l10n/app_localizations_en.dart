// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Home';

  @override
  String get navWallet => 'Badges';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profile';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionBack => 'Back';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Try again';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Got it';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get trustScore => 'Trust Score';

  @override
  String get reputation => 'Reputation';

  @override
  String get reputationShareQr => 'Share QR';

  @override
  String get community => 'Community';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Home Meetup';

  @override
  String get shoutout => 'Shoutout';

  @override
  String get joinCommunity => 'Join the community';

  @override
  String get identityVerified => 'Verified';

  @override
  String get verifiedByAdmin => 'Verified by admin';

  @override
  String get nostrVerified => 'Nostr verified';

  @override
  String get profileNickname => 'Nickname';

  @override
  String get profileChooseHomeMeetup => 'Choose your home meetup';

  @override
  String get profileYourIdentity => 'Your identity';

  @override
  String get profileNostrKey => 'NOSTR KEY';

  @override
  String get profileKeyActive => 'Key active';

  @override
  String get requiredField => 'Required — please fill in';

  @override
  String get requiredHomeMeetup => 'Required — please choose your home meetup';

  @override
  String fillRequired(String fields) {
    return 'Please fill in: $fields';
  }

  @override
  String get identityGenerateKey => 'Create a new key';

  @override
  String get identityConnectAmber => 'Connect with Amber';

  @override
  String get identityImportNsec => 'Import existing nsec';

  @override
  String get amberConnected =>
      'Connected with Amber! Your nsec stays in Amber.';

  @override
  String get amberNotFound => 'Amber not found';

  @override
  String get amberCancelled => 'Connection cancelled in Amber.';

  @override
  String get walletTitle => 'My badges';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count badges',
      one: '1 badge',
      zero: 'No badges',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
      zero: 'today',
    );
    return 'in $_temp0';
  }

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputation';

  @override
  String get tileReputationShare => 'Share QR';

  @override
  String get tileReputationCheck => 'Check';

  @override
  String get tileCommunity => 'Community';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Events';

  @override
  String get tileEventsCalendar => 'Calendar';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Send';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Listen';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Community';

  @override
  String get tileOrganizer => 'Organizer';

  @override
  String get tileOrganizerPanel => 'Admin panel';

  @override
  String get tileOrganizerNew => 'New via Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'HOME MEETUP';

  @override
  String get homeMeetupChoose => 'Choose your meetup';

  @override
  String get homeMeetupChooseSub => 'Select your regular meetup';

  @override
  String homeMeetupBadges(int count) {
    return '$count badges';
  }

  @override
  String get homeMeetupToday => 'Today!';

  @override
  String get homeMeetupTomorrow => 'Tomorrow';

  @override
  String homeMeetupInDays(int days) {
    return 'in $days days';
  }

  @override
  String get homeMeetupNoDate => 'No date scheduled';

  @override
  String get homeMeetupNextEvent => 'Next meetup';

  @override
  String get homeMeetupNoneSoon => 'No date in sight.\nTime to change that!';

  @override
  String get homeMeetupSelectFirst => 'Choose home meetup\nfirst!';

  @override
  String get btnEvents => 'EVENTS';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusMeetupActive => 'Meetup active';

  @override
  String get loading => 'Loading...';

  @override
  String get organizerPromoted => 'You are now an ORGANIZER!';

  @override
  String get resetTitle => 'Reset app?';

  @override
  String get resetBody => 'All badges and your profile will be deleted.';

  @override
  String get resetCancel => 'Cancel';

  @override
  String get resetConfirm => 'DELETE';

  @override
  String get settingsSectionBackup => 'BACKUP';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsSectionNostr => 'NOSTR NETWORK';

  @override
  String get settingsSectionControl => 'CONTROLS';

  @override
  String get settingsSectionAccount => 'ACCOUNT';

  @override
  String get settingsBackup => 'Create backup';

  @override
  String get settingsBackupSub => 'Secure your account';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageChoose => 'Choose language';

  @override
  String get settingsRelays => 'Nostr relays';

  @override
  String get settingsRelaysSub => 'Configure relays';

  @override
  String get settingsHaptic => 'Haptic feedback';

  @override
  String get settingsHapticOn => 'On';

  @override
  String get settingsHapticOff => 'Off';

  @override
  String get settingsReset => 'Reset app';

  @override
  String get settingsResetSub => 'Deletes profile and badges';

  @override
  String get introTagline => 'YOUR BITCOIN COMMUNITY';

  @override
  String get introJoin => 'JOIN COMMUNITY';

  @override
  String get introLoadBackup => 'LOAD BACKUP';

  @override
  String get introSetIdentity => 'Please set up your identity first.';

  @override
  String get navWalletTab => 'Badges';

  @override
  String get navProfileTab => 'Profile';

  @override
  String get scanBadge => 'Scan badge';

  @override
  String get scanBadgeSub => 'QR code from the meetup';

  @override
  String get scanReputation => 'Check reputation';

  @override
  String get scanReputationSub => 'Verify another person\'s Trust Score';

  @override
  String get calendarTitle => 'MEETUP EVENTS';

  @override
  String get calendarSearch => 'Search (e.g. Munich, Bitcoin...)';

  @override
  String get calendarNoEvents => 'No events found.';

  @override
  String get sectionDescription => 'DESCRIPTION';

  @override
  String get sectionLocation => 'LOCATION';

  @override
  String get sectionDates => 'DATES';

  @override
  String get sectionLinks => 'LINKS';

  @override
  String get meetupRoute => 'Route';

  @override
  String get meetupNoDatesCal => 'No dates in the calendar right now.';

  @override
  String get errorOpenLink => 'Couldn\'t open link';

  @override
  String get walletNoBadges => 'No badges collected yet';

  @override
  String get walletNoBadgesSub =>
      'Visit meetups and scan the QR code to collect badges!';

  @override
  String get walletShareReputation => 'SHARE REPUTATION';

  @override
  String get walletShowQr => 'Show QR code';

  @override
  String get walletShowQrSub => 'For scanning on site';

  @override
  String get walletExportJson => 'Export as JSON';

  @override
  String get walletExportJsonSub => 'Signed export with Schnorr proof';

  @override
  String get walletShareText => 'Share as text';

  @override
  String get walletShareTextSub => 'Readable by anyone (copied on the web)';

  @override
  String get walletShareTitle => 'Share reputation';

  @override
  String get walletJsonCopied => 'JSON data copied to clipboard';

  @override
  String get walletReputationCopied => 'Reputation copied to clipboard';

  @override
  String get cancel => 'Cancel';

  @override
  String get badgeDetailsTitle => 'Badge details';

  @override
  String get badgeShare => 'Share badge';

  @override
  String get badgeShareCaps => 'SHARE BADGE';

  @override
  String get badgeClose => 'CLOSE';

  @override
  String get badgeProofTitle => 'Cryptographic proof';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'This badge cryptographically confirms you were physically present.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Meetup date';

  @override
  String get badgeMeetupId => 'Meetup ID';

  @override
  String get badgeOrganizerNpub => 'Organizer (npub)';

  @override
  String get badgeSignatureType => 'Signature type';

  @override
  String get badgeTransmission => 'Transmission';

  @override
  String get badgeTimestamp => 'Timestamp';

  @override
  String get badgeScanTime => 'Scan time';

  @override
  String get badgeVerificationHash => 'VERIFICATION HASH';

  @override
  String get badgeClaimBinding => 'Claim binding';

  @override
  String get badgeBound => 'Bound ✓';

  @override
  String get badgeNotBound => 'Not bound';

  @override
  String get badgeClaimedLater => 'Claimed later';

  @override
  String get badgeNote => 'Note';

  @override
  String get badgeNoSignature => 'No signature';

  @override
  String get badgeHashCopied => 'Hash copied';

  @override
  String get badgeInfoCopied => 'Badge info copied to clipboard';

  @override
  String get badgeNfcTag => 'NFC tag';

  @override
  String get badgeRollingQr => 'Rolling QR code';

  @override
  String get levelNew => 'NEW';

  @override
  String get levelStarter => 'STARTER';

  @override
  String get levelActive => 'ACTIVE';

  @override
  String get levelEstablished => 'ESTABLISHED';

  @override
  String get levelVeteran => 'VETERAN';

  @override
  String get reputationTitle => 'REPUTATION';

  @override
  String get reputationNoBadges => 'NO BADGES YET';

  @override
  String get reputationNoProofs => 'No cryptographic proofs yet';

  @override
  String get reputationBuildHint1 => 'Visit a meetup and scan a badge to ';

  @override
  String get reputationBuildHint2 => 'build your reputation.';

  @override
  String get reputationScanQr => 'SCAN QR CODE';

  @override
  String get reputationShareImage => 'SHARE QR AS IMAGE';

  @override
  String get reputationUpdateRelays => 'UPDATE ON RELAYS';

  @override
  String get reputationPublishing => 'PUBLISHING...';

  @override
  String get reputationBadges => 'Badges';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Signers';

  @override
  String get reputationBound => 'Bound';

  @override
  String get reputationSchnorrSigned => 'Schnorr-signed';

  @override
  String get reputationSignedNoId => 'Signed (no identity)';

  @override
  String get reputationNoIdentity =>
      'No identity linked. Add Telegram or Nostr in your profile.';

  @override
  String get reputationCheck => 'Check reputation';

  @override
  String get reputationVerified => 'My verified meetup reputation';

  @override
  String get reputationCodeFrom => 'Reputation code from';

  @override
  String get portalDiscover => 'DISCOVER';

  @override
  String get portalQuickAccess => 'QUICK ACCESS';

  @override
  String get portalPodcastMedia => 'PODCAST & MEDIA';

  @override
  String get portalSocialNetworks => 'SOCIAL NETWORKS';

  @override
  String get portalAssociation => 'ASSOCIATION';

  @override
  String get portalProfile => 'Your profile & badges';

  @override
  String get portalMeetupMap => 'Meetup map';

  @override
  String get portalMeetupMapSub => 'Meetups near you';

  @override
  String get portalBeginnerPath => 'The Path (beginners)';

  @override
  String get portalShoutoutSend => 'Send shoutout';

  @override
  String get portalMembership => 'Become a member';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips & sounds';

  @override
  String get portalInterviews => 'Interviews';

  @override
  String get portalMediaArticles => 'Media & articles';

  @override
  String get portalMerch => 'Merch & Bitcoin products';

  @override
  String get portalShop => 'Shop';

  @override
  String get portalDonate => 'Donate';

  @override
  String get portalContact => 'Contact';

  @override
  String get portalPrivacy => 'Privacy';

  @override
  String get portalStatutes => 'Statutes (PDF)';

  @override
  String get portalAboutAssoc => 'About the association';

  @override
  String get portalOpen => 'Open portal';

  @override
  String get portalTagline => 'for bullish Bitcoiners.';

  @override
  String get portalInfotainment => 'Toxic-maximalist infotainment';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';

  @override
  String get profileTitle => 'YOUR PROFILE';

  @override
  String get profileEditTitle => 'EDIT PROFILE';

  @override
  String get profileSave => 'SAVE PROFILE';

  @override
  String get profileIntro => 'Choose a nickname and your home meetup.';

  @override
  String get profileNicknameMin => 'At least 2 characters';

  @override
  String get profileNicknameReq => 'Required field — please fill in';

  @override
  String get profileNicknameAnon =>
      'Please choose your own nickname (not \'Anon\')';

  @override
  String get profileHomeMeetup => 'Home meetup';

  @override
  String get profileHomeMeetupDash => 'Home meetup';

  @override
  String get profileChooseMeetup => 'Choose your home meetup';

  @override
  String get profileMeetupReq => 'Required — please choose your home meetup';

  @override
  String get profileSearchCity => 'Search city...';

  @override
  String get profileIdentity => 'YOUR IDENTITY';

  @override
  String get profileStrengthen => 'STRENGTHEN IDENTITY';

  @override
  String get profileStrengthenDesc =>
      'Link platforms and prove your humanity to raise your Trust Score.';

  @override
  String get profileLinkPlatforms => 'Link platforms';

  @override
  String get profilePlatformsSub => 'Telegram, X, classifieds';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => 'Zapped once? Check now';

  @override
  String get profileLightningActive => 'Lightning proof active';

  @override
  String get profileVerified => 'VERIFIED';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'No Nostr key yet';

  @override
  String get profileKeyActiveCaps => 'KEY ACTIVE';

  @override
  String get profileCreateKey => 'CREATE NOSTR KEY';

  @override
  String get profileCreateNewKey => 'CREATE NEW KEY';

  @override
  String get profileCreating => 'CREATING...';

  @override
  String get profileNoNostrNeeded =>
      'You don\'t need a Nostr account. The app creates a key for you — takes a second.';

  @override
  String get profileKeyDesc =>
      'Your cryptographic key — used to sign badges and verify your reputation.';

  @override
  String get profileConnectAmber => 'CONNECT WITH AMBER';

  @override
  String get profileConnectExtension => 'CONNECT WITH BROWSER EXTENSION';

  @override
  String get profileExtensionConnected =>
      'Extension connected! Your key stays there.';

  @override
  String get profileExtensionAborted => 'Rejected in the extension.';

  @override
  String get profileExtensionNotFound =>
      'No Nostr extension found in this browser.';

  @override
  String get profileAmberDesc =>
      'Amber is a separate signer for Android that keeps your private ';

  @override
  String get profileAmberConnected =>
      'Connected with Amber! Your nsec stays in Amber.';

  @override
  String get profileAmberNotFound => 'Amber not found';

  @override
  String get profileAmberInstall =>
      'Key stored securely. Install Amber (e.g. via F-Droid ';

  @override
  String get profileAmberRetry => 'or the Zapstore) and try again.';

  @override
  String get profileAmberAborted => 'Connection aborted in Amber.';

  @override
  String get profileSwitchSignerHeading => 'Connect a different signer';

  @override
  String get profileDisconnectSigner => 'DISCONNECT SIGNER';

  @override
  String get profileDisconnectTitle => 'Disconnect signer?';

  @override
  String get profileDisconnectBody =>
      'The connection to the signer is released. If a local key exists, the app uses it again — otherwise it cannot sign until you create or import one.\n\nThe authorisation inside the signer stays; you can revoke it there as well.';

  @override
  String get profileDisconnectDone => 'Signer disconnected.';

  @override
  String get profileSignerUnusable =>
      'Signing is currently not possible — reconnect the signer.';

  @override
  String get profileSwitchSignerHint =>
      'Your current key stays stored and in the backup.';

  @override
  String get profileSwitchSignerTitle => 'Switch signer?';

  @override
  String get profileSwitchSignerBody =>
      'The signer brings its own key. If it does NOT hold the same one as before, your identity changes — your badges will still belong to the old key.\n\nYour current key is not deleted: it stays in storage and in the backup, so you can switch back.';

  @override
  String get profileSwitchSignerContinue => 'CONTINUE';

  @override
  String get profileIdentityChanged =>
      'Careful: the signer uses a different identity than before. Your badges belong to the previous key.';

  @override
  String get profileConnectBunker => 'CONNECT REMOTE SIGNER';

  @override
  String get bunkerTitle => 'Connect a remote signer';

  @override
  String get bunkerIntro =>
      'Your key stays inside the signer. The app only requests signatures — on any device.';

  @override
  String get bunkerModeSigner => 'Connect signer app';

  @override
  String get bunkerModeSignerDesc =>
      'The app shows a QR code for you to scan in the signer.';

  @override
  String get bunkerModePaste => 'Paste a bunker:// address';

  @override
  String get bunkerModePasteDesc =>
      'Copy it from nsec.app, Amber or Alby. The most reliable route on iPhone.';

  @override
  String get bunkerPasteLabel => 'bunker:// address';

  @override
  String get bunkerPasteHint => 'bunker://…?relay=wss://…';

  @override
  String get bunkerConnect => 'CONNECT';

  @override
  String get bunkerBack => 'BACK';

  @override
  String get bunkerWaiting => 'Waiting for approval in the signer …';

  @override
  String get bunkerWaitingHint =>
      'This can take up to two minutes. Keep the app open.';

  @override
  String get bunkerScanHint =>
      'Scan it in the signer — or paste the address there.';

  @override
  String get bunkerCopy => 'Copy address';

  @override
  String get bunkerCopied => 'Address copied.';

  @override
  String get bunkerOpenSigner => 'Open signer';

  @override
  String get bunkerNoSignerApp =>
      'No signer app found. Use \"Paste a bunker:// address\" instead.';

  @override
  String get bunkerRecommendAndroid =>
      'Recommended on Android: Amber — signer app with bunker support, on Zapstore and F-Droid. Alternatively a self-hosted bunker (Bunker46, Signet).';

  @override
  String get bunkerRecommendIos =>
      'Recommended on iOS: Clave — wakes itself via push to sign in the background. Alternatively a self-hosted bunker (Bunker46, Signet) or Amber on an Android device.';

  @override
  String get bunkerRecommendWeb =>
      'Suitable counterparts are Amber (Android), Clave (iOS) or a self-hosted bunker such as Bunker46 or Signet.';

  @override
  String get bunkerAuthOpen => 'Open approval in browser';

  @override
  String get bunkerAuthNeeded => 'The signer requires approval in the browser.';

  @override
  String get bunkerAuthAction => 'OPEN';

  @override
  String get bunkerTimeout =>
      'The signer did not respond. Is it open and online?';

  @override
  String get bunkerConnected =>
      'Remote signer connected! Your key stays there.';

  @override
  String get bunkerDisconnected => 'Remote signer disconnected.';

  @override
  String get bunkerCheck => 'CHECK CONNECTION';

  @override
  String get bunkerAlive =>
      'Signer responds — the session is active. Whether the permissions still hold only shows on the next signature.';

  @override
  String get bunkerDead =>
      'Signer does not respond. Is it open and online? Otherwise reconnect.';

  @override
  String get profileImportNsec => 'IMPORT EXISTING NSEC';

  @override
  String get profileImportNsecShort => 'IMPORT NSEC';

  @override
  String get keyExportEncrypted => 'EXPORT ENCRYPTED (ncryptsec)';

  @override
  String get keyExportTitle => 'Export key encrypted';

  @override
  String get keyExportDesc =>
      'Creates an ncryptsec — your key, encrypted with a password. You can safely store it in a password manager and import it into Amber, Clave, nsec.app or your own bunker.';

  @override
  String get keyExportDuration =>
      'The encryption is deliberately slow: about half a second on the device, up to half a minute in the browser.';

  @override
  String get keyExportAction => 'EXPORT';

  @override
  String get keyExportMismatch => 'The passwords do not match.';

  @override
  String get keyExportNoKey => 'No local key present.';

  @override
  String get keyExportReadyTitle => 'Encrypted key';

  @override
  String get keyExportReadyBody =>
      'Without your password this is worthless — and with your password it is your full key. Treat both accordingly.';

  @override
  String get keyExportCopy => 'COPY';

  @override
  String get keyExportCopied => 'Encrypted key copied.';

  @override
  String get keyExportFromVault =>
      'This is your key encrypted with the password you set when you created it — no new password needed.';

  @override
  String get keyExportOtherPassword => 'Create with a different password';

  @override
  String get profileImport => 'IMPORT';

  @override
  String get profileEnterNsec =>
      'Enter your private Nostr key (starts with nsec1...):';

  @override
  String get profileKeyImported => 'Key imported!';

  @override
  String get profileShowNsecQ => 'SHOW NSEC?';

  @override
  String get profileShowNsecWarn =>
      'Your private key will be shown. Make sure nobody is looking at your screen!';

  @override
  String get profileShow => 'SHOW';

  @override
  String get profileCopy => 'COPY';

  @override
  String get profileSecureKey => 'SECURE YOUR KEY!';

  @override
  String get profileSaveKeyDesc =>
      'This is your private key. Store it in a safe place! ';

  @override
  String get profileKeyNotShownAgain => 'This key will NOT be shown again!';

  @override
  String get profileKeySecured => 'I\'VE SECURED IT';

  @override
  String get profileNpubCopied => 'npub copied!';

  @override
  String get profileNsecCopied => 'nsec copied! Save it securely now.';

  @override
  String get profileNsecNeverLeaves => 'Your nsec never leaves your device.';

  @override
  String get profileWhoHasKey => 'Whoever has this key HAS your identity.';

  @override
  String get profileBackupNsec =>
      'Important: back up your nsec! If you lose your device, your key is gone.';

  @override
  String get profileNewKeypairDesc =>
      'A new key pair will be created. Your private key (nsec) is stored securely on your device.\n\n';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileEditLoseStatus => 'EDIT (lose status)';

  @override
  String get profileWarning => 'Warning!';

  @override
  String get profileEditWarnDesc =>
      'If you edit, you lose your \'Verified\' status and must be re-approved.';

  @override
  String get dialogCancel => 'CANCEL';

  @override
  String get dialogCancelMixed => 'Cancel';

  @override
  String get dialogCreate => 'CREATE';

  @override
  String errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Amber error: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Please fill in: $fields';
  }

  @override
  String get backupEncryptTitle => 'Encrypt backup';

  @override
  String get backupDecryptTitle => 'Decrypt backup';

  @override
  String get backupExportDesc =>
      'Set a password to protect your private key (nsec) in the backup.\n\n⚠️ If you forget this password, the backup is IRRECOVERABLY lost!';

  @override
  String get backupImportDesc =>
      'This backup is encrypted. Please enter the password.';

  @override
  String get backupPassword => 'Password';

  @override
  String get backupPasswordConfirm => 'Confirm password';

  @override
  String get backupPasswordEmpty => 'Password cannot be empty';

  @override
  String get backupPasswordMin => 'At least 8 characters';

  @override
  String get backupPasswordMismatch => 'Passwords do not match';

  @override
  String get backupEncryptSave => 'Encrypt & Save';

  @override
  String get backupDecryptLoad => 'Decrypt & Load';

  @override
  String get backupShareTitle => 'Einundzwanzig App Backup (Encrypted)';

  @override
  String get backupShareText =>
      'Your encrypted backup. Keep your password ready to restore it.';

  @override
  String backupError(String msg) {
    return 'Backup error: $msg';
  }

  @override
  String get backupCorrupt => 'Backup file is corrupted (format error).';

  @override
  String get backupWrongPassword => 'Wrong password or file corrupted!';

  @override
  String get backupNotValid => 'File is not a valid backup or wrong format.';

  @override
  String get backupNotEinundzwanzig =>
      'File is not a valid Einundzwanzig backup.';

  @override
  String backupLoaded(Object items) {
    return '✅ Backup loaded! $items restored.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Import failed: $msg';
  }

  @override
  String get qrScanTitle => 'CHECK REPUTATION';

  @override
  String get qrResultTitle => 'RESULT';

  @override
  String get qrScanHint => 'Scan an Einundzwanzig\nreputation QR code';

  @override
  String get qrLoadFromGallery => 'LOAD QR FROM GALLERY';

  @override
  String get qrBack => 'BACK';

  @override
  String get qrNoCodeInImage => 'No QR code found in image';

  @override
  String get qrNotEinundzwanzig =>
      'QR code found, but not Einundzwanzig format';

  @override
  String get qrVerified => 'VERIFIED';

  @override
  String get qrVerifiedV1 => 'VERIFIED (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFIED (v2)';

  @override
  String get qrSigInvalid => 'SIGNATURE INVALID';

  @override
  String get qrFormatUnknown => 'FORMAT UNKNOWN';

  @override
  String get qrReadError => 'READ ERROR';

  @override
  String get qrV2Subtitle => 'Legacy signature valid — no badge proof';

  @override
  String get qrV1Subtitle => 'Older format — no identity binding';

  @override
  String get qrCantRead => 'QR code could not be read.';

  @override
  String qrProcessError(String msg) {
    return 'Processing error: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTITY';

  @override
  String get qrNoIdentity => 'NO IDENTITY';

  @override
  String get qrNoVerifiableIdentity => 'No verifiable identity.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'SOCIAL NETWORK';

  @override
  String get qrSectionPlatforms => 'LINKED PLATFORMS';

  @override
  String get qrSectionMeetups => 'VISITED MEETUPS';

  @override
  String get qrHumanVerified => 'Human verified';

  @override
  String get qrLightningActive => 'Lightning proof active';

  @override
  String get qrNoLightning => 'No Lightning proof found';

  @override
  String get qrNoZap => 'No zap activity';

  @override
  String get qrNip05Invalid => 'NIP-05 invalid';

  @override
  String get qrYouFollow => 'You follow';

  @override
  String get qrFollowsYou => 'Follows you';

  @override
  String get qrMutualFollow => 'Mutual follow';

  @override
  String get qrNoDirectFollow => 'No direct follow';

  @override
  String get qrDirectConnection => 'Direct connection';

  @override
  String get qrBidirectional => 'Direct bidirectional connection';

  @override
  String get qrOneWay => 'One-way connection';

  @override
  String get qrViaContacts => 'Via shared contacts';

  @override
  String get qrStrongOverlap => 'Strong network overlap';

  @override
  String get qrPartiallyConnected => 'Partially connected';

  @override
  String get qrNoOverlap => 'No overlap';

  @override
  String get qrEndorsement => 'Endorsement from known admins';

  @override
  String get qrSigVerified => 'Signature verified';

  @override
  String get qrAnalyzingNetwork => 'Analyzing network...';

  @override
  String get qrCheckingLightning => 'Checking Lightning...';

  @override
  String get qrCheckingNip05 => 'Checking NIP-05...';

  @override
  String get qrStatBadges => 'Badges';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Signers';

  @override
  String get qrStatBound => 'Bound';

  @override
  String get qrStatDays => 'Days';

  @override
  String get qrLabelNickname => 'Nickname';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Other';

  @override
  String get qrLinked => 'Linked';

  @override
  String get qrSigVerifiedShort => 'Signature verified';

  @override
  String get qrLinkedShort => 'Linked';

  @override
  String get nfcDisabled => 'NFC is disabled';

  @override
  String get nfcDisabledHint => 'NFC is disabled. Please turn it on.';

  @override
  String get nfcUnavailable => 'NFC unavailable';

  @override
  String get nfcOpenSettings => 'OPEN SETTINGS';

  @override
  String get nfcEnableHint => 'Please enable NFC in your device settings ';

  @override
  String get nfcSettingsAndroid => 'Android: Settings → Connections → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Settings → NFC';

  @override
  String get verifyScanBadge => 'SCAN BADGE';

  @override
  String get verifyScanNfc => 'SCAN NFC TAG';

  @override
  String get verifyScanQr => 'SCAN QR';

  @override
  String get verifyScanQrCaps => 'SCAN QR CODE';

  @override
  String get verifyReadyToScan => 'Ready to scan';

  @override
  String get verifyWaitingNfc => 'Waiting for NFC tag...';

  @override
  String get verifyCheckingNfc => 'Checking NFC...';

  @override
  String get verifyScanInstruction =>
      'Scan the QR code\nof the meetup organizer.';

  @override
  String get verifyScanQrInstruction =>
      'Scan the QR code\nof the meetup organizer';

  @override
  String get verifyNoNfcDevice => 'This device has no NFC. Use the QR scanner.';

  @override
  String get verifyNoNfcLong => 'This device does not support NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Use the QR code scanner instead ';

  @override
  String get verifyToGetBadge => 'to get your badge.';

  @override
  String get verifyAskScan => 'Please let a participant scan your tag.';

  @override
  String get verifyCantSelfBadge => 'You cannot give yourself a badge.\n';

  @override
  String get verifyBadgeFound => 'BADGE FOUND';

  @override
  String get verifyAlreadyCollected => 'ALREADY COLLECTED';

  @override
  String get verifyAddToWallet => 'ADD TO WALLET';

  @override
  String get verifyVerifiedAdmin => 'Verified admin';

  @override
  String get verifyUnknownMeetup => 'Unknown meetup';

  @override
  String get verifyNoExpiry => 'No expiry';

  @override
  String get writerReadyToWrite => 'Ready to write';

  @override
  String get writerNoNfcDevice =>
      'This device has no NFC. Use rolling QR codes.';

  @override
  String get writerUseRollingQr => 'You can use rolling QR codes instead ';

  @override
  String get writerForYourMeetup => 'for your meetup.';

  @override
  String get writerSelectHomeFirst =>
      'Please select a home meetup in your profile first';

  @override
  String get writerYourHomeMeetup => 'YOUR HOME MEETUP';

  @override
  String get writerCreateTag => 'CREATE TAG';

  @override
  String get writerCreateMeetupTag => 'CREATE MEETUP TAG';

  @override
  String get writerMeetupTag => 'MEETUP TAG';

  @override
  String get writerSuccess => 'SUCCESS!';

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Valid for ${hours}h\n\n';
  }

  @override
  String get writerHoldTag => 'Hold tag to the device...';

  @override
  String get writerHoldTagInstruction =>
      'Hold an NFC tag to the device.\nParticipants scan this tag to collect a badge.';

  @override
  String get writerFormatting => 'Formatting empty tag...';

  @override
  String get writerFormatFailed => 'Formatting failed';

  @override
  String get writerLoadingSession => 'Loading session data...';

  @override
  String get writerJumpToQr => 'Jumping to QR code...';

  @override
  String get writerNoNdef => 'NDEF format not possible';

  @override
  String get writerTagReadOnly => 'Tag is read-only';

  @override
  String get writerCanOverwrite => 'Tag can be overwritten afterwards';

  @override
  String get writerTagLost => 'Tag lost during writing';

  @override
  String get writerTagRemovedEarly =>
      'Tag removed too early — hold it steady for 2–3 seconds';

  @override
  String get writerUseNtag215 => 'Use an NTAG215 (504B) or larger.';

  @override
  String get writerToWriteTag => 'to write the tag.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Location: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Block: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Signed by: $signer';
  }

  @override
  String get verifyMsgProof => 'Proof: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Tag expiry: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Already collected\n\nYou already have a badge today from:\n$name';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Error: $msg';
  }

  @override
  String writerTagTooSmall(Object data, Object max) {
    return 'Tag too small! Data: ${data}B, tag: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ MEETUP TAG written!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (compact)\n';
  }

  @override
  String get verifyErrNoNdef => '✗ No NDEF tag';

  @override
  String get verifyErrTagEmpty => '✗ Tag is empty';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload empty';

  @override
  String get verifyErrInvalidFormat => '✗ Invalid format';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Invalid tag: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Read error: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ NFC error: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ QR code expired!\n$msg\n\nPlease scan directly on the organizer\'s screen.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Start error: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — fits on NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ No home meetup set';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Home meetup not found';

  @override
  String get writerNoActiveSession =>
      '❌ No active meetup session found. Please restart the meetup.';

  @override
  String get apMeetupSession => 'MEETUP SESSION';

  @override
  String get apSessionRunning => 'SESSION RUNNING';

  @override
  String get apOpenActiveMeetup => 'OPEN ACTIVE MEETUP';

  @override
  String get apStartMeetup => 'START MEETUP';

  @override
  String get apEndMeetupEarly => 'End meetup early';

  @override
  String get apOrganizer => 'ORGANIZER';

  @override
  String get apHowItWorks => 'HOW IT WORKS';

  @override
  String get apNewMeetupQ => 'Start new meetup?';

  @override
  String get apSessionEndQ => 'End session?';

  @override
  String get apCancel => 'Cancel';

  @override
  String get apStart => 'Start';

  @override
  String get apEnd => 'End';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Via Trust Score';

  @override
  String get apNewMeetupBody =>
      'This creates a unique signature (block time) for the next 4 hours. Creating new sessions is locked during this period.';

  @override
  String get apSessionEndBody =>
      'This locks the current block time. You can start a new session afterwards.';

  @override
  String get apGeneratesProof =>
      'Generates a new cryptographic proof for the next 4 hours.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'HUMAN VERIFIED';

  @override
  String get humNotVerified => 'NOT VERIFIED';

  @override
  String get humVerifiedSub => 'You are verified as human';

  @override
  String get humLightningActive => 'Lightning proof active';

  @override
  String get humCheckNow => 'CHECK NOW';

  @override
  String get humCheckAgain => 'CHECK AGAIN';

  @override
  String get humCheckAgainShort => 'Check again';

  @override
  String get humSearchingRelays => 'SEARCHING RELAYS...';

  @override
  String get humHowTitle => 'HOW DOES IT WORK?';

  @override
  String get humIntro1 => 'Prove you are human — by demonstrating ';

  @override
  String get humIntro2 => 'that you own a real Lightning wallet and ';

  @override
  String get humIntro3 => 'have zapped someone on Nostr before.';

  @override
  String get humExplain1 =>
      'Bots don\'t have Lightning wallets. A single real ';

  @override
  String get humExplain2 => 'payment proves you are a human with a real ';

  @override
  String get humExplain3 => 'wallet — without revealing personal data.';

  @override
  String get humStep1 => 'You zap anyone on Nostr';

  @override
  String get humStep2 => 'The zap creates a receipt on relays';

  @override
  String get humStep3 => 'The app finds your receipt';

  @override
  String get humStepInstruction =>
      'Anyone, any amount of sats. Use a Nostr client like Damus, Amethyst or Primal.';

  @override
  String get humCheckInstruction =>
      'Press the check button and the app searches Nostr relays for your zap.';

  @override
  String get humZapReturn => 'Zap anyone and come back';

  @override
  String get humCryptoProof =>
      'This is a cryptographic proof that you made a real Lightning payment.';

  @override
  String get humProofInEvent1 => 'on the Nostr network. This proof is in your ';

  @override
  String get humProofPrivacy =>
      'The proof is included in your reputation event. No amount or recipient is stored.';

  @override
  String get humReputationSaved => 'Reputation event saved.';

  @override
  String humPaidOn(String date) {
    return 'You made a Lightning payment on $date ';
  }

  @override
  String humLastCheck(String time) {
    return 'Last check: $time';
  }

  @override
  String get ppTitle => 'PLATFORM LINK';

  @override
  String get ppPlatform => 'PLATFORM';

  @override
  String get ppUsername => 'USERNAME';

  @override
  String get ppActiveLinks => 'ACTIVE LINKS';

  @override
  String get ppLinkPlatform => 'LINK PLATFORM';

  @override
  String get ppCreateLink => 'CREATE LINK';

  @override
  String get ppAnotherPlatform => 'ANOTHER PLATFORM';

  @override
  String get ppShareOnPlatform => 'SHARE ON PLATFORM';

  @override
  String get ppUnlinkQ => 'UNLINK?';

  @override
  String get ppRevoke => 'REVOKE';

  @override
  String get ppCancel => 'CANCEL';

  @override
  String get ppYourUsername => 'Your username';

  @override
  String get ppPlatformName => 'Platform name';

  @override
  String get ppIntro =>
      'Link your account with a platform. The proof is automatically embedded in your reputation QR.';

  @override
  String get ppLinkSaved =>
      'Link saved! Automatically embedded in your reputation QR.';

  @override
  String get ppMustUpdate =>
      'You must update your reputation event afterwards.';

  @override
  String get ppUnlinkBody1 => 'The platform link for \"';

  @override
  String get ppUnlinkBody2 => 'will be deleted.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'The platform link for \"$username\" on $platform will be deleted.\n\nYou must update your reputation event afterwards.';
  }

  @override
  String ppCreated(String date) {
    return 'Created: $date';
  }

  @override
  String get ppRevokeTooltip => 'Revoke';

  @override
  String get rqTitle => 'MEETUP QR CODE';

  @override
  String get rqActive => 'ACTIVE';

  @override
  String get rqCodeRenewing => 'Code is renewing...';

  @override
  String get rqNextCodeIn => 'Next code in';

  @override
  String get rqEndSession => 'End session';

  @override
  String get rqEndSessionQ => 'End session?';

  @override
  String get rqEnd => 'END';

  @override
  String get rqEndSessionBody =>
      'An ended session locks this block time. You can start a new session afterwards.';

  @override
  String get rqNoActiveSession => 'NO ACTIVE SESSION';

  @override
  String get rqNoSessionBody =>
      'There is currently no active meetup session.\nPlease restart the meetup in the Admin Panel.';

  @override
  String get rqBackToAdmin => 'BACK TO ADMIN PANEL';

  @override
  String get rsTitle => 'NOSTR RELAYS';

  @override
  String get rsDefaultRelays => 'DEFAULT RELAYS';

  @override
  String get rsCustomRelays => 'CUSTOM RELAYS';

  @override
  String get rsAddRelay => 'ADD RELAY';

  @override
  String get rsAdd => 'ADD';

  @override
  String get rsNoRelaysActive => 'No relays active!';

  @override
  String get rsNoCustomRelays => 'No custom relays configured.';

  @override
  String get rsAllRelaysInfo =>
      'The app uses all active relays simultaneously for maximum reach.';

  @override
  String get rsRelaysIntro =>
      'Relays distribute your reputation across the Nostr network. ';

  @override
  String get rsRelayPlaceholder => 'wss://my-relay.com';

  @override
  String get rdScanAdminTag => 'SCAN ADMIN TAG';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'COLLECT BADGE';

  @override
  String get rdYourReputation => 'YOUR REPUTATION';

  @override
  String get rdEditIdentity => 'Edit identity';

  @override
  String get rdLinkingIdentity => 'Linking identity...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'No badges collected yet.\nGo to a meetup!';

  @override
  String get rdSelfSovereign =>
      'Self-sovereign: This app runs without a server. Your badges belong only to you and are stored on this device.';

  @override
  String get rdVerifiedByAdmin => 'VERIFIED BY ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Remaining time: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Session: $time';
  }

  @override
  String get rvTitle => 'CHECK REPUTATION';

  @override
  String get rvChecking => 'CHECKING...';

  @override
  String get rvFullyVerified => 'FULLY VERIFIED';

  @override
  String get rvPartiallyVerified => 'PARTIALLY VERIFIED';

  @override
  String get rvSignatureOnly => 'SIGNATURE ONLY CHECKED';

  @override
  String get rvInvalid => 'INVALID';

  @override
  String get rvConfirmedInEvent => 'Confirmed in event';

  @override
  String get rvPlatformProof => 'Platform proof';

  @override
  String get rvIntro1 => 'Paste a person\'s verify string or npub ';

  @override
  String get rvIntro2 => 'to check their reputation across all proof layers.';

  @override
  String get rvCheckingSignature => 'Checking signature...';

  @override
  String get rvCheckingNostr => 'Analyzing Nostr network...';

  @override
  String get rvCheckingLightning => 'Checking Lightning activity...';

  @override
  String get rvCheckingNip05 => 'Checking NIP-05...';

  @override
  String get msSelectMeetup => 'SELECT MEETUP';

  @override
  String get msSearchMeetup => 'Search meetup...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Retry';

  @override
  String get mlLoadError => 'Error loading';

  @override
  String get mlNoMeetupsFound => 'No meetups found.';

  @override
  String mlNoMeetupFor(String query) {
    return 'No meetup for \"$query\"';
  }

  @override
  String get cmRequestSent => 'REQUEST SENT 🚀';

  @override
  String get cmDateTime => 'DATE & TIME';

  @override
  String get cmFoundBase => 'FOUND A BASE.';

  @override
  String get cmLocation => 'LOCATION';

  @override
  String get cmCityName => 'CITY NAME';

  @override
  String get cmTelegramGroup => 'TELEGRAM GROUP (OPTIONAL)';

  @override
  String get cmNewMeetup => 'NEW MEETUP';

  @override
  String get cmDateExample => 'e.g. May 21, 7:00 PM';

  @override
  String get cmCityExample => 'e.g. Frankfurt';

  @override
  String get cmLocationExample => 'e.g. Room 77';

  @override
  String get evUpcomingEvents => 'UPCOMING EVENTS';

  @override
  String get evDatesEvents => 'DATES & EVENTS';

  @override
  String get evNoMeetupsFound => 'No meetups found';

  @override
  String get evSearchCityCountry => 'Search city or country...';

  @override
  String get evIntro =>
      'Most Einundzwanzig meetups take place regularly. Tap a meetup for more info and dates.';

  @override
  String get rvLabelPlatform => 'Platform';

  @override
  String get rvLabelUsername => 'Username';

  @override
  String get countryDE => 'Germany';

  @override
  String get countryAT => 'Austria';

  @override
  String get countryCH => 'Switzerland';

  @override
  String get countryES => 'Spain';

  @override
  String get countryNL => 'Netherlands';

  @override
  String get countryIT => 'Italy';

  @override
  String get countryFR => 'France';

  @override
  String get siTitle => 'YOUR TRUST SCORE';

  @override
  String get siIntro =>
      'Measures your trustworthiness. Based on cryptographic proofs — nobody can forge it.';

  @override
  String get siIdentityLayer => 'IDENTITY LAYER';

  @override
  String siLinksActive(Object count) {
    return '$count links active';
  }

  @override
  String get siHumanitySub => 'Lightning zap verification';

  @override
  String get siNip05Sub => 'Nostr identity (name@domain)';

  @override
  String get siPlatformActive => 'Platform active';

  @override
  String get siPlatforms => 'Platforms';

  @override
  String get siNoneLinked => 'None linked yet';

  @override
  String get siTrustLevel => 'TRUST LEVEL';

  @override
  String get siLvlNew => 'Starting level. Visit meetups to collect badges.';

  @override
  String get siLvlStarter => 'Your first badges show community participation.';

  @override
  String get siLvlActive =>
      'Regularly active. Different meetups and organizers strengthen your profile.';

  @override
  String get siLvlEstablished =>
      'Trusted member. Well-connected and long-standing.';

  @override
  String get siLvlVeteran => 'Highest level. Reputation proven over months.';

  @override
  String get siCalculation => 'CALCULATION';

  @override
  String get siFacBadges => 'Meetup badges';

  @override
  String get siFacBadgesDesc =>
      'Base value per badge. Well-attended meetups worth more.';

  @override
  String get siFacDiversity => 'Diversity';

  @override
  String get siFacDiversityDesc => 'Different cities/organizers = more points.';

  @override
  String get siFacSigners => 'Signers';

  @override
  String get siFacSignersDesc => 'Independent organizers = higher trust.';

  @override
  String get siFacMaturity => 'Maturity';

  @override
  String get siFacMaturityDesc => 'Account age + regularity = bonus.';

  @override
  String get siFacFrequency => 'Frequency Cap';

  @override
  String get siFacFrequencyDesc => 'Max. 2 badges/week. Anti-farming.';

  @override
  String get siBecomeOrganizer => 'BECOME AN ORGANIZER';

  @override
  String get siBecomeOrgDesc =>
      'Automatic promotion once you have enough Trust Score. Then create your own QR codes.';

  @override
  String siProgressLabel(Object name) {
    return 'PROGRESS ($name)';
  }

  @override
  String get siAlreadyOrganizer => 'You are already an organizer!';

  @override
  String get siIncreaseScore => 'INCREASE SCORE';

  @override
  String get siTip1 => 'Visit different meetups regularly';

  @override
  String get siTip2 => 'Collect badges at meetups in other cities';

  @override
  String get siTip3 => 'Badges from different organizers';

  @override
  String get siTip4 => 'Verify identity with a Lightning zap';

  @override
  String get siTip5 => 'Set up NIP-05';

  @override
  String get siTip6 => 'Link platforms';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get badgeUnknown => 'unknown';

  @override
  String get badgeBlockAtScan => '₿ Block height at scan';

  @override
  String get mwStartMeetup => 'START MEETUP';

  @override
  String get mwStep1Nfc => 'STEP 1: NFC TAG';

  @override
  String get mwNfcIntro1 =>
      'Do you want to place physical NFC tags (NTAG215) for this meetup? ';

  @override
  String get mwNfcIntro2 =>
      'The cryptographic proof (block time & signature) is fixed onto them.';

  @override
  String get mwWriteNfcTag => 'WRITE NFC TAG';

  @override
  String get mwSkipQrOnly => 'SKIP — USE QR ONLY';

  @override
  String repAllBound(Object total) {
    return 'All $total badges bound and verified';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound of $total badges identity-bound';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified cryptographically verified)';
  }

  @override
  String repAllVerified(Object total) {
    return 'All $total badges cryptographically verified (not yet bound)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified of $total badges with Schnorr proof';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count platform links active';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'Could not open $url';
  }

  @override
  String get apHowStep3 => '3. Each scan = one badge for the participant\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city set as home meetup';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Known organizer: $name';
  }

  @override
  String get mvUnknownSigner =>
      'No entry found\nThis key is listed neither in the organiser registry nor among this meetup\'s leaders. The badge itself is valid — the signature checks out and is bound to this badge.';

  @override
  String get mvAdminCheckFailed =>
      '! Cannot verify — the organiser registry was unreachable. The badge itself is valid; the signature checks out.';

  @override
  String get mvLegacyBadge => '! Legacy badge (v1) — signer not verifiable';

  @override
  String get mvBadgeBound => '🔗 Badge bound';

  @override
  String get nwSelectHomeMeetup =>
      '❌ Please select a home meetup in your profile first!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count different recipients';
  }

  @override
  String get apHowStep1 => '1. Start a new meetup (session).\n';

  @override
  String get apHowStep2 => '2. Then show the QR code.\n';

  @override
  String get apHowStep4 =>
      '4. Badges build reputation → more reputation = new organizers';

  @override
  String get ppHowStep1 => '1. Choose a platform and enter your username\n';

  @override
  String get ppHowStep2 => '2. The app creates a cryptographic proof\n';

  @override
  String get ppHowStep3 =>
      '3. The proof is automatically embedded in your reputation QR\n';

  @override
  String get ppHowStep4 => '4. Others scan your QR and see the verified link';

  @override
  String homeImageLoadError(Object msg) {
    return 'Image could not be loaded: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count sent';
  }

  @override
  String repShareError(Object msg) {
    return 'Error sharing: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ No home meetup set';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup not found';

  @override
  String get rlWhatMeans => 'What does this mean?';

  @override
  String get rlWhyImportant => 'Why this matters';

  @override
  String get rlWeakLabel => 'Weak profile';

  @override
  String get rlWeakExpl =>
      'Only one proof layer active. This user has few verifiable connections. For larger transactions: caution.';

  @override
  String get rlWeakAdvice =>
      'Ask for more proofs (Lightning, NIP-05) or meet the person in person first.';

  @override
  String get rlLimitedLabel => 'Limited';

  @override
  String get rlLimitedExpl =>
      'There are meetup badges, but no other independent proofs. The user might be real — but confirmation from other layers is missing.';

  @override
  String get rlLimitedAdvice =>
      'OK for tiny amounts. For larger amounts: wait until more layers are active.';

  @override
  String get rlBuildingLabel => 'Building';

  @override
  String get rlBuildingExpl =>
      'Two proof layers active. The user is building reputation but doesn\'t yet have full breadth.';

  @override
  String get rlBuildingAdvice => 'Suitable for moderate transactions.';

  @override
  String get rlConnectedLabel => 'Well connected';

  @override
  String get rlConnectedExpl =>
      'Multiple independent proofs: meetups, Lightning activity and social connections. Hard to fake.';

  @override
  String get rlConnectedAdvice => 'Trustworthy for most transactions.';

  @override
  String get rlSolidLabel => 'Solid';

  @override
  String get rlSolidExpl =>
      'Broad base of proofs. Manipulation would be laborious and expensive.';

  @override
  String get rlSolidAdvice => 'Trustworthy for most purposes.';

  @override
  String get rlDefaultExpl => 'Some proofs present, but room for more.';

  @override
  String get rlDefaultAdvice => 'Use your own judgment.';

  @override
  String get rlMeetupProofs => 'Meetup proofs';

  @override
  String get rlMeetupGood =>
      'Attended different meetups with different organizers. This requires physical presence in multiple places.';

  @override
  String get rlMeetupMoreDiverse => 'More diversity would be more convincing.';

  @override
  String get rlMeetupNone =>
      'No meetup badges present. This user hasn\'t attended an Einundzwanzig meetup yet — or has only recently started using the app.';

  @override
  String get rlAllBound => 'All cryptographically bound';

  @override
  String get rlGoodSpread => 'Good regional spread';

  @override
  String get rlLowSpread => 'Low spread';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Has meetup badges, but only from $count organizer(s). More diversity would be more convincing.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count badges';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound of $total bound';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count different meetups';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count organizers';
  }

  @override
  String get rlConfirmedByDiff => 'Confirmed by different people';

  @override
  String get rlOneOrgOnly =>
      'Only one organizer — little independent confirmation';

  @override
  String rlMemberSince(Object since) {
    return 'Member since $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count days';
  }

  @override
  String get rlLightningProof => 'Lightning proof';

  @override
  String get rlLnBoth =>
      'Has made and received real Lightning payments. Bots don\'t have Lightning wallets — a strong authenticity signal.';

  @override
  String get rlLnPaid =>
      'Has paid via Lightning at least once. Basic proof that a real wallet exists.';

  @override
  String get rlLnActiveOnly =>
      'Lightning activity present, but Proof of Humanity not yet active.';

  @override
  String get rlLnNone =>
      'No Lightning activity. This doesn\'t mean the user is fake — maybe they don\'t use Lightning via Nostr. But an important anti-bot signal is missing.';

  @override
  String get rlHumanVerified => 'Human verified';

  @override
  String get rlRealLnPayment => 'Real Lightning payment proven';

  @override
  String rlZapsSent(Object count) {
    return '$count zaps sent';
  }

  @override
  String rlToRecipients(Object count) {
    return 'To $count different recipients';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count zaps received';
  }

  @override
  String rlFromSenders(Object count) {
    return 'From $count different senders';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count months active';
  }

  @override
  String get rlSocialTitle => 'Social network';

  @override
  String get rlSocMutualMany =>
      'You know each other on Nostr and share many contacts. Strong connection.';

  @override
  String get rlSocMutual => 'Mutual follow — you know each other on Nostr.';

  @override
  String get rlSocCommon =>
      'Many shared contacts — you move in the same network.';

  @override
  String get rlSocOneSided =>
      'One-sided connection. You know each other vaguely.';

  @override
  String get rlSocOrgFollow =>
      'Known Einundzwanzig organizers follow this user. That\'s a positive signal.';

  @override
  String get rlSocDefault =>
      'There are connections in the Nostr network to this user.';

  @override
  String get rlSocNone =>
      'No connection found in the Nostr network. This could mean: you\'ve never met on Nostr, or the user is very new. Normal for strangers — a warning sign for supposedly familiar faces.';

  @override
  String get rlMutualFollow => 'Mutual follow';

  @override
  String get rlYouFollow => 'You follow';

  @override
  String get rlFollowsYou => 'Follows you';

  @override
  String get rlNoFollow => 'No follow';

  @override
  String get rlKnowOnNostr => 'You know each other on Nostr';

  @override
  String get rlNoDirectConn => 'No direct connection';

  @override
  String rlCommonContacts(Object count) {
    return '$count shared contacts';
  }

  @override
  String get rlSameNetwork => 'Same network';

  @override
  String get rlSomeOverlap => 'Some overlap';

  @override
  String get rlSeparateNetworks => 'Separate networks';

  @override
  String rlOrgsFollow(Object count) {
    return '$count organizers follow';
  }

  @override
  String get rlEndorsement => 'Endorsement from known admins';

  @override
  String get rlIdentityTitle => 'Identity proof';

  @override
  String get rlIdNip05Plat =>
      'Has a NIP-05 address and linked platforms. This ties the Nostr identity to a domain — harder to fake than an anonymous account.';

  @override
  String get rlIdNip05Only =>
      'Has a NIP-05 address. This ties the Nostr identity to a domain — harder to fake than an anonymous account.';

  @override
  String get rlIdPlatOnly =>
      'Linked platform accounts. More platforms = more effort for forgers.';

  @override
  String get rlIdNone =>
      'No internet identification. Completely anonymous. That\'s fine for privacy, but gives fewer trust indicators.';

  @override
  String get rlLinked => 'Linked';

  @override
  String get rlNoIdentification => 'No identification';

  @override
  String get rlAnonymous => 'Anonymous';

  @override
  String get rlActive => '✓ active';

  @override
  String get rlActiveShort => '✓ active';

  @override
  String get rlMissingShort => '— missing';

  @override
  String qrReceivedCount(Object count) {
    return '$count received';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count different senders';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 proofs';
  }

  @override
  String get navNearby => 'Nearby';

  @override
  String get nbTitle => 'MEETUPS NEARBY';

  @override
  String get nbRequestingLocation => 'Getting location...';

  @override
  String get nbLoading => 'Loading meetups...';

  @override
  String get nbLocationDenied => 'Location access denied';

  @override
  String get nbLocationDeniedSub =>
      'Without location we show all meetups sorted by date. Enable location in settings to see distances.';

  @override
  String get nbServiceDisabled => 'Location services are disabled';

  @override
  String get nbRetryLocation => 'Try location again';

  @override
  String get nbContinueWithout => 'Continue without location';

  @override
  String get nbNoMeetups => 'No meetups for this period';

  @override
  String get nbNoMeetupsSub => 'Try a different filter or date.';

  @override
  String get nbFilterToday => 'Today';

  @override
  String get nbFilterWeek => 'This week';

  @override
  String get nbFilterUpcoming => 'All upcoming';

  @override
  String get nbFilterAll => 'All';

  @override
  String get nbPickDate => 'Pick date';

  @override
  String nbKmAway(Object km) {
    return '$km km away';
  }

  @override
  String get nbNoDate => 'No date announced';

  @override
  String nbListHeader(Object count) {
    return '$count meetups';
  }

  @override
  String get nbOpenInMaps => 'Open in maps';

  @override
  String get nbYourLocation => 'Your location';

  @override
  String get nbToday => 'Today';

  @override
  String get nbTomorrow => 'Tomorrow';

  @override
  String get nbResetDate => 'Reset filter';

  @override
  String get nbModeHere => 'Here & now';

  @override
  String get nbModePlanned => 'Planned';

  @override
  String get nbRadius => 'Radius';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Search place (e.g. Hamburg)';

  @override
  String get nbSearchingPlace => 'Searching places...';

  @override
  String get nbNoPlaceFound => 'No place found';

  @override
  String get nbCenterHere => 'My location';

  @override
  String get nbChangePlace => 'Change place';

  @override
  String get nbDateAny => 'Anytime';

  @override
  String get nbDateSingle => 'Date';

  @override
  String get nbDateRange => 'Range';

  @override
  String get nbPickDay => 'Pick day';

  @override
  String get nbPickRange => 'Pick range';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count meetups in range';
  }

  @override
  String get nbNoneInRadius => 'No meetups in range';

  @override
  String get nbNoneInRadiusSub => 'Increase the radius or change place/date.';

  @override
  String get nbApplySearch => 'Search';

  @override
  String nbMoreDates(Object count) {
    return '+$count more dates';
  }

  @override
  String get nbDirections => 'Directions';

  @override
  String get nbDetails => 'Details';

  @override
  String get settingsSectionProfile => 'Profile';

  @override
  String get settingsProfile => 'Edit profile';

  @override
  String get settingsProfileSub => 'Name, Nostr key & home meetup';

  @override
  String get apCreateEvent => 'Create event';

  @override
  String get apCreateEventSub => 'Add in the portal';

  @override
  String get apCreateEventTitle => 'Create event in portal';

  @override
  String get apCreateEventBody =>
      'Meetup events are managed centrally in the Einundzwanzig portal. The app will now open the portal in your browser — log in there with your Nostr key and add the event. It then appears here in the calendar automatically.';

  @override
  String get apOpenPortal => 'Open portal';

  @override
  String get apNoHomeMeetupSet =>
      'Select your home meetup in your profile first, then you can create events for it.';

  @override
  String get apPortalHint =>
      'Why not directly in the app? The portal is the central source for all events and requires your login. Direct creation from the app is planned once the portal supports it.';

  @override
  String get rcTitle => 'Reputation Profile';

  @override
  String get rcShareImage => 'Share as image';

  @override
  String get rcSaving => 'Creating image...';

  @override
  String rcShareError(Object error) {
    return 'Sharing failed: $error';
  }

  @override
  String get rcShareText => 'My Einundzwanzig Trust Score & Reputation';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Level';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Cities';

  @override
  String get rcLabelSigners => 'Signers';

  @override
  String get rcLabelAge => 'Days active';

  @override
  String get rcMember => 'Einundzwanzig member';

  @override
  String get rcNoData => 'No reputation yet. Collect badges at meetups!';

  @override
  String get caOptInTitle => 'Contribute to trust network?';

  @override
  String get caOptInBody =>
      'You can confirm your attendance at this meetup in the public trust network. Others will then see that your npub was at this meetup — and how you\'re connected through shared meetups.\n\nThis is optional. You get your badge regardless.';

  @override
  String get caOptInPrivacy =>
      'Public & permanent on Nostr relays. Reveals a movement and contact pattern. Consider carefully.';

  @override
  String get caOptInYes => 'Yes, contribute';

  @override
  String get caOptInNo => 'No, stay private';

  @override
  String get caPublished => 'Attendance confirmed in network';

  @override
  String get cnTitle => 'Network analysis';

  @override
  String get cnSubtitle =>
      'How is this person connected through shared meetups?';

  @override
  String get cnEnterNpub => 'Enter person\'s npub';

  @override
  String get cnScan => 'Scan';

  @override
  String get cnAnalyze => 'Analyze';

  @override
  String get cnLoading => 'Loading network...';

  @override
  String get cnSharedMeetups => 'Shared meetups';

  @override
  String get cnMutualContacts => 'Mutual contacts';

  @override
  String get cnReach => 'Person\'s reach';

  @override
  String get cnTotalMeetups => 'Meetups attended';

  @override
  String get cnTotalContacts => 'People met';

  @override
  String get cnNoConnection => 'No connection found';

  @override
  String get cnNoConnectionSub =>
      'You haven\'t been to shared meetups and have no mutual contacts — or this person doesn\'t participate in the network.';

  @override
  String get cnDirectMet => 'You\'ve met directly!';

  @override
  String get cnYou => 'You';

  @override
  String get cnTarget => 'This person';

  @override
  String cnViaShared(Object count) {
    return 'via $count shared meetups';
  }

  @override
  String get cnTrustHint =>
      'More shared meetups and contacts mean stronger organic trust.';

  @override
  String get cnInvalidNpub => 'Invalid npub';

  @override
  String get cnPrivacyNote => 'Only shows people who opted into the network.';

  @override
  String get tileTrustNetwork => 'Trust network';

  @override
  String get tileTrustNetworkSub => 'Check connections';

  @override
  String get tnHubTitle => 'Trust network';

  @override
  String get tnHubIntro =>
      'Check how trustworthy a person is in the Einundzwanzig network — through vouches and shared meetups.';

  @override
  String get tnHubNetTitle => 'Network analysis';

  @override
  String get tnHubNetSub => 'A person\'s shared meetups & contacts';

  @override
  String get orgBadgeCreated => 'Organizer attendance recorded';

  @override
  String get orgBadgeLabel => 'Organizer';

  @override
  String get orgBadgeSub => 'You hosted this meetup';

  @override
  String get mnTitle => 'My network';

  @override
  String get mnIntro =>
      'Your trust network from real meetup encounters — and who\'s connected to you beyond that.';

  @override
  String get mnLoading => 'Building network...';

  @override
  String get mnEmpty => 'No connections yet';

  @override
  String get mnEmptySub =>
      'Attend meetups and collect badges (with network participation) to build your trust network.';

  @override
  String get mnDegree1 => 'Met directly';

  @override
  String get mnDegree1Sub => 'People you met live at meetups';

  @override
  String get mnDegree2 => 'Connected via contacts';

  @override
  String get mnDegree2Sub => 'People your contacts met at meetups';

  @override
  String get mnDegree3 => 'Extended network';

  @override
  String get mnDegree3Sub => 'One more level out in the network';

  @override
  String mnSharedMeetups(Object count) {
    return '$count shared meetups';
  }

  @override
  String get mnOneSharedMeetup => '1 shared meetup';

  @override
  String mnViaContacts(Object count) {
    return 'via $count contacts';
  }

  @override
  String get mnViaOneContact => 'via 1 contact';

  @override
  String get mnReachLabel => 'Reach';

  @override
  String get mnDirectLabel => 'Direct';

  @override
  String get mnIndirectLabel => 'Indirect';

  @override
  String get mnTrustHint =>
      'Indirect contacts through real encounters gradually increase your trust — even without having met the person yourself.';

  @override
  String get mnPrivacyNote =>
      'Only shows people who participate in the network (opt-in at badge scan).';

  @override
  String get mnCheckPerson => 'Check specific person';

  @override
  String get settingsHeaderTitle => 'Settings';

  @override
  String get settingsHeaderSub => 'Manage app & account';

  @override
  String get settingsSecAccount => 'ACCOUNT';

  @override
  String get settingsSecData => 'DATA & SECURITY';

  @override
  String get settingsSecNetwork => 'NETWORK';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'DANGER ZONE';

  @override
  String get vpTitle => 'Verify person';

  @override
  String get vpIntro =>
      'Check via real meetup encounters whether and how this person is connected to you.';

  @override
  String get vpEnterNpub => 'Enter npub or scan reputation QR';

  @override
  String get vpScanQr => 'Scan QR';

  @override
  String get vpCheck => 'Verify';

  @override
  String get vpChecking => 'Checking connection...';

  @override
  String get vpDirectTitle => 'Met directly!';

  @override
  String vpDirectSub(Object count) {
    return 'You\'ve been to $count meetups together.';
  }

  @override
  String get vpDirectSubOne => 'You\'ve been to a meetup together.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Connected through $count hops';
  }

  @override
  String get vpIndirectSub =>
      'This person is connected to you through real meetup encounters.';

  @override
  String get vpNoneTitle => 'No connection found';

  @override
  String get vpNoneSub =>
      'There\'s currently no known meetup connection to you.';

  @override
  String get vpNotInNetwork => 'This person isn\'t in the network (yet).';

  @override
  String get vpPathTitle => 'Connection path';

  @override
  String get vpYou => 'You';

  @override
  String get vpTarget => 'This person';

  @override
  String get vpMetAt => 'shared meetup';

  @override
  String get vpInvalidNpub => 'Invalid npub';

  @override
  String get vpTrustNote =>
      'The closer the connection (lower degree), the stronger the trust via physical presence.';

  @override
  String get vpSelfTitle => 'That\'s you';

  @override
  String get gpsRequired => 'Location required';

  @override
  String get gpsRequiredOrg =>
      'Creating a meetup requires your location. It defines the meetup\'s place.';

  @override
  String get gpsRequiredScan =>
      'Collecting this badge requires your location — as proof you\'re on site.';

  @override
  String get gpsDenied =>
      'Location access denied. Please allow it in settings.';

  @override
  String get gpsDisabled =>
      'Location services are disabled. Please enable them.';

  @override
  String get gpsError =>
      'No GPS signal. Indoors this often takes longer – step near a window or outside and try again.';

  @override
  String get gpsRetry => 'Try again';

  @override
  String get gpsPickMeetup => 'Which meetup?';

  @override
  String get gpsPickMeetupSub =>
      'Several meetups are near you. Please pick the right one.';

  @override
  String gpsDistanceKm(Object km) {
    return '$km km away';
  }

  @override
  String get gpsNoMeetupNearby => 'No known meetup found nearby.';

  @override
  String get gpsTooFar => 'Too far away';

  @override
  String gpsTooFarSub(Object km, Object max) {
    return 'You\'re $km km from the meetup location. Badges can only be collected on site (max $max km).';
  }

  @override
  String get mapTitle => 'My badge world map';

  @override
  String get mapButton => 'View on map';

  @override
  String get mapStatMeetups => 'Meetups';

  @override
  String get mapStatCities => 'Cities';

  @override
  String get mapStatCountries => 'Countries';

  @override
  String mapShareText(Object count) {
    return 'Here\'s where I\'ve been! 🌍 $count meetups on my Einundzwanzig badge world map.';
  }

  @override
  String get mapShareButton => 'Share as image';

  @override
  String get mapEmpty => 'No badges with location yet';

  @override
  String get mapEmptySub =>
      'Collect badges at meetups — they\'ll appear here on your world map.';

  @override
  String get gpsNoMeetupTitle => 'No meetup nearby';

  @override
  String get gpsNoMeetupBody =>
      'No known meetup is registered within 10 km. You can still start a session — give your meetup a title. Your current location is automatically set as the venue on the map.';

  @override
  String get gpsMeetupNameLabel => 'Meetup title';

  @override
  String get gpsMeetupNameHint => 'e.g. Bitcoin meetup';

  @override
  String get gpsStartAnyway => 'Start session';

  @override
  String get gpsNameRequired => 'Please enter a name.';

  @override
  String get mnNodeDetailTitle => 'Connection';

  @override
  String get mnDegreeDirect => 'Directly connected';

  @override
  String get mnDegreeSecond => '2nd degree';

  @override
  String get mnDegreeThird => '3rd degree';

  @override
  String get mnSharedMeetupsList => 'Shared meetups';

  @override
  String get mnViaBridges => 'Connected via';

  @override
  String get mnNoSharedDetail => 'No direct shared meetups';

  @override
  String get mnOpenInNostr => 'Open in Nostr';

  @override
  String get mnTapHint => 'Tap a node for details';

  @override
  String get mnLegendDirect => 'Direct (1st)';

  @override
  String get mnLegendSecond => '2nd';

  @override
  String get mnLegendThird => '3rd';

  @override
  String get resetBackupTitle => 'Back up data?';

  @override
  String get resetBackupBody =>
      'Resetting permanently deletes ALL data — your badges, your key and your profile. Without a backup, badges CANNOT be restored (not even via Nostr). Create a backup first?';

  @override
  String get resetBackupCreate => 'Create backup';

  @override
  String get resetBackupSkip => 'Reset without backup';

  @override
  String get resetBackupDone => 'Backup created. Reset now?';

  @override
  String get resetNowConfirm => 'Reset now';

  @override
  String get verifyBadgeSaved => 'Badge saved ✓';

  @override
  String get tileConverter => 'Converter';

  @override
  String get tileConverterSub => 'Rate & sats';

  @override
  String get convTitle => 'Converter';

  @override
  String get convYouPay => 'Amount';

  @override
  String convRateInfo(Object price, Object cur) {
    return '1 BTC = $price $cur';
  }

  @override
  String convUpdated(Object time) {
    return 'Updated: $time';
  }

  @override
  String get convRefresh => 'Refresh rate';

  @override
  String get convOffline => 'Could not load rate. Are you online?';

  @override
  String get convLoading => 'Loading rate …';

  @override
  String get convSwap => 'Swap';

  @override
  String get convSelectCurrency => 'Select currency';

  @override
  String get convUnitSats => 'Satoshi';

  @override
  String get convUnitBtc => 'Bitcoin';

  @override
  String get convSource => 'Rate from mempool.space';

  @override
  String get tileNews => 'News';

  @override
  String get tileNewsSub => 'Read Einundzwanzig articles';

  @override
  String get newsTitle => 'News';

  @override
  String get newsEmpty => 'No articles found.';

  @override
  String get newsLoading => 'Loading articles …';

  @override
  String get newsRefresh => 'Refresh';

  @override
  String get newsSource => 'Articles via Nostr (NIP-23)';

  @override
  String get newsOpenWebsite => 'Open on the website';

  @override
  String get keyEduTitle => 'Your key to Nostr';

  @override
  String get keyEduWhatNostrH => 'What is Nostr?';

  @override
  String get keyEduWhatNostrB =>
      'Nostr is an open, decentralized network – similar to the internet itself, but for social identity. Nobody owns it. There is no company, no account and no password in the classic sense. Instead of signing up with a provider, you own a cryptographic key that identifies you everywhere in the network.';

  @override
  String get keyEduPairH => 'Your key pair';

  @override
  String get keyEduPairB =>
      'You are about to receive two matching keys. They work like a mailbox: the public key is the address you can give to anyone – the private key is the only key that opens the mailbox.';

  @override
  String get keyEduNpubH => 'npub – your public key';

  @override
  String get keyEduNpubB =>
      'The npub (starts with “npub1…”) is your public identity. You may share it freely – it\'s how others find you, see your posts and follow you. It\'s like your username, except it truly belongs to you and nobody can take it away.';

  @override
  String get webKeyWarnH => 'Less protected in the browser';

  @override
  String get webKeyWarnB =>
      'The iPhone and Android app stores your key in the device\'s secure storage. A browser cannot do that — there it is easier to read out.';

  @override
  String get webKeyWarnAdvice =>
      'In the browser, prefer a separate test identity. Do not enter the key your real Nostr identity depends on.';

  @override
  String get keyEduNsecH => 'nsec – your private key';

  @override
  String get keyEduNsecB =>
      'The nsec (starts with “nsec1…”) is your secret. Whoever holds it IS you – they can post in your name, take over your identity and abuse your reputation. NEVER share it, never type it anywhere you\'re unsure about, and never store a photo of it in a cloud. There is no “forgot password”: if the nsec is lost, the identity is gone forever.';

  @override
  String get keyEduIdentityH => 'One identity, many uses';

  @override
  String get keyEduIdentityB =>
      'This key pair is not just for this app. It is your identity across the entire Nostr network: you can use the same identity in many other Nostr apps – for social networks, blogs, chats, Lightning payments and more. In this app it is additionally tied to your reputation, your meetup badges and your web of trust. That\'s why protecting it matters: lose the key and you lose not just a login, but everything you\'ve built.';

  @override
  String get keyEduProtectH => 'How to protect your key';

  @override
  String get keyEduProtect1 =>
      'Back up the nsec right away (e.g. in a password manager).';

  @override
  String get keyEduProtect2 => 'Share only the npub – never the nsec.';

  @override
  String get keyEduProtect3 =>
      'Create an encrypted backup (possible in this app).';

  @override
  String get keyEduProtect4 =>
      'For more security: use a signer app like Amber.';

  @override
  String get keyEduUnderstood => 'Got it, create key';

  @override
  String get keyEduCancel => 'Cancel';

  @override
  String get keyEduIntro =>
      'Before you start: you\'re about to receive your own key pair. Take a moment – it\'s worth understanding what you\'re getting.';

  @override
  String get tilePortal => 'My meetups';

  @override
  String get tilePortalSub => 'Manage events on the portal';

  @override
  String get portalTitle => 'My meetups';

  @override
  String get portalNotConnected => 'Connect to the portal';

  @override
  String get portalConnectInfo =>
      'Sign in to the Einundzwanzig portal with your Nostr key to manage your meetup events right from the app.';

  @override
  String get portalConnect => 'Sign in';

  @override
  String get portalConnecting => 'Signing in …';

  @override
  String get portalLogout => 'Sign out';

  @override
  String get portalLoginFailed => 'Sign-in failed';

  @override
  String get portalLoadingMeetups => 'Loading your meetups …';

  @override
  String get portalNoMeetups =>
      'You don\'t manage any meetups on the portal yet.';

  @override
  String get portalLeader => 'Leader';

  @override
  String get portalNewEvent => 'Create event';

  @override
  String get portalEventTitle => 'New event';

  @override
  String get portalFieldStart => 'Date & time';

  @override
  String get portalPickDate => 'Pick date';

  @override
  String get portalPickTime => 'Pick time';

  @override
  String get portalFieldLocation => 'Location';

  @override
  String get portalFieldLocationHint => 'e.g. Bitcoin meetup café (optional)';

  @override
  String get portalFieldDescription => 'Description';

  @override
  String get portalFieldDescriptionHint => 'What\'s it about? (optional)';

  @override
  String get portalFieldLink => 'Link';

  @override
  String get portalFieldLinkHint => 'https://… (optional)';

  @override
  String get portalSave => 'Save event';

  @override
  String get portalSaving => 'Saving …';

  @override
  String get portalCreatedOk => 'Event created ✓';

  @override
  String get portalNeedStart => 'Please pick date & time.';

  @override
  String get portalSource => 'Connected to portal.einundzwanzig.space';

  @override
  String get evCalendarButton => 'Event calendar';

  @override
  String get evCalendarButtonSub => 'All events at a glance';

  @override
  String get calTitle => 'Event calendar';

  @override
  String get calViewMonth => 'Month';

  @override
  String get calViewYear => 'Year';

  @override
  String get calViewList => 'List';

  @override
  String get calToday => 'Today';

  @override
  String get calNoEvents => 'No events on this day.';

  @override
  String get calNoEventsRange => 'No events in this period.';

  @override
  String get calLoading => 'Loading events …';

  @override
  String get calAddEvent => 'Add event';

  @override
  String get calAllDay => 'All day';

  @override
  String get calSource => 'Events via Nostr (NIP-52)';

  @override
  String get calNewEventTitle => 'Add event';

  @override
  String get calFieldTitle => 'Title';

  @override
  String get calFieldTitleHint => 'e.g. BTC Prague, Zitadelle …';

  @override
  String get calFieldLocation => 'Location';

  @override
  String get calFieldLocationHint => 'e.g. Prague, Czechia';

  @override
  String get calFieldDescription => 'Description';

  @override
  String get calFieldDescriptionHint => 'What\'s it about? (optional)';

  @override
  String get calFieldAllDay => 'All-day event';

  @override
  String get calFieldStart => 'Start';

  @override
  String get calFieldEnd => 'End (optional)';

  @override
  String get calPickDateTime => 'Pick date & time';

  @override
  String get calPickDate => 'Pick date';

  @override
  String get calClearEnd => 'Remove end';

  @override
  String get calPublish => 'Publish to Nostr';

  @override
  String get calPublishing => 'Publishing …';

  @override
  String get calPublishFail => 'Publishing failed. Online & signed in?';

  @override
  String get calNeedTitle => 'Please enter a title.';

  @override
  String get calNeedStart => 'Please pick a start.';

  @override
  String get calPublishInfo =>
      'This event is published publicly on Nostr – everyone with this app sees it in their calendar.';

  @override
  String get calMonth1 => 'January';

  @override
  String get calMonth2 => 'February';

  @override
  String get calMonth3 => 'March';

  @override
  String get calMonth4 => 'April';

  @override
  String get calMonth5 => 'May';

  @override
  String get calMonth6 => 'June';

  @override
  String get calMonth7 => 'July';

  @override
  String get calMonth8 => 'August';

  @override
  String get calMonth9 => 'September';

  @override
  String get calMonth10 => 'October';

  @override
  String get calMonth11 => 'November';

  @override
  String get calMonth12 => 'December';

  @override
  String get calWd0 => 'Mon';

  @override
  String get calWd1 => 'Tue';

  @override
  String get calWd2 => 'Wed';

  @override
  String get calWd3 => 'Thu';

  @override
  String get calWd4 => 'Fri';

  @override
  String get calWd5 => 'Sat';

  @override
  String get calWd6 => 'Sun';

  @override
  String get calTypeMeetup => 'Meetup';

  @override
  String get calTypeEvent => 'Event';

  @override
  String get calLegendMeetup => 'Meetups';

  @override
  String get calLegendEvent => 'Events';

  @override
  String get portalManageEvents => 'Manage events';

  @override
  String get portalExistingEvents => 'Existing events';

  @override
  String get portalLoadingEvents => 'Loading events …';

  @override
  String get portalNoEvents => 'No events for this meetup yet.';

  @override
  String get portalEditEvent => 'Edit event';

  @override
  String get portalUpdatedOk => 'Event updated ✓';

  @override
  String get portalUpdate => 'Save changes';

  @override
  String get portalTapToEdit => 'Tap to edit';

  @override
  String get hubTitle => 'Events';

  @override
  String get hubMeetups => 'Meetups';

  @override
  String get hubMeetupsSub => 'Search & discover meetups';

  @override
  String get hubCalendar => 'Event calendar';

  @override
  String get hubCalendarSub => 'All events at a glance, color-coded';

  @override
  String get hubExternal => 'External events';

  @override
  String get hubExternalSub => 'Community conferences & events';

  @override
  String get extTitle => 'External events';

  @override
  String get extIntro =>
      'Community-submitted events (not meetups) – e.g. conferences like BTC Prague or Zitadelle.';

  @override
  String get extLoading => 'Loading external events …';

  @override
  String get extNone => 'No external events yet.';

  @override
  String get extAdd => 'Add event';

  @override
  String get calFilterAll => 'All';

  @override
  String get calFilterMeetups => 'Meetups';

  @override
  String get calFilterExternal => 'External';

  @override
  String get calFilterLocation => 'Search place/country …';

  @override
  String get calFilterActive => 'Filter active';

  @override
  String get calFilterClear => 'Clear filter';

  @override
  String get calFilterNoMatch => 'No events for this filter.';

  @override
  String get calWorldwide => 'Worldwide';

  @override
  String get calCommunityOnly => 'Community only';

  @override
  String get calWorldwideHint =>
      'Worldwide shows all Nostr events – including external ones.';

  @override
  String get chTitle => 'Community';

  @override
  String get chPortal => 'Portal';

  @override
  String get chPortalSub => 'Meetups · Events · Courses · Map';

  @override
  String get chNews => 'News';

  @override
  String get chNewsSub => 'Read articles';

  @override
  String get chNostr => 'Nostr';

  @override
  String get chNostrSub => 'Community feed';

  @override
  String get chShoutout => 'Shoutout';

  @override
  String get chShoutoutSub => 'Send';

  @override
  String get chPodcast => 'Podcast';

  @override
  String get chPodcastSub => 'Listen';

  @override
  String get paTitle => 'Portal';

  @override
  String get paMeetups => 'Meetups';

  @override
  String get paMeetupsSub => 'Browse all meetups';

  @override
  String get paEvents => 'Events & RSVP';

  @override
  String get paEventsSub => 'View events and RSVP';

  @override
  String get paCourses => 'Courses & lecturers';

  @override
  String get paCoursesSub => 'The Einundzwanzig education program';

  @override
  String get paMap => 'Map';

  @override
  String get paMapSub => 'Meetups nearby';

  @override
  String get paMine => 'My meetups';

  @override
  String get paMineSub => 'Manage events (organizer)';

  @override
  String get paWeb => 'Portal website';

  @override
  String get paWebSub => 'Open portal.einundzwanzig.space';

  @override
  String get rsvpLoading => 'Loading events …';

  @override
  String get rsvpNone => 'No upcoming events found.';

  @override
  String get rsvpGoing => 'RSVP';

  @override
  String get rsvpYouGo => 'You\'re going ✓';

  @override
  String get rsvpCount => 'going';

  @override
  String get rsvpNeedLogin =>
      'Please sign in to the portal first (My meetups).';

  @override
  String rsvpFailed(String msg) {
    return 'Response not saved: $msg';
  }

  @override
  String get crsLoading => 'Loading courses …';

  @override
  String get crsNone => 'No courses found.';

  @override
  String get crsCourses => 'Courses';

  @override
  String get crsLecturers => 'Lecturers';

  @override
  String get rsvpCancel => 'Cancel RSVP';

  @override
  String get crsAbout => 'About the course';

  @override
  String get crsUpcoming => 'Upcoming dates';

  @override
  String get crsLecturer => 'Lecturer';

  @override
  String get lecAbout => 'About the lecturer';

  @override
  String get lecLinks => 'Links';

  @override
  String get crsOpenPortal => 'Open in portal';

  @override
  String get rsvpImComing => 'I\'m coming';

  @override
  String get rsvpMaybe => 'Maybe';

  @override
  String get evOpenLink => 'Open link';

  @override
  String get evShare => 'Share';

  @override
  String get evToCalendar => 'Add to calendar';

  @override
  String get portalConnected => 'Portal connected';

  @override
  String get portalLoginPrompt => 'Connecting you to the portal to RSVP.';

  @override
  String get portalTileSub => 'For RSVPs & your meetups';

  @override
  String get ldTitle => 'Organizers';

  @override
  String get ldManage => 'Manage organizers';

  @override
  String get ldManageSub => 'Add trusted co-leaders';

  @override
  String get ldPickMeetup => 'Choose meetup';

  @override
  String get ldCreator => 'Creator';

  @override
  String get ldAdd => 'Add organizer';

  @override
  String get ldAddHint => 'npub of the new organizer';

  @override
  String get ldAddDo => 'Add';

  @override
  String get ldRemove => 'Remove';

  @override
  String get ldRemoveConfirm => 'Remove this organizer?';

  @override
  String get ldAdded => 'Organizer added';

  @override
  String get ldRemoved => 'Organizer removed';

  @override
  String get ldFailed => 'Action failed';

  @override
  String get ldEmpty => 'No other organizers yet.';

  @override
  String get ldLoading => 'Loading organizers …';

  @override
  String get ldNpubInvalid => 'Please enter a valid npub.';

  @override
  String get ldAddButton => 'Add admin';

  @override
  String get calLegendCourse => 'Courses';

  @override
  String get calFilterCourses => 'Courses';

  @override
  String get refreshRunning => 'Refreshing data …';

  @override
  String get refreshDone => 'Everything up to date';

  @override
  String get v4vSectionTitle => 'Support';

  @override
  String get v4vSectionSubtitle =>
      'Value for Value – support the project with sats';

  @override
  String get v4vTitle => 'Value for Value';

  @override
  String get v4vHeadline => 'Value for Value';

  @override
  String get v4vExplain1 =>
      'This app is handcrafted for the community – no ads, no tracking, no subscription. Following the \"Value for Value\" principle, you give back what the app is worth to you.';

  @override
  String get v4vExplain2 =>
      'Your sats go directly into developing the project further. Every amount helps – thank you!';

  @override
  String get v4vAmountLabel => 'Amount';

  @override
  String get v4vDonateButton => 'Donate with Lightning';

  @override
  String get v4vRecipient => 'Recipient';

  @override
  String get v4vErrInvalidAmount => 'Please enter a valid amount.';

  @override
  String get v4vErrBelowMin => 'Amount is too low for this address.';

  @override
  String get v4vErrAboveMax => 'Amount is too high for this address.';

  @override
  String get v4vErrUnreachable => 'Connection failed. Please try again later.';

  @override
  String get v4vErrGeneric => 'Could not create the invoice.';

  @override
  String get v4vNoWalletTitle => 'No Lightning wallet found';

  @override
  String get v4vNoWalletBody =>
      'No app was found to pay. You can copy the invoice and paste it into your wallet.';

  @override
  String get v4vCopyInvoice => 'Copy invoice';

  @override
  String get v4vCopied => 'Invoice copied';

  @override
  String get convPremiumTitle => 'Premium / Discount';

  @override
  String get convPremiumHint =>
      'For trades: percentage premium (+) or discount (−) on the rate.';

  @override
  String get convPremiumResult => 'With premium/discount';

  @override
  String get convPremiumBase => 'Base rate';

  @override
  String get convPremiumSats => 'Result in sats';

  @override
  String get portalTokenMismatch =>
      'Your portal login belongs to a different Nostr key and has been disconnected. Please reconnect the portal — with the key you are a leader with.';

  @override
  String get settingsLogTitle => 'Diagnostic log';

  @override
  String get settingsLogSub => 'Events for troubleshooting';

  @override
  String get rsvpNoNames =>
      'The portal does not provide a name list for this event.';

  @override
  String get rsvpAnon => 'Anonymous';

  @override
  String get settingsMempool => 'Mempool server';

  @override
  String get settingsMempoolSub => 'Source of the Bitcoin data';

  @override
  String get mempoolTitle => 'Mempool server';

  @override
  String get mempoolIntro =>
      'This is where the app fetches block height, fees, price and Lightning data. The default is mempool.space. If you browse via Tor, choose the onion address — mempool.space often rejects requests from Tor exit nodes.';

  @override
  String get mempoolClearnetTitle => 'Default (clearnet)';

  @override
  String get mempoolTorTitle => 'Tor / onion';

  @override
  String get mempoolTorSub => 'Official .onion of mempool.space';

  @override
  String get mempoolTorHint =>
      'Only works while Orbot is running in VPN mode and includes this app. Without Orbot an .onion address cannot be reached. Tor is slower — the data takes a little longer.';

  @override
  String get mempoolCustomTitle => 'Your own instance';

  @override
  String get mempoolCustomSub => 'Your own node (Umbrel, Start9, RaspiBlitz …)';

  @override
  String get mempoolSave => 'Save';

  @override
  String get mempoolSaved => 'Saved';

  @override
  String get mempoolInvalidUrl => 'That does not look like a valid address.';

  @override
  String get mempoolTest => 'Test connection';

  @override
  String get mempoolTesting => 'Testing …';

  @override
  String get mempoolTestOk => 'Connection works';

  @override
  String get mempoolTestFail => 'No connection';

  @override
  String get mempoolTestBlocked =>
      'The server is rejecting the request. On Tor: choose the onion address.';

  @override
  String get mempoolTestOnionFail =>
      'Onion not reachable. Is Orbot running in VPN mode with this app included?';

  @override
  String get mempoolActive => 'Active source';

  @override
  String get dashSource => 'Data';

  @override
  String get dashPartial => 'Only partially loaded';

  @override
  String get dashOfflineTitle => 'No connection';

  @override
  String get dashOfflineBody =>
      'No data could be loaded. Check your internet connection — or pick a different data source.';

  @override
  String get dashBlockedTitle => 'Server is rejecting requests';

  @override
  String get dashBlockedBody =>
      'mempool.space is blocking this IP address. This typically happens over Tor, because many users share one exit node. Fix: use the onion address or your own instance.';

  @override
  String get dashChangeServer => 'Change data source';

  @override
  String get chDuellSub => 'Quiz duels for sats — play against the community';

  @override
  String get sdMyTurn => 'Your move!';

  @override
  String get sdWaiting => 'Waiting for opponent';

  @override
  String get sdLobby => 'open games in the lobby';

  @override
  String get sdShortTurn => 'your turn';

  @override
  String get sdShortLobby => 'in the lobby';

  @override
  String get sdShortWait => 'awaiting opponent';

  @override
  String get chPlebrapSub => 'Bitcoin rap — plebs together strong';

  @override
  String get prV4V => 'Sats to the artists';

  @override
  String get prPickSong => 'Pick a song';

  @override
  String get prLoadError => 'Could not load the song';

  @override
  String get msFavoritesHint => 'Pick your meetups — you can choose several.';

  @override
  String get msSaveNone => 'Save without favorite';

  @override
  String msSaveFavorites(int count) {
    return 'Save $count favorites';
  }

  @override
  String calFavAdded(String city) {
    return '$city added to favorites ★';
  }

  @override
  String calFavRemoved(String city) {
    return '$city removed from favorites';
  }

  @override
  String get verifyBadgeDuplicate => 'This badge is already in your wallet.';

  @override
  String get gpsOpenLocationSettings => 'Open location settings';

  @override
  String get gpsOpenAppSettings => 'Open app settings';

  @override
  String get walletSearchHint => 'Search meetup…';

  @override
  String get walletGroupMeetup => 'By meetup';

  @override
  String get walletGroupYear => 'By year';

  @override
  String get walletNoResults => 'No badges found.';

  @override
  String get walletCleanupTitle => 'Clean up duplicates';

  @override
  String get walletCleanupConfirm => 'Remove';

  @override
  String get walletCleanupNone => 'No duplicates found.';

  @override
  String get walletCleanupHint =>
      'The original badge for each meetup is kept. Attendance proofs already published to the network stay unchanged.';

  @override
  String walletCleanupBody(int count) {
    return 'Found $count duplicate badge(s):';
  }

  @override
  String walletCleanupDone(int count) {
    return 'Removed $count duplicates.';
  }

  @override
  String get orgGpsSoftTitle => 'Continue without location?';

  @override
  String get orgGpsSoftBody =>
      'You can still create the meetup and enter the name yourself. Without a location, attendees cannot be confirmed by radius — their badges will count as unverified presence.';

  @override
  String get orgGpsSoftContinue => 'Without location';

  @override
  String get badgeUnverified => 'Presence unverified';

  @override
  String get badgeUnverifiedInfo =>
      'No location was available when collecting. The badge is valid, but its presence proof is not additionally confirmed.';

  @override
  String get verifyClose => 'CLOSE';

  @override
  String get verifyOpenWallet => 'OPEN WALLET';

  @override
  String get writerValidity => 'Valid for 4 hours';

  @override
  String get apPickPortalTitle => 'Select meetup';

  @override
  String get apPickPortalHint =>
      'Pick the meetup you are currently at. Its stored location serves as a reference for attendees — a wrong pick distorts their confirmation.';

  @override
  String get apEnterManually => 'Enter name manually';

  @override
  String get apCustomNeedsGpsTitle => 'Location required';

  @override
  String get apCustomNeedsGpsBody =>
      'A meetup with a custom name can only be created if your location is available — it is the only reference point for verifying attendance.\n\nThree options: step outside and try again, pick a meetup from the portal instead, or let someone else present with working location create the badge.';

  @override
  String get apNoRefTitle => 'No reference point';

  @override
  String get apNoRefContinue => 'Create anyway';

  @override
  String apNoRefBody(String city) {
    return 'No location is stored for „$city“ in the portal, and your own location is unavailable. Attendance therefore cannot be confirmed — the badges will count less.\n\nBetter: enable location, or let someone else present create the badge.';
  }

  @override
  String get apConfirmPickTitle => 'Are you here?';

  @override
  String get apConfirmPickBody =>
      'This name is permanently stored in every attendee\'s badge and cannot be changed later. If the location does not match the people present, they will see „too far away“ and receive no badge.';

  @override
  String get apConfirmPickYes => 'Yes, I am here';

  @override
  String get badgeOrganizerTitle => 'ORGANIZER RECORD';

  @override
  String get badgeOrganizerDesc =>
      'You created this meetup yourself. The badge records that, but it is unsigned and does not count towards reputation — nobody can confirm themselves. You get a counting badge when another organizer on site starts their own session and you scan their code.';

  @override
  String get walletOrganizerSection => 'Created by you';

  @override
  String reputationOrganizerNote(int count) {
    return '$count meetup(s) organized by you — not counted in the score, since nobody can confirm themselves.';
  }

  @override
  String get apCrossConfirmTitle => 'Another organizer present?';

  @override
  String get apCrossConfirmBody =>
      'You don\'t get a counting badge for your own meetup — nobody can confirm themselves. If you both start a session and scan each other, you both get a real record of the evening.';

  @override
  String get tileEventsToday => 'today in the event calendar';

  @override
  String tileNewsUnread(int count) {
    return '$count new since your visit';
  }

  @override
  String get tilesAvailable => 'Available';

  @override
  String get tilesEditHint =>
      'Drag onto another tile to move · Pin to attach or detach';

  @override
  String get tilesEditDone => 'Done';

  @override
  String tileReputationBadges(int count) {
    return '$count counted badges';
  }

  @override
  String get tileActListen => 'To listen';

  @override
  String get tileActConvert => 'Convert';

  @override
  String get tileActExchange => 'Exchange';

  @override
  String get tileActSend => 'Send';

  @override
  String get tileActExplore => 'Explore';

  @override
  String get tileActLookup => 'Look up';

  @override
  String get tileActNetwork => 'Network';

  @override
  String get tileActEncounters => 'Encounters';

  @override
  String get tileActManage => 'Manage';

  @override
  String get emptyFindMeetup => 'Find a meetup';

  @override
  String get reputationScoreLabel => 'Trust score';

  @override
  String get reputationUnsigned => 'Unsigned';

  @override
  String get portalConnectForOrganizer =>
      'Not connected to the portal — your organizer status cannot be detected.';

  @override
  String get npubCopied => 'npub copied';

  @override
  String get idSetupTitle => 'Identity';

  @override
  String get idSetupSubtitle => 'How do you want to start?';

  @override
  String get idSetupNewCard => 'New here';

  @override
  String get idSetupNewCardSub => 'Create an identity in the app';

  @override
  String get idSetupExistingCard => 'Already on Nostr';

  @override
  String get idSetupExistingCardSub => 'Connect an existing identity';

  @override
  String get idSetupResumeCard => 'Already on this device';

  @override
  String get idSetupResumeCardSub => 'Keep using the existing identity';

  @override
  String get idSetupResumeTitle => 'Continue';

  @override
  String get idSetupResumeContinue => 'Continue';

  @override
  String get idSetupResumeHasKey =>
      'Your key is still on this device. You will continue with it — nothing new is created.';

  @override
  String get idSetupResumePasskey => 'Unlock with passkey';

  @override
  String get idSetupResumePasskeyHint =>
      'Your key is stored encrypted on this device. Unlock it with your passkey.';

  @override
  String get idSetupResumePassword => 'Use password instead';

  @override
  String get idSetupResumePasswordHint =>
      'Your key is stored encrypted on this device. Enter the password you created it with.';

  @override
  String get idSetupResumeNeedPassword => 'Please enter the password.';

  @override
  String get idSetupResumeWrongPassword =>
      'That password does not match this key.';

  @override
  String get idSetupNewTitle => 'Create new';

  @override
  String get idSetupNewHint =>
      'Name and password are enough. Your key stays on this device.';

  @override
  String get idSetupNameLabel => 'Name';

  @override
  String get idSetupNameRequired => 'Please choose a name.';

  @override
  String get idSetupPasswordLabel => 'Password for your key';

  @override
  String get idSetupPasswordConfirmLabel => 'Confirm password';

  @override
  String get idSetupPasswordShort => 'Password must be at least 8 characters.';

  @override
  String get idSetupPasswordWarn =>
      'This password encrypts your key — it is the only thing that can open your backup. There is no reset: without the password the backup is worthless.';

  @override
  String get idSetupCreate => 'Get started';

  @override
  String get idSetupPasskeyTitle => 'Passkey';

  @override
  String get idSetupPasskeyBody =>
      'Optional: also protect with a passkey (Face ID / fingerprint).';

  @override
  String get idSetupPasskeyAction => 'Secure with passkey';

  @override
  String get idSetupPasskeyLater => 'Later';

  @override
  String get idSetupPasskeyUnavailable =>
      'Passkeys are not available on this device. You can continue with your password.';

  @override
  String get idSetupExistingTitle => 'Connect';

  @override
  String get idSetupPrimaryNip07 => 'Browser extension';

  @override
  String get idSetupPrimaryNip07Sub => 'Confirm in the extension';

  @override
  String get idSetupPrimaryAmber => 'Amber';

  @override
  String get idSetupPrimaryAmberSub => 'Confirm in Amber';

  @override
  String get idSetupPrimaryBunker => 'Connect signer';

  @override
  String get idSetupPrimaryBunkerSub => 'Bunker / Clave / Amber';

  @override
  String get idSetupOtherWay => 'Another way';

  @override
  String get idSetupImportHint => 'Paste an nsec or encrypted key (ncryptsec).';

  @override
  String get idSetupImportLabel => 'Key';

  @override
  String get idSetupImportPasswordLabel => 'Password (ncryptsec only)';

  @override
  String get idSetupImportAction => 'Import';

  @override
  String get idSetupImportEmpty => 'Please paste a key.';

  @override
  String get idSetupImportNeedPassword => 'ncryptsec needs the password.';

  @override
  String get idSetupNameTitle => 'Choose a name';

  @override
  String get idSetupNameOnlyHint => 'Which name should others see?';

  @override
  String get idSetupContinue => 'Continue';

  @override
  String get idSetupConnectFailed => 'Connection failed.';

  @override
  String get idSetupBackupTitle => 'Back up your key?';

  @override
  String get idSetupBackupBody =>
      'Copy the encrypted key into your password manager. Without the password it is useless.';

  @override
  String get idSetupBackupCopy => 'Copy';

  @override
  String get idSetupBackupLater => 'Later';

  @override
  String get idSetupMeetupTitle => 'Your meetup';

  @override
  String get idSetupMeetupHint =>
      'Which meetup is yours? You can add more later.';

  @override
  String get idSetupMeetupPick => 'Choose meetup';

  @override
  String get idSetupMeetupContinue => 'Continue';

  @override
  String get idSetupMeetupLater => 'Later';

  @override
  String get idSetupMeetupLoading => 'Loading meetups…';

  @override
  String get idSetupMeetupLoadError =>
      'Could not load meetups. You can set this later in your profile.';

  @override
  String get rsInvalidUrl =>
      'Invalid address. Expected wss://host.tld with no path.';

  @override
  String get rsRelayUnreachable =>
      'Relay unreachable. Check the address or your internet connection.';

  @override
  String get rsRelayAlreadyAdded => 'This relay is already on the list.';

  @override
  String get rsTesting => 'Testing connection …';

  @override
  String get rsRelayAdded => 'Relay added and reachable.';

  @override
  String get rsEnabledHint =>
      'Enabled — this does not mean the relay is reachable right now.';

  @override
  String get newsWriteArticle => 'Write an article';

  @override
  String get newsLike => 'Like';

  @override
  String get newsShare => 'Share';

  @override
  String get newsLikeFailed =>
      'Reaction could not be sent. No relay accepted it.';

  @override
  String get newsZap => 'Zap';

  @override
  String get newsZapTitle => 'Send sats to the author';

  @override
  String get newsZapBody =>
      'Pick an amount. The invoice is then handed to your lightning wallet.';

  @override
  String get newsZapNoAddress =>
      'The author has no lightning address in their profile.';

  @override
  String get newsZapUnsupportedAddress =>
      'The author\'s lightning address is not supported (only addresses like name@domain).';

  @override
  String get newsZapAmountRange =>
      'That amount is outside the range the author accepts.';

  @override
  String get newsZapFailed => 'Zap failed. Details are in the diagnostics log.';

  @override
  String get newsZapNoWallet => 'No lightning wallet found';

  @override
  String get newsZapCopyInvoice => 'Copy invoice';

  @override
  String get evBadgeCreate => 'Create event badge';

  @override
  String get evBadgeCreateSub => 'Attendees can collect a badge on site.';

  @override
  String get evBadgeNotAllowed =>
      'Only meetup organisers and leaders can hand out badges. You can still create the event.';

  @override
  String get evBadgeChecking => 'Checking permission …';

  @override
  String get evBadgeImage => 'Badge image';

  @override
  String get evBadgeImageHint => 'https://…/image.png';

  @override
  String get evBadgeLocation => 'Event location';

  @override
  String get evBadgeLocationHint => 'Use current location';

  @override
  String get evBadgeLocationInfo =>
      'Badges can only be issued near these coordinates and only on the day of the event.';

  @override
  String get evBadgeNoLocation =>
      'Location unavailable. Check the location service and permission.';

  @override
  String get evBadgeIssuers => 'Who may issue badges?';

  @override
  String get evBadgeIssuerHint => 'Paste npub1…';

  @override
  String get evBadgeIssuerInfo =>
      'You are always allowed. Add helpers who should hand out badges on site — they need no organiser role of their own.';

  @override
  String get evBadgeIssuerInvalid =>
      'That is not a valid npub. Expected npub1… or a 64-character hex key.';

  @override
  String get evBadgeIssuerDuplicate => 'That key is already on the list.';

  @override
  String get evBadgeImageInfo =>
      'Pick an image from your gallery — it gets uploaded so everyone can see it. A ready-made URL works too.';

  @override
  String get evBadgeUploading => 'Uploading image …';

  @override
  String evBadgeUploadFailed(String msg) {
    return 'Upload failed: $msg';
  }

  @override
  String get evBadgeLocationPick => 'Pick on the map';

  @override
  String get locPickTitle => 'Event location';

  @override
  String get locPickHint => 'Tap the map to set the venue.';

  @override
  String get locPickHintDone => 'Tap again to move the marker.';

  @override
  String get locPickJumpToMe => 'Jump to my location';

  @override
  String get locPickConfirm => 'Use this location';

  @override
  String get evBadgeAvailable => 'A badge is available here';

  @override
  String get evBadgeAvailableSub =>
      'You can collect a badge on site — on the day of the event, near the venue.';

  @override
  String get evBadgeYouIssue => 'You may issue badges here';

  @override
  String get evBadgeYouIssueSub =>
      'On the day of the event you can start a session on site and hand out badges.';

  @override
  String get evBadgeStartSession => 'Start badge session';

  @override
  String get evSessionNoIdentity => 'No Nostr key available. Create one first.';

  @override
  String get evSessionNotIssuer =>
      'You are not listed as an issuer for this event.';

  @override
  String get evSessionOutsideWindow =>
      'Badges are only available on the day of the event.';

  @override
  String get evSessionNoEventLocation =>
      'No location is stored for this event. Without coordinates there is no way to check that you are on site.';

  @override
  String get evSessionNoLocation =>
      'Location unavailable. Check the location service and permission.';

  @override
  String evSessionTooFar(String km) {
    return 'You are $km km from the venue. Badges can only be issued on site.';
  }

  @override
  String get evSessionFailed =>
      'Could not start the session. Details are in the diagnostics log.';

  @override
  String mvEventIssuerOk(String event, String creator) {
    return 'Event badge from “$event” — issued with permission from $creator.';
  }

  @override
  String mvEventSignerNotListed(String event) {
    return 'Careful: the issuer is not listed as a helper for “$event”.';
  }

  @override
  String mvEventCreatorNotAuthorized(String event) {
    return 'Careful: whoever created “$event” is not a registered organiser.';
  }

  @override
  String mvEventHasNoBadge(String event) {
    return 'Careful: “$event” is not supposed to hand out badges at all.';
  }

  @override
  String get mvEventNotFound =>
      'The linked event cannot be found. Without a connection the permission cannot be checked.';

  @override
  String get evBadgeShowSession => 'Show QR code';

  @override
  String get badgeShareTagline => 'Was there in person — verified over Nostr.';

  @override
  String get shareCardCollectedBy => 'Collected by';

  @override
  String get shareCardBlock => 'Block';

  @override
  String get shareCardScanned => 'Scanned';

  @override
  String get shareCardChecksum => 'Checksum';

  @override
  String get shareCardPromo =>
      'Been to an Einundzwanzig meetup? Collect your badge — cryptographic proof that you were there.';

  @override
  String get backupPwShow => 'Show password';

  @override
  String get backupPwHide => 'Hide password';

  @override
  String backupPwRuleLength(int min) {
    return 'At least $min characters — a long passphrase beats a short, complicated password.';
  }

  @override
  String get backupPwRuleMatch => 'Both entries match';

  @override
  String get idSetupOtherWaySub => 'nsec, ncryptsec, bunker or backup';

  @override
  String get guideWelcomeTitle => 'Welcome!';

  @override
  String get guideWelcomeBody =>
      'Would you like a quick tour of the app? We\'ll show you the most important features.';

  @override
  String get guideStart => 'Start tour';

  @override
  String get guideNoThanks => 'No thanks';

  @override
  String get guideSkip => 'SKIP';

  @override
  String get guideFinishTour => 'End tour';

  @override
  String get guideBack => 'Back';

  @override
  String get guideOnboardWelcomeTitle => 'Let\'s set up your profile';

  @override
  String get guideOnboardWelcomeBody =>
      'We\'ll walk you through the setup step by step. It only takes a minute.';

  @override
  String get guideOnboardNicknameTitle => 'Choose a Nickname';

  @override
  String get guideOnboardNicknameBody =>
      'This is how other community members will see you. Pick something memorable!';

  @override
  String get guideOnboardMeetupTitle => 'Select Your Home Meetup';

  @override
  String get guideOnboardMeetupBody =>
      'Your home meetup determines which badges you can collect and which events you see first.';

  @override
  String get guideOnboardNostrTitle => 'Your Nostr Key';

  @override
  String get guideOnboardNostrBody =>
      'This cryptographic key signs your badges and verifies your reputation. It\'s stored only on your device.';

  @override
  String get guideOnboardSaveTitle => 'Save Your Profile';

  @override
  String get guideOnboardSaveBody =>
      'Tap here when you\'re done. You can always change these settings later.';

  @override
  String get guideHomeMeetupTitle => 'Your Home Meetup';

  @override
  String get guideHomeMeetupBody =>
      'Your favorite meetups and the next upcoming event – at a glance.';

  @override
  String get guideHomeTrustScoreTitle => 'Your Trust Score';

  @override
  String get guideHomeTrustScoreBody =>
      'Here you see your current standing. Tap for a breakdown by diversity, activity & quality.';

  @override
  String get guideHomeReputationTitle => 'Reputation';

  @override
  String get guideHomeReputationBody =>
      'Check your reputation or verify someone else\'s trust score.';

  @override
  String get guideHomeWotTitle => 'Trust Network';

  @override
  String get guideHomeWotBody =>
      'See how you\'re connected to others in the Web of Trust.';

  @override
  String get guideHomeCommunityTitle => 'Community Portal';

  @override
  String get guideHomeCommunityBody =>
      'Access the podcast, shoutouts, merch and more.';

  @override
  String get guideHomeUmrechnerTitle => 'Converter';

  @override
  String get guideHomeUmrechnerBody => 'Quickly convert between EUR and sats.';

  @override
  String get guideHomeBitcoinTitle => 'Bitcoin Price';

  @override
  String get guideHomeBitcoinBody =>
      'Current price, network stats and block height.';

  @override
  String get guideHomeBadgeWalletTitle => 'Badge Wallet';

  @override
  String get guideHomeBadgeWalletBody =>
      'All collected badges – cryptographically signed and stored only on your device.';

  @override
  String get guideHomeScanTitle => 'Claim a Badge';

  @override
  String get guideHomeScanBody =>
      'Tap here to scan the organizer\'s QR code at a meetup or hold your device via NFC.';

  @override
  String get guideHomeSettingsTitle => 'Settings';

  @override
  String get guideHomeSettingsBody =>
      'Configure backup, language, relays and more. Don\'t forget to create a backup!';

  @override
  String get guideSettingsBackupTitle => 'Create a Backup!';

  @override
  String get guideSettingsBackupBody =>
      'IMPORTANT: Create a backup to protect your account. Without it, your badges and profile are lost if you lose your device.';

  @override
  String get guideSettingsLanguageTitle => 'Language';

  @override
  String get guideSettingsLanguageBody =>
      'Switch between German, English and Spanish.';

  @override
  String get guideSettingsRelaysTitle => 'Nostr Relays';

  @override
  String get guideSettingsRelaysBody =>
      'Configure which Nostr relays your app connects to.';

  @override
  String get guideSettingsHapticTitle => 'Haptic Feedback';

  @override
  String get guideSettingsHapticBody => 'Enable or disable vibration feedback.';

  @override
  String get guideSettingsResetTitle => 'Reset App';

  @override
  String get guideSettingsResetBody =>
      'This deletes your profile and all badges. Make sure you have a backup first!';

  @override
  String get guideEventsSearchTitle => 'Search Events';

  @override
  String get guideEventsSearchBody => 'Search for meetups by city or keyword.';

  @override
  String get guideEventsCalendarTitle => 'Calendar';

  @override
  String get guideEventsCalendarBody => 'Browse all upcoming meetup events.';

  @override
  String get guideEventsCardTitle => 'Event Details';

  @override
  String get guideEventsCardBody =>
      'Tap an event to see details, location and links.';

  @override
  String get guideEventsCreateTitle => 'Create Event';

  @override
  String get guideEventsCreateBody =>
      'As an organizer, you can create new meetup events here.';

  @override
  String get guidePortalShoutoutTitle => 'Send a Shoutout';

  @override
  String get guidePortalShoutoutBody =>
      'Send a public shoutout to the community.';

  @override
  String get guidePortalPodcastTitle => 'Podcast';

  @override
  String get guidePortalPodcastBody =>
      'Listen to the Einundzwanzig podcast directly in the app.';

  @override
  String get guidePortalSoundboardTitle => 'Soundboard';

  @override
  String get guidePortalSoundboardBody =>
      'Play clips and sounds from the podcast.';

  @override
  String get guidePortalMerchTitle => 'Shop';

  @override
  String get guidePortalMerchBody => 'Browse merch and Bitcoin products.';

  @override
  String get guidePortalMembershipTitle => 'Become a Member';

  @override
  String get guidePortalMembershipBody =>
      'Support the association by becoming a member.';

  @override
  String get guidePortalMapTitle => 'Meetup Map';

  @override
  String get guidePortalMapBody => 'Find meetups near you on the map.';

  @override
  String get guideWalletBadgesTitle => 'Your Badges';

  @override
  String get guideWalletBadgesBody =>
      'All collected badges – cryptographically signed and stored only on your device.';

  @override
  String get guideWalletShareQrTitle => 'Share QR Code';

  @override
  String get guideWalletShareQrBody =>
      'Show your reputation QR code for on-site scanning.';

  @override
  String get guideWalletExportTitle => 'Export as JSON';

  @override
  String get guideWalletExportBody =>
      'Signed export with Schnorr proof for verification.';

  @override
  String get guideWalletShareTextTitle => 'Share as Text';

  @override
  String get guideWalletShareTextBody =>
      'Share your reputation as readable text.';

  @override
  String get guideReputationScoreTitle => 'Your Score';

  @override
  String get guideReputationScoreBody =>
      'Your trust score is calculated from badges, diversity and activity.';

  @override
  String get guideReputationLevelTitle => 'Your Level';

  @override
  String get guideReputationLevelBody =>
      'From NEW to VETERAN – your level grows with your participation.';

  @override
  String get guideReputationStatsTitle => 'Statistics';

  @override
  String get guideReputationStatsBody =>
      'Badges, meetups, signers and bound proofs at a glance.';

  @override
  String get guideReputationShareTitle => 'Share Reputation';

  @override
  String get guideReputationShareBody =>
      'Share your verified reputation via QR code or text.';

  @override
  String get guideReputationUpdateTitle => 'Update on Relays';

  @override
  String get guideReputationUpdateBody =>
      'Publish your latest reputation to the Nostr network.';

  @override
  String guideStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get guideStepDone => 'Done';

  @override
  String get guideHintNickname => 'Tap the field and enter your nickname.';

  @override
  String get guideHintOpenPicker => 'Tap the field to open the meetup picker.';

  @override
  String get guideHintSearchCity => 'Type the first letters of your city.';

  @override
  String get guideHintStarMeetup => 'Tap the star next to your meetup.';

  @override
  String get guideHintConfirmSelection =>
      'Confirm your selection with the button below.';

  @override
  String get guideHintNostrKey => 'Create a new key or import an existing one.';

  @override
  String get guideHintSave => 'Tap SAVE PROFILE.';

  @override
  String get guideOnboardMeetupSearchTitle => 'Search for your city';

  @override
  String get guideOnboardMeetupSearchBody =>
      'Type your city name — the list filters instantly.';

  @override
  String get guideOnboardMeetupPickTitle => 'Mark your meetup';

  @override
  String get guideOnboardMeetupPickBody =>
      'Star your meetup. You can pick several favourites; the first one becomes your home meetup.';

  @override
  String get guideOnboardMeetupConfirmTitle => 'Confirm your selection';

  @override
  String get guideOnboardMeetupConfirmBody =>
      'The button shows how many favourites you picked. Tap it to return to your profile.';

  @override
  String get guideOnboardPlatformsTitle => 'Link your platforms';

  @override
  String get guideOnboardPlatformsBody =>
      'Connect accounts such as Telegram, X or classifieds to your Nostr identity. Every confirmed platform feeds into your trust score and shows others that a real person stands behind the profile.';

  @override
  String get guideHintPlatforms =>
      'Optional — you can do this later from your profile.';

  @override
  String get guideOnboardHumanityTitle => 'Proof of humanity';

  @override
  String get guideOnboardHumanityBody =>
      'A single lightning zap proves you operate a real wallet — the most effective guard against bot accounts in the web of trust. If you have zapped already, verify it here.';

  @override
  String get guideHintHumanity =>
      'Optional — the app works without this proof too.';

  @override
  String get guideHomeEventsTitle => 'Events';

  @override
  String get guideHomeEventsBody =>
      'This tile shows whether anything is happening today. It turns orange as soon as an event is scheduled for the day and takes you to the calendar of all upcoming meetups.';

  @override
  String get guideHomeShoutoutTitle => 'Shoutout';

  @override
  String get guideHomeShoutoutBody =>
      'Send a message to the community — it lands on the Einundzwanzig shoutout page. The tile opens it in your browser.';

  @override
  String get guideHomePodcastTitle => 'Podcast';

  @override
  String get guideHomePodcastBody =>
      'The Einundzwanzig podcast, straight from the app. The tile opens the episode list in your browser.';

  @override
  String get guideHomePortalConnectTitle => 'Portal connection';

  @override
  String get guideHomePortalConnectBody =>
      'Green means connected, red means disconnected. Connecting to the Einundzwanzig portal gives you the events and courses maintained there. Tapping the tile toggles it.';

  @override
  String get guideHomeNewsTitle => 'News';

  @override
  String get guideHomeNewsBody =>
      'The latest community headline sits right on the tile. Tap it for the full list.';

  @override
  String get guideHomeMyMeetupsTitle => 'My meetups';

  @override
  String get guideHomeMyMeetupsBody =>
      'Here you manage your meetups\' events in the portal — create, change, cancel. Only useful if you organise yourself.';

  @override
  String get guideHomeMoreTitle => 'And there\'s more';

  @override
  String get guideHomeMoreBody =>
      'Four more tiles are waiting on your dashboard: SatoshiDuell for quiz rounds over sats, PlebRap for community music, the portal area with meetups, events, courses and map, and the Nostr tile with the latest notes from your network. Each one can be hidden or shown again in the settings.';

  @override
  String get guideHomeNearbyTitle => 'Nearby';

  @override
  String get guideHomeNearbyBody =>
      'Shows meetups around you — handy when travelling or when you are looking for a second group in the region. The screen opens on top of the app; back brings you here again.';

  @override
  String get guideHomeEventsTabTitle => 'Events area';

  @override
  String get guideHomeEventsTabBody =>
      'The fourth button leads to the full calendar: every event, filterable by place and period, with reminders.';

  @override
  String get guideHomeSettingsBackupHint =>
      'Head straight for the backup — without it your key is gone if you lose your phone.';

  @override
  String get guideHintBackup =>
      'Create an encrypted backup now — it takes a minute.';

  @override
  String get guideEvBadgeSwitchTitle => 'Badge for your event';

  @override
  String get guideEvBadgeSwitchBody =>
      'Flip the switch if attendees should be able to collect a badge on site. Without it, this is just a calendar entry.';

  @override
  String get guideEvBadgeSwitchHint =>
      'If you do not need a badge for this event, just tap Continue.';

  @override
  String get guideEvBadgeImageTitle => 'The image';

  @override
  String get guideEvBadgeImageBody =>
      'Pick an image from your gallery — it gets uploaded and appears on every badge from this event. Without one, the generated artwork carries the card alone.';

  @override
  String get guideEvBadgeLocationTitle => 'The location matters';

  @override
  String get guideEvBadgeLocationBody =>
      'Place the marker where the event happens — not where you are right now. Badges can only be issued near it and only on the day of the event.';

  @override
  String get guideEvBadgeIssuersTitle => 'Your helpers';

  @override
  String get guideEvBadgeIssuersBody =>
      'Add the npubs of everyone who should hand out badges on site. They need no organiser role — the permission lives in the event and applies to this event only. You are always allowed.';

  @override
  String get glTitle => 'Reference';

  @override
  String get glSearchHint => 'Search — e.g. badge, trust score, backup';

  @override
  String get glNoResults =>
      'Nothing found. Try another word — the search also covers the body text.';

  @override
  String get glCatStart => 'Getting started';

  @override
  String get glCatBadges => 'Badges';

  @override
  String get glCatReputation => 'Reputation';

  @override
  String get glWhatIsAppTitle => 'What this app does';

  @override
  String get glWhatIsAppBody =>
      'It proves you were physically present at a Bitcoin meetup. Over time those proofs add up to a reputation that belongs to you and that nobody can revoke — it does not sit on an Einundzwanzig server but signed on the Nostr network.';

  @override
  String get glCollectTitle => 'How to collect a badge';

  @override
  String get glCollectBody =>
      'Go to the meetup and ask the organiser to show the QR code. Tap the round scan button in the bottom bar, capture the code — done. The badge then sits in your badge wallet.';

  @override
  String get glHomeMeetupTitle => 'Your home meetup';

  @override
  String get glHomeMeetupBody =>
      'The meetup you attend regularly. It decides which events you see first and which crest appears on your badges. You can pick several favourites — the first counts as your home meetup. You can change it any time in your profile.';

  @override
  String get glOfflineTitle => 'What works offline';

  @override
  String get glOfflineBody =>
      'Scanning and receiving a badge works offline — your device verifies the signature itself. Without a connection you only lose what comes from outside: block height, price, events and the check whether the organiser is registered.';

  @override
  String get glBadgeProofTitle => 'What a badge proves';

  @override
  String get glBadgeProofBody =>
      'That you were at a particular place at a particular time — confirmed by someone who was there too. The confirmation is a Schnorr signature per BIP-340. Nobody can forge it, not even the developers, because that would require the organiser\'s private key.';

  @override
  String get glRollingQrTitle => 'The rolling QR';

  @override
  String get glRollingQrBody =>
      'The organiser\'s code changes every few seconds. A photo of it is worthless minutes later — only someone actually standing in front of it can capture it. That is exactly why a badge cannot be passed on via chat.';

  @override
  String get glOnSiteTitle => 'Why only on site';

  @override
  String get glOnSiteBody =>
      'Besides the rotating code the app also checks distance: anyone too far from the meetup gets no badge. For meetups the limits are generous because some groups cover whole regions; for special events the location is precise and the limit tight.';

  @override
  String get glBadgeShareTitle => 'Sharing a badge';

  @override
  String get glBadgeShareBody =>
      'Open a badge and tap share in the top right. The app renders an image with place, date, block height and checksum. Anyone who sees it can follow the details — your private key is not in there.';

  @override
  String get glTrustScoreTitle => 'The trust score';

  @override
  String get glTrustScoreBody =>
      'A number summarising how solid your attendance record is. Quantity alone does not decide it: different meetups, different organisers and regularity over time weigh more than twenty visits to the same place in one week.';

  @override
  String get glLevelsTitle => 'The levels';

  @override
  String get glLevelsBody =>
      'As your trust score grows you reach higher levels. From a certain level you can run sessions and issue badges yourself — that is not an award but a responsibility: your signature then sits under other people\'s badges.';

  @override
  String get glHumanityTitle => 'Proof of humanity';

  @override
  String get glHumanityBody =>
      'A single lightning zap shows that a person with a real wallet stands behind the profile. It is the most effective guard against automatically created accounts in the web of trust. Optional — the app works without it.';

  @override
  String get glPlatformsTitle => 'Platform proofs';

  @override
  String get glPlatformsBody =>
      'You can link accounts such as Telegram or X to your Nostr identity. Every confirmed platform feeds into the trust score and shows others that an established person stands behind the profile. Also optional.';

  @override
  String get guideHomeGlossaryTitle => 'Look it up';

  @override
  String get guideHomeGlossaryBody =>
      'Everything is explained again here, calmly — sorted by topic and searchable. When this tour is over and a question remains, the answer is in here.';

  @override
  String get glCatNetwork => 'Web of trust';

  @override
  String get glCatIdentity => 'Identity & keys';

  @override
  String get glCatEvents => 'Events';

  @override
  String get glCatNostr => 'Nostr';

  @override
  String get glEncounterTitle => 'Encounters';

  @override
  String get glEncounterBody =>
      'Anyone who scanned with the same organiser on the same day counts as having met. That forms a web of people who actually shared a room — not of people who follow each other online.';

  @override
  String get glDegreesTitle => 'Degrees';

  @override
  String get glDegreesBody =>
      'First degree means you were with the same organiser. Second degree: someone you met has met that person. If a meetup had two organisers, their scanning each other bridges both groups — you are then connected at second degree instead of first.';

  @override
  String get glVouchTitle => 'Vouches';

  @override
  String get glVouchBody =>
      'Organisers can vouch for each other. A vouch is a public, signed statement — once published the whole network sees who you stand for. It can be withdrawn at any time, but the withdrawal is just as visible.';

  @override
  String get glEventNetTitle => 'Event network';

  @override
  String get glEventNetBody =>
      'Special events are counted separately. At a meetup with fifteen people you meet everyone — at an event with five hundred you do not. Mixing both would devalue what the network says, so events have their own category.';

  @override
  String get glKeysTitle => 'nsec and npub';

  @override
  String get glKeysBody =>
      'Your npub is your public address — share it freely. The nsec is the private key and belongs to nobody else: whoever has it IS you. There is no reset. If the nsec is gone, the identity and its reputation are gone with it.';

  @override
  String get glPasswordTitle => 'The two passwords';

  @override
  String get glPasswordBody =>
      'During setup you set a password that wraps your key on the device. For a backup you set a second one that encrypts the backup file. They may be identical but are independent — and neither can be reset.';

  @override
  String get glSignerTitle => 'Signer apps';

  @override
  String get glSignerBody =>
      'Instead of keeping the key in this app you can entrust it to a signer app such as Amber or connect it through a bunker. This app then asks there for every signature and never sees the key itself.';

  @override
  String get glBackupTitle => 'The backup';

  @override
  String get glBackupBody =>
      'Saves keys, badges and settings into an encrypted file. Without it everything is lost when the device is — no phone, no reputation. Create it early, not when you need it, and keep the file separate from the password.';

  @override
  String get glSpecialEventTitle => 'Special events';

  @override
  String get glSpecialEventBody =>
      'Besides the regular meetups there are one-off events with their own badges. They count as a badge and towards the variety of issuers, but not as a meetup visited — three large events do not replace a local community.';

  @override
  String get glEventHelperTitle => 'Helpers at an event';

  @override
  String get glEventHelperBody =>
      'Whoever creates an event with a badge can list any npubs as issuers. Those helpers need no organiser role — the permission lives in the event and applies to that one event only. Each helper shows their own QR code.';

  @override
  String get glEventWindowTitle => 'Location and time window';

  @override
  String get glEventWindowBody =>
      'An event badge can only be issued on the day of the event and only near the registered location. Together this prevents somebody handing out badges from home for an event they are not attending.';

  @override
  String get glRelaysTitle => 'Relays';

  @override
  String get glRelaysBody =>
      'Relays are the servers Nostr messages travel through. The app writes to several at once so nothing is lost when one fails. You can add your own in the settings — they are checked for reachability before being saved.';

  @override
  String get glPublicTitle => 'What is public';

  @override
  String get glPublicBody =>
      'Badges, attendance records and vouches sit openly on the relays — anyone can read and verify them, which is the whole point. Not public are your private key, your backup password and your exact location.';

  @override
  String get glZapTitle => 'Zaps';

  @override
  String get glZapBody =>
      'A zap is a small lightning payment with a Nostr receipt attached. In the news section you can send authors something directly; the app hands the invoice to your wallet. A single zap also serves as proof of humanity.';

  @override
  String get guideEvBasicsTitle => 'Title and place';

  @override
  String get guideEvBasicsBody =>
      'The title appears in the event list later and on the badge, if you issue one. The location field is the address to read out — the coordinates for issuing badges are set separately on the map further down.';

  @override
  String get guideEvWhenWhereTitle => 'When it happens';

  @override
  String get guideEvWhenWhereBody =>
      'A start is required, the end is optional. For an event with a badge the calendar day matters: badges can only be issued on that day, from midnight to midnight.';

  @override
  String get glCatApp => 'App & handling';

  @override
  String get glTilesTitle => 'Customising the dashboard';

  @override
  String get glTilesBody =>
      'Press and hold a tile to move or hide it. Trust score and home meetup always stay; everything else can be unpinned. Hidden tiles go to the tile manager and can be brought back any time.';

  @override
  String get glLanguageTitle => 'Language';

  @override
  String get glLanguageBody =>
      'The app is available in German, English and Spanish. Without an explicit choice it follows the system language. You can switch it in the settings; the change takes effect immediately, no restart needed.';

  @override
  String get glLogTitle => 'Diagnostics log';

  @override
  String get glLogBody =>
      'A record of what the app does in the background — which relays answered, why a scan was rejected. When something goes wrong this is the first place to look. It stays on the device and is never uploaded.';

  @override
  String get glResetTitle => 'Resetting the app';

  @override
  String get glResetBody =>
      'Deletes profile, keys and all badges from the device — permanently. Without a backup your identity is gone afterwards, even though the badges live on in the relays: without the matching key you can no longer claim them. Make a backup first.';

  @override
  String get glNicknameTitle => 'Your display name';

  @override
  String get glNicknameBody =>
      'The name you appear under in the network. It is freely chosen, need not be your real one and can be changed any time — your identity hangs on the key, not on the name.';

  @override
  String get glFindMeetupTitle => 'Finding meetups';

  @override
  String get glFindMeetupBody =>
      'The meetup search lists every registered group. Nearby instead shows what is around your current location — useful when travelling or when looking for a second group in the region.';

  @override
  String get glBlockHeightTitle => 'The block height';

  @override
  String get glBlockHeightBody =>
      'Every badge carries the number of the Bitcoin block that was current at scan time. It acts as a timestamp nobody can move afterwards — unlike a phone clock, which can be set to anything.';

  @override
  String get glChecksumTitle => 'The checksum';

  @override
  String get glChecksumBody =>
      'A short fingerprint over the whole badge content. Two people can compare badges from the same meetup: if the checksums match, both received the same data. It appears in the badge details and on the shared image.';

  @override
  String get glWorldMapTitle => 'The badge world map';

  @override
  String get glWorldMapBody =>
      'Shows your collected badges where you received them. A list of names turns into a map of your meetup visits — handy for spotting where the blank areas still are.';

  @override
  String get glDuplicateTitle => 'Duplicate badges';

  @override
  String get glDuplicateBody =>
      'There is exactly one badge per meetup and day. Scanning the same code twice does not give you a second one — by design: a badge stands for a visit, not for a scan.';

  @override
  String get glVerifyPersonTitle => 'Verifying someone';

  @override
  String get glVerifyPersonBody =>
      'Have the other person show their reputation QR and scan it. The app verifies whether the claims match the signed badges and shows how you are connected in the network. Useful before trading with a stranger.';

  @override
  String get glRepCardTitle => 'The reputation card';

  @override
  String get glRepCardBody =>
      'A shareable overview of your reputation as an image — level, number of meetups, time span. It contains no private key and can be posted without worry.';

  @override
  String get glPublishTitle => 'Publishing your reputation';

  @override
  String get glPublishBody =>
      'For others to check your reputation it has to be on the relays. The app publishes it signed; without that step a counterpart only sees what you show them directly.';

  @override
  String get glTrustPathTitle => 'Trust path';

  @override
  String get glTrustPathBody =>
      'Shows the chain connecting you to another person — who met whom and where. An abstract number becomes a statement you can follow: not just that you are connected, but through what.';

  @override
  String get glDistrustTitle => 'Reports and suspension';

  @override
  String get glDistrustBody =>
      'Organisers can report abuse. If reports against someone pile up, they are marked as suspended in the network — their badges do not vanish but carry that warning. A report is signed too and thus attributable to its author.';

  @override
  String get glOrganizerTitle => 'Becoming an organiser';

  @override
  String get glOrganizerBody =>
      'From a certain trust score you can run sessions yourself. On top of that you usually need vouches from existing organisers — the role is not granted, it grows out of the network.';

  @override
  String get glNcryptsecTitle => 'ncryptsec';

  @override
  String get glNcryptsecBody =>
      'An nsec encrypted with a password (NIP-49). The string starts with ncryptsec1 and is worthless without the password — so it travels more safely than a bare nsec. This is also how your key sits on the device.';

  @override
  String get glPasskeyTitle => 'Passkey';

  @override
  String get glPasskeyBody =>
      'Extra protection via fingerprint or face recognition. The passkey does not replace your password, it sits in front of it. Optional, and only on this device — on a new one you need the password or backup again.';

  @override
  String get glNip05Title => 'NIP-05 address';

  @override
  String get glNip05Body =>
      'A readable address of the form name@domain pointing to your key — like a name tag for the network. It shows that somebody with access to that domain vouches for you, but replaces none of the other checks.';

  @override
  String get glImportTitle => 'Bringing your own key';

  @override
  String get glImportBody =>
      'If you already have a Nostr identity you can use it here — as nsec, as ncryptsec or via a bunker. Your existing contacts and profile stay intact; the app only adds badges and reputation.';

  @override
  String get glRestoreTitle => 'Restoring a backup';

  @override
  String get glRestoreBody =>
      'During setup you can load a backup instead of creating a new key. You need the file AND the password it was encrypted with — one alone is not enough. Afterwards the identity and its badges are back.';

  @override
  String get glCalendarSourcesTitle => 'Where events come from';

  @override
  String get glCalendarSourcesBody =>
      'The calendar merges two sources: events from the Einundzwanzig portal and ones somebody entered via Nostr. Colour tells them apart — portal meetups orange, Nostr events cyan.';

  @override
  String get glPortalTitle => 'The portal connection';

  @override
  String get glPortalBody =>
      'You can sign in to the Einundzwanzig portal with your Nostr key. You then see the events and courses maintained there and, as a leader, can create your own. Everything else keeps working without the connection.';

  @override
  String get glCreateEventTitle => 'Creating an event';

  @override
  String get glCreateEventBody =>
      'Anyone can add an event — it is published signed on Nostr and appears in everyone\'s calendar. Only organisers and leaders, however, may attach a badge to it.';

  @override
  String get glNostrBasicsTitle => 'What Nostr is';

  @override
  String get glNostrBasicsBody =>
      'An open protocol for messages signed by their own author. There is no company behind it and no account that could be suspended — only keys and relays. That is why the identity from this app also works in other Nostr applications.';

  @override
  String get glNewsTitle => 'The news section';

  @override
  String get glNewsBody =>
      'The articles come from the Einundzwanzig magazine and exist as Nostr long-form posts. You can read them in the app, like them, share them and zap the authors sats — all with the same identity.';

  @override
  String get glConverterTitle => 'Converter and price';

  @override
  String get glConverterBody =>
      'Converts euro to sats and back. Price and block height come from a mempool instance; which one is up to you in the settings — your own node, for example.';

  @override
  String get glCommunityTitle => 'Community section';

  @override
  String get glCommunityBody =>
      'A hub for everything around Einundzwanzig that is not directly about badges: podcast, shoutouts, PlebRap, SatoshiDuell and the meetup map. Much of it opens in the browser.';

  @override
  String get settingsRestartGuide => 'Repeat the tour';

  @override
  String get settingsRestartGuideSub => 'Show all spotlight tours again';

  @override
  String get settingsGuideReset =>
      'Tours reset — they will start again when you next open those areas.';

  @override
  String get guideSettingsRestartTitle => 'Repeat the tour';

  @override
  String get guideSettingsRestartBody =>
      'Resets all spotlight tours. They start again the next time you open the relevant area — handy when you want to see something once more.';

  @override
  String get guideWalletMapTitle => 'World map';

  @override
  String get guideWalletMapBody =>
      'Shows your badges where you collected them. A list turns into a map of your meetup visits.';

  @override
  String get guideWalletViewTitle => 'Switch the view';

  @override
  String get guideWalletViewBody =>
      'Switch between large cards and a compact overview. With many badges the compact view is quicker to scan.';

  @override
  String get guideCommunityPortalTitle => 'The portal';

  @override
  String get guideCommunityPortalBody =>
      'Access to meetups, events, courses and the map on einundzwanzig.space. Much of it opens in the browser.';

  @override
  String get guideCommunityNewsTitle => 'News and Nostr';

  @override
  String get guideCommunityNewsBody =>
      'Articles from the Einundzwanzig magazine and the latest notes from your Nostr network — both readable right in the app.';

  @override
  String get guideCommunityFunTitle => 'Join in';

  @override
  String get guideCommunityFunBody =>
      'SatoshiDuell for quiz rounds over sats and PlebRap for community music. Both need nothing but your identity.';

  @override
  String get guideMyMeetupsListTitle => 'Your meetups';

  @override
  String get guideMyMeetupsListBody =>
      'The meetups you are registered for in the portal. Tap one to see and maintain its events — the button down there also creates new ones.';

  @override
  String get guideMyMeetupsCreateTitle => 'Create an event';

  @override
  String get guideMyMeetupsCreateBody =>
      'Adds a new event in the portal. It then appears in the calendar of everyone who has this meetup as a favourite.';

  @override
  String get guideWotTabsTitle => 'The three views';

  @override
  String get guideWotTabsBody =>
      'Network shows who is connected to whom. Vouches shows who you stand for and who stands for you. Reports collects the warnings from the network.';

  @override
  String get guideWotRefreshTitle => 'Refresh';

  @override
  String get guideWotRefreshBody =>
      'Fetches the current state from the relays. The network grows with every meetup — without refreshing you see the state from your last visit.';

  @override
  String get guideHomeCustomizeTitle => 'Your dashboard';

  @override
  String get guideHomeCustomizeBody =>
      'Under this heading sit the tiles you have not pinned — they are not gone, just set aside. Press and hold a tile to pin, unpin or move it. That way the top holds exactly what you actually use.';

  @override
  String get guidePaMeetupsTitle => 'Meetups and events';

  @override
  String get guidePaMeetupsBody =>
      'Both lead into the calendar: one to the groups, the other to the upcoming events. What you see there depends on your favourites — more favourites, fuller list.';

  @override
  String get guidePaCoursesTitle => 'Courses';

  @override
  String get guidePaCoursesBody =>
      'The Einundzwanzig educational offerings along with their lecturers — from a beginners\' evening to a multi-part series. Tap a course for content, dates and who teaches it.';

  @override
  String get guidePaMapTitle => 'The map';

  @override
  String get guidePaMapBody =>
      'Shows meetups around you on a map. Handy when travelling — or when you want to know what else exists in the region besides your home meetup.';

  @override
  String get guidePaMineTitle => 'My meetups';

  @override
  String get guidePaMineBody =>
      'Only of interest to organisers: here you maintain the events of the meetups you are registered for in the portal. If you run none, you will find an empty list.';

  @override
  String get guideSettingsProfileTitle => 'Profile and keys';

  @override
  String get guideSettingsProfileBody =>
      'Here you change your name and home meetup — and here your Nostr keys live. At the bottom you can copy the npub and reveal the nsec. If the app created a key for you, this is where you find it.';

  @override
  String get glFindKeysTitle => 'Where are my keys?';

  @override
  String get glFindKeysBody =>
      'Settings → Profile, at the very bottom. There you copy the npub with one tap and reveal the nsec — the latter only after a warning, because whoever sees the nsec has your identity. If you use Amber, a browser extension or a bunker there is no nsec here: it lives there, not in this app.';

  @override
  String get idSetupSecureTitle => 'Identity created — secure it now';

  @override
  String get idSetupSecureBody =>
      'There are two ways to secure this — they do different things. Best to do both.';

  @override
  String get idSetupSecureBackup => 'Create a backup';

  @override
  String get idSetupSecureCopy => 'Copy key to clipboard';

  @override
  String get idSetupSecureWhere =>
      'You can find your keys any time under Settings → Profile.';

  @override
  String get idSetupSecureBackupTitle => 'Backup file';

  @override
  String get idSetupSecureBackupBody =>
      'Contains everything: keys, badges, reputation and settings. With it your app comes back exactly as it was on a new device. The file is encrypted with its own password.';

  @override
  String get idSetupSecureKeyTitle => 'Encrypted key';

  @override
  String get idSetupSecureKeyBody =>
      'Finally your Nostr key on its own, wrapped with your password (ncryptsec). It saves your identity but no badges — in exchange it never goes stale and fits into any password manager.';

  @override
  String get idSetupSecureRepeat =>
      'Repeat the backup now and then under Settings → Backup. A file from today does not know tomorrow\'s badges — anything added later would be lost if the device is.';

  @override
  String get idSetupSecureKeySave => 'Save as a file';

  @override
  String get idSetupSecureKeySaved => 'Key file saved.';

  @override
  String get idSetupSecureSkip => 'Skip';

  @override
  String get idSetupSecureFileHeader =>
      'Einundzwanzig Meetup App — encrypted Nostr key (ncryptsec, NIP-49). Without the matching password this file is worthless. Keep the two apart.';

  @override
  String get chatRelayHint => 'Einundzwanzig group relay';

  @override
  String get chatEmpty =>
      'No messages yet. Write the first one — the room sits openly on the relay and is reachable from other Nostr apps too.';

  @override
  String get chatPlaceholder => 'Write a message …';

  @override
  String get chatJoin => 'Join the room';

  @override
  String get chatJoinHint =>
      'You can read along here without anything further. To write you have to join the room — the relay keeps the member list.';

  @override
  String chatJoinFailed(String msg) {
    return 'Join rejected: $msg';
  }

  @override
  String chatSendFailed(String msg) {
    return 'Message not delivered: $msg';
  }

  @override
  String get chatSearching => 'Looking for the chat room …';

  @override
  String chatNoRoom(String city) {
    return 'There is no chat room for $city on the group relay yet. Details are in the diagnostics log.';
  }

  @override
  String get chatEventOpen => 'Chat about this event';

  @override
  String get chatEventFailed =>
      'The chat room could not be opened. Details are in the diagnostics log.';

  @override
  String get btnChat => 'Chat';

  @override
  String get btnInfo => 'Info';

  @override
  String get chatEventHint => 'Comments on this event · public on Nostr';

  @override
  String get chatEventEmpty =>
      'Nothing written yet. Share information about this event here — meeting point, changes, questions. The comments hang on the event itself and are visible from any Nostr app.';

  @override
  String get chatMemberHint =>
      'Joining requires membership in the Einundzwanzig association. Without it the relay rejects the request — you stay a silent reader.';

  @override
  String get chatMemberLink => 'About membership';

  @override
  String walletSince(String month) {
    return 'since $month';
  }

  @override
  String walletLastVisit(String ago) {
    return 'last $ago';
  }

  @override
  String get walletAgoToday => 'today';

  @override
  String get walletAgoYesterday => 'yesterday';

  @override
  String walletAgoDays(int days) {
    return '$days days ago';
  }

  @override
  String walletAgoMonths(int months) {
    return '$months months ago';
  }

  @override
  String walletAgoYears(int years) {
    return '$years years ago';
  }

  @override
  String walletCollectionCount(int count) {
    return '$count badges';
  }

  @override
  String get rsvpYes => 'I\'m coming';

  @override
  String get rsvpNo => 'Not coming';

  @override
  String get tileEventChats => 'My events';

  @override
  String get tileEventChatsSub => 'RSVPs & chats';

  @override
  String get eventChatsTitle => 'My events';

  @override
  String get eventChatsEmpty =>
      'This shows the next dates of your meetups and every event you have accepted. Pick a favourite meetup or accept an event in the calendar.';

  @override
  String tileEventChatsUnread(int count) {
    return '$count new messages';
  }

  @override
  String get chatYou => 'You';

  @override
  String get chatCopyNpub => 'Copy npub';

  @override
  String get chatNpubCopied => 'npub copied.';

  @override
  String get eventChatsMeetups => 'My meetups';

  @override
  String get eventChatsEvents => 'Events I\'m attending';

  @override
  String get tileEventChatsNone => 'Nothing planned';

  @override
  String rsvpAttendees(int count) {
    return '$count attending';
  }

  @override
  String get rsvpWithdrawTitle => 'Withdraw your RSVP?';

  @override
  String rsvpWithdrawBody(String title) {
    return '“$title” will disappear from your events. The organiser sees a decline — the chat stays reachable through the calendar.';
  }

  @override
  String get rsvpWithdrawConfirm => 'Decline';

  @override
  String get evBadgeNeedLocation =>
      'A badge needs the event\'s location on the map — that is what proves who is on site.';

  @override
  String get evBadgeNoLocationSet =>
      'This event has no location on the map — so no badge can be issued or collected here.';

  @override
  String mvPortalOrganizer(String meetup) {
    return '✓ Organiser of $meetup\nListed in the Einundzwanzig portal as a leader of this meetup.';
  }

  @override
  String get evCancelAction => 'Cancel this event';

  @override
  String get evCancelTitle => 'Cancel this event?';

  @override
  String evCancelBody(String title) {
    return '“$title” disappears from every calendar. Nostr has no real delete — the event is marked cancelled and a removal request is sent as well. This cannot be undone; you would have to create it again.';
  }

  @override
  String get evCancelConfirm => 'Cancel it';

  @override
  String get evCancelDone => 'Event cancelled.';

  @override
  String get evCancelFailed =>
      'Cancellation not delivered — no relay accepted it.';
}
