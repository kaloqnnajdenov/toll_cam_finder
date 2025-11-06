import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AppConstants {
  /// Minimum zoom allowed on the segment picker map; prevents zooming so far
  /// out that the draggable markers become impractically small.
  static const double segmentPickerMinZoom = 3.0;

  /// Maximum zoom allowed on the segment picker map; avoids extreme zoom-in
  /// levels where tiles may no longer be available.
  static const double segmentPickerMaxZoom = 19.0;

  /// Amount the map zoom changes when the user presses the zoom controls.
  static const double segmentPickerZoomStep = 1.0;

  /// Width of the polyline that previews the OSRM route between A and B.
  static const double segmentPickerPolylineWidth = 4.0;

  /// Diameter of the Flutter Map marker widget that hosts the draggable
  /// endpoint controls.
  static const double segmentPickerMarkerOuterDiameter = 44.0;

  /// Diameter of the circular marker decoration that renders the A/B label.
  static const double segmentPickerMarkerInnerDiameter = 36.0;

  /// Blur radius applied to the endpoint marker's drop shadow.
  static const double segmentPickerMarkerShadowBlurRadius = 6.0;

  /// Vertical offset (in logical pixels) of the endpoint marker's shadow.
  static const double segmentPickerMarkerShadowOffsetY = 4.0;

  /// Border radius used by the inline map preview container.
  static const double segmentPickerClipRadius = 16.0;

  /// Aspect ratio for the inline map preview, matching the original design.
  static const double segmentPickerInlineAspectRatio = 3 / 2;

  /// Gap between stacked zoom buttons in the bottom-right corner.
  static const double segmentPickerZoomButtonSpacing = 12.0;

  /// Standard inset applied to floating controls positioned on the map.
  static const double segmentPickerOverlayInset = 16.0;

  /// Inset applied to the hint card's right edge, leaving room for the
  /// fullscreen toggle.
  static const double segmentPickerHintRightInset = 72.0;

  /// Additional space reserved around the bounds when fitting the camera.
  static const double segmentPickerCameraPadding = 48.0;

  /// Opacity applied to floating surfaces rendered over the map.
  static const double segmentPickerSurfaceOpacity = 0.9;

  /// Elevation used by circular action buttons layered on top of the map.
  static const double segmentPickerControlElevation = 2.0;

  /// Horizontal padding inside the hint card displayed at the top of the map.
  static const double segmentPickerHintHorizontalPadding = 16.0;

  /// Vertical padding inside the hint card displayed at the top of the map.
  static const double segmentPickerHintVerticalPadding = 12.0;

  /// Corner radius applied to the hint card to match the rest of the UI.
  static const double segmentPickerHintCornerRadius = 12.0;

  /// Distance (in meters) under which two coordinates are considered equal for
  /// route refresh comparisons.
  static const double segmentPickerEqualityThresholdMeters = 0.5;

  /// Geographic center used before a GPS fix is available; shifting it moves the
  /// initial map focus to another country or region.
  static const LatLng initialCenter = LatLng(42.7339, 25.4858);

  /// Geographic bounds used to constrain the map camera so the user cannot zoom
  /// out beyond a Europe-sized view.
  static final LatLngBounds europeBounds = LatLngBounds(
    LatLng(34.0, -11.0),
    LatLng(72.0, 45.0),
  );

  /// Map zoom level applied at startup; increasing it starts the user closer to
  /// street level, while decreasing shows a broader overview.
  static const double initialZoom = 7.0;

  /// Target zoom when centering on the user's location; higher values zoom in
  /// more aggressively once location is known, lower values keep more context.
  static const double zoomWhenFocused = 16;

  /// Minimum duration (ms) for the blue-dot animation; reducing it makes
  /// transitions snappier but can look jittery, increasing it slows all moves.
  static const int minMs = 1;

  /// Maximum duration (ms) for the blue-dot animation; raising it lets the dot
  /// trail longer on sparse GPS data, lowering it forces quicker catch-ups.
  static const int maxMs = 2000;

  /// Fraction of the GPS sampling interval dedicated to animating between
  /// fixes; higher values keep the dot moving nearly until the next fix,
  /// whereas lower values leave idle gaps but react faster to new data.
  static const double fillRatio = 0.95;

  /// Distance jump that triggers an instant teleport of the blue dot; larger
  /// values favor smoothing even on big jumps, smaller ones snap to new fixes
  /// more often.
  static const double blueDotTeleportDistanceMeters = 800.0;

  /// Implied speed (m/s) that triggers teleporting; increasing it tolerates
  /// faster jumps before snapping, decreasing makes unrealistic spikes reset
  /// immediately.
  static const double blueDotTeleportSpeedMps = 70.0;

  /// Radius (meters) used to query nearby toll-road segments; expanding it
  /// yields more candidates at the cost of extra processing, shrinking risks
  /// missing relevant segments.
  ///
  /// The previous value of 3000 m pulled in a large chunk of the dataset on
  /// every GPS fix, which had a measurable CPU and battery cost. Dropping the
  /// radius keeps more of the work local to the driver's immediate vicinity
  /// while still leaving plenty of margin for GPS noise on fast roads.
  static const double candidateRadiusMeters = 1200;

  ///Acts as the half-life for the exponential smoothing that blends the previously
  ///displayed position with each new GPS fix. Shortening it makes the blue dot
  ///react quickly (less smoothing, more jitter); lengthening it keeps motion buttery
  /// smooth but lags further behind abrupt path changes.
  static const double smoothingHalfLifeMs = 400.0;

  /// Sets the distance scale that boosts the smoothing factor when the raw fix
  /// diverges sharply from the smoothed track. Lowering it means even modest
  /// discrepancies drive an aggressive snap toward the fresh fix; raising it
  /// requires a much larger separation before the interpolation accelerates,
  /// preserving smoothing longer.
  static const double catchUpDistanceMeters = 20.0;

  /// Asset path for the toll-road segments dataset (CSV format).
  static const String pathToTollSegments = 'assets/data/toll_segments.csv';

  /// Asset path for the weigh-station dataset (CSV format).
  static const String pathToWeighStations = 'assets/data/weigh_stations.csv';

  /// Asset path to the toll segments dataset. Camera markers are derived from
  /// the start and end points of each segment in this CSV file.
  static const String camerasAsset = pathToTollSegments;
  //TODO: mertge camera assets with pathtotollsegments????

  /// Asset used for the upcoming-segment cue played shortly before entering a
  /// monitored area.
  static const String upcomingSegmentSoundAsset = 'data/ding_sound.mp3';

  /// Voice prompt that announces an upcoming segment (Bulgarian locale).
  static const String approachingSegmentVoiceAsset =
      'data/approaching_segment.mp3';

  /// Voice prompt that confirms a segment entry (Bulgarian locale).
  static const String segmentEnteredVoiceAsset = 'data/entered_segment.mp3';

  /// Voice prompt that announces an upcoming segment end (Bulgarian locale).
  static const String segmentEndingSoonVoiceAsset =
      'data/segment_ends_in800.mp3';

  /// Voice prompt that confirms a segment exit (Bulgarian locale).
  static const String segmentEndedVoiceAsset = 'data/segment_ended.mp3';

  /// Voice prompt that announces an upcoming weigh control (Bulgarian locale).
  static const String approachingWeighControlVoiceAsset =
      'data/approaching_weigh_control.mp3';

  /// Voice prompt used when the current segment ends and another one starts
  /// immediately after it (Bulgarian locale).
  static const String segmentEndingWithNextVoiceAsset =
      'data/segment_ends_in800_than_a_another_one.mp3';

  /// Voice prompt played when the monitored average speed rises above the
  /// allowed limit (Bulgarian locale).
  static const String averageAboveAllowedVoiceAsset =
      'data/avg_above_allowed.mp3';

  /// Voice prompt played when the monitored average speed returns within the
  /// allowed limit (Bulgarian locale).
  static const String averageBackWithinAllowedVoiceAsset =
      'data/avg_bellow_allowed.mp3';

  /// Follow-up prompt played when announcing an upcoming segment end and the
  /// speed is above the allowed average (Bulgarian locale).
  static const String segmentSpeedAboveVoiceAsset =
      'data/avg_above_allowed.mp3';

  /// Follow-up prompt played when announcing an upcoming segment end and the
  /// speed is below the allowed average (Bulgarian locale).
  static const String segmentSpeedBelowVoiceAsset =
      'data/avg_bellow_allowed.mp3';


  /// The animation controller starts with, and falls back to, a 500 ms duration for
  /// each interpolation run. Increasing that duration makes movements appear slower
  /// and smoother, while decreasing it yields snappier—but potentially choppier—updates
  /// between GPS samples.
  static const int interpolationDurationMs = 500;

  /// Requested interval (ms) between GPS samples on Android; lowering it asks
  /// for more frequent updates (better responsiveness, more battery), raising
  /// it saves power but slows tracking.
  ///
  /// We previously sampled at 100 ms (10 Hz) which overwhelms devices when the
  /// UI also performs spatial lookups for each fix. Asking for 1 Hz updates
  /// keeps the dot responsive without the heavy energy footprint.
  static const int gpsSampleIntervalMs = 1000;

  /// Minimum distance (in meters) that the user must travel before another GPS
  /// update is emitted. A zero filter floods the app with fixes even when the
  /// user is stationary, which wastes battery and heats devices unnecessarily.
  static const int gpsDistanceFilterMeters = 5;

  /// Title displayed in the persistent notification that keeps location
  /// tracking alive while the app runs in the background.
  static const String backgroundNotificationTitle =
      'Toll Cam Finder is active';

  /// Message shown in the background tracking notification so users understand
  /// why the app remains alive while hidden.
  static const String backgroundNotificationText =
      'Monitoring nearby toll segments in the background.';

  /// User-visible channel name for the background tracking notification.
  static const String backgroundNotificationChannelName =
      'Toll Cam Finder tracking';

  /// Drawable resource name used as the notification icon for the background
  /// tracking foreground service.
  static const String backgroundNotificationIconName = 'ic_launcher';

  /// Resource type of the notification icon so Android can resolve it.
  static const String backgroundNotificationIconType = 'mipmap';

  /// HTTP user-agent package identifier sent to the tile server; replace with a
  /// real app id to stay within OpenStreetMap usage policy.
  static const String userAgentPackageName = 'com.example.toll_cam';

  /// HTTP user-agent package identifier sent to the tile server; replace with a
  /// real app id to stay within OpenStreetMap usage policy.
  static const String mapURL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';


  /// Maximum distance (meters) between the user and a candidate polyline for
  /// it to be considered a viable match. Values around 30–50 m work well; we
  /// bias slightly higher to accommodate GPS noise on fast roads.
  static const double segmentOnPathToleranceMeters = 45.0;

  /// Radius (meters) for the geofence anchored at a segment's start point.
  /// Crossing this bubble is a strong indicator the user has begun the toll
  /// segment even if the polyline match is still noisy.
  static const double segmentStartGeofenceRadiusMeters = 40.0;

  /// Radius (meters) for the geofence at the segment's end marker. When the
  /// user enters this bubble we treat the segment as complete.
  static const double segmentEndGeofenceRadiusMeters = 40.0;

  /// Default diameter (logical pixels) for the blue location dot rendered on
  /// the map. Adjust to enlarge or shrink the marker footprint.
  static const double blueDotMarkerSize = 40.0;

  /// Inner circle diameter for the blue location dot, representing the most
  /// precise area of the indicator.
  static const double blueDotMarkerInnerSize = 12.0;

  /// Opacity applied to the outer ring of the blue location dot; lowering the
  /// value yields a subtler halo while higher values make it more pronounced.
  static const double blueDotMarkerOuterOpacity = 0.25;

  /// Default horizontal offset (logical pixels) for the OpenStreetMap
  /// attribution label.
  static const double mapAttributionLeftInset = 6.0;

  /// Default vertical offset (logical pixels) for the OpenStreetMap
  /// attribution label before system insets are considered.
  static const double mapAttributionBottomInset = 6.0;

  /// Additional downward shift (logical pixels) applied to the attribution
  /// label, allowing it to overlap with bottom insets when desired.
  static const double mapAttributionOverlap = 10.0;

  /// Font size used for the OpenStreetMap attribution text.
  static const double mapAttributionFontSize = 11.0;

  /// Opacity applied to the base style of the OpenStreetMap attribution text.
  static const double mapAttributionBaseOpacity = 0.75;

  /// Line height used for the attribution text, keeping the single line snug.
  static const double mapAttributionLineHeight = 1.1;

  /// Default duration (milliseconds) for smooth number transitions.
  static const int smoothNumberTextAnimationMs = 240;

  /// Duration (milliseconds) of the icon flip animation on the average-speed
  /// floating action button.
  static const int avgSpeedButtonAnimationMs = 180;

  /// Shared card width (logical pixels) used by the speed dials so they align
  /// visually when stacked.
  static const double speedDialDefaultWidth = 160.0;

  /// Default number of fractional digits displayed on the speed dials.
  static const int speedDialDefaultDecimals = 1;

  /// Default radius (logical pixels) used for card corners within the speed
  /// dial widgets.
  static const double speedDialCardRadius = 16.0;

  /// Default padding (logical pixels) applied uniformly inside speed dial
  /// cards.
  static const double speedDialCardPadding = 14.0;

  /// Vertical spacing (logical pixels) between stacked speed dial widgets.
  static const double speedDialStackSpacing = 12.0;

  /// Gap (logical pixels) between the headline row and the numeric readout in
  /// the speed dial widgets.
  static const double speedDialHeaderGap = 10.0;

  /// Horizontal spacing (logical pixels) between the numeric value and its
  /// unit label inside the speed dials.
  static const double speedDialValueUnitSpacing = 6.0;

  /// Bottom padding (logical pixels) applied to the unit label so it aligns
  /// with the baseline of the numeric readout.
  static const double speedDialUnitBaselinePadding = 6.0;

  /// Horizontal margin (logical pixels) for the last-segment feedback banners
  /// shown beneath the speed dials.
  static const double speedDialBannerHorizontalPadding = 12.0;

  /// Vertical padding (logical pixels) for the last-segment feedback banners
  /// shown beneath the speed dials.
  static const double speedDialBannerVerticalPadding = 8.0;

  /// Corner radius (logical pixels) for the banner containers shown beneath the
  /// speed dials.
  static const double speedDialBannerRadius = 12.0;

  /// Horizontal padding (logical pixels) for the debug badge displayed in
  /// development builds beneath the speed dials.
  static const double speedDialDebugBadgeHorizontalPadding = 10.0;

  /// Vertical padding (logical pixels) for the debug badge displayed beneath
  /// the speed dials.
  static const double speedDialDebugBadgeVerticalPadding = 6.0;

  /// Corner radius (logical pixels) for the debug badge displayed beneath the
  /// speed dials.
  static const double speedDialDebugBadgeRadius = 8.0;

  /// Default rise time (seconds) used by [SpeedSmoother] to approach increasing
  /// speed readings.
  static const double speedSmootherRiseTimeSeconds = 1.2;

  /// Default fall time (seconds) used by [SpeedSmoother] to respond to
  /// decreasing speed readings.
  static const double speedSmootherFallTimeSeconds = 0.45;

  /// Threshold (km/h) below which the [SpeedSmoother] snaps directly to zero.
  static const double speedSmootherStopSnapKmh = 1.0;

  /// Timeout (milliseconds) after the last GPS update before the UI forces the
  /// current speed readout to zero.
  static const int speedIdleResetTimeoutMs = 4000;

  /// Default padding (degrees) applied to map bounds when filtering visible
  /// cameras.
  static const double cameraUtilsBoundsPaddingDeg = 0.05;

  /// Initial error estimate used by the 1-D coordinate Kalman filters.
  static const double locationFilterInitialErrorEstimate = 1.0;

  /// Initial value assigned to the last-estimate term in the coordinate filter.
  static const double locationFilterInitialEstimate = 0.0;

  /// Initial Kalman gain used by the coordinate filter.
  static const double locationFilterInitialKalmanGain = 0.0;

  /// Measurement noise (variance) assumed by the coordinate filter.
  static const double locationFilterMeasurementError = 0.1;

  /// Process noise (variance) assumed by the coordinate filter.
  static const double locationFilterProcessError = 0.01;
}
