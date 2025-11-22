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
      'createSegmentInvalidSpeedLimit':
          'Please enter a valid speed limit using numbers only.',
      'createSegmentMapInstructionBody':
          'Drop or drag markers to adjust the start and end points. Coordinates are filled automatically as you move them.',
      'createSegmentMapInstructionTitle':
          'Set the start and end points on the map',
      'createSegmentNameHint': 'Segment name',
      'createSegmentNameLabel': 'Segment name',
      'createSegmentRoadNameHint': 'Road name',
      'createSegmentRoadNameLabel': 'Road name',
      'createSegmentSpeedLimitHint': 'e.g. 90',
      'createSegmentSpeedLimitLabel': 'Speed limit (km/h)',
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
          'Failed to publish the weigh station.',
      'weighStationPublished': 'Weigh station published.',
      'weighStationIdentifier': 'Weigh station {id}',
      'weighStationCoordinatesLabel': 'Coordinates: {coordinates}',
      'weighStationLocalBadge': 'Local only',
      'weighStationMapHintPlace':
          'Tap anywhere on the map to place the weigh station.',
      'weighStationMapHintDrag':
          'Long-press and drag the marker to adjust the weigh station.',
      'weighStationFeedbackTitle': 'Weigh station feedback',
      'weighStationUpvoteAction': 'Upvote',
      'weighStationDownvoteAction': 'Downvote',
      'weighStationUpvoteCount': 'Upvotes: {count}',
      'weighStationDownvoteCount': 'Downvotes: {count}',
          'weighStationApproachAlert':
              'You are approaching a station for weigh control.',
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
      'failedToPublishWeighStationWithReason':
          'Failed to publish the weigh station: {reason}',
      'failedToUpdateSegment':
          'Failed to update segment {displayId}: {errorMessage}',
      'failedToWriteSegmentsMetadataFile':
          'Failed to write to the segments metadata file.',
      'fullNameLabel': 'Full name',
      'hideSegmentOnMapAction': 'Hide segment on map',
      'joinTollCam': 'Join TollCam',
      'language': 'Language',
      'languageLabelEnglish': 'English',
      'languageLabelBulgarian': 'Български',
      'languageButton': 'Change language',
      'darkMode': 'Dark mode',
      'audioModeTitle': 'Guidance audio mode',
      'audioModeFullGuidance': 'Play all the time',
      'audioModeForegroundMuted': 'Mute in app',
      'audioModeBackgroundMuted': 'Mute in background mode',
      'audioModeAbsoluteMute': 'Mute all the time',
      'audioModeAbsoluteMuteConfirmationTitle':
          'Mute all voice guidance?',
      'audioModeAbsoluteMuteConfirmationBody':
          'If you mute all voice guidance, you will not receive alerts while driving when the app is in the foreground or background. Do you want to continue?',
      'audioModeBackgroundDisabledHelper':
          'Background location is off, so these options are unavailable.',
      'audioModeNotificationsDisabledHelper':
          'Notifications are blocked, so background alerts cannot play.',
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
      'noConnectionUnableToPublishWeighStation':
          'No internet connection. Unable to publish the weigh station.',
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
      'profileDangerZoneTitle': 'Danger zone',
      'profileDeleteAccountDescription':
          'Delete your account and all associated data.',
      'profileDeleteAccountAction': 'Delete account',
      'profileDeleteAccountConfirmTitle': 'Delete account?',
      'profileDeleteAccountConfirmBody':
          'Type DELETE to confirm. This action cannot be undone.',
      'profileDeleteAccountConfirmLabel': 'Type DELETE to confirm',
      'profileDeleteAccountConfirmHelper':
          'This will permanently remove your account.',
      'profileDeleteAccountMismatch':
          'Please type DELETE in all caps to continue.',
      'profileDeleteAccountSuccess': 'Your account was deleted.',
      'termsAndConditions': 'Terms & Conditions',
      'termsAcceptanceHeading': 'Acceptance of Terms',
      'termsAcceptanceBody':
          'By downloading, installing, or using TollCam you agree to these Terms & Conditions and confirm that any map, telemetry, or authentication calls executed by the app are initiated on your behalf. If you do not consent, uninstall the app and discontinue all use.',
      'termsThirdPartyHeading': 'Network Activity & Third-Party Services',
      'termsThirdPartyIntro':
          'To provide navigation, enforcement alerts, and account sync, TollCam must contact third parties using your device\'s connectivity. By continuing, you expressly authorize the app to send such requests on your behalf to:',
      'termsThirdPartyOsm':
          'OpenStreetMap (OSM) for map tiles, routing data, and speed-limit lookups.',
      'termsThirdPartySupabase':
          'Supabase for authentication, profile storage, telemetry sync, and moderation workflows.',
      'termsThirdPartyOther':
          'Additional infrastructure, analytics, or messaging providers that may be required to deliver existing or future features, each governed by its own terms.',
      'termsSpeedHeading': 'Speed Guidance Disclaimer',
      'termsSpeedBody':
          'Any speed thresholds, warnings, or recommended speeds that appear in the app are informational only. The development team does not condone speeding or aggressive driving, and you remain solely responsible for observing posted limits, traffic regulations, and law-enforcement directives. You accept that any fines, penalties, or consequences arising from your driving decisions are your own responsibility.',
      'termsUserResponsibilityHeading': 'User Responsibilities',
      'termsUserResponsibilityBody':
          'You must exercise independent judgment whenever you act on information provided by TollCam, ensure that location permissions are used lawfully, and stop using the app if it distracts you or interferes with safe vehicle operation.',
      'termsLiabilityHeading': 'Limitation of Liability',
      'termsLiabilityBody':
          'TollCam is provided on an "as is" and "as available" basis without warranties of any kind, whether express or implied. To the maximum extent permitted by applicable law, the developers and contributors disclaim all liability for direct, indirect, incidental, consequential, special, exemplary, or punitive damages, including but not limited to lost profits, loss of data, physical injury, or governmental sanctions that result from your access to or use of the app.',
      'termsChangesHeading': 'Changes to These Terms',
      'termsChangesBody':
          'The development team may update these Terms & Conditions from time to time. Material updates will be communicated through in-app notices or official release notes. Continued use of the app after an update constitutes acceptance of the revised terms.',
      'termsContactHeading': 'Contact',
      'termsContactBody':
          'For questions about these Terms & Conditions, reach out through the official TollCam communication channels or by contacting the development team through the in-app profile area.',
      'termsConsentLabel':
          'I have read and agree to the Terms & Conditions.',
      'termsViewDetails': 'View full terms',
      'termsConsentRequired':
          'Please accept the Terms & Conditions to continue.',
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
      'segmentBadgeApproved': 'Approved',
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
      'segmentMetricsSpeedLimit': 'Ticket-Free speed',
      'segmentMetricsDistanceToStart': 'To segment start',
      'segmentMetricsDistanceToEnd': 'To segment end',
      'segmentMetricsSafeSpeed': 'Ticket-Free speed',
      'introTitle': 'Welcome to TollSignal',
      'introSubtitle': '',
      'introInstructionsTitle': 'How guidance keeps you informed',
      'introInstructionsSyncTitle': 'Always up-to-date segments',
      'introInstructionsSyncBody':
          'When you open the app, it automatically synchronizes with our servers. If you want to double-check, you can tap "Synchronize" to ensure you have the latest updates for all segments. There’s no need to manually update the app — everything happens automatically.',
      'introInstructionsVoiceTitle': 'Voice alerts along the segment',
      'introInstructionsVoiceBody':
          'Audio prompts guide you without taking your eyes off the road:',
      'introInstructionsVoiceEnterTitle': 'Segment entry',
      'introInstructionsVoiceEnterBody':
          'We confirm the average speed monitoring has started.',
      'introInstructionsVoiceSpeedTitle': 'Average speed changes',
      'introInstructionsVoiceSpeedBody':
          'Reminders play if your speed exceeds the limit or returns to safe levels.',
      'introInstructionsVoiceApproachTitle': 'Approaching the finish',
      'introInstructionsVoiceApproachBody':
          'A heads-up plays in the final stretch so you can hold a safe pace.',
      'introInstructionsVoiceExitTitle': 'Segment complete',
      'introInstructionsVoiceExitBody':
          'We close the loop with your final average and whether you stayed within the limit.',
      'introMetricsTitle': 'Dashboard metrics',
      'introMetricCurrentSpeedTitle': 'Current speed',
      'introMetricCurrentSpeedBody':
          'Your live GPS speed so you always know how fast you\'re moving.',
      'introMetricAverageSpeedTitle': 'Segment average',
      'introMetricAverageSpeedBody':
          'The running average for the current segment.',
      'introMetricLimitTitle': 'Ticket-Free speed',
      'introMetricLimitBody':
          'Shows the speed You can maintain without risking a speeding ticket.',
      'introMetricDistanceTitle': 'Distance to start/end',
      'introMetricDistanceBody':
          'Distance to the start or end of the segment, depending on where you are.',
      'introSidebarTitle': 'What you can do from the menu',
      'introSidebarSyncTitle': 'Sync',
      'introSidebarSyncBody':
          'Download the latest public segments and weigh stations so you stay up to date offline.',
      'introSidebarSegmentsTitle': 'Segments',
      'introSidebarSegmentsBody':
          'Add new segments. You can keep personal ones without signing in, but you must log in to publish them publicly.',
      'introSidebarWeighStationsTitle': 'Weigh stations',
      'introSidebarWeighStationsBody':
          'Review nearby weigh stations or add your own. Signing in is required to publish them for everyone.',
      'introSidebarAudioTitle': 'Voice guidance',
      'introSidebarAudioBody':
          'Choose which voice alerts you hear and when they play during navigation.',
      'introSidebarLanguageTitle': 'Language',
      'introSidebarLanguageBody':
          'Switch the entire app between supported languages instantly.',
      'introSidebarProfileTitle': 'Profile & login',
      'introSidebarProfileBody':
          'Sign in or create an account. It\'s required to publish segments or weigh stations for the community.',
      'mapWelcomeTitle': 'Welcome to TollSignal',
      'mapWelcomeLanguagePrompt': 'Choose your language',
      'mapWeighStationsPromptTitle': 'Stations for weight control on the move?',
      'mapWeighStationsPromptDescription':
          'Do You want to see stations for weight control? You can change this anytime from the Weigh stations page.',
      'mapWeighStationsPromptEnableButton': 'Show weigh stations',
      'mapWeighStationsPromptSkipButton': 'Not now',
      'mapWeighStationsEnableButton': 'Enable weigh stations on map',
      'weighStationsVisibilitySettingTitle': 'Weigh stations on the map',
      'backgroundConsentTitle':
          'Keep TollCam running in the background?',
      'backgroundConsentBody':
          'We keep a small notification alive when you close the app so TollCam can continue monitoring nearby toll segments or weigh stations. We only read your precise location while alerts are active and do not share it except for the map tiles or routing needed for in-app navigation.',
      'backgroundConsentAllowTitle': 'Allow',
      'backgroundConsentAllowSubtitle':
          'Recommended. Runs a persistent notification so alerts keep working when the screen is off.',
      'backgroundConsentDenyTitle': 'Don\'t allow',
      'backgroundConsentDenySubtitle':
          'If you close the app we remove the notification and pause tracking, so no location is read and you will miss toll or weigh-station notifications until you reopen TollCam.',
      'backgroundConsentMenuHint':
          'You can adjust this anytime from the side menu.',
      'backgroundPermissionDeniedMessage':
          'Enable location access for TollCam in Android settings so we can keep working with the screen off. We only require the "While using the app" permission.',
      'locationDisclosureAgree': 'Agree',
      'locationDisclosureNotNow': 'Not now',
      'locationDisclosureSkip': 'Continue without background',
      'locationPermissionInfoTitle': 'Location access needed',
      'locationPermissionRequiredBody':
          'TollCam needs your precise location while the app is open to find toll segments or weigh stations nearby. Allow Android location access so alerts can start.',
      'locationPermissionOptOutBody':
          'Background alerts stay off until you change this choice. Enable them from the side menu whenever you want TollCam to keep a foreground notification running in the background.',
      'locationPermissionSettingsButton': 'Open app settings',
      'locationPermissionReviewDisclosure': 'Review in-app disclosure',
      'locationPermissionPromptButton': 'Allow location access',
      'notificationPermissionInfoTitle': 'Keep alert notifications on',
      'notificationPermissionRequiredBody':
          'We send heads-up alerts while TollCam runs in the background. Enable Android notifications so you don’t miss toll or weigh-station warnings.',
      'notificationPermissionSettingsButton': 'Open notification settings',
      'notificationPermissionPromptButton': 'Allow notifications',
      'backgroundLocationSettingTitle': 'Keep background alerts on',
      'backgroundLocationSettingDescription':
          'Runs a small notification and keeps precise alerts active when TollCam is in the background. Turn this off to stop all monitoring once you leave the app.',
      'introDismiss': 'Continue',
      'introMenuLabel': 'Show introduction',
      'segmentMetricsStatusTracking': 'Tracking segment',
      'segmentHandoverTitle': 'New zone started',
      'segmentHandoverPreviousAverage': 'Prev avg {value} {unit}',
      'segmentHandoverPreviousLimit': 'Prev limit {value} {unit}',
      'segmentHandoverNextLimit': 'Next limit {value} {unit}',
      'segmentHandoverNoNextSegment': 'Segment ended',
      'segmentHandoverUnknownValue': '--',
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
      'supabaseNotConfiguredForWeighStationPublishing':
          'Supabase is not configured. Unable to publish weigh stations.',
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
      'unableToDeleteAccountTryAgain':
          'Unable to delete your account. Please try again.',
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
      'unexpectedErrorPublishingWeighStation':
          'Unexpected error while publishing the weigh station.',
      'unexpectedSyncError': 'Unexpected error while syncing toll segments.',
      'fileSystemOperationsNotSupported':
          'File system operations are not supported on this platform.',
      'unitKilometersShort': 'km',
      'unitMetersShort': 'm',
      'unknownUserLabel': 'Unknown user',
      'userRequiredForPublicModeration':
          'A logged in user is required to submit a public segment for moderation.',
      'userRequiredForWeighStationPublishing':
          'A logged in user is required to publish weigh stations.',
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
      'createSegmentInvalidSpeedLimit':
          'Моля, въведи валидно ограничение на скоростта, използвайки само числа.',
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
'createSegmentSpeedLimitHint': 'напр. 90',
'createSegmentSpeedLimitLabel': 'Ограничение на скоростта (км/ч)',
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
          'Неуспешно публикуване на кантара.',
      'noConnectionUnableToPublishWeighStation':
          'Няма интернет връзка. Кантарът не може да бъде публикуван.',
      'failedToPublishWeighStationWithReason':
          'Неуспешно публикуване на кантара: {reason}',
      'unexpectedErrorPublishingWeighStation':
          'Неочаквана грешка при публикуване на кантара.',
      'weighStationPublished': 'Кантарът беше публикуван.',
      'weighStationIdentifier': 'Кантар {id}',
      'weighStationCoordinatesLabel': 'Координати: {coordinates}',
      'weighStationLocalBadge': 'Само локален',
      'weighStationMapHintPlace':
          'Докоснете картата, за да поставите кантара.',
      'weighStationMapHintDrag':
          'Задръжте и плъзнете маркера, за да коригирате кантара.',
      'weighStationFeedbackTitle': 'Обратна връзка за кантара',
      'weighStationUpvoteAction': 'Положителен вот',
      'weighStationDownvoteAction': 'Отрицателен вот',
      'weighStationUpvoteCount': 'Положителни гласове: {count}',
      'weighStationDownvoteCount': 'Отрицателни гласове: {count}',
      'weighStationApproachAlert': 'Приближавате кантар.',
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
      'languageLabelEnglish': 'English',
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
'profileDangerZoneTitle': 'Опасна зона',
'profileDeleteAccountDescription':
'Изтрий акаунта си и всички свързани данни.',
'profileDeleteAccountAction': 'Изтрий акаунта',
'profileDeleteAccountConfirmTitle': 'Да изтрия ли акаунта?',
'profileDeleteAccountConfirmBody':
'Напиши DELETE, за да потвърдиш. Това действие е необратимо.',
'profileDeleteAccountConfirmLabel': 'Въведи DELETE за потвърждение',
'profileDeleteAccountConfirmHelper':
'След изтриване няма връщане.',
'profileDeleteAccountMismatch': 'Моля, напиши DELETE с главни букви.',
'profileDeleteAccountSuccess': 'Акаунтът ти беше изтрит.',
      'termsAndConditions': 'Общи условия',
      'termsAcceptanceHeading': 'Приемане на условията',
      'termsAcceptanceBody':
          'С изтеглянето, инсталирането или използването на TollCam приемате настоящите Общи условия и потвърждавате, че всички картни, телеметрични или автентикационни заявки, които приложението изпраща, се извършват от ваше име. Ако не сте съгласни, деинсталирайте приложението и прекратете използването му.',
      'termsThirdPartyHeading':
          'Мрежова активност и външни услуги',
      'termsThirdPartyIntro':
          'За да осигурява навигация, предупреждения и синхронизиране на акаунти, TollCam извършва заявки чрез вашата интернет връзка. С продължаването на ползването изрично упълномощавате приложението да изпраща от ваше име заявки към:',
      'termsThirdPartyOsm':
          'OpenStreetMap (OSM) за картни плочки, маршрутни данни и справки за ограничение на скоростта.',
      'termsThirdPartySupabase':
          'Supabase за удостоверяване, съхранение на профил, синхронизация на телеметрия и процеси по модерация.',
      'termsThirdPartyOther':
          'Допълнителни инфраструктурни, аналитични или комуникационни доставчици, необходими за текущи или бъдещи функционалности, като всеки от тях се регулира от собствените си условия.',
      'termsSpeedHeading': 'Опровержение относно скоростта',
      'termsSpeedBody':
          'Всички прагове, предупреждения или препоръчителни скорости в приложението имат само информативен характер. Разработчиците не насърчават и не оправдават превишаване на скоростта или агресивно шофиране и вие сте единственият отговорен да спазвате ограничителните знаци, правилата за движение и указанията на органите на реда. Приемате, че всички глоби, санкции или последици, произтичащи от вашите решения при шофиране, са изцяло за ваша сметка.',
      'termsUserResponsibilityHeading': 'Отговорности на потребителя',
      'termsUserResponsibilityBody':
          'Винаги трябва да прилагате самостоятелна преценка при използване на информацията от TollCam, да гарантирате, че позволенията за местоположение се използват законосъобразно, и да преустановите използването на приложението, ако ви разсейва или затруднява безопасното управление на превозното средство.',
      'termsLiabilityHeading': 'Ограничаване на отговорността',
      'termsLiabilityBody':
          'TollCam се предоставя \"както е\" и \"според наличността\", без изрични или подразбиращи се гаранции. До максимално допустимата степен от приложимото право разработчиците и приносителите се освобождават от всякаква отговорност за преки, непреки, последващи, специални, примерни или наказателни вреди, включително, но не само пропуснати ползи, загубени данни, телесни повреди или административни санкции, произтичащи от достъпа до приложението или използването му.',
      'termsChangesHeading': 'Промени в условията',
      'termsChangesBody':
          'Екипът може периодично да актуализира тези Общи условия. Съществени промени ще бъдат съобщавани чрез уведомления в приложението или официални бележки към версиите. Продължаващото използване на приложението след актуализация означава, че приемате преработените условия.',
      'termsContactHeading': 'Контакт',
      'termsContactBody':
          'При въпроси относно настоящите Общи условия се свържете с екипа на TollCam чрез официалните комуникационни канали или чрез секцията за профила в приложението.',
      'termsConsentLabel': 'Прочетох и приемам Общите условия.',
      'termsViewDetails': 'Виж пълните условия',
      'termsConsentRequired':
          'Моля, приеми Общите условия, за да продължиш.',
