class Tuning {
  final double horizAccBad;
  final double minDt, maxDt;
  final double drvExtraNoise;
  final double smallSpeed;
  final double stationaryDisp;
  final int    stationaryDebounceCount;
  final double zeroExit;
  final double stationaryExitInflate;
  final double devAccClampFloor;
  const Tuning({
    this.horizAccBad = 30.0,
    this.minDt = 0.12,
    this.maxDt = 2.5,
    this.drvExtraNoise = 0.20,
    this.smallSpeed = 0.3,
    this.stationaryDisp = 1.0,
    this.stationaryDebounceCount = 3,
    this.zeroExit = 0.90,
    this.stationaryExitInflate = 4.0,
    this.devAccClampFloor = 0.15,
  });
}

class Measurements {
  final double? devSpeed;    // Doppler
  final double? devSigma;    // Doppler σ (already clamped)
  final double? drvSpeed;    // Derived
  final double? drvSigma;    // Derived σ
  const Measurements({this.devSpeed, this.devSigma, this.drvSpeed, this.drvSigma});
}

class Displacement {
  final double meters;
  final double acc1, acc2; // accuracies used
  const Displacement(this.meters, this.acc1, this.acc2);
}
