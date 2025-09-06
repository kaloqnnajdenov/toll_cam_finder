import 'dart:math' as math;
class KF {
  KF({
    required this.sigmaJerk, required this.fading,
    required this.pFloorV, required this.pFloorA, required this.maxSpeed,
  });
  final double sigmaJerk, fading, pFloorV, pFloorA, maxSpeed;
  bool initialized = false;
  double v = 0.0, a = 0.0;
  double p00 = 10.0, p01 = 0.0, p10 = 0.0, p11 = 10.0;

  void init(double v0, double r0) {
    v = v0.clamp(0.0, maxSpeed); a = 0.0;
    p00 = math.max(r0, pFloorV); p11 = math.max(4.0, pFloorA);
    p01 = 0.0; p10 = 0.0; initialized = true;
  }

  void predict(double dt) {
    if (!initialized) return;
    v = (v + a * dt).clamp(0.0, maxSpeed);
    final p00n = p00 + dt * (p01 + p10) + dt * dt * p11;
    final p01n = p01 + dt * p11;
    final p10n = p10 + dt * p11;
    final p11n = p11;
    final q = sigmaJerk * sigmaJerk, dt2 = dt * dt;
    final q00 = q * (dt * dt2) / 3.0, q01 = q * (dt2) / 2.0, q11 = q * dt;
    p00 = (p00n + q00) * fading;
    p01 = (p01n + q01) * fading;
    p10 = (p10n + q01) * fading;
    p11 = (p11n + q11) * fading;
    p00 = math.max(p00, pFloorV); p11 = math.max(p11, pFloorA);
  }

  void inflate(double f) {
    if (!initialized) return; final x = (f.isFinite && f >= 1.0) ? f : 1.0;
    p00*=x; p01*=x; p10*=x; p11*=x;
    p00 = math.max(p00, pFloorV); p11 = math.max(p11, pFloorA);
  }

  void updateRobust(double z, double r, {double gateSoft = 3.0, double gateHard = 8.0}) {
    if (!initialized) return;
    final s = p00 + r, sigma = math.sqrt(math.max(s, 1e-12)), y = z - v, ay = y.abs();
    if (ay > gateHard * sigma) return;
    if (ay > gateSoft * sigma) inflate(2.5);
    final k0 = p00 / s, k1 = p10 / s;
    v = (v + k0 * y).clamp(0.0, maxSpeed); a = a + k1 * y;
    final t00 = (1.0 - k0) * p00, t01 = (1.0 - k0) * p01, t10 = p10 - k1 * p00, t11 = p11 - k1 * p01;
    final p00n = t00 * (1.0 - k0) + (k0 * k0) * r;
    final p01n = -t00 * k1 + t01 + (k0 * k1) * r;
    final p10n = t10 * (1.0 - k0) + (k1 * k0) * r;
    final p11n = -t10 * k1 + t11 + (k1 * k1) * r;
    p00 = p00n; p01 = p01n; p10 = p10n; p11 = p11n;
    final avg = 0.5 * (p01 + p10); p01 = avg; p10 = avg;
    p00 = math.max(p00, pFloorV); p11 = math.max(p11, pFloorA);
  }
}
