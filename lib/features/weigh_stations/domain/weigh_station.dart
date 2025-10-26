import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_csv_constants.dart';

class WeighStationInfo {
  const WeighStationInfo({
    required this.id,
    required this.coordinates,
    this.name = '',
    this.road = '',
    this.upvotes = 0,
    this.downvotes = 0,
    this.isLocalOnly = false,
  });

  final String id;
  final String coordinates;
  final String name;
  final String road;
  final int upvotes;
  final int downvotes;
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
