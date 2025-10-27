import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/tracking/segment_tracker.dart';
import 'package:toll_cam_finder/shared/audio/navigation_audio_context.dart';

class SegmentGuidanceUiModel {
  const SegmentGuidanceUiModel({
    required this.line1,
    required this.line2,
    this.line3,
  });

  final String line1;
  final String line2;
  final String? line3;
}

class SegmentGuidanceResult {
  const SegmentGuidanceResult._({this.ui, this.shouldClear = false});

  factory SegmentGuidanceResult.update(SegmentGuidanceUiModel ui) =>
      SegmentGuidanceResult._(ui: ui);

  factory SegmentGuidanceResult.clear() =>
      const SegmentGuidanceResult._(shouldClear: true);

  final SegmentGuidanceUiModel? ui;
  final bool shouldClear;
}

class SegmentGuidanceController {
  SegmentGuidanceController({FlutterTts? tts, AudioPlayer? tonePlayer})
      : _tts = tts ?? FlutterTts(),
        _tonePlayer = tonePlayer ?? AudioPlayer(playerId: 'segment-guidance') {
    unawaited(_tts.awaitSpeakCompletion(true));
    unawaited(_configureTonePlayer());
    unawaited(_configureTextToSpeech());
  }

  static const Duration _quietInterval = Duration(seconds: 20);
  static const double _quietDistanceMeters = 500.0;
  static const Duration _aboveLimitGrace = Duration(seconds: 5);
  static const double _initialSpeechSuppressionDistanceMeters = 200.0;
  static const String _toneAsset = 'data/ding_sound.mp3';
  static const Duration _exitAnnouncementGrace = Duration(seconds: 4);
  bool _suppressGuidanceAudio = false;
  bool _useBulgarianVoice = false;
  double? _furthestDistanceFromStart;

  final FlutterTts _tts;
  final AudioPlayer _tonePlayer;
  GuidanceAudioPolicy _audioPolicy = const GuidanceAudioPolicy(
    allowSpeech: true,
    allowAlertTones: true,
    allowBoundaryTones: true,
  );

  bool _hasActiveSegment = false;
  double? _currentLimitKph;
  DateTime? _lastUiUpdateAt;
  double? _lastRemainingMeters;
  bool _closeToLimitNotified = false;
  DateTime? _aboveLimitSince;
  bool _aboveLimitAlerted = false;
  bool _wasOverLimit = false;
  bool _approachAnnounced = false;
  _PendingExitAnnouncement? _pendingExitAnnouncement;
  Timer? _exitAnnouncementTimer;

  void updateAudioPolicy(GuidanceAudioPolicy policy) {
    if (_audioPolicy == policy) {
      return;
    }

    final bool hadSpeech = _audioPolicy.allowSpeech;
    final bool hadAlerts = _audioPolicy.allowAlertTones;
    final bool hadBoundary = _audioPolicy.allowBoundaryTones;
    _audioPolicy = policy;

    if (!policy.allowSpeech && hadSpeech) {
      unawaited(_tts.stop());
      if (_useBulgarianVoice) {
        unawaited(_tonePlayer.stop());
      }
    }
    if ((!policy.allowAlertTones && hadAlerts) ||
        (!policy.allowBoundaryTones && hadBoundary)) {
      unawaited(_tonePlayer.stop());
    }
  }

  void updateLanguage(String languageCode) {
    final String normalized = languageCode.toLowerCase();
    final bool useBulgarian = normalized == 'bg' || normalized.startsWith('bg-');
    if (_useBulgarianVoice == useBulgarian) {
      return;
    }
    _useBulgarianVoice = useBulgarian;
    unawaited(_updateTtsLanguage());
  }

