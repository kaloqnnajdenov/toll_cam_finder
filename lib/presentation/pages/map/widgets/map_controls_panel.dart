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
      colorScheme: Theme.of(context).colorScheme,
      maxWidth: panelMaxWidth,
      maxHeight: panelMaxHeight,
      stackMetricsVertically: !placeLeft, // bottom placement => 2×2
      forceSingleRow: placeLeft,          // left placement => single column
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
          // stronger blur for frosted look
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
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

            // --- VERTICAL MODE => 2×2 grid like the screenshot ---
            if (stackMetricsVertically) {
              final List<_MetricTileData> orderedMetrics = [
                metrics[0], // current
                metrics[1], // avg
                metrics[3], // distance
                metrics[2], // safe / limit
              ];
              return _TwoByTwoMetricsGrid(tiles: orderedMetrics);
            }

            // --- LEFT RAIL (single column), unchanged behavior ---
            if (forceSingleRow) {
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
                        ),
                        child: _MetricTile(
                          data: metrics[i],
                          visualScale: visualScale,
                          dense: false,
                        ),
                      ),
                      if (i + 1 < metrics.length)
                        const SizedBox(height: spacing),
                    ],
                  ],
                ),
              );
            }

            // --- Fallback wrap (unchanged) ---
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
      final String formatted = km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
      return _MetricValue(value: formatted, unit: unit);
    }
    final String unit = localizations.translate('unitMetersShort');
    return _MetricValue(value: meters.toStringAsFixed(0), unit: unit);
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

/// 2×2 grid used in vertical mode (bottom placement).
/// Center separators are drawn with true centering.
class _TwoByTwoMetricsGrid extends StatelessWidget {
  const _TwoByTwoMetricsGrid({required this.tiles});

  final List<_MetricTileData> tiles;

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.12);

    const cellGap = 16.0;

    return Stack(
      children: [
        // Horizontal center divider
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
        // Vertical center divider
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
        // Content
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
                      dense: true,  // use preset typography to match screenshot
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
  });

  final _MetricTileData data;
  final double visualScale;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // When dense=true (2×2), match the screenshot typography closely.
    final bool preset = dense;

    final double layoutScale = visualScale.clamp(0.2, 1.0).toDouble();
    final double textScaleFactor = MediaQuery.textScaleFactorOf(context);
    final double typographicScale =
        (visualScale * textScaleFactor).clamp(0.3, 1.1).toDouble();

    final TextStyle labelBase = preset
        ? const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          )
        : (theme.textTheme.labelMedium ??
            theme.textTheme.labelSmall ??
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600));
    final TextStyle labelStyle = labelBase.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontSize: (labelBase.fontSize ?? 12) *
          typographicScale.clamp(0.7, 1.0).toDouble(),
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

    // Units smaller and medium weight
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
      fontSize:
          baseUnitFontSize * typographicScale.clamp(0.6, 1.05).toDouble(),
    );

    final double verticalPadding =
        lerpDouble(preset ? 8 : 8, preset ? 12 : 16, layoutScale)!;
    final double horizontalPadding =
        lerpDouble(preset ? 10 : 12, preset ? 16 : 20, layoutScale)!;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.label.toUpperCase(), style: labelStyle),
          SizedBox(
              height: lerpDouble(preset ? 6 : 6, preset ? 10 : 12, layoutScale)!),
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
