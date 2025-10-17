import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

class MapControlsPanel extends StatelessWidget {
  const MapControlsPanel({
    super.key,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    this.segmentSpeedLimitKph,
    this.segmentDebugPath,
    this.distanceToSegmentStartMeters,
  });

  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return SafeArea(
      top: false,
      bottom: false,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              mediaQuery.padding.bottom + 12,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: _SegmentMetricsCard(
                    currentSpeedKmh: speedKmh,
                    avgController: avgController,
                    hasActiveSegment: hasActiveSegment,
                    speedLimitKph: segmentSpeedLimitKph,
                    distanceToSegmentStartMeters: distanceToSegmentStartMeters,
                    distanceToSegmentEndMeters:
                        segmentDebugPath?.remainingDistanceMeters,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentMetricsCard extends StatelessWidget {
  const _SegmentMetricsCard({
    required this.currentSpeedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    required this.speedLimitKph,
    required this.distanceToSegmentStartMeters,
    required this.distanceToSegmentEndMeters,
  });

  final double? currentSpeedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? speedLimitKph;
  final double? distanceToSegmentStartMeters;
  final double? distanceToSegmentEndMeters;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: avgController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final localizations = AppLocalizations.of(context);
        final String speedUnit = localizations.speedDialUnitKmh;
        final DateTime now = DateTime.now();
        final bool averagingActive = hasActiveSegment && avgController.isRunning;

        final double? sanitizedStart =
            _sanitizeDistance(distanceToSegmentStartMeters);
        final double? sanitizedEnd = _sanitizeDistance(distanceToSegmentEndMeters);

        final double? safeSpeed = averagingActive
            ? _estimateSafeSpeed(
                averageKph: avgController.average,
                limitKph: speedLimitKph,
                remainingMeters: sanitizedEnd,
                startedAt: avgController.startedAt,
                now: now,
              )
            : null;

        final _FormattedSpeed currentSpeed =
            _formatSpeed(currentSpeedKmh, speedUnit);
        final _FormattedSpeed averageSpeed = averagingActive
            ? _formatSpeed(avgController.average, speedUnit)
            : const _FormattedSpeed(value: '-', unit: null);
        final _FormattedSpeed limitSpeed =
            _formatSpeed(speedLimitKph, speedUnit);
        final _FormattedSpeed safeSpeedFormatted = safeSpeed != null
            ? _formatSpeed(safeSpeed, speedUnit)
            : const _FormattedSpeed(value: '-', unit: null);

        final bool showLimit = limitSpeed.hasValue;
        final bool showSafeSpeed =
            averagingActive && safeSpeedFormatted.hasValue;

        final String distanceLabelKey = hasActiveSegment
            ? 'segmentMetricsDistanceToEnd'
            : 'segmentMetricsDistanceToStart';
        final double? distanceMeters = hasActiveSegment
            ? sanitizedEnd ?? sanitizedStart
            : sanitizedStart;
        final String distanceValue =
            _formatDistance(localizations, distanceMeters);

        final String statusText = hasActiveSegment
            ? localizations.translate('segmentMetricsStatusTracking')
            : localizations.speedDialNoActiveSegment;

        final String distanceLabel =
            localizations.translate(distanceLabelKey);
        final String distanceDisplay = distanceValue;

        final _MetricSpeedInfo trailingSpeed = averagingActive && showSafeSpeed
            ? _MetricSpeedInfo(
                label: localizations.translate('segmentMetricsSafeSpeed'),
                speed: safeSpeedFormatted,
              )
            : showLimit
                ? _MetricSpeedInfo(
                    label:
                        localizations.translate('segmentMetricsSpeedLimit'),
                    speed: limitSpeed,
                  )
                : const _MetricSpeedInfo.none();

        final TextStyle? statusStyle =
            theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          letterSpacing: 0.3,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MetricAccent(),
            _MetricLabel(
              text:
                  localizations.translate('segmentMetricsCurrentSpeed'),
            ),
            const SizedBox(height: 6),
            _MetricSpeedValue(speed: currentSpeed),
            const _MetricDivider(),
            if (averagingActive) ...[
              _MetricLabel(
                text:
                    localizations.translate('segmentMetricsAverageSpeed'),
              ),
              const SizedBox(height: 6),
              _MetricSpeedValue(speed: averageSpeed),
              if (showSafeSpeed) ...[
                const SizedBox(height: 6),
                Text(
                  '${localizations.translate('segmentMetricsSafeSpeed')}: ${safeSpeedFormatted.label}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.85),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
              const _MetricDivider(),
            ] else if (showLimit) ...[
              _MetricLabel(
                text:
                    localizations.translate('segmentMetricsSpeedLimit'),
              ),
              const SizedBox(height: 6),
              _MetricSpeedValue(speed: limitSpeed),
              const _MetricDivider(),
            ],
            _MetricLabel(text: distanceLabel),
            const SizedBox(height: 10),
            _DistanceAndTrailingSpeedRow(
              distanceText: distanceDisplay,
              trailing: trailingSpeed,
            ),
            if (statusText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(statusText, style: statusStyle),
            ],
          ],
        );
      },
    );
  }

