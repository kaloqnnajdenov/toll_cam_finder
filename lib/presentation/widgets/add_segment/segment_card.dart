import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/segments_repository.dart';

class SegmentCard extends StatelessWidget {
  const SegmentCard({super.key, required this.segment, this.onLongPress});

  final SegmentInfo segment;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasBadges = segment.isLocalOnly || segment.isDeactivated;
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      segment.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (hasBadges) ...[
                    const SizedBox(width: 8),
                    _SegmentBadges(segment: segment),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _SegmentLocation(value: segment.startDisplayName),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SegmentLocation(value: segment.endDisplayName),
                  ),
                ],
              ),
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
        'Hidden',
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
        'Local',
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
        'Review',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onTertiaryContainer,
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
      if (segment.isMarkedPublic) {
        badges.add(const _ReviewBadge());
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
  const _SegmentLocation({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedValue = value.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trimmedValue.isEmpty ? '—' : trimmedValue,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
