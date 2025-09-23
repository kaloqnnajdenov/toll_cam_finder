part of segment_tracker;

const int _headingHistoryMaxSamples = 6;
const double _headingHistoryMinDistanceMeters = 5.0;
const double _headingHistoryMinSpanMeters =
    _headingHistoryMinDistanceMeters * 2;
const double _headingHistoryMaxGapMeters = 200.0;
const double _headingBlendMinSpeedKmh = 2.0;
const double _headingBlendMaxSpeedKmh = 12.0;
const double _headingSmoothingFactor = 0.25;
const double _headingSmoothingEpsilonDeg = 0.2;
const double _headingLargeChangeThresholdDeg = 60.0;

/// Heading related utilities for [SegmentTracker].
extension _SegmentTrackerHeading on SegmentTracker {
  /// Picks the best heading estimate for the tracker by fusing compass readings
  /// with course-over-ground bearings derived from recent positions. Compass
  /// data stabilises low-speed behaviour while the positional history keeps the
  /// heading aligned with the vehicle path.
  double? _resolveHeading(
    LatLng current,
    LatLng? previous,
    double? rawHeading,
    double? speedKmh,
    double? compassHeading,
  ) {
    final double speed =
        speedKmh != null && speedKmh.isFinite ? speedKmh : 0.0;
    final double? normalizedCompass = _normalizeHeading(compassHeading);
    if (normalizedCompass != null) {
      _lastCompassHeadingDeg = normalizedCompass;
    }

    final bool speedOk = speedKmh == null || speed >= directionMinSpeedKmh;
    final double? normalizedCourse =
        speedOk ? _normalizeHeading(rawHeading) : null;

    final GeoPoint currentPoint = GeoPoint(current.latitude, current.longitude);
    if (previous == null) {
      _headingHistory
        ..clear()
        ..add(currentPoint);
      _smoothedHeadingDeg = null;
    } else {
      _addHeadingSample(currentPoint);
    }

    final double? historyHeading = _deriveHeadingFromHistory();
    double? fallbackHeading;
    if (previous != null) {
      final GeoPoint previousPoint =
          GeoPoint(previous.latitude, previous.longitude);
      final double distance = _distanceBetween(previousPoint, currentPoint);
      if (distance >= _headingHistoryMinDistanceMeters) {
        fallbackHeading = _bearingBetween(previous, current);
      }
    }

    double? courseHeading;
    if (normalizedCourse != null) {
      courseHeading = normalizedCourse;
      if (historyHeading != null) {
        courseHeading =
            _interpolateHeadings(historyHeading, normalizedCourse, 0.5);
      }
    } else if (historyHeading != null) {
      courseHeading = historyHeading;
    } else {
      courseHeading = fallbackHeading;
    }

    final double? compassForFusion =
        normalizedCompass ?? _lastCompassHeadingDeg;

    double? fusedHeading = _fuseCompassAndCourse(
      compass: compassForFusion,
      course: courseHeading,
      speedKmh: speed,
    );

    fusedHeading ??= courseHeading ?? compassForFusion;

    if (fusedHeading == null) {
      return normalizedCompass ?? normalizedCourse ?? fallbackHeading;
    }

    return _smoothResolvedHeading(fusedHeading);
  }

  double? _fuseCompassAndCourse({
    double? compass,
    double? course,
    required double speedKmh,
  }) {
    if (course == null) return compass;
    if (compass == null) return course;

    double weight = _courseBlendWeight(speedKmh);
    if (weight <= 0.0) return compass;
    if (weight >= 1.0) return course;

    final double delta = _headingDelta(compass, course).abs();
    if (delta > 90.0) {
      final double severity = ((delta - 90.0).clamp(0.0, 90.0)) / 90.0;
      weight *= 1 - 0.5 * severity;
    }

    if (weight <= 0.0) return compass;
    if (weight >= 1.0) return course;

    return _interpolateHeadings(compass, course, weight);
  }

  double _courseBlendWeight(double speedKmh) {
    if (!speedKmh.isFinite) return 0.0;
    if (speedKmh <= _headingBlendMinSpeedKmh) return 0.0;
    if (speedKmh >= _headingBlendMaxSpeedKmh) return 1.0;
    return (speedKmh - _headingBlendMinSpeedKmh) /
        (_headingBlendMaxSpeedKmh - _headingBlendMinSpeedKmh);
  }

