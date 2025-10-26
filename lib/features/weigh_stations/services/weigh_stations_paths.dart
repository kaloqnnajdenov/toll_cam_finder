import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String kWeighStationsAssetPath = 'assets/data/weigh_stations.csv';
const String kWeighStationsFileName = 'weigh_stations.csv';
const String kWeighStationsMetadataSuffix = '_metadata.json';

typedef WeighStationsPathResolver = Future<String> Function();

Future<String> resolveWeighStationsDataPath({
  WeighStationsPathResolver? overrideResolver,
}) async {
  if (overrideResolver != null) {
    return overrideResolver();
  }

  if (kIsWeb) {
    return kWeighStationsAssetPath;
  }

  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, kWeighStationsFileName);
}

Future<String> resolveWeighStationsMetadataPath({
  WeighStationsPathResolver? overrideResolver,
}) async {
  final csvPath = await resolveWeighStationsDataPath(
    overrideResolver: overrideResolver,
  );
  return '$csvPath$kWeighStationsMetadataSuffix';
}
