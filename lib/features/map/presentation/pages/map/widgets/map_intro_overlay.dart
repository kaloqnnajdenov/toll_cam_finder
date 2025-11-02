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

    final instructions = <_IntroInstructionData>[
      _IntroInstructionData(
        icon: Icons.insights_outlined,
        title: localizations.introInstructionsAverageTitle,
        body: localizations.introInstructionsAverageBody,
        children: [
          _AverageSpeedVisual(
            goodLabel: localizations.introInstructionsAverageStateGood,
            warningLabel: localizations.introInstructionsAverageStateWarning,
            overLabel: localizations.introInstructionsAverageStateOver,
          ),
        ],
      ),
      _IntroInstructionData(
        icon: Icons.record_voice_over_outlined,
        title: localizations.introInstructionsVoiceTitle,
        body: localizations.introInstructionsVoiceBody,
        children: [
          _VoiceTimelineVisual(
            steps: [
              _VoiceTimelineStepData(
                icon: Icons.flag_circle_outlined,
                title: localizations.introInstructionsVoiceEnterTitle,
                description: localizations.introInstructionsVoiceEnterBody,
              ),
              _VoiceTimelineStepData(
                icon: Icons.speed_outlined,
                title: localizations.introInstructionsVoiceSpeedTitle,
                description: localizations.introInstructionsVoiceSpeedBody,
              ),
              _VoiceTimelineStepData(
                icon: Icons.route_outlined,
                title: localizations.introInstructionsVoiceApproachTitle,
                description: localizations.introInstructionsVoiceApproachBody,
              ),
              _VoiceTimelineStepData(
                icon: Icons.check_circle_outline,
                title: localizations.introInstructionsVoiceExitTitle,
                description: localizations.introInstructionsVoiceExitBody,
              ),
            ],
          ),
        ],
      ),
    ];

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
                        instructionsTitle: localizations.introInstructionsTitle,
                        instructions: instructions,
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

class _IntroInstructionData {
  const _IntroInstructionData({
    required this.icon,
    required this.title,
    required this.body,
    this.children = const <Widget>[],
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;
}

class _IntroContentCard extends StatelessWidget {
  const _IntroContentCard({
    required this.title,
    required this.subtitle,
    required this.instructionsTitle,
    required this.instructions,
    required this.metricsTitle,
    required this.actionsTitle,
    required this.metrics,
    required this.actions,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String title;
  final String subtitle;
  final String instructionsTitle;
  final List<_IntroInstructionData> instructions;
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
            const SizedBox(height: 24),
            Text(instructionsTitle, style: sectionStyle),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < instructions.length; i++) ...[
                  _IntroInstructionCard(data: instructions[i]),
                  if (i < instructions.length - 1) const SizedBox(height: 16),
                ],
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
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: palette.primary.withOpacity(isDark ? 0.2 : 0.12),
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
                    style: theme.textTheme.titleMedium
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

class _IntroInstructionCard extends StatelessWidget {
  const _IntroInstructionCard({required this.data});

  final _IntroInstructionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color borderColor =
        palette.divider.withOpacity(isDark ? 0.8 : 0.45);
    final Color backgroundColor =
        palette.surface.withOpacity(isDark ? 0.78 : 0.96);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        color: backgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: palette.primary.withOpacity(isDark ? 0.22 : 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(data.icon, color: palette.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: palette.secondaryText,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (data.children.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...data.children,
            ],
          ],
        ),
      ),
    );
  }
}

class _AverageSpeedStateData {
  const _AverageSpeedStateData({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;
}

class _AverageSpeedVisual extends StatelessWidget {
  const _AverageSpeedVisual({
    required this.goodLabel,
    required this.warningLabel,
    required this.overLabel,
  });

  final String goodLabel;
  final String warningLabel;
  final String overLabel;

  @override
  Widget build(BuildContext context) {
    final states = <_AverageSpeedStateData>[
      _AverageSpeedStateData(color: Colors.green, label: goodLabel),
      _AverageSpeedStateData(color: Colors.amber, label: warningLabel),
      _AverageSpeedStateData(color: Colors.redAccent, label: overLabel),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool horizontal = constraints.maxWidth >= 520;
        if (horizontal) {
          return Row(
            children: [
              for (int i = 0; i < states.length; i++) ...[
                Expanded(child: _AverageSpeedStateTile(data: states[i])),
                if (i < states.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < states.length; i++) ...[
              _AverageSpeedStateTile(data: states[i]),
              if (i < states.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _AverageSpeedStateTile extends StatelessWidget {
  const _AverageSpeedStateTile({required this.data});

  final _AverageSpeedStateData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            data.color.withOpacity(0.85),
            data.color.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.speed, color: Colors.white.withOpacity(0.95), size: 24),
            const SizedBox(height: 12),
            Text(
              data.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceTimelineStepData {
  const _VoiceTimelineStepData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _VoiceTimelineVisual extends StatelessWidget {
  const _VoiceTimelineVisual({required this.steps});

  final List<_VoiceTimelineStepData> steps;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool horizontal = constraints.maxWidth >= 560;
        if (horizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(child: _VoiceTimelineStep(data: steps[i])),
                if (i < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: SizedBox(
                      width: 32,
                      child: Divider(
                        color: palette.divider.withOpacity(0.6),
                        thickness: 2,
                      ),
                    ),
                  ),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < steps.length; i++) ...[
              _VoiceTimelineStep(data: steps[i]),
              if (i < steps.length - 1)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 2,
                    height: 24,
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 28),
                    color: palette.divider.withOpacity(0.6),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _VoiceTimelineStep extends StatelessWidget {
  const _VoiceTimelineStep({required this.data});

  final _VoiceTimelineStepData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color bubbleColor =
        palette.primary.withOpacity(isDark ? 0.22 : 0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(data.icon, color: palette.primary, size: 26),
        ),
        const SizedBox(height: 12),
        Text(
          data.title,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          data.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.secondaryText,
            height: 1.4,
          ),
        ),
      ],
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
