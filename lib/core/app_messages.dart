/// Collection of user-facing strings displayed throughout the app.
///
/// Keeping messages together near [AppConstants] simplifies translation and
/// ensures copy updates remain consistent across the UI.
class AppMessages {
  /// Shown after returning from the segment creation flow when a draft has
  /// been saved to local storage instead of being published immediately.
  static const String segmentSavedLocally = 'Segment saved locally.';

  /// Label shown when offering to reveal a segment that was previously hidden
  /// on the map.
  static const String showSegmentOnMapAction = 'Show segment on map';

  /// Label shown when offering to hide a segment from the map.
  static const String hideSegmentOnMapAction = 'Hide segment on map';

  /// Subtitle explaining that restoring a segment will re-enable cameras and
  /// warnings for it.
  static const String segmentVisibilityRestoreSubtitle =
      'Cameras and warnings for this segment will be restored.';

  /// Subtitle explaining that hiding a segment will disable cameras and
  /// warnings for it.
  static const String segmentVisibilityDisableSubtitle =
      'No cameras or warnings will appear for this segment.';

  /// Shown after the user hides a segment; confirms the display id is now
  /// hidden and that related warnings are disabled.
  static String segmentHidden(String displayId) =>
      'Segment $displayId hidden. Cameras and warnings are disabled.';

  /// Shown after the user reactivates a segment; confirms visibility and
  /// warnings have been restored.
  static String segmentVisible(String displayId) =>
      'Segment $displayId is visible again. Cameras and warnings restored.';

  /// Shown when updating a segment's metadata fails and the error message
  /// should be surfaced to the user.
  static String failedToUpdateSegment(
    String displayId,
    String errorMessage,
  ) =>
      'Failed to update segment $displayId: $errorMessage';

  /// Shown when the user attempts to share a segment publicly without a valid
  /// authenticated session.
  static const String signInToShareSegment =
      'Please sign in to share segments publicly.';

  /// Label for the bottom sheet option that begins the public sharing flow for
  /// a segment.
  static const String shareSegmentPubliclyAction = 'Share segment publicly';

  /// Shown when the remote sharing infrastructure is not available, preventing
  /// the submission of public segments.
  static const String publicSharingUnavailable =
      'Public segment sharing is currently unavailable.';

  /// Short subtitle explaining that public sharing is currently unavailable in
  /// contexts where space is limited.
  static const String publicSharingUnavailableShort =
      'Public sharing is not available.';

  /// Subtitle informing the user that choosing to share publicly will submit
  /// the segment for moderation.
  static const String submitSegmentForPublicReviewSubtitle =
      'Submit this segment for public review.';

  /// Shown when the app cannot determine the logged in user during a public
  /// submission flow.
  static const String unableToDetermineLoggedInAccount =
      'Unable to determine the logged in account.';

  /// Shown when loading local draft data fails while preparing a public
  /// submission.
  static const String failedToPrepareSegmentForReview =
      'Failed to prepare the segment for public review.';

  /// Shown when checking the public submission status fails with a generic
  /// error.
  static const String failedToCheckSubmissionStatus =
      'Failed to check the public submission status.';

  /// Shown when submitting a segment for moderation fails unexpectedly.
  static const String failedToSubmitForModeration =
      'Failed to submit the segment for moderation.';

  /// Shown when a segment has already been submitted for public review by the
  /// same user and is awaiting moderation.
  static String segmentAlreadyAwaitingReview(String displayId) =>
      'Segment $displayId is already awaiting public review.';

  /// Shown when a segment is successfully submitted for public review and the
  /// segment id should be echoed back to the user.
  static String segmentSubmittedForPublicReview(String displayId) =>
      'Segment $displayId submitted for public review.';

  /// Shown when a segment is successfully submitted for public review but no
  /// display id is available (e.g. immediately after draft creation).
  static const String segmentSubmittedForPublicReviewGeneric =
      'Segment submitted for public review.';

  /// Shown when the app cannot withdraw a public submission due to missing
  /// authentication state.
  static const String unableToWithdrawSubmission =
      'Unable to withdraw the public submission.';

  /// Shown when the user must sign in before they can withdraw a public
  /// submission.
  static const String signInToWithdrawSubmission =
      'Please sign in to withdraw the public submission.';