  Future<SegmentGuidanceResult?> handleUpdate({
    required SegmentTrackerEvent event,
    required SegmentDebugPath? activePath,
    required double averageKph,
    required double? speedLimitKph,
    required DateTime now,
    required DateTime? averageStartedAt,
  }) async {
    if (event.startedSegment) {
      await _handleSegmentEntry(limitKph: speedLimitKph);
    }

    if (event.endedSegment || event.activeSegmentId == null) {
      if (_hasActiveSegment) {
        _hasActiveSegment = false;
        await _handleSegmentExit(averageKph: averageKph);
        await reset(stopTts: false);
        return SegmentGuidanceResult.clear();
      }
      return null;
    }

    _hasActiveSegment = true;
    _currentLimitKph = speedLimitKph;

    final double? remainingMeters = _normalizeDistance(
      activePath?.remainingDistanceMeters,
    );
    final double? segmentLength = _normalizeDistance(
      event.activeSegmentLengthMeters,
    );
    double? distanceFromStart = _normalizeDistance(
      activePath?.startDistanceMeters,
    );
    if (distanceFromStart == null &&
        segmentLength != null &&
        remainingMeters != null) {
      distanceFromStart = _normalizeDistance(segmentLength - remainingMeters);
    }

    if (_suppressGuidanceAudio && distanceFromStart != null) {
      final double furthest = _furthestDistanceFromStart == null
          ? distanceFromStart
          : math.max(_furthestDistanceFromStart!, distanceFromStart);
      _furthestDistanceFromStart = furthest;
      if (furthest >= _initialSpeechSuppressionDistanceMeters) {
        _suppressGuidanceAudio = false;
      }
    } else if (_furthestDistanceFromStart == null &&
        distanceFromStart != null) {
      _furthestDistanceFromStart = distanceFromStart;
    }

    bool forceUi = event.startedSegment;
    bool triggered = false;
    final bool allowSpeech =
        !_suppressGuidanceAudio && _audioPolicy.allowSpeech;

    if (_currentLimitKph != null && _currentLimitKph!.isFinite) {
      triggered |= await _checkCloseToLimit(
        averageKph: averageKph,
        allowSpeech: allowSpeech,
      );
      triggered |= await _checkLimitBreaches(now: now, averageKph: averageKph, allowSpeech: allowSpeech
      );
    }

    triggered |= await _checkApproachingExit(
      remainingMeters: remainingMeters,
      averageKph: averageKph,
      allowSpeech: allowSpeech,
    );

    final bool shouldEmitQuietUpdate = _shouldEmitQuietUpdate(
      now: now,
      remainingMeters: remainingMeters,
    );

    if (!forceUi && !triggered && !shouldEmitQuietUpdate) {
      return null;
    }

    final SegmentGuidanceUiModel ui = _buildUiModel(
      averageKph: averageKph,
      limitKph: _currentLimitKph,
      remainingMeters: remainingMeters,
      now: now,
      averageStartedAt: averageStartedAt,
    );

    _lastUiUpdateAt = now;
    if (remainingMeters != null) {
      _lastRemainingMeters = remainingMeters;
    }

    return SegmentGuidanceResult.update(ui);
  }

  Future<void> reset({bool stopTts = true}) async {
    _hasActiveSegment = false;
    _currentLimitKph = null;
    _lastUiUpdateAt = null;
    _lastRemainingMeters = null;
    _closeToLimitNotified = false;
    _aboveLimitSince = null;
    _aboveLimitAlerted = false;
    _wasOverLimit = false;
    _approachAnnounced = false;
    _suppressGuidanceAudio = false;
    _furthestDistanceFromStart = null;
    _pendingExitAnnouncement = null;
    _exitAnnouncementTimer?.cancel();
    _exitAnnouncementTimer = null;
    if (stopTts) {
      await _tts.stop();
    }
  }

  Future<void> dispose() async {
    await reset();
    await _tonePlayer.dispose();
  }

  Future<void> _configureTonePlayer() async {
    try {
      await _tonePlayer.setAudioContext(navigationAudioContext);
    } catch (_) {
      // Ignored: best-effort configuration.
    }
  }

  Future<void> _configureTextToSpeech() async {
    // The FlutterTts package used in this project does not expose a
    // setAudioAttributesForNavigation() method. Keep this as a best-effort
    // no-op for Android/other platforms and only call the iOS-specific
    // configuration that exists on the FlutterTts instance.
    try {
      // No-op placeholder for platform-specific audio attribute config.
      // If you later add a package or extension that provides Android audio
      // attribute configuration, call it here.
      await Future<void>.value();
    } catch (_) {
      // Ignored: best-effort configuration.
    }

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
      // Ignored: best-effort configuration.
    }

