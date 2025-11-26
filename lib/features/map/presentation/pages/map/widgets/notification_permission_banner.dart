import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

class NotificationPermissionBanner extends StatelessWidget {
  const NotificationPermissionBanner({
    super.key,
    required this.isRequesting,
    required this.onRequestPermission,
    required this.onNotNow,
  });

  final bool isRequesting;
  final VoidCallback onRequestPermission;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Material(
            color: theme.colorScheme.surface.withOpacity(isDark ? 0.96 : 0.98),
            elevation: 10,
            borderRadius: BorderRadius.circular(28),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: palette.primary
                              .withOpacity(isDark ? 0.24 : 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active,
                            color: palette.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.notificationPermissionInfoTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              localizations.notificationPermissionRequiredBody,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (_) {
                      final Widget primaryButton = FilledButton.icon(
                        onPressed: isRequesting ? null : onRequestPermission,
                        icon: const Icon(Icons.notifications),
                        label: isRequesting
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(localizations
                                      .notificationPermissionPromptButton),
                                ],
                              )
                            : Text(localizations
                                .notificationPermissionPromptButton),
                      );
                      final Widget notNowButton = TextButton(
                        onPressed: onNotNow,
                        child: Text(localizations.locationDisclosureNotNow),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: double.infinity, child: primaryButton),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: notNowButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
