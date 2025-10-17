import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

enum MapControlsPlacement {
  bottom,
  left,
}

class MapControlsPanel extends StatelessWidget {
  const MapControlsPanel({
    super.key,
    required this.speedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    this.segmentSpeedLimitKph,
    this.segmentDebugPath,
    this.distanceToSegmentStartMeters,
    this.placement = MapControlsPlacement.bottom,
  });

  final double? speedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? segmentSpeedLimitKph;
  final SegmentDebugPath? segmentDebugPath;
  final double? distanceToSegmentStartMeters;
  final MapControlsPlacement placement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);

    final bool placeLeft = placement == MapControlsPlacement.left;
    final double panelMaxWidth = placeLeft
        ? math.min(mediaQuery.size.width / 3, 520)
        : 520;
    final Widget panelCard = _buildPanelCard(
      colorScheme: colorScheme,
      maxWidth: panelMaxWidth,
    );

    if (placeLeft) {
      return Material(
        color: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mediaQuery.padding.left + 16,
            mediaQuery.padding.top + 16,
            16,
            mediaQuery.padding.bottom + 16,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: panelCard,
          ),
        ),
      );
    }

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
            child: panelCard,
          ),
        ),
      ),
    );
  }

  Widget _buildPanelCard({
    required ColorScheme colorScheme,
    required double maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
          child: Container(
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

        final String distanceLabel =
            localizations.translate(distanceLabelKey);
        final String distanceDisplay = distanceValue;

        final _MetricAccessory? primaryAccessory = showSafeSpeed
            ? _MetricAccessory(
                label: localizations.translate('segmentMetricsSafeSpeed'),
                labelAbove: true,
                child:
                    _MetricSpeedValue(speed: safeSpeedFormatted, alignRight: true),
              )
            : showLimit
                ? _MetricAccessory(
                    label: localizations
                        .translate('segmentMetricsSpeedLimit'),
                    child: _MetricSpeedValue(
                      speed: limitSpeed,
                      alignRight: true,
                    ),
                  )
                : null;

        final _MetricAccessory distanceAccessory = _MetricAccessory(
          label: distanceLabel,
          child: _DistanceValue(distanceText: distanceDisplay),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MetricLabel(
              text:
                  localizations.translate('segmentMetricsCurrentSpeed'),
            ),
            const SizedBox(height: 6),
            _MetricValueRow(
              value: _MetricSpeedValue(speed: currentSpeed),
              accessory: primaryAccessory,
            ),
            const _MetricDivider(),
            if (averagingActive) ...[
              _MetricLabel(
                text:
                    localizations.translate('segmentMetricsAverageSpeed'),
              ),
              const SizedBox(height: 6),
              _MetricValueRow(
                value: _MetricSpeedValue(speed: averageSpeed),
                accessory: distanceAccessory,
              ),
              const _MetricDivider(),
            ] else if (showLimit && primaryAccessory == null) ...[
              _MetricLabel(
                text:
                    localizations.translate('segmentMetricsSpeedLimit'),
              ),
              const SizedBox(height: 6),
              _MetricSpeedValue(speed: limitSpeed),
              const _MetricDivider(),
            ],
            if (!averagingActive) ...[
              _MetricLabel(text: distanceLabel),
              const SizedBox(height: 6),
              _DistanceValue(distanceText: distanceDisplay),
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

class _MetricValueRow extends StatelessWidget {
  const _MetricValueRow({required this.value, this.accessory});

  final Widget value;
  final _MetricAccessory? accessory;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: value),
        if (accessory != null) ...[
          const SizedBox(width: 16),
          accessory!,
        ],
      ],
    );
  }
}

class _MetricAccessory extends StatelessWidget {
  const _MetricAccessory({
    required this.label,
    required this.child,
    this.labelAbove = false,
  });

  final String label;
  final Widget child;
  final bool labelAbove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelWidget = Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 0.8,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: labelAbove
          ? [
              labelWidget,
              const SizedBox(height: 6),
              child,
            ]
          : [
              child,
              const SizedBox(height: 6),
              labelWidget,
            ],
    );
  }
}

class _DistanceValue extends StatelessWidget {
  const _DistanceValue({required this.distanceText});

  final String distanceText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final iconColor = theme.colorScheme.onSurface;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chevron_right, size: 20, color: iconColor),
        const SizedBox(width: 6),
        Text(distanceText, style: textStyle),
      ],
    );
  }
}
