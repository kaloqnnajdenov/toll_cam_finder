import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

class VerticalMapChrome extends StatefulWidget {
  const VerticalMapChrome({
    super.key,
    required this.map,
    required this.onResetView,
    required this.onToggleHeading,
    required this.followUser,
    required this.followHeading,
    required this.headingDegrees,
    required this.speedKmh,
    required this.speedLimitKph,
    required this.speedLimitLabel,
    required this.avgController,
    required this.hasActiveSegment,
    required this.distanceToSegmentStartMeters,
    required this.distanceToSegmentEndMeters,
  });

  final Widget map;
  final VoidCallback onResetView;
  final VoidCallback onToggleHeading;
  final bool followUser;
  final bool followHeading;
  final double? headingDegrees;
  final double? speedKmh;
  final double? speedLimitKph;
  final String? speedLimitLabel;
  final AverageSpeedController avgController;
  final bool hasActiveSegment;
  final double? distanceToSegmentStartMeters;
  final double? distanceToSegmentEndMeters;

  @override
  State<VerticalMapChrome> createState() => _VerticalMapChromeState();
}

class _VerticalMapChromeState extends State<VerticalMapChrome> {
  late final DraggableScrollableController _sheetController;

  @override
  void initState() {
    super.initState();
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_handleSheetChanged);
  }

  @override
  void dispose() {
    _sheetController.removeListener(_handleSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  void _handleSheetChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final metrics = _VerticalLayoutMetrics(mediaQuery);
    final brightness = Theme.of(context).brightness;

    final double collapsedFraction =
        metrics.collapsedHeight / metrics.screenHeight;
    final double midFraction = metrics.expandedHeight / metrics.screenHeight;
    final double maxFraction =
        metrics.maxExpandedHeight / metrics.screenHeight;

    double currentSheetFraction = collapsedFraction;
    try {
      currentSheetFraction = _sheetController.size;
    } catch (_) {
      currentSheetFraction = collapsedFraction;
    }

    final double span = (maxFraction - collapsedFraction).abs();
    final double normalizedProgress = span <= 0.0001
        ? 0.0
        : ((currentSheetFraction - collapsedFraction) /
                (maxFraction - collapsedFraction))
            .clamp(0.0, 1.0);
    final bool showSpeedLimitChip =
        currentSheetFraction <= collapsedFraction + 0.01;

    final sheetData = _SheetMetricsData.fromState(
      localizations: AppLocalizations.of(context),
      currentSpeedKmh: widget.speedKmh,
      avgController: widget.avgController,
      hasActiveSegment: widget.hasActiveSegment,
      speedLimitKph: widget.speedLimitKph,
      distanceToStartMeters: widget.distanceToSegmentStartMeters,
      distanceToEndMeters: widget.distanceToSegmentEndMeters,
    );

    return Stack(
      children: [
        Positioned.fill(child: widget.map),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: _MapVignette(metrics: metrics, brightness: brightness),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              top: metrics.edgeInset,
              left: metrics.edgeInset,
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: showSpeedLimitChip ? 1.0 : 0.0,
              child: showSpeedLimitChip
                  ? _SpeedLimitChip(
                      metrics: metrics,
                      brightness: brightness,
                      label: widget.speedLimitLabel,
                      currentSpeedKmh: widget.speedKmh,
                      speedLimitKmh: widget.speedLimitKph,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(
                top: metrics.edgeInset,
                right: metrics.edgeInset,
              ),
              child: Builder(
                builder: (context) => _MenuButton(
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: Offset(0, -metrics.speedBubbleVerticalOffset),
            child: _SpeedBubble(
              metrics: metrics,
              brightness: brightness,
              speedKmh: widget.speedKmh,
              speedLimitKmh: widget.speedLimitKph,
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: metrics.edgeInset,
                bottom: metrics.edgeInset,
              ),
              child: _FabStack(
                metrics: metrics,
                brightness: brightness,
                followUser: widget.followUser,
                followHeading: widget.followHeading,
                headingDegrees: widget.headingDegrees,
                onResetView: widget.onResetView,
                onToggleHeading: widget.onToggleHeading,
              ),
            ),
          ),
        ),
        _VerticalMetricsSheet(
          controller: _sheetController,
          metrics: metrics,
          brightness: brightness,
          collapsedFraction: collapsedFraction,
          midFraction: midFraction,
          maxFraction: maxFraction,
          sheetProgress: normalizedProgress,
          data: sheetData,
        ),
      ],
    );
  }
}

