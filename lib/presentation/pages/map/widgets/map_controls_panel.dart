import 'dart:math' as math;

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
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentMetricsCard(
          currentSpeedKmh: speedKmh,
          avgController: avgController,
          hasActiveSegment: hasActiveSegment,
          speedLimitKph: segmentSpeedLimitKph,
          distanceToSegmentStartMeters: distanceToSegmentStartMeters,
          distanceToSegmentEndMeters:
              segmentDebugPath?.remainingDistanceMeters,
        ),
      ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: avgController,
      builder: (context, _) {
        final localizations = AppLocalizations.of(context);
        final String speedUnit = localizations.speedDialUnitKmh;
        final DateTime now = DateTime.now();
        final bool averagingActive =
            hasActiveSegment && avgController.isRunning;

        final double? sanitizedStart =
            _sanitizeDistance(distanceToSegmentStartMeters);
        final double? sanitizedEnd =
            _sanitizeDistance(distanceToSegmentEndMeters);

        final double? safeSpeed = averagingActive
            ? _estimateSafeSpeed(
                averageKph: avgController.average,
                limitKph: speedLimitKph,
                remainingMeters: sanitizedEnd,
                startedAt: avgController.startedAt,
                now: now,
              )
            : null;

        final _MetricData currentSpeedMetric = _MetricData(
          label: localizations.translate('segmentMetricsCurrentSpeed'),
          value: _formatSpeed(currentSpeedKmh, speedUnit),
        );

        final bool onSegment = hasActiveSegment;
        final String distanceLabelKey = onSegment
            ? 'segmentMetricsDistanceToEnd'
            : 'segmentMetricsDistanceToStart';
        final double? distanceMeters = onSegment
            ? sanitizedEnd ?? sanitizedStart
            : sanitizedStart;

        final _MetricData distanceMetric = _MetricData(
          label: localizations.translate(distanceLabelKey),
          value: _formatDistance(localizations, distanceMeters),
        );

        final _MetricData safeSpeedMetric = _MetricData(
          label: localizations.translate('segmentMetricsSafeSpeed'),
          value: averagingActive && safeSpeed != null
              ? _formatSpeed(safeSpeed, speedUnit)
              : '-',
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localizations.translate('segmentMetricsHeading'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.8),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 16),
              _MetricRow(
                leading: currentSpeedMetric,
                trailing: distanceMetric,
              ),
              const SizedBox(height: 12),
              _MetricRow(
                leading: _MetricData(
                  label: currentSpeedMetric.label,
                  value: currentSpeedMetric.value,
                ),
                trailing: safeSpeedMetric,
              ),
            ],
          ),
        );
      },
    );
  }

  double? _sanitizeDistance(double? meters) {
    if (meters == null || !meters.isFinite) {
      return null;
    }
    final double value = meters < 0 ? 0 : meters;
    return value;
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

  String _formatSpeed(double? speedKph, String unit) {
    if (speedKph == null || !speedKph.isFinite) {
      return '-';
    }
    final double clamped =
        speedKph.clamp(0, double.infinity).toDouble();
    return '${clamped.toStringAsFixed(0)} $unit';
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

class _MetricData {
  const _MetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.leading, required this.trailing});

  final _MetricData leading;
  final _MetricData trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricTile(data: leading)),
        const SizedBox(width: 18),
        Expanded(child: _MetricTile(data: trailing)),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
