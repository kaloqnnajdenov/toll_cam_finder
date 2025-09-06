import 'package:flutter/material.dart';
import 'package:toll_cam_finder/services/average_speed_est.dart';
/// Simple card "dial" showing average speed. No external state mgmt required.
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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final avg = controller.average;
        final isRunning = controller.isRunning;
        return SizedBox(
          width: width,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(avg.toStringAsFixed(decimals),
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(unit, style: Theme.of(context).textTheme.titleSmall),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRunning
                        ? 'Since ${_formatTime(controller.startedAt)}'
                        : 'Press Start',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatTime(DateTime? t) {
    if (t == null) return '—';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
