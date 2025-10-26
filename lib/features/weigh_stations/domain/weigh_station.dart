import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_csv_constants.dart';

class WeighStationInfo {
  const WeighStationInfo({
    required this.id,
    required this.name,
    required this.road,
    required this.coordinates,
    this.isLocalOnly = false,
  });

  final String id;
  final String name;
  final String road;
  final String coordinates;
  final bool isLocalOnly;

  String get displayId {
    if (!isLocalOnly) {
      return id;
    }
    if (id.startsWith(WeighStationsCsvSchema.localWeighStationIdPrefix)) {
      return id.substring(WeighStationsCsvSchema.localWeighStationIdPrefix.length);
    }
    return id;
  }
}
