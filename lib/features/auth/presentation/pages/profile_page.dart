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
              _DangerZoneSection(
                onDeleteAccount: () =>
                    _handleDeleteAccountPressed(context, localizations),
              ),
              const SizedBox(height: 24),
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

  Future<void> _handleDeleteAccountPressed(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final confirmed = await _showDeleteAccountDialog(context, localizations);
    if (confirmed != true) {
      return;
    }

    final navigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    var loadingClosed = false;
    void closeLoadingDialog() {
      if (!loadingClosed) {
        rootNavigator.pop();
        loadingClosed = true;
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await context.read<AuthController>().deleteAccount();
      closeLoadingDialog();
      messenger.showSnackBar(
        SnackBar(content: Text(localizations.profileDeleteAccountSuccess)),
      );
      navigator.popUntil(ModalRoute.withName(AppRoutes.map));
    } on AuthFailure catch (error) {
      closeLoadingDialog();
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error, stackTrace) {
      closeLoadingDialog();
      debugPrint('Delete account error: $error\n$stackTrace');
      messenger.showSnackBar(
        SnackBar(content: Text(AppMessages.unableToDeleteAccountTryAgain)),
      );
    }
  }

  Future<bool?> _showDeleteAccountDialog(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    final controller = TextEditingController();
    String? errorText;
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(localizations.profileDeleteAccountConfirmTitle),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(localizations.profileDeleteAccountConfirmBody),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText:
                              localizations.profileDeleteAccountConfirmLabel,
                          helperText:
                              localizations.profileDeleteAccountConfirmHelper,
                          errorText: errorText,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.error,
                      foregroundColor:
                          Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () {
                      final input = controller.text.trim();
                      if (input.toUpperCase() == 'DELETE') {
                        Navigator.of(context).pop(true);
                      } else {
                        setState(() {
                          errorText =
                              localizations.profileDeleteAccountMismatch;
                        });
                      }
                    },
                    child: Text(localizations.profileDeleteAccountAction),
                  ),
                ],
              );
            },
          );
        },
      );
      return result;
    } finally {
      controller.dispose();
    }
  }
}

class _DangerZoneSection extends StatelessWidget {
  const _DangerZoneSection({required this.onDeleteAccount});

  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.profileDangerZoneTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.profileDeleteAccountDescription,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: onDeleteAccount,
            child: Text(localizations.profileDeleteAccountAction),
          ),
        ],
      ),
    );
  }
}
