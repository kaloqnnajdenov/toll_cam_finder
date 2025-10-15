import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

class SegmentGuidanceBanner extends StatelessWidget {
  const SegmentGuidanceBanner({
    super.key,
    required this.path,
    this.margin,
  });

  final SegmentDebugPath path;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final String distanceText = localizations.translate(
      'segmentDebugDistanceMeters',
      {'distance': path.distanceMeters.toStringAsFixed(1)},
    );

    String? remainingDistanceText;
    final double remainingMeters = path.remainingDistanceMeters;
    if (remainingMeters.isFinite) {
      final String remainingKm = (remainingMeters / 1000).toStringAsFixed(2);
      remainingDistanceText = localizations.translate(
        'segmentDebugDistanceKilometersLeft',
        {'distance': remainingKm},
      );
    }

    final List<String> tags = <String>[
      path.isDetailed
          ? localizations.translate('segmentDebugTagDetailed')
          : localizations.translate('segmentDebugTagApprox'),
      if (path.startHit)
        localizations.translate('segmentDebugTagStart'),
      if (path.endHit) localizations.translate('segmentDebugTagEnd'),
    ];
    final String? tagsText = tags.isEmpty
        ? null
        : tags.join(localizations.translate('segmentDebugTagSeparator'));

    return Container(
      margin: margin ?? const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.speedDialBannerHorizontalPadding,
        vertical: AppConstants.speedDialBannerVerticalPadding,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppConstants.speedDialBannerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            path.id,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            distanceText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (remainingDistanceText != null) ...[
            const SizedBox(height: 2),
            Text(
              remainingDistanceText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (tagsText != null) ...[
            const SizedBox(height: 2),
            Text(
              tagsText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
