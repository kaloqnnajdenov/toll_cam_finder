import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class SegmentMetricsCard extends StatelessWidget {
  const SegmentMetricsCard({
    super.key,
    required this.currentSpeedKmh,
    required this.avgController,
    required this.hasActiveSegment,
    required this.speedLimitKph,
    required this.distanceToSegmentStartMeters,
    required this.distanceToSegmentEndMeters,
    required this.stackMetricsVertically,
    required this.forceSingleRow,
    required this.maxAvailableHeight,
    required this.isLandscape,
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
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: avgController,
      builder: (context, _) {
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

        final String distanceLabel =
            localizations.translate(distanceLabelKey);
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
                metrics[1],
                metrics[3],
                metrics[2],
              ];
              return _TwoByTwoMetricsGrid(
                tiles: orderedMetrics,
                isLandscape: isLandscape,
              );
            }

            if (forceSingleRow) {
              return _SingleColumnMetrics(
                metrics: metrics,
                spacing: spacing,
                width: width,
                maxAvailableHeight: maxAvailableHeight,
                isLandscape: isLandscape,
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
                        dense: false,
                        isLandscape: isLandscape,
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
}

class _SingleColumnMetrics extends StatelessWidget {
  const _SingleColumnMetrics({
    required this.metrics,
    required this.spacing,
    required this.width,
    required this.maxAvailableHeight,
    required this.isLandscape,
  });

  final List<_MetricTileData> metrics;
  final double spacing;
  final double width;
  final double? maxAvailableHeight;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final double screenWidth = mediaQuery.size.width;
    final double screenHeight = mediaQuery.size.height;
    final double maxTileWidth = math.min(width, screenWidth * 0.28);
    final double minTileWidth = math.min(maxTileWidth, screenWidth * 0.24);

    final double? boundedHeight = maxAvailableHeight;
    final double panelVerticalPadding =
        (mediaQuery.viewPadding.top + mediaQuery.viewPadding.bottom) * 0.15 +
            28;

    final double preferredTileHeight = () {
      final double widthDrivenHeight = maxTileWidth * 0.78;
      final double heightDriven = screenHeight * 0.22;
      final double fallbackHeight = 128;
      final double raw = math.max(widthDrivenHeight, heightDriven);
      return raw.isFinite && raw > 0 ? raw : fallbackHeight;
    }();

    double visualScale = 1.0;
    if (boundedHeight != null && boundedHeight.isFinite) {
      final double availableForTiles = math.max(
        0,
        boundedHeight - panelVerticalPadding - spacing * (metrics.length - 1),
      );
      if (metrics.isNotEmpty && availableForTiles > 0) {
        final double rawScale =
            availableForTiles / (preferredTileHeight * metrics.length);
        visualScale = rawScale.clamp(0.35, 1.0).toDouble();
      } else {
        visualScale = 0.45;
      }
    }

    final double widthScale = maxTileWidth > 0
        ? (maxTileWidth / (screenWidth * 0.28)).clamp(0.35, 1.0).toDouble()
        : 0.6;
    visualScale = math.min(visualScale, widthScale);

    final double resolvedTileHeight =
        (preferredTileHeight * visualScale)
            .clamp(80, screenHeight * 0.32)
            .toDouble();

    final double estimatedContentHeight =
        resolvedTileHeight * metrics.length +
            spacing * (metrics.length - 1);

    Widget column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < metrics.length; i++) ...[
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: minTileWidth,
              maxWidth: maxTileWidth,
              minHeight: resolvedTileHeight,
            ),
            child: _MetricTile(
              data: metrics[i],
              visualScale: visualScale,
              dense: false,
              isLandscape: isLandscape,
            ),
          ),
          if (i + 1 < metrics.length)
            SizedBox(height: spacing),
        ],
      ],
    );

    final double scrollableAreaHeight =
        boundedHeight != null && boundedHeight.isFinite
            ? math.max(0, boundedHeight - panelVerticalPadding)
            : double.infinity;

    final bool needsScroll =
        estimatedContentHeight > scrollableAreaHeight;

    if (needsScroll) {
      column = SingleChildScrollView(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        child: column,
      );
    }

    return IntrinsicWidth(child: column);
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

class _TwoByTwoMetricsGrid extends StatelessWidget {
  const _TwoByTwoMetricsGrid({required this.tiles, required this.isLandscape});

