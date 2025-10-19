class CameraPollingService {
  const CameraPollingService();

  Duration delayForDistance(double? distanceMeters) {
    // TODO: Restore smarter heuristics when telemetry is available.
    return Duration.zero;
  }
}
