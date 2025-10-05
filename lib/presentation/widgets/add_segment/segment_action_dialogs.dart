import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/services/auth_controller.dart';
import 'package:toll_cam_finder/services/segments_repository.dart';

enum SegmentAction { delete, deactivate, activate, makePublic }

Future<SegmentAction?> showSegmentActionsSheet(
  BuildContext context,
  SegmentInfo segment,
) {
  final canDelete = segment.isLocalOnly;
  final isDeactivated = segment.isDeactivated;
  return showModalBottomSheet<SegmentAction>(
    context: context,
    builder: (context) {
      AuthController? authController;
      try {
        authController = context.read<AuthController>();
      } catch (_) {
        authController = null;
      }
      final isLoggedIn = authController?.isLoggedIn == true;
      final isAuthConfigured = authController?.isConfigured == true;
      final canMakePublic =
          segment.isLocalOnly && !segment.isMarkedPublic && isAuthConfigured;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isDeactivated ? Icons.visibility : Icons.visibility_off,
              ),
              title: Text(
                isDeactivated ? 'Show segment on map' : 'Hide segment on map',
              ),
              subtitle: Text(
                isDeactivated
                    ? 'Cameras and warnings for this segment will be restored.'
                    : 'No cameras or warnings will appear for this segment.',
              ),
              onTap: () => Navigator.of(context).pop(
                isDeactivated
                    ? SegmentAction.activate
                    : SegmentAction.deactivate,
              ),
            ),
            if (segment.isLocalOnly && !segment.isMarkedPublic)
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Share segment publicly'),
                subtitle: !isAuthConfigured
                    ? const Text('Public sharing is not available.')
                    : isLoggedIn
                        ? const Text('Submit this segment for public review.')
                        : const Text('Please sign in to share segments publicly.'),
                enabled: canMakePublic && isLoggedIn,
                onTap: canMakePublic && isLoggedIn
                    ? () => Navigator.of(context).pop(SegmentAction.makePublic)
                    : null,
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete segment'),
              subtitle: canDelete
                  ? null
                  : const Text('Only local segments can be deleted.'),
              enabled: canDelete,
              onTap: canDelete
                  ? () => Navigator.of(context).pop(SegmentAction.delete)
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> showDeleteConfirmationDialog(
  BuildContext context,
  SegmentInfo segment,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Delete segment'),
        content: Text(
          'Are you sure you want to delete segment ${segment.displayId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}

Future<bool> showCancelRemoteSubmissionDialog(
  BuildContext context,
  SegmentInfo segment,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Withdraw public submission?'),
        content: const Text(
          'You have submitted this segment for review. '
          'Do you want to withdraw the submission?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
