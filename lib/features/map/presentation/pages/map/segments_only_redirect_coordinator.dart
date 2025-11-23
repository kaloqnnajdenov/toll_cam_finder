import 'dart:async';

import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';

typedef _OpenSimpleModePage = Future<void> Function(
  SegmentsOnlyModeReason reason,
);
typedef _CloseSimpleModePage = Future<void> Function();

class SegmentsOnlyRedirectCoordinator {
  SegmentsOnlyRedirectCoordinator({
    required SegmentsOnlyModeController controller,
    required _OpenSimpleModePage onOpenSimpleModePage,
    required _CloseSimpleModePage onCloseSimpleModePageIfOpen,
    Duration redirectDelay = const Duration(seconds: 3),
    required bool Function() hasConnectivity,
    required bool Function() isOsmServiceAvailable,
  })  : _controller = controller,
        _onOpenSimpleModePage = onOpenSimpleModePage,
        _onCloseSimpleModePageIfOpen = onCloseSimpleModePageIfOpen,
        _redirectDelay = redirectDelay,
        _hasConnectivity = hasConnectivity,
        _isOsmServiceAvailable = isOsmServiceAvailable;

  final SegmentsOnlyModeController _controller;
  final _OpenSimpleModePage _onOpenSimpleModePage;
  final _CloseSimpleModePage _onCloseSimpleModePageIfOpen;
  final Duration _redirectDelay;
  final bool Function() _hasConnectivity;
  final bool Function() _isOsmServiceAvailable;

  Timer? _offlineRedirectTimer;
  Timer? _osmUnavailableRedirectTimer;
  bool _simpleModePageOpen = false;

  bool get isSimpleModePageOpen => _simpleModePageOpen;

  void handleConnectivityChanged(bool isConnected) {
    if (!isConnected) {
      _controller.enterMode(SegmentsOnlyModeReason.offline);
      _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason.offline);
      return;
    }

    _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason.offline);
    if (_controller.reason == SegmentsOnlyModeReason.offline) {
      _controller.exitMode();
      if (_simpleModePageOpen) {
        unawaited(closeSimpleModePageIfOpen());
      }
    }
  }

  void handleOsmServiceRecovered() {
    _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason.osmUnavailable);
    if (_controller.reason == SegmentsOnlyModeReason.osmUnavailable) {
      _controller.exitMode();
      if (_simpleModePageOpen) {
        unawaited(closeSimpleModePageIfOpen());
      }
    }
  }

  void handleOsmUnavailableBeyondGrace() {
    if (_controller.reason != SegmentsOnlyModeReason.osmUnavailable) {
      _controller.enterMode(SegmentsOnlyModeReason.osmUnavailable);
    }
    _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason.osmUnavailable);
  }

  Future<void> openSimpleModePage(SegmentsOnlyModeReason reason) async {
    _controller.enterMode(reason);
    if (_simpleModePageOpen) {
      return;
    }

    _simpleModePageOpen = true;
    try {
      await _onOpenSimpleModePage(reason);
    } finally {
      _simpleModePageOpen = false;
      if (_shouldExitSegmentsOnlyModeAfterNav(reason)) {
        _controller.exitMode();
      }
    }
  }

  Future<void> closeSimpleModePageIfOpen() async {
    if (!_simpleModePageOpen) {
      return;
    }
    await _onCloseSimpleModePageIfOpen();
  }

  void dispose() {
    _offlineRedirectTimer?.cancel();
    _osmUnavailableRedirectTimer?.cancel();
  }

  void _scheduleSegmentsOnlyRedirect(SegmentsOnlyModeReason reason) {
    if (reason == SegmentsOnlyModeReason.manual) {
      return;
    }

    final Timer? existing = _redirectTimerFor(reason);
    if (existing?.isActive ?? false) {
      return;
    }

    final Timer timer = Timer(_redirectDelay, () {
      _setRedirectTimer(reason, null);
      if (_controller.reason != reason) {
        return;
      }
      unawaited(openSimpleModePage(reason));
    });

    _setRedirectTimer(reason, timer);
  }

  void _cancelSegmentsOnlyRedirectTimer(SegmentsOnlyModeReason reason) {
    final Timer? existing = _redirectTimerFor(reason);
    existing?.cancel();
    _setRedirectTimer(reason, null);
  }

  Timer? _redirectTimerFor(SegmentsOnlyModeReason reason) {
    switch (reason) {
      case SegmentsOnlyModeReason.offline:
        return _offlineRedirectTimer;
      case SegmentsOnlyModeReason.osmUnavailable:
        return _osmUnavailableRedirectTimer;
      case SegmentsOnlyModeReason.manual:
        return null;
    }
  }

  void _setRedirectTimer(SegmentsOnlyModeReason reason, Timer? timer) {
    switch (reason) {
      case SegmentsOnlyModeReason.offline:
        _offlineRedirectTimer = timer;
        break;
      case SegmentsOnlyModeReason.osmUnavailable:
        _osmUnavailableRedirectTimer = timer;
        break;
      case SegmentsOnlyModeReason.manual:
        break;
    }
  }

  bool _shouldExitSegmentsOnlyModeAfterNav(SegmentsOnlyModeReason reason) {
    final SegmentsOnlyModeReason? currentReason = _controller.reason;

    if (!_controller.isActive || currentReason == null) {
      return true;
    }

    if (currentReason != reason) {
      return true;
    }

    switch (reason) {
      case SegmentsOnlyModeReason.manual:
        return true;
      case SegmentsOnlyModeReason.offline:
        return _hasConnectivity();
      case SegmentsOnlyModeReason.osmUnavailable:
        return _isOsmServiceAvailable();
    }
  }
}
