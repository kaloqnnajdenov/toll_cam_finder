import 'package:test/test.dart';

import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_data_store.dart';

void main() {
  group('WeighStationsDataStore.updateRemoteRows', () {
    final store = WeighStationsDataStore.instance;

    setUp(store.clear);

    test('keeps only the most recent row for each id', () {
      store.updateRemoteRows(const <List<String>>[
        <String>['1', 'Original', '', '1,1', '1', '0'],
        <String>['2', 'Second', '', '2,2', '0', '1'],
        <String>['1', 'Updated', '', '1,1', '2', '3'],
        <String>['', 'Without id', '', '3,3', '0', '0'],
      ]);

      final rows = store.remoteRows;

      expect(rows, isNotNull);
      expect(rows, hasLength(3));
      expect(
        rows!.singleWhere((row) => row.first == '1'),
        const <String>['1', 'Updated', '', '1,1', '2', '3'],
      );
      expect(
        rows.singleWhere((row) => row.first == '2'),
        const <String>['2', 'Second', '', '2,2', '0', '1'],
      );
      expect(
        rows.where((row) => row.first.isEmpty).toList(),
        equals([
          const <String>['', 'Without id', '', '3,3', '0', '0'],
        ]),
      );
    });
  });
}
