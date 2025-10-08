import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLanguageCodes = ['en', 'es'];

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'accountCreatedCheckEmail': 'Account created! Check your email to confirm it.',
      'appTitle': 'TollCam',
      'authenticationNotConfigured':
          'Authentication is not configured. Please add Supabase credentials.',
      'averageSpeedResetTooltip': 'Reset Avg',
      'averageSpeedStartTooltip': 'Start Avg',
      'cancelAction': 'Cancel',
      'chooseSegmentVisibilityQuestion':
          'Do you want the segment to be publically visible?',
      'comingSoon': 'Coming soon',
      'confirmDeleteSegment':
          'Are you sure you want to delete segment {displayId}?',
      'confirmKeepSegmentPrivate':
          'Are you sure that you want to keep the segment only to yourself?',
      'confirmMakeSegmentPublic': 'Are you sure you want to make this segment public?',
      'confirmPasswordLabel': 'Confirm password',
      'confirmYourPassword': 'Please confirm your password',
      'continue': 'Continue',
      'createAccount': 'Create account',
      'createAccountCta': 'Create an account',
      'createAccountDescription': 'Already have an account? Log in',
      'createNewAccount': 'Create a new account',
      'createPasswordPrompt': 'Please create a password',
      'createSegment': 'Create segment',
      'csvMissingStartEndColumns': 'CSV must contain "Start" and "End" columns',
      'deleteAction': 'Delete',
      'deleteSegmentAction': 'Delete segment',
      'deleteSegmentConfirmationTitle': 'Delete segment',
      'emailLabel': 'Email',
      'enterYourEmail': 'Please enter your email',
      'enterYourName': 'Please enter your name',
      'enterYourPassword': 'Please enter your password',
      'failedToAccessSegmentsMetadataFile':
          'Failed to access the segments metadata file.',
      'failedToAccessTollSegmentsFile':
          'Failed to access the toll segments file: {reason}',
      'failedToCancelPublicReview':
          'Failed to cancel the public review for this segment.',
      'failedToCancelSubmissionWithReason':
          'Failed to cancel the public submission: {reason}',
      'failedToCheckSubmissionStatus':
          'Failed to check the public submission status.',
      'failedToCheckSubmissionStatusWithReason':
          'Failed to check the public submission status: {reason}',
      'failedToDeleteSegment': 'Failed to delete the segment.',
      'failedToDetermineTollSegmentsPath':
          'Failed to determine the local toll segments storage path.',
      'failedToDownloadTollSegments':
          'Failed to download toll segments: {reason}',
      'failedToLoadCameras': 'Failed to load cameras: {error}',
      'failedToLoadSegmentPreferences':
          'Failed to load segment preferences: {errorMessage}',
      'failedToLoadSegments': 'Failed to load segments.',
      'failedToParseSegmentsMetadataFile':
          'Failed to parse the segments metadata file.',
      'failedToPrepareSegmentForReview':
          'Failed to prepare the segment for public review.',
      'failedToSaveSegmentLocally': 'Failed to save the segment locally.',
      'failedToSubmitForModeration':
          'Failed to submit the segment for moderation.',
      'failedToSubmitSegmentForModerationWithReason':
          'Failed to submit the segment for moderation: {reason}',
      'failedToUpdateSegment':
          'Failed to update segment {displayId}: {errorMessage}',
      'failedToWriteSegmentsMetadataFile':
          'Failed to write to the segments metadata file.',
      'fullNameLabel': 'Full name',
      'hideSegmentOnMapAction': 'Hide segment on map',
      'joinTollCam': 'Join TollCam',
      'language': 'Language',
      'languageButton': 'Change language',
      'localSegments': 'Local segments',
      'logIn': 'Log in',
      'logOut': 'Log out',
      'loggedInRetrySavePrompt':
          'Logged in successfully. Tap "Save segment" again to submit the segment.',
      'loginAction': 'Login',
      'mapHintDragPoint':
          'Touch and hold A or B for 0.5s, then drag to reposition that point.',
      'mapHintPlacePointA': 'Tap anywhere on the map to place point A.',
      'mapHintPlacePointB': 'Tap a second location to place point B.',
      'missingRequiredColumn':
          'Missing required column "{column}" in the Toll_Segments table.',
      'noAction': 'No',
      'noConnectionCannotWithdrawSubmission':
          'No internet connection. The public submission cannot be withdrawn and the segment will only be deleted locally.',
      'noConnectionUnableToManageSubmissions':
          'No internet connection. Unable to manage public submissions.',
      'noConnectionUnableToSubmitForModeration':
          'No internet connection. Unable to submit the segment for moderation.',
      'noLocalSegments': 'No local segments saved yet.',
      'noSegmentsAvailable': 'No segments available.',
      'noTollSegmentRowsFound':
          'No toll segment rows were returned from Supabase. Checked tables: {tablesChecked}. Ensure your account has access to the data.',
      'nonNumericSegmentIdEncountered':
          'Encountered an existing segment with a non-numeric id.',
      'onlyLocalSegmentsCanBeDeleted': 'Only local segments can be deleted.',
      'openMenu': 'Open menu',
      'osmCopyrightLaunchFailed':
          'Could not open the OpenStreetMap copyright page.',
      'passwordLabel': 'Password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',
      'profile': 'Profile',
      'profileSubtitle': 'Manage your TollCam account and preferences.',
      'publicSharingUnavailable':
          'Public segment sharing is currently unavailable.',
      'publicSharingUnavailableShort': 'Public sharing is not available.',
      'recenter': 'Recenter',
      'retryAction': 'Retry',
      'saveLocallyAction': 'Save locally',
      'saveSegment': 'Save segment',
      'segmentAlreadyAwaitingReview':
          'Segment {displayId} is already awaiting public review.',
      'segmentDebugDistanceKilometersLeft': '{distance} km left',
      'segmentDebugDistanceMeters': '{distance} m',
      'segmentDebugHeadingDiff': 'Δθ={angle}°',
      'segmentDebugTagApprox': 'approx',
      'segmentDebugTagDetailed': 'detailed',
      'segmentDebugTagDirectionFail': 'dir✖',
      'segmentDebugTagDirectionPass': 'dir✔',
      'segmentDebugTagEnd': 'end',
      'segmentDebugTagSeparator': ' · ',
      'segmentDebugTagStart': 'start',
      'segmentDeleted': 'Segment {displayId} deleted.',
      'segmentHidden':
          'Segment {displayId} hidden. Cameras and warnings are disabled.',
      'segmentMetadataUpdateUnavailable':
          'Segment metadata cannot be updated on the web.',
      'segmentNoLongerUnderReview':
          'Segment {displayId} will no longer be reviewed for public release.',
      'segmentProgressEndKilometers': '{distance} km to segment end',
      'segmentProgressEndMeters': '{distance} m to segment end',
      'segmentProgressEndNearby': 'Segment end nearby',
      'segmentProgressStartKilometers': '{distance} km to segment start',
      'segmentProgressStartMeters': '{distance} m to segment start',
      'segmentProgressStartNearby': 'Segment start nearby',
      'segmentSavedLocally': 'Segment saved locally.',
      'segmentSubmittedForPublicReview':
          'Segment {displayId} submitted for public review.',
      'segmentSubmittedForPublicReviewGeneric': 'Segment submitted for public review.',
      'segmentVisibilityDisableSubtitle':
          'No cameras or warnings will appear for this segment.',
      'segmentVisibilityRestoreSubtitle':
          'Cameras and warnings for this segment will be restored.',
      'segmentVisible':
          'Segment {displayId} is visible again. Cameras and warnings restored.',
      'segments': 'Segments',
      'selectLanguage': 'Select language',
      'shareSegmentPubliclyAction': 'Share segment publicly',
      'showSegmentOnMapAction': 'Show segment on map',
      'signInToSharePubliclyBody':
          'You need to be logged in to submit a public segment. Would you like to log in or save the segment locally instead?',
      'signInToSharePubliclyTitle': 'Sign in to share publicly',
      'signInToShareSegment': 'Please sign in to share segments publicly.',
      'signInToWithdrawSubmission': 'Please sign in to withdraw the public submission.',
      'somethingWentWrongTryAgain': 'Something went wrong. Please try again.',
      'speedDialAverageTitle': 'Avg Speed',
      'speedDialCurrentTitle': 'Speed',
      'speedDialDebugSummary': 'Segments: {count}  r={radius}{unit}',
      'speedDialLastSegmentAverage':
          'Avg speed for the last segment: {value}{unit}',
      'speedDialLimitLabel': 'Limit: {value} {unit}',
      'speedDialNoActiveSegment': 'No active segment',
      'speedDialUnitKmh': 'km/h',
      'syncAddedMany': '{count} segments added',
      'syncAddedOne': '{count} segment added',
      'syncApprovedSummaryPlural':
          '{count} of your submitted segments were approved and are now visible to everyone.',
      'syncApprovedSummarySingular':
          '{count} of your submitted segments was approved and is now visible to everyone.',
      'syncCompleteIntro': 'Sync complete.',
      'syncNoChangesDetected': 'No changes detected.',
      'syncRemovedMany': '{count} segments removed',
      'syncRemovedOne': '{count} segment removed',
      'syncTotalSegmentsSummary': '{count} total segments available.',
      'startEndCoordinatesRequired': 'Start and end coordinates are required.',
      'submitSegmentForPublicReviewSubtitle':
          'Submit this segment for public review.',
      'supabaseNotConfiguredForModeration':
          'Supabase is not configured. Unable to submit the segment for moderation.',
      'supabaseNotConfiguredForPublicSubmissions':
          'Supabase is not configured. Unable to manage public submissions.',
      'supabaseNotConfiguredForSync':
          'Supabase is not configured. Please add credentials to enable sync.',
      'sync': 'Sync',
      'syncNotSupportedOnWeb': 'Syncing toll segments is not supported on the web.',
      'tableMissingModerationColumn':
          'The "{tableName}" table is missing the "{column}" column required for moderation.',
      'tableReturnedNoRows':
          'The {tableName} table did not return any rows.',
      'unableToAssignNewSegmentId':
          'Unable to assign a new segment id: all smallint values are exhausted.',
      'unableToDetermineLoggedInAccount':
          'Unable to determine the logged in account.',
      'unableToDetermineLoggedInAccountRetry':
          'Unable to determine the logged in account. Please sign in again.',
      'unableToLogOutTryAgain': 'Unable to log out. Please try again.',
      'unableToWithdrawSubmission': 'Unable to withdraw the public submission.',
      'unexpectedErrorCancellingSubmission':
          'Unexpected error while cancelling the public submission.',
      'unexpectedErrorCheckingSubmissionStatus':
          'Unexpected error while checking the public submission status.',
      'unexpectedErrorCreatingAccount':
          'Unexpected error while creating the account.',
      'unexpectedErrorSigningIn': 'Unexpected error while signing in.',
      'unexpectedErrorSigningOut': 'Unexpected error while signing out.',
      'unexpectedErrorSubmittingForModeration':
          'Unexpected error while submitting the segment for moderation.',
      'unexpectedSyncError': 'Unexpected error while syncing toll segments.',
      'unitKilometersShort': 'km',
      'unitMetersShort': 'm',
      'unknownUserLabel': 'Unknown user',
      'userRequiredForPublicModeration':
          'A logged in user is required to submit a public segment for moderation.',
      'welcomeTitle': 'Welcome',
      'withdrawPublicSubmissionMessage':
          'You have submitted this segment for review. Do you want to withdraw the submission?',
      'withdrawPublicSubmissionTitle': 'Withdraw public submission?',
      'yesAction': 'Yes',
      'yourProfile': 'Your profile',
    },
    'es': {
      'appTitle': 'TollCam',
      'averageSpeedResetTooltip': 'Reiniciar promedio',
      'averageSpeedStartTooltip': 'Iniciar promedio',
      'comingSoon': 'Próximamente',
      'confirmPasswordLabel': 'Confirmar contraseña',
      'continue': 'Continuar',
      'createAccount': 'Crear cuenta',
      'createAccountCta': 'Crear una cuenta',
      'createAccountDescription': '¿Ya tienes una cuenta? Inicia sesión',
      'createNewAccount': 'Crear una cuenta nueva',
      'createSegment': 'Crear segmento',
      'emailLabel': 'Correo electrónico',
      'fullNameLabel': 'Nombre completo',
      'joinTollCam': 'Únete a TollCam',
      'language': 'Idioma',
      'languageButton': 'Cambiar idioma',
      'localSegments': 'Segmentos locales',
      'logIn': 'Iniciar sesión',
      'logOut': 'Cerrar sesión',
      'noLocalSegments': 'Aún no hay segmentos locales guardados.',
      'noSegmentsAvailable': 'No hay segmentos disponibles.',
      'openMenu': 'Abrir menú',
      'passwordLabel': 'Contraseña',
      'profile': 'Perfil',
      'profileSubtitle': 'Administra tu cuenta y preferencias de TollCam.',
      'recenter': 'Recentrar',
      'saveSegment': 'Guardar segmento',
      'segmentDebugDistanceKilometersLeft': '{distance} km restantes',
      'segmentDebugDistanceMeters': '{distance} m',
      'segmentDebugHeadingDiff': 'Δθ={angle}°',
      'segmentDebugTagApprox': 'aprox',
      'segmentDebugTagDetailed': 'detallado',
      'segmentDebugTagDirectionFail': 'dir✖',
      'segmentDebugTagDirectionPass': 'dir✔',
      'segmentDebugTagEnd': 'fin',
      'segmentDebugTagSeparator': ' · ',
      'segmentDebugTagStart': 'inicio',
      'segmentProgressEndKilometers':
          '{distance} km hasta el final del segmento',
      'segmentProgressEndMeters': '{distance} m hasta el final del segmento',
      'segmentProgressEndNearby': 'Final del segmento cercano',
      'segmentProgressStartKilometers':
          '{distance} km hasta el inicio del segmento',
      'segmentProgressStartMeters': '{distance} m hasta el inicio del segmento',
      'segmentProgressStartNearby': 'Inicio del segmento cercano',
      'segments': 'Segmentos',
      'selectLanguage': 'Seleccionar idioma',
      'speedDialAverageTitle': 'Velocidad promedio',
      'speedDialCurrentTitle': 'Velocidad',
      'speedDialDebugSummary': 'Segmentos: {count}  r={radius}{unit}',
      'speedDialLastSegmentAverage':
          'Velocidad promedio del último segmento: {value}{unit}',
      'speedDialLimitLabel': 'Límite: {value} {unit}',
      'speedDialNoActiveSegment': 'Sin segmento activo',
      'speedDialUnitKmh': 'km/h',
      'syncAddedMany': '{count} segmentos añadidos',
      'syncAddedOne': '{count} segmento añadido',
      'syncApprovedSummaryPlural':
          '{count} de tus segmentos enviados fueron aprobados y ahora son visibles para todos.',
      'syncApprovedSummarySingular':
          '{count} de tus segmentos enviados fue aprobado y ahora es visible para todos.',
      'syncCompleteIntro': 'Sincronización completa.',
      'syncNoChangesDetected': 'No se detectaron cambios.',
      'syncRemovedMany': '{count} segmentos eliminados',
      'syncRemovedOne': '{count} segmento eliminado',
      'syncTotalSegmentsSummary': '{count} segmentos totales disponibles.',
      'sync': 'Sincronizar',
      'unitKilometersShort': 'km',
      'unitMetersShort': 'm',
      'unknownUserLabel': 'Usuario desconocido',
      'welcomeTitle': 'Bienvenido',
      'yourProfile': 'Tu perfil',
    },
  };

  static List<Locale> get supportedLocales =>
      supportedLanguageCodes.map((code) => Locale(code)).toList(growable: false);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String _value(String key) {
    return _localizedStrings[locale.languageCode]?[key] ??
        _localizedStrings['en']![key]!;
  }

  String translate(String key, [Map<String, String>? replacements]) {
    var value = _value(key);
    if (replacements != null) {
      replacements.forEach((placeholder, replacement) {
        value = value.replaceAll('{$placeholder}', replacement);
      });
    }
    return value;
  }

  String get appTitle => _value('appTitle');
  String get sync => _value('sync');
  String get segments => _value('segments');
  String get language => _value('language');
  String get profile => _value('profile');
  String get selectLanguage => _value('selectLanguage');
  String get comingSoon => _value('comingSoon');
  String get openMenu => _value('openMenu');
  String get logIn => _value('logIn');
  String get createAccount => _value('createAccount');
  String get createAccountCta => _value('createAccountCta');
  String get createAccountDescription => _value('createAccountDescription');
  String get continueLabel => _value('continue');
  String get createNewAccount => _value('createNewAccount');
  String get yourProfile => _value('yourProfile');
  String get logOut => _value('logOut');
  String get localSegments => _value('localSegments');
  String get createSegmentLabel => _value('createSegment');
  String get saveSegmentLabel => _value('saveSegment');
  String get noSegmentsAvailable => _value('noSegmentsAvailable');
  String get noLocalSegments => _value('noLocalSegments');
  String get recenter => _value('recenter');
  String get languageButton => _value('languageButton');
  String get welcomeTitle => _value('welcomeTitle');
  String get joinTollCam => _value('joinTollCam');
  String get emailLabel => _value('emailLabel');
  String get passwordLabel => _value('passwordLabel');
  String get confirmPasswordLabel => _value('confirmPasswordLabel');
  String get fullNameLabel => _value('fullNameLabel');
  String get profileSubtitle => _value('profileSubtitle');
  String get unknownUserLabel => _value('unknownUserLabel');
  String get averageSpeedStartTooltip => _value('averageSpeedStartTooltip');
  String get averageSpeedResetTooltip => _value('averageSpeedResetTooltip');
  String get speedDialCurrentTitle => _value('speedDialCurrentTitle');
  String get speedDialAverageTitle => _value('speedDialAverageTitle');
  String get speedDialUnitKmh => _value('speedDialUnitKmh');
  String get speedDialNoActiveSegment => _value('speedDialNoActiveSegment');
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguageCodes
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
