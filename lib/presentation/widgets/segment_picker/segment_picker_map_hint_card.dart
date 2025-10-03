import 'package:flutter/material.dart';

class SegmentPickerMapHintCard extends StatelessWidget {
  const SegmentPickerMapHintCard({
    super.key,
    required this.hasStart,
    required this.hasEnd,
  });

  final bool hasStart;
  final bool hasEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String message;
    if (!hasStart && !hasEnd) {
      message = 'Tap anywhere on the map to place point A.';
    } else if (hasStart && !hasEnd) {
      message = 'Tap a second location to place point B.';
    } else {
      message = 'Tap near A or B to reposition that point.';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}
