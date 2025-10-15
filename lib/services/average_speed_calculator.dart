/// Provides utilities for computing average speed in km/h.
class AverageSpeedCalculator {
  const AverageSpeedCalculator();

  /// Calculates the average speed in km/h for the given [distanceMeters] and
  /// [elapsed] duration.
  ///
  /// Returns `0` when the input is not valid or the elapsed duration is zero
  /// (or negative).
  double calculateKph({
    required double distanceMeters,
    required Duration elapsed,
  }) {
    if (!distanceMeters.isFinite) {
      return 0.0;
    }

    if (elapsed <= Duration.zero) {
      return 0.0;
    }

    final double elapsedHours =
        elapsed.inMilliseconds /
            Duration.millisecondsPerSecond /
            Duration.secondsPerHour;
    if (elapsedHours <= 0) {
      return 0.0;
    }

    final double distanceKm = distanceMeters <= 0 ? 0.0 : distanceMeters / 1000.0;
    return distanceKm / elapsedHours;
  }
}
