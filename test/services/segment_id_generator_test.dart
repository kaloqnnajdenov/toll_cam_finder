import 'package:flutter_test/flutter_test.dart';
import 'package:toll_cam_finder/features/segments/services/segment_id_generator.dart';
import 'package:toll_cam_finder/features/segments/services/toll_segments_csv_constants.dart';

void main() {
  test('generateLocalId starts after the highest remote identifier', () {
    final id = SegmentIdGenerator.generateLocalId(
      existingLocalIds: const <String>[],
      remoteIds: const <String>['12', '7', '99'],
    );

    expect(id, '${TollSegmentsCsvSchema.localSegmentIdPrefix}100');
  });

  test('generateLocalId increments when local identifiers exist', () {
    final generated = <String>[];

    for (var i = 0; i < 3; i++) {
      final id = SegmentIdGenerator.generateLocalId(
        existingLocalIds: generated,
        remoteIds: const <String>['5'],
      );
      generated.add(id);
    }

    expect(generated, <String>[
      '${TollSegmentsCsvSchema.localSegmentIdPrefix}6',
      '${TollSegmentsCsvSchema.localSegmentIdPrefix}7',
      '${TollSegmentsCsvSchema.localSegmentIdPrefix}8',
    ]);
  });

  test('generateLocalId ignores non-numeric identifiers', () {
    final id = SegmentIdGenerator.generateLocalId(
      existingLocalIds: const <String>['${TollSegmentsCsvSchema.localSegmentIdPrefix}foo-123'],
      remoteIds: const <String>['abc', ''],
    );

    expect(id, '${TollSegmentsCsvSchema.localSegmentIdPrefix}1');
  });
}
