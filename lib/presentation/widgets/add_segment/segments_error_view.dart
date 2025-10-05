import 'package:flutter/material.dart';
import 'package:toll_cam_finder/core/app_messages.dart';

class SegmentsErrorView extends StatelessWidget {
  const SegmentsErrorView({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(AppMessages.failedToLoadSegments),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text(AppMessages.retryAction),
          ),
        ],
      ),
    );
  }
}
