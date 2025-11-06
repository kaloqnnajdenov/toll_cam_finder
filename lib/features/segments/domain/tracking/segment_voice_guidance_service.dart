import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

/// Coordinates all spoken guidance for toll-road segments.
///
/// The class reacts to [SegmentTrackerEvent] updates and issues voice prompts
/// according to the business rules described in the specification. English
/// prompts are generated with text-to-speech while Bulgarian prompts play from
/// bundled audio assets.
class SegmentVoiceGuidanceService {
  SegmentVoiceGuidanceService({SegmentVoiceMessenger? messenger})
      : _messenger = messenger ?? SegmentVoiceMessenger();

  final SegmentVoiceMessenger _messenger;

  String? _activeSegmentId;
  double? _currentLimitKph;
  double? _currentSegmentLengthMeters;
  bool _endWarningIssued = false;
  bool _nextSegmentStartsImmediately = false;
  bool _wasAboveLimitOnLastCheck = false;
  bool _hasBeenAboveLimit = false;
  bool _announcedBelowAfterAbove = false;
  DateTime? _lastAboveAnnouncementAt;
  double? _lastKnownDistanceFromStartMeters;

  String? _lastApproachSegmentId;
  DateTime? _lastApproachAnnouncedAt;
  double? _lastApproachAnnouncedDistance;

  static const Duration _aboveReminderInterval = Duration(seconds: 30);
  static const Duration _approachCooldown = Duration(minutes: 2);
  static const double _approachTriggerDistanceMeters = 800;
  static const double _aboveReminderStartDistanceMeters = 1000;
  static const double _speedReminderCutoffMeters = 1500;
  static const double _headingToleranceDegrees = 45;

  void updateAudioPolicy(GuidanceAudioPolicy policy) {
    _messenger.updateAudioPolicy(policy);
  }

  void updateLanguage(String languageCode) {
    _messenger.updateLanguage(languageCode);
  }

  Future<void> reset() async {
    _clearActiveSegmentState();
    _resetUpcomingApproachState();
    await _messenger.stop();
  }

  Future<void> dispose() => _messenger.dispose();

  Future<void> handleUpdate({
    required SegmentTrackerEvent event,
    required SegmentDebugPath? activePath,
    required double averageKph,
    required double? speedLimitKph,
    required DateTime now,
    double? headingDegrees,
  }) async {
    if (event.endedSegment) {
      await _handleSegmentExit();
    }

    if (event.startedSegment) {
      await _handleSegmentEntry(
        limitKph: speedLimitKph,
        lengthMeters: event.activeSegmentLengthMeters,
      );
    }

    final String? activeId = event.activeSegmentId;
    if (activeId == null) {
      _clearActiveSegmentState();
      await _maybeAnnounceUpcomingSegment(
        candidates: event.debugData.candidatePaths,
        headingDegrees: headingDegrees,
        now: now,
      );
      return;
    }

    _activeSegmentId = activeId;
    _currentLimitKph = speedLimitKph;
    if (event.activeSegmentLengthMeters != null &&
        event.activeSegmentLengthMeters!.isFinite) {
      _currentSegmentLengthMeters =
          _normalizeDistance(event.activeSegmentLengthMeters);
    }

    await _handleActiveSegment(
      event: event,
      path: activePath ??
          _resolveActivePath(event.debugData.candidatePaths, activeId),
      averageKph: averageKph,
      now: now,
      headingDegrees: headingDegrees,
    );
  }

  Future<void> _handleSegmentEntry({
    double? limitKph,
    double? lengthMeters,
  }) async {
    _activeSegmentId = null;
    _currentLimitKph = limitKph;
    _currentSegmentLengthMeters = _normalizeDistance(lengthMeters);
    _endWarningIssued = false;
    _nextSegmentStartsImmediately = false;
    _wasAboveLimitOnLastCheck = false;
    _hasBeenAboveLimit = false;
    _announcedBelowAfterAbove = false;
    _lastAboveAnnouncementAt = null;
    _lastKnownDistanceFromStartMeters = null;
    _resetUpcomingApproachState();

    await _messenger.deliverPrompt(
      englishMessage: 'Segment started.',
      bulgarianAsset: AppConstants.segmentEnteredVoiceAsset,
    );
  }