'unableToDeleteAccountTryAgain':
'Неуспешно изтриване на акаунта. Опитай отново.',
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
      'segmentBadgeApproved': 'Одобрен',
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
'segmentMetricsSpeedLimit': 'Скорост без фиш',
'segmentMetricsDistanceToStart': 'До началото',
'segmentMetricsDistanceToEnd': 'До края',
'segmentMetricsSafeSpeed': 'Скорост без фиш',
'introTitle': 'Добре дошли в TollSignal',
      'introSubtitle': '',
      'introInstructionsTitle': 'Как ви информираме по време на път',
      'introInstructionsSyncTitle': 'Винаги актуални сегменти',
      'introInstructionsSyncBody':
          'Когато отворите приложението, то автоматично се синхронизира с нашите сървъри. Ако искате да сте сигурни, може да натиснете „Синхронизирай“, за да получите най-новите актуализации за всички сегменти. Не е необходимо да ъпдейтвате ръчно приложението ръчно приложението — всичко се случва автоматично.',
      'introInstructionsVoiceTitle': 'Гласови съобщения в сегмента',
      'introInstructionsVoiceBody':
          'Гласовите подсказки ви насочват, без да сваляте очи от пътя:',
      'introInstructionsVoiceEnterTitle': 'При влизане в сегмента',
      'introInstructionsVoiceEnterBody':
          'Потвърждаваме, че следим средната скорост.',
      'introInstructionsVoiceSpeedTitle': 'Промяна на средната скорост',
      'introInstructionsVoiceSpeedBody':
          'Получавате напомняния всеки път, когато превишите лимита или се върнете към безопасна средна скорост.',
      'introInstructionsVoiceApproachTitle': 'При наближаване на края',
      'introInstructionsVoiceApproachBody':
          'Напомняне в последните метри, за да задържите безопасно темпо.',
      'introInstructionsVoiceExitTitle': 'Край на сегмента',
      'introInstructionsVoiceExitBody':
          'Финално съобщение, което Ви информира за края на сегмента и дали сте спазили лимита.',
      'introMetricsTitle': 'Показатели на таблото',
