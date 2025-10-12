import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:toll_cam_finder/services/segment_tracker.dart';

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
  }

  static const Duration _quietInterval = Duration(seconds: 20);
  static const double _quietDistanceMeters = 500.0;
  static const Duration _aboveLimitGrace = Duration(seconds: 5);
  static const String _toneAsset = 'data/ding_sound.mp3';

  final FlutterTts _tts;
  final AudioPlayer _tonePlayer;

  bool _hasActiveSegment = false;
  double? _currentLimitKph;
  DateTime? _lastUiUpdateAt;
  double? _lastRemainingMeters;
  bool _closeToLimitNotified = false;
  DateTime? _aboveLimitSince;
  bool _aboveLimitAlerted = false;
  bool _wasOverLimit = false;
  bool _approachAnnounced = false;

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
        await reset();
        return SegmentGuidanceResult.clear();
      }
      return null;
    }

    _hasActiveSegment = true;
    _currentLimitKph = speedLimitKph;

    final double? remainingMeters =
        _normalizeDistance(activePath?.remainingDistanceMeters);

    bool forceUi = event.startedSegment;
    bool triggered = false;

    if (_currentLimitKph != null && _currentLimitKph!.isFinite) {
      triggered |= await _checkCloseToLimit(averageKph: averageKph);
      triggered |= await _checkLimitBreaches(
        now: now,
        averageKph: averageKph,
      );
    }

    triggered |= await _checkApproachingExit(
      remainingMeters: remainingMeters,
      averageKph: averageKph,
    );

    final bool shouldEmitQuietUpdate =
        _shouldEmitQuietUpdate(now: now, remainingMeters: remainingMeters);

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

  Future<void> reset() async {
    _hasActiveSegment = false;
    _currentLimitKph = null;
    _lastUiUpdateAt = null;
    _lastRemainingMeters = null;
    _closeToLimitNotified = false;
    _aboveLimitSince = null;
    _aboveLimitAlerted = false;
    _wasOverLimit = false;
    _approachAnnounced = false;
    await _tts.stop();
  }

  Future<void> dispose() async {
    await reset();
    await _tonePlayer.dispose();
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

    await _playChime(times: 2);

    final String limitText =
        (limitKph != null && limitKph.isFinite)
            ? 'Limit ${limitKph.toStringAsFixed(0)}.'
            : 'Limit unknown.';
    await _speak('Zone started. $limitText Tracking average speed.');
  }

  Future<bool> _checkCloseToLimit({
    required double averageKph,
  }) async {
    final double limit = _currentLimitKph!;
    final double threshold = limit * 0.95;
    if (!_closeToLimitNotified && averageKph >= threshold && averageKph < limit) {
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
  }) async {
    final double limit = _currentLimitKph!;
    final double margin = 1.0;

    if (averageKph > limit + margin) {
      _wasOverLimit = true;
      _aboveLimitSince ??= now;
      if (!_aboveLimitAlerted &&
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
  }) async {
    if (_approachAnnounced) {
      return false;
    }
    if (remainingMeters == null) {
      return false;
    }
    if (remainingMeters > 800 || remainingMeters <= 0) {
      return false;
    }

    _approachAnnounced = true;

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
      await _speak('$distanceText to end. Avg $avgText, target ≤$limitText.');
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
    final String limitText =
        (limitKph != null && limitKph.isFinite) ? limitKph.toStringAsFixed(0) : '--';
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
    if (remainingMeters == null || !remainingMeters.isFinite || remainingMeters <= 0) {
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

    final double distanceSoFar = averageKph * elapsedHours;
    final double denominator = (averageKph - limitKph) * elapsedHours + remainingKm;
    if (denominator <= 0) {
      return limitKph;
    }
    final double required = (limitKph * remainingKm) / denominator;
    if (!required.isFinite) {
      return limitKph;
    }
    final double clamped = math.max(0, math.min(limitKph, required));
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

  Future<void> _playChime({
    int times = 1,
    Duration spacing = const Duration(milliseconds: 250),
  }) async {
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
    await _tts.speak(message);
  }
}