    await _updateTtsLanguage();
  }

  Future<void> _handleSegmentEntry({double? limitKph}) async {
    _hasActiveSegment = true;
    _currentLimitKph = limitKph;
    _lastUiUpdateAt = null;
    _lastRemainingMeters = null;
    _closeToLimitNotified = false;
    _aboveLimitSince = null;
    _aboveLimitAlerted = false;
    _wasOverLimit = false;
    _approachAnnounced = false;
    _suppressGuidanceAudio = true;
    _furthestDistanceFromStart = null;

    final _PendingExitAnnouncement? exitAnnouncement =
        _takePendingExitAnnouncementForCombination();
    if (exitAnnouncement != null) {
      await _announceCombinedBoundary(
        exitAnnouncement,
        nextLimitKph: limitKph,
      );
      return;
    }

    if (_useBulgarianVoice) {
      await _playVoicePrompt(AppConstants.segmentEnteredVoiceAsset);
      return;
    }

    await _playChime(times: 2, isBoundary: true);

    final String limitText = (limitKph != null && limitKph.isFinite)
        ? 'Limit ${limitKph.toStringAsFixed(0)}.'
        : 'Limit unknown.';
    await _speak('Zone started. $limitText Tracking average speed.');
  }

  Future<void> _handleSegmentExit({required double averageKph}) async {
    final double? limit =
        (_currentLimitKph != null && _currentLimitKph!.isFinite)
        ? _currentLimitKph
        : null;
    final bool hasAverage = averageKph.isFinite;

    _scheduleExitAnnouncement(
      limitKph: limit,
      averageKph: hasAverage ? averageKph : null,
    );
  }

  void _scheduleExitAnnouncement({
    double? limitKph,
    double? averageKph,
  }) {
    _pendingExitAnnouncement = _PendingExitAnnouncement(
      createdAt: DateTime.now(),
      useVoicePrompt: _useBulgarianVoice,
      limitKph: limitKph,
      averageKph: averageKph,
    );
    _exitAnnouncementTimer?.cancel();
    _exitAnnouncementTimer = Timer(_exitAnnouncementGrace, () {
      final _PendingExitAnnouncement? pending = _pendingExitAnnouncement;
      _pendingExitAnnouncement = null;
      if (pending != null) {
        unawaited(_deliverExitAnnouncement(pending));
      }
    });
  }

  Future<bool> _checkCloseToLimit({
    required double averageKph,
    required bool allowSpeech,
  }) async {
    final double limit = _currentLimitKph!;
    final double threshold = limit * 0.95;
    if (!_closeToLimitNotified &&
        allowSpeech &&
        averageKph >= threshold &&
        averageKph < limit) {
      _closeToLimitNotified = true;
      await _playChime();
      await _speak('Close to limit.');
      return true;
    }

    if (_closeToLimitNotified && averageKph <= threshold - 2) {
      _closeToLimitNotified = false;
    }
    return false;
  }

  Future<bool> _checkLimitBreaches({
    required DateTime now,
    required double averageKph,
    required bool allowSpeech,
  }) async {
    final double limit = _currentLimitKph!;
    final double margin = 1.0;

    if (averageKph > limit + margin) {
      _wasOverLimit = true;
      _aboveLimitSince ??= now;
      if (!_aboveLimitAlerted &&          allowSpeech &&
          now.difference(_aboveLimitSince!) >= _aboveLimitGrace) {
        _aboveLimitAlerted = true;
        await _playChime(times: 2, spacing: const Duration(milliseconds: 180));
        await _speak('Average above limit. Reduce speed.');
        return true;
      }
      return false;
    }

    _aboveLimitSince = null;
    if (_wasOverLimit && averageKph <= limit) {
      if (!allowSpeech) {
        return false;
      }
      _wasOverLimit = false;
      _aboveLimitAlerted = false;
      await _playChime();
      await _speak('Average back within limit.');
      return true;
    }

    if (averageKph <= limit - 1) {
      _aboveLimitAlerted = false;
    }

    return false;
  }

  Future<bool> _checkApproachingExit({
    required double? remainingMeters,
    required double averageKph,
    required bool allowSpeech,
  }) async {
    if (_approachAnnounced || !allowSpeech) {
      return false;
    }
    if (remainingMeters == null) {
      return false;
    }
    if (remainingMeters > 800 || remainingMeters <= 0) {
      return false;
    }

    _approachAnnounced = true;

    if (_useBulgarianVoice) {
      await _playVoicePrompt(AppConstants.segmentEndingSoonVoiceAsset);
      return true;
    }

    final double? limit =
        (_currentLimitKph != null && _currentLimitKph!.isFinite)
        ? _currentLimitKph
        : null;

    if (limit != null && averageKph > limit) {
      final int rounded = (remainingMeters / 50).round() * 50;
      final String distanceText = rounded >= 1000
          ? '${(rounded / 1000).toStringAsFixed(1)} km'
          : '$rounded m';
      final String avgText = averageKph.toStringAsFixed(0);
      final String limitText = limit.toStringAsFixed(0);
      await _speak('$distanceText to end. Average speed is $avgText, speed limit is $limitText.');
    } else {
      await _playChime();
    }
    return true;
  }

  bool _shouldEmitQuietUpdate({
    required DateTime now,
    required double? remainingMeters,
  }) {
    if (_lastUiUpdateAt == null) {
      return true;
    }

    final Duration since = now.difference(_lastUiUpdateAt!);
    if (since < _quietInterval) {
      return false;
    }

    if (remainingMeters == null || _lastRemainingMeters == null) {
      return true;
    }

    final double delta = _lastRemainingMeters! - remainingMeters;
    return delta >= _quietDistanceMeters;
  }

  SegmentGuidanceUiModel _buildUiModel({
    required double averageKph,
    required double? limitKph,
    required double? remainingMeters,
    required DateTime now,
    required DateTime? averageStartedAt,
  }) {
    final String avgText = averageKph.isFinite
        ? averageKph.toStringAsFixed(0)
        : '--';
    final String limitText = (limitKph != null && limitKph.isFinite)
        ? limitKph.toStringAsFixed(0)
        : '--';
    final String line1 = 'Avg: $avgText | Limit: $limitText (km/h)';

    final String remainingText = _formatRemaining(remainingMeters);
    final String deltaText = _formatDelta(averageKph, limitKph);
    final String line2 = 'Rem: $remainingText | Δavg: $deltaText';

    final double? safeSpeed = _estimateSafeSpeed(
      averageKph: averageKph,
      limitKph: limitKph,
      remainingMeters: remainingMeters,
      now: now,
      averageStartedAt: averageStartedAt,
    );

    final String? line3 = safeSpeed != null
        ? 'Est. safe speed now: ${safeSpeed.toStringAsFixed(0)} (computed to finish ≤ limit)'
        : null;

    return SegmentGuidanceUiModel(line1: line1, line2: line2, line3: line3);
  }

  String _formatRemaining(double? remainingMeters) {
    if (remainingMeters == null || !remainingMeters.isFinite) {
      return '--';
    }
    if (remainingMeters >= 1000) {
      return '${(remainingMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${remainingMeters.toStringAsFixed(0)} m';
  }

  String _formatDelta(double averageKph, double? limitKph) {
    if (limitKph == null || !limitKph.isFinite || !averageKph.isFinite) {
      return '--';
    }
    final double delta = averageKph - limitKph;
    final String sign = delta >= 0 ? '+' : '-';
    return '$sign${delta.abs().toStringAsFixed(0)}';
  }

  double? _estimateSafeSpeed({
    required double averageKph,
    required double? limitKph,
    required double? remainingMeters,
    required DateTime now,
    required DateTime? averageStartedAt,
  }) {
    if (limitKph == null || !limitKph.isFinite) {
      return null;
    }
    if (!averageKph.isFinite) {
      return null;
    }
    if (remainingMeters == null ||
        !remainingMeters.isFinite ||
        remainingMeters <= 0) {
      return null;
    }
    if (averageStartedAt == null) {
      return null;
    }

    final double remainingKm = remainingMeters / 1000.0;
    final Duration elapsed = now.difference(averageStartedAt);
    final double elapsedHours = elapsed.inSeconds / 3600.0;
    if (elapsedHours <= 0) {
      return limitKph;
    }

    final double denominator =
        (averageKph - limitKph) * elapsedHours + remainingKm;
    if (denominator <= 0) {
      return limitKph;
    }
    final double required = (limitKph * remainingKm) / denominator;
    if (!required.isFinite) {
      return limitKph;
    }
    final double clamped = math.max(0, required);
    return clamped;
  }

  double? _normalizeDistance(double? value) {
    if (value == null || !value.isFinite) {
      return null;
    }
    if (value < 0) {
      return 0;
    }
    return value;
  }

  Future<void> _playVoicePrompt(String asset) async {
    if (!_audioPolicy.allowSpeech) {
      return;
    }
    try {
      await _tts.stop();
    } catch (_) {
      // best effort
    }
    try {
      await _tonePlayer.stop();
    } catch (_) {
      // best effort
    }
    try {
      await _tonePlayer.play(AssetSource(asset));
    } catch (_) {
      // best effort
    }
  }

  Future<void> _playChime({
    int times = 1,
    Duration spacing = const Duration(milliseconds: 250),
    bool isBoundary = false,
  }) async {
    if (!_audioPolicy.canPlayTone(isBoundary: isBoundary)) {
      return;
    }
    for (int i = 0; i < times; i++) {
      await _tonePlayer.stop();
      await _tonePlayer.play(AssetSource(_toneAsset));
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (i < times - 1) {
        await Future<void>.delayed(spacing);
      }
    }
  }

  Future<void> _speak(String message) async {
    await _tts.stop();
    if (!_audioPolicy.allowSpeech) {
      return;
    }
    await _tts.speak(message);
  }

  Future<void> _updateTtsLanguage() async {
    final String locale = _useBulgarianVoice ? 'bg-BG' : 'en-US';
    try {
      await _tts.setLanguage(locale);
    } catch (_) {
      // best effort
    }
  }

  _PendingExitAnnouncement? _takePendingExitAnnouncementForCombination() {
    final _PendingExitAnnouncement? pending = _pendingExitAnnouncement;
    if (pending == null) {
      return null;
    }

    if (DateTime.now().difference(pending.createdAt) > _exitAnnouncementGrace) {
      return null;
    }

    _pendingExitAnnouncement = null;
    _exitAnnouncementTimer?.cancel();
    _exitAnnouncementTimer = null;
    return pending;
  }

  Future<void> _announceCombinedBoundary(
    _PendingExitAnnouncement exitAnnouncement, {
    double? nextLimitKph,
  }) async {
    await _playChime(times: 2, isBoundary: true);

    final bool isBulgarian = _useBulgarianVoice;
    final String limitText =
        _formatBoundaryValue(exitAnnouncement.limitKph, bulgarian: isBulgarian);
    final String averageText =
        _formatBoundaryValue(exitAnnouncement.averageKph, bulgarian: isBulgarian);
    final String nextLimitText =
        _formatBoundaryValue(nextLimitKph, bulgarian: isBulgarian);

    if (isBulgarian) {
      final String message =
          'Предишната зона приключи. Позволена средна $limitText. Твоята средна $averageText. '
          'Започва нова зона. Ограничението е $nextLimitText. Следим средната скорост.';
      await _speak(message);
      return;
    }

    final String message =
        'Previous zone complete. Allowed average $limitText. Your average $averageText. '
        'Next zone started. Limit $nextLimitText. Tracking average speed.';
    await _speak(message);
  }

  Future<void> _deliverExitAnnouncement(
    _PendingExitAnnouncement announcement,
  ) async {
    if (announcement.useVoicePrompt) {
      await _playVoicePrompt(AppConstants.segmentEndedVoiceAsset);
      return;
    }

    await _playChime(isBoundary: true);

    final String limitText =
        _formatBoundaryValue(announcement.limitKph, bulgarian: false);
    final String averageText =
        _formatBoundaryValue(announcement.averageKph, bulgarian: false);

    await _speak(
      'Zone complete. Allowed average $limitText. Your average $averageText.',
    );
  }

  String _formatBoundaryValue(
    double? value, {
    required bool bulgarian,
  }) {
    if (value == null || !value.isFinite) {
      return bulgarian ? 'неизвестно' : 'unknown';
    }
    return value.toStringAsFixed(0);
  }
}

class _PendingExitAnnouncement {
  const _PendingExitAnnouncement({
    required this.createdAt,
    required this.useVoicePrompt,
    this.limitKph,
    this.averageKph,
  });

  final DateTime createdAt;
  final bool useVoicePrompt;
  final double? limitKph;
  final double? averageKph;
}