  double? _sanitizeDistance(double? meters) {
    if (meters == null || !meters.isFinite) {
      return null;
    }
    return meters < 0 ? 0 : meters;
  }

  double? _estimateSafeSpeed({
    required double averageKph,
    required double? limitKph,
    required double? remainingMeters,
    required DateTime? startedAt,
    required DateTime now,
  }) {
    if (limitKph == null || !limitKph.isFinite) {
      return null;
    }
    if (!averageKph.isFinite) {
      return null;
    }
    if (remainingMeters == null || remainingMeters <= 0) {
      return null;
    }
    if (startedAt == null) {
      return null;
    }

    final double remainingKm = remainingMeters / 1000.0;
    final Duration elapsed = now.difference(startedAt);
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

    return math.max(0, math.min(limitKph, required));
  }

  _FormattedSpeed _formatSpeed(double? speedKph, String unit) {
    if (speedKph == null || !speedKph.isFinite) {
      return const _FormattedSpeed(value: '-', unit: null);
    }
    final double clamped =
        speedKph.clamp(0, double.infinity).toDouble();
    final bool useDecimals = clamped < 10;
    final String formatted =
        clamped.toStringAsFixed(useDecimals ? 1 : 0);
    return _FormattedSpeed(value: formatted, unit: unit);
  }

  String _formatDistance(AppLocalizations localizations, double? meters) {
    if (meters == null || !meters.isFinite) {
      return '-';
    }
    if (meters >= 1000) {
      final double km = meters / 1000.0;
      final String unit = localizations.translate('unitKilometersShort');
      final String formatted =
          km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
      return '$formatted $unit';
    }
    final String unit = localizations.translate('unitMetersShort');
    return '${meters.toStringAsFixed(0)} $unit';
  }
}

class _FormattedSpeed {
  const _FormattedSpeed({required this.value, this.unit});

  final String value;
  final String? unit;

  bool get hasValue => unit != null && value != '-';

  String get label => hasValue ? '$value $unit' : value;
}

class _MetricSpeedInfo {
  const _MetricSpeedInfo({required this.label, required this.speed})
      : hasValue = true;

  const _MetricSpeedInfo.none()
      : label = null,
        speed = const _FormattedSpeed(value: '-'),
        hasValue = false;

  final String? label;
  final _FormattedSpeed speed;
  final bool hasValue;
}

class _MetricAccent extends StatelessWidget {
  const _MetricAccent();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 6,
        height: 12,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD400),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context)
        .colorScheme
        .onSurface
        .withOpacity(0.08);
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 14),
      color: color,
    );
  }
}

class _MetricSpeedValue extends StatelessWidget {
  const _MetricSpeedValue({required this.speed, this.alignRight = false});

  final _FormattedSpeed speed;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = alignRight ? Alignment.centerRight : Alignment.centerLeft;
    final TextStyle baseValueStyle = (speed.unit != null
            ? theme.textTheme.displaySmall
            : theme.textTheme.headlineMedium) ??
        theme.textTheme.displaySmall ??
        const TextStyle(fontSize: 36, fontWeight: FontWeight.w700);
    final valueStyle = baseValueStyle.copyWith(
      height: 1.0,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
    );
    final TextStyle baseUnitStyle = theme.textTheme.titleMedium ??
        theme.textTheme.titleSmall ??
        const TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
    final unitStyle = baseUnitStyle.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );

    return Align(
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(speed.value, style: valueStyle),
          if (speed.unit != null) ...[
            const SizedBox(width: 6),
            Text(speed.unit!, style: unitStyle),
          ],
        ],
      ),
    );
  }
}

class _DistanceAndTrailingSpeedRow extends StatelessWidget {
  const _DistanceAndTrailingSpeedRow({
    required this.distanceText,
    required this.trailing,
  });

  final String distanceText;
  final _MetricSpeedInfo trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final iconColor = theme.colorScheme.onSurface;

    return Row(
      children: [
        Icon(Icons.chevron_right, size: 20, color: iconColor),
        const SizedBox(width: 6),
        Text(distanceText, style: textStyle),
        if (trailing.hasValue) ...[
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MetricSpeedValue(speed: trailing.speed, alignRight: true),
              const SizedBox(height: 6),
              Text(
                trailing.label!.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
