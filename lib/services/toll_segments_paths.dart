import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Default asset path for the bundled toll segments CSV file.
const String kTollSegmentsAssetPath = 'assets/data/toll_segments.csv';

/// Default file name used when storing the synced toll segments data on disk.
const String kTollSegmentsFileName = 'toll_segments.csv';

/// Default file name used to persist metadata about locally created segments.
const String kTollSegmentsMetadataFileName = 'toll_segments_public.json';

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

/// Resolves the absolute path where metadata for locally created segments
/// should be stored. The metadata file lives alongside the CSV that stores the
/// segment records.
Future<String> resolveTollSegmentsMetadataPath({
  TollSegmentsPathResolver? overrideResolver,
}) async {
  final csvPath = await resolveTollSegmentsDataPath(
    overrideResolver: overrideResolver,
  );

  if (kIsWeb) {
    // Web builds cannot persist to disk. A synthetic asset-like path is
    // returned for consistency, even though it will not be used.
    return p.setExtension(csvPath, '.public.json');
  }

  final directory = p.dirname(csvPath);
  return p.join(directory, kTollSegmentsMetadataFileName);
}
