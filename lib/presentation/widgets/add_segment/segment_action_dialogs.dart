import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
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
                isDeactivated
                    ? AppMessages.showSegmentOnMapAction
                    : AppMessages.hideSegmentOnMapAction,
              ),
              subtitle: Text(
                isDeactivated
                    ? AppMessages.segmentVisibilityRestoreSubtitle
                    : AppMessages.segmentVisibilityDisableSubtitle,
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
                title:  Text(AppMessages.shareSegmentPubliclyAction),
                subtitle: !isAuthConfigured
                    ?  Text(AppMessages.publicSharingUnavailableShort)
                    : isLoggedIn
                        ?  Text(
                            AppMessages.submitSegmentForPublicReviewSubtitle,
                          )
                        :  Text(AppMessages.signInToShareSegment),
                enabled: canMakePublic && isLoggedIn,
                onTap: canMakePublic && isLoggedIn
                    ? () => Navigator.of(context).pop(SegmentAction.makePublic)
                    : null,
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title:  Text(AppMessages.deleteSegmentAction),
              subtitle: canDelete
                  ? null
                  :  Text(AppMessages.onlyLocalSegmentsCanBeDeleted),
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
        title:  Text(AppMessages.deleteSegmentConfirmationTitle),
        content: Text(
          AppMessages.confirmDeleteSegment(segment.displayId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:  Text(AppMessages.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(AppMessages.deleteAction),
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
        title:  Text(AppMessages.withdrawPublicSubmissionTitle),
        content:  Text(AppMessages.withdrawPublicSubmissionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:  Text(AppMessages.noAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:  Text(AppMessages.yesAction),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
