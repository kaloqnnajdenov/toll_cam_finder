import 'package:flutter/material.dart';

import 'package:toll_cam_finder/services/segments_repository.dart';

enum SegmentAction { delete }

Future<SegmentAction?> showSegmentActionsSheet(
  BuildContext context,
  SegmentInfo segment,
) {
  final canDelete = segment.isLocalOnly;
  return showModalBottomSheet<SegmentAction>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
