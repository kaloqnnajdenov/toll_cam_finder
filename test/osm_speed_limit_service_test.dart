import 'package:test/test.dart';
import 'package:toll_cam_finder/services/map/osm_speed_limit_service.dart';

void main() {
  group('OsmSpeedLimitService.resolveFromTags', () {
    test('returns km/h value when maxspeed tag is numeric', () {
      final double? result = OsmSpeedLimitService.resolveFromTags({
        'maxspeed': '50',
      });

      expect(result, 50);
    });

    test('converts mph to km/h', () {
      final double? result = OsmSpeedLimitService.resolveFromTags({
        'maxspeed': '30 mph',
      });

      expect(result, closeTo(48.2802, 0.0001));
    });

    test('returns null when no numeric maxspeed tag exists', () {
      final double? result = OsmSpeedLimitService.resolveFromTags({
        'maxspeed': 'signals',
        'maxspeed:type': 'signals',
      });

      expect(result, isNull);
    });

    test('checks directional tags when primary maxspeed missing', () {
      final double? result = OsmSpeedLimitService.resolveFromTags({
        'maxspeed:forward': '80',
      });

      expect(result, 80);
    });
  });
}
