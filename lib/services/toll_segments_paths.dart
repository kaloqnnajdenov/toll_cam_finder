import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Default asset path for the bundled toll segments CSV file.
const String kTollSegmentsAssetPath = 'assets/data/toll_segments.csv';

/// Default file name used when storing the synced toll segments data on disk.
const String kTollSegmentsFileName = 'toll_segments.csv';

/// Suffix appended to the toll segments CSV path to store local metadata.
const String kTollSegmentsMetadataSuffix = '_metadata.json';

/// Suffix appended to the toll segments CSV path to store cached segment paths
/// as GeoJSON.
const String kSegmentPathsSuffix = '_paths.geojson';

/// Function signature for providing a custom on-disk location for the synced
/// toll segments CSV. Useful for tests.
typedef TollSegmentsPathResolver = Future<String> Function();

/// Resolves the absolute path where the synced toll segments CSV should be
/// stored.
///
/// The default implementation stores the CSV in the platform-specific
/// application support directory. A custom [overrideResolver] can be supplied
/// for tests or alternative storage strategies.
Future<String> resolveTollSegmentsDataPath({
  TollSegmentsPathResolver? overrideResolver,
}) async {
  if (overrideResolver != null) {
    return overrideResolver();
  }

  if (kIsWeb) {
    // Web builds cannot persist to disk; the asset path is returned instead so
    // callers can continue to operate against the bundled data.
    return kTollSegmentsAssetPath;
  }

  final directory = await getApplicationSupportDirectory();
  return p.join(directory.path, kTollSegmentsFileName);
}

/// Resolves the path where metadata related to the toll segments CSV should be
/// stored.
Future<String> resolveTollSegmentsMetadataPath({
  TollSegmentsPathResolver? overrideResolver,
}) async {
  final csvPath = await resolveTollSegmentsDataPath(
    overrideResolver: overrideResolver,
  );
  return '$csvPath$kTollSegmentsMetadataSuffix';
}

/// Resolves the path where cached segment path GeoJSON data should be stored.
Future<String> resolveSegmentPathsCachePath({
  TollSegmentsPathResolver? overrideResolver,
}) async {
  final csvPath = await resolveTollSegmentsDataPath(
    overrideResolver: overrideResolver,
  );
  return '$csvPath$kSegmentPathsSuffix';
}

