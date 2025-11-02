import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/features/segments/services/segments_repository.dart';

class SegmentCard extends StatelessWidget {
  const SegmentCard({super.key, required this.segment, this.onLongPress});

  final SegmentInfo segment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadges = segment.isLocalOnly || segment.isDeactivated;
    final speedLimit = segment.speedLimitKph?.trim();
    final hasSpeedLimit = speedLimit != null && speedLimit.isNotEmpty;
    return Card(
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      segment.displayId,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasBadges) ...[
                    const SizedBox(width: 8),
                    _SegmentBadges(segment: segment),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                segment.name,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SegmentLocation(
                      title: AppMessages.segmentLocationStartLabel,
                      value: segment.startDisplayName,
                      fallback: segment.startCoordinates,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SegmentLocation(
                      title: AppMessages.segmentLocationEndLabel,
                      value: segment.endDisplayName,
                      fallback: segment.endCoordinates,
                    ),
                  ),
                ],
              ),
              if (hasSpeedLimit) ...[
                const SizedBox(height: 16),
                _SegmentSpeed(speedLimit: speedLimit!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeactivatedBadge extends StatelessWidget {
  const _DeactivatedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppMessages.segmentBadgeHidden,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _LocalBadge extends StatelessWidget {
  const _LocalBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppMessages.segmentBadgeLocal,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  const _ReviewBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppMessages.segmentBadgeReview,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
        ),
      ),
    );
  }
}

class _ApprovedBadge extends StatelessWidget {
  const _ApprovedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        AppMessages.segmentBadgeApproved,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _SegmentBadges extends StatelessWidget {
  const _SegmentBadges({required this.segment});

  final SegmentInfo segment;

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];
    if (segment.isDeactivated) {
      badges.add(const _DeactivatedBadge());
    }
    if (segment.isLocalOnly) {
      if (segment.isPublicReviewPending) {
        badges.add(const _ReviewBadge());
      } else if (segment.isPublicReviewApproved) {
        badges.add(const _ApprovedBadge());
      } else {
        badges.add(const _LocalBadge());
      }
    }

    if (badges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(spacing: 8, runSpacing: 8, children: badges);
  }
}

class _SegmentLocation extends StatelessWidget {
  const _SegmentLocation({
    required this.title,
    required this.value,
    required this.fallback,
  });

  final String title;
  final String value;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedValue = value.trim();
    final trimmedFallback = fallback.trim();
    final displayValue = trimmedValue.isNotEmpty
        ? trimmedValue
        : (trimmedFallback.isNotEmpty ? trimmedFallback : '—');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          displayValue,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SegmentSpeed extends StatelessWidget {
  const _SegmentSpeed({required this.speedLimit});

  final String speedLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.speed,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Max speed: $speedLimit km/h',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
