import 'dart:ui';

import '../app/localization/app_localizations.dart';

class AppMessages {
  AppMessages._();

  static Locale _locale = const Locale('en');
  static AppLocalizations _localizations = AppLocalizations(_locale);

  static void updateLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    _localizations = AppLocalizations(locale);
  }

  static AppLocalizations get _l => _localizations;

  static String get segmentSavedLocally =>
      _l.translate('segmentSavedLocally');
  static String get showSegmentOnMapAction =>
      _l.translate('showSegmentOnMapAction');
  static String get hideSegmentOnMapAction =>
      _l.translate('hideSegmentOnMapAction');
  static String get segmentVisibilityRestoreSubtitle =>
      _l.translate('segmentVisibilityRestoreSubtitle');
  static String get segmentVisibilityDisableSubtitle =>
      _l.translate('segmentVisibilityDisableSubtitle');
  static String segmentHidden(String displayId) =>
      _l.translate('segmentHidden', {'displayId': displayId});
  static String segmentVisible(String displayId) =>
      _l.translate('segmentVisible', {'displayId': displayId});
  static String failedToUpdateSegment(
    String displayId,
    String errorMessage,
  ) =>
      _l.translate('failedToUpdateSegment', {
        'displayId': displayId,
        'errorMessage': errorMessage,
      });
  static String get signInToShareSegment =>
      _l.translate('signInToShareSegment');
  static String get shareSegmentPubliclyAction =>
      _l.translate('shareSegmentPubliclyAction');
  static String get publicSharingUnavailable =>
      _l.translate('publicSharingUnavailable');
  static String get publicSharingUnavailableShort =>
      _l.translate('publicSharingUnavailableShort');
  static String get submitSegmentForPublicReviewSubtitle =>
      _l.translate('submitSegmentForPublicReviewSubtitle');
  static String get unableToDetermineLoggedInAccount =>
      _l.translate('unableToDetermineLoggedInAccount');
  static String get failedToPrepareSegmentForReview =>
      _l.translate('failedToPrepareSegmentForReview');
  static String get failedToCheckSubmissionStatus =>
      _l.translate('failedToCheckSubmissionStatus');
  static String get failedToSubmitForModeration =>
      _l.translate('failedToSubmitForModeration');
  static String segmentAlreadyAwaitingReview(String displayId) =>
      _l.translate('segmentAlreadyAwaitingReview', {'displayId': displayId});
  static String segmentSubmittedForPublicReview(String displayId) =>
      _l.translate('segmentSubmittedForPublicReview', {'displayId': displayId});
  static String get segmentSubmittedForPublicReviewGeneric =>
      _l.translate('segmentSubmittedForPublicReviewGeneric');
  static String get unableToWithdrawSubmission =>
      _l.translate('unableToWithdrawSubmission');
  static String get signInToWithdrawSubmission =>
      _l.translate('signInToWithdrawSubmission');
  static String segmentNoLongerUnderReview(String displayId) =>
      _l.translate('segmentNoLongerUnderReview', {'displayId': displayId});
  static String get noConnectionCannotWithdrawSubmission =>
      _l.translate('noConnectionCannotWithdrawSubmission');
  static String get failedToCancelPublicReview =>
      _l.translate('failedToCancelPublicReview');
  static String get failedToDeleteSegment =>
      _l.translate('failedToDeleteSegment');
  static String get deleteSegmentAction =>
      _l.translate('deleteSegmentAction');
  static String get onlyLocalSegmentsCanBeDeleted =>
      _l.translate('onlyLocalSegmentsCanBeDeleted');
  static String segmentDeleted(String displayId) =>
      _l.translate('segmentDeleted', {'displayId': displayId});
  static String get deleteSegmentConfirmationTitle =>
      _l.translate('deleteSegmentConfirmationTitle');
  static String confirmDeleteSegment(String displayId) =>
      _l.translate('confirmDeleteSegment', {'displayId': displayId});
  static String get unableToDetermineLoggedInAccountRetry =>
      _l.translate('unableToDetermineLoggedInAccountRetry');
  static String get chooseSegmentVisibilityQuestion =>
      _l.translate('chooseSegmentVisibilityQuestion');
  static String get confirmKeepSegmentPrivate =>
      _l.translate('confirmKeepSegmentPrivate');
  static String get confirmMakeSegmentPublic =>
      _l.translate('confirmMakeSegmentPublic');
  static String get withdrawPublicSubmissionTitle =>
      _l.translate('withdrawPublicSubmissionTitle');
  static String get withdrawPublicSubmissionMessage =>
      _l.translate('withdrawPublicSubmissionMessage');
  static String get somethingWentWrongTryAgain =>
      _l.translate('somethingWentWrongTryAgain');
  static String get accountCreatedCheckEmail =>
      _l.translate('accountCreatedCheckEmail');
  static String get unableToLogOutTryAgain =>
      _l.translate('unableToLogOutTryAgain');
  static String get authenticationNotConfigured =>
      _l.translate('authenticationNotConfigured');
  static String get unexpectedErrorSigningIn =>
      _l.translate('unexpectedErrorSigningIn');
  static String get unexpectedErrorCreatingAccount =>
      _l.translate('unexpectedErrorCreatingAccount');
  static String get unexpectedErrorSigningOut =>
      _l.translate('unexpectedErrorSigningOut');
  static String get enterYourName => _l.translate('enterYourName');
  static String get enterYourEmail => _l.translate('enterYourEmail');
  static String get enterYourPassword => _l.translate('enterYourPassword');
  static String get confirmYourPassword =>
      _l.translate('confirmYourPassword');
  static String get createPasswordPrompt =>
      _l.translate('createPasswordPrompt');
  static String get passwordTooShort => _l.translate('passwordTooShort');
  static String get passwordsDoNotMatch =>
      _l.translate('passwordsDoNotMatch');
  static String get failedToLoadSegments =>
      _l.translate('failedToLoadSegments');
  static String get retryAction => _l.translate('retryAction');
  static String get yesAction => _l.translate('yesAction');
  static String get noAction => _l.translate('noAction');
  static String get cancelAction => _l.translate('cancelAction');
  static String get deleteAction => _l.translate('deleteAction');
  static String get mapHintPlacePointA =>
      _l.translate('mapHintPlacePointA');
  static String get mapHintPlacePointB =>
      _l.translate('mapHintPlacePointB');
  static String get mapHintDragPoint => _l.translate('mapHintDragPoint');
  static String failedToLoadCameras(String error) =>
      _l.translate('failedToLoadCameras', {'error': error});
  static String get failedToAccessSegmentsMetadataFile =>
      _l.translate('failedToAccessSegmentsMetadataFile');
  static String get failedToParseSegmentsMetadataFile =>
      _l.translate('failedToParseSegmentsMetadataFile');
  static String get failedToWriteSegmentsMetadataFile =>
      _l.translate('failedToWriteSegmentsMetadataFile');
  static String failedToSubmitSegmentForModerationWithReason(String reason) =>
      _l.translate('failedToSubmitSegmentForModerationWithReason',
          {'reason': reason});
  static String failedToCheckSubmissionStatusWithReason(String reason) =>
      _l.translate(
        'failedToCheckSubmissionStatusWithReason',
        {'reason': reason},
      );
  static String failedToCancelSubmissionWithReason(String reason) =>
      _l.translate('failedToCancelSubmissionWithReason', {'reason': reason});
  static String failedToDownloadTollSegments(String reason) =>
      _l.translate('failedToDownloadTollSegments', {'reason': reason});
  static String failedToAccessTollSegmentsFile(String reason) =>
      _l.translate('failedToAccessTollSegmentsFile', {'reason': reason});
  static String get failedToDetermineTollSegmentsPath =>
      _l.translate('failedToDetermineTollSegmentsPath');
  static String get segmentMetadataUpdateUnavailable =>
      _l.translate('segmentMetadataUpdateUnavailable');
  static String get supabaseNotConfiguredForModeration =>
      _l.translate('supabaseNotConfiguredForModeration');
  static String get supabaseNotConfiguredForPublicSubmissions =>
      _l.translate('supabaseNotConfiguredForPublicSubmissions');
  static String get userRequiredForPublicModeration =>
      _l.translate('userRequiredForPublicModeration');
  static String get noConnectionUnableToSubmitForModeration =>
      _l.translate('noConnectionUnableToSubmitForModeration');
  static String get noConnectionUnableToManageSubmissions =>
      _l.translate('noConnectionUnableToManageSubmissions');
  static String get unexpectedErrorSubmittingForModeration =>
      _l.translate('unexpectedErrorSubmittingForModeration');
  static String get unexpectedErrorCheckingSubmissionStatus =>
      _l.translate('unexpectedErrorCheckingSubmissionStatus');
  static String get unexpectedErrorCancellingSubmission =>
      _l.translate('unexpectedErrorCancellingSubmission');
  static String get unableToAssignNewSegmentId =>
      _l.translate('unableToAssignNewSegmentId');
  static String get nonNumericSegmentIdEncountered =>
      _l.translate('nonNumericSegmentIdEncountered');
  static String get syncNotSupportedOnWeb =>
      _l.translate('syncNotSupportedOnWeb');
  static String tableReturnedNoRows(String tableName) =>
      _l.translate('tableReturnedNoRows', {'tableName': tableName});
  static String noTollSegmentRowsFound(String tablesChecked) =>
      _l.translate(
        'noTollSegmentRowsFound',
        {'tablesChecked': tablesChecked},
      );
  static String tableMissingModerationColumn(
    String tableName,
    String column,
  ) =>
      _l.translate('tableMissingModerationColumn', {
        'tableName': tableName,
        'column': column,
      });
  static String get csvMissingStartEndColumns =>
      _l.translate('csvMissingStartEndColumns');
  static String missingRequiredColumn(String column) =>
      _l.translate('missingRequiredColumn', {'column': column});
  static String get signInToSharePubliclyTitle =>
      _l.translate('signInToSharePubliclyTitle');
  static String get signInToSharePubliclyBody =>
      _l.translate('signInToSharePubliclyBody');
  static String get saveLocallyAction => _l.translate('saveLocallyAction');
  static String get loginAction => _l.translate('loginAction');
  static String get failedToSaveSegmentLocally =>
      _l.translate('failedToSaveSegmentLocally');
  static String get startEndCoordinatesRequired =>
      _l.translate('startEndCoordinatesRequired');
  static String get loggedInRetrySavePrompt =>
      _l.translate('loggedInRetrySavePrompt');
  static String get osmCopyrightLaunchFailed =>
      _l.translate('osmCopyrightLaunchFailed');
  static String failedToLoadSegmentPreferences(String errorMessage) =>
      _l.translate(
        'failedToLoadSegmentPreferences',
        {'errorMessage': errorMessage},
      );
  static String get supabaseNotConfiguredForSync =>
      _l.translate('supabaseNotConfiguredForSync');
  static String get unexpectedSyncError =>
      _l.translate('unexpectedSyncError');

  static String syncCompleteSummary({
    required int addedSegments,
    required int removedSegments,
    required int totalSegments,
    required int approvedLocalSegments,
  }) {
    final l = _l;
    final parts = <String>[];
    if (addedSegments > 0) {
      final key = addedSegments == 1 ? 'syncAddedOne' : 'syncAddedMany';
      parts.add(l.translate(key, {'count': '$addedSegments'}));
    }
    if (removedSegments > 0) {
      final key = removedSegments == 1 ? 'syncRemovedOne' : 'syncRemovedMany';
      parts.add(l.translate(key, {'count': '$removedSegments'}));
    }

    final changesSummary = parts.isEmpty
        ? l.translate('syncNoChangesDetected')
        : parts.join(', ') + '.';
    final buffer = StringBuffer()
      ..write(l.translate('syncCompleteIntro') + ' ')
      ..write(changesSummary + ' ')
      ..write(l.translate('syncTotalSegmentsSummary', {
        'count': '$totalSegments',
      }));

    if (approvedLocalSegments > 0) {
      final key = approvedLocalSegments == 1
          ? 'syncApprovedSummarySingular'
          : 'syncApprovedSummaryPlural';
      buffer.write(' ');
      buffer.write(
        l.translate(key, {'count': '$approvedLocalSegments'}),
      );
    }

    return buffer.toString();
  }
}
