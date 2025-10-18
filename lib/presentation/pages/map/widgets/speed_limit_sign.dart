import 'package:flutter/material.dart';

class SpeedLimitSign extends StatelessWidget {
  const SpeedLimitSign({super.key, this.speedLimit});

  final String? speedLimit;

  @override
  Widget build(BuildContext context) {
    final displayText = speedLimit ?? '-';
    final textTheme = Theme.of(context).textTheme;

    return IgnorePointer(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.shade700, width: 6),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ) ??
              const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
        ),
      ),
    );
  }
}
