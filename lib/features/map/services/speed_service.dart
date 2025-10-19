class SpeedService {
  const SpeedService({double speedDeadbandKmh = 1.0})
      : _speedDeadbandKmh = speedDeadbandKmh;

  final double _speedDeadbandKmh;

  double normalizeSpeed(double metersPerSecond) {
    if (!metersPerSecond.isFinite || metersPerSecond < 0) return 0.0;
    final double kmh = metersPerSecond * 3.6;
    return kmh < _speedDeadbandKmh ? 0.0 : kmh;
  }
}