'introMetricCurrentSpeedTitle': 'Текуща скорост',
'introMetricCurrentSpeedBody':
'Показва моментната Ви скорост.',
'introMetricAverageSpeedTitle': 'Средна скорост в сегмента',
'introMetricAverageSpeedBody':
'Средната скорост за активния тол сегмент от началото на измерването.',
'introMetricLimitTitle': 'скорост без фиш',
'introMetricLimitBody':
'Показва скоростта която трябва да поддържате, за да завършите сегмента в допустимата средна скорост.',
'introMetricDistanceTitle': 'Разстояние до начало/край',
'introMetricDistanceBody':
'Разстоянието до началото или края на сегмента според текущата ви позиция.',
'introSidebarTitle': 'Какво можете да правите от менюто',
'introSidebarSyncTitle': 'Синхронизирай',
'introSidebarSyncBody':
'Изтеглете най-новите публични сегменти и кантари, за да сте актуални офлайн.',
'introSidebarSegmentsTitle': 'Сегменти',
'introSidebarSegmentsBody':
'Добавяйте нови сегменти. Можете да пазите лични без да създавате акаунт, но за публично споделяне е необходим акаунт.',
'introSidebarWeighStationsTitle': 'Кантари',
'introSidebarWeighStationsBody':
'Разглеждайте близките кантари или добавяйте свои. За публикуване е нужен акаунт.',
'introSidebarAudioTitle': 'Гласови съобщения',
'introSidebarAudioBody':
'Изберете кои гласови известия да чувате и кога да се възпроизвеждат.',
'introSidebarLanguageTitle': 'Език',
'introSidebarLanguageBody':
'Сменете езика на приложението по всяко време.',
'introSidebarProfileTitle': 'Профил и вход',
'introSidebarProfileBody':
'Влезте или създайте акаунт. Необходимо е за публикуване на сегменти и кантари.',
'mapWelcomeTitle': 'Добре дошли в TollSignal',
'mapWelcomeLanguagePrompt': 'Изберете вашия език',
'mapWeighStationsPromptTitle': 'Станции за измерване на теглото в движение?',
'mapWeighStationsPromptDescription':
'Искате ли да показваме близките станции за измерване на тегло в движение. Можете да промените избора си по всяко време от страницата „Кантари“.',
'mapWeighStationsPromptEnableButton': 'Показвай кантари',
'mapWeighStationsPromptSkipButton': 'Не сега',
'mapWeighStationsEnableButton': 'Активирай кантари на картата',
'weighStationsVisibilitySettingTitle': 'Кантари на картата',
'backgroundConsentTitle': 'Да поддържаме TollCam активен във фона?',
'backgroundConsentBody':
'Показваме малко известие, когато затворите приложението, за да продължим да следим близките тол сегменти и кантари. Четем точната ви локация само докато предупрежденията са активни и не я споделяме, освен за картите и маршрутизацията в приложението.',
'backgroundConsentAllowTitle': 'Позволи',
'backgroundConsentAllowSubtitle':
'Препоръчително. Поддържа постоянно известие, за да работят предупрежденията дори при изключен екран.',
'backgroundConsentDenyTitle': 'Не позволявай',
'backgroundConsentDenySubtitle':
'Когато затворите приложението, известието изчезва и спираме фоновото проследяване, така че няма да четем локация и ще изпускате тол или кантар известия, докато не отворите TollCam отново.',
'backgroundConsentMenuHint': 'Можете да промените избора си по всяко време от страничното меню.',
'backgroundPermissionDeniedMessage':
'Разрешете достъп до локацията за TollCam в настройките на Android, за да продължим да работим с изключен екран. Нуждаем се само от разрешението „Докато използвате приложението“.',
'locationDisclosureAgree': 'Съгласен съм',
'locationDisclosureNotNow': 'Не сега',
'locationDisclosureSkip': 'Продължи без фонова локация',
'locationPermissionInfoTitle': 'Необходим е достъп до местоположението',
'locationPermissionRequiredBody':
    'TollCam се нуждае от точната Ви локация, докато приложението е отворено, за да открива тол сегменти и кантари наблизо. Разрешете достъп до местоположението в Android, за да започнат предупрежденията.',
