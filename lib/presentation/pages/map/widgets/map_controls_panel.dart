import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/presentation/widgets/avg_speed_dial.dart';
import 'package:toll_cam_finder/presentation/widgets/curretn_speed_dial.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

import 'segment_guidance_banner.dart';

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
  final bool showDebugBadge;
  final int segmentCount;
  final double segmentRadiusMeters;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CurrentSpeedDial(
          speedKmh: speedKmh,
          title: localizations.speedDialCurrentTitle,
          unit: localizations.speedDialUnitKmh,
        ),
        const SizedBox(height: AppConstants.speedDialStackSpacing),
        AverageSpeedDial(
          controller: avgController,
          title: localizations.speedDialAverageTitle,
          unit: localizations.speedDialUnitKmh,
          isActive: hasActiveSegment,
          speedLimitKph:
              hasActiveSegment ? segmentSpeedLimitKph : null,
        ),
        if (segmentDebugPath != null)
          SegmentGuidanceBanner(path: segmentDebugPath!),
        if (segmentProgressLabel != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.speedDialBannerHorizontalPadding,
              vertical: AppConstants.speedDialBannerVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius:
                  BorderRadius.circular(AppConstants.speedDialBannerRadius),
            ),
            child: Text(
              segmentProgressLabel!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (lastSegmentAvgKmh != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.speedDialBannerHorizontalPadding,
              vertical: AppConstants.speedDialBannerVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius:
                  BorderRadius.circular(AppConstants.speedDialBannerRadius),
            ),
            child: Text(
              localizations.translate(
                'speedDialLastSegmentAverage',
                {
                  'value': lastSegmentAvgKmh!
                      .toStringAsFixed(1),
                  'unit': localizations.speedDialUnitKmh,
                },
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (showDebugBadge && kDebugMode)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.speedDialDebugBadgeHorizontalPadding,
              vertical: AppConstants.speedDialDebugBadgeVerticalPadding,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius:
                  BorderRadius.circular(AppConstants.speedDialDebugBadgeRadius),
            ),
            child: Text(
              localizations.translate(
                'speedDialDebugSummary',
                {
                  'count': '$segmentCount',
                  'radius': '${segmentRadiusMeters.toInt()}',
                  'unit': localizations.translate('unitMetersShort'),
                },
              ),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
