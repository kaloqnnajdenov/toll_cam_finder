import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLanguageCodes = ['en', 'bg'];

  static const Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'accountCreatedCheckEmail': 'Account created! Check your email to confirm it.',
      'appTitle': 'TollCam',
      'authenticationNotConfigured':
          'Authentication is not configured. Please add Supabase credentials.',
      'backgroundTrackingNotificationRationale':
          'Allow notifications so Toll Cam Finder can stay active in the background.',
      'averageSpeedResetTooltip': 'Reset Avg',
      'averageSpeedStartTooltip': 'Start Avg',
      'cancelAction': 'Cancel',
      'okAction': 'OK',
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
      'createSegmentMissingFields':
          'Please provide the following before saving: {fields}.',
      'createSegmentMissingFieldSegmentName': 'segment name',
      'createSegmentMissingFieldStartCoordinates': 'start coordinates',
      'createSegmentMissingFieldEndCoordinates': 'end coordinates',
      'createSegmentMissingFieldsDelimiter': ', ',
      'createSegmentMissingFieldsConjunction': 'and',
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
      'weighStations': 'Weigh stations',
      'createWeighStation': 'Add weigh station',
      'createWeighStationInstructions':
          'Tap the map to place the weigh station marker. Long-press and drag to fine-tune the location.',
      'weighStationCoordinatesInputLabel': 'Coordinates',
      'weighStationCoordinatesHint': '41.8626802,26.0873785',
      'saveWeighStation': 'Save weigh station',
      'failedToLoadWeighStations': 'Failed to load weigh stations.',
      'noWeighStationsAvailable': 'No weigh stations available.',
      'failedToSaveWeighStationLocally':
          'Failed to save the weigh station locally.',
      'failedToSubmitWeighStation':
          'Failed to submit the weigh station for moderation.',
      'weighStationSubmittedForReview':
          'Weigh station submitted for review.',
      'weighStationIdentifier': 'Weigh station {id}',
      'weighStationCoordinatesLabel': 'Coordinates: {coordinates}',
      'weighStationLocalBadge': 'Local only',
      'weighStationMapHintPlace':
          'Tap anywhere on the map to place the weigh station.',
      'weighStationMapHintDrag':
          'Long-press and drag the marker to adjust the weigh station.',
      'deleteWeighStationAction': 'Delete weigh station',
      'deleteWeighStationConfirmationTitle': 'Delete weigh station',
      'confirmDeleteWeighStation':
          'Are you sure you want to delete weigh station {id}?',
      'weighStationDeleted': 'Weigh station {id} deleted.',
      'failedToDeleteWeighStation': 'Failed to delete the weigh station.',
      'onlyLocalWeighStationsCanBeDeleted':
          'Only weigh stations saved locally can be deleted.',
      'deletingLocalWeighStationsNotSupportedOnWeb':
          'Deleting local weigh stations is not supported on the web.',
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
      'failedToAccessWeighStationsFile':
          'Failed to access the weigh stations file: {reason}',
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
      'failedToDownloadWeighStations':
          'Failed to download weigh stations: {reason}',
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
      'languageLabelBulgarian': 'Bulgarian',
      'languageButton': 'Change language',
      'darkMode': 'Dark mode',
      'audioModeTitle': 'Guidance audio mode',
      'audioModeFullGuidance':
          'Play all guidance sounds (foreground and background)',
      'audioModeForegroundMuted':
          'Mute in app (background guidance, start/end dings only)',
      'audioModeBackgroundMuted':
          'Mute in background (in-app guidance, start/end dings only)',
      'audioModeAbsoluteMute': 'Absolute mute (no sounds)',
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
      'openNotificationSettingsAction': 'Open settings',
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
      'faceTravelDirection': 'Face Travel Direction',
      'northUp': 'North Up',
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
      'segmentBadgeHidden': 'Hidden',
      'segmentBadgeLocal': 'Local',
      'segmentBadgeReview': 'In review',
      'segmentLocationStartLabel': 'Start',
      'segmentLocationEndLabel': 'End',
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
      'segmentsOnlyModeTitle': 'Simple mode',
      'segmentsOnlyModeButton': 'Simple mode',
      'segmentsOnlyModeManualMessage':
          "You're in simple mode. Use this screen to track your segment metrics without the map. Tap the back button to return to the map.",
      'segmentsOnlyModeOsmBlockedMessage':
          "Simple mode is still tracking segments and average speed, but our free map provider is temporarily unavailable. We're sorry for the inconvenience and are working on a fix.",
      'segmentsOnlyModeOfflineMessage':
          "You're offline. We'll keep tracking segments and your average speed, but the map needs an internet connection. Check your connection and come back when you're online again.",
      'segmentsOnlyModeContinueButton': 'Continue to map',
      'segmentsOnlyModeReminder':
          'Segments and averages continue updating while simple mode is open.',
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
      'segmentMetricsHeading': 'Segment overview',
      'segmentMetricsCurrentSpeed': 'Current speed',
      'segmentMetricsAverageSpeed': 'Segment avg',
      'segmentMetricsSpeedLimit': 'Speed limit',
      'segmentMetricsDistanceToStart': 'To segment start',
      'segmentMetricsDistanceToEnd': 'To segment end',
      'segmentMetricsSafeSpeed': 'Safe to finish',
      'segmentMetricsStatusTracking': 'Tracking segment',
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
      'syncRequiresInternetConnection':
          'Synchronizing toll segments requires an internet connection.',
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
    'bg': {
'appTitle': 'TollCam',
'backgroundTrackingNotificationRationale':
'Позволете известията, за да може Toll Cam Finder да остане активен във фонов режим.',
'chooseSegmentVisibilityQuestion':
'Искаш ли сегментът да бъде видим публично?',
'averageSpeedResetTooltip': 'Нулирай средната скорост',
'averageSpeedStartTooltip': 'Започни средната скорост',
'confirmKeepSegmentPrivate':
'Сигурен ли си, че искаш да запазиш сегмента само за себе си?',
'confirmMakeSegmentPublic':
'Сигурен ли си, че искаш да направиш този сегмент публичен?',
'confirmDeleteSegment':
'Сигурен ли си, че искаш да изтриеш сегмент {displayId}?',
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
      'createSegmentMissingFields':
          'Моля, попълни следните полета преди да запазиш: {fields}.',
      'createSegmentMissingFieldSegmentName': 'име на сегмента',
      'createSegmentMissingFieldStartCoordinates': 'начални координати',
      'createSegmentMissingFieldEndCoordinates': 'крайни координати',
      'createSegmentMissingFieldsDelimiter': ', ',
      'createSegmentMissingFieldsConjunction': 'и',
      'cancelAction': 'Отказ',
      'okAction': 'Добре',
      'deleteAction': 'Изтрий',
      'deleteSegmentAction': 'Изтрий сегмента',
      'deleteSegmentConfirmationTitle': 'Изтриване на сегмента',
      'failedToDeleteSegment': 'Неуспешно изтриване на сегмента.',
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
      'weighStations': 'Кантари',
      'createWeighStation': 'Добави кантар',
      'createWeighStationInstructions':
          'Докоснете картата, за да поставите маркера за кантара. Задръжте и плъзнете, за да коригирате позицията.',
      'weighStationCoordinatesInputLabel': 'Координати',
      'weighStationCoordinatesHint': '41.8626802,26.0873785',
      'saveWeighStation': 'Запази кантара',
      'failedToLoadWeighStations': 'Неуспешно зареждане на кантари.',
      'failedToAccessWeighStationsFile':
          'Неуспешен достъп до файла с кантарите: {reason}',
      'failedToDownloadWeighStations':
          'Неуспешно изтегляне на кантари: {reason}',
      'noWeighStationsAvailable': 'Няма налични кантари.',
      'failedToSaveWeighStationLocally':
          'Неуспешно запазване на кантара локално.',
      'failedToSubmitWeighStation':
          'Неуспешно изпращане на кантара за модерация.',
      'weighStationSubmittedForReview':
          'Кантарът е изпратен за преглед.',
      'weighStationIdentifier': 'Кантар {id}',
      'weighStationCoordinatesLabel': 'Координати: {coordinates}',
      'weighStationLocalBadge': 'Само локален',
      'weighStationMapHintPlace':
          'Докоснете картата, за да поставите кантара.',
      'weighStationMapHintDrag':
          'Задръжте и плъзнете маркера, за да коригирате кантара.',
      'deleteWeighStationAction': 'Изтрий кантара',
      'deleteWeighStationConfirmationTitle': 'Изтриване на кантара',
      'confirmDeleteWeighStation':
          'Сигурни ли сте, че искате да изтриете кантар {id}?',
      'weighStationDeleted': 'Кантар {id} беше изтрит.',
      'failedToDeleteWeighStation': 'Неуспешно изтриване на кантара.',
      'onlyLocalWeighStationsCanBeDeleted':
          'Само локално запазени кантари могат да бъдат изтрити.',
      'deletingLocalWeighStationsNotSupportedOnWeb':
          'Изтриването на локални кантари не се поддържа в уеб.',
      'emailLabel': 'Имейл адрес',
'fullNameLabel': 'Пълно име',
'joinTollCam': 'Присъедини се към TollCam',
'language': 'Език',
      'languageLabelEnglish': 'Английски',
      'languageLabelBulgarian': 'Български',
'languageButton': 'Смени езика',
'darkMode': 'Тъмен режим',
'localSegments': 'Локални сегменти',
'loginAction': 'Вход',
'logIn': 'Вход',
'logOut': 'Изход',
'loggedInRetrySavePrompt':
'Успешен вход. Натисни „Запази сегмента“ отново, за да изпратиш сегмента.',
'noAction': 'Не',
'noLocalSegments': 'Все още няма запазени локални сегменти.',
'noSegmentsAvailable': 'Няма налични сегменти.',
'openMenu': 'Отвори менюто',
'openNotificationSettingsAction': 'Отвори настройките',
'passwordLabel': 'Парола',
'profile': 'Профил',
'profileSubtitle': 'Управлявай акаунта и настройките си в TollCam.',
'faceTravelDirection': 'По посока на движение',
'northUp': 'Север нагоре',
'recenter': 'Центрирай Екрана',
'saveLocallyAction': 'Запази локално',
'saveSegment': 'Запази сегмента',
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
'segmentDeleted': 'Сегмент {displayId} е изтрит.',
'segmentProgressEndKilometers':
'{distance} км до края на сегмента',
'segmentProgressEndMeters': '{distance} м до края на сегмента',
'segmentProgressEndNearby': 'Краят на сегмента е близо',
'segmentProgressStartKilometers':
'{distance} км до началото на сегмента',
'segmentProgressStartMeters': '{distance} м до началото на сегмента',
'segmentProgressStartNearby': 'Началото на сегмента е близо',
'segments': 'Сегменти',
'segmentsOnlyModeTitle': 'Опростен режим',
'segmentsOnlyModeButton': 'Опростен режим',
'segmentsOnlyModeManualMessage':
'В момента използваш опростен режим. Използвай този екран, за да следиш показателите за сегментите без картата. Натисни бутона назад, за да се върнеш към картата.',
'segmentsOnlyModeOsmBlockedMessage':
'Не се притеснявай, опростен режим продължава да наблюдава сегментите и средната скорост, но тъй като приложението е безплатно, разчитаме на безплатни доставчици на карти, които в момента имат затруднения. Извиняваме се за неудобството и работим по отстраняването му.',
'segmentsOnlyModeOfflineMessage':
'Изглежда си офлайн. Ще продължим да следим сегментите и средната ти скорост, но картата изисква интернет връзка. Провери връзката си и се върни, когато отново имаш достъп.',
'segmentsOnlyModeContinueButton': 'Продължи към картата',
'segmentsOnlyModeReminder':
'Сегментите и средната скорост продължават да се обновяват, докато опростен режим е отворен.',
'selectLanguage': 'Избери език',
'signInToSharePubliclyBody':
'Трябва да си влязъл в акаунта си, за да изпратиш публичен сегмент. Искаш ли да влезеш или вместо това да запазиш сегмента локално?',
'signInToSharePubliclyTitle': 'Влез, за да споделиш публично',
'segmentDefaultStartName': 'Начало на {name}',
'segmentDefaultEndName': 'Край на {name}',
'segmentPickerStartMarkerLabel': 'A',
'segmentPickerEndMarkerLabel': 'B',
'segmentMissingCoordinates':
'Запазеният сегмент няма координати и не може да бъде споделен публично.',
      'segmentHidden':
          'Сегмент {displayId} е скрит. Камерите и предупрежденията са изключени.',
      'segmentBadgeHidden': 'Скрит',
      'segmentBadgeLocal': 'Локален',
      'segmentBadgeReview': 'В преглед',
      'segmentLocationStartLabel': 'Начало',
      'segmentLocationEndLabel': 'Край',
'segmentVisible':
'Сегмент {displayId} отново е видим. Камерите и предупрежденията са възстановени.',
'segmentVisibilityDisableSubtitle':
'Няма да се показват камери и предупреждения за този сегмент.',
'segmentVisibilityRestoreSubtitle':
'Камерите и предупрежденията за този сегмент ще бъдат възстановени.',
'hideSegmentOnMapAction': 'Скрий сегмента на картата',
'showSegmentOnMapAction': 'Покажи сегмента на картата',
'segmentNotFoundLocally': 'Сегментът не беше намерен локално.',
'personalSegmentDefaultName': 'Личен сегмент',
'onlySegmentsSavedLocallyCanBeShared':
'Само сегменти, запазени локално, могат да бъдат споделяни публично.',
'onlyLocalSegmentsCanBeDeleted':
'Само сегменти, запазени локално, могат да бъдат изтрити.',
'segmentAlreadyApprovedAndPublic':
'Сегмент {displayId} вече беше одобрен от администраторите и е публичен.',
'speedDialAverageTitle': 'Средна скорост',
'speedDialCurrentTitle': 'Скорост',
'speedDialDebugSummary': 'Сегменти: {count} r={radius}{unit}',
'speedDialLastSegmentAverage':
'Средна скорост на последния сегмент: {value}{unit}',
'speedDialLimitLabel': 'Лимит: {value} {unit}',
'speedDialNoActiveSegment': 'Няма активен сегмент',
'speedDialPlaceholder': '—',
'speedDialUnitKmh': 'км/ч',
'segmentMetricsHeading': 'Преглед на сегмента',
'segmentMetricsCurrentSpeed': 'Текуща скорост',
'segmentMetricsAverageSpeed': 'Средна за сегмента',
'segmentMetricsSpeedLimit': 'Ограничение на скоростта',
'segmentMetricsDistanceToStart': 'До началото',
'segmentMetricsDistanceToEnd': 'До края',
'segmentMetricsSafeSpeed': 'Безопасна скорост',
'segmentMetricsStatusTracking': 'Следене на сегмента',
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
      'syncRequiresInternetConnection':
          'Синхронизирането на сегменти изисква интернет връзка.',
      'audioModeTitle': 'Режим на аудио насоките',
      'audioModeFullGuidance':
          'Всички аудио насоки (в приложението и на заден план)',
      'audioModeForegroundMuted':
          'Заглушено в приложението (активно на заден план, само сигнал при старт/край)',
      'audioModeBackgroundMuted':
          'Заглушено на заден план (активно в приложението, само сигнал при старт/край)',
      'audioModeAbsoluteMute': 'Пълно заглушаване (без звук)',
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
'yesAction': 'Да',
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
  String get segmentsOnlyModeTitle => _value('segmentsOnlyModeTitle');
  String get segmentsOnlyModeButton => _value('segmentsOnlyModeButton');
  String get segmentsOnlyModeManualMessage =>
      _value('segmentsOnlyModeManualMessage');
  String get segmentsOnlyModeOsmBlockedMessage =>
      _value('segmentsOnlyModeOsmBlockedMessage');
  String get segmentsOnlyModeOfflineMessage =>
      _value('segmentsOnlyModeOfflineMessage');
  String get segmentsOnlyModeContinueButton =>
      _value('segmentsOnlyModeContinueButton');
  String get segmentsOnlyModeReminder =>
      _value('segmentsOnlyModeReminder');
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
  String get weighStations => _value('weighStations');
  String get createWeighStation => _value('createWeighStation');
  String get createWeighStationInstructions =>
      _value('createWeighStationInstructions');
  String get weighStationCoordinatesInputLabel =>
      _value('weighStationCoordinatesInputLabel');
  String get weighStationCoordinatesHint =>
      _value('weighStationCoordinatesHint');
  String get saveWeighStation => _value('saveWeighStation');
  String get failedToLoadWeighStations => _value('failedToLoadWeighStations');
  String get noWeighStationsAvailable =>
      _value('noWeighStationsAvailable');
  String get failedToSaveWeighStationLocally =>
      _value('failedToSaveWeighStationLocally');
  String get failedToSubmitWeighStation =>
      _value('failedToSubmitWeighStation');
  String get weighStationSubmittedForReview =>
      _value('weighStationSubmittedForReview');
  String weighStationIdentifier(String id) =>
      translate('weighStationIdentifier', {'id': id});
  String weighStationCoordinatesLabel(String coordinates) => translate(
        'weighStationCoordinatesLabel',
        {'coordinates': coordinates},
      );
  String get weighStationLocalBadge => _value('weighStationLocalBadge');
  String get weighStationMapHintPlace => _value('weighStationMapHintPlace');
  String get weighStationMapHintDrag => _value('weighStationMapHintDrag');
  String get saveSegment => _value('saveSegment');
  String get noSegmentsAvailable => _value('noSegmentsAvailable');
  String get noLocalSegments => _value('noLocalSegments');
  String get faceTravelDirection => _value('faceTravelDirection');
  String get northUp => _value('northUp');
  String get recenter => _value('recenter');
  String get languageButton => _value('languageButton');
  String get darkMode => _value('darkMode');
  String get audioModeTitle => _value('audioModeTitle');
  String get audioModeFullGuidance => _value('audioModeFullGuidance');
  String get audioModeForegroundMuted =>
      _value('audioModeForegroundMuted');
  String get audioModeBackgroundMuted =>
      _value('audioModeBackgroundMuted');
  String get audioModeAbsoluteMute => _value('audioModeAbsoluteMute');
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