  /// Shown when a public submission has been successfully cancelled and the
  /// review process will no longer continue.
  static String segmentNoLongerUnderReview(String displayId) =>
      'Segment $displayId will no longer be reviewed for public release.';

  /// Shown when withdrawing a public submission fails due to a missing internet
  /// connection; informs the user that only the local delete will proceed.
  static const String noConnectionCannotWithdrawSubmission =
      'No internet connection. The public submission cannot be withdrawn and the segment will only be deleted locally.';

  /// Shown when the app fails to cancel an in-progress public review request.
  static const String failedToCancelPublicReview =
      'Failed to cancel the public review for this segment.';

  /// Shown when deleting a segment fails for any reason.
  static const String failedToDeleteSegment =
      'Failed to delete the segment.';

  /// Label for the delete option in segment action sheets and dialogs.
  static const String deleteSegmentAction = 'Delete segment';

  /// Subtitle explaining why a segment cannot currently be deleted.
  static const String onlyLocalSegmentsCanBeDeleted =
      'Only local segments can be deleted.';

  /// Shown after a segment has been deleted from the local store.
  static String segmentDeleted(String displayId) =>
      'Segment $displayId deleted.';

  /// Title shown when confirming whether a segment should be deleted.
  static const String deleteSegmentConfirmationTitle = 'Delete segment';

  /// Message shown when asking the user to confirm segment deletion.
  static String confirmDeleteSegment(String displayId) =>
      'Are you sure you want to delete segment $displayId?';

  /// Shown when the app cannot determine the logged in account and suggests
  /// signing in again.
  static const String unableToDetermineLoggedInAccountRetry =
      'Unable to determine the logged in account. Please sign in again.';

  /// Shown when prompting the user to choose if a new segment should be visible
  /// publicly after creation.
  static const String chooseSegmentVisibilityQuestion =
      'Do you want the segment to be publically visible?';

  /// Shown when asking the user to confirm keeping a segment private.
  static const String confirmKeepSegmentPrivate =
      'Are you sure that you want to keep the segment only to yourself?';

  /// Shown when asking the user to confirm making a segment public.
  static const String confirmMakeSegmentPublic =
      'Are you sure you want to make this segment public?';

  /// Title used when asking the user to withdraw a public submission.
  static const String withdrawPublicSubmissionTitle =
      'Withdraw public submission?';

  /// Message shown when confirming if the user wants to withdraw a submission.
  static const String withdrawPublicSubmissionMessage =
      'You have submitted this segment for review. Do you want to withdraw the submission?';

  /// Generic fallback error shown when an operation fails unexpectedly.
  static const String somethingWentWrongTryAgain =
      'Something went wrong. Please try again.';

  /// Shown after a new account is created to prompt email confirmation.
  static const String accountCreatedCheckEmail =
      'Account created! Check your email to confirm it.';

  /// Shown when logging out fails unexpectedly.
  static const String unableToLogOutTryAgain =
      'Unable to log out. Please try again.';

  /// Shown when authentication services have not been configured.
  static const String authenticationNotConfigured =
      'Authentication is not configured. Please add Supabase credentials.';

  /// Shown when sign-in fails due to an unexpected platform error.
  static const String unexpectedErrorSigningIn =
      'Unexpected error while signing in.';

  /// Shown when account creation fails due to an unexpected platform error.
  static const String unexpectedErrorCreatingAccount =
      'Unexpected error while creating the account.';

  /// Shown when sign-out fails due to an unexpected platform error.
  static const String unexpectedErrorSigningOut =
      'Unexpected error while signing out.';

  /// Validation message shown when the name field is left empty.
  static const String enterYourName = 'Please enter your name';

  /// Validation message shown when the email field is left empty.
  static const String enterYourEmail = 'Please enter your email';

  /// Validation message shown when the password field is left empty.
  static const String enterYourPassword = 'Please enter your password';

  /// Validation message shown when the password confirmation is missing.
  static const String confirmYourPassword = 'Please confirm your password';

  /// Validation message shown when creating a new password requires input.
  static const String createPasswordPrompt = 'Please create a password';

  /// Validation message shown when the password is shorter than the minimum.
  static const String passwordTooShort =
      'Password must be at least 6 characters';

  /// Validation message shown when the password and confirmation do not match.
  static const String passwordsDoNotMatch = 'Passwords do not match';

