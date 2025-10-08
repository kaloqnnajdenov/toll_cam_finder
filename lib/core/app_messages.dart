import 'localization/app_locale.dart';

/// Collection of user-facing strings displayed throughout the app.
///
/// Keeping messages together near [AppConstants] simplifies translation and
/// ensures copy updates remain consistent across the UI.
class AppMessages {
  static const _fallbackLanguageCode = 'en';

  static String get _languageCode => AppLocale.languageCode;

  static String _translate(String key) {
    final translations = _localizedValues[key];
    if (translations == null) {
      return key;
    }
    return translations[_languageCode] ??
        translations[_fallbackLanguageCode] ??
        key;
  }

  static String _translateWithArgs(
    String key,
    Map<String, String> replacements,
  ) {
    var value = _translate(key);
    replacements.forEach((placeholder, replacement) {
      value = value.replaceAll('{$placeholder}', replacement);
    });
    return value;
  }

  static String get segmentSavedLocally =>
      _translate('segmentSavedLocally');

  static String get showSegmentOnMapAction =>
      _translate('showSegmentOnMapAction');

  static String get hideSegmentOnMapAction =>
      _translate('hideSegmentOnMapAction');

  static String get segmentVisibilityRestoreSubtitle =>
      _translate('segmentVisibilityRestoreSubtitle');

  static String get segmentVisibilityDisableSubtitle =>
      _translate('segmentVisibilityDisableSubtitle');

  static String segmentHidden(String displayId) =>
      _translateWithArgs('segmentHidden', {'displayId': displayId});

  static String segmentVisible(String displayId) =>
      _translateWithArgs('segmentVisible', {'displayId': displayId});

  static String failedToUpdateSegment(
    String displayId,
    String errorMessage,
  ) =>
      _translateWithArgs('failedToUpdateSegment', {
        'displayId': displayId,
        'errorMessage': errorMessage,
      });

  static String get signInToShareSegment =>
      _translate('signInToShareSegment');

  static String get shareSegmentPubliclyAction =>
      _translate('shareSegmentPubliclyAction');

  static String get publicSharingUnavailable =>
      _translate('publicSharingUnavailable');

  static String get publicSharingUnavailableShort =>
      _translate('publicSharingUnavailableShort');

  static String get submitSegmentForPublicReviewSubtitle =>
      _translate('submitSegmentForPublicReviewSubtitle');

  static String get unableToDetermineLoggedInAccount =>
      _translate('unableToDetermineLoggedInAccount');

  static String get failedToPrepareSegmentForReview =>
      _translate('failedToPrepareSegmentForReview');

  static String get failedToCheckSubmissionStatus =>
      _translate('failedToCheckSubmissionStatus');

  static String get failedToSubmitForModeration =>
      _translate('failedToSubmitForModeration');

  static String get unableToWithdrawSubmission =>
      _translate('unableToWithdrawSubmission');

  static String get signInToWithdrawSubmission =>
      _translate('signInToWithdrawSubmission');

  static String segmentNoLongerUnderReview(String displayId) =>
      _translateWithArgs('segmentNoLongerUnderReview', {
        'displayId': displayId,
      });

  static String get noConnectionCannotWithdrawSubmission =>
      _translate('noConnectionCannotWithdrawSubmission');

  static String get failedToCancelPublicReview =>
      _translate('failedToCancelPublicReview');

  static String get failedToDeleteSegment =>
      _translate('failedToDeleteSegment');

  static String get deleteSegmentAction =>
      _translate('deleteSegmentAction');

  static String get onlyLocalSegmentsCanBeDeleted =>
      _translate('onlyLocalSegmentsCanBeDeleted');

  static String segmentDeleted(String displayId) =>
      _translateWithArgs('segmentDeleted', {'displayId': displayId});

  static String get deleteSegmentConfirmationTitle =>
      _translate('deleteSegmentConfirmationTitle');

  static String confirmDeleteSegment(String displayId) =>
      _translateWithArgs('confirmDeleteSegment', {'displayId': displayId});

  static String get unableToDetermineLoggedInAccountRetry =>
      _translate('unableToDetermineLoggedInAccountRetry');

  static String get chooseSegmentVisibilityQuestion =>
      _translate('chooseSegmentVisibilityQuestion');

  static String get confirmKeepSegmentPrivate =>
      _translate('confirmKeepSegmentPrivate');

  static String get confirmMakeSegmentPublic =>
      _translate('confirmMakeSegmentPublic');

  static String get withdrawPublicSubmissionTitle =>
      _translate('withdrawPublicSubmissionTitle');

  static String get withdrawPublicSubmissionMessage =>
      _translate('withdrawPublicSubmissionMessage');

  static String get somethingWentWrongTryAgain =>
      _translate('somethingWentWrongTryAgain');

  static String get accountCreatedCheckEmail =>
      _translate('accountCreatedCheckEmail');

  static String get unableToLogOutTryAgain =>
      _translate('unableToLogOutTryAgain');

  static String get authenticationNotConfigured =>
      _translate('authenticationNotConfigured');

  static String get unexpectedErrorSigningIn =>
      _translate('unexpectedErrorSigningIn');

  static String get unexpectedErrorCreatingAccount =>
      _translate('unexpectedErrorCreatingAccount');

  static String get unexpectedErrorSigningOut =>
      _translate('unexpectedErrorSigningOut');

  static String get enterYourName => _translate('enterYourName');

  static String get enterYourEmail => _translate('enterYourEmail');

  static String get enterYourPassword =>
      _translate('enterYourPassword');

  static String get confirmYourPassword =>
      _translate('confirmYourPassword');

  static String get createPasswordPrompt =>
      _translate('createPasswordPrompt');

  static String get passwordTooShort =>
      _translate('passwordTooShort');

