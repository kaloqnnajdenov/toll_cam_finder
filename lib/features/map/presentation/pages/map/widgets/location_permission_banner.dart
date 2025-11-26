import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

class LocationPermissionBanner extends StatelessWidget {
  const LocationPermissionBanner({
    super.key,
    required this.userOptedOut,
    required this.isRequestingPermission,
    required this.onRequestPermission,
    required this.onReviewDisclosure,
    required this.onNotNow,
  });

  final bool userOptedOut;
  final bool isRequestingPermission;
  final VoidCallback onRequestPermission;
  final VoidCallback onReviewDisclosure;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final String bodyText = userOptedOut
        ? localizations.locationPermissionOptOutBody
        : localizations.locationPermissionRequiredBody;

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
                        child: Icon(Icons.my_location, color: palette.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.locationPermissionInfoTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bodyText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: palette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (userOptedOut) ...[
                    const SizedBox(height: 12),
                    Text(
                      localizations.backgroundConsentMenuHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: palette.secondaryText,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _LocationPermissionActions(
                    userOptedOut: userOptedOut,
                    isRequestingPermission: isRequestingPermission,
                    onRequestPermission: onRequestPermission,
                    onReviewDisclosure: onReviewDisclosure,
                    onNotNow: onNotNow,
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

class _LocationPermissionActions extends StatelessWidget {
  const _LocationPermissionActions({
    required this.userOptedOut,
    required this.isRequestingPermission,
    required this.onRequestPermission,
    required this.onReviewDisclosure,
    required this.onNotNow,
  });

  final bool userOptedOut;
  final bool isRequestingPermission;
  final VoidCallback onRequestPermission;
  final VoidCallback onReviewDisclosure;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final Widget primaryButton = FilledButton.icon(
      onPressed: isRequestingPermission ? null : onRequestPermission,
      icon: const Icon(Icons.my_location),
      label: isRequestingPermission
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
                Text(localizations.locationPermissionPromptButton),
              ],
            )
          : Text(localizations.locationPermissionPromptButton),
    );

    final Widget? reviewButton = userOptedOut
        ? TextButton(
            onPressed: onReviewDisclosure,
            child: Text(localizations.locationPermissionReviewDisclosure),
          )
        : null;
    final Widget notNowButton = TextButton(
      onPressed: onNotNow,
      child: Text(localizations.locationDisclosureNotNow),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: double.infinity, child: primaryButton),
        if (reviewButton != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: reviewButton,
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: notNowButton),
      ],
    );
  }
}
