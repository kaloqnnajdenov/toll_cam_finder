part of segment_tracker;

/// Holds the mutable bookkeeping for the segment that is currently
/// considered active by [SegmentTracker].
class _ActiveSegmentState {
  /// Creates a new state snapshot for the active segment. The caller provides
  /// the geometry and initial settings derived from the match that promoted the
  /// segment to the active state.
  _ActiveSegmentState({
    required this.geometry,
    required this.path,
    required this.forceKeepUntilEnd,
    required this.enteredAt,
  });

  /// Geometry metadata describing the underlying road segment.
  final SegmentGeometry geometry;

  /// Polyline currently used for proximity checks. This may be upgraded to a
  /// denser path when an enhanced route is fetched.
  List<GeoPoint> path;

  /// When `true` the tracker keeps the segment active until it is explicitly
  /// exited, even if interim matches are weak.
  bool forceKeepUntilEnd;

  /// Timestamp at which the segment became active, used by timeout heuristics.
  final DateTime enteredAt;

  /// Optional deadline until which the segment should be kept alive despite
  /// missing candidates. This is used when the tracker reloads while a segment
  /// is already active so temporary data unavailability does not trigger an
  /// exit.
  DateTime? keepAliveUntil;

  /// Number of consecutive update cycles in which the active segment failed to
  /// produce a satisfactory match.
  int consecutiveMisses = 0;

  /// Most recent positive match for the active segment. This is reused for
  /// debugging and to provide continuity when no fresh candidates are present.
  SegmentMatch? lastMatch;

  /// Extends the keep-alive deadline by the provided [duration]. When the
  /// segment already has a future deadline the later of the two is retained.
  void extendKeepAlive(Duration duration, {DateTime? now}) {
    final DateTime baseline = now ?? DateTime.now();
    final DateTime candidate = baseline.add(duration);
    final DateTime? existing = keepAliveUntil;
    if (existing == null || existing.isBefore(candidate)) {
      keepAliveUntil = candidate;
    }
  }

  /// Restores a previously persisted keep-alive deadline, dropping it if it
  /// already expired.
  void restoreKeepAlive(DateTime? until) {
    if (until == null) {
      keepAliveUntil = null;
      return;
    }
    if (until.isAfter(DateTime.now())) {
      keepAliveUntil = until;
    } else {
      keepAliveUntil = null;
    }
  }

  /// Clears the keep-alive deadline so normal miss handling resumes
  /// immediately.
  void clearKeepAlive() {
    keepAliveUntil = null;
  }

  /// Returns whether the keep-alive deadline is still in the future, clearing
  /// it automatically if the grace window elapsed.
  bool hasKeepAlive(DateTime now) {
    final DateTime? expiry = keepAliveUntil;
    if (expiry == null) {
      return false;
    }
    if (now.isBefore(expiry)) {
      return true;
    }
    keepAliveUntil = null;
    return false;
  }
}
