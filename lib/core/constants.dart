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
  static const double candidateRadiusMeters = 3000;

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

/// Asset path to the toll segments dataset. Camera markers are derived from
  /// the start and end points of each segment in this CSV file.
  static const String camerasAsset = pathToTollSegments;
  //TODO: mertge camera assets with pathtotollsegments????



  /// The animation controller starts with, and falls back to, a 500 ms duration for
  /// each interpolation run. Increasing that duration makes movements appear slower
  /// and smoother, while decreasing it yields snappier—but potentially choppier—updates
  /// between GPS samples.
  static const int interpolationDurationMs = 500;

  /// Requested interval (ms) between GPS samples on Android; lowering it asks
  /// for more frequent updates (better responsiveness, more battery), raising
  /// it saves power but slows tracking.
  static const int gpsSampleIntervalMs = 100;

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

  /// Heading difference (degrees) permitted between the user's travel heading
  /// and the local bearing of the matched polyline when direction checks are
  /// enforced.
  static const double segmentDirectionToleranceDegrees = 75.0;

  /// Minimum speed (km/h) before we trust the heading sensor enough to enforce
  /// direction checks. Below this, heading readings are typically unstable.
  static const double segmentDirectionMinSpeedKmh = 5.0;

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

  /// Default padding (degrees) applied to map bounds when filtering visible
  /// cameras.
  static const double cameraUtilsBoundsPaddingDeg = 0.05;

  /// Process-noise spectral density (m/s³) used by the speed Kalman filter to
  /// balance responsiveness with stability.
  static const double speedEstimatorSigmaJerk = 3.0;

  /// Covariance fading factor (>1) applied on each predict step of the speed
  /// Kalman filter to provide gentle forgetting.
  static const double speedEstimatorFadingFactor = 1.15;

  /// Minimum variance allowed for the velocity state in the speed Kalman
  /// filter.
  static const double speedEstimatorVelocityVarianceFloor = 0.10;

  /// Minimum variance allowed for the acceleration state in the speed Kalman
  /// filter.
  static const double speedEstimatorAccelerationVarianceFloor = 0.25;

  /// Initial variance assigned to the acceleration state when seeding the
  /// speed Kalman filter.
  static const double speedEstimatorInitialAccelerationVariance = 4.0;

  /// Maximum speed (m/s) permitted by the speed Kalman filter, preventing
  /// unrealistic spikes.
  static const double speedEstimatorMaxSpeed = 80.0;

  /// Horizontal accuracy (meters) above which derived-speed measurements are
  /// ignored due to poor quality.
  static const double speedEstimatorHorizAccBadMeters = 30.0;

  /// Minimum delta-time (seconds) accepted when computing derived speed from
  /// consecutive fixes.
  static const double speedEstimatorMinDtSeconds = 0.12;

  /// Maximum delta-time (seconds) clamped when computing derived speed from
  /// consecutive fixes.
  static const double speedEstimatorMaxDtSeconds = 2.5;

  /// Maximum displacement (meters) considered "stationary" for the speed
  /// estimator's zero-lock detection.
  static const double speedEstimatorStationaryDispMeters = 1.0;

  /// Number of consecutive stationary detections required before engaging
  /// zero-lock behavior in the speed estimator.
  static const int speedEstimatorStationaryDebounceCount = 3;

  /// Threshold (m/s) under which speeds are treated as effectively zero for the
  /// purpose of stationarity checks.
  static const double speedEstimatorSmallSpeedMps = 0.3;

  /// Inflation factor applied to the covariance matrix when leaving the
  /// stationary state so the filter reacts quickly to new motion.
  static const double speedEstimatorStationaryExitInflate = 4.0;

  /// Minimum Doppler speed accuracy (m/s) accepted by the speed estimator; raw
  /// values below this floor are clamped up.
  static const double speedEstimatorDevAccClampFloor = 0.15;

  /// Additional noise (m/s) added in quadrature to derived-speed measurements
  /// to compensate for curvature and discretization.
  static const double speedEstimatorDrvExtraNoise = 0.20;

  /// Exit threshold (m/s) for the zero-lock hysteresis in the speed estimator.
  static const double speedEstimatorZeroExitSpeedMps = 0.90;

  /// Fallback horizontal accuracy (meters) used when the raw reading is absent
  /// or invalid.
  static const double speedEstimatorAccuracyFallbackMeters = 999.0;

  /// Default measurement variance (m/s)² used by the soft stationary update in
  /// the speed estimator.
  static const double speedEstimatorStationaryVariance = 0.12 * 0.12;

  /// Covariance inflation factor applied during each stationary tick to keep
  /// the filter responsive once movement resumes.
  static const double speedEstimatorStationaryInflateFactor = 1.3;

  /// Short delta-time threshold (seconds) that triggers additional inflation of
  /// derived-speed measurement variance.
  static const double speedEstimatorShortDtSeconds = 0.25;

  /// Maximum inflation factor applied when correcting for short delta-times in
  /// derived-speed variance.
  static const double speedEstimatorShortDtInflateMax = 4.0;

  /// Minimum inflation factor applied when correcting for short delta-times in
  /// derived-speed variance.
  static const double speedEstimatorShortDtInflateMin = 1.0;

  /// Initial measurement variance (m/s)² assumed when seeding the speed Kalman
  /// filter.
  static const double speedEstimatorInitialMeasurementVariance = 25.0;

  /// Soft gating threshold (σ multiplier) used before inflating covariance in
  /// the robust speed update.
  static const double speedEstimatorGateSoftSigma = 3.0;

  /// Hard gating threshold (σ multiplier) beyond which Doppler measurements are
  /// rejected entirely.
  static const double speedEstimatorGateHardSigma = 8.0;

  /// Covariance inflation factor used when accepting a surprising high
  /// measurement during robust updates.
  static const double speedEstimatorPositiveSurpriseInflate = 2.5;

  /// Covariance inflation factor used when accepting a surprising low
  /// measurement during robust updates.
  static const double speedEstimatorNegativeSurpriseInflate = 1.8;

  /// Minimum innovation variance enforced when computing Kalman gains to avoid
  /// division by zero.
  static const double speedEstimatorInnovationVarianceFloor = 1e-12;

  /// Initial diagonal values used for the covariance matrix before the filter
  /// receives its first measurement.
  static const double speedEstimatorInitialCovariance = 10.0;

  /// Minimum allowed covariance inflation factor.
  static const double speedEstimatorInflateFloor = 1.0;

  /// Minimum variance allowed by the helper that bounds measurement variance.
  static const double speedEstimatorMinVariance = 0.25 * 0.25;

  /// Maximum variance allowed by the helper that bounds measurement variance.
  static const double speedEstimatorMaxVariance = 400.0;

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