  static String get passwordsDoNotMatch =>
      _translate('passwordsDoNotMatch');

  static String get createAccountTitle =>
      _translate('createAccountTitle');

  static String get joinTollCamHeadline =>
      _translate('joinTollCamHeadline');

  static String get fullNameLabel => _translate('fullNameLabel');

  static String get emailLabel => _translate('emailLabel');

  static String get passwordLabel => _translate('passwordLabel');

  static String get confirmPasswordLabel =>
      _translate('confirmPasswordLabel');

  static String get createAccountAction =>
      _translate('createAccountAction');

  static String get alreadyHaveAccountPrompt =>
      _translate('alreadyHaveAccountPrompt');

  static String get welcomeHeadline =>
      _translate('welcomeHeadline');

  static String get continueAction =>
      _translate('continueAction');

  static String get createNewAccountPrompt =>
      _translate('createNewAccountPrompt');

  static String get unknownUser => _translate('unknownUser');

  static String get profileTitle => _translate('profileTitle');

  static String get profileSubtitle => _translate('profileSubtitle');

  static String get logOutAction => _translate('logOutAction');

  static String get failedToLoadSegments =>
      _translate('failedToLoadSegments');

  static String get retryAction => _translate('retryAction');

  static String get yesAction => _translate('yesAction');

  static String get noAction => _translate('noAction');

  static String get cancelAction => _translate('cancelAction');

  static String get deleteAction => _translate('deleteAction');

  static String get drawerSync => _translate('drawerSync');

  static String get drawerSegments => _translate('drawerSegments');

  static String get drawerLanguage => _translate('drawerLanguage');

  static String get drawerProfile => _translate('drawerProfile');

  static String get languageSelectionTitle =>
      _translate('languageSelectionTitle');

  static String get languageComingSoon =>
      _translate('languageComingSoon');

  static String get createAccountDrawerTitle =>
      _translate('createAccountDrawerTitle');

  static String get segmentsTitle => _translate('segmentsTitle');

  static String get localSegmentsTooltip =>
      _translate('localSegmentsTooltip');

  static String get createSegmentAction =>
      _translate('createSegmentAction');

  static String get localSegmentsTitle =>
      _translate('localSegmentsTitle');

  static String get noSegmentsAvailable =>
      _translate('noSegmentsAvailable');

  static String get noLocalSegmentsSaved =>
      _translate('noLocalSegmentsSaved');

  static String get segmentStartLabel =>
      _translate('segmentStartLabel');

  static String get segmentEndLabel =>
      _translate('segmentEndLabel');

  static String get segmentHiddenBadge =>
      _translate('segmentHiddenBadge');

  static String get segmentLocalBadge =>
      _translate('segmentLocalBadge');

  static String get segmentReviewBadge =>
      _translate('segmentReviewBadge');

  static String get fineTuneSegmentHeadline =>
      _translate('fineTuneSegmentHeadline');

  static String get adjustSegmentInstructions =>
      _translate('adjustSegmentInstructions');

  static String get segmentCoordinatesAutoFill =>
      _translate('segmentCoordinatesAutoFill');

  static String get segmentDetailsSectionTitle =>
      _translate('segmentDetailsSectionTitle');

  static String get segmentNameLabel =>
      _translate('segmentNameLabel');

  static String get roadNameLabel => _translate('roadNameLabel');

  static String get segmentStartNameHint =>
      _translate('segmentStartNameHint');

  static String get segmentEndNameHint =>
      _translate('segmentEndNameHint');

  static String get segmentStartCoordinatesLabel =>
      _translate('segmentStartCoordinatesLabel');

  static String get segmentEndPointLabel =>
      _translate('segmentEndPointLabel');

  static String get saveSegmentAction =>
      _translate('saveSegmentAction');

  static String get mapDataFromLabel =>
      _translate('mapDataFromLabel');

  static String get openStreetMapLabel =>
      _translate('openStreetMapLabel');

  static String segmentAlreadyApprovedAndPublic(String displayId) =>
      _translateWithArgs('segmentAlreadyApprovedAndPublic', {
        'displayId': displayId,
      });

  static String segmentDistanceMeters(String meters) =>
      _translateWithArgs('segmentDistanceMeters', {'meters': meters});

  static String segmentDistanceKmLeft(String kilometers) =>
      _translateWithArgs('segmentDistanceKmLeft', {'kilometers': kilometers});

  static String segmentHeadingDifference(String degrees) =>
      _translateWithArgs('segmentHeadingDifference', {'degrees': degrees});

  static String get segmentDebugTagDetailed =>
      _translate('segmentDebugTagDetailed');

  static String get segmentDebugTagApprox =>
      _translate('segmentDebugTagApprox');

  static String get segmentDebugTagDirectionPass =>
      _translate('segmentDebugTagDirectionPass');

  static String get segmentDebugTagDirectionFail =>
      _translate('segmentDebugTagDirectionFail');

  static String get segmentDebugTagStart =>
      _translate('segmentDebugTagStart');

  static String get segmentDebugTagEnd =>
      _translate('segmentDebugTagEnd');

  static String averageSpeedBanner(String speedKph) =>
      _translateWithArgs('averageSpeedBanner', {'speed': speedKph});

  static String segmentsDebugCountRadius({
    required String count,
    required String radius,
  }) =>
      _translateWithArgs('segmentsDebugCountRadius', {
        'count': count,
        'radius': radius,
      });

  static String get fabRecenterLabel =>
      _translate('fabRecenterLabel');

  static String segmentMaxSpeed(String speedLimit) =>
      _translateWithArgs('segmentMaxSpeed', {'speed': speedLimit});

  static String get avgSpeedDialLimitLabel =>
      _translate('avgSpeedDialLimitLabel');

