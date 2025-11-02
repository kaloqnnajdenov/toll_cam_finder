import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';

class MapWelcomeOverlay extends StatelessWidget {
  const MapWelcomeOverlay({
    super.key,
    required this.visible,
    required this.languageOptions,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
    required this.onContinue,
  });

  final bool visible;
  final List<LanguageOption> languageOptions;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageSelected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final List<LanguageOption> availableOptions = languageOptions
        .where((option) => option.available)
        .toList(growable: false);

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        opacity: visible ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primary.withOpacity(isDark ? 0.7 : 0.55),
                      palette.surface.withOpacity(isDark ? 0.92 : 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withOpacity(isDark ? 0.96 : 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: palette.divider
                                .withOpacity(isDark ? 0.7 : 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.45 : 0.18),
                              blurRadius: 38,
                              offset: const Offset(0, 24),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                localizations.mapWelcomeTitle,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                localizations.mapWelcomeLanguagePrompt,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              ...availableOptions.map(
                                (option) => RadioListTile<String>(
                                  value: option.languageCode,
                                  groupValue: selectedLanguageCode,
                                  onChanged: (code) {
                                    if (code != null) {
                                      onLanguageSelected(code);
                                    }
                                  },
                                  title: Text(option.label),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: onContinue,
                                  child: Text(localizations.continueLabel),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapWeighStationPreferenceOverlay extends StatelessWidget {
  const MapWeighStationPreferenceOverlay({
    super.key,
    required this.visible,
    required this.onEnable,
    required this.onSkip,
  });

  final bool visible;
  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        opacity: visible ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: palette.surface.withOpacity(isDark ? 0.85 : 0.82),
              ),
            ),
            Positioned.fill(
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withOpacity(isDark ? 0.97 : 0.95),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: palette.divider
                                .withOpacity(isDark ? 0.75 : 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.5 : 0.2),
                              blurRadius: 34,
                              offset: const Offset(0, 20),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.mapWeighStationsPromptTitle,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.mapWeighStationsPromptDescription,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: palette.secondaryText,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: onSkip,
                                    child: Text(
                                      localizations
                                          .mapWeighStationsPromptSkipButton,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  FilledButton(
                                    onPressed: onEnable,
                                    child: Text(
                                      localizations
                                          .mapWeighStationsPromptEnableButton,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
