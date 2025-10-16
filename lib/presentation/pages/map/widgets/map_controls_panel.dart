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
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.25),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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

        final entries = <_SummaryEntryData>[
          _SummaryEntryData(
            label: localizations.translate('segmentMetricsCurrentSpeed'),
            value: currentSpeed.value,
            unit: currentSpeed.unit,
          ),
          _SummaryEntryData(
            label: localizations.translate(distanceLabelKey),
            value: distanceValue,
          ),
        ];

        if (averagingActive) {
          entries.add(
            _SummaryEntryData(
              label: localizations.translate('segmentMetricsAverageSpeed'),
              value: averageSpeed.value,
              unit: averageSpeed.unit,
              helper: showSafeSpeed
                  ? '${localizations.translate('segmentMetricsSafeSpeed')}: ${safeSpeedFormatted.label}'
                  : null,
            ),
          );
        } else if (showLimit) {
          entries.add(
            _SummaryEntryData(
              label: localizations.translate('segmentMetricsSpeedLimit'),
              value: limitSpeed.value,
              unit: limitSpeed.unit,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.translate('segmentMetricsHeading'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            _SummaryEntriesRow(entries: entries),
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

class _SummaryEntryData {
  const _SummaryEntryData({
    required this.label,
    required this.value,
    this.unit,
    this.helper,
  });

  final String label;
  final String value;
  final String? unit;
  final String? helper;
}

class _SummaryEntriesRow extends StatelessWidget {
  const _SummaryEntriesRow({
    required this.entries,
  });

  final List<_SummaryEntryData> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool shouldWrap = constraints.maxWidth < 360 && entries.length > 2;
        if (!shouldWrap) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildRowChildren(entries, theme),
            ),
          );
        }

        final firstRow = entries.take(2).toList();
        final secondRow = entries.skip(2).toList();

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRowChildren(firstRow, theme),
              ),
            ),
            if (secondRow.isNotEmpty) ...[
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _buildRowChildren(secondRow, theme),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildRowChildren(
    List<_SummaryEntryData> data,
    ThemeData theme,
  ) {
    final children = <Widget>[];
    for (var i = 0; i < data.length; i++) {
      children.add(
        Expanded(
          child: _SummaryEntry(data: data[i]),
        ),
      );
      if (i != data.length - 1) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 60,
              child: VerticalDivider(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                thickness: 1,
                width: 1,
              ),
            ),
          ),
        );
      }
    }
    return children;
  }
}

class _SummaryEntry extends StatelessWidget {
  const _SummaryEntry({
    required this.data,
  });

  final _SummaryEntryData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final TextStyle valueStyle = (theme.textTheme.displaySmall ??
            theme.textTheme.headlineLarge ??
            const TextStyle(fontSize: 36))
        .copyWith(
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      letterSpacing: -0.4,
      height: 0.95,
    );

    final TextStyle unitStyle = (theme.textTheme.titleMedium ??
            theme.textTheme.titleSmall ??
            const TextStyle(fontSize: 18))
        .copyWith(
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.3,
    );

    final TextStyle labelStyle = (theme.textTheme.labelLarge ??
            theme.textTheme.bodyMedium ??
            const TextStyle(fontSize: 14))
        .copyWith(
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.4,
    );

    final TextStyle helperStyle = (theme.textTheme.bodySmall ??
            const TextStyle(fontSize: 12))
        .copyWith(
      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
      letterSpacing: 0.2,
    );

    final spans = <InlineSpan>[
      TextSpan(
        text: data.value,
        style: valueStyle,
      ),
    ];
    if (data.unit != null) {
      spans.add(
        TextSpan(
          text: ' ${data.unit}',
          style: unitStyle,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(children: spans),
        ),
        const SizedBox(height: 6),
        Text(
          data.label.toUpperCase(),
          style: labelStyle,
        ),
        if (data.helper != null) ...[
          const SizedBox(height: 4),
          Text(
            data.helper!,
            style: helperStyle,
          ),
        ],
      ],
    );
  }
}