  final List<_MetricTileData> tiles;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    const cellGap = 16.0;

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: dividerColor),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: dividerColor),
              ),
            ),
          ),
        ),
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: cellGap / 2,
                      bottom: cellGap,
                    ),
                    child: _MetricTile(
                      data: tiles[0],
                      visualScale: 1.0,
                      dense: true,
                      isLandscape: isLandscape,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: cellGap / 2,
                      bottom: cellGap,
                    ),
                    child: _MetricTile(
                      data: tiles[1],
                      visualScale: 1.0,
                      dense: true,
                      isLandscape: isLandscape,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      right: cellGap / 2,
                      top: cellGap,
                    ),
                    child: _MetricTile(
                      data: tiles[2],
                      visualScale: 1.0,
                      dense: true,
                      isLandscape: isLandscape,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: cellGap / 2,
                      top: cellGap,
                    ),
                    child: _MetricTile(
                      data: tiles[3],
                      visualScale: 1.0,
                      dense: true,
                      isLandscape: isLandscape,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.data,
    required this.visualScale,
    this.dense = false,
    required this.isLandscape,
  });

  final _MetricTileData data;
  final double visualScale;
  final bool dense;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool preset = dense;

    final double layoutScale = visualScale.clamp(0.2, 1.0).toDouble();
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final double orientationBoost = isLandscape ? 1.18 : 1.0;
    final double typographicScale =
        (visualScale * orientationBoost * textScaleFactor)
            .clamp(isLandscape ? 0.4 : 0.3, isLandscape ? 1.3 : 1.1)
            .toDouble();

    final TextStyle labelBase = preset
        ? const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          )
        : (theme.textTheme.labelMedium ??
            theme.textTheme.labelSmall ??
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600));
    final bool isDark = colorScheme.brightness == Brightness.dark;
    final TextStyle labelStyle = labelBase.copyWith(
      color: preset
          ? colorScheme.onSurface.withOpacity(isDark ? 0.72 : 0.58)
          : colorScheme.onSurfaceVariant.withOpacity(isDark ? 0.95 : 0.82),
      fontSize: (labelBase.fontSize ?? 12) *
          typographicScale.clamp(0.7, 1.0).toDouble(),
      letterSpacing: preset ? 0.9 : 0.6,
    );

    final TextStyle valueBase = preset
        ? const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            height: 1.0,
          )
        : (theme.textTheme.displaySmall ??
            theme.textTheme.headlineMedium ??
            const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.0));
    final double baseValueFontSize = valueBase.fontSize ?? 40;
    final TextStyle valueStyle = valueBase.copyWith(
      color: colorScheme.onSurface,
      fontSize: baseValueFontSize * typographicScale,
    );

    final TextStyle unitBase = preset
        ? const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.0,
          )
        : (theme.textTheme.titleSmall ??
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600));
    final double baseUnitFontSize = unitBase.fontSize ?? 18;
    final TextStyle unitStyle = unitBase.copyWith(
      color: colorScheme.onSurface,
      fontSize: baseUnitFontSize *
          typographicScale.clamp(0.6, isLandscape ? 1.2 : 1.05).toDouble(),
    );

    final double verticalPadding =
        lerpDouble(preset ? 8 : 8, preset ? 12 : 16, layoutScale)!;
    final double horizontalPadding =
        lerpDouble(preset ? 10 : 12, preset ? 16 : 20, layoutScale)!;

    final bool showBackground = !preset;
    final BoxDecoration? decoration;
    if (showBackground) {
      final Color baseColor = Color.lerp(
            colorScheme.surface,
            Colors.white,
            isDark ? 0.15 : 0.6,
          )!
          .withOpacity(isDark ? 0.24 : 0.42);
      decoration = BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(20),
      );
    } else {
      decoration = null;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.label.toUpperCase(), style: labelStyle),
          SizedBox(
            height: lerpDouble(preset ? 6 : 6, preset ? 10 : 12, layoutScale)!,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(data.value.value, style: valueStyle),
              if (data.value.unit != null) ...[
                SizedBox(width: lerpDouble(4, 8, layoutScale)!),
                Text(data.value.unit!, style: unitStyle),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

double? _sanitizeDistance(double? meters) {
  if (meters == null || !meters.isFinite) return null;
  return meters < 0 ? 0 : meters;
}

double? _estimateSafeSpeed({
  required double averageKph,
  required double? limitKph,
  required double? remainingMeters,
  required DateTime? startedAt,
  required DateTime now,
}) {
  if (limitKph == null || !limitKph.isFinite) return null;
  if (!averageKph.isFinite) return null;
  if (remainingMeters == null || remainingMeters <= 0) return null;
  if (startedAt == null) return null;

  final double remainingKm = remainingMeters / 1000.0;
  final Duration elapsed = now.difference(startedAt);
  final double elapsedHours = elapsed.inSeconds / 3600.0;
  if (elapsedHours <= 0) return limitKph;

  final double denominator =
      (averageKph - limitKph) * elapsedHours + remainingKm;
  if (denominator <= 0) return limitKph;

  final double required = (limitKph * remainingKm) / denominator;
  if (!required.isFinite) return limitKph;

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
    final String formatted =
        km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return _MetricValue(value: formatted, unit: unit);
  }
  final String unit = localizations.translate('unitMetersShort');
  return _MetricValue(value: meters.toStringAsFixed(0), unit: unit);
}
