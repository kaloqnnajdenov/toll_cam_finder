import 'package:flutter/foundation.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/widgets/background_location_consent_overlay.dart';

import 'package:toll_cam_finder/shared/services/background_location_consent_controller.dart';
import 'package:toll_cam_finder/shared/services/notification_permission_service.dart';
import 'package:toll_cam_finder/shared/services/permission_service.dart';

class LocationPermissionFlowState {
  const LocationPermissionFlowState({
    required this.locationPermissionGranted,
    required this.showLocationPermissionInfo,
    required this.locationPermissionTemporarilyDenied,
    required this.isRequestingForegroundPermission,
    required this.showNotificationPermissionInfo,
    required this.notificationPermissionTemporarilyDenied,
    required this.isRequestingNotificationPermission,
    required this.backgroundLocationAllowed,
    required this.notificationsEnabled,
    required this.hasSystemBackgroundPermission,
    required this.isRequestingBackgroundPermission,
    required this.showBackgroundConsent,
    required this.pendingBackgroundConsent,
  });

  final bool locationPermissionGranted;
  final bool showLocationPermissionInfo;
  final bool locationPermissionTemporarilyDenied;
  final bool isRequestingForegroundPermission;

  final bool showNotificationPermissionInfo;
  final bool notificationPermissionTemporarilyDenied;
  final bool isRequestingNotificationPermission;

  final bool? backgroundLocationAllowed;
  final bool notificationsEnabled;
  final bool hasSystemBackgroundPermission;
  final bool isRequestingBackgroundPermission;

  final bool showBackgroundConsent;
  final BackgroundLocationConsentOption? pendingBackgroundConsent;

  LocationPermissionFlowState copyWith({
    bool? locationPermissionGranted,
    bool? showLocationPermissionInfo,
    bool? locationPermissionTemporarilyDenied,
    bool? isRequestingForegroundPermission,
    bool? showNotificationPermissionInfo,
    bool? notificationPermissionTemporarilyDenied,
    bool? isRequestingNotificationPermission,
    Object? backgroundLocationAllowed = _unsetBackgroundAllowed,
    bool? notificationsEnabled,
    bool? hasSystemBackgroundPermission,
    bool? isRequestingBackgroundPermission,
    bool? showBackgroundConsent,
    BackgroundLocationConsentOption? pendingBackgroundConsent,
  }) {
    return LocationPermissionFlowState(
      locationPermissionGranted:
          locationPermissionGranted ?? this.locationPermissionGranted,
      showLocationPermissionInfo:
          showLocationPermissionInfo ?? this.showLocationPermissionInfo,
      locationPermissionTemporarilyDenied:
          locationPermissionTemporarilyDenied ??
              this.locationPermissionTemporarilyDenied,
      isRequestingForegroundPermission:
          isRequestingForegroundPermission ??
              this.isRequestingForegroundPermission,
      showNotificationPermissionInfo:
          showNotificationPermissionInfo ?? this.showNotificationPermissionInfo,
      notificationPermissionTemporarilyDenied:
      notificationPermissionTemporarilyDenied ??
          this.notificationPermissionTemporarilyDenied,
      isRequestingNotificationPermission:
          isRequestingNotificationPermission ??
              this.isRequestingNotificationPermission,
      backgroundLocationAllowed: backgroundLocationAllowed ==
              _unsetBackgroundAllowed
          ? this.backgroundLocationAllowed
          : backgroundLocationAllowed as bool?,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      hasSystemBackgroundPermission:
          hasSystemBackgroundPermission ?? this.hasSystemBackgroundPermission,
      isRequestingBackgroundPermission:
          isRequestingBackgroundPermission ??
              this.isRequestingBackgroundPermission,
      showBackgroundConsent: showBackgroundConsent ?? this.showBackgroundConsent,
      pendingBackgroundConsent:
          pendingBackgroundConsent == _unsetConsentSelection
              ? this.pendingBackgroundConsent
              : pendingBackgroundConsent,
    );
  }
}

// ignore: constant_identifier_names
const _unsetConsentSelection = Object();
const _unsetBackgroundAllowed = Object();

