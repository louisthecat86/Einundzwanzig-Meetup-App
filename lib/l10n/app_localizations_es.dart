// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Einundzwanzig Meetup';

  @override
  String get navHome => 'Inicio';

  @override
  String get navWallet => 'Insignias';

  @override
  String get navEvents => 'Eventos';

  @override
  String get navProfile => 'Perfil';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionConfirm => 'Confirmar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionContinue => 'Continuar';

  @override
  String get actionBack => 'Atrás';

  @override
  String get actionClose => 'Cerrar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionOk => 'OK';

  @override
  String get actionUnderstood => 'Entendido';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get trustScore => 'Puntuación de confianza';

  @override
  String get reputation => 'Reputación';

  @override
  String get reputationShareQr => 'Compartir QR';

  @override
  String get community => 'Comunidad';

  @override
  String get communityPortal => 'Portal';

  @override
  String get homeMeetup => 'Meetup principal';

  @override
  String get shoutout => 'Mención';

  @override
  String get joinCommunity => 'Unirse a la comunidad';

  @override
  String get identityVerified => 'Verificado';

  @override
  String get verifiedByAdmin => 'Verificado por admin';

  @override
  String get nostrVerified => 'Verificado en Nostr';

  @override
  String get profileNickname => 'Apodo';

  @override
  String get profileChooseHomeMeetup => 'Elige tu meetup principal';

  @override
  String get profileYourIdentity => 'Tu identidad';

  @override
  String get profileNostrKey => 'CLAVE NOSTR';

  @override
  String get profileKeyActive => 'Clave activa';

  @override
  String get requiredField => 'Campo obligatorio — complétalo';

  @override
  String get requiredHomeMeetup =>
      'Campo obligatorio — elige tu meetup principal';

  @override
  String fillRequired(String fields) {
    return 'Completa: $fields';
  }

  @override
  String get identityGenerateKey => 'Crear una clave nueva';

  @override
  String get identityConnectAmber => 'Conectar con Amber';

  @override
  String get identityImportNsec => 'Importar nsec existente';

  @override
  String get amberConnected =>
      '¡Conectado con Amber! Tu nsec permanece en Amber.';

  @override
  String get amberNotFound => 'Amber no encontrado';

  @override
  String get amberCancelled => 'Conexión cancelada en Amber.';

  @override
  String get walletTitle => 'Mis insignias';

  @override
  String badgesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count insignias',
      one: '1 insignia',
      zero: 'Sin insignias',
    );
    return '$_temp0';
  }

  @override
  String eventInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '1 día',
      zero: 'hoy',
    );
    return 'en $_temp0';
  }

  @override
  String get tileTrustScore => 'Trust Score';

  @override
  String get tileReputation => 'Reputación';

  @override
  String get tileReputationShare => 'Compartir QR';

  @override
  String get tileReputationCheck => 'Verificar';

  @override
  String get tileCommunity => 'Comunidad';

  @override
  String get tileCommunityPortal => 'Portal';

  @override
  String get tileEvents => 'Eventos';

  @override
  String get tileEventsCalendar => 'Calendario';

  @override
  String get tileShoutout => 'Shoutout';

  @override
  String get tileShoutoutSend => 'Enviar';

  @override
  String get tilePodcast => 'Podcast';

  @override
  String get tilePodcastListen => 'Escuchar';

  @override
  String get tileNostr => 'Nostr';

  @override
  String get tileNostrCommunity => 'Comunidad';

  @override
  String get tileOrganizer => 'Organizador';

  @override
  String get tileOrganizerPanel => 'Panel de admin';

  @override
  String get tileOrganizerNew => 'Nuevo vía Trust Score';

  @override
  String get tileWot => 'WoT';

  @override
  String get tileWotSubtitle => 'Web of Trust';

  @override
  String get homeMeetupLabel => 'MEETUP PRINCIPAL';

  @override
  String get homeMeetupChoose => 'Elige tu meetup';

  @override
  String get homeMeetupChooseSub => 'Selecciona tu meetup habitual';

  @override
  String homeMeetupBadges(int count) {
    return '$count insignias';
  }

  @override
  String get homeMeetupToday => '¡Hoy!';

  @override
  String get homeMeetupTomorrow => 'Mañana';

  @override
  String homeMeetupInDays(int days) {
    return 'en $days días';
  }

  @override
  String get homeMeetupNoDate => 'Sin fecha programada';

  @override
  String get homeMeetupNextEvent => 'Próximo meetup';

  @override
  String get homeMeetupNoneSoon => 'Sin fecha a la vista.\n¡Hora de cambiarlo!';

  @override
  String get homeMeetupSelectFirst => '¡Elige primero el\nmeetup principal!';

  @override
  String get btnEvents => 'EVENTOS';

  @override
  String get statusLive => 'EN VIVO';

  @override
  String get statusMeetupActive => 'Meetup activo';

  @override
  String get loading => 'Cargando...';

  @override
  String get organizerPromoted => '¡Ahora eres ORGANIZADOR!';

  @override
  String get resetTitle => '¿Restablecer la app?';

  @override
  String get resetBody => 'Se eliminarán todas las insignias y tu perfil.';

  @override
  String get resetCancel => 'Cancelar';

  @override
  String get resetConfirm => 'ELIMINAR';

  @override
  String get settingsSectionBackup => 'COPIA DE SEGURIDAD';

  @override
  String get settingsSectionLanguage => 'IDIOMA';

  @override
  String get settingsSectionNostr => 'RED NOSTR';

  @override
  String get settingsSectionControl => 'CONTROLES';

  @override
  String get settingsSectionAccount => 'CUENTA';

  @override
  String get settingsBackup => 'Crear copia de seguridad';

  @override
  String get settingsBackupSub => 'Protege tu cuenta';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageChoose => 'Elegir idioma';

  @override
  String get settingsRelays => 'Relays Nostr';

  @override
  String get settingsRelaysSub => 'Configurar relays';

  @override
  String get settingsHaptic => 'Vibración';

  @override
  String get settingsHapticOn => 'Activado';

  @override
  String get settingsHapticOff => 'Desactivado';

  @override
  String get settingsReset => 'Restablecer la app';

  @override
  String get settingsResetSub => 'Elimina perfil e insignias';

  @override
  String get introTagline => 'TU COMUNIDAD BITCOIN';

  @override
  String get introJoin => 'UNIRSE A LA COMUNIDAD';

  @override
  String get introLoadBackup => 'CARGAR COPIA';

  @override
  String get introSetIdentity => 'Primero configura tu identidad.';

  @override
  String get navWalletTab => 'Insignias';

  @override
  String get navProfileTab => 'Perfil';

  @override
  String get scanBadge => 'Escanear insignia';

  @override
  String get scanBadgeSub => 'Código QR del meetup';

  @override
  String get scanReputation => 'Verificar reputación';

  @override
  String get scanReputationSub => 'Verificar el Trust Score de otra persona';

  @override
  String get calendarTitle => 'EVENTOS MEETUP';

  @override
  String get calendarSearch => 'Buscar (p.ej. Múnich, Bitcoin...)';

  @override
  String get calendarNoEvents => 'No se encontraron eventos.';

  @override
  String get sectionDescription => 'DESCRIPCIÓN';

  @override
  String get sectionLocation => 'UBICACIÓN';

  @override
  String get sectionDates => 'FECHAS';

  @override
  String get sectionLinks => 'ENLACES';

  @override
  String get meetupRoute => 'Ruta';

  @override
  String get meetupNoDatesCal => 'Sin fechas en el calendario ahora.';

  @override
  String get errorOpenLink => 'No se pudo abrir el enlace';

  @override
  String get walletNoBadges => 'Aún no hay insignias';

  @override
  String get walletNoBadgesSub =>
      '¡Visita meetups y escanea el código QR para coleccionar insignias!';

  @override
  String get walletShareReputation => 'COMPARTIR REPUTACIÓN';

  @override
  String get walletShowQr => 'Mostrar código QR';

  @override
  String get walletShowQrSub => 'Para escanear in situ';

  @override
  String get walletExportJson => 'Exportar como JSON';

  @override
  String get walletExportJsonSub => 'Exportación firmada con prueba Schnorr';

  @override
  String get walletShareText => 'Compartir como texto';

  @override
  String get walletShareTextSub => 'Legible para todos (se copia en la web)';

  @override
  String get walletShareTitle => 'Compartir reputación';

  @override
  String get walletJsonCopied => 'Datos JSON copiados al portapapeles';

  @override
  String get walletReputationCopied => 'Reputación copiada al portapapeles';

  @override
  String get cancel => 'Cancelar';

  @override
  String get badgeDetailsTitle => 'Detalles de la insignia';

  @override
  String get badgeShare => 'Compartir insignia';

  @override
  String get badgeShareCaps => 'COMPARTIR INSIGNIA';

  @override
  String get badgeClose => 'CERRAR';

  @override
  String get badgeProofTitle => 'Prueba criptográfica';

  @override
  String get badgeProofOfAttendance => 'PROOF OF ATTENDANCE';

  @override
  String get badgeProofDesc =>
      'Esta insignia confirma criptográficamente que estuviste presente.';

  @override
  String get badgeMeetup => 'Meetup';

  @override
  String get badgeMeetupDate => 'Fecha del meetup';

  @override
  String get badgeMeetupId => 'ID del meetup';

  @override
  String get badgeOrganizerNpub => 'Organizador (npub)';

  @override
  String get badgeSignatureType => 'Tipo de firma';

  @override
  String get badgeTransmission => 'Transmisión';

  @override
  String get badgeTimestamp => 'Marca de tiempo';

  @override
  String get badgeScanTime => 'Hora del escaneo';

  @override
  String get badgeVerificationHash => 'HASH DE VERIFICACIÓN';

  @override
  String get badgeClaimBinding => 'Vinculación del claim';

  @override
  String get badgeBound => 'Vinculado ✓';

  @override
  String get badgeNotBound => 'No vinculado';

  @override
  String get badgeClaimedLater => 'Reclamado después';

  @override
  String get badgeNote => 'Nota';

  @override
  String get badgeNoSignature => 'Sin firma';

  @override
  String get badgeHashCopied => 'Hash copiado';

  @override
  String get badgeInfoCopied => 'Info de insignia copiada';

  @override
  String get badgeNfcTag => 'Etiqueta NFC';

  @override
  String get badgeRollingQr => 'Código QR rotativo';

  @override
  String get levelNew => 'NUEVO';

  @override
  String get levelStarter => 'INICIAL';

  @override
  String get levelActive => 'ACTIVO';

  @override
  String get levelEstablished => 'ESTABLECIDO';

  @override
  String get levelVeteran => 'VETERANO';

  @override
  String get reputationTitle => 'REPUTACIÓN';

  @override
  String get reputationNoBadges => 'AÚN SIN INSIGNIAS';

  @override
  String get reputationNoProofs => 'Aún sin pruebas criptográficas';

  @override
  String get reputationBuildHint1 =>
      'Visita un meetup y escanea una insignia para ';

  @override
  String get reputationBuildHint2 => 'construir tu reputación.';

  @override
  String get reputationScanQr => 'ESCANEAR CÓDIGO QR';

  @override
  String get reputationShareImage => 'COMPARTIR QR COMO IMAGEN';

  @override
  String get reputationUpdateRelays => 'ACTUALIZAR EN RELAYS';

  @override
  String get reputationPublishing => 'PUBLICANDO...';

  @override
  String get reputationBadges => 'Insignias';

  @override
  String get reputationMeetups => 'Meetups';

  @override
  String get reputationSigners => 'Firmantes';

  @override
  String get reputationBound => 'Vinculado';

  @override
  String get reputationSchnorrSigned => 'Firmado Schnorr';

  @override
  String get reputationSignedNoId => 'Firmado (sin identidad)';

  @override
  String get reputationNoIdentity =>
      'Sin identidad vinculada. Añade Telegram o Nostr en tu perfil.';

  @override
  String get reputationCheck => 'Verificar reputación';

  @override
  String get reputationVerified => 'Mi reputación de meetup verificada';

  @override
  String get reputationCodeFrom => 'Código de reputación de';

  @override
  String get portalDiscover => 'DESCUBRIR';

  @override
  String get portalQuickAccess => 'ACCESO RÁPIDO';

  @override
  String get portalPodcastMedia => 'PODCAST Y MEDIOS';

  @override
  String get portalSocialNetworks => 'REDES SOCIALES';

  @override
  String get portalAssociation => 'ASOCIACIÓN';

  @override
  String get portalProfile => 'Tu perfil e insignias';

  @override
  String get portalMeetupMap => 'Mapa de meetups';

  @override
  String get portalMeetupMapSub => 'Meetups cerca de ti';

  @override
  String get portalBeginnerPath => 'El Camino (principiantes)';

  @override
  String get portalShoutoutSend => 'Enviar shoutout';

  @override
  String get portalMembership => 'Hazte miembro';

  @override
  String get portalSoundboard => 'Soundboard';

  @override
  String get portalClipsSounds => 'Clips y sonidos';

  @override
  String get portalInterviews => 'Entrevistas';

  @override
  String get portalMediaArticles => 'Medios y artículos';

  @override
  String get portalMerch => 'Merch y productos Bitcoin';

  @override
  String get portalShop => 'Tienda';

  @override
  String get portalDonate => 'Donar';

  @override
  String get portalContact => 'Contacto';

  @override
  String get portalPrivacy => 'Privacidad';

  @override
  String get portalStatutes => 'Estatutos (PDF)';

  @override
  String get portalAboutAssoc => 'Sobre la asociación';

  @override
  String get portalOpen => 'Abrir portal';

  @override
  String get portalTagline => 'para bitcoiners alcistas.';

  @override
  String get portalInfotainment => 'Infotainment toximalista';

  @override
  String get portalPodcast => 'Podcast';

  @override
  String get portalProfile2 => 'Portal';

  @override
  String get profileTitle => 'TU PERFIL';

  @override
  String get profileEditTitle => 'EDITAR PERFIL';

  @override
  String get profileSave => 'GUARDAR PERFIL';

  @override
  String get profileIntro => 'Elige un apodo y tu meetup principal.';

  @override
  String get profileNicknameMin => 'Mínimo 2 caracteres';

  @override
  String get profileNicknameReq => 'Campo obligatorio — complétalo';

  @override
  String get profileNicknameAnon => 'Elige tu propio apodo (no \'Anon\')';

  @override
  String get profileHomeMeetup => 'Meetup principal';

  @override
  String get profileHomeMeetupDash => 'Meetup principal';

  @override
  String get profileChooseMeetup => 'Elige tu meetup principal';

  @override
  String get profileMeetupReq => 'Obligatorio — elige tu meetup principal';

  @override
  String get profileSearchCity => 'Buscar ciudad...';

  @override
  String get profileIdentity => 'TU IDENTIDAD';

  @override
  String get profileStrengthen => 'REFORZAR IDENTIDAD';

  @override
  String get profileStrengthenDesc =>
      'Vincula plataformas y demuestra tu humanidad para subir tu Trust Score.';

  @override
  String get profileLinkPlatforms => 'Vincular plataformas';

  @override
  String get profilePlatformsSub => 'Telegram, X, anuncios';

  @override
  String get profileProofHumanity => 'Proof of Humanity';

  @override
  String get profileZapCheck => '¿Has hecho un zap? Verifícalo';

  @override
  String get profileLightningActive => 'Prueba Lightning activa';

  @override
  String get profileVerified => 'VERIFICADO';

  @override
  String get profileNostrKeyShort => 'Nostr';

  @override
  String get profileNoKey => 'Aún sin clave Nostr';

  @override
  String get profileKeyActiveCaps => 'CLAVE ACTIVA';

  @override
  String get profileCreateKey => 'CREAR CLAVE NOSTR';

  @override
  String get profileCreateNewKey => 'CREAR NUEVA CLAVE';

  @override
  String get profileCreating => 'CREANDO...';

  @override
  String get profileNoNostrNeeded =>
      'No necesitas cuenta Nostr. La app crea una clave por ti — toma un segundo.';

  @override
  String get profileKeyDesc =>
      'Tu clave criptográfica — firma insignias y verifica tu reputación.';

  @override
  String get profileConnectAmber => 'CONECTAR CON AMBER';

  @override
  String get profileConnectExtension => 'CONECTAR CON EXTENSIÓN DEL NAVEGADOR';

  @override
  String get profileExtensionConnected =>
      '¡Extensión conectada! Tu clave permanece allí.';

  @override
  String get profileExtensionAborted => 'Rechazado en la extensión.';

  @override
  String get profileExtensionNotFound =>
      'No se encontró ninguna extensión Nostr en este navegador.';

  @override
  String get profileAmberDesc =>
      'Amber es un firmante aparte para Android que mantiene tu clave privada ';

  @override
  String get profileAmberConnected =>
      '¡Conectado con Amber! Tu nsec permanece en Amber.';

  @override
  String get profileAmberNotFound => 'Amber no encontrado';

  @override
  String get profileAmberInstall =>
      'Clave guardada de forma segura. Instala Amber (p.ej. vía F-Droid ';

  @override
  String get profileAmberRetry => 'o el Zapstore) e inténtalo de nuevo.';

  @override
  String get profileAmberAborted => 'Conexión cancelada en Amber.';

  @override
  String get profileSwitchSignerHeading => 'Conectar otro firmante';

  @override
  String get profileDisconnectSigner => 'DESCONECTAR FIRMANTE';

  @override
  String get profileDisconnectTitle => '¿Desconectar el firmante?';

  @override
  String get profileDisconnectBody =>
      'Se libera la conexión con el firmante. Si existe una clave local, la app la usará de nuevo — si no, no podrá firmar hasta que crees o importes una.\n\nLa autorización dentro del firmante permanece; puedes revocarla allí también.';

  @override
  String get profileDisconnectDone => 'Firmante desconectado.';

  @override
  String get profileSignerUnusable =>
      'Ahora no se puede firmar — vuelve a conectar el firmante.';

  @override
  String get profileSwitchSignerHint =>
      'Tu clave actual permanece guardada y en la copia de seguridad.';

  @override
  String get profileSwitchSignerTitle => '¿Cambiar de firmante?';

  @override
  String get profileSwitchSignerBody =>
      'El firmante trae su propia clave. Si NO contiene la misma que antes, tu identidad cambia — tus insignias seguirán perteneciendo a la clave anterior.\n\nTu clave actual no se elimina: permanece en el almacenamiento y en la copia de seguridad, así que puedes volver.';

  @override
  String get profileSwitchSignerContinue => 'CONTINUAR';

  @override
  String get profileIdentityChanged =>
      'Atención: el firmante usa una identidad distinta a la anterior. Tus insignias pertenecen a la clave previa.';

  @override
  String get profileConnectBunker => 'CONECTAR FIRMANTE REMOTO';

  @override
  String get bunkerTitle => 'Conectar un firmante remoto';

  @override
  String get bunkerIntro =>
      'Tu clave permanece en el firmante. La app solo solicita firmas — en cualquier dispositivo.';

  @override
  String get bunkerModeSigner => 'Conectar app de firmante';

  @override
  String get bunkerModeSignerDesc =>
      'La app muestra un código QR para que lo escanees en el firmante.';

  @override
  String get bunkerModePaste => 'Pegar una dirección bunker://';

  @override
  String get bunkerModePasteDesc =>
      'Cópiala de nsec.app, Amber o Alby. La vía más fiable en iPhone.';

  @override
  String get bunkerPasteLabel => 'Dirección bunker://';

  @override
  String get bunkerPasteHint => 'bunker://…?relay=wss://…';

  @override
  String get bunkerConnect => 'CONECTAR';

  @override
  String get bunkerBack => 'ATRÁS';

  @override
  String get bunkerWaiting => 'Esperando la aprobación en el firmante …';

  @override
  String get bunkerWaitingHint =>
      'Puede tardar hasta dos minutos. Mantén la app abierta.';

  @override
  String get bunkerScanHint =>
      'Escanéalo en el firmante — o pega allí la dirección.';

  @override
  String get bunkerCopy => 'Copiar dirección';

  @override
  String get bunkerCopied => 'Dirección copiada.';

  @override
  String get bunkerOpenSigner => 'Abrir firmante';

  @override
  String get bunkerNoSignerApp =>
      'No se encontró ninguna app de firmante. Usa «Pegar una dirección bunker://».';

  @override
  String get bunkerRecommendAndroid =>
      'Recomendado en Android: Amber — app de firma con búnker, en Zapstore y F-Droid. Como alternativa, un búnker propio (Bunker46, Signet).';

  @override
  String get bunkerRecommendIos =>
      'Recomendado en iOS: Clave — se despierta por push para firmar en segundo plano. Como alternativa, un búnker propio (Bunker46, Signet) o Amber en un dispositivo Android.';

  @override
  String get bunkerRecommendWeb =>
      'Como contraparte sirven Amber (Android), Clave (iOS) o un búnker propio como Bunker46 o Signet.';

  @override
  String get bunkerAuthOpen => 'Abrir aprobación en el navegador';

  @override
  String get bunkerAuthNeeded =>
      'El firmante requiere aprobación en el navegador.';

  @override
  String get bunkerAuthAction => 'ABRIR';

  @override
  String get bunkerTimeout =>
      'El firmante no respondió. ¿Está abierto y en línea?';

  @override
  String get bunkerConnected =>
      '¡Firmante remoto conectado! Tu clave permanece allí.';

  @override
  String get bunkerDisconnected => 'Firmante remoto desconectado.';

  @override
  String get bunkerCheck => 'COMPROBAR CONEXIÓN';

  @override
  String get bunkerAlive =>
      'El firmante responde — la sesión está activa. Si los permisos siguen vigentes solo se verá en la próxima firma.';

  @override
  String get bunkerDead =>
      'El firmante no responde. ¿Está abierto y en línea? Si no, vuelve a conectarlo.';

  @override
  String get profileImportNsec => 'IMPORTAR NSEC EXISTENTE';

  @override
  String get profileImportNsecShort => 'IMPORTAR NSEC';

  @override
  String get keyExportEncrypted => 'EXPORTAR CIFRADO (ncryptsec)';

  @override
  String get keyExportTitle => 'Exportar la clave cifrada';

  @override
  String get keyExportDesc =>
      'Crea un ncryptsec — tu clave, cifrada con una contraseña. Puedes guardarla sin riesgo en un gestor de contraseñas e importarla en Amber, Clave, nsec.app o tu propio búnker.';

  @override
  String get keyExportDuration =>
      'El cifrado es lento a propósito: medio segundo en el dispositivo, hasta medio minuto en el navegador.';

  @override
  String get keyExportAction => 'EXPORTAR';

  @override
  String get keyExportMismatch => 'Las contraseñas no coinciden.';

  @override
  String get keyExportNoKey => 'No hay clave local.';

  @override
  String get keyExportReadyTitle => 'Clave cifrada';

  @override
  String get keyExportReadyBody =>
      'Sin tu contraseña esto no vale nada — y con tu contraseña es tu clave completa. Trata ambas en consecuencia.';

  @override
  String get keyExportCopy => 'COPIAR';

  @override
  String get keyExportCopied => 'Clave cifrada copiada.';

  @override
  String get keyExportFromVault =>
      'Esta es tu clave cifrada con la contraseña que fijaste al crearla — no hace falta una nueva.';

  @override
  String get keyExportOtherPassword => 'Crear con otra contraseña';

  @override
  String get profileImport => 'IMPORTAR';

  @override
  String get profileEnterNsec =>
      'Introduce tu clave privada Nostr (empieza con nsec1...):';

  @override
  String get profileKeyImported => '¡Clave importada!';

  @override
  String get profileShowNsecQ => '¿MOSTRAR NSEC?';

  @override
  String get profileShowNsecWarn =>
      'Se mostrará tu clave privada. ¡Asegúrate de que nadie mire tu pantalla!';

  @override
  String get profileShow => 'MOSTRAR';

  @override
  String get profileCopy => 'COPIAR';

  @override
  String get profileSecureKey => '¡PROTEGE TU CLAVE!';

  @override
  String get profileSaveKeyDesc =>
      'Esta es tu clave privada. ¡Guárdala en un lugar seguro! ';

  @override
  String get profileKeyNotShownAgain => '¡Esta clave NO se mostrará de nuevo!';

  @override
  String get profileKeySecured => 'LA HE GUARDADO';

  @override
  String get profileNpubCopied => '¡npub copiado!';

  @override
  String get profileNsecCopied => '¡nsec copiado! Guárdalo de forma segura.';

  @override
  String get profileNsecNeverLeaves => 'Tu nsec nunca sale de tu dispositivo.';

  @override
  String get profileWhoHasKey => 'Quien tenga esta clave TIENE tu identidad.';

  @override
  String get profileBackupNsec =>
      'Importante: ¡haz copia de tu nsec! Si pierdes el dispositivo, pierdes la clave.';

  @override
  String get profileNewKeypairDesc =>
      'Se creará un nuevo par de claves. Tu clave privada (nsec) se guarda de forma segura en tu dispositivo.\n\n';

  @override
  String get profileEdit => 'Editar';

  @override
  String get profileEditLoseStatus => 'EDITAR (perder estado)';

  @override
  String get profileWarning => '¡Atención!';

  @override
  String get profileEditWarnDesc =>
      'Si editas, pierdes tu estado \'Verificado\' y deberás ser reaprobado.';

  @override
  String get dialogCancel => 'CANCELAR';

  @override
  String get dialogCancelMixed => 'Cancelar';

  @override
  String get dialogCreate => 'CREAR';

  @override
  String errorGeneric(String msg) {
    return 'Error: $msg';
  }

  @override
  String errorAmber(String msg) {
    return 'Error de Amber: $msg';
  }

  @override
  String profileFillIn(Object fields) {
    return 'Por favor completa: $fields';
  }

  @override
  String get backupEncryptTitle => 'Cifrar copia de seguridad';

  @override
  String get backupDecryptTitle => 'Descifrar copia de seguridad';

  @override
  String get backupExportDesc =>
      'Establece una contraseña para proteger tu clave privada (nsec) en la copia.\n\n⚠️ Si olvidas esta contraseña, ¡la copia se perderá IRRECUPERABLEMENTE!';

  @override
  String get backupImportDesc =>
      'Esta copia está cifrada. Introduce la contraseña.';

  @override
  String get backupPassword => 'Contraseña';

  @override
  String get backupPasswordConfirm => 'Confirmar contraseña';

  @override
  String get backupPasswordEmpty => 'La contraseña no puede estar vacía';

  @override
  String get backupPasswordMin => 'Mínimo 8 caracteres';

  @override
  String get backupPasswordMismatch => 'Las contraseñas no coinciden';

  @override
  String get backupEncryptSave => 'Cifrar y guardar';

  @override
  String get backupDecryptLoad => 'Descifrar y cargar';

  @override
  String get backupShareTitle => 'Copia de Einundzwanzig App (Cifrada)';

  @override
  String get backupShareText =>
      'Tu copia cifrada. Ten lista tu contraseña para restaurarla.';

  @override
  String backupError(String msg) {
    return 'Error de copia: $msg';
  }

  @override
  String get backupCorrupt =>
      'El archivo de copia está dañado (error de formato).';

  @override
  String get backupWrongPassword => '¡Contraseña incorrecta o archivo dañado!';

  @override
  String get backupNotValid =>
      'El archivo no es una copia válida o tiene formato incorrecto.';

  @override
  String get backupNotEinundzwanzig =>
      'El archivo no es una copia válida de Einundzwanzig.';

  @override
  String backupLoaded(Object items) {
    return '✅ ¡Copia cargada! $items restaurado.';
  }

  @override
  String backupImportFailed(String msg) {
    return 'Importación fallida: $msg';
  }

  @override
  String get qrScanTitle => 'VERIFICAR REPUTACIÓN';

  @override
  String get qrResultTitle => 'RESULTADO';

  @override
  String get qrScanHint => 'Escanea un código QR\nde reputación Einundzwanzig';

  @override
  String get qrLoadFromGallery => 'CARGAR QR DESDE GALERÍA';

  @override
  String get qrBack => 'ATRÁS';

  @override
  String get qrNoCodeInImage => 'No se encontró código QR en la imagen';

  @override
  String get qrNotEinundzwanzig =>
      'Código QR encontrado, pero no es formato Einundzwanzig';

  @override
  String get qrVerified => 'VERIFICADO';

  @override
  String get qrVerifiedV1 => 'VERIFICADO (v1)';

  @override
  String get qrVerifiedV2 => 'VERIFICADO (v2)';

  @override
  String get qrSigInvalid => 'FIRMA NO VÁLIDA';

  @override
  String get qrFormatUnknown => 'FORMATO DESCONOCIDO';

  @override
  String get qrReadError => 'ERROR DE LECTURA';

  @override
  String get qrV2Subtitle => 'Firma legacy válida — sin prueba de insignia';

  @override
  String get qrV1Subtitle => 'Formato antiguo — sin vinculación de identidad';

  @override
  String get qrCantRead => 'No se pudo leer el código QR.';

  @override
  String qrProcessError(String msg) {
    return 'Error al procesar: $msg';
  }

  @override
  String get qrSectionIdentity => 'IDENTIDAD';

  @override
  String get qrNoIdentity => 'SIN IDENTIDAD';

  @override
  String get qrNoVerifiableIdentity => 'Sin identidad verificable.';

  @override
  String get qrSectionLightning => 'LIGHTNING';

  @override
  String get qrSectionSocial => 'RED SOCIAL';

  @override
  String get qrSectionPlatforms => 'PLATAFORMAS VINCULADAS';

  @override
  String get qrSectionMeetups => 'MEETUPS VISITADOS';

  @override
  String get qrHumanVerified => 'Humano verificado';

  @override
  String get qrLightningActive => 'Prueba Lightning activa';

  @override
  String get qrNoLightning => 'No se encontró prueba Lightning';

  @override
  String get qrNoZap => 'Sin actividad de zaps';

  @override
  String get qrNip05Invalid => 'NIP-05 no válido';

  @override
  String get qrYouFollow => 'Tú sigues';

  @override
  String get qrFollowsYou => 'Te sigue';

  @override
  String get qrMutualFollow => 'Seguimiento mutuo';

  @override
  String get qrNoDirectFollow => 'Sin seguimiento directo';

  @override
  String get qrDirectConnection => 'Conexión directa';

  @override
  String get qrBidirectional => 'Conexión bidireccional directa';

  @override
  String get qrOneWay => 'Conexión unidireccional';

  @override
  String get qrViaContacts => 'A través de contactos comunes';

  @override
  String get qrStrongOverlap => 'Fuerte solapamiento de red';

  @override
  String get qrPartiallyConnected => 'Parcialmente conectado';

  @override
  String get qrNoOverlap => 'Sin solapamiento';

  @override
  String get qrEndorsement => 'Respaldo de admins conocidos';

  @override
  String get qrSigVerified => 'Firma verificada';

  @override
  String get qrAnalyzingNetwork => 'Analizando red...';

  @override
  String get qrCheckingLightning => 'Verificando Lightning...';

  @override
  String get qrCheckingNip05 => 'Verificando NIP-05...';

  @override
  String get qrStatBadges => 'Insignias';

  @override
  String get qrStatMeetups => 'Meetups';

  @override
  String get qrStatSigners => 'Firmantes';

  @override
  String get qrStatBound => 'Vinculado';

  @override
  String get qrStatDays => 'Días';

  @override
  String get qrLabelNickname => 'Apodo';

  @override
  String get qrLabelTwitter => 'Twitter/X';

  @override
  String get qrPlatformOther => 'Otra';

  @override
  String get qrLinked => 'Vinculado';

  @override
  String get qrSigVerifiedShort => 'Firma verificada';

  @override
  String get qrLinkedShort => 'Vinculado';

  @override
  String get nfcDisabled => 'NFC está desactivado';

  @override
  String get nfcDisabledHint => 'NFC está desactivado. Por favor actívalo.';

  @override
  String get nfcUnavailable => 'NFC no disponible';

  @override
  String get nfcOpenSettings => 'ABRIR AJUSTES';

  @override
  String get nfcEnableHint => 'Activa NFC en los ajustes de tu dispositivo ';

  @override
  String get nfcSettingsAndroid => 'Android: Ajustes → Conexiones → NFC';

  @override
  String get nfcSettingsIos => 'iOS: Ajustes → NFC';

  @override
  String get verifyScanBadge => 'ESCANEAR INSIGNIA';

  @override
  String get verifyScanNfc => 'ESCANEAR ETIQUETA NFC';

  @override
  String get verifyScanQr => 'ESCANEAR QR';

  @override
  String get verifyScanQrCaps => 'ESCANEAR CÓDIGO QR';

  @override
  String get verifyReadyToScan => 'Listo para escanear';

  @override
  String get verifyWaitingNfc => 'Esperando etiqueta NFC...';

  @override
  String get verifyCheckingNfc => 'Verificando NFC...';

  @override
  String get verifyScanInstruction =>
      'Escanea el código QR\ndel organizador del meetup.';

  @override
  String get verifyScanQrInstruction =>
      'Escanea el código QR\ndel organizador del meetup';

  @override
  String get verifyNoNfcDevice =>
      'Este dispositivo no tiene NFC. Usa el escáner QR.';

  @override
  String get verifyNoNfcLong => 'Este dispositivo no admite NFC.\n\n';

  @override
  String get verifyUseQrInstead => 'Usa el escáner de códigos QR en su lugar ';

  @override
  String get verifyToGetBadge => 'para obtener tu insignia.';

  @override
  String get verifyAskScan => 'Pide a un participante que escanee tu etiqueta.';

  @override
  String get verifyCantSelfBadge =>
      'No puedes darte una insignia a ti mismo.\n';

  @override
  String get verifyBadgeFound => 'INSIGNIA ENCONTRADA';

  @override
  String get verifyAlreadyCollected => 'YA RECOGIDA';

  @override
  String get verifyAddToWallet => 'AÑADIR A LA CARTERA';

  @override
  String get verifyVerifiedAdmin => 'Admin verificado';

  @override
  String get verifyUnknownMeetup => 'Meetup desconocido';

  @override
  String get verifyNoExpiry => 'Sin caducidad';

  @override
  String get writerReadyToWrite => 'Listo para escribir';

  @override
  String get writerNoNfcDevice =>
      'Este dispositivo no tiene NFC. Usa códigos QR rotativos.';

  @override
  String get writerUseRollingQr =>
      'Puedes usar códigos QR rotativos en su lugar ';

  @override
  String get writerForYourMeetup => 'para tu meetup.';

  @override
  String get writerSelectHomeFirst =>
      'Primero selecciona un meetup principal en tu perfil';

  @override
  String get writerYourHomeMeetup => 'TU MEETUP PRINCIPAL';

  @override
  String get writerCreateTag => 'CREAR ETIQUETA';

  @override
  String get writerCreateMeetupTag => 'CREAR ETIQUETA MEETUP';

  @override
  String get writerMeetupTag => 'ETIQUETA MEETUP';

  @override
  String get writerSuccess => '¡ÉXITO!';

  @override
  String writerValidHours(Object hours) {
    return '⏱️ Válido por ${hours}h\n\n';
  }

  @override
  String get writerHoldTag => 'Acerca la etiqueta al dispositivo...';

  @override
  String get writerHoldTagInstruction =>
      'Acerca una etiqueta NFC al dispositivo.\nLos participantes la escanean para recoger una insignia.';

  @override
  String get writerFormatting => 'Formateando etiqueta vacía...';

  @override
  String get writerFormatFailed => 'Error de formateo';

  @override
  String get writerLoadingSession => 'Cargando datos de sesión...';

  @override
  String get writerJumpToQr => 'Saltando al código QR...';

  @override
  String get writerNoNdef => 'Formato NDEF no posible';

  @override
  String get writerTagReadOnly => 'La etiqueta es de solo lectura';

  @override
  String get writerCanOverwrite => 'La etiqueta se puede sobrescribir después';

  @override
  String get writerTagLost => 'Etiqueta perdida durante la escritura';

  @override
  String get writerTagRemovedEarly =>
      'Etiqueta retirada demasiado pronto — mantenla firme 2–3 segundos';

  @override
  String get writerUseNtag215 => 'Usa un NTAG215 (504B) o mayor.';

  @override
  String get writerToWriteTag => 'para escribir la etiqueta.\n\n';

  @override
  String verifyMsgLocation(String name) {
    return 'Lugar: $name';
  }

  @override
  String verifyMsgBlock(Object height) {
    return 'Bloque: $height';
  }

  @override
  String verifyMsgSignedBy(String signer) {
    return 'Firmado por: $signer';
  }

  @override
  String get verifyMsgProof => 'Prueba: Schnorr (BIP-340)';

  @override
  String verifyMsgTagExpiry(String expiry) {
    return 'Caducidad de etiqueta: $expiry';
  }

  @override
  String verifyAlreadyToday(String name) {
    return 'Ya recogida\n\nHoy ya tienes una insignia de:\n$name';
  }

  @override
  String wotErrorShort(String msg) {
    return 'Error: $msg';
  }

  @override
  String writerTagTooSmall(Object data, Object max) {
    return '¡Etiqueta demasiado pequeña! Datos: ${data}B, etiqueta: ${max}B.\n';
  }

  @override
  String get writerTagWritten => '✅ ¡ETIQUETA MEETUP escrita!\n\n';

  @override
  String writerCompactSize(Object size) {
    return '📦 ${size}B (compacto)\n';
  }

  @override
  String get verifyErrNoNdef => '✗ Sin etiqueta NDEF';

  @override
  String get verifyErrTagEmpty => '✗ Etiqueta vacía';

  @override
  String get verifyErrPayloadEmpty => '✗ Payload vacío';

  @override
  String get verifyErrInvalidFormat => '✗ Formato no válido';

  @override
  String verifyErrInvalidTag(String msg) {
    return '✗ Etiqueta no válida: $msg';
  }

  @override
  String verifyErrReadError(String msg) {
    return '✗ Error de lectura: $msg';
  }

  @override
  String verifyErrNfcError(String msg) {
    return '✗ Error NFC: $msg';
  }

  @override
  String verifyErrQrExpired(String msg) {
    return '✗ ¡Código QR caducado!\n$msg\n\nEscanea directamente en la pantalla del organizador.';
  }

  @override
  String verifyErrPrefix(String msg) {
    return '✗ $msg';
  }

  @override
  String writerStartError(String msg) {
    return '❌ Error de inicio: $msg';
  }

  @override
  String writerFitsNtag215(Object size) {
    return '~${size}B — cabe en NTAG215 (492B)';
  }

  @override
  String get writerNoHomeMeetup => '⚠️ Sin meetup principal definido';

  @override
  String get writerHomeMeetupNotFound => '⚠️ Meetup principal no encontrado';

  @override
  String get writerNoActiveSession =>
      '❌ No se encontró sesión de meetup activa. Reinicia el meetup.';

  @override
  String get apMeetupSession => 'SESIÓN DE MEETUP';

  @override
  String get apSessionRunning => 'SESIÓN ACTIVA';

  @override
  String get apOpenActiveMeetup => 'ABRIR MEETUP ACTIVO';

  @override
  String get apStartMeetup => 'INICIAR MEETUP';

  @override
  String get apEndMeetupEarly => 'Finalizar meetup antes';

  @override
  String get apOrganizer => 'ORGANIZADOR';

  @override
  String get apHowItWorks => 'CÓMO FUNCIONA';

  @override
  String get apNewMeetupQ => '¿Iniciar nuevo meetup?';

  @override
  String get apSessionEndQ => '¿Finalizar sesión?';

  @override
  String get apCancel => 'Cancelar';

  @override
  String get apStart => 'Iniciar';

  @override
  String get apEnd => 'Finalizar';

  @override
  String get apSeedAdmin => 'Seed Admin';

  @override
  String get apViaTrustScore => 'Vía Trust Score';

  @override
  String get apNewMeetupBody =>
      'Esto crea una firma única (tiempo de bloque) para las próximas 4 horas. Durante ese periodo no se pueden crear nuevas sesiones.';

  @override
  String get apSessionEndBody =>
      'Esto bloquea el tiempo de bloque actual. Después puedes iniciar una nueva sesión.';

  @override
  String get apGeneratesProof =>
      'Genera una nueva prueba criptográfica para las próximas 4 horas.';

  @override
  String get humTitle => 'PROOF OF HUMANITY';

  @override
  String get humVerified => 'HUMANO VERIFICADO';

  @override
  String get humNotVerified => 'NO VERIFICADO';

  @override
  String get humVerifiedSub => 'Estás verificado como humano';

  @override
  String get humLightningActive => 'Prueba Lightning activa';

  @override
  String get humCheckNow => 'VERIFICAR AHORA';

  @override
  String get humCheckAgain => 'VERIFICAR DE NUEVO';

  @override
  String get humCheckAgainShort => 'Verificar de nuevo';

  @override
  String get humSearchingRelays => 'BUSCANDO EN RELAYS...';

  @override
  String get humHowTitle => '¿CÓMO FUNCIONA?';

  @override
  String get humIntro1 => 'Demuestra que eres humano — mostrando ';

  @override
  String get humIntro2 => 'que posees una cartera Lightning real y ';

  @override
  String get humIntro3 => 'ya has hecho un zap a alguien en Nostr.';

  @override
  String get humExplain1 => 'Los bots no tienen carteras Lightning. Un único ';

  @override
  String get humExplain2 => 'pago real demuestra que eres un humano con una ';

  @override
  String get humExplain3 => 'cartera real — sin revelar datos personales.';

  @override
  String get humStep1 => 'Haces un zap a cualquiera en Nostr';

  @override
  String get humStep2 => 'El zap crea un recibo en los relays';

  @override
  String get humStep3 => 'La app encuentra tu recibo';

  @override
  String get humStepInstruction =>
      'A cualquiera, cualquier cantidad de sats. Usa un cliente Nostr como Damus, Amethyst o Primal.';

  @override
  String get humCheckInstruction =>
      'Pulsa el botón de verificar y la app busca tu zap en los relays Nostr.';

  @override
  String get humZapReturn => 'Haz un zap a cualquiera y vuelve';

  @override
  String get humCryptoProof =>
      'Esta es una prueba criptográfica de que has hecho un pago Lightning real.';

  @override
  String get humProofInEvent1 => 'en la red Nostr. Esta prueba está en tu ';

  @override
  String get humProofPrivacy =>
      'La prueba se incluye en tu evento de reputación. No se guarda importe ni destinatario.';

  @override
  String get humReputationSaved => 'Evento de reputación guardado.';

  @override
  String humPaidOn(String date) {
    return 'Hiciste un pago Lightning el $date ';
  }

  @override
  String humLastCheck(String time) {
    return 'Última verificación: $time';
  }

  @override
  String get ppTitle => 'VINCULACIÓN DE PLATAFORMA';

  @override
  String get ppPlatform => 'PLATAFORMA';

  @override
  String get ppUsername => 'NOMBRE DE USUARIO';

  @override
  String get ppActiveLinks => 'VÍNCULOS ACTIVOS';

  @override
  String get ppLinkPlatform => 'VINCULAR PLATAFORMA';

  @override
  String get ppCreateLink => 'CREAR VÍNCULO';

  @override
  String get ppAnotherPlatform => 'OTRA PLATAFORMA';

  @override
  String get ppShareOnPlatform => 'COMPARTIR EN PLATAFORMA';

  @override
  String get ppUnlinkQ => '¿DESVINCULAR?';

  @override
  String get ppRevoke => 'REVOCAR';

  @override
  String get ppCancel => 'CANCELAR';

  @override
  String get ppYourUsername => 'Tu nombre de usuario';

  @override
  String get ppPlatformName => 'Nombre de la plataforma';

  @override
  String get ppIntro =>
      'Vincula tu cuenta con una plataforma. La prueba se incrusta automáticamente en tu QR de reputación.';

  @override
  String get ppLinkSaved =>
      '¡Vínculo guardado! Se incrusta automáticamente en tu QR de reputación.';

  @override
  String get ppMustUpdate =>
      'Debes actualizar tu evento de reputación después.';

  @override
  String get ppUnlinkBody1 => 'El vínculo de plataforma para \"';

  @override
  String get ppUnlinkBody2 => 'se eliminará.\n\n';

  @override
  String ppUnlinkBody(String username, String platform) {
    return 'El vínculo de plataforma para \"$username\" en $platform se eliminará.\n\nDebes actualizar tu evento de reputación después.';
  }

  @override
  String ppCreated(String date) {
    return 'Creado: $date';
  }

  @override
  String get ppRevokeTooltip => 'Revocar';

  @override
  String get rqTitle => 'CÓDIGO QR MEETUP';

  @override
  String get rqActive => 'ACTIVO';

  @override
  String get rqCodeRenewing => 'El código se renueva...';

  @override
  String get rqNextCodeIn => 'Próximo código en';

  @override
  String get rqEndSession => 'Finalizar sesión';

  @override
  String get rqEndSessionQ => '¿Finalizar sesión?';

  @override
  String get rqEnd => 'FINALIZAR';

  @override
  String get rqEndSessionBody =>
      'Una sesión finalizada bloquea este tiempo de bloque. Después puedes iniciar una nueva sesión.';

  @override
  String get rqNoActiveSession => 'SIN SESIÓN ACTIVA';

  @override
  String get rqNoSessionBody =>
      'No hay ninguna sesión de meetup activa.\nReinicia el meetup en el Panel de Admin.';

  @override
  String get rqBackToAdmin => 'VOLVER AL PANEL DE ADMIN';

  @override
  String get rsTitle => 'RELAYS NOSTR';

  @override
  String get rsDefaultRelays => 'RELAYS POR DEFECTO';

  @override
  String get rsCustomRelays => 'RELAYS PROPIOS';

  @override
  String get rsAddRelay => 'AÑADIR RELAY';

  @override
  String get rsAdd => 'AÑADIR';

  @override
  String get rsNoRelaysActive => '¡Sin relays activos!';

  @override
  String get rsNoCustomRelays => 'Sin relays propios configurados.';

  @override
  String get rsAllRelaysInfo =>
      'La app usa todos los relays activos a la vez para máxima cobertura.';

  @override
  String get rsRelaysIntro =>
      'Los relays distribuyen tu reputación en la red Nostr. ';

  @override
  String get rsRelayPlaceholder => 'wss://mi-relay.es';

  @override
  String get rdScanAdminTag => 'ESCANEAR ETIQUETA ADMIN';

  @override
  String get rdAnon => 'ANON';

  @override
  String get rdCollectBadge => 'RECOGER INSIGNIA';

  @override
  String get rdYourReputation => 'TU REPUTACIÓN';

  @override
  String get rdEditIdentity => 'Editar identidad';

  @override
  String get rdLinkingIdentity => 'Vinculando identidad...';

  @override
  String get rdNostrVerified => 'NOSTR VERIFIED';

  @override
  String get rdNoBadges => 'Aún sin insignias.\n¡Ve a un meetup!';

  @override
  String get rdSelfSovereign =>
      'Soberanía propia: Esta app funciona sin servidor. Tus insignias son solo tuyas y se guardan en este dispositivo.';

  @override
  String get rdVerifiedByAdmin => 'VERIFICADO POR ADMIN';

  @override
  String rqRemainingTime(String time) {
    return 'Tiempo restante: $time\n\n';
  }

  @override
  String rqSessionRemaining(String time) {
    return 'Sesión: $time';
  }

  @override
  String get rvTitle => 'VERIFICAR REPUTACIÓN';

  @override
  String get rvChecking => 'VERIFICANDO...';

  @override
  String get rvFullyVerified => 'TOTALMENTE VERIFICADO';

  @override
  String get rvPartiallyVerified => 'PARCIALMENTE VERIFICADO';

  @override
  String get rvSignatureOnly => 'SOLO FIRMA VERIFICADA';

  @override
  String get rvInvalid => 'NO VÁLIDO';

  @override
  String get rvConfirmedInEvent => 'Confirmado en el evento';

  @override
  String get rvPlatformProof => 'Prueba de plataforma';

  @override
  String get rvIntro1 =>
      'Pega la cadena de verificación o npub de una persona ';

  @override
  String get rvIntro2 =>
      'para verificar su reputación en todas las capas de prueba.';

  @override
  String get rvCheckingSignature => 'Verificando firma...';

  @override
  String get rvCheckingNostr => 'Analizando red Nostr...';

  @override
  String get rvCheckingLightning => 'Verificando actividad Lightning...';

  @override
  String get rvCheckingNip05 => 'Verificando NIP-05...';

  @override
  String get msSelectMeetup => 'SELECCIONAR MEETUP';

  @override
  String get msSearchMeetup => 'Buscar meetup...';

  @override
  String get mlTitle => 'MEETUPS';

  @override
  String get mlRetry => 'Reintentar';

  @override
  String get mlLoadError => 'Error al cargar';

  @override
  String get mlNoMeetupsFound => 'No se encontraron meetups.';

  @override
  String mlNoMeetupFor(String query) {
    return 'Sin meetup para \"$query\"';
  }

  @override
  String get cmRequestSent => 'SOLICITUD ENVIADA 🚀';

  @override
  String get cmDateTime => 'FECHA Y HORA';

  @override
  String get cmFoundBase => 'FUNDA UNA BASE.';

  @override
  String get cmLocation => 'UBICACIÓN / LUGAR';

  @override
  String get cmCityName => 'NOMBRE DE LA CIUDAD';

  @override
  String get cmTelegramGroup => 'GRUPO DE TELEGRAM (OPCIONAL)';

  @override
  String get cmNewMeetup => 'NUEVO MEETUP';

  @override
  String get cmDateExample => 'p. ej. 21 de mayo, 19:00';

  @override
  String get cmCityExample => 'p. ej. Fráncfort';

  @override
  String get cmLocationExample => 'p. ej. Room 77';

  @override
  String get evUpcomingEvents => 'PRÓXIMOS EVENTOS';

  @override
  String get evDatesEvents => 'FECHAS Y EVENTOS';

  @override
  String get evNoMeetupsFound => 'No se encontraron meetups';

  @override
  String get evSearchCityCountry => 'Buscar ciudad o país...';

  @override
  String get evIntro =>
      'La mayoría de los meetups de Einundzwanzig son periódicos. Toca un meetup para más info y fechas.';

  @override
  String get rvLabelPlatform => 'Plataforma';

  @override
  String get rvLabelUsername => 'Usuario';

  @override
  String get countryDE => 'Alemania';

  @override
  String get countryAT => 'Austria';

  @override
  String get countryCH => 'Suiza';

  @override
  String get countryES => 'España';

  @override
  String get countryNL => 'Países Bajos';

  @override
  String get countryIT => 'Italia';

  @override
  String get countryFR => 'Francia';

  @override
  String get siTitle => 'TU TRUST SCORE';

  @override
  String get siIntro =>
      'Mide tu fiabilidad. Se basa en pruebas criptográficas — nadie puede falsificarlo.';

  @override
  String get siIdentityLayer => 'CAPA DE IDENTIDAD';

  @override
  String siLinksActive(Object count) {
    return '$count vínculos activos';
  }

  @override
  String get siHumanitySub => 'Verificación con zap Lightning';

  @override
  String get siNip05Sub => 'Identidad Nostr (name@domain)';

  @override
  String get siPlatformActive => 'Plataforma activa';

  @override
  String get siPlatforms => 'Plataformas';

  @override
  String get siNoneLinked => 'Aún ninguna vinculada';

  @override
  String get siTrustLevel => 'NIVEL DE CONFIANZA';

  @override
  String get siLvlNew =>
      'Nivel inicial. Visita meetups para recoger insignias.';

  @override
  String get siLvlStarter =>
      'Tus primeras insignias muestran participación en la comunidad.';

  @override
  String get siLvlActive =>
      'Activo con regularidad. Diferentes meetups y organizadores refuerzan tu perfil.';

  @override
  String get siLvlEstablished =>
      'Miembro de confianza. Bien conectado y veterano.';

  @override
  String get siLvlVeteran =>
      'Nivel máximo. Reputación demostrada durante meses.';

  @override
  String get siCalculation => 'CÁLCULO';

  @override
  String get siFacBadges => 'Insignias de meetup';

  @override
  String get siFacBadgesDesc =>
      'Valor base por insignia. Los meetups concurridos valen más.';

  @override
  String get siFacDiversity => 'Diversidad';

  @override
  String get siFacDiversityDesc =>
      'Diferentes ciudades/organizadores = más puntos.';

  @override
  String get siFacSigners => 'Firmantes';

  @override
  String get siFacSignersDesc =>
      'Organizadores independientes = mayor confianza.';

  @override
  String get siFacMaturity => 'Madurez';

  @override
  String get siFacMaturityDesc =>
      'Antigüedad de la cuenta + regularidad = bonus.';

  @override
  String get siFacFrequency => 'Límite de frecuencia';

  @override
  String get siFacFrequencyDesc => 'Máx. 2 insignias/semana. Anti-farming.';

  @override
  String get siBecomeOrganizer => 'HACERTE ORGANIZADOR';

  @override
  String get siBecomeOrgDesc =>
      'Promoción automática al alcanzar suficiente Trust Score. Luego puedes crear tus propios códigos QR.';

  @override
  String siProgressLabel(Object name) {
    return 'PROGRESO ($name)';
  }

  @override
  String get siAlreadyOrganizer => '¡Ya eres organizador!';

  @override
  String get siIncreaseScore => 'AUMENTAR SCORE';

  @override
  String get siTip1 => 'Visita diferentes meetups con regularidad';

  @override
  String get siTip2 => 'Recoge insignias en meetups de otras ciudades';

  @override
  String get siTip3 => 'Insignias de diferentes organizadores';

  @override
  String get siTip4 => 'Verifica tu identidad con un zap Lightning';

  @override
  String get siTip5 => 'Configura NIP-05';

  @override
  String get siTip6 => 'Vincula plataformas';

  @override
  String siProgressRow(Object label, Object current, Object required) {
    return '$label: $current/$required';
  }

  @override
  String get badgeUnknown => 'desconocido';

  @override
  String get badgeBlockAtScan => '₿ Altura de bloque al escanear';

  @override
  String get mwStartMeetup => 'INICIAR MEETUP';

  @override
  String get mwStep1Nfc => 'PASO 1: ETIQUETA NFC';

  @override
  String get mwNfcIntro1 =>
      '¿Quieres colocar etiquetas NFC físicas (NTAG215) para este meetup? ';

  @override
  String get mwNfcIntro2 =>
      'La prueba criptográfica (tiempo de bloque y firma) queda fijada en ellas.';

  @override
  String get mwWriteNfcTag => 'ESCRIBIR ETIQUETA NFC';

  @override
  String get mwSkipQrOnly => 'OMITIR — SOLO USAR QR';

  @override
  String repAllBound(Object total) {
    return 'Las $total insignias vinculadas y verificadas';
  }

  @override
  String repBoundOf(Object total, Object bound) {
    return '$bound de $total insignias vinculadas a identidad';
  }

  @override
  String repBoundExtra(Object verified) {
    return ' ($verified verificadas criptográficamente)';
  }

  @override
  String repAllVerified(Object total) {
    return 'Las $total insignias verificadas criptográficamente (aún no vinculadas)';
  }

  @override
  String repVerifiedSchnorr(Object total, Object verified) {
    return '$verified de $total insignias con prueba Schnorr';
  }

  @override
  String repPlatformLinksActive(Object count) {
    return '$count vínculos de plataforma activos';
  }

  @override
  String homeCouldNotOpen(Object url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get apHowStep3 =>
      '3. Cada escaneo = una insignia para el participante\n';

  @override
  String get badgeSchnorrSig => 'Schnorr (Nostr v2) ✓';

  @override
  String msHomeMeetupSet(Object city) {
    return '✅ $city establecido como meetup principal';
  }

  @override
  String mvKnownOrganizer(Object name) {
    return '✓ Organizador conocido: $name';
  }

  @override
  String get mvUnknownSigner =>
      'Sin registro\nEsta clave no figura ni en el registro de organizadores ni entre los líderes de este meetup. La insignia es válida: la firma es correcta y está vinculada a ella.';

  @override
  String get mvAdminCheckFailed =>
      '! No verificable: el registro de organizadores no estaba accesible. La insignia es válida; la firma es correcta.';

  @override
  String get mvLegacyBadge =>
      '! Insignia antigua (v1) — firmante no verificable';

  @override
  String get mvBadgeBound => '🔗 Insignia vinculada';

  @override
  String get nwSelectHomeMeetup =>
      '❌ ¡Primero selecciona un meetup principal en tu perfil!';

  @override
  String qrUniqueRecipients(Object count) {
    return '$count destinatarios diferentes';
  }

  @override
  String get apHowStep1 => '1. Inicia un nuevo meetup (sesión).\n';

  @override
  String get apHowStep2 => '2. Luego muestra el código QR.\n';

  @override
  String get apHowStep4 =>
      '4. Las insignias construyen reputación → más reputación = nuevos organizadores';

  @override
  String get ppHowStep1 =>
      '1. Elige una plataforma e introduce tu nombre de usuario\n';

  @override
  String get ppHowStep2 => '2. La app crea una prueba criptográfica\n';

  @override
  String get ppHowStep3 =>
      '3. La prueba se incrusta automáticamente en tu QR de reputación\n';

  @override
  String get ppHowStep4 =>
      '4. Otros escanean tu QR y ven el vínculo verificado';

  @override
  String homeImageLoadError(Object msg) {
    return 'No se pudo cargar la imagen: $msg';
  }

  @override
  String qrSentCount(Object count) {
    return '$count enviados';
  }

  @override
  String repShareError(Object msg) {
    return 'Error al compartir: $msg';
  }

  @override
  String get rqNoHomeMeetup => '⚠️ Sin meetup principal definido';

  @override
  String get rqMeetupNotFound => '⚠️ Meetup no encontrado';

  @override
  String get rlWhatMeans => '¿Qué significa esto?';

  @override
  String get rlWhyImportant => 'Por qué es importante';

  @override
  String get rlWeakLabel => 'Perfil débil';

  @override
  String get rlWeakExpl =>
      'Solo una capa de prueba activa. Este usuario tiene pocas conexiones verificables. Para transacciones grandes: precaución.';

  @override
  String get rlWeakAdvice =>
      'Pide más pruebas (Lightning, NIP-05) o reúnete con la persona primero.';

  @override
  String get rlLimitedLabel => 'Limitado';

  @override
  String get rlLimitedExpl =>
      'Hay insignias de meetup, pero no otras pruebas independientes. El usuario podría ser real — pero falta confirmación de otras capas.';

  @override
  String get rlLimitedAdvice =>
      'OK para importes mínimos. Para importes mayores: espera a que haya más capas activas.';

  @override
  String get rlBuildingLabel => 'En desarrollo';

  @override
  String get rlBuildingExpl =>
      'Dos capas de prueba activas. El usuario está construyendo reputación pero aún sin amplitud completa.';

  @override
  String get rlBuildingAdvice => 'Adecuado para transacciones moderadas.';

  @override
  String get rlConnectedLabel => 'Bien conectado';

  @override
  String get rlConnectedExpl =>
      'Múltiples pruebas independientes: meetups, actividad Lightning y conexiones sociales. Difícil de falsificar.';

  @override
  String get rlConnectedAdvice => 'Fiable para la mayoría de transacciones.';

  @override
  String get rlSolidLabel => 'Sólido';

  @override
  String get rlSolidExpl =>
      'Amplia base de pruebas. Manipularlo sería laborioso y costoso.';

  @override
  String get rlSolidAdvice => 'Fiable para la mayoría de los casos.';

  @override
  String get rlDefaultExpl =>
      'Algunas pruebas presentes, pero hay margen para más.';

  @override
  String get rlDefaultAdvice => 'Usa tu propio criterio.';

  @override
  String get rlMeetupProofs => 'Pruebas de meetup';

  @override
  String get rlMeetupGood =>
      'Asistió a diferentes meetups con diferentes organizadores. Esto requiere presencia física en varios lugares.';

  @override
  String get rlMeetupMoreDiverse => 'Más diversidad sería más convincente.';

  @override
  String get rlMeetupNone =>
      'Sin insignias de meetup. Este usuario aún no ha asistido a un meetup de Einundzwanzig — o usa la app desde hace poco.';

  @override
  String get rlAllBound => 'Todas vinculadas criptográficamente';

  @override
  String get rlGoodSpread => 'Buena distribución regional';

  @override
  String get rlLowSpread => 'Poca distribución';

  @override
  String rlPhysGoodDiversity(Object count) {
    return 'Tiene insignias de meetup, pero solo de $count organizador(es). Más diversidad sería más convincente.';
  }

  @override
  String rlBadgeCount(Object count) {
    return '$count insignias';
  }

  @override
  String rlBoundOf(Object bound, Object total) {
    return '$bound de $total vinculadas';
  }

  @override
  String rlDiffMeetups(Object count) {
    return '$count meetups diferentes';
  }

  @override
  String rlOrganizers(Object count) {
    return '$count organizadores';
  }

  @override
  String get rlConfirmedByDiff => 'Confirmado por distintas personas';

  @override
  String get rlOneOrgOnly =>
      'Solo un organizador — poca confirmación independiente';

  @override
  String rlMemberSince(Object since) {
    return 'Miembro desde $since';
  }

  @override
  String rlDaysCount(Object count) {
    return '$count días';
  }

  @override
  String get rlLightningProof => 'Prueba Lightning';

  @override
  String get rlLnBoth =>
      'Ha realizado y recibido pagos Lightning reales. Los bots no tienen carteras Lightning — una fuerte señal de autenticidad.';

  @override
  String get rlLnPaid =>
      'Ha pagado vía Lightning al menos una vez. Prueba básica de que existe una cartera real.';

  @override
  String get rlLnActiveOnly =>
      'Hay actividad Lightning, pero Proof of Humanity aún no activo.';

  @override
  String get rlLnNone =>
      'Sin actividad Lightning. No significa que el usuario sea falso — quizás no usa Lightning vía Nostr. Pero falta una señal anti-bot importante.';

  @override
  String get rlHumanVerified => 'Humano verificado';

  @override
  String get rlRealLnPayment => 'Pago Lightning real demostrado';

  @override
  String rlZapsSent(Object count) {
    return '$count zaps enviados';
  }

  @override
  String rlToRecipients(Object count) {
    return 'A $count destinatarios diferentes';
  }

  @override
  String rlZapsReceived(Object count) {
    return '$count zaps recibidos';
  }

  @override
  String rlFromSenders(Object count) {
    return 'De $count remitentes diferentes';
  }

  @override
  String rlMonthsActive(Object count) {
    return '$count meses activo';
  }

  @override
  String get rlSocialTitle => 'Red social';

  @override
  String get rlSocMutualMany =>
      'Os conocéis en Nostr y compartís muchos contactos. Conexión fuerte.';

  @override
  String get rlSocMutual => 'Seguimiento mutuo — os conocéis en Nostr.';

  @override
  String get rlSocCommon =>
      'Muchos contactos en común — os movéis en la misma red.';

  @override
  String get rlSocOneSided => 'Conexión unilateral. Os conocéis de pasada.';

  @override
  String get rlSocOrgFollow =>
      'Organizadores conocidos de Einundzwanzig siguen a este usuario. Es una señal positiva.';

  @override
  String get rlSocDefault => 'Hay conexiones en la red Nostr con este usuario.';

  @override
  String get rlSocNone =>
      'No se encontró conexión en la red Nostr. Puede significar: nunca os habéis encontrado en Nostr, o el usuario es muy nuevo. Normal con desconocidos — señal de alerta con caras supuestamente conocidas.';

  @override
  String get rlMutualFollow => 'Seguimiento mutuo';

  @override
  String get rlYouFollow => 'Tú sigues';

  @override
  String get rlFollowsYou => 'Te sigue';

  @override
  String get rlNoFollow => 'Sin seguimiento';

  @override
  String get rlKnowOnNostr => 'Os conocéis en Nostr';

  @override
  String get rlNoDirectConn => 'Sin conexión directa';

  @override
  String rlCommonContacts(Object count) {
    return '$count contactos en común';
  }

  @override
  String get rlSameNetwork => 'Misma red';

  @override
  String get rlSomeOverlap => 'Algunas coincidencias';

  @override
  String get rlSeparateNetworks => 'Redes separadas';

  @override
  String rlOrgsFollow(Object count) {
    return '$count organizadores siguen';
  }

  @override
  String get rlEndorsement => 'Respaldo de admins conocidos';

  @override
  String get rlIdentityTitle => 'Prueba de identidad';

  @override
  String get rlIdNip05Plat =>
      'Tiene una dirección NIP-05 y plataformas vinculadas. Esto liga la identidad Nostr a un dominio — más difícil de falsificar que una cuenta anónima.';

  @override
  String get rlIdNip05Only =>
      'Tiene una dirección NIP-05. Esto liga la identidad Nostr a un dominio — más difícil de falsificar que una cuenta anónima.';

  @override
  String get rlIdPlatOnly =>
      'Cuentas de plataforma vinculadas. Más plataformas = más esfuerzo para falsificadores.';

  @override
  String get rlIdNone =>
      'Sin identificación de internet. Completamente anónimo. Bien para la privacidad, pero da menos indicios de confianza.';

  @override
  String get rlLinked => 'Vinculado';

  @override
  String get rlNoIdentification => 'Sin identificación';

  @override
  String get rlAnonymous => 'Anónimo';

  @override
  String get rlActive => '✓ activo';

  @override
  String get rlActiveShort => '✓ activo';

  @override
  String get rlMissingShort => '— falta';

  @override
  String qrReceivedCount(Object count) {
    return '$count recibidos';
  }

  @override
  String qrUniqueSenders(Object count) {
    return '$count remitentes diferentes';
  }

  @override
  String rlProofsOfFour(Object count) {
    return '$count / 4 pruebas';
  }

  @override
  String get navNearby => 'Cerca';

  @override
  String get nbTitle => 'MEETUPS CERCA';

  @override
  String get nbRequestingLocation => 'Obteniendo ubicación...';

  @override
  String get nbLoading => 'Cargando meetups...';

  @override
  String get nbLocationDenied => 'Acceso a ubicación denegado';

  @override
  String get nbLocationDeniedSub =>
      'Sin ubicación mostramos todos los meetups por fecha. Activa la ubicación en ajustes para ver distancias.';

  @override
  String get nbServiceDisabled =>
      'Los servicios de ubicación están desactivados';

  @override
  String get nbRetryLocation => 'Reintentar ubicación';

  @override
  String get nbContinueWithout => 'Continuar sin ubicación';

  @override
  String get nbNoMeetups => 'No hay meetups para este periodo';

  @override
  String get nbNoMeetupsSub => 'Prueba otro filtro u otra fecha.';

  @override
  String get nbFilterToday => 'Hoy';

  @override
  String get nbFilterWeek => 'Esta semana';

  @override
  String get nbFilterUpcoming => 'Próximos';

  @override
  String get nbFilterAll => 'Todos';

  @override
  String get nbPickDate => 'Elegir fecha';

  @override
  String nbKmAway(Object km) {
    return 'a $km km';
  }

  @override
  String get nbNoDate => 'Sin fecha anunciada';

  @override
  String nbListHeader(Object count) {
    return '$count meetups';
  }

  @override
  String get nbOpenInMaps => 'Abrir en mapas';

  @override
  String get nbYourLocation => 'Tu ubicación';

  @override
  String get nbToday => 'Hoy';

  @override
  String get nbTomorrow => 'Mañana';

  @override
  String get nbResetDate => 'Restablecer filtro';

  @override
  String get nbModeHere => 'Aquí y ahora';

  @override
  String get nbModePlanned => 'Planificado';

  @override
  String get nbRadius => 'Radio';

  @override
  String nbRadiusValue(Object km) {
    return '$km km';
  }

  @override
  String get nbSearchPlace => 'Buscar lugar (p. ej. Hamburgo)';

  @override
  String get nbSearchingPlace => 'Buscando lugares...';

  @override
  String get nbNoPlaceFound => 'Lugar no encontrado';

  @override
  String get nbCenterHere => 'Mi ubicación';

  @override
  String get nbChangePlace => 'Cambiar lugar';

  @override
  String get nbDateAny => 'Cualquier fecha';

  @override
  String get nbDateSingle => 'Fecha';

  @override
  String get nbDateRange => 'Periodo';

  @override
  String get nbPickDay => 'Elegir día';

  @override
  String get nbPickRange => 'Elegir periodo';

  @override
  String nbDateFromTo(Object from, Object to) {
    return '$from – $to';
  }

  @override
  String nbResultsHeader(Object count) {
    return '$count meetups en el radio';
  }

  @override
  String get nbNoneInRadius => 'Sin meetups en el radio';

  @override
  String get nbNoneInRadiusSub => 'Amplía el radio o cambia lugar/fecha.';

  @override
  String get nbApplySearch => 'Buscar';

  @override
  String nbMoreDates(Object count) {
    return '+$count fechas más';
  }

  @override
  String get nbDirections => 'Ruta';

  @override
  String get nbDetails => 'Detalles';

  @override
  String get settingsSectionProfile => 'Perfil';

  @override
  String get settingsProfile => 'Editar perfil';

  @override
  String get settingsProfileSub => 'Nombre, clave Nostr y meetup principal';

  @override
  String get apCreateEvent => 'Crear evento';

  @override
  String get apCreateEventSub => 'Crear en el portal';

  @override
  String get apCreateEventTitle => 'Crear evento en el portal';

  @override
  String get apCreateEventBody =>
      'Los eventos de meetup se gestionan de forma centralizada en el portal Einundzwanzig. La app abrirá ahora el portal en tu navegador — inicia sesión con tu clave Nostr y crea el evento. Después aparecerá aquí en el calendario automáticamente.';

  @override
  String get apOpenPortal => 'Abrir portal';

  @override
  String get apNoHomeMeetupSet =>
      'Selecciona primero tu meetup principal en el perfil, luego podrás crear eventos.';

  @override
  String get apPortalHint =>
      '¿Por qué no directamente en la app? El portal es la fuente central de todos los eventos y requiere tu inicio de sesión. La creación directa desde la app está prevista en cuanto el portal lo permita.';

  @override
  String get rcTitle => 'Perfil de reputación';

  @override
  String get rcShareImage => 'Compartir como imagen';

  @override
  String get rcSaving => 'Creando imagen...';

  @override
  String rcShareError(Object error) {
    return 'Error al compartir: $error';
  }

  @override
  String get rcShareText => 'Mi Trust Score y reputación de Einundzwanzig';

  @override
  String get rcLabelScore => 'Trust Score';

  @override
  String get rcLabelLevel => 'Nivel';

  @override
  String get rcLabelBadges => 'Badges';

  @override
  String get rcLabelMeetups => 'Meetups';

  @override
  String get rcLabelCities => 'Ciudades';

  @override
  String get rcLabelSigners => 'Avales';

  @override
  String get rcLabelAge => 'Días activo';

  @override
  String get rcMember => 'Miembro de Einundzwanzig';

  @override
  String get rcNoData =>
      'Aún no hay reputación. ¡Consigue badges en los meetups!';

  @override
  String get caOptInTitle => '¿Contribuir a la red de confianza?';

  @override
  String get caOptInBody =>
      'Puedes confirmar tu asistencia a este meetup en la red pública de confianza. Otros verán que tu npub estuvo en este meetup — y cómo estáis conectados por meetups en común.\n\nEs voluntario. Recibes tu badge igualmente.';

  @override
  String get caOptInPrivacy =>
      'Público y permanente en relays Nostr. Revela un patrón de movimiento y contactos. Piénsalo bien.';

  @override
  String get caOptInYes => 'Sí, contribuir';

  @override
  String get caOptInNo => 'No, mantener privado';

  @override
  String get caPublished => 'Asistencia confirmada en la red';

  @override
  String get cnTitle => 'Análisis de red';

  @override
  String get cnSubtitle =>
      '¿Cómo está conectada esta persona por meetups en común?';

  @override
  String get cnEnterNpub => 'Introduce el npub de la persona';

  @override
  String get cnScan => 'Escanear';

  @override
  String get cnAnalyze => 'Analizar';

  @override
  String get cnLoading => 'Cargando red...';

  @override
  String get cnSharedMeetups => 'Meetups en común';

  @override
  String get cnMutualContacts => 'Contactos en común';

  @override
  String get cnReach => 'Alcance de la persona';

  @override
  String get cnTotalMeetups => 'Meetups asistidos';

  @override
  String get cnTotalContacts => 'Personas conocidas';

  @override
  String get cnNoConnection => 'No se encontró conexión';

  @override
  String get cnNoConnectionSub =>
      'No habéis estado en meetups comunes ni tenéis contactos en común — o esta persona no participa en la red.';

  @override
  String get cnDirectMet => '¡Os habéis conocido directamente!';

  @override
  String get cnYou => 'Tú';

  @override
  String get cnTarget => 'Esta persona';

  @override
  String cnViaShared(Object count) {
    return 'por $count meetups en común';
  }

  @override
  String get cnTrustHint =>
      'Más meetups y contactos en común significan más confianza orgánica.';

  @override
  String get cnInvalidNpub => 'npub no válido';

  @override
  String get cnPrivacyNote =>
      'Solo muestra personas que participan en la red (opt-in).';

  @override
  String get tileTrustNetwork => 'Red de confianza';

  @override
  String get tileTrustNetworkSub => 'Comprobar conexiones';

  @override
  String get tnHubTitle => 'Red de confianza';

  @override
  String get tnHubIntro =>
      'Comprueba la confiabilidad de una persona en la red Einundzwanzig — mediante avales y meetups en común.';

  @override
  String get tnHubNetTitle => 'Análisis de red';

  @override
  String get tnHubNetSub => 'Meetups y contactos en común de una persona';

  @override
  String get orgBadgeCreated => 'Asistencia de organizador registrada';

  @override
  String get orgBadgeLabel => 'Organizador';

  @override
  String get orgBadgeSub => 'Organizaste este meetup';

  @override
  String get mnTitle => 'Mi red';

  @override
  String get mnIntro =>
      'Tu red de confianza de encuentros reales en meetups — y quién está conectado contigo más allá.';

  @override
  String get mnLoading => 'Construyendo red...';

  @override
  String get mnEmpty => 'Aún sin conexiones';

  @override
  String get mnEmptySub =>
      'Asiste a meetups y colecciona badges (con participación en la red) para construir tu red de confianza.';

  @override
  String get mnDegree1 => 'Conocidos directamente';

  @override
  String get mnDegree1Sub => 'Personas que conociste en vivo en meetups';

  @override
  String get mnDegree2 => 'Conectados por contactos';

  @override
  String get mnDegree2Sub => 'Personas que tus contactos conocieron en meetups';

  @override
  String get mnDegree3 => 'Red extendida';

  @override
  String get mnDegree3Sub => 'Un nivel más en la red';

  @override
  String mnSharedMeetups(Object count) {
    return '$count meetups en común';
  }

  @override
  String get mnOneSharedMeetup => '1 meetup en común';

  @override
  String mnViaContacts(Object count) {
    return 'por $count contactos';
  }

  @override
  String get mnViaOneContact => 'por 1 contacto';

  @override
  String get mnReachLabel => 'Alcance';

  @override
  String get mnDirectLabel => 'Directo';

  @override
  String get mnIndirectLabel => 'Indirecto';

  @override
  String get mnTrustHint =>
      'Los contactos indirectos a través de encuentros reales aumentan gradualmente tu confianza, incluso sin haber conocido a la persona.';

  @override
  String get mnPrivacyNote =>
      'Solo muestra personas que participan en la red (opt-in al escanear badge).';

  @override
  String get mnCheckPerson => 'Comprobar persona concreta';

  @override
  String get settingsHeaderTitle => 'Ajustes';

  @override
  String get settingsHeaderSub => 'Gestionar app y cuenta';

  @override
  String get settingsSecAccount => 'CUENTA';

  @override
  String get settingsSecData => 'DATOS Y SEGURIDAD';

  @override
  String get settingsSecNetwork => 'RED';

  @override
  String get settingsSecApp => 'APP';

  @override
  String get settingsSecDanger => 'ZONA DE PELIGRO';

  @override
  String get vpTitle => 'Verificar persona';

  @override
  String get vpIntro =>
      'Comprueba mediante encuentros reales en meetups si esta persona está conectada contigo.';

  @override
  String get vpEnterNpub => 'Introduce npub o escanea QR de reputación';

  @override
  String get vpScanQr => 'Escanear QR';

  @override
  String get vpCheck => 'Verificar';

  @override
  String get vpChecking => 'Comprobando conexión...';

  @override
  String get vpDirectTitle => '¡Conocido directamente!';

  @override
  String vpDirectSub(Object count) {
    return 'Habéis estado en $count meetups juntos.';
  }

  @override
  String get vpDirectSubOne => 'Habéis estado en un meetup juntos.';

  @override
  String vpIndirectTitle(Object count) {
    return 'Conectado a través de $count pasos';
  }

  @override
  String get vpIndirectSub =>
      'Esta persona está conectada contigo mediante encuentros reales en meetups.';

  @override
  String get vpNoneTitle => 'No se encontró conexión';

  @override
  String get vpNoneSub =>
      'Actualmente no hay conexión de meetup conocida contigo.';

  @override
  String get vpNotInNetwork => 'Esta persona no está (aún) en la red.';

  @override
  String get vpPathTitle => 'Ruta de conexión';

  @override
  String get vpYou => 'Tú';

  @override
  String get vpTarget => 'Esta persona';

  @override
  String get vpMetAt => 'meetup en común';

  @override
  String get vpInvalidNpub => 'npub no válido';

  @override
  String get vpTrustNote =>
      'Cuanto más cercana la conexión (menor grado), mayor la confianza por presencia física.';

  @override
  String get vpSelfTitle => 'Eres tú mismo';

  @override
  String get gpsRequired => 'Ubicación requerida';

  @override
  String get gpsRequiredOrg =>
      'Crear un meetup requiere tu ubicación. Define el lugar del meetup.';

  @override
  String get gpsRequiredScan =>
      'Recoger este badge requiere tu ubicación — como prueba de que estás presente.';

  @override
  String get gpsDenied => 'Acceso a ubicación denegado. Permítelo en ajustes.';

  @override
  String get gpsDisabled =>
      'Los servicios de ubicación están desactivados. Actívalos.';

  @override
  String get gpsError =>
      'Sin señal GPS. En interiores suele tardar más: acércate a una ventana o sal fuera e inténtalo de nuevo.';

  @override
  String get gpsRetry => 'Reintentar';

  @override
  String get gpsPickMeetup => '¿Qué meetup?';

  @override
  String get gpsPickMeetupSub => 'Hay varios meetups cerca. Elige el correcto.';

  @override
  String gpsDistanceKm(Object km) {
    return 'a $km km';
  }

  @override
  String get gpsNoMeetupNearby =>
      'No se encontró ningún meetup conocido cerca.';

  @override
  String get gpsTooFar => 'Demasiado lejos';

  @override
  String gpsTooFarSub(Object km, Object max) {
    return 'Estás a $km km del lugar del meetup. Los badges solo se recogen in situ (máx $max km).';
  }

  @override
  String get mapTitle => 'Mi mapa mundial de badges';

  @override
  String get mapButton => 'Ver en el mapa';

  @override
  String get mapStatMeetups => 'Meetups';

  @override
  String get mapStatCities => 'Ciudades';

  @override
  String get mapStatCountries => 'Países';

  @override
  String mapShareText(Object count) {
    return '¡Aquí he estado! 🌍 $count meetups en mi mapa mundial de badges Einundzwanzig.';
  }

  @override
  String get mapShareButton => 'Compartir como imagen';

  @override
  String get mapEmpty => 'Aún sin badges con ubicación';

  @override
  String get mapEmptySub =>
      'Colecciona badges en meetups — aparecerán aquí en tu mapa mundial.';

  @override
  String get gpsNoMeetupTitle => 'Ningún meetup cerca';

  @override
  String get gpsNoMeetupBody =>
      'No hay ningún meetup conocido en un radio de 10 km. Aún puedes iniciar una sesión — dale un título a tu meetup. Tu ubicación actual se establece automáticamente como lugar en el mapa.';

  @override
  String get gpsMeetupNameLabel => 'Título del meetup';

  @override
  String get gpsMeetupNameHint => 'p. ej. Encuentro Bitcoin';

  @override
  String get gpsStartAnyway => 'Iniciar sesión';

  @override
  String get gpsNameRequired => 'Introduce un nombre.';

  @override
  String get mnNodeDetailTitle => 'Conexión';

  @override
  String get mnDegreeDirect => 'Conexión directa';

  @override
  String get mnDegreeSecond => '2.º grado';

  @override
  String get mnDegreeThird => '3.er grado';

  @override
  String get mnSharedMeetupsList => 'Meetups en común';

  @override
  String get mnViaBridges => 'Conectado a través de';

  @override
  String get mnNoSharedDetail => 'Sin meetups en común directos';

  @override
  String get mnOpenInNostr => 'Abrir en Nostr';

  @override
  String get mnTapHint => 'Toca un nodo para más detalles';

  @override
  String get mnLegendDirect => 'Directo (1.º)';

  @override
  String get mnLegendSecond => '2.º';

  @override
  String get mnLegendThird => '3.er';

  @override
  String get resetBackupTitle => '¿Respaldar datos?';

  @override
  String get resetBackupBody =>
      'Restablecer borra TODOS los datos de forma irreversible — tus badges, tu clave y tu perfil. Sin copia de seguridad, los badges NO se pueden recuperar (tampoco vía Nostr). ¿Crear una copia primero?';

  @override
  String get resetBackupCreate => 'Crear copia';

  @override
  String get resetBackupSkip => 'Restablecer sin copia';

  @override
  String get resetBackupDone => 'Copia creada. ¿Restablecer ahora?';

  @override
  String get resetNowConfirm => 'Restablecer ahora';

  @override
  String get verifyBadgeSaved => 'Badge guardado ✓';

  @override
  String get tileConverter => 'Calculadora';

  @override
  String get tileConverterSub => 'Tipo & sats';

  @override
  String get convTitle => 'Conversor';

  @override
  String get convYouPay => 'Importe';

  @override
  String convRateInfo(Object price, Object cur) {
    return '1 BTC = $price $cur';
  }

  @override
  String convUpdated(Object time) {
    return 'Actualizado: $time';
  }

  @override
  String get convRefresh => 'Actualizar tasa';

  @override
  String get convOffline => 'No se pudo cargar la tasa. ¿Estás en línea?';

  @override
  String get convLoading => 'Cargando tasa …';

  @override
  String get convSwap => 'Intercambiar';

  @override
  String get convSelectCurrency => 'Seleccionar moneda';

  @override
  String get convUnitSats => 'Satoshi';

  @override
  String get convUnitBtc => 'Bitcoin';

  @override
  String get convSource => 'Tasa de mempool.space';

  @override
  String get tileNews => 'Noticias';

  @override
  String get tileNewsSub => 'Leer artículos de Einundzwanzig';

  @override
  String get newsTitle => 'Noticias';

  @override
  String get newsEmpty => 'No se encontraron artículos.';

  @override
  String get newsLoading => 'Cargando artículos …';

  @override
  String get newsRefresh => 'Actualizar';

  @override
  String get newsSource => 'Artículos vía Nostr (NIP-23)';

  @override
  String get newsOpenWebsite => 'Abrir en el sitio web';

  @override
  String get keyEduTitle => 'Tu clave para Nostr';

  @override
  String get keyEduWhatNostrH => '¿Qué es Nostr?';

  @override
  String get keyEduWhatNostrB =>
      'Nostr es una red abierta y descentralizada, similar a internet, pero para la identidad social. No pertenece a nadie. No hay empresa, ni cuenta, ni contraseña en el sentido clásico. En lugar de registrarte con un proveedor, posees una clave criptográfica que te identifica en toda la red.';

  @override
  String get keyEduPairH => 'Tu par de claves';

  @override
  String get keyEduPairB =>
      'Estás a punto de recibir dos claves emparejadas. Funcionan como un buzón: la clave pública es la dirección que puedes dar a cualquiera; la clave privada es la única que abre el buzón.';

  @override
  String get keyEduNpubH => 'npub – tu clave pública';

  @override
  String get keyEduNpubB =>
      'El npub (empieza con «npub1…») es tu identidad pública. Puedes compartirlo libremente: así te encuentran, ven tus publicaciones y te siguen. Es como tu nombre de usuario, salvo que realmente te pertenece y nadie puede quitártelo.';

  @override
  String get webKeyWarnH => 'Menos protegida en el navegador';

  @override
  String get webKeyWarnB =>
      'La app para iPhone y Android guarda tu clave en el almacenamiento seguro del dispositivo. En el navegador eso no es posible: allí se puede leer más fácilmente.';

  @override
  String get webKeyWarnAdvice =>
      'En el navegador, usa mejor una identidad de prueba propia. No introduzcas aquí la clave de la que depende tu identidad real en Nostr.';

  @override
  String get keyEduNsecH => 'nsec – tu clave privada';

  @override
  String get keyEduNsecB =>
      'El nsec (empieza con «nsec1…») es tu secreto. Quien lo posea ERES tú: puede publicar en tu nombre, apropiarse de tu identidad y abusar de tu reputación. NUNCA lo compartas, no lo escribas donde no estés seguro y nunca guardes una foto en la nube. No hay «olvidé mi contraseña»: si pierdes el nsec, la identidad se pierde para siempre.';

  @override
  String get keyEduIdentityH => 'Una identidad, muchos usos';

  @override
  String get keyEduIdentityB =>
      'Este par de claves no es solo para esta app. Es tu identidad en toda la red Nostr: puedes usar la misma identidad en muchas otras apps de Nostr, para redes sociales, blogs, chats, pagos Lightning y más. En esta app, además, está vinculada a tu reputación, tus badges de meetups y tu red de confianza. Por eso es tan importante protegerla: si pierdes la clave, no pierdes solo un acceso, sino todo lo que has construido.';

  @override
  String get keyEduProtectH => 'Cómo proteger tu clave';

  @override
  String get keyEduProtect1 =>
      'Haz una copia del nsec de inmediato (p. ej. en un gestor de contraseñas).';

  @override
  String get keyEduProtect2 => 'Comparte solo el npub, nunca el nsec.';

  @override
  String get keyEduProtect3 => 'Crea una copia cifrada (posible en esta app).';

  @override
  String get keyEduProtect4 =>
      'Para más seguridad: usa una app firmante como Amber.';

  @override
  String get keyEduUnderstood => 'Entendido, crear clave';

  @override
  String get keyEduCancel => 'Cancelar';

  @override
  String get keyEduIntro =>
      'Antes de empezar: estás a punto de recibir tu propio par de claves. Tómate un momento; vale la pena entender lo que recibes.';

  @override
  String get tilePortal => 'Mis meetups';

  @override
  String get tilePortalSub => 'Gestionar eventos en el portal';

  @override
  String get portalTitle => 'Mis meetups';

  @override
  String get portalNotConnected => 'Conectar con el portal';

  @override
  String get portalConnectInfo =>
      'Inicia sesión en el portal Einundzwanzig con tu clave Nostr para gestionar tus eventos desde la app.';

  @override
  String get portalConnect => 'Iniciar sesión';

  @override
  String get portalConnecting => 'Iniciando sesión …';

  @override
  String get portalLogout => 'Cerrar sesión';

  @override
  String get portalLoginFailed => 'Error de inicio de sesión';

  @override
  String get portalLoadingMeetups => 'Cargando tus meetups …';

  @override
  String get portalNoMeetups => 'Aún no gestionas meetups en el portal.';

  @override
  String get portalLeader => 'Organizador';

  @override
  String get portalNewEvent => 'Crear evento';

  @override
  String get portalEventTitle => 'Nuevo evento';

  @override
  String get portalFieldStart => 'Fecha y hora';

  @override
  String get portalPickDate => 'Elegir fecha';

  @override
  String get portalPickTime => 'Elegir hora';

  @override
  String get portalFieldLocation => 'Ubicación';

  @override
  String get portalFieldLocationHint => 'p. ej. café del meetup (opcional)';

  @override
  String get portalFieldDescription => 'Descripción';

  @override
  String get portalFieldDescriptionHint => '¿De qué trata? (opcional)';

  @override
  String get portalFieldLink => 'Enlace';

  @override
  String get portalFieldLinkHint => 'https://… (opcional)';

  @override
  String get portalSave => 'Guardar evento';

  @override
  String get portalSaving => 'Guardando …';

  @override
  String get portalCreatedOk => 'Evento creado ✓';

  @override
  String get portalNeedStart => 'Elige fecha y hora.';

  @override
  String get portalSource => 'Conectado a portal.einundzwanzig.space';

  @override
  String get evCalendarButton => 'Calendario de eventos';

  @override
  String get evCalendarButtonSub => 'Todos los eventos de un vistazo';

  @override
  String get calTitle => 'Calendario de eventos';

  @override
  String get calViewMonth => 'Mes';

  @override
  String get calViewYear => 'Año';

  @override
  String get calViewList => 'Lista';

  @override
  String get calToday => 'Hoy';

  @override
  String get calNoEvents => 'No hay eventos este día.';

  @override
  String get calNoEventsRange => 'No hay eventos en este periodo.';

  @override
  String get calLoading => 'Cargando eventos …';

  @override
  String get calAddEvent => 'Añadir evento';

  @override
  String get calAllDay => 'Todo el día';

  @override
  String get calSource => 'Eventos vía Nostr (NIP-52)';

  @override
  String get calNewEventTitle => 'Añadir evento';

  @override
  String get calFieldTitle => 'Título';

  @override
  String get calFieldTitleHint => 'p. ej. BTC Praga, Zitadelle …';

  @override
  String get calFieldLocation => 'Ubicación';

  @override
  String get calFieldLocationHint => 'p. ej. Praga, Chequia';

  @override
  String get calFieldDescription => 'Descripción';

  @override
  String get calFieldDescriptionHint => '¿De qué trata? (opcional)';

  @override
  String get calFieldAllDay => 'Evento de todo el día';

  @override
  String get calFieldStart => 'Inicio';

  @override
  String get calFieldEnd => 'Fin (opcional)';

  @override
  String get calPickDateTime => 'Elegir fecha y hora';

  @override
  String get calPickDate => 'Elegir fecha';

  @override
  String get calClearEnd => 'Quitar fin';

  @override
  String get calPublish => 'Publicar en Nostr';

  @override
  String get calPublishing => 'Publicando …';

  @override
  String get calPublishFail => 'Error al publicar. ¿En línea y conectado?';

  @override
  String get calNeedTitle => 'Introduce un título.';

  @override
  String get calNeedStart => 'Elige un inicio.';

  @override
  String get calPublishInfo =>
      'Este evento se publica públicamente en Nostr: todos con esta app lo verán en su calendario.';

  @override
  String get calMonth1 => 'Enero';

  @override
  String get calMonth2 => 'Febrero';

  @override
  String get calMonth3 => 'Marzo';

  @override
  String get calMonth4 => 'Abril';

  @override
  String get calMonth5 => 'Mayo';

  @override
  String get calMonth6 => 'Junio';

  @override
  String get calMonth7 => 'Julio';

  @override
  String get calMonth8 => 'Agosto';

  @override
  String get calMonth9 => 'Septiembre';

  @override
  String get calMonth10 => 'Octubre';

  @override
  String get calMonth11 => 'Noviembre';

  @override
  String get calMonth12 => 'Diciembre';

  @override
  String get calWd0 => 'Lun';

  @override
  String get calWd1 => 'Mar';

  @override
  String get calWd2 => 'Mié';

  @override
  String get calWd3 => 'Jue';

  @override
  String get calWd4 => 'Vie';

  @override
  String get calWd5 => 'Sáb';

  @override
  String get calWd6 => 'Dom';

  @override
  String get calTypeMeetup => 'Meetup';

  @override
  String get calTypeEvent => 'Evento';

  @override
  String get calLegendMeetup => 'Meetups';

  @override
  String get calLegendEvent => 'Eventos';

  @override
  String get portalManageEvents => 'Gestionar eventos';

  @override
  String get portalExistingEvents => 'Eventos existentes';

  @override
  String get portalLoadingEvents => 'Cargando eventos …';

  @override
  String get portalNoEvents => 'Aún no hay eventos para este meetup.';

  @override
  String get portalEditEvent => 'Editar evento';

  @override
  String get portalUpdatedOk => 'Evento actualizado ✓';

  @override
  String get portalUpdate => 'Guardar cambios';

  @override
  String get portalTapToEdit => 'Toca para editar';

  @override
  String get hubTitle => 'Eventos';

  @override
  String get hubMeetups => 'Meetups';

  @override
  String get hubMeetupsSub => 'Buscar y descubrir meetups';

  @override
  String get hubCalendar => 'Calendario de eventos';

  @override
  String get hubCalendarSub => 'Todos los eventos, por colores';

  @override
  String get hubExternal => 'Eventos externos';

  @override
  String get hubExternalSub => 'Conferencias y eventos de la comunidad';

  @override
  String get extTitle => 'Eventos externos';

  @override
  String get extIntro =>
      'Eventos de la comunidad (no meetups), p. ej. conferencias como BTC Praga o Zitadelle.';

  @override
  String get extLoading => 'Cargando eventos externos …';

  @override
  String get extNone => 'Aún no hay eventos externos.';

  @override
  String get extAdd => 'Añadir evento';

  @override
  String get calFilterAll => 'Todos';

  @override
  String get calFilterMeetups => 'Meetups';

  @override
  String get calFilterExternal => 'Externos';

  @override
  String get calFilterLocation => 'Buscar lugar/país …';

  @override
  String get calFilterActive => 'Filtro activo';

  @override
  String get calFilterClear => 'Borrar filtro';

  @override
  String get calFilterNoMatch => 'No hay eventos para este filtro.';

  @override
  String get calWorldwide => 'Mundial';

  @override
  String get calCommunityOnly => 'Solo comunidad';

  @override
  String get calWorldwideHint =>
      'Mundial muestra todos los eventos Nostr, también externos.';

  @override
  String get chTitle => 'Comunidad';

  @override
  String get chPortal => 'Portal';

  @override
  String get chPortalSub => 'Meetups · Eventos · Cursos · Mapa';

  @override
  String get chNews => 'Noticias';

  @override
  String get chNewsSub => 'Leer artículos';

  @override
  String get chNostr => 'Nostr';

  @override
  String get chNostrSub => 'Feed de la comunidad';

  @override
  String get chShoutout => 'Shoutout';

  @override
  String get chShoutoutSub => 'Enviar';

  @override
  String get chPodcast => 'Podcast';

  @override
  String get chPodcastSub => 'Escuchar';

  @override
  String get paTitle => 'Portal';

  @override
  String get paMeetups => 'Meetups';

  @override
  String get paMeetupsSub => 'Explorar meetups';

  @override
  String get paEvents => 'Eventos y confirmaciones';

  @override
  String get paEventsSub => 'Ver eventos y confirmar asistencia';

  @override
  String get paCourses => 'Cursos y docentes';

  @override
  String get paCoursesSub => 'La oferta educativa';

  @override
  String get paMap => 'Mapa';

  @override
  String get paMapSub => 'Meetups cercanos';

  @override
  String get paMine => 'Mis meetups';

  @override
  String get paMineSub => 'Gestionar eventos';

  @override
  String get paWeb => 'Web del portal';

  @override
  String get paWebSub => 'Abrir portal.einundzwanzig.space';

  @override
  String get rsvpLoading => 'Cargando eventos …';

  @override
  String get rsvpNone => 'No hay eventos próximos.';

  @override
  String get rsvpGoing => 'Confirmar';

  @override
  String get rsvpYouGo => 'Has confirmado ✓';

  @override
  String get rsvpCount => 'asistentes';

  @override
  String get rsvpNeedLogin => 'Inicia sesión en el portal primero.';

  @override
  String rsvpFailed(String msg) {
    return 'Respuesta no guardada: $msg';
  }

  @override
  String get crsLoading => 'Cargando cursos …';

  @override
  String get crsNone => 'No hay cursos.';

  @override
  String get crsCourses => 'Cursos';

  @override
  String get crsLecturers => 'Docentes';

  @override
  String get rsvpCancel => 'Cancelar';

  @override
  String get crsAbout => 'Sobre el curso';

  @override
  String get crsUpcoming => 'Próximas fechas';

  @override
  String get crsLecturer => 'Docente';

  @override
  String get lecAbout => 'Sobre el docente';

  @override
  String get lecLinks => 'Enlaces';

  @override
  String get crsOpenPortal => 'Abrir en el portal';

  @override
  String get rsvpImComing => 'Voy a ir';

  @override
  String get rsvpMaybe => 'Quizás';

  @override
  String get evOpenLink => 'Abrir enlace';

  @override
  String get evShare => 'Compartir';

  @override
  String get evToCalendar => 'Añadir al calendario';

  @override
  String get portalConnected => 'Portal conectado';

  @override
  String get portalLoginPrompt => 'Te conectamos al portal para confirmar.';

  @override
  String get portalTileSub => 'Para confirmaciones y tus meetups';

  @override
  String get ldTitle => 'Organizadores';

  @override
  String get ldManage => 'Gestionar organizadores';

  @override
  String get ldManageSub => 'Añadir co-organizadores';

  @override
  String get ldPickMeetup => 'Elegir meetup';

  @override
  String get ldCreator => 'Creador';

  @override
  String get ldAdd => 'Añadir organizador';

  @override
  String get ldAddHint => 'npub del nuevo organizador';

  @override
  String get ldAddDo => 'Añadir';

  @override
  String get ldRemove => 'Quitar';

  @override
  String get ldRemoveConfirm => '¿Quitar este organizador?';

  @override
  String get ldAdded => 'Organizador añadido';

  @override
  String get ldRemoved => 'Organizador quitado';

  @override
  String get ldFailed => 'Acción fallida';

  @override
  String get ldEmpty => 'Aún no hay otros organizadores.';

  @override
  String get ldLoading => 'Cargando organizadores …';

  @override
  String get ldNpubInvalid => 'Introduce un npub válido.';

  @override
  String get ldAddButton => 'Añadir admin';

  @override
  String get calLegendCourse => 'Cursos';

  @override
  String get calFilterCourses => 'Cursos';

  @override
  String get refreshRunning => 'Actualizando datos …';

  @override
  String get refreshDone => 'Todo actualizado';

  @override
  String get v4vSectionTitle => 'Apoyar';

  @override
  String get v4vSectionSubtitle =>
      'Value for Value – apoya el proyecto con sats';

  @override
  String get v4vTitle => 'Value for Value';

  @override
  String get v4vHeadline => 'Value for Value';

  @override
  String get v4vExplain1 =>
      'Esta app está hecha a mano para la comunidad: sin anuncios, sin rastreo, sin suscripción. Según el principio \"Value for Value\", devuelves lo que la app vale para ti.';

  @override
  String get v4vExplain2 =>
      'Tus sats van directamente al desarrollo del proyecto. Cada cantidad ayuda. ¡Gracias!';

  @override
  String get v4vAmountLabel => 'Cantidad';

  @override
  String get v4vDonateButton => 'Donar con Lightning';

  @override
  String get v4vRecipient => 'Destinatario';

  @override
  String get v4vErrInvalidAmount => 'Introduce una cantidad válida.';

  @override
  String get v4vErrBelowMin =>
      'La cantidad es demasiado baja para esta dirección.';

  @override
  String get v4vErrAboveMax =>
      'La cantidad es demasiado alta para esta dirección.';

  @override
  String get v4vErrUnreachable =>
      'Conexión fallida. Inténtalo de nuevo más tarde.';

  @override
  String get v4vErrGeneric => 'No se pudo crear la factura.';

  @override
  String get v4vNoWalletTitle => 'No se encontró ninguna wallet Lightning';

  @override
  String get v4vNoWalletBody =>
      'No se encontró ninguna app para pagar. Puedes copiar la factura y pegarla en tu wallet.';

  @override
  String get v4vCopyInvoice => 'Copiar factura';

  @override
  String get v4vCopied => 'Factura copiada';

  @override
  String get convPremiumTitle => 'Prima / Descuento';

  @override
  String get convPremiumHint =>
      'Para operaciones: prima (+) o descuento (−) en porcentaje sobre el precio.';

  @override
  String get convPremiumResult => 'Con prima/descuento';

  @override
  String get convPremiumBase => 'Precio base';

  @override
  String get convPremiumSats => 'Resultado en sats';

  @override
  String get portalTokenMismatch =>
      'Tu sesión del portal pertenece a otra clave Nostr y se ha desconectado. Vuelve a conectar el portal con la clave con la que eres líder.';

  @override
  String get settingsLogTitle => 'Registro de diagnóstico';

  @override
  String get settingsLogSub => 'Eventos para solución de problemas';

  @override
  String get rsvpNoNames =>
      'El portal no proporciona una lista de nombres para este evento.';

  @override
  String get rsvpAnon => 'Anónimo';

  @override
  String get settingsMempool => 'Servidor Mempool';

  @override
  String get settingsMempoolSub => 'Fuente de los datos de Bitcoin';

  @override
  String get mempoolTitle => 'Servidor Mempool';

  @override
  String get mempoolIntro =>
      'Desde aquí la app obtiene la altura de bloque, las comisiones, el precio y los datos de Lightning. El valor por defecto es mempool.space. Si navegas por Tor, elige la dirección onion: mempool.space suele rechazar peticiones de nodos de salida Tor.';

  @override
  String get mempoolClearnetTitle => 'Predeterminado (clearnet)';

  @override
  String get mempoolTorTitle => 'Tor / onion';

  @override
  String get mempoolTorSub => 'Dirección .onion oficial de mempool.space';

  @override
  String get mempoolTorHint =>
      'Solo funciona si Orbot está en modo VPN e incluye esta app. Sin Orbot no se puede acceder a una dirección .onion. Tor es más lento: los datos tardan algo más.';

  @override
  String get mempoolCustomTitle => 'Instancia propia';

  @override
  String get mempoolCustomSub =>
      'Tu propio nodo (Umbrel, Start9, RaspiBlitz …)';

  @override
  String get mempoolSave => 'Guardar';

  @override
  String get mempoolSaved => 'Guardado';

  @override
  String get mempoolInvalidUrl => 'Eso no parece una dirección válida.';

  @override
  String get mempoolTest => 'Probar conexión';

  @override
  String get mempoolTesting => 'Probando …';

  @override
  String get mempoolTestOk => 'Conexión establecida';

  @override
  String get mempoolTestFail => 'Sin conexión';

  @override
  String get mempoolTestBlocked =>
      'El servidor rechaza la petición. Con Tor: elige la dirección onion.';

  @override
  String get mempoolTestOnionFail =>
      'Onion no accesible. ¿Está Orbot en modo VPN e incluye esta app?';

  @override
  String get mempoolActive => 'Fuente activa';

  @override
  String get dashSource => 'Datos';

  @override
  String get dashPartial => 'Cargado solo parcialmente';

  @override
  String get dashOfflineTitle => 'Sin conexión';

  @override
  String get dashOfflineBody =>
      'No se pudieron cargar datos. Comprueba tu conexión a internet o elige otra fuente de datos.';

  @override
  String get dashBlockedTitle => 'El servidor rechaza las peticiones';

  @override
  String get dashBlockedBody =>
      'mempool.space está bloqueando esta dirección IP. Suele ocurrir con Tor, porque muchos usuarios comparten un nodo de salida. Solución: usa la dirección onion o tu propia instancia.';

  @override
  String get dashChangeServer => 'Cambiar fuente de datos';

  @override
  String get chDuellSub =>
      'Duelos de quiz por sats — juega contra la comunidad';

  @override
  String get sdMyTurn => '¡Te toca!';

  @override
  String get sdWaiting => 'Esperando al rival';

  @override
  String get sdLobby => 'partidas abiertas en la sala';

  @override
  String get sdShortTurn => 'te toca';

  @override
  String get sdShortLobby => 'en la sala';

  @override
  String get sdShortWait => 'esperando rival';

  @override
  String get chPlebrapSub => 'Rap Bitcoin — plebs together strong';

  @override
  String get prV4V => 'Sats para los artistas';

  @override
  String get prPickSong => 'Elige una canción';

  @override
  String get prLoadError => 'No se pudo cargar la canción';

  @override
  String get msFavoritesHint =>
      'Elige tus meetups — puedes seleccionar varios.';

  @override
  String get msSaveNone => 'Guardar sin favorito';

  @override
  String msSaveFavorites(int count) {
    return 'Guardar $count favoritos';
  }

  @override
  String calFavAdded(String city) {
    return '$city añadido a favoritos ★';
  }

  @override
  String calFavRemoved(String city) {
    return '$city eliminado de favoritos';
  }

  @override
  String get verifyBadgeDuplicate => 'Esta insignia ya está en tu cartera.';

  @override
  String get gpsOpenLocationSettings => 'Abrir ajustes de ubicación';

  @override
  String get gpsOpenAppSettings => 'Abrir ajustes de la app';

  @override
  String get walletSearchHint => 'Buscar meetup…';

  @override
  String get walletGroupMeetup => 'Por meetup';

  @override
  String get walletGroupYear => 'Por año';

  @override
  String get walletNoResults => 'No se encontraron insignias.';

  @override
  String get walletCleanupTitle => 'Limpiar duplicados';

  @override
  String get walletCleanupConfirm => 'Eliminar';

  @override
  String get walletCleanupNone => 'No se encontraron duplicados.';

  @override
  String get walletCleanupHint =>
      'Se conserva la insignia original de cada meetup. Las pruebas de asistencia ya publicadas en la red no cambian.';

  @override
  String walletCleanupBody(int count) {
    return 'Se encontraron $count insignia(s) duplicada(s):';
  }

  @override
  String walletCleanupDone(int count) {
    return '$count duplicados eliminados.';
  }

  @override
  String get orgGpsSoftTitle => '¿Continuar sin ubicación?';

  @override
  String get orgGpsSoftBody =>
      'Puedes crear el meetup e introducir el nombre tú mismo. Sin ubicación, los asistentes no pueden confirmarse por radio: sus insignias contarán como presencia no verificada.';

  @override
  String get orgGpsSoftContinue => 'Sin ubicación';

  @override
  String get badgeUnverified => 'Presencia no verificada';

  @override
  String get badgeUnverifiedInfo =>
      'No había ubicación disponible al recogerla. La insignia es válida, pero su prueba de presencia no está confirmada adicionalmente.';

  @override
  String get verifyClose => 'CERRAR';

  @override
  String get verifyOpenWallet => 'ABRIR CARTERA';

  @override
  String get writerValidity => 'Válido durante 4 horas';

  @override
  String get apPickPortalTitle => 'Seleccionar meetup';

  @override
  String get apPickPortalHint =>
      'Elige el meetup en el que estás ahora. Su ubicación sirve de referencia para los asistentes: una elección errónea falsea su confirmación.';

  @override
  String get apEnterManually => 'Introducir nombre';

  @override
  String get apCustomNeedsGpsTitle => 'Ubicación necesaria';

  @override
  String get apCustomNeedsGpsBody =>
      'Un meetup con nombre propio solo puede crearse si tu ubicación está disponible: es el único punto de referencia para verificar la asistencia.\n\nTres opciones: sal fuera e inténtalo de nuevo, elige un meetup del portal, o deja que otra persona presente con ubicación funcional cree la insignia.';

  @override
  String get apNoRefTitle => 'Sin punto de referencia';

  @override
  String get apNoRefContinue => 'Crear igualmente';

  @override
  String apNoRefBody(String city) {
    return 'No hay ubicación registrada para „$city“ en el portal y la tuya no está disponible. Por eso no se puede confirmar la asistencia: las insignias contarán menos.\n\nMejor: habilita la ubicación o deja que otra persona presente cree la insignia.';
  }

  @override
  String get apConfirmPickTitle => '¿Estás aquí?';

  @override
  String get apConfirmPickBody =>
      'Este nombre queda de forma permanente en la insignia de cada asistente y no puede cambiarse después. Si el lugar no coincide con los presentes, verán „demasiado lejos“ y no recibirán insignia.';

  @override
  String get apConfirmPickYes => 'Sí, estoy aquí';

  @override
  String get badgeOrganizerTitle => 'REGISTRO DE ORGANIZADOR';

  @override
  String get badgeOrganizerDesc =>
      'Creaste este meetup tú mismo. La insignia lo documenta, pero no está firmada y no cuenta para la reputación: nadie puede confirmarse a sí mismo. Obtienes una insignia que cuenta cuando otro organizador presente inicia su propia sesión y escaneas su código.';

  @override
  String get walletOrganizerSection => 'Creados por ti';

  @override
  String reputationOrganizerNote(int count) {
    return '$count meetup(s) organizados por ti: no cuentan para la puntuación, ya que nadie puede confirmarse a sí mismo.';
  }

  @override
  String get apCrossConfirmTitle => '¿Hay otro organizador?';

  @override
  String get apCrossConfirmBody =>
      'No obtienes una insignia que cuente por tu propio meetup: nadie puede confirmarse a sí mismo. Si ambos iniciáis una sesión y os escaneáis mutuamente, los dos tenéis una prueba real de la noche.';

  @override
  String get tileEventsToday => 'hoy en el calendario de eventos';

  @override
  String tileNewsUnread(int count) {
    return '$count nuevos desde tu visita';
  }

  @override
  String get tilesAvailable => 'Disponibles';

  @override
  String get tilesEditHint =>
      'Arrastra sobre otra tarjeta para mover · Chincheta para fijar o soltar';

  @override
  String get tilesEditDone => 'Listo';

  @override
  String tileReputationBadges(int count) {
    return '$count insignias contadas';
  }

  @override
  String get tileActListen => 'Para escuchar';

  @override
  String get tileActConvert => 'Convertir';

  @override
  String get tileActExchange => 'Intercambio';

  @override
  String get tileActSend => 'Enviar';

  @override
  String get tileActExplore => 'Explorar';

  @override
  String get tileActLookup => 'Consultar';

  @override
  String get tileActNetwork => 'Red';

  @override
  String get tileActEncounters => 'Encuentros';

  @override
  String get tileActManage => 'Gestionar';

  @override
  String get emptyFindMeetup => 'Buscar meetup';

  @override
  String get reputationScoreLabel => 'Puntuación de confianza';

  @override
  String get reputationUnsigned => 'Sin firmar';

  @override
  String get portalConnectForOrganizer =>
      'No conectado al portal: no se puede detectar tu estado de organizador.';

  @override
  String get npubCopied => 'npub copiado';

  @override
  String get idSetupTitle => 'Identidad';

  @override
  String get idSetupSubtitle => '¿Cómo quieres empezar?';

  @override
  String get idSetupNewCard => 'Soy nuevo';

  @override
  String get idSetupNewCardSub => 'Crear una identidad en la app';

  @override
  String get idSetupExistingCard => 'Ya uso Nostr';

  @override
  String get idSetupExistingCardSub => 'Conectar una identidad existente';

  @override
  String get idSetupResumeCard => 'Ya está en este dispositivo';

  @override
  String get idSetupResumeCardSub => 'Seguir con la identidad existente';

  @override
  String get idSetupResumeTitle => 'Continuar';

  @override
  String get idSetupResumeContinue => 'Continuar';

  @override
  String get idSetupResumeHasKey =>
      'Tu clave sigue en este dispositivo. Continuarás con ella — no se crea nada nuevo.';

  @override
  String get idSetupResumePasskey => 'Desbloquear con passkey';

  @override
  String get idSetupResumePasskeyHint =>
      'Tu clave está guardada cifrada en este dispositivo. Desbloquéala con tu passkey.';

  @override
  String get idSetupResumePassword => 'Usar contraseña en su lugar';

  @override
  String get idSetupResumePasswordHint =>
      'Tu clave está guardada cifrada en este dispositivo. Introduce la contraseña con la que la creaste.';

  @override
  String get idSetupResumeNeedPassword => 'Introduce la contraseña.';

  @override
  String get idSetupResumeWrongPassword =>
      'Esa contraseña no corresponde a esta clave.';

  @override
  String get idSetupNewTitle => 'Crear nueva';

  @override
  String get idSetupNewHint =>
      'Bastan nombre y contraseña. Tu clave se queda en el dispositivo.';

  @override
  String get idSetupNameLabel => 'Nombre';

  @override
  String get idSetupNameRequired => 'Elige un nombre.';

  @override
  String get idSetupPasswordLabel => 'Contraseña de tu clave';

  @override
  String get idSetupPasswordConfirmLabel => 'Confirmar contraseña';

  @override
  String get idSetupPasswordShort =>
      'La contraseña debe tener al menos 8 caracteres.';

  @override
  String get idSetupPasswordWarn =>
      'Esta contraseña cifra tu clave — es lo único que puede abrir tu copia de seguridad. No hay restablecimiento: sin la contraseña la copia no vale nada.';

  @override
  String get idSetupCreate => 'Empezar';

  @override
  String get idSetupPasskeyTitle => 'Passkey';

  @override
  String get idSetupPasskeyBody =>
      'Opcional: proteger también con passkey (Face ID / huella).';

  @override
  String get idSetupPasskeyAction => 'Proteger con passkey';

  @override
  String get idSetupPasskeyLater => 'Más tarde';

  @override
  String get idSetupPasskeyUnavailable =>
      'Las passkeys no están disponibles en este dispositivo. Puedes seguir con la contraseña.';

  @override
  String get idSetupExistingTitle => 'Conectar';

  @override
  String get idSetupPrimaryNip07 => 'Extensión del navegador';

  @override
  String get idSetupPrimaryNip07Sub => 'Confirmar en la extensión';

  @override
  String get idSetupPrimaryAmber => 'Amber';

  @override
  String get idSetupPrimaryAmberSub => 'Confirmar en Amber';

  @override
  String get idSetupPrimaryBunker => 'Conectar firmante';

  @override
  String get idSetupPrimaryBunkerSub => 'Bunker / Clave / Amber';

  @override
  String get idSetupOtherWay => 'Otra forma';

  @override
  String get idSetupImportHint =>
      'Pega un nsec o una clave cifrada (ncryptsec).';

  @override
  String get idSetupImportLabel => 'Clave';

  @override
  String get idSetupImportPasswordLabel => 'Contraseña (solo ncryptsec)';

  @override
  String get idSetupImportAction => 'Importar';

  @override
  String get idSetupImportEmpty => 'Pega una clave.';

  @override
  String get idSetupImportNeedPassword => 'ncryptsec necesita la contraseña.';

  @override
  String get idSetupNameTitle => 'Elige un nombre';

  @override
  String get idSetupNameOnlyHint => '¿Con qué nombre quieres aparecer?';

  @override
  String get idSetupContinue => 'Continuar';

  @override
  String get idSetupConnectFailed => 'La conexión falló.';

  @override
  String get idSetupBackupTitle => '¿Respaldar la clave?';

  @override
  String get idSetupBackupBody =>
      'Copia la clave cifrada en tu gestor de contraseñas. Sin la contraseña no sirve de nada.';

  @override
  String get idSetupBackupCopy => 'Copiar';

  @override
  String get idSetupBackupLater => 'Más tarde';

  @override
  String get idSetupMeetupTitle => 'Tu meetup';

  @override
  String get idSetupMeetupHint =>
      '¿Cuál es tu meetup? Puedes añadir más después.';

  @override
  String get idSetupMeetupPick => 'Elegir meetup';

  @override
  String get idSetupMeetupContinue => 'Continuar';

  @override
  String get idSetupMeetupLater => 'Más tarde';

  @override
  String get idSetupMeetupLoading => 'Cargando meetups…';

  @override
  String get idSetupMeetupLoadError =>
      'No se pudieron cargar los meetups. Puedes hacerlo después en el perfil.';

  @override
  String get rsInvalidUrl =>
      'Dirección no válida. Se espera wss://host.tld sin ruta.';

  @override
  String get rsRelayUnreachable =>
      'Relé inaccesible. Comprueba la dirección o tu conexión a internet.';

  @override
  String get rsRelayAlreadyAdded => 'Este relé ya está en la lista.';

  @override
  String get rsTesting => 'Comprobando la conexión …';

  @override
  String get rsRelayAdded => 'Relé añadido y accesible.';

  @override
  String get rsEnabledHint =>
      'Activado: no significa que el relé esté accesible en este momento.';

  @override
  String get newsWriteArticle => 'Escribir un artículo';

  @override
  String get newsLike => 'Me gusta';

  @override
  String get newsShare => 'Compartir';

  @override
  String get newsLikeFailed =>
      'No se pudo enviar la reacción. Ningún relé la aceptó.';

  @override
  String get newsZap => 'Zap';

  @override
  String get newsZapTitle => 'Enviar sats al autor';

  @override
  String get newsZapBody =>
      'Elige un importe. Después se enviará la factura a tu cartera Lightning.';

  @override
  String get newsZapNoAddress =>
      'El autor no tiene una dirección Lightning en su perfil.';

  @override
  String get newsZapUnsupportedAddress =>
      'La dirección Lightning del autor no es compatible (solo direcciones del tipo nombre@dominio).';

  @override
  String get newsZapAmountRange =>
      'El importe está fuera del rango que acepta el autor.';

  @override
  String get newsZapFailed =>
      'El zap ha fallado. Los detalles están en el registro de diagnóstico.';

  @override
  String get newsZapNoWallet => 'No se ha encontrado ninguna cartera Lightning';

  @override
  String get newsZapCopyInvoice => 'Copiar factura';

  @override
  String get evBadgeCreate => 'Crear insignia del evento';

  @override
  String get evBadgeCreateSub =>
      'Los asistentes pueden recoger una insignia en el lugar.';

  @override
  String get evBadgeNotAllowed =>
      'Solo los organizadores y líderes de meetups pueden repartir insignias. Aun así puedes crear el evento.';

  @override
  String get evBadgeChecking => 'Comprobando el permiso …';

  @override
  String get evBadgeImage => 'Imagen de la insignia';

  @override
  String get evBadgeImageHint => 'https://…/imagen.png';

  @override
  String get evBadgeLocation => 'Ubicación del evento';

  @override
  String get evBadgeLocationHint => 'Usar la ubicación actual';

  @override
  String get evBadgeLocationInfo =>
      'Las insignias solo se pueden emitir cerca de estas coordenadas y solo el día del evento.';

  @override
  String get evBadgeNoLocation =>
      'No se puede determinar la ubicación. Comprueba el servicio de localización y el permiso.';

  @override
  String get evBadgeIssuers => '¿Quién puede emitir insignias?';

  @override
  String get evBadgeIssuerHint => 'Pega npub1…';

  @override
  String get evBadgeIssuerInfo =>
      'Tú siempre puedes. Añade ayudantes que repartirán insignias en el lugar: no necesitan un rol de organizador propio.';

  @override
  String get evBadgeIssuerInvalid =>
      'Eso no es un npub válido. Se espera npub1… o una clave hex de 64 caracteres.';

  @override
  String get evBadgeIssuerDuplicate => 'Esa clave ya está en la lista.';

  @override
  String get evBadgeImageInfo =>
      'Elige una imagen de tu galería: se subirá para que todos puedan verla. También sirve una URL ya lista.';

  @override
  String get evBadgeUploading => 'Subiendo la imagen …';

  @override
  String evBadgeUploadFailed(String msg) {
    return 'Error al subir: $msg';
  }

  @override
  String get evBadgeLocationPick => 'Elegir en el mapa';

  @override
  String get locPickTitle => 'Ubicación del evento';

  @override
  String get locPickHint => 'Toca el mapa para marcar el lugar.';

  @override
  String get locPickHintDone => 'Toca de nuevo para mover el marcador.';

  @override
  String get locPickJumpToMe => 'Ir a mi ubicación';

  @override
  String get locPickConfirm => 'Usar esta ubicación';

  @override
  String get evBadgeAvailable => 'Aquí hay una insignia';

  @override
  String get evBadgeAvailableSub =>
      'Puedes recoger una insignia en el lugar: el día del evento y cerca del sitio.';

  @override
  String get evBadgeYouIssue => 'Puedes emitir insignias aquí';

  @override
  String get evBadgeYouIssueSub =>
      'El día del evento puedes iniciar una sesión en el lugar y repartir insignias.';

  @override
  String get evBadgeStartSession => 'Iniciar sesión de insignias';

  @override
  String get evSessionNoIdentity => 'No hay clave Nostr. Crea una primero.';

  @override
  String get evSessionNotIssuer => 'No figuras como emisor de este evento.';

  @override
  String get evSessionOutsideWindow =>
      'Las insignias solo están disponibles el día del evento.';

  @override
  String get evSessionNoEventLocation =>
      'Este evento no tiene ubicación guardada. Sin coordenadas no se puede comprobar que estés en el lugar.';

  @override
  String get evSessionNoLocation =>
      'No se puede determinar la ubicación. Comprueba el servicio de localización y el permiso.';

  @override
  String evSessionTooFar(String km) {
    return 'Estás a $km km del lugar. Las insignias solo se pueden emitir allí.';
  }

  @override
  String get evSessionFailed =>
      'No se pudo iniciar la sesión. Los detalles están en el registro de diagnóstico.';

  @override
  String mvEventIssuerOk(String event, String creator) {
    return 'Insignia del evento «$event»: emitida con permiso de $creator.';
  }

  @override
  String mvEventSignerNotListed(String event) {
    return 'Atención: el emisor no figura como ayudante de «$event».';
  }

  @override
  String mvEventCreatorNotAuthorized(String event) {
    return 'Atención: quien creó «$event» no es un organizador registrado.';
  }

  @override
  String mvEventHasNoBadge(String event) {
    return 'Atención: «$event» no debería repartir insignias.';
  }

  @override
  String get mvEventNotFound =>
      'No se encuentra el evento vinculado. Sin conexión no se puede comprobar el permiso.';

  @override
  String get evBadgeShowSession => 'Mostrar código QR';

  @override
  String get badgeShareTagline =>
      'Estuve allí en persona: verificado por Nostr.';

  @override
  String get shareCardCollectedBy => 'Recogida por';

  @override
  String get shareCardBlock => 'Bloque';

  @override
  String get shareCardScanned => 'Escaneada';

  @override
  String get shareCardChecksum => 'Suma de verificación';

  @override
  String get shareCardPromo =>
      '¿Has estado en un meetup de Einundzwanzig? Consigue tu insignia: prueba criptográfica de que estuviste allí.';

  @override
  String get backupPwShow => 'Mostrar contraseña';

  @override
  String get backupPwHide => 'Ocultar contraseña';

  @override
  String backupPwRuleLength(int min) {
    return 'Al menos $min caracteres: una frase larga es mejor que una contraseña corta y complicada.';
  }

  @override
  String get backupPwRuleMatch => 'Ambas entradas coinciden';

  @override
  String get idSetupOtherWaySub =>
      'nsec, ncryptsec, bunker o copia de seguridad';

  @override
  String get guideWelcomeTitle => '¡Bienvenido!';

  @override
  String get guideWelcomeBody =>
      '¿Quieres un recorrido rápido por la app? Te mostraremos las funciones más importantes.';

  @override
  String get guideStart => 'Iniciar tour';

  @override
  String get guideNoThanks => 'No, gracias';

  @override
  String get guideSkip => 'SALTAR';

  @override
  String get guideFinishTour => 'Terminar tour';

  @override
  String get guideBack => 'Atrás';

  @override
  String get guideOnboardWelcomeTitle => 'Configuremos tu perfil';

  @override
  String get guideOnboardWelcomeBody =>
      'Te guiaremos paso a paso por la configuración. Solo toma un minuto.';

  @override
  String get guideOnboardNicknameTitle => 'Elige un Apodo';

  @override
  String get guideOnboardNicknameBody =>
      'Así te verán otros miembros de la comunidad. ¡Elige algo memorable!';

  @override
  String get guideOnboardMeetupTitle => 'Selecciona tu Meetup Principal';

  @override
  String get guideOnboardMeetupBody =>
      'Tu meetup principal determina qué insignias puedes coleccionar y qué eventos ves primero.';

  @override
  String get guideOnboardNostrTitle => 'Tu Clave Nostr';

  @override
  String get guideOnboardNostrBody =>
      'Esta clave criptográfica firma tus insignias y verifica tu reputación. Se almacena solo en tu dispositivo.';

  @override
  String get guideOnboardSaveTitle => 'Guardar tu Perfil';

  @override
  String get guideOnboardSaveBody =>
      'Toca aquí cuando termines. Siempre puedes cambiar esta configuración después.';

  @override
  String get guideHomeMeetupTitle => 'Tu Meetup Principal';

  @override
  String get guideHomeMeetupBody =>
      'Tus meetups favoritos y el próximo evento – de un vistazo.';

  @override
  String get guideHomeTrustScoreTitle => 'Tu Trust Score';

  @override
  String get guideHomeTrustScoreBody =>
      'Aquí ves tu posición actual. Toca para ver el desglose por diversidad, actividad y calidad.';

  @override
  String get guideHomeReputationTitle => 'Reputación';

  @override
  String get guideHomeReputationBody =>
      'Verifica tu reputación o la puntuación de confianza de otra persona.';

  @override
  String get guideHomeWotTitle => 'Red de Confianza';

  @override
  String get guideHomeWotBody =>
      'Ve cómo estás conectado con otros en la Web of Trust.';

  @override
  String get guideHomeCommunityTitle => 'Portal de la Comunidad';

  @override
  String get guideHomeCommunityBody =>
      'Accede al podcast, shoutouts, merch y más.';

  @override
  String get guideHomeUmrechnerTitle => 'Conversor';

  @override
  String get guideHomeUmrechnerBody =>
      'Convierte rápidamente entre EUR y sats.';

  @override
  String get guideHomeBitcoinTitle => 'Precio de Bitcoin';

  @override
  String get guideHomeBitcoinBody =>
      'Precio actual, estadísticas de red y altura de bloque.';

  @override
  String get guideHomeBadgeWalletTitle => 'Cartera de Insignias';

  @override
  String get guideHomeBadgeWalletBody =>
      'Todas las insignias coleccionadas – firmadas criptográficamente y almacenadas solo en tu dispositivo.';

  @override
  String get guideHomeScanTitle => 'Reclamar una Insignia';

  @override
  String get guideHomeScanBody =>
      'Toca aquí para escanear el código QR del organizador en un meetup o acerca tu dispositivo vía NFC.';

  @override
  String get guideHomeSettingsTitle => 'Configuración';

  @override
  String get guideHomeSettingsBody =>
      'Configura copia de seguridad, idioma, relays y más. ¡No olvides crear una copia de seguridad!';

  @override
  String get guideSettingsBackupTitle => '¡Crea una Copia de Seguridad!';

  @override
  String get guideSettingsBackupBody =>
      'IMPORTANTE: Crea una copia para proteger tu cuenta. Sin ella, tus insignias y perfil se pierden si pierdes tu dispositivo.';

  @override
  String get guideSettingsLanguageTitle => 'Idioma';

  @override
  String get guideSettingsLanguageBody =>
      'Cambia entre alemán, inglés y español.';

  @override
  String get guideSettingsRelaysTitle => 'Relays Nostr';

  @override
  String get guideSettingsRelaysBody =>
      'Configura a qué relays Nostr se conecta tu app.';

  @override
  String get guideSettingsHapticTitle => 'Retroalimentación Háptica';

  @override
  String get guideSettingsHapticBody =>
      'Activa o desactiva la retroalimentación por vibración.';

  @override
  String get guideSettingsResetTitle => 'Restablecer App';

  @override
  String get guideSettingsResetBody =>
      'Esto elimina tu perfil y todas las insignias. ¡Asegúrate de tener una copia primero!';

  @override
  String get guideEventsSearchTitle => 'Buscar Eventos';

  @override
  String get guideEventsSearchBody =>
      'Busca meetups por ciudad o palabra clave.';

  @override
  String get guideEventsCalendarTitle => 'Calendario';

  @override
  String get guideEventsCalendarBody =>
      'Explora todos los próximos eventos de meetup.';

  @override
  String get guideEventsCardTitle => 'Detalles del Evento';

  @override
  String get guideEventsCardBody =>
      'Toca un evento para ver detalles, ubicación y enlaces.';

  @override
  String get guideEventsCreateTitle => 'Crear Evento';

  @override
  String get guideEventsCreateBody =>
      'Como organizador, puedes crear nuevos eventos de meetup aquí.';

  @override
  String get guidePortalShoutoutTitle => 'Enviar un Shoutout';

  @override
  String get guidePortalShoutoutBody =>
      'Envía un shoutout público a la comunidad.';

  @override
  String get guidePortalPodcastTitle => 'Podcast';

  @override
  String get guidePortalPodcastBody =>
      'Escucha el podcast Einundzwanzig directamente en la app.';

  @override
  String get guidePortalSoundboardTitle => 'Soundboard';

  @override
  String get guidePortalSoundboardBody =>
      'Reproduce clips y sonidos del podcast.';

  @override
  String get guidePortalMerchTitle => 'Tienda';

  @override
  String get guidePortalMerchBody => 'Explora merch y productos Bitcoin.';

  @override
  String get guidePortalMembershipTitle => 'Hazte Miembro';

  @override
  String get guidePortalMembershipBody =>
      'Apoya a la asociación haciéndote miembro.';

  @override
  String get guidePortalMapTitle => 'Mapa de Meetups';

  @override
  String get guidePortalMapBody => 'Encuentra meetups cerca de ti en el mapa.';

  @override
  String get guideWalletBadgesTitle => 'Tus Insignias';

  @override
  String get guideWalletBadgesBody =>
      'Todas las insignias coleccionadas – firmadas criptográficamente y almacenadas solo en tu dispositivo.';

  @override
  String get guideWalletShareQrTitle => 'Compartir Código QR';

  @override
  String get guideWalletShareQrBody =>
      'Muestra tu código QR de reputación para escanear en persona.';

  @override
  String get guideWalletExportTitle => 'Exportar como JSON';

  @override
  String get guideWalletExportBody =>
      'Exportación firmada con prueba Schnorr para verificación.';

  @override
  String get guideWalletShareTextTitle => 'Compartir como Texto';

  @override
  String get guideWalletShareTextBody =>
      'Comparte tu reputación como texto legible.';

  @override
  String get guideReputationScoreTitle => 'Tu Puntuación';

  @override
  String get guideReputationScoreBody =>
      'Tu trust score se calcula a partir de insignias, diversidad y actividad.';

  @override
  String get guideReputationLevelTitle => 'Tu Nivel';

  @override
  String get guideReputationLevelBody =>
      'De NUEVO a VETERANO – tu nivel crece con tu participación.';

  @override
  String get guideReputationStatsTitle => 'Estadísticas';

  @override
  String get guideReputationStatsBody =>
      'Insignias, meetups, firmantes y pruebas vinculadas de un vistazo.';

  @override
  String get guideReputationShareTitle => 'Compartir Reputación';

  @override
  String get guideReputationShareBody =>
      'Comparte tu reputación verificada vía código QR o texto.';

  @override
  String get guideReputationUpdateTitle => 'Actualizar en Relays';

  @override
  String get guideReputationUpdateBody =>
      'Publica tu última reputación en la red Nostr.';

  @override
  String guideStepOf(int current, int total) {
    return 'Paso $current de $total';
  }

  @override
  String get guideStepDone => 'Hecho';

  @override
  String get guideHintNickname => 'Toca el campo e introduce tu apodo.';

  @override
  String get guideHintOpenPicker =>
      'Toca el campo para abrir la selección de meetups.';

  @override
  String get guideHintSearchCity => 'Escribe las primeras letras de tu ciudad.';

  @override
  String get guideHintStarMeetup => 'Toca la estrella junto a tu meetup.';

  @override
  String get guideHintConfirmSelection =>
      'Confirma tu selección con el botón de abajo.';

  @override
  String get guideHintNostrKey =>
      'Crea una clave nueva o importa una existente.';

  @override
  String get guideHintSave => 'Toca GUARDAR PERFIL.';

  @override
  String get guideOnboardMeetupSearchTitle => 'Busca tu ciudad';

  @override
  String get guideOnboardMeetupSearchBody =>
      'Escribe el nombre de tu ciudad — la lista se filtra al instante.';

  @override
  String get guideOnboardMeetupPickTitle => 'Marca tu meetup';

  @override
  String get guideOnboardMeetupPickBody =>
      'Marca con la estrella tu meetup. Puedes elegir varios favoritos; el primero será tu meetup principal.';

  @override
  String get guideOnboardMeetupConfirmTitle => 'Confirma la selección';

  @override
  String get guideOnboardMeetupConfirmBody =>
      'El botón muestra cuántos favoritos has elegido. Tócalo para volver a tu perfil.';

  @override
  String get guideOnboardPlatformsTitle => 'Vincula tus plataformas';

  @override
  String get guideOnboardPlatformsBody =>
      'Conecta cuentas como Telegram, X o anuncios clasificados con tu identidad Nostr. Cada plataforma confirmada suma a tu puntuación de confianza y demuestra a los demás que detrás del perfil hay una persona real.';

  @override
  String get guideHintPlatforms =>
      'Opcional — puedes hacerlo más tarde desde tu perfil.';

  @override
  String get guideOnboardHumanityTitle => 'Prueba de humanidad';

  @override
  String get guideOnboardHumanityBody =>
      'Un único zap de Lightning demuestra que manejas una cartera real: la defensa más eficaz contra cuentas automatizadas en la red de confianza. Si ya has enviado un zap, verifícalo aquí.';

  @override
  String get guideHintHumanity =>
      'Opcional — la aplicación funciona igual sin esta prueba.';

  @override
  String get guideHomeEventsTitle => 'Eventos';

  @override
  String get guideHomeEventsBody =>
      'Este panel muestra si hay algo hoy. Se vuelve naranja en cuanto hay un evento programado para el día y te lleva al calendario con todos los encuentros próximos.';

  @override
  String get guideHomeShoutoutTitle => 'Shoutout';

  @override
  String get guideHomeShoutoutBody =>
      'Envía un mensaje a la comunidad: aparecerá en la página de shoutouts de Einundzwanzig. El panel la abre en tu navegador.';

  @override
  String get guideHomePodcastTitle => 'Pódcast';

  @override
  String get guideHomePodcastBody =>
      'El pódcast de Einundzwanzig, directamente desde la app. El panel abre la lista de episodios en tu navegador.';

  @override
  String get guideHomePortalConnectTitle => 'Conexión con el portal';

  @override
  String get guideHomePortalConnectBody =>
      'Verde significa conectado, rojo desconectado. La conexión con el portal de Einundzwanzig te muestra los eventos y cursos que se gestionan allí. Un toque en el panel cambia el estado.';

  @override
  String get guideHomeNewsTitle => 'Noticias';

  @override
  String get guideHomeNewsBody =>
      'El titular más reciente de la comunidad aparece en el propio panel. Tócalo para ver la lista completa.';

  @override
  String get guideHomeMyMeetupsTitle => 'Mis meetups';

  @override
  String get guideHomeMyMeetupsBody =>
      'Aquí gestionas las fechas de tus meetups en el portal: crear, modificar, cancelar. Solo tiene sentido si organizas tú.';

  @override
  String get guideHomeMoreTitle => 'Y aún hay más';

  @override
  String get guideHomeMoreBody =>
      'En tu panel te esperan cuatro paneles más: SatoshiDuell para partidas de preguntas por sats, PlebRap para música de la comunidad, el área del portal con meetups, eventos, cursos y mapa, y el panel de Nostr con las últimas notas de tu red. Cada uno se puede ocultar o mostrar de nuevo en los ajustes.';

  @override
  String get guideHomeNearbyTitle => 'Cerca de ti';

  @override
  String get guideHomeNearbyBody =>
      'Muestra los meetups de tu entorno: útil cuando viajas o buscas un segundo grupo en la región. La pantalla se abre sobre la app; volver te trae de nuevo aquí.';

  @override
  String get guideHomeEventsTabTitle => 'Zona de eventos';

  @override
  String get guideHomeEventsTabBody =>
      'El cuarto botón lleva al calendario completo: todos los eventos, filtrables por lugar y periodo, con recordatorios.';

  @override
  String get guideHomeSettingsBackupHint =>
      'Ve directo a la copia de seguridad: sin ella, tu clave desaparece si pierdes el móvil.';

  @override
  String get guideHintBackup =>
      'Crea ahora una copia cifrada: es cuestión de un minuto.';

  @override
  String get guideEvBadgeSwitchTitle => 'Insignia para tu evento';

  @override
  String get guideEvBadgeSwitchBody =>
      'Activa el interruptor si los asistentes deben poder recoger una insignia en el lugar. Sin él, es solo una cita.';

  @override
  String get guideEvBadgeSwitchHint =>
      'Si no necesitas insignia para este evento, simplemente toca Continuar.';

  @override
  String get guideEvBadgeImageTitle => 'La imagen';

  @override
  String get guideEvBadgeImageBody =>
      'Elige una imagen de tu galería: se subirá y aparecerá en cada insignia de este evento. Sin ella, el gráfico generado sostiene la tarjeta por sí solo.';

  @override
  String get guideEvBadgeLocationTitle => 'La ubicación importa';

  @override
  String get guideEvBadgeLocationBody =>
      'Coloca el marcador donde ocurre el evento, no donde estás ahora. Las insignias solo se pueden emitir cerca y solo el día del evento.';

  @override
  String get guideEvBadgeIssuersTitle => 'Tus ayudantes';

  @override
  String get guideEvBadgeIssuersBody =>
      'Añade los npubs de todos los que repartirán insignias en el lugar. No necesitan rol de organizador: el permiso vive en el evento y solo vale para él. Tú siempre puedes.';

  @override
  String get glTitle => 'Referencia';

  @override
  String get glSearchHint => 'Buscar: insignia, trust score, copia…';

  @override
  String get glNoResults =>
      'No se ha encontrado nada. Prueba otra palabra: la búsqueda también cubre el texto.';

  @override
  String get glCatStart => 'Primeros pasos';

  @override
  String get glCatBadges => 'Insignias';

  @override
  String get glCatReputation => 'Reputación';

  @override
  String get glWhatIsAppTitle => 'Qué hace esta app';

  @override
  String get glWhatIsAppBody =>
      'Demuestra que estuviste realmente en un meetup de Bitcoin. Con el tiempo, esas pruebas forman una reputación que te pertenece y que nadie puede retirarte: no está en un servidor de Einundzwanzig, sino firmada en la red Nostr.';

  @override
  String get glCollectTitle => 'Cómo conseguir una insignia';

  @override
  String get glCollectBody =>
      'Ve al meetup y pide al organizador que muestre el código QR. Toca el botón redondo de escaneo en la barra inferior, captura el código y listo. La insignia queda en tu cartera.';

  @override
  String get glHomeMeetupTitle => 'Tu meetup principal';

  @override
  String get glHomeMeetupBody =>
      'El meetup al que vas con regularidad. Determina qué eventos ves primero y qué escudo aparece en tus insignias. Puedes elegir varios favoritos; el primero cuenta como principal. Se puede cambiar en cualquier momento en el perfil.';

  @override
  String get glOfflineTitle => 'Qué funciona sin conexión';

  @override
  String get glOfflineBody =>
      'Escanear y recibir una insignia funciona sin conexión: tu dispositivo verifica la firma. Sin red solo faltan los datos externos: altura de bloque, precio, eventos y la comprobación de si el organizador está registrado.';

  @override
  String get glBadgeProofTitle => 'Qué demuestra una insignia';

  @override
  String get glBadgeProofBody =>
      'Que estuviste en un lugar concreto en un momento concreto, confirmado por alguien que también estaba allí. La confirmación es una firma Schnorr según BIP-340. Nadie puede falsificarla, ni los desarrolladores, porque haría falta la clave privada del organizador.';

  @override
  String get glRollingQrTitle => 'El QR rotativo';

  @override
  String get glRollingQrBody =>
      'El código del organizador cambia cada pocos segundos. Una foto no sirve minutos después: solo quien está realmente delante puede capturarlo. Por eso una insignia no se puede pasar por chat.';

  @override
  String get glOnSiteTitle => 'Por qué solo en el lugar';

  @override
  String get glOnSiteBody =>
      'Además del código rotativo, la app comprueba la distancia: quien esté demasiado lejos no recibe insignia. En los meetups los límites son amplios porque algunos grupos abarcan regiones enteras; en eventos especiales la ubicación es exacta y el límite estrecho.';

  @override
  String get glBadgeShareTitle => 'Compartir una insignia';

  @override
  String get glBadgeShareBody =>
      'Abre una insignia y toca compartir arriba a la derecha. La app genera una imagen con lugar, fecha, altura de bloque y suma de verificación. Quien la vea puede comprobar los datos; tu clave privada no está incluida.';

  @override
  String get glTrustScoreTitle => 'El trust score';

  @override
  String get glTrustScoreBody =>
      'Un número que resume la solidez de tu historial de asistencia. No decide solo la cantidad: meetups distintos, organizadores distintos y la regularidad pesan más que veinte visitas al mismo sitio en una semana.';

  @override
  String get glLevelsTitle => 'Los niveles';

  @override
  String get glLevelsBody =>
      'A medida que sube tu trust score alcanzas niveles superiores. A partir de cierto nivel puedes iniciar sesiones y emitir insignias: no es un premio sino una responsabilidad, porque tu firma queda bajo las insignias de otros.';

  @override
  String get glHumanityTitle => 'Prueba de humanidad';

  @override
  String get glHumanityBody =>
      'Un único zap de Lightning demuestra que detrás del perfil hay una persona con una cartera real. Es la defensa más eficaz contra cuentas creadas automáticamente en la red de confianza. Es opcional: la app funciona sin ello.';

  @override
  String get glPlatformsTitle => 'Pruebas de plataforma';

  @override
  String get glPlatformsBody =>
      'Puedes vincular cuentas como Telegram o X con tu identidad Nostr. Cada plataforma confirmada suma al trust score y muestra a los demás que detrás del perfil hay una persona con historia. También es opcional.';

  @override
  String get guideHomeGlossaryTitle => 'Para consultar';

  @override
  String get guideHomeGlossaryBody =>
      'Aquí está todo explicado con calma, ordenado por temas y con búsqueda. Cuando termine esta visita y quede alguna duda, la respuesta está aquí.';

  @override
  String get glCatNetwork => 'Red de confianza';

  @override
  String get glCatIdentity => 'Identidad y claves';

  @override
  String get glCatEvents => 'Eventos';

  @override
  String get glCatNostr => 'Nostr';

  @override
  String get glEncounterTitle => 'Encuentros';

  @override
  String get glEncounterBody =>
      'Quien escaneó con el mismo organizador el mismo día cuenta como encuentro. Así surge una red de personas que realmente compartieron una sala, no de gente que se sigue en internet.';

  @override
  String get glDegreesTitle => 'Grados';

  @override
  String get glDegreesBody =>
      'Primer grado significa que estuvisteis con el mismo organizador. Segundo grado: alguien a quien conociste ha conocido a esa persona. Si un meetup tuvo dos organizadores, el hecho de que se escaneen mutuamente une ambos grupos.';

  @override
  String get glVouchTitle => 'Avales';

  @override
  String get glVouchBody =>
      'Los organizadores pueden avalarse entre sí. Un aval es un voto público y firmado: tras publicarlo, toda la red ve por quién respondes. Se puede retirar en cualquier momento, pero la retirada es igual de visible.';

  @override
  String get glEventNetTitle => 'Red de eventos';

  @override
  String get glEventNetBody =>
      'Los eventos especiales se cuentan aparte. En un meetup de quince personas conoces a todos; en un evento de quinientas, no. Mezclarlos devaluaría lo que dice la red, por eso tienen su propia categoría.';

  @override
  String get glKeysTitle => 'nsec y npub';

  @override
  String get glKeysBody =>
      'Tu npub es tu dirección pública: compártela sin problema. El nsec es la clave privada y no pertenece a nadie más: quien la tenga, ES tú. No hay restablecimiento: si el nsec desaparece, la identidad y su reputación se pierden.';

  @override
  String get glPasswordTitle => 'Las dos contraseñas';

  @override
  String get glPasswordBody =>
      'Durante la configuración estableces una contraseña que envuelve tu clave en el dispositivo. Para la copia de seguridad defines otra que cifra el archivo. Pueden coincidir, pero son independientes, y ninguna se puede restablecer.';

  @override
  String get glSignerTitle => 'Aplicaciones de firma';

  @override
  String get glSignerBody =>
      'En lugar de guardar la clave en esta app, puedes confiarla a una aplicación de firma como Amber o conectarla mediante un bunker. Esta app pedirá allí cada firma y nunca verá la clave.';

  @override
  String get glBackupTitle => 'La copia de seguridad';

  @override
  String get glBackupBody =>
      'Guarda claves, insignias y ajustes en un archivo cifrado. Sin ella, si pierdes el dispositivo lo pierdes todo. Créala pronto, no cuando la necesites, y guarda el archivo separado de la contraseña.';

  @override
  String get glSpecialEventTitle => 'Eventos especiales';

  @override
  String get glSpecialEventBody =>
      'Además de los meetups habituales hay eventos únicos con insignias propias. Cuentan como insignia y para la variedad de emisores, pero no como meetup visitado.';

  @override
  String get glEventHelperTitle => 'Ayudantes en un evento';

  @override
  String get glEventHelperBody =>
      'Quien crea un evento con insignia puede añadir cualquier npub como emisor. Esos ayudantes no necesitan rol de organizador: el permiso está en el evento y solo vale para ese.';

  @override
  String get glEventWindowTitle => 'Ubicación y ventana temporal';

  @override
  String get glEventWindowBody =>
      'Una insignia de evento solo se puede emitir el día del evento y cerca de la ubicación registrada. Ambas condiciones impiden repartir insignias desde casa.';

  @override
  String get glRelaysTitle => 'Relés';

  @override
  String get glRelaysBody =>
      'Los relés son los servidores por los que viajan los mensajes de Nostr. La app escribe en varios a la vez. Puedes añadir los tuyos en los ajustes: se comprueba su accesibilidad antes de guardarlos.';

  @override
  String get glPublicTitle => 'Qué es público';

  @override
  String get glPublicBody =>
      'Las insignias, los registros de asistencia y los avales están abiertos en los relés: cualquiera puede leerlos y verificarlos. No son públicos tu clave privada, tu contraseña de copia ni tu ubicación exacta.';

  @override
  String get glZapTitle => 'Zaps';

  @override
  String get glZapBody =>
      'Un zap es un pequeño pago Lightning con un recibo de Nostr. En las noticias puedes enviar algo directamente a los autores. Un zap único también sirve como prueba de humanidad.';

  @override
  String get guideEvBasicsTitle => 'Título y lugar';

  @override
  String get guideEvBasicsBody =>
      'El título aparecerá luego en la lista de eventos y en la insignia, si emites alguna. El campo de ubicación es la dirección legible; las coordenadas para emitir insignias se fijan aparte en el mapa, más abajo.';

  @override
  String get guideEvWhenWhereTitle => 'Cuándo se celebra';

  @override
  String get guideEvWhenWhereBody =>
      'El inicio es obligatorio; el final es opcional. En un evento con insignia cuenta el día natural: las insignias solo se pueden emitir ese día, de medianoche a medianoche.';

  @override
  String get glCatApp => 'App y manejo';

  @override
  String get glTilesTitle => 'Personalizar el panel';

  @override
  String get glTilesBody =>
      'Mantén pulsado un panel para moverlo u ocultarlo. El trust score y el meetup principal siempre permanecen; el resto se puede desanclar. Los ocultos van al gestor y se pueden recuperar.';

  @override
  String get glLanguageTitle => 'Idioma';

  @override
  String get glLanguageBody =>
      'La app está en alemán, inglés y español. Sin elección propia sigue el idioma del sistema. Puedes cambiarlo en los ajustes; el cambio surte efecto de inmediato, sin reiniciar.';

  @override
  String get glLogTitle => 'Registro de diagnóstico';

  @override
  String get glLogBody =>
      'Un registro de lo que la app hace en segundo plano: qué relés respondieron, por qué se rechazó un escaneo. Cuando algo falla, es el primer sitio donde mirar. Se queda en el dispositivo y nunca se sube.';

  @override
  String get glResetTitle => 'Restablecer la app';

  @override
  String get glResetBody =>
      'Borra el perfil, las claves y todas las insignias del dispositivo, de forma definitiva. Sin copia de seguridad pierdes tu identidad, aunque las insignias sigan en los relés: sin la clave no podrás reclamarlas. Haz una copia antes.';

  @override
  String get glNicknameTitle => 'Tu nombre visible';

  @override
  String get glNicknameBody =>
      'El nombre con el que apareces en la red. Es libre, no tiene que ser el real y puedes cambiarlo cuando quieras: tu identidad depende de la clave, no del nombre.';

  @override
  String get glFindMeetupTitle => 'Encontrar meetups';

  @override
  String get glFindMeetupBody =>
      'La búsqueda de meetups lista todos los grupos registrados. «Cerca» muestra lo que hay alrededor de tu ubicación actual: útil al viajar o si buscas un segundo grupo en la región.';

  @override
  String get glBlockHeightTitle => 'La altura de bloque';

  @override
  String get glBlockHeightBody =>
      'Cada insignia lleva el número del bloque de Bitcoin vigente en el momento del escaneo. Funciona como una marca de tiempo que nadie puede mover después, al contrario que el reloj de un móvil.';

  @override
  String get glChecksumTitle => 'La suma de verificación';

  @override
  String get glChecksumBody =>
      'Una huella corta de todo el contenido de la insignia. Dos personas pueden comparar sus insignias del mismo meetup: si coinciden las sumas, ambos recibieron los mismos datos.';

  @override
  String get glWorldMapTitle => 'El mapa mundial de insignias';

  @override
  String get glWorldMapBody =>
      'Muestra tus insignias donde las conseguiste. Una lista de nombres se convierte en un mapa de tus visitas: útil para ver dónde quedan huecos.';

  @override
  String get glDuplicateTitle => 'Insignias duplicadas';

  @override
  String get glDuplicateBody =>
      'Hay exactamente una insignia por meetup y día. Escanear el mismo código dos veces no da una segunda: una insignia representa una visita, no un escaneo.';

  @override
  String get glVerifyPersonTitle => 'Verificar a alguien';

  @override
  String get glVerifyPersonBody =>
      'Pide a la otra persona su QR de reputación y escanéalo. La app comprueba si los datos coinciden con las insignias firmadas y muestra cómo estáis conectados. Útil antes de comerciar con desconocidos.';

  @override
  String get glRepCardTitle => 'La tarjeta de reputación';

  @override
  String get glRepCardBody =>
      'Un resumen compartible de tu reputación como imagen: nivel, número de meetups, periodo. No contiene ninguna clave privada y se puede publicar sin problema.';

  @override
  String get glPublishTitle => 'Publicar tu reputación';

  @override
  String get glPublishBody =>
      'Para que otros comprueben tu reputación, esta debe estar en los relés. La app la publica firmada; sin ese paso, tu interlocutor solo ve lo que le enseñas directamente.';

  @override
  String get glTrustPathTitle => 'Ruta de confianza';

  @override
  String get glTrustPathBody =>
      'Muestra la cadena que te conecta con otra persona: quién conoció a quién y dónde. Un número abstracto se convierte en algo comprensible: no solo que estáis conectados, sino a través de qué.';

  @override
  String get glDistrustTitle => 'Denuncias y suspensión';

  @override
  String get glDistrustBody =>
      'Los organizadores pueden denunciar abusos. Si se acumulan denuncias contra alguien, queda marcado como suspendido: sus insignias no desaparecen, pero llevan esa advertencia. La denuncia también va firmada.';

  @override
  String get glOrganizerTitle => 'Convertirse en organizador';

  @override
  String get glOrganizerBody =>
      'A partir de cierto trust score puedes iniciar sesiones. Además suelen hacer falta avales de organizadores existentes: el rol no se concede, crece desde la red.';

  @override
  String get glNcryptsecTitle => 'ncryptsec';

  @override
  String get glNcryptsecBody =>
      'Un nsec cifrado con una contraseña (NIP-49). La cadena empieza por ncryptsec1 y no sirve de nada sin la contraseña, así que se transporta con menos riesgo que un nsec desnudo.';

  @override
  String get glPasskeyTitle => 'Passkey';

  @override
  String get glPasskeyBody =>
      'Protección adicional por huella o reconocimiento facial. El passkey no sustituye a tu contraseña, se antepone a ella. Es opcional y solo en este dispositivo.';

  @override
  String get glNip05Title => 'Dirección NIP-05';

  @override
  String get glNip05Body =>
      'Una dirección legible del tipo nombre@dominio que apunta a tu clave, como una etiqueta para la red. Demuestra que alguien con acceso a ese dominio responde por ti, pero no sustituye a las demás comprobaciones.';

  @override
  String get glImportTitle => 'Traer tu propia clave';

  @override
  String get glImportBody =>
      'Si ya tienes una identidad Nostr puedes usarla aquí: como nsec, como ncryptsec o mediante un bunker. Tus contactos y tu perfil se mantienen; la app solo añade insignias y reputación.';

  @override
  String get glRestoreTitle => 'Restaurar una copia';

  @override
  String get glRestoreBody =>
      'Durante la configuración puedes cargar una copia en lugar de crear una clave nueva. Necesitas el archivo Y la contraseña con la que se cifró: uno solo no basta.';

  @override
  String get glCalendarSourcesTitle => 'De dónde vienen los eventos';

  @override
  String get glCalendarSourcesBody =>
      'El calendario reúne dos fuentes: eventos del portal de Einundzwanzig y otros introducidos vía Nostr. El color los distingue: meetups del portal en naranja, eventos Nostr en turquesa.';

  @override
  String get glPortalTitle => 'La conexión con el portal';

  @override
  String get glPortalBody =>
      'Puedes iniciar sesión en el portal de Einundzwanzig con tu clave Nostr. Verás los eventos y cursos que allí se gestionan y, como líder, podrás crear los tuyos. Sin conexión, todo lo demás sigue funcionando.';

  @override
  String get glCreateEventTitle => 'Crear un evento';

  @override
  String get glCreateEventBody =>
      'Cualquiera puede añadir un evento: se publica firmado en Nostr y aparece en el calendario de todos. Sin embargo, solo organizadores y líderes pueden asociarle una insignia.';

  @override
  String get glNostrBasicsTitle => 'Qué es Nostr';

  @override
  String get glNostrBasicsBody =>
      'Un protocolo abierto para mensajes firmados por su propio autor. No hay empresa detrás ni cuenta que puedan bloquear: solo claves y relés. Por eso tu identidad de esta app también funciona en otras aplicaciones Nostr.';

  @override
  String get glNewsTitle => 'La sección de noticias';

  @override
  String get glNewsBody =>
      'Los artículos vienen de la revista Einundzwanzig y existen como textos largos de Nostr. Puedes leerlos en la app, darles un me gusta, compartirlos y enviar sats a los autores.';

  @override
  String get glConverterTitle => 'Conversor y precio';

  @override
  String get glConverterBody =>
      'Convierte euros a sats y viceversa. El precio y la altura de bloque vienen de una instancia de mempool; puedes cambiarla en los ajustes, por ejemplo a tu propio nodo.';

  @override
  String get glCommunityTitle => 'Sección de comunidad';

  @override
  String get glCommunityBody =>
      'Un punto de reunión para todo lo de Einundzwanzig que no trata de insignias: pódcast, shoutouts, PlebRap, SatoshiDuell y el mapa de meetups. Gran parte se abre en el navegador.';

  @override
  String get settingsRestartGuide => 'Repetir la visita';

  @override
  String get settingsRestartGuideSub =>
      'Volver a mostrar todas las visitas guiadas';

  @override
  String get settingsGuideReset =>
      'Visitas restablecidas: volverán a iniciarse al abrir esas secciones.';

  @override
  String get guideSettingsRestartTitle => 'Repetir la visita';

  @override
  String get guideSettingsRestartBody =>
      'Restablece todas las visitas guiadas. Volverán a iniciarse la próxima vez que abras cada sección.';

  @override
  String get guideWalletMapTitle => 'Mapa mundial';

  @override
  String get guideWalletMapBody =>
      'Muestra tus insignias donde las conseguiste. Una lista se convierte en un mapa de tus visitas.';

  @override
  String get guideWalletViewTitle => 'Cambiar la vista';

  @override
  String get guideWalletViewBody =>
      'Alterna entre tarjetas grandes y una vista compacta. Con muchas insignias, la compacta se revisa más rápido.';

  @override
  String get guideCommunityPortalTitle => 'El portal';

  @override
  String get guideCommunityPortalBody =>
      'Acceso a meetups, eventos, cursos y el mapa en einundzwanzig.space. Gran parte se abre en el navegador.';

  @override
  String get guideCommunityNewsTitle => 'Noticias y Nostr';

  @override
  String get guideCommunityNewsBody =>
      'Artículos de la revista Einundzwanzig y las últimas notas de tu red Nostr, ambos legibles en la app.';

  @override
  String get guideCommunityFunTitle => 'Para participar';

  @override
  String get guideCommunityFunBody =>
      'SatoshiDuell para partidas de preguntas por sats y PlebRap para música de la comunidad. Ambos solo necesitan tu identidad.';

  @override
  String get guideMyMeetupsListTitle => 'Tus meetups';

  @override
  String get guideMyMeetupsListBody =>
      'Los meetups en los que estás registrado en el portal. Toca uno para ver y gestionar sus fechas; el botón de abajo también crea nuevas.';

  @override
  String get guideMyMeetupsCreateTitle => 'Crear una fecha';

  @override
  String get guideMyMeetupsCreateBody =>
      'Añade una nueva fecha en el portal. Aparecerá en el calendario de todos los que tengan este meetup como favorito.';

  @override
  String get guideWotTabsTitle => 'Las tres vistas';

  @override
  String get guideWotTabsBody =>
      'Red muestra quién está conectado con quién. Avales muestra por quién respondes y quién responde por ti. Denuncias reúne las advertencias de la red.';

  @override
  String get guideWotRefreshTitle => 'Recargar';

  @override
  String get guideWotRefreshBody =>
      'Obtiene el estado actual de los relés. La red crece con cada meetup; sin recargar ves el estado de tu última visita.';

  @override
  String get guideHomeCustomizeTitle => 'Tu panel';

  @override
  String get guideHomeCustomizeBody =>
      'Bajo este encabezado están los paneles que no has anclado: no han desaparecido, solo están apartados. Mantén pulsado un panel para anclarlo, soltarlo o moverlo.';

  @override
  String get guidePaMeetupsTitle => 'Meetups y fechas';

  @override
  String get guidePaMeetupsBody =>
      'Ambos llevan al calendario: uno a los grupos, el otro a las próximas fechas. Lo que ves depende de tus favoritos.';

  @override
  String get guidePaCoursesTitle => 'Cursos';

  @override
  String get guidePaCoursesBody =>
      'La oferta formativa de Einundzwanzig con sus docentes, desde una noche para principiantes hasta una serie de varias partes.';

  @override
  String get guidePaMapTitle => 'El mapa';

  @override
  String get guidePaMapBody =>
      'Muestra los meetups de tu entorno en un mapa. Útil al viajar o para saber qué más hay en la región además de tu meetup principal.';

  @override
  String get guidePaMineTitle => 'Mis meetups';

  @override
  String get guidePaMineBody =>
      'Solo interesa a los organizadores: aquí gestionas las fechas de los meetups en los que estás registrado. Si no llevas ninguno, verás una lista vacía.';

  @override
  String get guideSettingsProfileTitle => 'Perfil y claves';

  @override
  String get guideSettingsProfileBody =>
      'Aquí cambias tu nombre y tu meetup principal, y aquí están tus claves Nostr. Abajo puedes copiar el npub y mostrar el nsec. Si la app creó una clave para ti, aquí la encuentras.';

  @override
  String get glFindKeysTitle => '¿Dónde están mis claves?';

  @override
  String get glFindKeysBody =>
      'Ajustes → Perfil, al final. Allí copias el npub con un toque y muestras el nsec, esto último solo tras una advertencia: quien ve el nsec tiene tu identidad. Si usas Amber, una extensión o un bunker, aquí no hay nsec: está allí, no en esta app.';

  @override
  String get idSetupSecureTitle => 'Identidad creada: asegúrala ahora';

  @override
  String get idSetupSecureBody =>
      'Hay dos maneras de asegurarlo y hacen cosas distintas. Lo mejor es hacer ambas.';

  @override
  String get idSetupSecureBackup => 'Crear copia de seguridad';

  @override
  String get idSetupSecureCopy => 'Copiar la clave al portapapeles';

  @override
  String get idSetupSecureWhere =>
      'Puedes encontrar tus claves en cualquier momento en Ajustes → Perfil.';

  @override
  String get idSetupSecureBackupTitle => 'Archivo de copia';

  @override
  String get idSetupSecureBackupBody =>
      'Contiene todo: claves, insignias, reputación y ajustes. Con él, tu app vuelve exactamente igual en un dispositivo nuevo. El archivo está cifrado con su propia contraseña.';

  @override
  String get idSetupSecureKeyTitle => 'Clave cifrada';

  @override
  String get idSetupSecureKeyBody =>
      'Por último, tu clave Nostr sola, envuelta con tu contraseña (ncryptsec). Salva tu identidad pero no las insignias; a cambio nunca queda obsoleta.';

  @override
  String get idSetupSecureRepeat =>
      'Repite la copia de vez en cuando en Ajustes → Copia de seguridad. Un archivo de hoy no conoce las insignias de mañana.';

  @override
  String get idSetupSecureKeySave => 'Guardar como archivo';

  @override
  String get idSetupSecureKeySaved => 'Archivo de clave guardado.';

  @override
  String get idSetupSecureSkip => 'Omitir';

  @override
  String get idSetupSecureFileHeader =>
      'Einundzwanzig Meetup App — clave Nostr cifrada (ncryptsec, NIP-49). Sin la contraseña correspondiente, este archivo no sirve de nada. Guárdalos por separado.';

  @override
  String get chatRelayHint => 'Relé de grupos de Einundzwanzig';

  @override
  String get chatEmpty =>
      'Aún no hay mensajes. Escribe el primero: la sala está abierta en el relé y también es accesible desde otras apps de Nostr.';

  @override
  String get chatPlaceholder => 'Escribe un mensaje …';

  @override
  String get chatJoin => 'Unirse a la sala';

  @override
  String get chatJoinHint =>
      'Puedes leer sin más. Para escribir debes unirte a la sala: el relé mantiene la lista de miembros.';

  @override
  String chatJoinFailed(String msg) {
    return 'Unión rechazada: $msg';
  }

  @override
  String chatSendFailed(String msg) {
    return 'Mensaje no entregado: $msg';
  }

  @override
  String get chatSearching => 'Buscando la sala de chat …';

  @override
  String chatNoRoom(String city) {
    return 'Todavía no hay sala de chat para $city en el relé de grupos. Los detalles están en el registro de diagnóstico.';
  }

  @override
  String get chatEventOpen => 'Chat sobre esta fecha';

  @override
  String get chatEventFailed =>
      'No se pudo abrir la sala de chat. Los detalles están en el registro de diagnóstico.';

  @override
  String get btnChat => 'Chat';

  @override
  String get btnInfo => 'Info';

  @override
  String get chatEventHint => 'Comentarios sobre la fecha · públicos en Nostr';

  @override
  String get chatEventEmpty =>
      'Aún no hay nada escrito. Comparte información sobre la fecha: punto de encuentro, cambios, preguntas. Los comentarios cuelgan del propio evento.';

  @override
  String get chatMemberHint =>
      'Unirse requiere ser miembro de la asociación Einundzwanzig. Sin ello, el relé rechaza la solicitud y sigues como lector silencioso.';

  @override
  String get chatMemberLink => 'Sobre la membresía';

  @override
  String walletSince(String month) {
    return 'desde $month';
  }

  @override
  String walletLastVisit(String ago) {
    return 'última vez $ago';
  }

  @override
  String get walletAgoToday => 'hoy';

  @override
  String get walletAgoYesterday => 'ayer';

  @override
  String walletAgoDays(int days) {
    return 'hace $days días';
  }

  @override
  String walletAgoMonths(int months) {
    return 'hace $months meses';
  }

  @override
  String walletAgoYears(int years) {
    return 'hace $years años';
  }

  @override
  String walletCollectionCount(int count) {
    return '$count insignias';
  }

  @override
  String get rsvpYes => 'Voy a ir';

  @override
  String get rsvpNo => 'No voy';

  @override
  String get tileEventChats => 'Mis fechas';

  @override
  String get tileEventChatsSub => 'Confirmaciones y chats';

  @override
  String get eventChatsTitle => 'Mis fechas';

  @override
  String get eventChatsEmpty =>
      'Aquí aparecen las próximas fechas de tus meetups y los eventos que has confirmado. Elige un meetup favorito o confirma en el calendario.';

  @override
  String tileEventChatsUnread(int count) {
    return '$count mensajes nuevos';
  }

  @override
  String get chatYou => 'Tú';

  @override
  String get chatCopyNpub => 'Copiar npub';

  @override
  String get chatNpubCopied => 'npub copiado.';

  @override
  String get eventChatsMeetups => 'Mis meetups';

  @override
  String get eventChatsEvents => 'Eventos confirmados';

  @override
  String get tileEventChatsNone => 'Nada planeado';

  @override
  String rsvpAttendees(int count) {
    return '$count asisten';
  }

  @override
  String get rsvpWithdrawTitle => '¿Retirar tu confirmación?';

  @override
  String rsvpWithdrawBody(String title) {
    return '«$title» desaparecerá de tus fechas. El organizador verá una cancelación; el chat sigue accesible desde el calendario.';
  }

  @override
  String get rsvpWithdrawConfirm => 'Cancelar asistencia';

  @override
  String get evBadgeNeedLocation =>
      'Una insignia necesita la ubicación del evento en el mapa: con ella se comprueba quién está allí.';

  @override
  String get evBadgeNoLocationSet =>
      'Este evento no tiene ubicación en el mapa, así que aquí no se puede emitir ni recoger ninguna insignia.';

  @override
  String mvPortalOrganizer(String meetup) {
    return '✓ Organizador de $meetup\nRegistrado en el portal de Einundzwanzig como líder de este meetup.';
  }
}
