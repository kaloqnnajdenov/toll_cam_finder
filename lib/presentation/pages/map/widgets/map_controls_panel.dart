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
    final double screenHeight = mediaQuery.size.height;
    final double heightFactor = _panelHeightFactor(screenHeight);
    final double panelHeight = screenHeight.isFinite && screenHeight > 0
        ? screenHeight * heightFactor
        : 0;

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double fallbackHeight = constraints.maxHeight.isFinite &&
                        constraints.maxHeight > 0
                    ? constraints.maxHeight * heightFactor
                    : 0;
                final double effectiveHeight =
                    panelHeight > 0 ? panelHeight : fallbackHeight;

                return SizedBox(
                  width: double.infinity,
                  height: effectiveHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: _SegmentMetricsCard(
                      currentSpeedKmh: speedKmh,
                      avgController: avgController,
                      hasActiveSegment: hasActiveSegment,
                      speedLimitKph: segmentSpeedLimitKph,
                      distanceToSegmentStartMeters:
                          distanceToSegmentStartMeters,
                      distanceToSegmentEndMeters:
                          segmentDebugPath?.remainingDistanceMeters,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

double _panelHeightFactor(double screenHeight) {
  if (!screenHeight.isFinite || screenHeight <= 0) {
    return 0.25;
  }
  if (screenHeight >= 900) {
    return 0.22;
  }
  if (screenHeight >= 720) {
    return 0.25;
  }
  if (screenHeight >= 600) {
    return 0.3;
  }
  return 0.36;
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
        final bool showSafeSpeed = averagingActive && safeSpeedFormatted.hasValue;

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

        final metrics = <_MetricData>[
          _MetricData(
            icon: hasActiveSegment
                ? Icons.flag_circle_outlined
                : Icons.my_location_outlined,
            label: localizations.translate(distanceLabelKey),
            value: distanceValue,
          ),
          _MetricData(
            icon: Icons.speed_outlined,
            label: localizations.translate('segmentMetricsAverageSpeed'),
            value: averageSpeed.label,
          ),
          if (showLimit)
            _MetricData(
              icon: Icons.shield_outlined,
              label: localizations.translate('segmentMetricsSpeedLimit'),
              value: limitSpeed.label,
            ),
          if (showSafeSpeed)
            _MetricData(
              icon: Icons.flag_outlined,
              label: localizations.translate('segmentMetricsSafeSpeed'),
              value: safeSpeedFormatted.label,
            ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 640;
            final bool isCompactHeight = constraints.maxHeight <= 260;
            final bool isUltraCompact = constraints.maxHeight <= 210;
            final double headerSpacing = isUltraCompact
                ? 8
                : isCompactHeight
                    ? 12
                    : 16;
            final double bodySpacing = isUltraCompact
                ? 8
                : isCompactHeight
                    ? 12
                    : 16;

            final header = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isUltraCompact ? 4 : 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    size: isUltraCompact ? 16 : 18,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(width: isUltraCompact ? 6 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.translate('segmentMetricsHeading'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: isUltraCompact ? 2 : 4),
                      Text(
                        statusText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final highlight = _SpeedHighlight(
              label: localizations.translate('segmentMetricsCurrentSpeed'),
              speed: currentSpeed,
              subtitle: statusText,
              compact: isCompactHeight,
              ultraCompact: isUltraCompact,
            );

            final metricsWrap = _MetricsWrap(
              metrics: metrics,
              compact: isCompactHeight,
            );

            final metricsSection = Align(
              alignment: Alignment.topLeft,
              child: metricsWrap,
            );

            final Widget body = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: highlight),
                      SizedBox(width: bodySpacing),
                      Expanded(child: metricsSection),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(child: highlight),
                      SizedBox(height: bodySpacing),
                      Expanded(child: metricsSection),
                    ],
                  );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                SizedBox(height: headerSpacing),
                Expanded(child: body),
              ],
            );
          },
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

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _SpeedHighlight extends StatelessWidget {
  const _SpeedHighlight({
    required this.label,
    required this.speed,
    required this.subtitle,
    required this.compact,
    required this.ultraCompact,
  });

  final String label;
  final _FormattedSpeed speed;
  final String subtitle;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final double paddingValue = ultraCompact
        ? 12
        : compact
            ? 14
            : 16;
    final double labelSpacing = ultraCompact
        ? 8
        : compact
            ? 10
            : 12;
    final double subtitleSpacing = ultraCompact
        ? 6
        : compact
            ? 8
            : 10;
    final double borderRadius = ultraCompact ? 16 : 20;
    final double blurRadius = ultraCompact ? 10 : 14;
    final double shadowOffsetY = ultraCompact ? 6 : 8;

    final Color startColor = colorScheme.primary;
    final Color endColor = colorScheme.secondary;

    TextStyle _scaleStyle(TextStyle? base, double scale, Color color,
        {FontWeight fontWeight = FontWeight.w700, double? height}) {
      final double fontSize = (base?.fontSize ?? 40) * scale;
      return (base ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: height,
      );
    }

    final TextStyle baseValueStyle = theme.textTheme.displaySmall ??
        theme.textTheme.headlineLarge ??
        const TextStyle(fontSize: 40);
    final double valueScale = ultraCompact
        ? 0.68
        : compact
            ? 0.82
            : 1.0;
    final TextStyle valueStyle = _scaleStyle(
      baseValueStyle,
      valueScale,
      Colors.white,
      height: 0.9,
    );

    final TextStyle unitBaseStyle = theme.textTheme.titleLarge ??
        theme.textTheme.titleMedium ??
        const TextStyle(fontSize: 22);
    final double unitScale = ultraCompact
        ? 0.78
        : compact
            ? 0.88
            : 1.0;
    final TextStyle unitStyle = _scaleStyle(
      unitBaseStyle,
      unitScale,
      Colors.white.withOpacity(0.85),
      fontWeight: FontWeight.w500,
    );

    final TextStyle labelStyle = (theme.textTheme.labelLarge ??
            theme.textTheme.labelMedium ??
            const TextStyle(fontSize: 14))
        .copyWith(
      color: Colors.white.withOpacity(0.75),
      letterSpacing: 1.05,
      fontWeight: FontWeight.w600,
    );

    final TextStyle subtitleStyle = (theme.textTheme.bodyMedium ??
            theme.textTheme.bodySmall ??
            const TextStyle(fontSize: 14))
        .copyWith(
      color: Colors.white.withOpacity(0.85),
      letterSpacing: 0.2,
    );

    return Container(
      padding: EdgeInsets.all(paddingValue),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            startColor.withOpacity(0.95),
            endColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: startColor.withOpacity(0.2),
            blurRadius: blurRadius,
            offset: Offset(0, shadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: labelStyle,
          ),
          SizedBox(height: labelSpacing),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 360),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: speed.unit != null
                ? RichText(
                    key: ValueKey('${speed.value}${speed.unit}'),
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: speed.value,
                          style: valueStyle,
                        ),
                        TextSpan(
                          text: ' ${speed.unit}',
                          style: unitStyle,
                        ),
                      ],
                    ),
                  )
                : Text(
                    speed.value,
                    key: ValueKey(speed.value),
                    style: valueStyle.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          SizedBox(height: subtitleSpacing),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: subtitleStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsWrap extends StatelessWidget {
  const _MetricsWrap({
    required this.metrics,
    required this.compact,
  });

  final List<_MetricData> metrics;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (metrics.isEmpty) {
          return const SizedBox.shrink();
        }

        final double maxWidth = constraints.maxWidth;
        final double spacing = compact ? 10 : 12;
        final bool useTwoColumns =
            maxWidth >= (compact ? 340 : 380) && metrics.length > 1;
        final double tileWidth = useTwoColumns
            ? (maxWidth - spacing) / 2
            : maxWidth;

        double computeWidth(double value) {
          if (value <= 0) {
            return 0;
          }
          if (value >= maxWidth) {
            return maxWidth;
          }
          return value;
        }

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: computeWidth(tileWidth),
                  child: _MetricTile(
                    data: metric,
                    compact: compact,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.data,
    required this.compact,
  });

  final _MetricData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isPlaceholder = data.value.trim() == '-';

    final double horizontalPadding = compact ? 12 : 14;
    final double verticalPadding = compact ? 10 : 12;
    final double radius = compact ? 16 : 18;
    final double iconPadding = compact ? 4.5 : 5;
    final double iconSize = compact ? 15 : 16;
    final double labelSpacing = compact ? 6 : 8;
    final double valueSpacing = compact ? 8 : 10;

    final TextStyle labelStyle = (theme.textTheme.labelLarge ??
            theme.textTheme.labelMedium ??
            const TextStyle(fontSize: 14))
        .copyWith(
      color: colorScheme.onSurface.withOpacity(0.7),
      letterSpacing: 0.1,
    );

    final TextStyle valueStyle = (theme.textTheme.titleLarge ??
            theme.textTheme.titleMedium ??
            const TextStyle(fontSize: 20))
        .copyWith(
      fontWeight: FontWeight.w600,
      color: isPlaceholder
          ? colorScheme.onSurface.withOpacity(0.45)
          : colorScheme.onSurface,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.24 : 0.36,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data.icon,
                  size: iconSize,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: labelSpacing),
              Expanded(
                child: Text(
                  data.label,
                  style: labelStyle,
                ),
              ),
            ],
          ),
          SizedBox(height: valueSpacing),
          Text(
            data.value,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}