  /// Message displayed when loading segments fails in list views.
  static const String failedToLoadSegments = 'Failed to load segments.';

  /// Generic retry button label used across error surfaces.
  static const String retryAction = 'Retry';

  /// Generic affirmative button label.
  static const String yesAction = 'Yes';

  /// Generic negative button label.
  static const String noAction = 'No';

  /// Generic cancel action label.
  static const String cancelAction = 'Cancel';

  /// Generic delete action label.
  static const String deleteAction = 'Delete';

  /// Hint shown before either endpoint has been positioned on the map.
  static const String mapHintPlacePointA =
      'Tap anywhere on the map to place point A.';

  /// Hint shown after the start point has been placed but not the end point.
  static const String mapHintPlacePointB =
      'Tap a second location to place point B.';

  /// Hint shown once both endpoints exist, explaining how to reposition them.
  static const String mapHintDragPoint =
      'Touch and hold A or B for 0.5s, then drag to reposition that point.';

  /// Message shown when loading camera data fails.
  static String failedToLoadCameras(String error) =>
      'Failed to load cameras: $error';

  /// Message shown when the app cannot access the segments metadata file.
  static const String failedToAccessSegmentsMetadataFile =
      'Failed to access the segments metadata file.';

  /// Message shown when the segments metadata file cannot be parsed.
  static const String failedToParseSegmentsMetadataFile =
      'Failed to parse the segments metadata file.';

  /// Message shown when the segments metadata file cannot be written.
  static const String failedToWriteSegmentsMetadataFile =
      'Failed to write to the segments metadata file.';

  /// Message shown when submitting a segment for moderation fails.
  static String failedToSubmitSegmentForModerationWithReason(String reason) =>
      'Failed to submit the segment for moderation: $reason';

  /// Message shown when checking the submission status fails.
  static String failedToCheckSubmissionStatusWithReason(String reason) =>
      'Failed to check the public submission status: $reason';

  /// Message shown when cancelling a submission fails.
  static String failedToCancelSubmissionWithReason(String reason) =>
      'Failed to cancel the public submission: $reason';

  /// Message shown when downloading toll segments fails.
  static String failedToDownloadTollSegments(String reason) =>
      'Failed to download toll segments: $reason';

  /// Message shown when accessing the local toll segments file fails.
  static String failedToAccessTollSegmentsFile(String reason) =>
      'Failed to access the toll segments file: $reason';

  /// Message shown when the local storage path for toll segments cannot be
  /// determined.
  static const String failedToDetermineTollSegmentsPath =
      'Failed to determine the local toll segments storage path.';

  /// Message shown when attempting to edit metadata on unsupported platforms.
  static const String segmentMetadataUpdateUnavailable =
      'Segment metadata cannot be updated on the web.';

  /// Message shown when Supabase is not configured for moderation submissions.
  static const String supabaseNotConfiguredForModeration =
      'Supabase is not configured. Unable to submit the segment for moderation.';

  /// Message shown when Supabase is not configured for managing public submissions.
  static const String supabaseNotConfiguredForPublicSubmissions =
      'Supabase is not configured. Unable to manage public submissions.';

  /// Message shown when a logged-in user is required to submit a segment.
  static const String userRequiredForPublicModeration =
      'A logged in user is required to submit a public segment for moderation.';

  /// Message shown when there is no internet connection for moderation actions.
  static const String noConnectionUnableToSubmitForModeration =
      'No internet connection. Unable to submit the segment for moderation.';

  /// Message shown when there is no internet connection for managing submissions.
  static const String noConnectionUnableToManageSubmissions =
      'No internet connection. Unable to manage public submissions.';

  /// Message shown when an unexpected error occurs while submitting a segment.
  static const String unexpectedErrorSubmittingForModeration =
      'Unexpected error while submitting the segment for moderation.';

  /// Message shown when an unexpected error occurs while checking submission status.
  static const String unexpectedErrorCheckingSubmissionStatus =
      'Unexpected error while checking the public submission status.';

  /// Message shown when an unexpected error occurs while cancelling a submission.
  static const String unexpectedErrorCancellingSubmission =
      'Unexpected error while cancelling the public submission.';

  /// Message shown when there are no more available segment ids.
  static const String unableToAssignNewSegmentId =
      'Unable to assign a new segment id: all smallint values are exhausted.';

