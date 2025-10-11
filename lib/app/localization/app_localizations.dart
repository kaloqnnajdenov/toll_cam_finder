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
      'coordinatesMustBeProvided':
          'Coordinates must be provided in the format "lat, lon".',
      'coordinatesMustBeDecimalNumbers':
          'Coordinates must be valid decimal numbers.',
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
      'createSegmentDetailsTitle': 'Segment details',
      'createSegmentEndCoordinatesHint': '41.8322163,26.1404669',
      'createSegmentEndCoordinatesLabel': 'End point',
      'createSegmentEndLabel': 'End',
      'createSegmentEndNameHint': 'End name',
      'createSegmentMapInstructionBody':
          'Drop or drag markers to adjust the start and end points. Coordinates are filled automatically as you move them.',
      'createSegmentMapInstructionTitle':
          'Set the start and end points on the map',
      'createSegmentNameHint': 'Segment name',
      'createSegmentNameLabel': 'Segment name',
      'createSegmentRoadNameHint': 'Road name',
      'createSegmentRoadNameLabel': 'Road name',
      'createSegmentStartCoordinatesHint': '41.8626802,26.0873785',
      'createSegmentStartCoordinatesLabel': 'Start coordinates',
      'createSegmentStartLabel': 'Start',
      'createSegmentStartNameHint': 'Start name',
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
      'languageLabelEnglish': 'English',
      'languageLabelSpanish': 'Bulgarian',
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
      'onlySegmentsSavedLocallyCanBeShared':
          'Only segments saved locally can be shared publicly.',
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
      'segmentAlreadyApprovedAndPublic':
          'Segment {displayId} was already approved by the administrators and is public.',
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
      'segmentMissingCoordinates':
          'The saved segment is missing coordinates and cannot be shared publicly.',
      'segmentNotFoundLocally': 'The segment could not be found locally.',
      'segmentNoLongerUnderReview':
          'Segment {displayId} will no longer be reviewed for public release.',
      'segmentProgressEndKilometers': '{distance} km to segment end',
      'segmentProgressEndMeters': '{distance} m to segment end',
      'segmentProgressEndNearby': 'Segment end nearby',
      'segmentProgressStartKilometers': '{distance} km to segment start',
      'segmentProgressStartMeters': '{distance} m to segment start',
      'segmentProgressStartNearby': 'Segment start nearby',
      'segmentSavedLocally': 'Segment saved locally.',
      'segmentDefaultStartName': '{name} start',
      'segmentDefaultEndName': '{name} end',
      'segmentPickerStartMarkerLabel': 'A',
      'segmentPickerEndMarkerLabel': 'B',
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
      'speedDialPlaceholder': '—',
      'speedDialUnitKmh': 'km/h',
      'personalSegmentDefaultName': 'Personal segment',
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
      'segmentNameRequired': 'Segment name is required.',
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
      'savingLocalSegmentsNotSupportedOnWeb':
          'Saving local segments is not supported on the web.',
      'loadingLocalSegmentsNotSupportedOnWeb':
          'Loading local segments is not supported on the web.',
      'deletingLocalSegmentsNotSupportedOnWeb':
          'Deleting local segments is not supported on the web.',
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
      'fileSystemOperationsNotSupported':
          'File system operations are not supported on this platform.',
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
      'chooseSegmentVisibilityQuestion':
          'Do you want the segment to be publically visible?',
      'averageSpeedResetTooltip': 'Нулирай средната скорост',
      'averageSpeedStartTooltip': 'Започни средната скорост',
      'confirmKeepSegmentPrivate':
          'Are you sure that you want to keep the segment only to yourself?',
      'confirmMakeSegmentPublic':
          'Are you sure you want to make this segment public?',
      'comingSoon': 'Очаквайте скоро',
      'coordinatesMustBeProvided':
          'Координатите трябва да бъдат въведени във формат „ширина, дължина“.',
      'coordinatesMustBeDecimalNumbers':
          'Координатите трябва да са валидни десетични числа.',
      'confirmPasswordLabel': 'Потвърди паролата',
      'continue': 'Продължи',
      'createAccount': 'Създай акаунт',
      'createAccountCta': 'Създай акаунт',
      'createAccountDescription': 'Вече имаш акаунт? Влез',
      'createNewAccount': 'Създай нов акаунт',
      'createSegment': 'Създай сегмент',
      'createSegmentDetailsTitle': 'Детайли за сегмента',
      'createSegmentEndCoordinatesHint': '41.8322163,26.1404669',
      'createSegmentEndCoordinatesLabel': 'Крайна точка',
      'createSegmentEndLabel': 'Край',
      'createSegmentEndNameHint': 'Име на края',
      'createSegmentMapInstructionBody':
          'Постави или премести маркерите, за да коригираш началната и крайната точка. Координатите се попълват автоматично при преместване.',
      'createSegmentMapInstructionTitle': 'Поставете началната и крайната точка на картата',
      'createSegmentNameHint': 'Име на сегмента',
      'createSegmentNameLabel': 'Име на сегмента',
      'createSegmentRoadNameHint': 'Име на пътя',
      'createSegmentRoadNameLabel': 'Име на пътя',
      'createSegmentStartCoordinatesHint': '41.8626802,26.0873785',
      'createSegmentStartCoordinatesLabel': 'Начални координати',
      'createSegmentStartLabel': 'Начало',
      'createSegmentStartNameHint': 'Име на началото',
      'emailLabel': 'Имейл адрес',
      'fullNameLabel': 'Пълно име',
      'joinTollCam': 'Присъедини се към TollCam',
      'language': 'Език',
      'languageLabelEnglish': 'Английски',
      'languageLabelSpanish': 'Български',
      'languageButton': 'Смени езика',
      'localSegments': 'Локални сегменти',
      'loginAction': 'Login',
      'logIn': 'Вход',
      'logOut': 'Изход',
      'loggedInRetrySavePrompt':
          'Logged in successfully. Tap "Save segment" again to submit the segment.',
      'noAction': 'No',
      'noLocalSegments': 'Все още няма запазени локални сегменти.',
      'noSegmentsAvailable': 'Няма налични сегменти.',
      'openMenu': 'Отвори менюто',
      'passwordLabel': 'Парола',
      'profile': 'Профил',
      'profileSubtitle': 'Управлявай акаунта и настройките си в TollCam.',
      'recenter': 'Центрирай Екрана',
      'saveLocallyAction': 'Save locally',
      'saveSegment': 'Запази сегмента',
      'segmentNameRequired': 'Моля, въведете име на сегмента.',
      'startEndCoordinatesRequired': 'Моля, въведете начални и крайни координати.',
      'segmentDebugDistanceKilometersLeft': '{distance} км оставащи',
      'segmentDebugDistanceMeters': '{distance} м',
      'segmentDebugHeadingDiff': 'Δθ={angle}°',
      'segmentDebugTagApprox': 'прибл.',
      'segmentDebugTagDetailed': 'подробно',
      'segmentDebugTagDirectionFail': 'пос✖',
      'segmentDebugTagDirectionPass': 'пос✔',
      'segmentDebugTagEnd': 'край',
      'segmentDebugTagSeparator': ' · ',
      'segmentDebugTagStart': 'начало',
      'segmentProgressEndKilometers':
          '{distance} км до края на сегмента',
      'segmentProgressEndMeters': '{distance} м до края на сегмента',
      'segmentProgressEndNearby': 'Краят на сегмента е близо',
      'segmentProgressStartKilometers':
          '{distance} км до началото на сегмента',
      'segmentProgressStartMeters': '{distance} м до началото на сегмента',
      'segmentProgressStartNearby': 'Началото на сегмента е близо',
      'segments': 'Сегменти',
      'selectLanguage': 'Избери език',
      'signInToSharePubliclyBody':
          'You need to be logged in to submit a public segment. Would you like to log in or save the segment locally instead?',
      'signInToSharePubliclyTitle': 'Sign in to share publicly',
      'segmentDefaultStartName': 'Начало на {name}',
      'segmentDefaultEndName': 'Край на {name}',
      'segmentPickerStartMarkerLabel': 'A',
      'segmentPickerEndMarkerLabel': 'B',
      'segmentMissingCoordinates':
          'Запазеният сегмент няма координати и не може да бъде споделен публично.',
      'segmentNotFoundLocally': 'Сегментът не беше намерен локално.',
      'personalSegmentDefaultName': 'Личен сегмент',
      'onlySegmentsSavedLocallyCanBeShared':
          'Само сегменти, запазени локално, могат да бъдат споделяни публично.',
      'segmentAlreadyApprovedAndPublic':
          'Segment {displayId} was already approved by the administrators and is public.',
      'speedDialAverageTitle': 'Средна скорост',
      'speedDialCurrentTitle': 'Скорост',
      'speedDialDebugSummary': 'Сегменти: {count}  r={radius}{unit}',
      'speedDialLastSegmentAverage':
          'Средна скорост на последния сегмент: {value}{unit}',
      'speedDialLimitLabel': 'Лимит: {value} {unit}',
      'speedDialNoActiveSegment': 'Няма активен сегмент',
      'speedDialPlaceholder': '—',
      'speedDialUnitKmh': 'км/ч',
      'syncAddedMany': '{count} сегмента добавени',
      'syncAddedOne': '{count} сегмент добавен',
      'syncApprovedSummaryPlural':
          '{count} от твоите изпратени сегменти бяха одобрени и вече са видими за всички.',
      'syncApprovedSummarySingular':
          '{count} от твоите изпратени сегменти беше одобрен и вече е видим за всички.',
      'syncCompleteIntro': 'Синхронизацията е завършена.',
      'syncNoChangesDetected': 'Няма открити промени.',
      'syncRemovedMany': '{count} сегмента изтрити',
      'syncRemovedOne': '{count} сегмент изтрит',
      'syncTotalSegmentsSummary': 'Общо налични сегменти: {count}.',
      'sync': 'Синхронизирай',
      'savingLocalSegmentsNotSupportedOnWeb':
          'Запазването на локални сегменти не се поддържа в уеб версията.',
      'loadingLocalSegmentsNotSupportedOnWeb':
          'Зареждането на локални сегменти не се поддържа в уеб версията.',
      'deletingLocalSegmentsNotSupportedOnWeb':
          'Изтриването на локални сегменти не се поддържа в уеб версията.',
      'fileSystemOperationsNotSupported':
          'Операциите с файловата система не се поддържат на тази платформа.',
      'unitKilometersShort': 'км',
      'unitMetersShort': 'м',
      'unknownUserLabel': 'Непознат потребител',
      'welcomeTitle': 'Добре Дошли!',
      'yesAction': 'Yes',
      'yourProfile': 'Твоят профил',

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
  String get createAccountDescription =>
      _value('createAccountDescription');
  String get continueLabel => _value('continue');
  String get createNewAccount => _value('createNewAccount');
  String get yourProfile => _value('yourProfile');
  String get logOut => _value('logOut');
  String get localSegments => _value('localSegments');
  String get createSegment => _value('createSegment');
  String get saveSegment => _value('saveSegment');
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
