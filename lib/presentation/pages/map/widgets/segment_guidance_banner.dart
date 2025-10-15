import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/constants.dart';
import 'package:toll_cam_finder/services/segment_guidance_controller.dart';

class SegmentGuidanceBanner extends StatelessWidget {
  const SegmentGuidanceBanner({
    super.key,
    required this.guidance,
    this.margin,
  });

  final SegmentGuidanceUiModel guidance;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
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
            guidance.line1,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            guidance.line2,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (guidance.line3 != null) ...[
            const SizedBox(height: 2),
            Text(
              guidance.line3!,
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
