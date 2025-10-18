import 'package:flutter/material.dart';

class SpeedLimitSign extends StatelessWidget {
  const SpeedLimitSign({
    super.key,
    required this.speedLimitKph,
    this.margin = const EdgeInsets.all(16),
  });

  final double? speedLimitKph;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    if (speedLimitKph == null) {
      return const SizedBox.shrink();
    }

    final int roundedLimit = speedLimitKph!.round();

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: const ShapeDecoration(
          shape: CircleBorder(),
          shadows: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.redAccent, width: 6),
            color: Colors.white,
          ),
          child: Center(
            child: Text(
              '$roundedLimit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ) ??
                  const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
