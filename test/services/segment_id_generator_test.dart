import 'package:flutter_test/flutter_test.dart';
import 'package:toll_cam_finder/services/segment_id_generator.dart';
import 'package:toll_cam_finder/services/toll_segments_csv_constants.dart';

void main() {
  test('generateLocalId returns unique values with expected prefix', () {
    final prefix = TollSegmentsCsvSchema.localSegmentIdPrefix;
    final generated = <String>{};

    for (var i = 0; i < 500; i++) {
      final id = SegmentIdGenerator.generateLocalId();
      expect(id.startsWith(prefix), isTrue, reason: 'Local ID should start with prefix.');
      expect(generated.add(id), isTrue, reason: 'Local IDs must be unique.');
    }
  });
}
