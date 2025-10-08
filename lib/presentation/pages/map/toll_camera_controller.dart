import 'package:flutter_map/flutter_map.dart';

import 'package:toll_cam_finder/presentation/widgets/toll_cameras_overlay.dart';
import 'package:toll_cam_finder/services/camera_utils.dart';


/// Keeps the toll-camera loading and filtering logic isolated from the widget.
class TollCameraController {
  TollCameraController({CameraUtils? utils})
      : _cameras = utils ?? CameraUtils(boundsPaddingDeg: 0.05);

  final CameraUtils _cameras;

  TollCamerasState get state => TollCamerasState(
        error: _cameras.error,
        isLoading: _cameras.isLoading,
        visibleCameras: _cameras.visibleCameras,
      );

  Future<void> loadFromAsset(
    String assetPath, {
    Set<String> excludedSegmentIds = const <String>{},
  }) async {
    await _cameras.loadFromAsset(
      assetPath,
      excludedSegmentIds: excludedSegmentIds,
    );
  }

  void updateVisible({LatLngBounds? bounds}) {
    _cameras.updateVisible(bounds: bounds);
  }

  double? nearestCameraDistanceMeters(LatLng point) {
    return _cameras.nearestCameraDistanceMeters(point);
  }
}
