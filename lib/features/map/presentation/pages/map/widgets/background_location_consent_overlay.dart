import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

enum BackgroundLocationConsentOption {
  allow,
  deny,
}

class BackgroundLocationConsentOverlay extends StatelessWidget {
  const BackgroundLocationConsentOverlay({
    super.key,
    required this.visible,
    required this.selection,
    required this.onSelectionChanged,
    required this.onAgree,
    required this.onNotNow,
    this.isProcessing = false,
  });

  final bool visible;
  final BackgroundLocationConsentOption? selection;
  final ValueChanged<BackgroundLocationConsentOption> onSelectionChanged;
  final VoidCallback onAgree;
  final VoidCallback onNotNow;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool allowSelected =
        selection == BackgroundLocationConsentOption.allow;
    final bool denySelected =
        selection == BackgroundLocationConsentOption.deny;
    final bool canAgree = allowSelected && !isProcessing;
    final bool canSkip = denySelected && !isProcessing;
    final bool showAgreeProgress =
        isProcessing && allowSelected;

    final List<_ConsentOptionData> options = [
      _ConsentOptionData(
        option: BackgroundLocationConsentOption.allow,
        icon: Icons.shield_moon_outlined,
        title: localizations.backgroundConsentAllowTitle,
        description: localizations.backgroundConsentAllowSubtitle,
      ),
      _ConsentOptionData(
        option: BackgroundLocationConsentOption.deny,
        icon: Icons.visibility_off_outlined,
        title: localizations.backgroundConsentDenyTitle,
        description: localizations.backgroundConsentDenySubtitle,
      ),
    ];

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        opacity: visible ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.primary.withOpacity(isDark ? 0.75 : 0.55),
                      palette.surface.withOpacity(isDark ? 0.9 : 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
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
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withOpacity(isDark ? 0.96 : 0.94),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: palette.divider
                                .withOpacity(isDark ? 0.7 : 0.45),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(isDark ? 0.45 : 0.16),
                              blurRadius: 40,
                              offset: const Offset(0, 28),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 32,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: palette.primary
                                      .withOpacity(isDark ? 0.2 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.my_location,
                                  color: palette.primary,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                localizations.backgroundConsentTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.backgroundConsentBody,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: palette.secondaryText,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizations.backgroundConsentMenuHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: palette.secondaryText
                                      .withOpacity(0.9),
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final bool horizontal =
                                      constraints.maxWidth >= 420;
                                  final List<Widget> cards = options
                                      .map(
                                        (data) => _ConsentOptionCard(
                                          data: data,
                                          selected:
                                              selection == data.option,
                                          onTap: () =>
                                              onSelectionChanged(data.option),
                                        ),
                                      )
                                      .toList(growable: false);
                                  if (horizontal) {
                                    return Row(
                                      children: [
                                        Expanded(child: cards[0]),
                                        const SizedBox(width: 16),
                                        Expanded(child: cards[1]),
                                      ],
                                    );
                                  }
                                  return Column(
                                    children: [
                                      cards[0],
                                      const SizedBox(height: 16),
                                      cards[1],
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: canAgree ? onAgree : null,
                                  child: showAgreeProgress
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
                                            Text(
                                              localizations
                                                  .locationDisclosureAgree,
                                            ),
                                          ],
                                        )
                                      : Text(
                                          localizations.locationDisclosureAgree,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: canSkip ? onNotNow : null,
                                  child: Text(
                                    localizations.locationDisclosureSkip,
                                  ),
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

class _ConsentOptionData {
  const _ConsentOptionData({
    required this.option,
    required this.icon,
    required this.title,
    required this.description,
  });

  final BackgroundLocationConsentOption option;
  final IconData icon;
  final String title;
  final String description;
}

class _ConsentOptionCard extends StatelessWidget {
  const _ConsentOptionCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _ConsentOptionData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color borderColor =
        selected ? palette.primary : palette.divider.withOpacity(0.6);
    final Color backgroundColor = selected
        ? palette.primary.withOpacity(isDark ? 0.22 : 0.14)
        : palette.surface.withOpacity(isDark ? 0.3 : 0.86);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            color: backgroundColor,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: palette.primary.withOpacity(0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 18),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: palette.surface.withOpacity(isDark ? 0.4 : 0.92),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.icon,
                  color: palette.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: palette.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
