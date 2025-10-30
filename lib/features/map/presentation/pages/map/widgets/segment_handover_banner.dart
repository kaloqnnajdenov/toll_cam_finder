import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/features/segments/domain/controllers/current_segment_controller.dart';

class SegmentHandoverBanner extends StatelessWidget {
  const SegmentHandoverBanner({
    super.key,
    required this.status,
    this.margin,
  });

  final SegmentHandoverStatus status;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final String unit = localizations.speedDialUnitKmh;
    final String unknown = localizations.segmentHandoverUnknownValue;

    final String previousAverageText = localizations.segmentHandoverPreviousAverage(
      _formatValue(status.previousAverageKph, unknown),
      unit,
    );
    final String previousLimitText = localizations.segmentHandoverPreviousLimit(
      _formatValue(status.previousLimitKph, unknown),
      unit,
    );
    final String nextLimitText = localizations.segmentHandoverNextLimit(
      _formatValue(status.nextLimitKph, unknown),
      unit,
    );
    final String summaryText = status.hasNextSegment
        ? nextLimitText
        : localizations.segmentHandoverNoNextSegment;

    return Container(
      margin: margin ?? const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.speedDialBannerHorizontalPadding,
        vertical: AppConstants.speedDialBannerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppConstants.speedDialBannerRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.segmentHandoverTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            previousAverageText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            previousLimitText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summaryText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(double? value, String unknown) {
    if (value == null || !value.isFinite) {
      return unknown;
    }
    return value.toStringAsFixed(0);
  }
}
