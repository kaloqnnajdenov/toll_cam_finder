import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station.dart';

import 'weigh_stations_csv_constants.dart';
import 'weigh_stations_data_store.dart';
import 'weigh_stations_file_system.dart';
import 'weigh_stations_file_system_stub.dart'
    if (dart.library.io) 'weigh_stations_file_system_io.dart' as fs_impl;
import 'weigh_stations_paths.dart';

class WeighStationsRepository {
  WeighStationsRepository({
    WeighStationsFileSystem? fileSystem,
    WeighStationsPathResolver? pathResolver,
  })  : _fileSystem = fileSystem ?? fs_impl.createFileSystem(),
        _pathResolver = pathResolver;

  final WeighStationsFileSystem _fileSystem;
  final WeighStationsPathResolver? _pathResolver;

  Future<List<WeighStationInfo>> loadStations({
    String assetPath = kWeighStationsAssetPath,
  }) async {
    final raw = await _loadStationsData(assetPath);
    final rows = const CsvToListConverter(fieldDelimiter: ';').convert(raw);
    if (rows.isEmpty) {
      return const [];
    }

    final header = rows.first
        .map((cell) => '$cell'.trim().toLowerCase())
        .toList();
    final idIndex = header.indexOf('id');
    final nameIndex = header.indexOf('name');
    final roadIndex = header.indexOf('road');
    final coordIndex = header.indexOf('coordinates');
    final stations = <WeighStationInfo>[];

    for (final row in rows.skip(1)) {
      if (row.length <= idIndex || row.length <= coordIndex) {
        continue;
      }
      final id = _stringAt(row, idIndex);
      final name = _stringAt(row, nameIndex);
      final road = _stringAt(row, roadIndex);
      final coordinates = _stringAt(row, coordIndex);
      if (id.isEmpty && coordinates.isEmpty) {
        continue;
      }

      final isLocalOnly = id.startsWith(
        WeighStationsCsvSchema.localWeighStationIdPrefix,
      );

      stations.add(
        WeighStationInfo(
          id: id,
          name: name,
          road: road,
          coordinates: coordinates,
          isLocalOnly: isLocalOnly,
        ),
      );
    }

    stations.sort((a, b) {
      final idComparison = a.displayId.compareTo(b.displayId);
      if (idComparison != 0) {
        return idComparison;
      }
      final nameComparison = a.name.compareTo(b.name);
      if (nameComparison != 0) {
        return nameComparison;
      }
      return a.coordinates.compareTo(b.coordinates);
    });

    return stations;
  }

  Future<String> _loadStationsData(String assetPath) async {
    if (assetPath == kWeighStationsAssetPath) {
      return WeighStationsDataStore.instance.loadCombinedCsv(
        fileSystem: _fileSystem,
        assetPath: assetPath,
        pathResolver: _pathResolver,
      );
    }

    return rootBundle.loadString(assetPath);
  }

  String _stringAt(List<dynamic> row, int index) {
    if (index < 0 || index >= row.length) {
      return '';
    }
    return '${row[index]}'.trim();
  }
}
