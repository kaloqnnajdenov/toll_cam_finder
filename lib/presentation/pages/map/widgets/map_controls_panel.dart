import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
    this.lastSegmentAvgKmh,
    this.segmentSpeedLimitKph,
    this.segmentProgressLabel,
    this.segmentDebugPath,
    this.distanceToSegmentStartMeters,
    required this.showDebugBadge,
    required this.segmentCount,
    required this.segmentRadiusMeters,
  });

  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? lastSegmentAvgKmh;
  final double? segmentSpeedLimitKph;
  final String? segmentProgressLabel;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final bool showDebugBadge;
  final int segmentCount;
  final double segmentRadiusMeters;

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
        if (segmentProgressLabel != null) ...[
          const SizedBox(height: 12),
          _InfoChip(
            text: segmentProgressLabel!,
            icon: Icons.near_me,
          ),
        ],
        if (lastSegmentAvgKmh != null) ...[
          const SizedBox(height: 12),
          _InfoChip(
            text: localizations.translate(
              'speedDialLastSegmentAverage',
              {
                'value': lastSegmentAvgKmh!.toStringAsFixed(1),
                'unit': localizations.speedDialUnitKmh,
              },
            ),
            icon: Icons.history,
          ),
        ],
        if (showDebugBadge && kDebugMode) ...[
          const SizedBox(height: 12),
          _InfoChip(
            text: localizations.translate(
              'speedDialDebugSummary',
              {
                'count': '$segmentCount',
                'radius': '${segmentRadiusMeters.toInt()}',
                'unit': localizations.translate('unitMetersShort'),
              },
            ),
            icon: Icons.bug_report_outlined,
          ),
        ],
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
        final double? activeAverage = averagingActive
            ? avgController.average
            : null;

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

        final List<_MetricData> metrics = [
          _MetricData(
            label: localizations.translate('segmentMetricsCurrentSpeed'),
            value: _formatSpeed(currentSpeedKmh, speedUnit),
          ),
          _MetricData(
            label: localizations.translate('segmentMetricsAverageSpeed'),
            value: averagingActive
                ? _formatSpeed(activeAverage, speedUnit)
                : '-',
          ),
          _MetricData(
            label: localizations.translate('segmentMetricsDistanceToStart'),
            value: _formatDistance(localizations, sanitizedStart),
          ),
          _MetricData(
            label: localizations.translate('segmentMetricsDistanceToEnd'),
            value: averagingActive
                ? _formatDistance(localizations, sanitizedEnd)
                : '-',
          ),
          _MetricData(
            label: localizations.translate('segmentMetricsSafeSpeed'),
            value: averagingActive && safeSpeed != null
                ? _formatSpeed(safeSpeed, speedUnit)
                : '-',
          ),
        ];

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.translate('segmentMetricsHeading'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.8),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 12,
                children: metrics
                    .map((metric) => _MetricTile(data: metric))
                    .toList(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
