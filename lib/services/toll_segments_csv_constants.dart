/// Canonical header for the toll segments CSV files used across the app.
///
/// The order of these columns matches the schema produced by the Supabase
/// export and expected by the sync service.
class TollSegmentsCsvSchema {
  const TollSegmentsCsvSchema._();

  /// List of column headers in the order they should appear in the CSV.
  static const List<String> header = <String>[
    'ID',
    'name',
    'road',
    'Start name',
    'End name',
    'Start',
    'End',
  ];

  /// Legacy header used before the dedicated `name` column was introduced.
  static const List<String> legacyHeader = <String>[
    'ID',
    'road',
    'Start name',
    'End name',
    'Start',
    'End',
  ];

  /// Prefix applied to identifiers of user-created segments that only exist on
  /// the local device. These rows must be preserved during cloud synchronisation
  /// to avoid losing user data.
  static const String localSegmentIdPrefix = 'LOCAL:';
}
