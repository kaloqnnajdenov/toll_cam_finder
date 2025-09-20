import 'package:flutter/material.dart';
import 'package:toll_cam_finder/presentation/widgets/smooth_number_text.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';

/// "Average speed" dial styled to match CurrentSpeedDial.
class AverageSpeedDial extends StatelessWidget {
  const AverageSpeedDial({
    super.key,
    required this.controller,
    this.title = 'Avg Speed',
    this.decimals = 1,
    this.unit = 'km/h',
    this.width = 160,
  });

  final AverageSpeedController controller;
  final String title;
  final int decimals;
  final String unit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final avgRaw = controller.average;
        final avg = avgRaw.isFinite ? avgRaw : 0.0;

        return SizedBox(
          width: width,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row with subtle loop icon to echo "averaging"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.auto_awesome_motion, size: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Big numeric + unit
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SmoothNumberText(
                          value: avg,
                          decimals: decimals,
                          style: textTheme.displaySmall,
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(unit, style: textTheme.titleSmall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
