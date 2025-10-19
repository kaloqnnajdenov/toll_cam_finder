part of segment_tracker;

/// Simple value object the tracker uses internally to report whether the latest
/// update triggered a start or end transition for the active segment.
class _SegmentTransition {
  const _SegmentTransition({this.started = false, this.ended = false});

  /// Whether a segment was entered.
  final bool started;

  /// Whether the active segment was exited.
  final bool ended;
}
