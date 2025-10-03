import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/constants.dart';

class MapHintCard extends StatelessWidget {
  const MapHintCard({
    super.key,
    required this.hasStart,
    required this.hasEnd,
  });

  final bool hasStart;
  final bool hasEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _buildMessage();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface
            .withOpacity(AppConstants.segmentPickerSurfaceOpacity),
        borderRadius:
            BorderRadius.circular(AppConstants.segmentPickerHintCornerRadius),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.segmentPickerHintHorizontalPadding,
          vertical: AppConstants.segmentPickerHintVerticalPadding,
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _buildMessage() {
    if (!hasStart && !hasEnd) {
      return 'Tap anywhere on the map to place point A.';
    } else if (hasStart && !hasEnd) {
      return 'Tap a second location to place point B.';
    }
    return 'Touch and hold A or B for 0.5s, then drag to reposition that point.';
  }
}
