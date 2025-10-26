class WeighStationsCsvSchema {
  const WeighStationsCsvSchema._();

  static const List<String> header = <String>[
    'ID',
    'name',
    'road',
    'coordinates',
  ];

  static const String localWeighStationIdPrefix = 'LOCAL_WS:';
}
