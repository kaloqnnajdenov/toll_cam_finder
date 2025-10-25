import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/average_speed_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/widgets/map_controls/map_controls_panel_card.dart';

class SegmentsOnlyPage extends StatelessWidget {
  const SegmentsOnlyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final segmentsController = context.watch<SegmentsOnlyModeController>();
    final avgController = context.watch<AverageSpeedController>();

    final reason = segmentsController.reason ?? SegmentsOnlyModeReason.manual;
    final String message;
    switch (reason) {
      case SegmentsOnlyModeReason.manual:
        message = localizations.segmentsOnlyModeManualMessage;
        break;
      case SegmentsOnlyModeReason.osmUnavailable:
        message = localizations.segmentsOnlyModeOsmBlockedMessage;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.segmentsOnlyModeTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        message,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      MapControlsPanelCard(
                        colorScheme: theme.colorScheme,
                        speedKmh: segmentsController.currentSpeedKmh,
                        avgController: avgController,
                        hasActiveSegment: segmentsController.hasActiveSegment,
                        segmentSpeedLimitKph:
                            segmentsController.segmentSpeedLimitKph,
                        segmentDebugPath: segmentsController.segmentDebugPath,
                        distanceToSegmentStartMeters:
                            segmentsController.distanceToSegmentStartMeters,
                        maxWidth: constraints.maxWidth,
                        maxHeight: null,
                        stackMetricsVertically: constraints.maxWidth < 480,
                        forceSingleRow: false,
                        isLandscape:
                            mediaQuery.orientation == Orientation.landscape,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.segmentsOnlyModeReminder,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