class _MapVignette extends StatelessWidget {
  const _MapVignette({
    required this.metrics,
    required this.brightness,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final double height = metrics.screenHeight * 0.12;
    final Color baseColor = brightness == Brightness.dark
        ? Colors.black.withOpacity(0.10)
        : Colors.black.withOpacity(0.06);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              baseColor.withOpacity(0.0),
              baseColor,
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color background = Colors.black.withOpacity(0.45);
    return Material(
      color: background,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.menu, color: Colors.white),
        tooltip: AppLocalizations.of(context).openMenu,
      ),
    );
  }
}

class _SpeedBubble extends StatelessWidget {
  const _SpeedBubble({
    required this.metrics,
    required this.brightness,
    required this.speedKmh,
    required this.speedLimitKmh,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final double? speedKmh;
  final double? speedLimitKmh;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final Color background = brightness == Brightness.dark
        ? const Color(0xA6000000)
        : const Color(0xE62B2F3A);

    final String speedText = _formatSpeedDisplay(speedKmh);
    final Color valueColor = _resolveSpeedColor(
      brightness: brightness,
      speed: speedKmh,
      limit: speedLimitKmh,
      neutralOnLight: Colors.white,
      neutralOnDark: Colors.white,
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      offset: const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: 1,
        child: Container(
          height: metrics.speedBubbleHeight,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.speedBubbleHorizontalPadding,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(metrics.speedBubbleRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.24),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SizeTransition(sizeFactor: animation, child: child),
                  ),
                  child: Text(
                    speedText,
                    key: ValueKey<String>(speedText),
                    style: TextStyle(
                      fontSize: metrics.speedBubbleValueFontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.01 * metrics.speedBubbleValueFontSize,
                      color: valueColor,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                SizedBox(width: metrics.speedBubbleUnitSpacing),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: metrics.speedBubbleUnitBaselineOffset,
                  ),
                  child: Text(
                    localizations.speedDialUnitKmh,
                    style: TextStyle(
                      fontSize: metrics.speedBubbleUnitFontSize,
                      fontWeight: FontWeight.w600,
                      color: valueColor.withOpacity(0.85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _SpeedLimitChip extends StatelessWidget {
  const _SpeedLimitChip({
    required this.metrics,
    required this.brightness,
    required this.label,
    required this.currentSpeedKmh,
    required this.speedLimitKmh,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final String? label;
  final double? currentSpeedKmh;
  final double? speedLimitKmh;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final Color background = brightness == Brightness.dark
        ? const Color(0xEB0B0F14)
        : const Color(0xE6FFFFFF);
    final String valueText = label ?? '--';

    final Color valueColor = _resolveSpeedColor(
      brightness: brightness,
      speed: currentSpeedKmh,
      limit: speedLimitKmh,
      neutralOnLight: const Color(0xFF0B1220),
      neutralOnDark: const Color(0xFFE6E9EF),
    );

    final Color labelColor = valueColor.withOpacity(0.8);

    return Container(
      constraints: BoxConstraints(minHeight: metrics.speedLimitChipHeight),
      padding: EdgeInsets.symmetric(
        horizontal: metrics.speedLimitChipHorizontalPadding,
        vertical: metrics.speedLimitChipVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(metrics.speedLimitChipRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valueText,
            style: TextStyle(
              fontSize: metrics.speedLimitValueFontSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(height: metrics.gap * 0.25),
          Text(
            localizations.translate('segmentMetricsSpeedLimit'),
            style: TextStyle(
              fontSize: metrics.speedLimitLabelFontSize,
              fontWeight: FontWeight.w600,
              color: labelColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FabStack extends StatelessWidget {
  const _FabStack({
    required this.metrics,
    required this.brightness,
    required this.followUser,
    required this.followHeading,
    required this.headingDegrees,
    required this.onResetView,
    required this.onToggleHeading,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final bool followUser;
  final bool followHeading;
  final double? headingDegrees;
  final VoidCallback onResetView;
  final VoidCallback onToggleHeading;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4F8BFF);
    final Color onPrimary = Colors.white;
    final Color secondaryColor = brightness == Brightness.dark
        ? const Color(0xE6121820)
        : const Color(0xE6F4F6F8);
    final Color onSecondary = brightness == Brightness.dark
        ? const Color(0xFFE6E9EF).withOpacity(0.8)
        : const Color(0xFF0B1220).withOpacity(0.8);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AdaptiveFabButton(
          diameter: metrics.secondaryFabDiameter,
          backgroundColor: secondaryColor,
          elevation: 3,
          border: followHeading
              ? Border.all(color: primaryColor, width: 2)
              : null,
          onPressed: onToggleHeading,
          child: _CompassIcon(
            followHeading: followHeading,
            headingDegrees: headingDegrees,
            color: onSecondary,
            diameter: metrics.secondaryFabDiameter,
          ),
        ),
        SizedBox(height: metrics.fabSpacing),
        _AdaptiveFabButton(
          diameter: metrics.primaryFabDiameter,
          backgroundColor: primaryColor,
          elevation: 6,
          onPressed: onResetView,
          child: Icon(
            followUser ? Icons.my_location : Icons.my_location_outlined,
            size: metrics.primaryFabIconSize,
            color: onPrimary,
          ),
        ),
      ],
    );
  }
}

class _CompassIcon extends StatelessWidget {
  const _CompassIcon({
    required this.followHeading,
    required this.headingDegrees,
    required this.color,
    required this.diameter,
  });

  final bool followHeading;
  final double? headingDegrees;
  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final bool shouldRotate = followHeading && headingDegrees != null;
    final double turns = shouldRotate ? (headingDegrees! % 360) / 360 : 0;
    final double iconSize = math.min(28, diameter * 0.45);

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedRotation(
          turns: turns,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: Icon(Icons.navigation, color: color, size: iconSize),
        ),
        AnimatedOpacity(
          opacity: followHeading ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          child: Icon(
            Icons.lock,
            size: iconSize * 0.42,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _AdaptiveFabButton extends StatefulWidget {
  const _AdaptiveFabButton({
    required this.diameter,
    required this.backgroundColor,
    required this.onPressed,
    this.child,
    this.elevation = 6,
    this.border,
  });

  final double diameter;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final double elevation;
  final Widget? child;
  final BoxBorder? border;

  @override
  State<_AdaptiveFabButton> createState() => _AdaptiveFabButtonState();
}

class _AdaptiveFabButtonState extends State<_AdaptiveFabButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Material(
          color: widget.backgroundColor,
          elevation: widget.elevation,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: widget.onPressed,
            customBorder: const CircleBorder(),
            child: Ink(
              width: widget.diameter,
              height: widget.diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: widget.border,
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
class _VerticalMetricsSheet extends StatelessWidget {
  const _VerticalMetricsSheet({
    required this.controller,
    required this.metrics,
    required this.brightness,
    required this.collapsedFraction,
    required this.midFraction,
    required this.maxFraction,
    required this.sheetProgress,
    required this.data,
  });

  final DraggableScrollableController controller;
  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final double collapsedFraction;
  final double midFraction;
  final double maxFraction;
  final double sheetProgress;
  final _SheetMetricsData data;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final List<double> snapSizes = <double>{
      collapsedFraction,
      midFraction,
      maxFraction,
    }.toList()
      ..sort();

    final Color background = brightness == Brightness.dark
        ? const Color(0xEB0B0F14)
        : const Color(0xE6FFFFFF);
    final Color borderColor = brightness == Brightness.dark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.05);

    return DraggableScrollableSheet(
      controller: controller,
      minChildSize: collapsedFraction,
      initialChildSize: collapsedFraction,
      maxChildSize: maxFraction,
      snap: true,
      snapSizes: snapSizes,
      builder: (context, scrollController) {
        final double contentOpacity = 0.92 + (0.08 * sheetProgress);
        return Padding(
          padding: EdgeInsets.only(bottom: mediaQuery.padding.bottom),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: metrics.sheetHorizontalMargin,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(metrics.sheetCornerRadius),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(metrics.sheetCornerRadius),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        metrics.sheetPadding,
                        metrics.sheetTopPadding,
                        metrics.sheetPadding,
                        metrics.sheetBottomPadding + mediaQuery.padding.bottom,
                      ),
                      children: [
                        _SheetHandle(metrics: metrics, brightness: brightness),
                        SizedBox(height: metrics.gap),
                        _CollapsedHeaderRow(
                          metrics: metrics,
                          brightness: brightness,
                          data: data,
                        ),
                        SizedBox(height: metrics.gap),
                        Opacity(
                          opacity: contentOpacity,
                          child: _MetricsGrid(
                            metrics: metrics,
                            brightness: brightness,
                            data: data,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.metrics, required this.brightness});

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final Color color = brightness == Brightness.dark
        ? const Color(0xFFE6E9EF).withOpacity(0.2)
        : const Color(0xFF0B1220).withOpacity(0.2);

    return Align(
      child: Container(
        width: metrics.sheetHandleWidth,
        height: 4,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CollapsedHeaderRow extends StatelessWidget {
  const _CollapsedHeaderRow({
    required this.metrics,
    required this.brightness,
    required this.data,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final _SheetMetricsData data;

  @override
  Widget build(BuildContext context) {
    final Color neutral = _neutralOn(brightness);
    final Color warning = const Color(0xFFF59E0B);
    final Color danger = const Color(0xFFEF4444);

    final double separatorPadding = (metrics.screenWidth * 0.02).clamp(8, 18);

    TextStyle baseStyle = TextStyle(
      fontSize: metrics.headerValueFontSize,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    TextStyle separatorStyle = baseStyle.copyWith(
      fontWeight: FontWeight.w500,
      color: neutral.withOpacity(0.6),
    );

    final Color currentColor = _stateColor(
      value: data.currentSpeed.numeric,
      limit: data.limitReferenceSpeed,
      neutral: neutral,
      warning: warning,
      danger: danger,
    );

    final Color limitColor = _stateColor(
      value: data.limitSpeed.numeric,
      limit: data.limitReferenceSpeed,
      neutral: neutral,
      warning: warning,
      danger: danger,
    );

    final TextStyle currentStyle = baseStyle.copyWith(color: currentColor);
    final TextStyle limitStyle = baseStyle.copyWith(color: limitColor);
    final TextStyle avgStyle = baseStyle.copyWith(color: neutral.withOpacity(0.9));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(data.currentSpeed.displayLabel, style: currentStyle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: separatorPadding),
          child: Text('·', style: separatorStyle),
        ),
        Text(data.limitSpeed.displayLabel, style: limitStyle),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: separatorPadding),
          child: Text('·', style: separatorStyle),
        ),
        Text(data.averageSpeed.displayLabel, style: avgStyle),
      ],
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.metrics,
    required this.brightness,
    required this.data,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final _SheetMetricsData data;

  @override
  Widget build(BuildContext context) {
    final neutral = _neutralOn(brightness);
    final warning = const Color(0xFFF59E0B);
    final danger = const Color(0xFFEF4444);

    final cards = <_MetricCardData>[
      _MetricCardData(
        label: data.currentLabel,
        value: data.currentSpeed,
        color: _stateColor(
          value: data.currentSpeed.numeric,
          limit: data.limitReferenceSpeed,
          neutral: neutral,
          warning: warning,
          danger: danger,
        ),
        unitOpacity: 0.8,
      ),
      _MetricCardData(
        label: data.averageLabel,
        value: data.averageSpeed,
        color: neutral.withOpacity(0.9),
        unitOpacity: 0.8,
      ),
      _MetricCardData(
        label: data.limitLabel,
        value: data.limitSpeed,
        color: _stateColor(
          value: data.limitSpeed.numeric,
          limit: data.limitReferenceSpeed,
          neutral: neutral,
          warning: warning,
          danger: danger,
        ),
        unitOpacity: 0.8,
      ),
      _MetricCardData(
        label: data.distanceLabel,
        value: data.distance,
        color: neutral.withOpacity(0.95),
        unitOpacity: 0.8,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;
        final double columnWidth =
            math.max(0, (availableWidth - metrics.gap) / 2);
        return Wrap(
          spacing: metrics.gap,
          runSpacing: metrics.gap,
          children: cards.map((card) {
            return SizedBox(
              width: columnWidth,
              child: _MetricCard(
                metrics: metrics,
                brightness: brightness,
                data: card,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.metrics,
    required this.brightness,
    required this.data,
  });

  final _VerticalLayoutMetrics metrics;
  final Brightness brightness;
  final _MetricCardData data;

  @override
  Widget build(BuildContext context) {
    final Color background = brightness == Brightness.dark
        ? const Color(0xFF121820)
        : const Color(0xFFF4F6F8);

    final double minHeight = metrics.metricCardMinHeight;

    return Material(
      color: Colors.transparent,
      elevation: 2,
      borderRadius: BorderRadius.circular(metrics.metricCardRadius),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: EdgeInsets.all(metrics.metricCardPadding),
        decoration: BoxDecoration(
          color: background.withOpacity(brightness == Brightness.dark ? 0.9 : 0.95),
          borderRadius: BorderRadius.circular(metrics.metricCardRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.label,
              style: TextStyle(
                fontSize: metrics.metricLabelFontSize,
                fontWeight: FontWeight.w500,
                color: data.color.withOpacity(0.9),
              ),
            ),
            SizedBox(height: metrics.metricLabelToValueSpacing),
            Row(
              crossAxisAlignment: TextBaseline.alphabetic,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  data.value.text,
                  style: TextStyle(
                    fontSize: metrics.metricValueFontSize,
                    fontWeight: FontWeight.w600,
                    color: data.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (data.value.unit != null) ...[
                  SizedBox(width: metrics.metricUnitSpacing),
                  Text(
                    data.value.unit!,
                    style: TextStyle(
                      fontSize: metrics.metricValueFontSize * 0.85,
                      fontWeight: FontWeight.w500,
                      color: data.color.withOpacity(data.unitOpacity),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
class _MetricCardData {
  const _MetricCardData({
    required this.label,
    required this.value,
    required this.color,
    required this.unitOpacity,
  });

  final String label;
  final _MetricDisplayValue value;
  final Color color;
  final double unitOpacity;
}

class _SheetMetricsData {
  const _SheetMetricsData({
    required this.currentSpeed,
    required this.averageSpeed,
    required this.limitSpeed,
    required this.distance,
    required this.currentLabel,
    required this.averageLabel,
    required this.limitLabel,
    required this.distanceLabel,
    required this.limitReferenceSpeed,
  });

  final _MetricDisplayValue currentSpeed;
  final _MetricDisplayValue averageSpeed;
  final _MetricDisplayValue limitSpeed;
  final _MetricDisplayValue distance;
  final String currentLabel;
  final String averageLabel;
  final String limitLabel;
  final String distanceLabel;
  final double? limitReferenceSpeed;

  static _SheetMetricsData fromState({
    required AppLocalizations localizations,
    required double? currentSpeedKmh,
    required AverageSpeedController avgController,
    required bool hasActiveSegment,
    required double? speedLimitKph,
    required double? distanceToStartMeters,
    required double? distanceToEndMeters,
  }) {
    final DateTime now = DateTime.now();
    final bool averagingActive = hasActiveSegment && avgController.isRunning;

    final double? sanitizedStart = _sanitizeDistance(distanceToStartMeters);
    final double? sanitizedEnd = _sanitizeDistance(distanceToEndMeters);

    final double? safeSpeed = averagingActive
        ? _estimateSafeSpeed(
            averageKph: avgController.average,
            limitKph: speedLimitKph,
            remainingMeters: sanitizedEnd,
            startedAt: avgController.startedAt,
            now: now,
          )
        : null;

    final String speedUnit = localizations.speedDialUnitKmh;

    final _MetricDisplayValue current = _formatSpeed(currentSpeedKmh, speedUnit);
    final _MetricDisplayValue average = averagingActive
        ? _formatSpeed(avgController.average, speedUnit)
        : const _MetricDisplayValue(text: '-', unit: null, numeric: null);
    final _MetricDisplayValue limit = safeSpeed != null
        ? _formatSpeed(safeSpeed, speedUnit)
        : _formatSpeed(speedLimitKph, speedUnit);

    final bool showSafeSpeed = safeSpeed != null;
    final String limitLabel = showSafeSpeed
        ? localizations.translate('segmentMetricsSafeSpeed')
        : localizations.translate('segmentMetricsSpeedLimit');

    final String currentLabel =
        localizations.translate('segmentMetricsCurrentSpeed');
    final String averageLabel =
        localizations.translate('segmentMetricsAverageSpeed');

    final String distanceLabelKey = hasActiveSegment
        ? 'segmentMetricsDistanceToEnd'
        : 'segmentMetricsDistanceToStart';

    final double? distanceMeters = hasActiveSegment
        ? sanitizedEnd ?? sanitizedStart
        : sanitizedStart;

    final _MetricDisplayValue distanceValue = _formatDistance(
      localizations,
      distanceMeters,
    );

    return _SheetMetricsData(
      currentSpeed: current,
      averageSpeed: average,
      limitSpeed: limit,
      distance: distanceValue,
      currentLabel: currentLabel,
      averageLabel: averageLabel,
      limitLabel: limitLabel,
      distanceLabel: localizations.translate(distanceLabelKey),
      limitReferenceSpeed: speedLimitKph,
    );
  }
}

class _MetricDisplayValue {
  const _MetricDisplayValue({
    required this.text,
    this.unit,
    this.numeric,
  });

  final String text;
  final String? unit;
  final double? numeric;

  String get displayLabel => unit != null ? '$text ${unit!}' : text;
}

class _VerticalLayoutMetrics {
  _VerticalLayoutMetrics(MediaQueryData mediaQuery)
      : screenWidth = mediaQuery.size.width,
        screenHeight = mediaQuery.size.height,
        textScale = mediaQuery.textScaleFactor {
    widthScale = screenWidth / 390.0;
    heightScale = screenHeight / 844.0;
    overallScale = math
        .max(0.85, math.min(1.35, (widthScale + heightScale) / 2.0));
    numericScale = math
        .max(0.90, math.min(1.50, textScale * overallScale));
    edgeInset = _clamp(screenWidth * 0.06, 16, 28);
    gap = _clamp(screenWidth * 0.03, 8, 16);
    speedBubbleHeight = _clamp(screenHeight * 0.066 * overallScale, 52, 68);
    speedBubbleHorizontalPadding =
        _clamp(screenWidth * 0.046, 14, 24);
    speedBubbleRadius = math.min(speedBubbleHeight * 0.28, 24);
    speedBubbleVerticalOffset = screenHeight * 0.085;
    speedBubbleValueFontSize = _clamp(34 * numericScale, 28, 42);
    speedBubbleUnitFontSize = _clamp(15 * numericScale, 13, 18);
    speedBubbleUnitSpacing = gap * 0.6;
    speedBubbleUnitBaselineOffset = speedBubbleValueFontSize * 0.08;

    primaryFabDiameter = _clamp(screenWidth * 0.14, 52, 64);
    secondaryFabDiameter = _clamp(screenWidth * 0.12, 44, 56);
    primaryFabIconSize = math.min(28, primaryFabDiameter * 0.45);
    fabSpacing = gap + 4;

    speedLimitChipHeight = _clamp(primaryFabDiameter * 0.085 + 24, 30, 38);
    speedLimitChipHorizontalPadding = _clamp(screenWidth * 0.04, 12, 20);
    speedLimitChipVerticalPadding = gap * 0.35;
    speedLimitChipRadius = math.min(12 * overallScale, 16);
    speedLimitValueFontSize = _clamp(17 * numericScale, 16, 20);
    speedLimitLabelFontSize = _clamp(13 * numericScale, 12, 15);

    sheetCornerRadius = math.min(24 * overallScale, 28);
    sheetPadding = _clamp(screenWidth * 0.05, 16, 24);
    sheetHorizontalMargin = 0;
    sheetTopPadding = gap * 0.8;
    sheetBottomPadding = gap;
    sheetHandleWidth = _clamp(screenWidth * 0.12, 32, 52);
    collapsedHeight = _clamp(screenHeight * 0.16, 112, 160);
    expandedHeight = screenHeight * 0.55;
    maxExpandedHeight = screenHeight * 0.70;

    headerValueFontSize = _clamp(18 * numericScale, 16, 22);

    metricCardMinHeight = _clamp(screenHeight * 0.12, 84, 124);
    metricCardRadius = math.min(20 * overallScale, 24);
    metricCardPadding = _clamp(screenWidth * 0.04, 12, 18);
    metricLabelFontSize = _clamp(12.5 * numericScale, 11, 14);
    metricValueFontSize = _clamp(22 * numericScale, 18, 26);
    metricLabelToValueSpacing = metricValueFontSize * 0.4;
    metricUnitSpacing = gap * 0.4;
  }

  final double screenWidth;
  final double screenHeight;
  final double textScale;
  late final double widthScale;
  late final double heightScale;
  late final double overallScale;
  late final double numericScale;

  late final double edgeInset;
  late final double gap;

  late final double speedBubbleHeight;
  late final double speedBubbleHorizontalPadding;
  late final double speedBubbleRadius;
  late final double speedBubbleVerticalOffset;
  late final double speedBubbleValueFontSize;
  late final double speedBubbleUnitFontSize;
  late final double speedBubbleUnitSpacing;
  late final double speedBubbleUnitBaselineOffset;

  late final double primaryFabDiameter;
  late final double secondaryFabDiameter;
  late final double primaryFabIconSize;
  late final double fabSpacing;

  late final double speedLimitChipHeight;
  late final double speedLimitChipHorizontalPadding;
  late final double speedLimitChipVerticalPadding;
  late final double speedLimitChipRadius;
  late final double speedLimitValueFontSize;
  late final double speedLimitLabelFontSize;

  late final double sheetCornerRadius;
  late final double sheetPadding;
  late final double sheetHorizontalMargin;
  late final double sheetTopPadding;
  late final double sheetBottomPadding;
  late final double sheetHandleWidth;
  late final double collapsedHeight;
  late final double expandedHeight;
  late final double maxExpandedHeight;

  late final double headerValueFontSize;

  late final double metricCardMinHeight;
  late final double metricCardRadius;
  late final double metricCardPadding;
  late final double metricLabelFontSize;
  late final double metricValueFontSize;
  late final double metricLabelToValueSpacing;
  late final double metricUnitSpacing;

  static double _clamp(double value, double min, double max) =>
      value.clamp(min, max).toDouble();
}

Color _resolveSpeedColor({
  required Brightness brightness,
  required double? speed,
  required double? limit,
  required Color neutralOnLight,
  required Color neutralOnDark,
}) {
  final Color neutral =
      brightness == Brightness.dark ? neutralOnDark : neutralOnLight;
  final Color warning = const Color(0xFFF59E0B);
  final Color danger = const Color(0xFFEF4444);
  return _stateColor(
    value: speed,
    limit: limit,
    neutral: neutral,
    warning: warning,
    danger: danger,
  );
}

Color _stateColor({
  required double? value,
  required double? limit,
  required Color neutral,
  required Color warning,
  required Color danger,
}) {
  if (value == null || !value.isFinite || limit == null || !limit.isFinite) {
    return neutral;
  }
  final double speed = value;
  final double limitValue = limit;
  if (speed >= limitValue) {
    return danger;
  }
  if (speed >= 0.9 * limitValue) {
    return warning;
  }
  return neutral;
}

Color _neutralOn(Brightness brightness) {
  return brightness == Brightness.dark
      ? const Color(0xFFE6E9EF)
      : const Color(0xFF0B1220);
}

String _formatSpeedDisplay(double? speedKmh) {
  if (speedKmh == null || !speedKmh.isFinite) {
    return '--';
  }
  final double sanitized = speedKmh.clamp(0, double.infinity).toDouble();
  final bool useDecimals = sanitized < 10;
  return sanitized.toStringAsFixed(useDecimals ? 1 : 0);
}

_MetricDisplayValue _formatSpeed(double? speedKmh, String unit) {
  if (speedKmh == null || !speedKmh.isFinite) {
    return const _MetricDisplayValue(text: '-', unit: null, numeric: null);
  }
  final double clamped = speedKmh.clamp(0, double.infinity).toDouble();
  final bool useDecimals = clamped < 10;
  final String formatted = clamped.toStringAsFixed(useDecimals ? 1 : 0);
  return _MetricDisplayValue(text: formatted, unit: unit, numeric: clamped);
}

_MetricDisplayValue _formatDistance(
  AppLocalizations localizations,
  double? meters,
) {
  if (meters == null || !meters.isFinite) {
    return const _MetricDisplayValue(text: '-', unit: null, numeric: null);
  }
  if (meters >= 1000) {
    final double km = meters / 1000.0;
    final String unit = localizations.translate('unitKilometersShort');
    final String formatted =
        km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return _MetricDisplayValue(text: formatted, unit: unit, numeric: km);
  }
  final String unit = localizations.translate('unitMetersShort');
  return _MetricDisplayValue(
    text: meters.toStringAsFixed(0),
    unit: unit,
    numeric: meters,
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
