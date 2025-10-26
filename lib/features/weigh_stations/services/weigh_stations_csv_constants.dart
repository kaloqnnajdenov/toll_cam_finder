class WeighStationsCsvSchema {
  const WeighStationsCsvSchema._();

  static const String columnId = 'ID';
  static const String columnName = 'name';
  static const String columnRoad = 'road';
  static const String columnCoordinates = 'coordinates';
  static const String columnUpvotes = 'upvotes';
  static const String columnDownvotes = 'downvotes';

  static const List<String> header = <String>[
    columnId,
    columnName,
    columnRoad,
    columnCoordinates,
    columnUpvotes,
    columnDownvotes,
  ];

  static const String localWeighStationIdPrefix = 'LOCAL_WS:';
}