  Future<void> _handleSegmentExit() async {
    if (_nextSegmentStartsImmediately) {
      _nextSegmentStartsImmediately = false;
      _clearActiveSegmentState();
      return;
    }

    await _messenger.deliverPrompt(
      englishMessage: 'Segment ended.',
      bulgarianAsset: AppConstants.segmentEndedVoiceAsset,
    );
    _clearActiveSegmentState();
  }

  Future<void> _handleActiveSegment({
    required SegmentTrackerEvent event,
    required SegmentDebugPath? path,
    required double averageKph,
    required DateTime now,
    double? headingDegrees,
  }) async {
    final double? remaining = _normalizeDistance(path?.remainingDistanceMeters);
    final double? distanceFromStart =
        _normalizeDistance(path?.startDistanceMeters);
    final double? distanceForCheck =
        distanceFromStart ?? _lastKnownDistanceFromStartMeters;
    if (distanceFromStart != null) {
      _lastKnownDistanceFromStartMeters = distanceFromStart;
    }

    await _checkAverageSpeed(
      averageKph: averageKph,
      remainingMeters: remaining,
      distanceFromStartMeters: distanceForCheck,
      now: now,
    );

    if (!_endWarningIssued &&
        remaining != null &&
        remaining > 0 &&
        remaining <= _approachTriggerDistanceMeters) {
      final bool hasImmediateNext = _hasImmediateNextSegment(
        event: event,
        remainingMeters: remaining,
        headingDegrees: headingDegrees,
      );
      await _announceSegmentEnding(
        averageKph: averageKph,
        hasImmediateNextSegment: hasImmediateNext,
      );
      _endWarningIssued = true;
      _nextSegmentStartsImmediately = hasImmediateNext;
    }
  }

  Future<void> _checkAverageSpeed({
    required double averageKph,
    required double? remainingMeters,
    required double? distanceFromStartMeters,
    required DateTime now,
  }) async {
    final double? limit = _currentLimitKph;
    if (limit == null || !limit.isFinite || !averageKph.isFinite) {
      _wasAboveLimitOnLastCheck = false;
      return;
    }

    final bool isAbove = averageKph > limit;
    final double? progressMeters = _computeProgressMeters(
      distanceFromStartMeters: distanceFromStartMeters,
      remainingMeters: remainingMeters,
      segmentLengthMeters: _currentSegmentLengthMeters,
    );
    final bool pastInitialDistance = progressMeters != null &&
        progressMeters >= _aboveReminderStartDistanceMeters;
    final bool outsideFinalWindow = remainingMeters == null ||
        remainingMeters > _speedReminderCutoffMeters;
    final bool allowReminder = pastInitialDistance && outsideFinalWindow;

    if (isAbove) {
      _hasBeenAboveLimit = true;
      _announcedBelowAfterAbove = false;
      if (allowReminder) {
        final bool shouldAnnounce =
            !_wasAboveLimitOnLastCheck ||
            _lastAboveAnnouncementAt == null ||
            now.difference(_lastAboveAnnouncementAt!) >=
                _aboveReminderInterval;
        if (shouldAnnounce) {
          _wasAboveLimitOnLastCheck = true;
          _lastAboveAnnouncementAt = now;
          await _messenger.deliverPrompt(
            englishMessage: 'Average above limit. Reduce speed.',
            bulgarianAsset: AppConstants.averageAboveAllowedVoiceAsset,
          );
        }
      }
    } else if (_hasBeenAboveLimit && !_announcedBelowAfterAbove) {
      await _messenger.deliverPrompt(
        englishMessage: 'Average speed is under the limit.',
        bulgarianAsset: AppConstants.averageBackWithinAllowedVoiceAsset,
      );
      _announcedBelowAfterAbove = true;
      _lastAboveAnnouncementAt = null;
    } else {
      _lastAboveAnnouncementAt = null;
    }

    _wasAboveLimitOnLastCheck = isAbove;

    if (!isAbove && averageKph <= limit) {
      _hasBeenAboveLimit = _hasBeenAboveLimit && _announcedBelowAfterAbove;
    }
  }

