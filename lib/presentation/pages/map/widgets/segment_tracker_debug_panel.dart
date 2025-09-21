import 'package:flutter/material.dart';
import 'package:toll_cam_finder/services/segment_tracker.dart';

import 'segment_debug_styles.dart';

class SegmentTrackerDebugPanel extends StatelessWidget {
  const SegmentTrackerDebugPanel({
    super.key,
    required this.snapshot,
    required this.distanceThresholdMeters,
    required this.startGeofenceRadiusMeters,
  });

  final SegmentTrackerDebugSnapshot snapshot;
  final double distanceThresholdMeters;
  final double startGeofenceRadiusMeters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.labelLarge?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final infoStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white70,
    );

    final matches = [...snapshot.matches]
      ..sort((a, b) {
        if (a.isBestCandidate != b.isBestCandidate) {
          return a.isBestCandidate ? -1 : 1;
        }
        final activeId = snapshot.activeSegment?.id;
        if (activeId != null) {
          final aIsActive = a.segment.id == activeId;
          final bIsActive = b.segment.id == activeId;
          if (aIsActive != bIsActive) {
            return aIsActive ? -1 : 1;
          }
        }
        return a.distanceMeters.compareTo(b.distanceMeters);
      });

    final topMatches = matches.take(4).toList();

    final entered = snapshot.enteredSegment;
    final exited = snapshot.exitedSegment;

    return Card(
      color: Colors.black87.withOpacity(0.75),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Segment tracker', style: titleStyle),
              const SizedBox(height: 4),
              _StatusLine(
                label: 'Active',
                value: snapshot.activeSegment?.id ?? 'none',
                color: snapshot.activeSegment != null
                    ? Colors.greenAccent
                    : Colors.white54,
              ),
              if (entered != null)
                _StatusLine(
                  label: 'Entered',
                  value: entered.id,
                  color: Colors.greenAccent,
                ),
              if (exited != null)
                _StatusLine(
                  label: 'Exited',
                  value: exited.id,
                  color: Colors.redAccent,
                ),
              if (snapshot.distanceToActiveMeters != null)
                Text(
                  '⊥ distance: ${snapshot.distanceToActiveMeters!.toStringAsFixed(1)} m',
                  style: infoStyle,
                ),
              if (snapshot.startDistanceToActiveMeters != null)
                Text(
                  'Start distance: ${snapshot.startDistanceToActiveMeters!.toStringAsFixed(1)} m',
                  style: infoStyle,
                ),
              if (topMatches.isNotEmpty) ...[
                const SizedBox(height: 12),
                Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                for (var i = 0; i < topMatches.length; i++) ...[
                  _MatchRow(
                    match: topMatches[i],
                    isActive:
                        snapshot.activeSegment?.id == topMatches[i].segment.id,
                  ),
                  if (i != topMatches.length - 1) const SizedBox(height: 10),
                ],
              ] else ...[
                const SizedBox(height: 12),
                Text('No segment candidates in radius', style: infoStyle),
              ],
              const SizedBox(height: 8),
              Text(
                'distance≤${distanceThresholdMeters.toStringAsFixed(0)} m · '
                'start≤${startGeofenceRadiusMeters.toStringAsFixed(0)} m',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white70,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text('$label:', style: style),
          ),
          Expanded(
            child: Text(
              value,
              style: style?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({
    required this.match,
    required this.isActive,
  });

  final SegmentTrackerDebugMatch match;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SegmentDebugStyles.colorForMatch(match, isActive: isActive);
    final textStyle = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white,
      fontWeight: isActive || match.isBestCandidate
          ? FontWeight.w600
          : FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                match.segment.id,
                style: textStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (match.directionDeltaDeg != null) ...[
              Text(
                'Δ ${match.directionDeltaDeg!.toStringAsFixed(0)}°',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: match.directionOk
                      ? Colors.white70
                      : Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${match.distanceMeters.toStringAsFixed(1)} m',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 2,
          children: [
            for (final flag in SegmentDebugStyles.flagsForMatch(match))
              _DebugChip(flag: flag),
          ],
        ),
      ],
    );
  }
}

class _DebugChip extends StatelessWidget {
  const _DebugChip({required this.flag});

  final SegmentDebugFlag flag;

  @override
  Widget build(BuildContext context) {
    final background = flag.color.withOpacity(0.18);
    final border = flag.color.withOpacity(0.8);
    final textColor = flag.color.computeLuminance() > 0.55
        ? Colors.black87
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        flag.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontSize: 11,
            ),
      ),
    );
  }
}