  /// Message shown when a non-numeric segment id is encountered.
  static const String nonNumericSegmentIdEncountered =
      'Encountered an existing segment with a non-numeric id.';

  /// Message shown when sync is not supported on the current platform.
  static const String syncNotSupportedOnWeb =
      'Syncing toll segments is not supported on the web.';

  /// Message shown when the remote table returns no rows.
  static String tableReturnedNoRows(String tableName) =>
      'The $tableName table did not return any rows.';

  /// Message shown when none of the candidate tables returned any rows.
  static String noTollSegmentRowsFound(String tablesChecked) =>
      'No toll segment rows were returned from Supabase. Checked tables: '
      '$tablesChecked. Ensure your account has access to the data.';

  /// Message shown when a required moderation column is missing.
  static String tableMissingModerationColumn(String tableName, String column) =>
      'The "$tableName" table is missing the "$column" column required for moderation.';

  /// Message shown when the local CSV is missing required start/end columns.
  static const String csvMissingStartEndColumns =
      'CSV must contain "Start" and "End" columns';

  /// Message shown when an expected column is absent in the remote table.
  static String missingRequiredColumn(String column) =>
      'Missing required column "$column" in the Toll_Segments table.';

  /// Title for the dialog prompting the user to sign in before sharing a
  /// segment publicly.
  static const String signInToSharePubliclyTitle =
      'Sign in to share publicly';

  /// Body copy shown when the user must sign in before sharing publicly and is
  /// given the option to save locally instead.
  static const String signInToSharePubliclyBody =
      'You need to be logged in to submit a public segment. Would you like to log in or save the segment locally instead?';

  /// Label for dialog actions that save a draft locally instead of logging in.
  static const String saveLocallyAction = 'Save locally';

  /// Label for dialog actions that initiate the login flow.
  static const String loginAction = 'Login';

  /// Shown when saving a draft locally fails unexpectedly.
  static const String failedToSaveSegmentLocally =
      'Failed to save the segment locally.';

  /// Shown when the draft form is missing required coordinate values.
  static const String startEndCoordinatesRequired =
      'Start and end coordinates are required.';

  /// Shown after a successful login when the user is returned to the draft
  /// flow and needs to press the save button again to continue submission.
  static const String loggedInRetrySavePrompt =
      'Logged in successfully. Tap "Save segment" again to submit the segment.';

  /// Shown when launching the OpenStreetMap copyright page fails.
  static const String osmCopyrightLaunchFailed =
      'Could not open the OpenStreetMap copyright page.';

  /// Shown when the app fails to load the persisted segment metadata
  /// preferences and falls back to defaults.
  static String failedToLoadSegmentPreferences(String errorMessage) =>
      'Failed to load segment preferences: $errorMessage';

  /// Shown when Supabase credentials are missing and online sync cannot start.
  static const String supabaseNotConfiguredForSync =
      'Supabase is not configured. Please add credentials to enable sync.';

  /// Shown when an unexpected error occurs during the toll segment sync flow.
  static const String unexpectedSyncError =
      'Unexpected error while syncing toll segments.';

  /// Builds the sync completion summary shown after the toll segments database
  /// has been refreshed.
  static String syncCompleteSummary({
    required int addedSegments,
    required int removedSegments,
    required int totalSegments,
    required int approvedLocalSegments,
  }) {
    final parts = <String>[];
    if (addedSegments > 0) {
      final label = addedSegments == 1 ? 'segment' : 'segments';
      parts.add('$addedSegments $label added');
    }
    if (removedSegments > 0) {
      final label = removedSegments == 1 ? 'segment' : 'segments';
      parts.add('$removedSegments $label removed');
    }

    final changesSummary = parts.isEmpty
        ? 'No changes detected.'
        : parts.join(', ') + '.';
    final buffer = StringBuffer(
      'Sync complete. $changesSummary $totalSegments total segments available.',
    );

    if (approvedLocalSegments > 0) {
      final verb = approvedLocalSegments == 1 ? 'was' : 'were';
      final visibilityVerb = approvedLocalSegments == 1 ? 'is' : 'are';
      buffer.write(
        ' $approvedLocalSegments of your submitted segments ',
      );
      buffer.write(
        '$verb approved and now $visibilityVerb visible to everyone.',
      );
    }

    return buffer.toString();
  }
}