  Future<void> _announceSegmentEnding({
    required double averageKph,
    required bool hasImmediateNextSegment,
  }) async {
    final _SpeedStatus status =
        _speedStatusFor(averageKph: averageKph, limitKph: _currentLimitKph);

    if (hasImmediateNextSegment) {
      final String englishMessage = status == _SpeedStatus.unknown
          ? 'Segment ends in about 800 meters. After the current segment ends, another one begins.'
          : 'Segment ends in about 800 meters. Speed is ${status == _SpeedStatus.above ? 'above' : 'below'} allowed. After the current segment ends, another one begins.';

      await _messenger.deliverPrompt(
        englishMessage: englishMessage,
        bulgarianAsset: AppConstants.segmentEndingWithNextVoiceAsset,
      );

      await _playSpeedFollowUp(status);
      return;
    }

    final String englishMessage = status == _SpeedStatus.unknown
        ? 'Segment ends in about 800 meters.'
        : 'Segment ends in about 800 meters. Speed is ${status == _SpeedStatus.above ? 'above' : 'below'} allowed.';

    await _messenger.deliverPrompt(
      englishMessage: englishMessage,
      bulgarianAsset: AppConstants.segmentEndingSoonVoiceAsset,
    );

    await _playSpeedFollowUp(status);
  }

  Future<void> _playSpeedFollowUp(_SpeedStatus status) async {
    if (_messenger.isUsingBulgarianAudio) {
      return;
    }
    switch (status) {
      case _SpeedStatus.above:
        await _messenger.playBulgarianAsset(
          AppConstants.segmentSpeedAboveVoiceAsset,
        );
        break;
      case _SpeedStatus.belowOrEqual:
        await _messenger.playBulgarianAsset(
          AppConstants.segmentSpeedBelowVoiceAsset,
        );
        break;
      case _SpeedStatus.unknown:
        break;
    }
  }

  Future<void> _maybeAnnounceUpcomingSegment({
    required Iterable<SegmentDebugPath> candidates,
    required double? headingDegrees,
    required DateTime now,
  }) async {
    if (headingDegrees == null) {
      return;
    }

    final SegmentDebugPath? upcoming = _findUpcomingSegment(
      candidates: candidates,
      headingDegrees: headingDegrees,
    );
    if (upcoming == null) {
      return;
    }

    final double distance = upcoming.startDistanceMeters;
    if (distance <= 0 || distance > _approachTriggerDistanceMeters) {
      if (_lastApproachSegmentId == upcoming.id &&
          _lastApproachAnnouncedDistance != null &&
          distance > _lastApproachAnnouncedDistance! + 200) {
        _resetUpcomingApproachState();
      }
      return;
    }

    final bool shouldAnnounce =
        _lastApproachSegmentId != upcoming.id ||
            _lastApproachAnnouncedAt == null ||
            now.difference(_lastApproachAnnouncedAt!) > _approachCooldown;

    if (!shouldAnnounce) {
      return;
    }

    await _messenger.deliverPrompt(
      englishMessage: 'You are approaching a segment with monitored average speed.',
      bulgarianAsset: AppConstants.approachingSegmentVoiceAsset,
    );

    _lastApproachSegmentId = upcoming.id;
    _lastApproachAnnouncedAt = now;
    _lastApproachAnnouncedDistance = distance;
  }

  SegmentDebugPath? _resolveActivePath(
    Iterable<SegmentDebugPath> paths,
    String activeId,
  ) {
    for (final SegmentDebugPath path in paths) {
      if (path.id == activeId && path.isActive) {
        return path;
      }
    }
    for (final SegmentDebugPath path in paths) {
      if (path.id == activeId) {
        return path;
      }
    }
    for (final SegmentDebugPath path in paths) {
      if (path.isActive) {
        return path;
      }
    }
    return null;
  }

  SegmentDebugPath? _findUpcomingSegment({
    required Iterable<SegmentDebugPath> candidates,
    required double headingDegrees,
  }) {
    SegmentDebugPath? closest;
    for (final SegmentDebugPath path in candidates) {
      if (path.startDistanceMeters.isNaN || path.startDistanceMeters < 0) {
        continue;
      }
      if (path.startDistanceMeters > _approachTriggerDistanceMeters) {
        continue;
      }

      final double? segmentHeading =
          _extractPolylineHeading(path.polyline, atEnd: false);
      if (segmentHeading == null) {
        continue;
      }
      final double delta =
          _minimalHeadingDeltaDegrees(segmentHeading, headingDegrees);
      if (delta > _headingToleranceDegrees) {
        continue;
      }

      if (closest == null ||
          path.startDistanceMeters < closest.startDistanceMeters) {
        closest = path;
      }
    }
    return closest;
  }

