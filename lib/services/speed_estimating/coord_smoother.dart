// coord_smoother.dart
class CoordSmoother {
  final _KF1D _lat = _KF1D();
  final _KF1D _lng = _KF1D();
  (double latSm, double lngSm) smooth(double lat, double lng) =>
      (_lat.filter(lat), _lng.filter(lng));
}

class _KF1D {
  double _P = 1.0, _x = 0.0;
  final double _Q = 0.01, _R = 0.1;
  bool _init = false;
  double filter(double z) {
    if (!_init) { _init = true; _x = z; return z; }
    // predict
    _P += _Q;
    // update
    final K = _P / (_P + _R);
    _x = _x + K * (z - _x);
    _P = (1.0 - K) * _P;
    return _x;
  }
}