'locationPermissionOptOutBody':
    'Фоновите известия са изключени според Вашия избор. Можете да ги активирате от страничното меню, когато сте готови TollCam да поддържа известие и да следи във фона.',
'locationPermissionSettingsButton': 'Отвори настройките на приложението',
'locationPermissionReviewDisclosure': 'Преглед на изискването за локация',
'locationPermissionPromptButton': 'Разреши достъп до локацията',
'notificationPermissionInfoTitle': 'Разрешете известията',
'notificationPermissionRequiredBody':
    'Изпращаме предупреждения, когато приложението работи във фонов режим. Разрешете уведомленията в Android, за да не пропускате тол или кантар сигнали.',
'notificationPermissionSettingsButton': 'Отвори настройките за известия',
'notificationPermissionPromptButton': 'Разреши известията',
'backgroundLocationSettingTitle': 'Фонови предупреждения',
'backgroundLocationSettingDescription':
'Показва малко известие и пази точните предупреждения активни, докато TollCam работи във фона. Изключете го, ако искате да спрем следенето, когато напуснете приложението.',
'introDismiss': 'Започни',
'introMenuLabel': 'Въведение',
'segmentMetricsStatusTracking': 'Следене на сегмента',
'segmentHandoverTitle': 'Нова зона',
'segmentHandoverPreviousAverage': 'Предишна средна {value} {unit}',
'segmentHandoverPreviousLimit': 'Предишно ограничение {value} {unit}',
'segmentHandoverNextLimit': 'Следващо ограничение {value} {unit}',
'segmentHandoverNoNextSegment': 'Сегментът приключи',
'segmentHandoverUnknownValue': '--',
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
      'supabaseNotConfiguredForModeration':
          'Supabase не е конфигуриран. Не могат да се изпращат сегменти за модерация.',
      'supabaseNotConfiguredForWeighStationPublishing':
          'Supabase не е конфигуриран. Не могат да се публикуват кантари.',
      'supabaseNotConfiguredForPublicSubmissions':
          'Supabase не е конфигуриран. Не могат да се управляват публични изпращания.',
      'userRequiredForPublicModeration':
          'Необходим е влязъл потребител, за да изпрати публичен сегмент за модерация.',
      'userRequiredForWeighStationPublishing':
          'Необходим е влязъл потребител, за да публикува кантар.',
      'audioModeTitle': 'Режим на аудио насоките',
      'audioModeFullGuidance': 'Възпроизвеждане през цялото време',
      'audioModeForegroundMuted': 'Заглушено в приложението',
      'audioModeBackgroundMuted': 'Заглушено във фонов режим',
      'audioModeAbsoluteMute': 'Заглушено през цялото време',
      'audioModeAbsoluteMuteConfirmationTitle':
          'Изключване на всички гласови предупреждения?',
      'audioModeAbsoluteMuteConfirmationBody':
          'Ако изключиш всички гласови предупреждения, няма да получаваш известия нито когато приложението е на преден план, нито във фонов режим. Искаш ли да продължиш?',
      'audioModeBackgroundDisabledHelper':
          'Фоновата локация е изключена, затова тези опции не са налични.',
      'audioModeNotificationsDisabledHelper':
          'Известията са блокирани, затова фоновите предупреждения не могат да звучат.',
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
  String get weighStationPublished => _value('weighStationPublished');
  String weighStationIdentifier(String id) =>
      translate('weighStationIdentifier', {'id': id});
  String weighStationCoordinatesLabel(String coordinates) => translate(
        'weighStationCoordinatesLabel',
        {'coordinates': coordinates},
      );
  String get weighStationLocalBadge => _value('weighStationLocalBadge');
  String get weighStationMapHintPlace => _value('weighStationMapHintPlace');
  String get weighStationMapHintDrag => _value('weighStationMapHintDrag');
  String get weighStationFeedbackTitle => _value('weighStationFeedbackTitle');
  String get weighStationUpvoteAction => _value('weighStationUpvoteAction');
  String get weighStationDownvoteAction =>
      _value('weighStationDownvoteAction');
  String weighStationUpvoteCount(int count) => translate(
        'weighStationUpvoteCount',
        {'count': '$count'},
      );
  String weighStationDownvoteCount(int count) => translate(
        'weighStationDownvoteCount',
        {'count': '$count'},
      );
  String get weighStationApproachAlert =>
      _value('weighStationApproachAlert');
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
  String get audioModeAbsoluteMuteConfirmationTitle =>
      _value('audioModeAbsoluteMuteConfirmationTitle');
  String get audioModeAbsoluteMuteConfirmationBody =>
      _value('audioModeAbsoluteMuteConfirmationBody');
  String get audioModeBackgroundDisabledHelper =>
      _value('audioModeBackgroundDisabledHelper');
  String get audioModeNotificationsDisabledHelper =>
      _value('audioModeNotificationsDisabledHelper');
  String get welcomeTitle => _value('welcomeTitle');
  String get joinTollCam => _value('joinTollCam');
  String get emailLabel => _value('emailLabel');
  String get passwordLabel => _value('passwordLabel');
  String get confirmPasswordLabel => _value('confirmPasswordLabel');
  String get fullNameLabel => _value('fullNameLabel');
  String get profileSubtitle => _value('profileSubtitle');
  String get profileDangerZoneTitle => _value('profileDangerZoneTitle');
  String get profileDeleteAccountDescription =>
      _value('profileDeleteAccountDescription');
  String get profileDeleteAccountAction =>
      _value('profileDeleteAccountAction');
  String get profileDeleteAccountConfirmTitle =>
      _value('profileDeleteAccountConfirmTitle');
  String get profileDeleteAccountConfirmBody =>
      _value('profileDeleteAccountConfirmBody');
  String get profileDeleteAccountConfirmLabel =>
      _value('profileDeleteAccountConfirmLabel');
  String get profileDeleteAccountConfirmHelper =>
      _value('profileDeleteAccountConfirmHelper');
  String get profileDeleteAccountMismatch =>
      _value('profileDeleteAccountMismatch');
  String get profileDeleteAccountSuccess =>
      _value('profileDeleteAccountSuccess');
  String get termsAndConditions => _value('termsAndConditions');
  String get termsAcceptanceHeading => _value('termsAcceptanceHeading');
  String get termsAcceptanceBody => _value('termsAcceptanceBody');
  String get termsThirdPartyHeading => _value('termsThirdPartyHeading');
  String get termsThirdPartyIntro => _value('termsThirdPartyIntro');
  String get termsThirdPartyOsm => _value('termsThirdPartyOsm');
  String get termsThirdPartySupabase => _value('termsThirdPartySupabase');
  String get termsThirdPartyOther => _value('termsThirdPartyOther');
  String get termsSpeedHeading => _value('termsSpeedHeading');
  String get termsSpeedBody => _value('termsSpeedBody');
  String get termsUserResponsibilityHeading =>
      _value('termsUserResponsibilityHeading');
  String get termsUserResponsibilityBody =>
      _value('termsUserResponsibilityBody');
  String get termsLiabilityHeading => _value('termsLiabilityHeading');
  String get termsLiabilityBody => _value('termsLiabilityBody');
  String get termsChangesHeading => _value('termsChangesHeading');
  String get termsChangesBody => _value('termsChangesBody');
  String get termsContactHeading => _value('termsContactHeading');
  String get termsContactBody => _value('termsContactBody');
  String get termsConsentLabel => _value('termsConsentLabel');
  String get termsViewDetails => _value('termsViewDetails');
  String get termsConsentRequired => _value('termsConsentRequired');
  String get unknownUserLabel => _value('unknownUserLabel');
  String get averageSpeedStartTooltip => _value('averageSpeedStartTooltip');
  String get averageSpeedResetTooltip => _value('averageSpeedResetTooltip');
  String get speedDialCurrentTitle => _value('speedDialCurrentTitle');
  String get speedDialAverageTitle => _value('speedDialAverageTitle');
  String get speedDialUnitKmh => _value('speedDialUnitKmh');
  String get segmentHandoverTitle => _value('segmentHandoverTitle');
  String segmentHandoverPreviousAverage(String value, String unit) => translate(
        'segmentHandoverPreviousAverage',
        {'value': value, 'unit': unit},
      );
  String segmentHandoverPreviousLimit(String value, String unit) => translate(
        'segmentHandoverPreviousLimit',
        {'value': value, 'unit': unit},
      );
  String segmentHandoverNextLimit(String value, String unit) => translate(
        'segmentHandoverNextLimit',
        {'value': value, 'unit': unit},
      );
  String get segmentHandoverNoNextSegment =>
      _value('segmentHandoverNoNextSegment');
  String get segmentHandoverUnknownValue => _value('segmentHandoverUnknownValue');
  String get speedDialNoActiveSegment => _value('speedDialNoActiveSegment');
  String get introTitle => _value('introTitle');
  String get introSubtitle => _value('introSubtitle');
  String get introInstructionsTitle => _value('introInstructionsTitle');
  String get introInstructionsSyncTitle =>
      _value('introInstructionsSyncTitle');
  String get introInstructionsSyncBody =>
      _value('introInstructionsSyncBody');
  String get introInstructionsVoiceTitle =>
      _value('introInstructionsVoiceTitle');
  String get introInstructionsVoiceBody =>
      _value('introInstructionsVoiceBody');
  String get introInstructionsVoiceEnterTitle =>
      _value('introInstructionsVoiceEnterTitle');
  String get introInstructionsVoiceEnterBody =>
      _value('introInstructionsVoiceEnterBody');
  String get introInstructionsVoiceSpeedTitle =>
      _value('introInstructionsVoiceSpeedTitle');
  String get introInstructionsVoiceSpeedBody =>
      _value('introInstructionsVoiceSpeedBody');
  String get introInstructionsVoiceApproachTitle =>
      _value('introInstructionsVoiceApproachTitle');
  String get introInstructionsVoiceApproachBody =>
      _value('introInstructionsVoiceApproachBody');
  String get introInstructionsVoiceExitTitle =>
      _value('introInstructionsVoiceExitTitle');
  String get introInstructionsVoiceExitBody =>
      _value('introInstructionsVoiceExitBody');
  String get introMetricsTitle => _value('introMetricsTitle');
  String get introMetricCurrentSpeedTitle =>
      _value('introMetricCurrentSpeedTitle');
  String get introMetricCurrentSpeedBody =>
      _value('introMetricCurrentSpeedBody');
  String get introMetricAverageSpeedTitle =>
      _value('introMetricAverageSpeedTitle');
  String get introMetricAverageSpeedBody =>
      _value('introMetricAverageSpeedBody');
  String get introMetricLimitTitle => _value('introMetricLimitTitle');
  String get introMetricLimitBody => _value('introMetricLimitBody');
  String get introMetricDistanceTitle =>
      _value('introMetricDistanceTitle');
  String get introMetricDistanceBody =>
      _value('introMetricDistanceBody');
  String get introSidebarTitle => _value('introSidebarTitle');
  String get introSidebarSyncTitle => _value('introSidebarSyncTitle');
  String get introSidebarSyncBody => _value('introSidebarSyncBody');
  String get introSidebarSegmentsTitle =>
      _value('introSidebarSegmentsTitle');
  String get introSidebarSegmentsBody =>
      _value('introSidebarSegmentsBody');
  String get introSidebarWeighStationsTitle =>
      _value('introSidebarWeighStationsTitle');
  String get introSidebarWeighStationsBody =>
      _value('introSidebarWeighStationsBody');
  String get introSidebarAudioTitle => _value('introSidebarAudioTitle');
  String get introSidebarAudioBody => _value('introSidebarAudioBody');
  String get introSidebarLanguageTitle =>
      _value('introSidebarLanguageTitle');
  String get introSidebarLanguageBody =>
      _value('introSidebarLanguageBody');
  String get introSidebarProfileTitle =>
      _value('introSidebarProfileTitle');
  String get introSidebarProfileBody =>
      _value('introSidebarProfileBody');
  String get mapWelcomeTitle => _value('mapWelcomeTitle');
  String get mapWelcomeLanguagePrompt =>
      _value('mapWelcomeLanguagePrompt');
  String get mapWeighStationsPromptTitle =>
      _value('mapWeighStationsPromptTitle');
  String get mapWeighStationsPromptDescription =>
      _value('mapWeighStationsPromptDescription');
  String get mapWeighStationsPromptEnableButton =>
      _value('mapWeighStationsPromptEnableButton');
  String get mapWeighStationsPromptSkipButton =>
      _value('mapWeighStationsPromptSkipButton');
  String get mapWeighStationsEnableButton =>
      _value('mapWeighStationsEnableButton');
  String get weighStationsVisibilitySettingTitle =>
      _value('weighStationsVisibilitySettingTitle');
  String get backgroundConsentTitle =>
      _value('backgroundConsentTitle');
  String get backgroundConsentBody =>
      _value('backgroundConsentBody');
  String get backgroundConsentAllowTitle =>
      _value('backgroundConsentAllowTitle');
  String get backgroundConsentAllowSubtitle =>
      _value('backgroundConsentAllowSubtitle');
  String get backgroundConsentDenyTitle =>
      _value('backgroundConsentDenyTitle');
  String get backgroundConsentDenySubtitle =>
      _value('backgroundConsentDenySubtitle');
  String get backgroundConsentMenuHint =>
      _value('backgroundConsentMenuHint');
  String get backgroundPermissionDeniedMessage =>
      _value('backgroundPermissionDeniedMessage');
  String get locationDisclosureAgree =>
      _value('locationDisclosureAgree');
  String get locationDisclosureNotNow =>
      _value('locationDisclosureNotNow');
  String get locationDisclosureSkip =>
      _value('locationDisclosureSkip');
  String get locationPermissionInfoTitle =>
      _value('locationPermissionInfoTitle');
  String get locationPermissionRequiredBody =>
      _value('locationPermissionRequiredBody');
  String get locationPermissionOptOutBody =>
      _value('locationPermissionOptOutBody');
  String get locationPermissionSettingsButton =>
      _value('locationPermissionSettingsButton');
  String get locationPermissionReviewDisclosure =>
      _value('locationPermissionReviewDisclosure');
  String get locationPermissionPromptButton =>
      _value('locationPermissionPromptButton');
  String get notificationPermissionInfoTitle =>
      _value('notificationPermissionInfoTitle');
  String get notificationPermissionRequiredBody =>
      _value('notificationPermissionRequiredBody');
  String get notificationPermissionSettingsButton =>
      _value('notificationPermissionSettingsButton');
  String get notificationPermissionPromptButton =>
      _value('notificationPermissionPromptButton');
  String get backgroundLocationSettingTitle =>
      _value('backgroundLocationSettingTitle');
  String get backgroundLocationSettingDescription =>
      _value('backgroundLocationSettingDescription');
  String get introDismiss => _value('introDismiss');
  String get introMenuLabel => _value('introMenuLabel');
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