  bool _hasImmediateNextSegment({
    required SegmentTrackerEvent event,
    required double? remainingMeters,
    required double? headingDegrees,
  }) {
    final String? activeId = event.activeSegmentId;
    if (activeId == null || remainingMeters == null) {
      return false;
    }

    final double? activeHeading = _extractHeadingForSegment(
      event.debugData.candidatePaths,
      segmentId: activeId,
      atEnd: true,
    );

    for (final SegmentDebugPath path in event.debugData.candidatePaths) {
      if (path.id == activeId) {
        continue;
      }
      final double startDistance = path.startDistanceMeters;
      if (!startDistance.isFinite || startDistance < 0) {
        continue;
      }
      if ((startDistance - remainingMeters).abs() > 120) {
        continue;
      }

      final double? segmentHeading =
          _extractPolylineHeading(path.polyline, atEnd: false);
      if (segmentHeading == null) {
        continue;
      }

      if (activeHeading != null) {
        final double delta =
            _minimalHeadingDeltaDegrees(segmentHeading, activeHeading);
        if (delta <= _headingToleranceDegrees) {
          return true;
        }
        continue;
      }

      if (headingDegrees != null) {
        final double delta =
            _minimalHeadingDeltaDegrees(segmentHeading, headingDegrees);
        if (delta <= _headingToleranceDegrees) {
          return true;
        }
      } else {
        return true;
      }
    }

    return false;
  }

  double? _extractHeadingForSegment(
    Iterable<SegmentDebugPath> paths, {
    required String segmentId,
    required bool atEnd,
  }) {
    for (final SegmentDebugPath path in paths) {
      if (path.id == segmentId) {
        return _extractPolylineHeading(path.polyline, atEnd: atEnd);
      }
    }
    return null;
  }

  double? _extractPolylineHeading(List<LatLng> polyline, {required bool atEnd}) {
    if (polyline.length < 2) {
      return null;
    }

    if (atEnd) {
      for (int i = polyline.length - 1; i > 0; i--) {
        final LatLng current = polyline[i];
        final LatLng previous = polyline[i - 1];
        final double? bearing = _bearingBetween(previous, current);
        if (bearing != null) {
          return bearing;
        }
      }
    } else {
      for (int i = 0; i < polyline.length - 1; i++) {
        final LatLng current = polyline[i];
        final LatLng next = polyline[i + 1];
        final double? bearing = _bearingBetween(current, next);
        if (bearing != null) {
          return bearing;
        }
      }
    }

    return null;
  }

  double? _bearingBetween(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180.0;
    final double lat2 = to.latitude * math.pi / 180.0;
    final double dLon = (to.longitude - from.longitude) * math.pi / 180.0;

    if (dLon.abs() <= 1e-9 && (lat2 - lat1).abs() <= 1e-9) {
      return null;
    }

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final double bearing = math.atan2(y, x) * 180.0 / math.pi;
    return (bearing + 360) % 360;
  }

  double _minimalHeadingDeltaDegrees(double a, double b) {
    final double delta = (a - b).abs() % 360;
    return delta > 180 ? 360 - delta : delta;
  }

  double? _computeProgressMeters({
    double? distanceFromStartMeters,
    double? remainingMeters,
    double? segmentLengthMeters,
  }) {
    if (distanceFromStartMeters != null) {
      return _normalizeDistance(distanceFromStartMeters);
    }

    if (segmentLengthMeters != null &&
        remainingMeters != null &&
        segmentLengthMeters.isFinite &&
        remainingMeters.isFinite) {
      final double progress = segmentLengthMeters - remainingMeters;
      return _normalizeDistance(progress);
    }

    return null;
  }

  double? _normalizeDistance(double? value) {
    if (value == null || !value.isFinite) {
      return null;
    }
    return value < 0 ? 0 : value;
  }

  void _clearActiveSegmentState() {
    _activeSegmentId = null;
    _currentLimitKph = null;
    _currentSegmentLengthMeters = null;
    _endWarningIssued = false;
    _nextSegmentStartsImmediately = false;
    _wasAboveLimitOnLastCheck = false;
    _hasBeenAboveLimit = false;
    _announcedBelowAfterAbove = false;
    _lastAboveAnnouncementAt = null;
    _lastKnownDistanceFromStartMeters = null;
  }

  void _resetUpcomingApproachState() {
    _lastApproachSegmentId = null;
    _lastApproachAnnouncedAt = null;
    _lastApproachAnnouncedDistance = null;
  }

