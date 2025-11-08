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
        icon: Icons.cloud_sync_outlined,
        title: localizations.introInstructionsSyncTitle,
        body: localizations.introInstructionsSyncBody,
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
    final bool hasSubtitle = subtitle.trim().isNotEmpty;
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
                      if (hasSubtitle) ...[
                        const SizedBox(height: 12),
                        Text(subtitle, style: subtitleStyle),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
            _IntroMetricsPanel(metrics: metrics),
            const SizedBox(height: 32),
            Text(actionsTitle, style: sectionStyle),
            const SizedBox(height: 16),
            _IntroActionsPanel(actions: actions),
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

class _IntroMetricsPanel extends StatelessWidget {
  const _IntroMetricsPanel({required this.metrics});

  final List<_IntroMetricData> metrics;

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
      child: Column(
        children: [
          for (int i = 0; i < metrics.length; i++) ...[
            _IntroMetricTile(data: metrics[i]),
            if (i < metrics.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: palette.divider.withOpacity(isDark ? 0.65 : 0.35),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _IntroMetricTile extends StatelessWidget {
  const _IntroMetricTile({required this.data});

  final _IntroMetricData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroActionsPanel extends StatelessWidget {
  const _IntroActionsPanel({required this.actions});

  final List<_IntroActionData> actions;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(context);
    final theme = Theme.of(context);
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
      child: Column(
        children: [
          for (int i = 0; i < actions.length; i++) ...[
            _IntroActionEntry(data: actions[i]),
            if (i < actions.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: palette.divider.withOpacity(isDark ? 0.65 : 0.35),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _IntroActionEntry extends StatelessWidget {
  const _IntroActionEntry({required this.data});

  final _IntroActionData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppColors.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: palette.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  child: Text(
                    data.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.secondaryText,
                height: 1.45,
              ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(14),
          child: Icon(data.icon, color: palette.primary, size: 26),
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
              const SizedBox(height: 4),
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
      ],
    );
  }
}
