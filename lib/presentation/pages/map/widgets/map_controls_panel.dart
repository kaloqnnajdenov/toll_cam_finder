import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

enum MapControlsPlacement { bottom, left }

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
    final double horizontalPadding = placeLeft
        ? mediaQuery.padding.left + mediaQuery.padding.right + 32
        : 32;
    final double availableWidth =
        math.max(0, mediaQuery.size.width - horizontalPadding);
    final double panelMaxWidth = placeLeft
        ? math.min(availableWidth, mediaQuery.size.width * 0.25)
        : availableWidth;
    double? panelMaxHeight;
    if (placeLeft) {
      final double availableHeight = mediaQuery.size.height -
          (mediaQuery.padding.top + mediaQuery.padding.bottom + 32);
      if (availableHeight.isFinite && availableHeight > 0) {
        panelMaxHeight = availableHeight;
      }
    }
    final Widget panelCard = _buildPanelCard(
      colorScheme: colorScheme,
      maxWidth: panelMaxWidth,
      maxHeight: panelMaxHeight,
      stackMetricsVertically: !placeLeft,
      forceSingleRow: placeLeft,
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
    required double? maxHeight,
    required bool stackMetricsVertically,
    required bool forceSingleRow,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: _SegmentMetricsCard(
              currentSpeedKmh: speedKmh,
              avgController: avgController,
              hasActiveSegment: hasActiveSegment,
              speedLimitKph: segmentSpeedLimitKph,
              distanceToSegmentStartMeters: distanceToSegmentStartMeters,
              distanceToSegmentEndMeters:
                  segmentDebugPath?.remainingDistanceMeters,
              stackMetricsVertically: stackMetricsVertically,
              forceSingleRow: forceSingleRow,
              maxAvailableHeight: maxHeight,
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
    required this.stackMetricsVertically,
    required this.forceSingleRow,
    required this.maxAvailableHeight,
  });

  final double? currentSpeedKmh;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? speedLimitKph;
  final double? distanceToSegmentStartMeters;
  final double? distanceToSegmentEndMeters;
  final bool stackMetricsVertically;
  final bool forceSingleRow;
  final double? maxAvailableHeight;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: avgController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final localizations = AppLocalizations.of(context);
        final String speedUnit = localizations.speedDialUnitKmh;
        final DateTime now = DateTime.now();
        final bool averagingActive =
            hasActiveSegment && avgController.isRunning;

        final double? sanitizedStart = _sanitizeDistance(
          distanceToSegmentStartMeters,
        );
        final double? sanitizedEnd = _sanitizeDistance(
          distanceToSegmentEndMeters,
        );

        final double? safeSpeed = averagingActive
            ? _estimateSafeSpeed(
                averageKph: avgController.average,
                limitKph: speedLimitKph,
                remainingMeters: sanitizedEnd,
                startedAt: avgController.startedAt,
                now: now,
              )
            : null;

        final _MetricValue currentSpeed = _formatSpeed(
          currentSpeedKmh,
          speedUnit,
        );
        final _MetricValue averageSpeed = averagingActive
            ? _formatSpeed(avgController.average, speedUnit)
            : const _MetricValue(value: '-', unit: null);
        final _MetricValue limitSpeed = _formatSpeed(
          speedLimitKph,
          speedUnit,
        );
        final _MetricValue safeSpeedFormatted = safeSpeed != null
            ? _formatSpeed(safeSpeed, speedUnit)
            : const _MetricValue(value: '-', unit: null);

        final bool showSafeSpeed =
            averagingActive && safeSpeedFormatted.hasValue;

        final String distanceLabelKey = hasActiveSegment
            ? 'segmentMetricsDistanceToEnd'
            : 'segmentMetricsDistanceToStart';
        final double? distanceMeters = hasActiveSegment
            ? sanitizedEnd ?? sanitizedStart
            : sanitizedStart;
        final _MetricValue distanceValue = _formatDistance(
          localizations,
          distanceMeters,
        );

        final String distanceLabel = localizations.translate(distanceLabelKey);
        final List<_MetricTileData> metrics = [
          _MetricTileData(
            label: localizations.translate('segmentMetricsCurrentSpeed'),
            value: currentSpeed,
          ),
          _MetricTileData(
            label: localizations.translate('segmentMetricsAverageSpeed'),
            value: averageSpeed,
          ),
          _MetricTileData(
            label: showSafeSpeed
                ? localizations.translate('segmentMetricsSafeSpeed')
                : localizations.translate('segmentMetricsSpeedLimit'),
            value: showSafeSpeed ? safeSpeedFormatted : limitSpeed,
          ),
          _MetricTileData(
            label: distanceLabel,
            value: distanceValue,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            const double spacing = 12;

            if (stackMetricsVertically) {
              final List<_MetricTileData> orderedMetrics = [
                metrics[0],
                metrics[2],
                metrics[1],
                metrics[3],
              ];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int row = 0; row < orderedMetrics.length; row += 2) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            data: orderedMetrics[row],
                            visualScale: 1.0,
                          ),
                        ),
                        const SizedBox(width: spacing),
                        Expanded(
                          child: _MetricTile(
                            data: orderedMetrics[row + 1],
                            visualScale: 1.0,
                          ),
                        ),
                      ],
                    ),
                    if (row + 2 < orderedMetrics.length)
                      const SizedBox(height: spacing),
                  ],
                ],
              );
            }

            if (forceSingleRow) {
              final mediaQuery = MediaQuery.of(context);
              final double screenWidth = mediaQuery.size.width;
              final double maxTileWidth = math.min(width, screenWidth * 0.25);
              final double minTileWidth = math.min(maxTileWidth, 160);

              const double panelVerticalPadding = 14 + 12;
              final double? boundedHeight = maxAvailableHeight;
              const double baseTileHeight = 128;
              const double comfortableMinScale = 0.55;
              const double absoluteMinScale = 0.35;
              double visualScale = 1.0;
              if (boundedHeight != null && boundedHeight.isFinite) {
                final double availableForTiles = math.max(
                  0,
                  boundedHeight - panelVerticalPadding - spacing * (metrics.length - 1),
                );
                if (metrics.isNotEmpty && availableForTiles > 0) {
                  final double rawScale =
                      availableForTiles / (baseTileHeight * metrics.length);
                  if (rawScale >= comfortableMinScale) {
                    visualScale = rawScale.clamp(comfortableMinScale, 1.0);
                  } else if (rawScale >= absoluteMinScale) {
                    visualScale = rawScale;
                  } else if (rawScale > 0) {
                    visualScale = rawScale;
                  } else {
                    visualScale = absoluteMinScale;
                  }
                } else {
                  visualScale = comfortableMinScale;
                }
              }
              visualScale = (visualScale.clamp(0.0, 1.0) as double);
              if (visualScale == 0) {
                visualScale = absoluteMinScale;
              }
              final double resolvedTileHeight = baseTileHeight * visualScale;
              final bool enforceFixedHeight =
                  boundedHeight != null && boundedHeight.isFinite;

              return IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < metrics.length; i++) ...[
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: minTileWidth,
                          maxWidth: maxTileWidth,
                          minHeight: resolvedTileHeight,
                          maxHeight: enforceFixedHeight
                              ? resolvedTileHeight
                              : double.infinity,
                        ),
                        child: _MetricTile(
                          data: metrics[i],
                          visualScale: visualScale,
                        ),
                      ),
                      if (i + 1 < metrics.length)
                        const SizedBox(height: spacing),
                    ],
                  ],
                ),
              );
            }

            final bool useTwoColumns = width >= 360;
            final double tileWidth =
                useTwoColumns ? math.max((width - spacing) / 2, 0) : width;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: metrics
                  .map(
                    (metric) => SizedBox(
                      width: tileWidth,
                      child: _MetricTile(
                        data: metric,
                        visualScale: 1.0,
                      ),
                    ),
                  )
                  .toList(),
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

  _MetricValue _formatSpeed(double? speedKph, String unit) {
    if (speedKph == null || !speedKph.isFinite) {
      return const _MetricValue(value: '-', unit: null);
    }
    final double clamped = speedKph.clamp(0, double.infinity).toDouble();
    final bool useDecimals = clamped < 10;
    final String formatted = clamped.toStringAsFixed(useDecimals ? 1 : 0);
    return _MetricValue(value: formatted, unit: unit);
  }

  _MetricValue _formatDistance(
    AppLocalizations localizations,
    double? meters,
  ) {
    if (meters == null || !meters.isFinite) {
      return const _MetricValue(value: '-', unit: null);
    }
    if (meters >= 1000) {
      final double km = meters / 1000.0;
      final String unit = localizations.translate('unitKilometersShort');
      final String formatted = km >= 10
          ? km.toStringAsFixed(0)
          : km.toStringAsFixed(1);
      return _MetricValue(value: formatted, unit: unit);
    }
    final String unit = localizations.translate('unitMetersShort');
    return _MetricValue(
      value: meters.toStringAsFixed(0),
      unit: unit,
    );
  }
}