  void _addHeadingSample(GeoPoint sample) {
    final history = _headingHistory;
    if (history.isEmpty) {
      history.add(sample);
      return;
    }

    final GeoPoint last = history.last;
    final double distance = _distanceBetween(last, sample);

    if (distance > _headingHistoryMaxGapMeters) {
      history
        ..clear()
        ..add(sample);
      _smoothedHeadingDeg = null;
      return;
    }

    if (distance < _headingHistoryMinDistanceMeters) {
      if (history.length == 1) {
        history.add(sample);
      } else {
        history[history.length - 1] = sample;
      }
      return;
    }

    history.add(sample);
    if (history.length > _headingHistoryMaxSamples) {
      history.removeAt(0);
    }
  }

  double? _deriveHeadingFromHistory() {
    final history = _headingHistory;
    if (history.length < 2) return null;

    double totalX = 0.0;
    double totalY = 0.0;
    double totalDistance = 0.0;

    for (var i = 0; i < history.length - 1; i++) {
      final GeoPoint start = history[i];
      final GeoPoint end = history[i + 1];
      final double segmentDistance = _distanceBetween(start, end);
      if (segmentDistance < _headingHistoryMinDistanceMeters) {
        continue;
      }

      final double bearingDeg = _bearingBetween(
        LatLng(start.lat, start.lon),
        LatLng(end.lat, end.lon),
      );
      final double bearingRad = bearingDeg * math.pi / 180.0;
      totalX += math.cos(bearingRad) * segmentDistance;
      totalY += math.sin(bearingRad) * segmentDistance;
      totalDistance += segmentDistance;
    }

    if (totalDistance < _headingHistoryMinSpanMeters) {
      final GeoPoint first = history.first;
      final GeoPoint last = history.last;
      final double span = _distanceBetween(first, last);
      if (span < _headingHistoryMinSpanMeters) {
        return null;
      }
      final double bearing = _bearingBetween(
        LatLng(first.lat, first.lon),
        LatLng(last.lat, last.lon),
      );
      return _normalizeHeading(bearing);
    }

    final double averagedRad = math.atan2(totalY, totalX);
    final double averagedDeg = averagedRad * 180.0 / math.pi;
    return _normalizeHeading(averagedDeg);
  }

  double _smoothResolvedHeading(double headingDeg) {
    final double? normalized = _normalizeHeading(headingDeg);
    if (normalized == null) {
      return _smoothedHeadingDeg ?? headingDeg;
    }

    final double? previous = _smoothedHeadingDeg;
    if (previous == null) {
      _smoothedHeadingDeg = normalized;
      return normalized;
    }

    final double delta = _headingDelta(previous, normalized);
    final double absDelta = delta.abs();
    if (absDelta <= _headingSmoothingEpsilonDeg ||
        absDelta >= _headingLargeChangeThresholdDeg) {
      _smoothedHeadingDeg = normalized;
      return normalized;
    }

    final double smoothed = previous + delta * _headingSmoothingFactor;
    final double? normalizedSmoothed = _normalizeHeading(smoothed);
    if (normalizedSmoothed == null) {
      _smoothedHeadingDeg = normalized;
      return normalized;
    }

    _smoothedHeadingDeg = normalizedSmoothed;
    return normalizedSmoothed;
  }

  double _interpolateHeadings(double fromDeg, double toDeg, double t) {
    final double clampedT = t < 0.0
        ? 0.0
        : (t > 1.0
            ? 1.0
            : t);
    final double? fromNorm = _normalizeHeading(fromDeg);
    final double? toNorm = _normalizeHeading(toDeg);
    if (fromNorm == null || toNorm == null) {
      return toDeg;
    }

    final double delta = _headingDelta(fromNorm, toNorm);
    final double interpolated = fromNorm + delta * clampedT;
    return _normalizeHeading(interpolated) ?? interpolated;
  }

  double _headingDelta(double fromDeg, double toDeg) {
    final double? fromNorm = _normalizeHeading(fromDeg);
    final double? toNorm = _normalizeHeading(toDeg);
    if (fromNorm == null || toNorm == null) {
      return 0.0;
    }

    return ((toNorm - fromNorm + 540.0) % 360.0) - 180.0;
  }

  /// Normalises [heading] to the [0, 360) range and discards invalid values.
  double? _normalizeHeading(double? heading) {
    if (heading == null || !heading.isFinite) return null;
    double value = heading % 360.0;
    if (value < 0) value += 360.0;
    return value;
  }
}
