import 'package:flutter/material.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_colors.dart';

class MapIntroOverlay extends StatelessWidget {
  const MapIntroOverlay({
    super.key,
    required this.visible,
    required this.onDismiss,
  });

  final bool visible;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final localizations = AppLocalizations.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final metrics = <_IntroMetricData>[
      _IntroMetricData(
        icon: Icons.speed,
        title: localizations.introMetricCurrentSpeedTitle,
        description: localizations.introMetricCurrentSpeedBody,
      ),
      _IntroMetricData(
        icon: Icons.timeline,
        title: localizations.introMetricAverageSpeedTitle,
        description: localizations.introMetricAverageSpeedBody,
      ),
      _IntroMetricData(
        icon: Icons.shield_outlined,
        title: localizations.introMetricLimitTitle,
        description: localizations.introMetricLimitBody,
      ),
      _IntroMetricData(
        icon: Icons.straighten,
        title: localizations.introMetricDistanceTitle,
        description: localizations.introMetricDistanceBody,
      ),
    ];

    final actions = <_IntroActionData>[
      _IntroActionData(
        icon: Icons.sync,
        title: localizations.introSidebarSyncTitle,
        description: localizations.introSidebarSyncBody,
      ),
      _IntroActionData(
        icon: Icons.segment,
        title: localizations.introSidebarSegmentsTitle,
        description: localizations.introSidebarSegmentsBody,
      ),
      _IntroActionData(
        icon: Icons.scale_outlined,
        title: localizations.introSidebarWeighStationsTitle,
        description: localizations.introSidebarWeighStationsBody,
      ),
      _IntroActionData(
        icon: Icons.volume_up_outlined,
        title: localizations.introSidebarAudioTitle,
        description: localizations.introSidebarAudioBody,
      ),
      _IntroActionData(
        icon: Icons.language,
        title: localizations.introSidebarLanguageTitle,
        description: localizations.introSidebarLanguageBody,
      ),
      _IntroActionData(
        icon: Icons.person_outline,
        title: localizations.introSidebarProfileTitle,
        description: localizations.introSidebarProfileBody,
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onDismiss,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        palette.primary.withOpacity(isDark ? 0.72 : 0.55),
                        palette.surface.withOpacity(isDark ? 0.9 : 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _IntroContentCard(
                        title: localizations.introTitle,
                        subtitle: localizations.introSubtitle,
                        metricsTitle: localizations.introMetricsTitle,
                        actionsTitle: localizations.introSidebarTitle,
                        metrics: metrics,
                        actions: actions,
                        dismissLabel: localizations.introDismiss,
                        onDismiss: onDismiss,
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

class _IntroMetricData {
  const _IntroMetricData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _IntroActionData {
  const _IntroActionData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _IntroContentCard extends StatelessWidget {
  const _IntroContentCard({
    required this.title,
    required this.subtitle,
    required this.metricsTitle,
    required this.actionsTitle,
    required this.metrics,
    required this.actions,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final String metricsTitle;
  final String actionsTitle;
  final List<_IntroMetricData> metrics;
  final List<_IntroActionData> actions;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor =
        theme.colorScheme.surface.withOpacity(isDark ? 0.96 : 0.94);
    final Color borderColor =
        palette.divider.withOpacity(isDark ? 0.7 : 0.45);
    final TextStyle? titleStyle =
        theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700);
    final TextStyle? subtitleStyle = theme.textTheme.bodyLarge
        ?.copyWith(color: palette.secondaryText, height: 1.4);
    final TextStyle? sectionStyle =
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.5 : 0.18),
            blurRadius: 42,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle),
                      const SizedBox(height: 12),
                      Text(subtitle, style: subtitleStyle),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(metricsTitle, style: sectionStyle),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool twoColumns = width >= 600;
                final double cardWidth = twoColumns
                    ? (width - 16) / 2
                    : width;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: metrics
                      .map(
                        (metric) => SizedBox(
                          width: cardWidth,
                          child: _IntroMetricCard(data: metric),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(actionsTitle, style: sectionStyle),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  _IntroActionTile(data: actions[i]),
                  if (i < actions.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onDismiss,
                child: Text(dismissLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroMetricCard extends StatelessWidget {
  const _IntroMetricCard({required this.data});

  final _IntroMetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.surface.withOpacity(isDark ? 0.75 : 0.9),
        border:
            Border.all(color: palette.divider.withOpacity(isDark ? 0.8 : 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(data.icon, color: palette.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              data.title,
              style:
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: palette.secondaryText, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroActionTile extends StatelessWidget {
  const _IntroActionTile({required this.data});

  final _IntroActionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: palette.surface.withOpacity(isDark ? 0.7 : 0.92),
        border:
            Border.all(color: palette.divider.withOpacity(isDark ? 0.85 : 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(data.icon, color: palette.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: palette.secondaryText, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