class _MetricValue {
  const _MetricValue({required this.value, this.unit});

  final String value;
  final String? unit;

  bool get hasValue => unit != null && value != '-';

  String get label => hasValue ? '$value $unit' : value;
}

class _MetricTileData {
  const _MetricTileData({required this.label, required this.value});

  final String label;
  final _MetricValue value;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.data,
    required this.visualScale,
  });

  final _MetricTileData data;
  final double visualScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TextStyle valueBaseStyle = theme.textTheme.displaySmall ??
        theme.textTheme.headlineMedium ??
        const TextStyle(fontSize: 36, fontWeight: FontWeight.w700);
    final double scale = visualScale.clamp(0.2, 1.0);
    final double? baseValueSize = valueBaseStyle.fontSize;
    final TextStyle valueStyle = valueBaseStyle.copyWith(
      height: 1.0,
      fontWeight: FontWeight.w800,
      color: colorScheme.onSurface,
      fontSize: baseValueSize != null ? baseValueSize * scale : null,
    );
    final TextStyle unitBaseStyle = (theme.textTheme.titleMedium ??
            theme.textTheme.titleSmall ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
        .copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface);
    final double? unitBaseSize = unitBaseStyle.fontSize;
    final TextStyle unitStyle = unitBaseStyle.copyWith(
      fontSize: unitBaseSize != null ? unitBaseSize * scale : null,
    );
    final TextStyle labelBaseStyle = (theme.textTheme.labelMedium ??
            theme.textTheme.labelSmall ??
            const TextStyle(fontSize: 12))
        .copyWith(
      color: colorScheme.onSurfaceVariant,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
    );
    final double? labelBaseSize = labelBaseStyle.fontSize;
    final TextStyle labelStyle = labelBaseStyle.copyWith(
      fontSize: labelBaseSize != null ? labelBaseSize * scale : null,
    );

    final double verticalPadding = lerpDouble(6, 12, scale)!;
    final double horizontalPadding = lerpDouble(10, 16, scale)!;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.label.toUpperCase(), style: labelStyle),
          SizedBox(height: lerpDouble(4, 10, scale)!),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(data.value.value, style: valueStyle),
              if (data.value.unit != null) ...[
                const SizedBox(width: 6),
                Text(data.value.unit!, style: unitStyle),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
