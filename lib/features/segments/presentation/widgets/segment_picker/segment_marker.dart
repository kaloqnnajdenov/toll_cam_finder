import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/constants.dart';

class SegmentMarker extends StatelessWidget {
  const SegmentMarker({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: AppConstants.segmentPickerMarkerShadowBlurRadius,
            offset: Offset(0, AppConstants.segmentPickerMarkerShadowOffsetY),
          ),
        ],
      ),
      child: SizedBox(
        width: AppConstants.segmentPickerMarkerInnerDiameter,
        height: AppConstants.segmentPickerMarkerInnerDiameter,
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