class LocationPermissionFlow extends ChangeNotifier {
  LocationPermissionFlow({
    required PermissionService permissionService,
    required NotificationPermissionService notificationPermissionService,
    required BackgroundLocationConsentController backgroundConsentController,
    bool? initialBackgroundConsentAllowed,
  })  : _permissionService = permissionService,
        _notificationPermissionService = notificationPermissionService,
        _backgroundConsentController = backgroundConsentController,
        _state = LocationPermissionFlowState(
          locationPermissionGranted: false,
          showLocationPermissionInfo: false,
          locationPermissionTemporarilyDenied: false,
          isRequestingForegroundPermission: false,
          showNotificationPermissionInfo: false,
          notificationPermissionTemporarilyDenied: false,
          isRequestingNotificationPermission: false,
          backgroundLocationAllowed: initialBackgroundConsentAllowed,
          notificationsEnabled: true,
          hasSystemBackgroundPermission: false,
          isRequestingBackgroundPermission: false,
          showBackgroundConsent: false,
          pendingBackgroundConsent: null,
        );

  final PermissionService _permissionService;
  final NotificationPermissionService _notificationPermissionService;
  final BackgroundLocationConsentController _backgroundConsentController;

  LocationPermissionFlowState _state;

  LocationPermissionFlowState get state => _state;

  void setLocationPermissionGranted(bool granted) {
    if (_state.locationPermissionGranted == granted) {
      return;
    }
    _updateState(_state.copyWith(locationPermissionGranted: granted));
  }

  void setBackgroundConsentAllowed(bool? allowed) {
    bool showLocation = _state.showLocationPermissionInfo;
    bool showNotification = _state.showNotificationPermissionInfo;

    if (allowed == true) {
      showLocation = false;
    } else if (allowed == false) {
      showNotification = false;
    }

    _updateState(
      _state.copyWith(
        backgroundLocationAllowed: allowed,
        showLocationPermissionInfo: showLocation,
        showNotificationPermissionInfo: showNotification,
      ),
    );
  }

  void setHasSystemBackgroundPermission(bool granted) {
    if (_state.hasSystemBackgroundPermission == granted) {
      return;
    }
    _updateState(_state.copyWith(hasSystemBackgroundPermission: granted));
  }

  void setNotificationsEnabled(
    bool enabled, {
    required bool backgroundAllowed,
  }) {
    final bool shouldShowBanner =
        backgroundAllowed && !enabled && !_state.notificationPermissionTemporarilyDenied;
    _updateState(
      _state.copyWith(
        notificationsEnabled: enabled,
        showNotificationPermissionInfo: shouldShowBanner,
      ),
    );
  }

  void setLocationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    if (visible) {
      if (_state.locationPermissionTemporarilyDenied) {
        return;
      }
      _updateState(_state.copyWith(showLocationPermissionInfo: true));
      return;
    }

