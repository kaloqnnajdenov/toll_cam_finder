import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final email = auth.currentEmail ??
        AppLocalizations.of(context).unknownUserLabel;

    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.yourProfile),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                email,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                localizations.profileSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(localizations.deleteProfileTitle),
                          content:
                              Text(localizations.deleteProfileConfirmation),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(localizations.cancelAction),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: Text(localizations.deleteAction),
                            ),
                          ],
                        ),
                      ) ??
                      false;

                  if (!confirmed) {
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await context.read<AuthController>().deleteAccount();
                    Navigator.of(context).popUntil(
                      ModalRoute.withName(AppRoutes.map),
                    );
                  } on AuthFailure catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  } catch (error, stackTrace) {
                    debugPrint('Delete profile error: $error\n$stackTrace');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(AppMessages.unableToDeleteAccount),
                      ),
                    );
                  }
                },
                child: Text(localizations.deleteProfileAction),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await context.read<AuthController>().logOut();
                    Navigator.of(context).popUntil(
                      ModalRoute.withName(AppRoutes.map),
                    );
                  } on AuthFailure catch (error) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(error.message)),
                    );
                  } catch (error, stackTrace) {
                    debugPrint('Logout error: $error\n$stackTrace');
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(AppMessages.unableToLogOutTryAgain),
                      ),
                    );
                  }
                },
                child: Text(localizations.logOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
