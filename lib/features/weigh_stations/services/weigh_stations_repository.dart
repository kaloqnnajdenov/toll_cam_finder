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
    final coordIndex = header.indexOf('coordinates');
    final nameIndex = header.indexOf('name');
    final roadIndex = header.indexOf('road');
    final upvotesIndex = header.indexOf('upvotes');
    final downvotesIndex = header.indexOf('downvotes');
    final stations = <WeighStationInfo>[];

    for (final row in rows.skip(1)) {
      if (row.length <= idIndex || row.length <= coordIndex) {
        continue;
      }
      final id = _stringAt(row, idIndex);
      final coordinates = _stringAt(row, coordIndex);
      final name = _stringAt(row, nameIndex);
      final road = _stringAt(row, roadIndex);
      final upvotes = _intAt(row, upvotesIndex);
      final downvotes = _intAt(row, downvotesIndex);
      if (id.isEmpty && coordinates.isEmpty) {
        continue;
      }

      final isLocalOnly = id.startsWith(
        WeighStationsCsvSchema.localWeighStationIdPrefix,
      );

      stations.add(
        WeighStationInfo(
          id: id,
          coordinates: coordinates,
          name: name,
          road: road,
          upvotes: upvotes,
          downvotes: downvotes,
          isLocalOnly: isLocalOnly,
        ),
      );
    }

    stations.sort((a, b) {
      final idComparison = a.displayId.compareTo(b.displayId);
      if (idComparison != 0) {
        return idComparison;
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

  int _intAt(List<dynamic> row, int index) {
    final raw = _stringAt(row, index);
    if (raw.isEmpty) {
      return 0;
    }
    return int.tryParse(raw) ?? 0;
  }
}