  _SpeedStatus _speedStatusFor({
    required double averageKph,
    required double? limitKph,
  }) {
    if (!averageKph.isFinite || limitKph == null || !limitKph.isFinite) {
      return _SpeedStatus.unknown;
    }
    if (averageKph > limitKph) {
      return _SpeedStatus.above;
    }
    return _SpeedStatus.belowOrEqual;
  }
}

enum _SpeedStatus { above, belowOrEqual, unknown }

/// Handles low-level audio playback for [SegmentVoiceGuidanceService].
class SegmentVoiceMessenger {
  SegmentVoiceMessenger({FlutterTts? tts, AudioPlayer? player})
      : _tts = tts ?? FlutterTts(),
        _player = player ?? AudioPlayer(playerId: 'segment-voice-guidance') {
    unawaited(_initialize());
  }

  final FlutterTts _tts;
  final AudioPlayer _player;
  bool _useBulgarian = false;
  GuidanceAudioPolicy _audioPolicy = const GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );
  int _englishSpeechSequence = 0;
  int? _activeEnglishSpeechId;
  String? _activeEnglishMessage;

  bool get isUsingBulgarianAudio => _useBulgarian;

  Future<void> _initialize() async {
    await _tts.awaitSpeakCompletion(true);
    await _configurePlayer();
    await _configureTts();
  }

  void updateAudioPolicy(GuidanceAudioPolicy policy) {
    if (_audioPolicy == policy) {
      return;
    }
    final bool hadSpeech = _audioPolicy.allowSpeech;
    _audioPolicy = policy;
    if (hadSpeech && !policy.allowSpeech) {
      unawaited(stop());
    }
  }

  void updateLanguage(String languageCode) {
    final String normalized = languageCode.toLowerCase();
    final bool useBg = normalized == 'bg' || normalized.startsWith('bg-');
    if (_useBulgarian == useBg) {
      return;
    }
    _useBulgarian = useBg;
    unawaited(_updateTtsLanguage());
  }

  Future<void> deliverPrompt({
    required String englishMessage,
    required String bulgarianAsset,
  }) async {
    if (!_audioPolicy.allowSpeech) {
      return;
    }

    if (_useBulgarian) {
      await _playAsset(bulgarianAsset);
      return;
    }

    final String message = englishMessage.trim();
    if (message.isEmpty) {
      return;
    }

    final bool isDuplicateInFlight =
        _activeEnglishSpeechId != null && _activeEnglishMessage == message;
    if (isDuplicateInFlight) {
      return;
    }

    await _speakEnglish(message);
  }

  Future<void> playBulgarianAsset(String asset) async {
    if (!_useBulgarian || !_audioPolicy.allowSpeech) {
      return;
    }
    await _playAsset(asset);
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {
      // best effort
    }
    try {
      await _player.stop();
    } catch (_) {
      // best effort
    }
    _activeEnglishSpeechId = null;
    _activeEnglishMessage = null;
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }

  Future<void> _configurePlayer() async {
    try {
      await _player.setAudioContext(navigationAudioContext);
    } catch (_) {
      // best effort
    }
  }

  Future<void> _configureTts() async {
    try {
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        <IosTextToSpeechAudioCategoryOptions>[
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
          IosTextToSpeechAudioCategoryOptions.interruptSpokenAudioAndMixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    } catch (_) {
      // best effort
    }

    await _updateTtsLanguage();
  }

  Future<void> _playAsset(String asset) async {
    try {
      await _player.stop();
    } catch (_) {
      // best effort
    }
    try {
      await _player.play(AssetSource(asset));
    } catch (_) {
      // best effort
    }
  }

  Future<void> _speakEnglish(String message) async {
    final int speechId = ++_englishSpeechSequence;
    _activeEnglishSpeechId = speechId;
    _activeEnglishMessage = message;
    try {
      await _speak(message);
    } finally {
      if (_activeEnglishSpeechId == speechId) {
        _activeEnglishSpeechId = null;
        _activeEnglishMessage = null;
      }
    }
  }

  Future<void> _speak(String message) async {
    try {
      await _tts.stop();
    } catch (_) {
      // best effort
    }
    try {
      await _tts.speak(message);
    } catch (_) {
      // best effort
    }
  }

  Future<void> _updateTtsLanguage() async {
    final String locale = _useBulgarian ? 'bg-BG' : 'en-US';
    try {
      await _tts.setLanguage(locale);
    } catch (_) {
      // best effort
    }
  }
}
