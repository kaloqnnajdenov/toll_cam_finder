import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/constants.dart';

class MapActionButton extends StatelessWidget {
  const MapActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface
          .withOpacity(AppConstants.segmentPickerSurfaceOpacity),
      shape: const CircleBorder(),
      elevation: AppConstants.segmentPickerControlElevation,
      child: IconButton(
        icon: Icon(icon, color: theme.colorScheme.onSurface),
        onPressed: onPressed,
      ),
    );
  }
}