    _updateState(
      _state.copyWith(
        showLocationPermissionInfo: false,
        locationPermissionTemporarilyDenied: resetTemporaryDismissal
            ? false
            : _state.locationPermissionTemporarilyDenied,
      ),
    );
  }

  void setNotificationPermissionBannerVisible(
    bool visible, {
    bool resetTemporaryDismissal = true,
  }) {
    if (visible) {
      if (_state.notificationPermissionTemporarilyDenied) {
        return;
      }
      _updateState(_state.copyWith(showNotificationPermissionInfo: true));
      return;
    }

    _updateState(
      _state.copyWith(
        showNotificationPermissionInfo: false,
        notificationPermissionTemporarilyDenied: resetTemporaryDismissal
            ? false
            : _state.notificationPermissionTemporarilyDenied,
      ),
    );
  }

  void temporarilyDismissLocationPermissionPrompt() {
    _updateState(
      _state.copyWith(
        locationPermissionTemporarilyDenied: true,
        showLocationPermissionInfo: false,
      ),
    );
  }

  void temporarilyDismissNotificationPermissionPrompt() {
    _updateState(
      _state.copyWith(
        notificationPermissionTemporarilyDenied: true,
        showNotificationPermissionInfo: false,
      ),
    );
  }

  Future<bool> requestForegroundPermission() async {
    if (_state.isRequestingForegroundPermission) {
      return _state.locationPermissionGranted;
    }

    _updateState(
      _state.copyWith(isRequestingForegroundPermission: true),
    );

    bool granted = false;
    try {
      granted = await _permissionService.ensureForegroundPermission();
    } finally {
      _updateState(
        _state.copyWith(
          isRequestingForegroundPermission: false,
          locationPermissionGranted: granted,
          showLocationPermissionInfo: granted ? false : true,
        ),
      );
    }

    return granted;
  }

  Future<bool> ensureNotificationPermission({
    required bool backgroundAllowed,
  }) async {
    final bool enabled =
        await _notificationPermissionService.areNotificationsEnabled();
    final bool shouldShowBanner =
        backgroundAllowed && !enabled && !_state.notificationPermissionTemporarilyDenied;
    _updateState(
      _state.copyWith(
        notificationsEnabled: enabled,
        showNotificationPermissionInfo: shouldShowBanner,
      ),
    );
    return enabled;
  }

  Future<bool> requestNotificationPermission({
    required bool backgroundAllowed,
  }) async {
    if (_state.isRequestingNotificationPermission) {
      return _state.notificationsEnabled;
    }

    _updateState(
      _state.copyWith(isRequestingNotificationPermission: true),
    );

    final bool granted = await _notificationPermissionService.ensurePermissionGranted();
    _updateState(
      _state.copyWith(
        isRequestingNotificationPermission: false,
        notificationsEnabled: granted,
        showNotificationPermissionInfo:
            backgroundAllowed && !granted && !_state.notificationPermissionTemporarilyDenied,
      ),
    );

    return granted;
  }

  Future<bool> requestSystemBackgroundPermission({
    bool showDeniedMessage = true,
    void Function(String message)? showDeniedMessageCallback,
    required String deniedMessage,
  }) async {
    if (_state.isRequestingBackgroundPermission) {
      return false;
    }

    final bool alreadyGranted =
        await _permissionService.hasBackgroundPermission();
    if (alreadyGranted) {
      _updateState(_state.copyWith(hasSystemBackgroundPermission: true));
      return true;
    }

    _updateState(_state.copyWith(isRequestingBackgroundPermission: true));
    bool granted = false;
    try {
      granted = await _permissionService.ensureBackgroundPermission();
    } finally {
      _updateState(
        _state.copyWith(
          isRequestingBackgroundPermission: false,
          hasSystemBackgroundPermission: granted,
        ),
      );
    }

    if (!granted && showDeniedMessage && showDeniedMessageCallback != null) {
      showDeniedMessageCallback(deniedMessage);
    }

    return granted;
  }

  void presentBackgroundConsentOverlay({required bool prefillSelection}) {
    final bool? allowed = _state.backgroundLocationAllowed;
    final BackgroundLocationConsentOption? pending =
        prefillSelection && allowed != null
            ? (allowed
                ? BackgroundLocationConsentOption.allow
                : BackgroundLocationConsentOption.deny)
            : null;
    _updateState(
      _state.copyWith(
        showBackgroundConsent: true,
        pendingBackgroundConsent: pending,
      ),
    );
  }

  void selectBackgroundConsent(
    BackgroundLocationConsentOption? option,
  ) {
    _updateState(
      _state.copyWith(pendingBackgroundConsent: option),
    );
  }

  Future<void> persistBackgroundConsent(bool allow) async {
    await _backgroundConsentController.setAllowed(allow);
    _updateState(
      _state.copyWith(
        backgroundLocationAllowed: allow,
        showBackgroundConsent: false,
        pendingBackgroundConsent: null,
      ),
    );
  }

  void hideBackgroundConsentOverlay() {
    _updateState(
      _state.copyWith(
        showBackgroundConsent: false,
        pendingBackgroundConsent: null,
      ),
    );
  }

  void _updateState(LocationPermissionFlowState next) {
    _state = next;
    notifyListeners();
  }
}