  static String get avgSpeedDialNoSegment =>
      _translate('avgSpeedDialNoSegment');

  static String get averageSpeedTitle =>
      _translate('averageSpeedTitle');

  static String get mapHintPlacePointA =>
      _translate('mapHintPlacePointA');

  static String get mapHintPlacePointB =>
      _translate('mapHintPlacePointB');

  static String get mapHintDragPoint =>
      _translate('mapHintDragPoint');

  static String failedToLoadCameras(String error) =>
      _translateWithArgs('failedToLoadCameras', {'error': error});

  static String distanceToSegmentEndKm(String distanceKm) =>
      _translateWithArgs('distanceToSegmentEndKm', {'distance': distanceKm});

  static String distanceToSegmentEndMeters(String distanceMeters) =>
      _translateWithArgs('distanceToSegmentEndMeters', {'distance': distanceMeters});

  static String get segmentEndNearby =>
      _translate('segmentEndNearby');

  static String distanceToSegmentStartKm(String distanceKm) =>
      _translateWithArgs('distanceToSegmentStartKm', {'distance': distanceKm});

  static String distanceToSegmentStartMeters(String distanceMeters) =>
      _translateWithArgs('distanceToSegmentStartMeters', {
        'distance': distanceMeters,
      });

  static String get segmentStartNearby =>
      _translate('segmentStartNearby');

  static String get openMenuTooltip => _translate('openMenuTooltip');

  static String get failedToAccessSegmentsMetadataFile =>
      _translate('failedToAccessSegmentsMetadataFile');

  static String get failedToParseSegmentsMetadataFile =>
      _translate('failedToParseSegmentsMetadataFile');

  static String get failedToWriteSegmentsMetadataFile =>
      _translate('failedToWriteSegmentsMetadataFile');

  static String failedToSubmitSegmentForModerationWithReason(
    String reason,
  ) =>
      _translateWithArgs(
        'failedToSubmitSegmentForModerationWithReason',
        {'reason': reason},
      );

  static String failedToCheckSubmissionStatusWithReason(String reason) =>
      _translateWithArgs(
        'failedToCheckSubmissionStatusWithReason',
        {'reason': reason},
      );

  static String failedToCancelSubmissionWithReason(String reason) =>
      _translateWithArgs(
        'failedToCancelSubmissionWithReason',
        {'reason': reason},
      );

  static String failedToDownloadTollSegments(String reason) =>
      _translateWithArgs('failedToDownloadTollSegments', {'reason': reason});

  static String failedToAccessTollSegmentsFile(String reason) =>
      _translateWithArgs('failedToAccessTollSegmentsFile', {'reason': reason});

  static String get failedToDetermineTollSegmentsPath =>
      _translate('failedToDetermineTollSegmentsPath');

  static String get segmentMetadataUpdateUnavailable =>
      _translate('segmentMetadataUpdateUnavailable');

  static String get supabaseNotConfiguredForModeration =>
      _translate('supabaseNotConfiguredForModeration');

  static String get supabaseNotConfiguredForPublicSubmissions =>
      _translate('supabaseNotConfiguredForPublicSubmissions');

  static String get userRequiredForPublicModeration =>
      _translate('userRequiredForPublicModeration');

  static String get noConnectionUnableToSubmitForModeration =>
      _translate('noConnectionUnableToSubmitForModeration');

  static String get noConnectionUnableToManageSubmissions =>
      _translate('noConnectionUnableToManageSubmissions');

  static String get unexpectedErrorSubmittingForModeration =>
      _translate('unexpectedErrorSubmittingForModeration');

  static String get unexpectedErrorCheckingSubmissionStatus =>
      _translate('unexpectedErrorCheckingSubmissionStatus');

  static String get unexpectedErrorCancellingSubmission =>
      _translate('unexpectedErrorCancellingSubmission');

  static String get unableToAssignNewSegmentId =>
      _translate('unableToAssignNewSegmentId');

  static String get nonNumericSegmentIdEncountered =>
      _translate('nonNumericSegmentIdEncountered');

  static String get syncNotSupportedOnWeb =>
      _translate('syncNotSupportedOnWeb');

  static String tableReturnedNoRows(String tableName) =>
      _translateWithArgs('tableReturnedNoRows', {'tableName': tableName});

  static String noTollSegmentRowsFound(String tablesChecked) =>
      _translateWithArgs('noTollSegmentRowsFound', {
        'tablesChecked': tablesChecked,
      });

  static String tableMissingModerationColumn(
    String tableName,
    String column,
  ) =>
      _translateWithArgs('tableMissingModerationColumn', {
        'tableName': tableName,
        'column': column,
      });

  static String get csvMissingStartEndColumns =>
      _translate('csvMissingStartEndColumns');

  static String missingRequiredColumn(String column) =>
      _translateWithArgs('missingRequiredColumn', {'column': column});

  static String get signInToSharePubliclyTitle =>
      _translate('signInToSharePubliclyTitle');

  static String get signInToSharePubliclyBody =>
      _translate('signInToSharePubliclyBody');

  static String get saveLocallyAction => _translate('saveLocallyAction');

  static String get loginAction => _translate('loginAction');

  static String get failedToSaveSegmentLocally =>
      _translate('failedToSaveSegmentLocally');

  static String get startEndCoordinatesRequired =>
      _translate('startEndCoordinatesRequired');

  static String get loggedInRetrySavePrompt =>
      _translate('loggedInRetrySavePrompt');

  static String get osmCopyrightLaunchFailed =>
      _translate('osmCopyrightLaunchFailed');

  static String failedToLoadSegmentPreferences(String errorMessage) =>
      _translateWithArgs('failedToLoadSegmentPreferences', {
        'errorMessage': errorMessage,
      });

