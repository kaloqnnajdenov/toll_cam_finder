import 'package:flutter/material.dart';

import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station.dart';

enum WeighStationAction { delete }

Future<WeighStationAction?> showWeighStationActionsSheet(
  BuildContext context,
  WeighStationInfo station,
) {
  final canDelete = station.isLocalOnly;
  return showModalBottomSheet<WeighStationAction>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppMessages.deleteWeighStationAction),
              subtitle: canDelete
                  ? null
                  : Text(AppMessages.onlyLocalWeighStationsCanBeDeleted),
              enabled: canDelete,
              onTap: canDelete
                  ? () => Navigator.of(context).pop(WeighStationAction.delete)
                  : null,
            ),
          ],
        ),
      );
    },
  );
}

Future<bool> showDeleteWeighStationConfirmationDialog(
  BuildContext context,
  WeighStationInfo station,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(AppMessages.deleteWeighStationConfirmationTitle),
        content: Text(
          AppMessages.confirmDeleteWeighStation(station.displayId),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppMessages.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppMessages.deleteAction),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