  static String get supabaseNotConfiguredForSync =>
      _translate('supabaseNotConfiguredForSync');

  static String get unexpectedSyncError =>
      _translate('unexpectedSyncError');

  static String syncCompleteSummary({
    required int addedSegments,
    required int removedSegments,
    required int totalSegments,
    required int approvedLocalSegments,
  }) {
    final parts = <String>[];
    if (addedSegments > 0) {
      parts.add(
        _translateWithArgs('syncAddedSegments', {
          'count': addedSegments.toString(),
          'segmentLabel': addedSegments == 1
              ? _translate('segmentLabelSingular')
              : _translate('segmentLabelPlural'),
        }),
      );
    }
    if (removedSegments > 0) {
      parts.add(
        _translateWithArgs('syncRemovedSegments', {
          'count': removedSegments.toString(),
          'segmentLabel': removedSegments == 1
              ? _translate('segmentLabelSingular')
              : _translate('segmentLabelPlural'),
        }),
      );
    }

    final changesSummary = parts.isEmpty
        ? _translate('syncNoChangesDetected')
        : parts.join(_translate('syncChangesSeparator')) +
            _translate('syncChangesPeriod');

    final buffer = StringBuffer(
      _translateWithArgs('syncCompleteHeadline', {
        'changesSummary': changesSummary,
        'totalSegments': totalSegments.toString(),
      }),
    );

    if (approvedLocalSegments > 0) {
      buffer.write(' ');
      buffer.write(
        _translateWithArgs('syncApprovedSegments', {
          'count': approvedLocalSegments.toString(),
          'wasVerb': approvedLocalSegments == 1
              ? _translate('syncVerbWas')
              : _translate('syncVerbWere'),
          'visibilityVerb': approvedLocalSegments == 1
              ? _translate('syncVerbIs')
              : _translate('syncVerbAre'),
        }),
      );
    }

    return buffer.toString();
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'segmentSavedLocally': {
      'en': 'Segment saved locally.',
      'es': 'Segmento guardado localmente.',
    },
    'showSegmentOnMapAction': {
      'en': 'Show segment on map',
      'es': 'Mostrar segmento en el mapa',
    },
    'hideSegmentOnMapAction': {
      'en': 'Hide segment on map',
      'es': 'Ocultar segmento en el mapa',
    },
    'segmentVisibilityRestoreSubtitle': {
      'en': 'Cameras and warnings for this segment will be restored.',
      'es': 'Se restaurarán las cámaras y alertas para este segmento.',
    },
    'segmentVisibilityDisableSubtitle': {
      'en': 'No cameras or warnings will appear for this segment.',
      'es': 'No aparecerán cámaras ni alertas para este segmento.',
    },
    'segmentHidden': {
      'en':
          'Segment {displayId} hidden. Cameras and warnings are disabled.',
      'es':
          'Segmento {displayId} oculto. Las cámaras y alertas están desactivadas.',
    },
    'segmentVisible': {
      'en':
          'Segment {displayId} is visible again. Cameras and warnings restored.',
      'es':
          'El segmento {displayId} vuelve a ser visible. Cámaras y alertas restauradas.',
    },
    'failedToUpdateSegment': {
      'en': 'Failed to update segment {displayId}: {errorMessage}',
      'es':
          'No se pudo actualizar el segmento {displayId}: {errorMessage}',
    },
    'signInToShareSegment': {
      'en': 'Please sign in to share segments publicly.',
      'es': 'Inicia sesión para compartir segmentos públicamente.',
    },
    'shareSegmentPubliclyAction': {
      'en': 'Share segment publicly',
      'es': 'Compartir segmento públicamente',
    },
    'publicSharingUnavailable': {
      'en': 'Public segment sharing is currently unavailable.',
      'es': 'El uso compartido público de segmentos no está disponible.',
    },
    'publicSharingUnavailableShort': {
      'en': 'Public sharing is not available.',
      'es': 'El uso compartido público no está disponible.',
    },
    'submitSegmentForPublicReviewSubtitle': {
      'en': 'Submit this segment for public review.',
      'es': 'Enviar este segmento para revisión pública.',
    },
    'unableToDetermineLoggedInAccount': {
      'en': 'Unable to determine the logged in account.',
      'es': 'No se puede determinar la cuenta iniciada.',
    },
    'failedToPrepareSegmentForReview': {
      'en': 'Failed to prepare the segment for public review.',
      'es': 'No se pudo preparar el segmento para la revisión pública.',
    },
    'failedToCheckSubmissionStatus': {
      'en': 'Failed to check the public submission status.',
      'es': 'No se pudo comprobar el estado del envío público.',
    },
    'failedToSubmitForModeration': {
      'en': 'Failed to submit the segment for moderation.',
      'es': 'No se pudo enviar el segmento para moderación.',
    },
    'unableToWithdrawSubmission': {
      'en': 'Unable to withdraw the public submission.',
      'es': 'No se puede retirar el envío público.',
    },
    'signInToWithdrawSubmission': {
      'en': 'Please sign in to withdraw the public submission.',
      'es': 'Inicia sesión para retirar el envío público.',
    },
    'segmentNoLongerUnderReview': {
      'en':
          'Segment {displayId} will no longer be reviewed for public release.',
      'es':
          'El segmento {displayId} ya no se revisará para su publicación.',
    },
    'noConnectionCannotWithdrawSubmission': {
      'en':
          'No internet connection. The public submission cannot be withdrawn and the segment will only be deleted locally.',
      'es':
          'Sin conexión a internet. El envío público no puede retirarse y el segmento solo se eliminará localmente.',
    },
    'failedToCancelPublicReview': {
      'en': 'Failed to cancel the public review for this segment.',
      'es': 'No se pudo cancelar la revisión pública de este segmento.',
    },
    'failedToDeleteSegment': {
      'en': 'Failed to delete the segment.',
      'es': 'No se pudo eliminar el segmento.',
    },
    'deleteSegmentAction': {
      'en': 'Delete segment',
      'es': 'Eliminar segmento',
    },
    'onlyLocalSegmentsCanBeDeleted': {
      'en': 'Only local segments can be deleted.',
      'es': 'Solo se pueden eliminar segmentos locales.',
    },
    'segmentDeleted': {
      'en': 'Segment {displayId} deleted.',
      'es': 'Segmento {displayId} eliminado.',
    },
    'deleteSegmentConfirmationTitle': {
      'en': 'Delete segment',
      'es': 'Eliminar segmento',
    },
    'confirmDeleteSegment': {
      'en': 'Are you sure you want to delete segment {displayId}?',
      'es': '¿Seguro que deseas eliminar el segmento {displayId}?',
    },
    'unableToDetermineLoggedInAccountRetry': {
      'en':
          'Unable to determine the logged in account. Please sign in again.',
      'es':
          'No se puede determinar la cuenta iniciada. Inicia sesión nuevamente.',
    },
    'chooseSegmentVisibilityQuestion': {
      'en': 'Do you want the segment to be publically visible?',
      'es': '¿Quieres que el segmento sea visible públicamente?',
    },
    'confirmKeepSegmentPrivate': {
      'en':
          'Are you sure that you want to keep the segment only to yourself?',
      'es': '¿Seguro que quieres mantener el segmento solo para ti?',
    },
    'confirmMakeSegmentPublic': {
      'en': 'Are you sure you want to make this segment public?',
      'es': '¿Seguro que quieres hacer público este segmento?',
    },
    'withdrawPublicSubmissionTitle': {
      'en': 'Withdraw public submission?',
      'es': '¿Retirar envío público?',
    },
    'withdrawPublicSubmissionMessage': {
      'en':
          'You have submitted this segment for review. Do you want to withdraw the submission?',
      'es':
          'Has enviado este segmento para revisión. ¿Quieres retirar el envío?',
    },
    'somethingWentWrongTryAgain': {
      'en': 'Something went wrong. Please try again.',
      'es': 'Algo salió mal. Inténtalo de nuevo.',
    },
    'accountCreatedCheckEmail': {
      'en': 'Account created! Check your email to confirm it.',
      'es': '¡Cuenta creada! Revisa tu correo para confirmarla.',
    },
    'unableToLogOutTryAgain': {
      'en': 'Unable to log out. Please try again.',
      'es': 'No se puede cerrar sesión. Inténtalo de nuevo.',
    },
    'authenticationNotConfigured': {
      'en':
          'Authentication is not configured. Please add Supabase credentials.',
      'es':
          'La autenticación no está configurada. Agrega las credenciales de Supabase.',
    },
    'unexpectedErrorSigningIn': {
      'en': 'Unexpected error while signing in.',
      'es': 'Error inesperado al iniciar sesión.',
    },
    'unexpectedErrorCreatingAccount': {
      'en': 'Unexpected error while creating the account.',
      'es': 'Error inesperado al crear la cuenta.',
    },
    'unexpectedErrorSigningOut': {
      'en': 'Unexpected error while signing out.',
      'es': 'Error inesperado al cerrar sesión.',
    },
    'enterYourName': {
      'en': 'Please enter your name',
      'es': 'Ingresa tu nombre',
    },
    'enterYourEmail': {
      'en': 'Please enter your email',
      'es': 'Ingresa tu correo electrónico',
    },
    'enterYourPassword': {
      'en': 'Please enter your password',
      'es': 'Ingresa tu contraseña',
    },
    'confirmYourPassword': {
      'en': 'Please confirm your password',
      'es': 'Confirma tu contraseña',
    },
    'createPasswordPrompt': {
      'en': 'Please create a password',
      'es': 'Crea una contraseña',
    },
    'passwordTooShort': {
      'en': 'Password must be at least 6 characters',
      'es': 'La contraseña debe tener al menos 6 caracteres',
    },
    'passwordsDoNotMatch': {
      'en': 'Passwords do not match',
      'es': 'Las contraseñas no coinciden',
    },
    'createAccountTitle': {
      'en': 'Create account',
      'es': 'Crear cuenta',
    },
    'joinTollCamHeadline': {
      'en': 'Join TollCam',
      'es': 'Únete a TollCam',
    },
    'fullNameLabel': {
      'en': 'Full name',
      'es': 'Nombre completo',
    },
    'emailLabel': {
      'en': 'Email',
      'es': 'Correo electrónico',
    },
    'passwordLabel': {
      'en': 'Password',
      'es': 'Contraseña',
    },
    'confirmPasswordLabel': {
      'en': 'Confirm password',
      'es': 'Confirmar contraseña',
    },
    'createAccountAction': {
      'en': 'Create account',
      'es': 'Crear cuenta',
    },
    'alreadyHaveAccountPrompt': {
      'en': 'Already have an account? Log in',
      'es': '¿Ya tienes una cuenta? Inicia sesión',
    },
    'welcomeHeadline': {
      'en': 'Welcome',
      'es': 'Bienvenido',
    },
    'continueAction': {
      'en': 'Continue',
      'es': 'Continuar',
    },
    'createNewAccountPrompt': {
      'en': 'Create a new account',
      'es': 'Crea una cuenta nueva',
    },
    'unknownUser': {
      'en': 'Unknown user',
      'es': 'Usuario desconocido',
    },
    'profileTitle': {
      'en': 'Your profile',
      'es': 'Tu perfil',
    },
    'profileSubtitle': {
      'en': 'Manage your TollCam account and preferences.',
      'es': 'Administra tu cuenta de TollCam y tus preferencias.',
    },
    'logOutAction': {
      'en': 'Log out',
      'es': 'Cerrar sesión',
    },
    'failedToLoadSegments': {
      'en': 'Failed to load segments.',
      'es': 'No se pudieron cargar los segmentos.',
    },
    'retryAction': {
      'en': 'Retry',
      'es': 'Reintentar',
    },
    'yesAction': {
      'en': 'Yes',
      'es': 'Sí',
    },
    'noAction': {
      'en': 'No',
      'es': 'No',
    },
    'cancelAction': {
      'en': 'Cancel',
      'es': 'Cancelar',
    },
    'deleteAction': {
      'en': 'Delete',
      'es': 'Eliminar',
    },
    'drawerSync': {
      'en': 'Sync',
      'es': 'Sincronizar',
    },
    'drawerSegments': {
      'en': 'Segments',
      'es': 'Segmentos',
    },
    'drawerLanguage': {
      'en': 'Language',
      'es': 'Idioma',
    },
    'drawerProfile': {
      'en': 'Profile',
      'es': 'Perfil',
    },
    'languageSelectionTitle': {
      'en': 'Select language',
      'es': 'Seleccionar idioma',
    },
    'languageComingSoon': {
      'en': 'Coming soon',
      'es': 'Muy pronto',
    },
    'createAccountDrawerTitle': {
      'en': 'Create an account',
      'es': 'Crear una cuenta',
    },
    'segmentsTitle': {
      'en': 'Segments',
      'es': 'Segmentos',
    },
    'localSegmentsTooltip': {
      'en': 'Local segments',
      'es': 'Segmentos locales',
    },
    'createSegmentAction': {
      'en': 'Create segment',
      'es': 'Crear segmento',
    },
    'localSegmentsTitle': {
      'en': 'Local segments',
      'es': 'Segmentos locales',
    },
    'noSegmentsAvailable': {
      'en': 'No segments available.',
      'es': 'No hay segmentos disponibles.',
    },
    'noLocalSegmentsSaved': {
      'en': 'No local segments saved yet.',
      'es': 'Aún no hay segmentos locales guardados.',
    },
    'segmentStartLabel': {
      'en': 'Start',
      'es': 'Inicio',
    },
    'segmentEndLabel': {
      'en': 'End',
      'es': 'Fin',
    },
    'segmentHiddenBadge': {
      'en': 'Hidden',
      'es': 'Oculto',
    },
    'segmentLocalBadge': {
      'en': 'Local',
      'es': 'Local',
    },
    'segmentReviewBadge': {
      'en': 'Review',
      'es': 'Revisión',
    },
    'fineTuneSegmentHeadline': {
      'en': 'Fine-tune the segment on the map',
      'es': 'Ajusta el segmento en el mapa',
    },
    'adjustSegmentInstructions': {
      'en': 'Drop or drag markers to adjust the start and end points.',
      'es': 'Suelta o arrastra marcadores para ajustar los puntos inicial y final.',
    },
    'segmentCoordinatesAutoFill': {
      'en': 'Coordinates are filled automatically as you move them.',
      'es': 'Las coordenadas se completan automáticamente al moverlos.',
    },
    'segmentDetailsSectionTitle': {
      'en': 'Segment details',
      'es': 'Detalles del segmento',
    },
    'segmentNameLabel': {
      'en': 'Segment name',
      'es': 'Nombre del segmento',
    },
    'roadNameLabel': {
      'en': 'Road name',
      'es': 'Nombre de la vía',
    },
    'segmentStartNameHint': {
      'en': 'Start name',
      'es': 'Nombre de inicio',
    },
    'segmentEndNameHint': {
      'en': 'End name',
      'es': 'Nombre de finalización',
    },
    'segmentStartCoordinatesLabel': {
      'en': 'Start coordinates',
      'es': 'Coordenadas de inicio',
    },
    'segmentEndPointLabel': {
      'en': 'End point',
      'es': 'Punto final',
    },
    'saveSegmentAction': {
      'en': 'Save segment',
      'es': 'Guardar segmento',
    },
    'mapDataFromLabel': {
      'en': 'Map data from ',
      'es': 'Datos del mapa de ',
    },
    'openStreetMapLabel': {
      'en': 'OpenStreetMap',
      'es': 'OpenStreetMap',
    },
    'segmentAlreadyApprovedAndPublic': {
      'en':
          'Segment {displayId} was already approved by the administrators and is public.',
      'es':
          'El segmento {displayId} ya fue aprobado por los administradores y es público.',
    },
    'segmentDistanceMeters': {
      'en': '{meters} m',
      'es': '{meters} m',
    },
    'segmentDistanceKmLeft': {
      'en': '{kilometers} km left',
      'es': 'quedan {kilometers} km',
    },
    'segmentHeadingDifference': {
      'en': 'Δθ={degrees}°',
      'es': 'Δθ={degrees}°',
    },
    'segmentDebugTagDetailed': {
      'en': 'detailed',
      'es': 'detallado',
    },
    'segmentDebugTagApprox': {
      'en': 'approx',
      'es': 'aprox',
    },
    'segmentDebugTagDirectionPass': {
      'en': 'dir✔',
      'es': 'dir✔',
    },
    'segmentDebugTagDirectionFail': {
      'en': 'dir✖',
      'es': 'dir✖',
    },
    'segmentDebugTagStart': {
      'en': 'start',
      'es': 'inicio',
    },
    'segmentDebugTagEnd': {
      'en': 'end',
      'es': 'fin',
    },
    'averageSpeedBanner': {
      'en': 'avg speed for the last segment: {speed}kph',
      'es': 'vel. media del último segmento: {speed} km/h',
    },
    'segmentsDebugCountRadius': {
      'en': 'Segments: {count}  r={radius}m',
      'es': 'Segmentos: {count}  r={radius}m',
    },
    'fabRecenterLabel': {
      'en': 'Recenter',
      'es': 'Centrar',
    },
    'segmentMaxSpeed': {
      'en': 'Max speed: {speed} km/h',
      'es': 'Velocidad máx.: {speed} km/h',
    },
    'avgSpeedDialLimitLabel': {
      'en': 'Limit: ',
      'es': 'Límite: ',
    },
    'avgSpeedDialNoSegment': {
      'en': 'no active segment',
      'es': 'sin segmento activo',
    },
    'averageSpeedTitle': {
      'en': 'Avg Speed',
      'es': 'Vel. media',
    },
    'mapHintPlacePointA': {
      'en': 'Tap anywhere on the map to place point A.',
      'es': 'Toca cualquier lugar del mapa para colocar el punto A.',
    },
    'mapHintPlacePointB': {
      'en': 'Tap a second location to place point B.',
      'es': 'Toca un segundo lugar para colocar el punto B.',
    },
    'mapHintDragPoint': {
      'en':
          'Touch and hold A or B for 0.5s, then drag to reposition that point.',
      'es':
          'Mantén presionado A o B durante 0,5 s y arrastra para reposicionar ese punto.',
    },
    'failedToLoadCameras': {
      'en': 'Failed to load cameras: {error}',
      'es': 'No se pudieron cargar las cámaras: {error}',
    },
    'distanceToSegmentEndKm': {
      'en': '{distance} km to segment end',
      'es': '{distance} km hasta el final del segmento',
    },
    'distanceToSegmentEndMeters': {
      'en': '{distance} m to segment end',
      'es': '{distance} m hasta el final del segmento',
    },
    'segmentEndNearby': {
      'en': 'Segment end nearby',
      'es': 'Fin del segmento cercano',
    },
    'distanceToSegmentStartKm': {
      'en': '{distance} km to segment start',
      'es': '{distance} km hasta el inicio del segmento',
    },
    'distanceToSegmentStartMeters': {
      'en': '{distance} m to segment start',
      'es': '{distance} m hasta el inicio del segmento',
    },
    'segmentStartNearby': {
      'en': 'Segment start nearby',
      'es': 'Inicio del segmento cercano',
    },
    'openMenuTooltip': {
      'en': 'Open menu',
      'es': 'Abrir menú',
    },
    'failedToAccessSegmentsMetadataFile': {
      'en': 'Failed to access the segments metadata file.',
      'es': 'No se pudo acceder al archivo de metadatos de segmentos.',
    },
    'failedToParseSegmentsMetadataFile': {
      'en': 'Failed to parse the segments metadata file.',
      'es': 'No se pudieron analizar los metadatos de segmentos.',
    },
    'failedToWriteSegmentsMetadataFile': {
      'en': 'Failed to write to the segments metadata file.',
      'es': 'No se pudo escribir en el archivo de metadatos de segmentos.',
    },
    'failedToSubmitSegmentForModerationWithReason': {
      'en': 'Failed to submit the segment for moderation: {reason}',
      'es': 'No se pudo enviar el segmento para moderación: {reason}',
    },
    'failedToCheckSubmissionStatusWithReason': {
      'en': 'Failed to check the public submission status: {reason}',
      'es': 'No se pudo comprobar el estado del envío público: {reason}',
    },
    'failedToCancelSubmissionWithReason': {
      'en': 'Failed to cancel the public submission: {reason}',
      'es': 'No se pudo cancelar el envío público: {reason}',
    },
    'failedToDownloadTollSegments': {
      'en': 'Failed to download toll segments: {reason}',
      'es': 'No se pudieron descargar los segmentos de peaje: {reason}',
    },
    'failedToAccessTollSegmentsFile': {
      'en': 'Failed to access the toll segments file: {reason}',
      'es': 'No se pudo acceder al archivo de segmentos de peaje: {reason}',
    },
    'failedToDetermineTollSegmentsPath': {
      'en': 'Failed to determine the local toll segments storage path.',
      'es': 'No se pudo determinar la ruta local para guardar los segmentos.',
    },
    'segmentMetadataUpdateUnavailable': {
      'en': 'Segment metadata cannot be updated on the web.',
      'es': 'Los metadatos de segmentos no se pueden actualizar en la web.',
    },
    'supabaseNotConfiguredForModeration': {
      'en':
          'Supabase is not configured. Unable to submit the segment for moderation.',
      'es':
          'Supabase no está configurado. No es posible enviar el segmento para moderación.',
    },
    'supabaseNotConfiguredForPublicSubmissions': {
      'en':
          'Supabase is not configured. Unable to manage public submissions.',
      'es':
          'Supabase no está configurado. No es posible gestionar envíos públicos.',
    },
    'userRequiredForPublicModeration': {
      'en':
          'A logged in user is required to submit a public segment for moderation.',
      'es':
          'Se necesita un usuario autenticado para enviar un segmento público a moderación.',
    },
    'noConnectionUnableToSubmitForModeration': {
      'en':
          'No internet connection. Unable to submit the segment for moderation.',
      'es':
          'Sin conexión a internet. No es posible enviar el segmento para moderación.',
    },
    'noConnectionUnableToManageSubmissions': {
      'en': 'No internet connection. Unable to manage public submissions.',
      'es': 'Sin conexión a internet. No es posible gestionar envíos públicos.',
    },
    'unexpectedErrorSubmittingForModeration': {
      'en': 'Unexpected error while submitting the segment for moderation.',
      'es': 'Error inesperado al enviar el segmento para moderación.',
    },
    'unexpectedErrorCheckingSubmissionStatus': {
      'en': 'Unexpected error while checking the public submission status.',
      'es': 'Error inesperado al comprobar el estado del envío público.',
    },
    'unexpectedErrorCancellingSubmission': {
      'en': 'Unexpected error while cancelling the public submission.',
      'es': 'Error inesperado al cancelar el envío público.',
    },
    'unableToAssignNewSegmentId': {
      'en':
          'Unable to assign a new segment id: all smallint values are exhausted.',
      'es':
          'No se puede asignar un nuevo ID de segmento: se agotaron los valores smallint.',
    },
    'nonNumericSegmentIdEncountered': {
      'en': 'Encountered an existing segment with a non-numeric id.',
      'es': 'Se encontró un segmento existente con un ID no numérico.',
    },
    'syncNotSupportedOnWeb': {
      'en': 'Syncing toll segments is not supported on the web.',
      'es': 'La sincronización de segmentos de peaje no es compatible en la web.',
    },
    'tableReturnedNoRows': {
      'en': 'The {tableName} table did not return any rows.',
      'es': 'La tabla {tableName} no devolvió ninguna fila.',
    },
    'noTollSegmentRowsFound': {
      'en':
          'No toll segment rows were returned from Supabase. Checked tables: {tablesChecked}. Ensure your account has access to the data.',
      'es':
          'Supabase no devolvió filas de segmentos de peaje. Tablas verificadas: {tablesChecked}. Asegúrate de que tu cuenta tenga acceso a los datos.',
    },
    'tableMissingModerationColumn': {
      'en':
          'The "{tableName}" table is missing the "{column}" column required for moderation.',
      'es':
          'La tabla "{tableName}" no tiene la columna "{column}" necesaria para la moderación.',
    },
    'csvMissingStartEndColumns': {
      'en': 'CSV must contain "Start" and "End" columns',
      'es': 'El CSV debe contener las columnas "Start" y "End"',
    },
    'missingRequiredColumn': {
      'en': 'Missing required column "{column}" in the Toll_Segments table.',
      'es': 'Falta la columna obligatoria "{column}" en la tabla Toll_Segments.',
    },
    'signInToSharePubliclyTitle': {
      'en': 'Sign in to share publicly',
      'es': 'Inicia sesión para compartir públicamente',
    },
    'signInToSharePubliclyBody': {
      'en':
          'You need to be logged in to submit a public segment. Would you like to log in or save the segment locally instead?',
      'es':
          'Debes iniciar sesión para enviar un segmento público. ¿Quieres iniciar sesión o guardar el segmento localmente?',
    },
    'saveLocallyAction': {
      'en': 'Save locally',
      'es': 'Guardar localmente',
    },
    'loginAction': {
      'en': 'Login',
      'es': 'Iniciar sesión',
    },
    'failedToSaveSegmentLocally': {
      'en': 'Failed to save the segment locally.',
      'es': 'No se pudo guardar el segmento localmente.',
    },
    'startEndCoordinatesRequired': {
      'en': 'Start and end coordinates are required.',
      'es': 'Se requieren las coordenadas de inicio y fin.',
    },
    'loggedInRetrySavePrompt': {
      'en':
          'Logged in successfully. Tap "Save segment" again to submit the segment.',
      'es':
          'Inicio de sesión correcto. Pulsa "Guardar segmento" nuevamente para enviarlo.',
    },
    'osmCopyrightLaunchFailed': {
      'en': 'Could not open the OpenStreetMap copyright page.',
      'es': 'No se pudo abrir la página de derechos de autor de OpenStreetMap.',
    },
    'failedToLoadSegmentPreferences': {
      'en': 'Failed to load segment preferences: {errorMessage}',
      'es': 'No se pudieron cargar las preferencias de segmentos: {errorMessage}',
    },
    'supabaseNotConfiguredForSync': {
      'en':
          'Supabase is not configured. Please add credentials to enable sync.',
      'es':
          'Supabase no está configurado. Agrega credenciales para habilitar la sincronización.',
    },
    'unexpectedSyncError': {
      'en': 'Unexpected error while syncing toll segments.',
      'es': 'Error inesperado al sincronizar segmentos de peaje.',
    },
    'segmentLabelSingular': {
      'en': 'segment',
      'es': 'segmento',
    },
    'segmentLabelPlural': {
      'en': 'segments',
      'es': 'segmentos',
    },
    'syncAddedSegments': {
      'en': '{count} {segmentLabel} added',
      'es': 'Se añadieron {count} {segmentLabel}',
    },
    'syncRemovedSegments': {
      'en': '{count} {segmentLabel} removed',
      'es': 'Se eliminaron {count} {segmentLabel}',
    },
    'syncNoChangesDetected': {
      'en': 'No changes detected.',
      'es': 'No se detectaron cambios.',
    },
    'syncChangesSeparator': {
      'en': ', ',
      'es': ', ',
    },
    'syncChangesPeriod': {
      'en': '.',
      'es': '.',
    },
    'syncCompleteHeadline': {
      'en':
          'Sync complete. {changesSummary} {totalSegments} total segments available.',
      'es':
          'Sincronización completa. {changesSummary} {totalSegments} segmentos totales disponibles.',
    },
    'syncApprovedSegments': {
      'en':
          '{count} of your submitted segments {wasVerb} approved and now {visibilityVerb} visible to everyone.',
      'es':
          '{count} de tus segmentos enviados {wasVerb} aprobados y ahora {visibilityVerb} visibles para todos.',
    },
    'syncVerbWas': {
      'en': 'was',
      'es': 'fue',
    },
    'syncVerbWere': {
      'en': 'were',
      'es': 'fueron',
    },
    'syncVerbIs': {
      'en': 'is',
      'es': 'está',
    },
    'syncVerbAre': {
      'en': 'are',
      'es': 'están',
    },
  };
}
