import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/guidance_audio_controller.dart';
import 'package:toll_cam_finder/features/map/domain/controllers/segments_only_mode_controller.dart';
import 'package:toll_cam_finder/features/map/presentation/pages/map/widgets/map_controls/map_controls_panel_card.dart';
import 'package:toll_cam_finder/shared/services/language_controller.dart';
import 'package:toll_cam_finder/shared/services/theme_controller.dart';
import 'package:toll_cam_finder/features/segments/domain/controllers/current_segment_controller.dart';

class SimpleModePage extends StatelessWidget {
  const SimpleModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    final segmentsController = context.watch<SegmentsOnlyModeController>();
    final currentSegment = context.watch<CurrentSegmentController>();
    final avgController = currentSegment.averageController;

    final SegmentsOnlyModeReason reason =
        segmentsController.reason ?? SegmentsOnlyModeReason.manual;
    final bool isForcedMode = reason == SegmentsOnlyModeReason.offline ||
        reason == SegmentsOnlyModeReason.osmUnavailable;
    final bool canResumeMap = !isForcedMode;

    final String message;
    switch (reason) {
      case SegmentsOnlyModeReason.manual:
        message = localizations.segmentsOnlyModeManualMessage;
        break;
      case SegmentsOnlyModeReason.osmUnavailable:
        message = localizations.segmentsOnlyModeOsmBlockedMessage;
        break;
      case SegmentsOnlyModeReason.offline:
        message = localizations.segmentsOnlyModeOfflineMessage;
        break;
    }

    return WillPopScope(
      onWillPop: () async => !isForcedMode,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !isForcedMode,
          title: Text(localizations.segmentsOnlyModeTitle),
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                );
              },
            ),
          ],
        ),
        endDrawer: const _SimpleModeOptionsDrawer(),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final Widget scrollChild = ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        message,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      MapControlsPanelCard(
                        colorScheme: theme.colorScheme,
                        speedKmh: segmentsController.currentSpeedKmh,
                        avgController: avgController,
                        hasActiveSegment: segmentsController.hasActiveSegment,
                        segmentSpeedLimitKph:
                            segmentsController.segmentSpeedLimitKph,
                        segmentDebugPath: segmentsController.segmentDebugPath,
                        distanceToSegmentStartMeters:
                            segmentsController.distanceToSegmentStartMeters,
                        distanceToSegmentStartIsCapped:
                            segmentsController.distanceToSegmentStartIsCapped,
                        maxWidth: constraints.maxWidth,
                        maxHeight: null,
                        stackMetricsVertically: constraints.maxWidth < 480,
                        forceSingleRow: false,
                        isLandscape:
                            mediaQuery.orientation == Orientation.landscape,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations.segmentsOnlyModeReminder,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(child: scrollChild),
                    ),
                    if (canResumeMap) ...[
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child:
                            Text(localizations.segmentsOnlyModeContinueButton),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SimpleModeOptionsDrawer extends StatelessWidget {
  const _SimpleModeOptionsDrawer();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Consumer<ThemeController>(
              builder: (context, themeController, _) {
                final bool isDarkMode = themeController.isDarkMode;
                return ListTile(
                  leading: Icon(
                    isDarkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(localizations.darkMode),
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    onChanged: (value) => themeController.setDarkMode(value),
                  ),
                  onTap: themeController.toggle,
                );
              },
            ),
            Consumer<GuidanceAudioController>(
              builder: (context, audioController, _) {
                return ListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: Text(localizations.audioModeTitle),
                  subtitle: Text(
                    _audioModeLabel(audioController.mode, localizations),
                  ),
                  onTap: () => _showAudioModeSheet(context),
                );
              },
            ),
            Consumer<LanguageController>(
              builder: (context, languageController, _) {
                return ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(localizations.languageButton),
                  subtitle: Text(languageController.currentOption.label),
                  onTap: () => _showLanguageSheet(context),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(localizations.profile),
              onTap: () => _showProfileSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  String _audioModeLabel(
    GuidanceAudioMode mode,
    AppLocalizations localizations,
  ) {
    switch (mode) {
      case GuidanceAudioMode.fullGuidance:
        return localizations.audioModeFullGuidance;
      case GuidanceAudioMode.muteForeground:
        return localizations.audioModeForegroundMuted;
      case GuidanceAudioMode.muteBackground:
        return localizations.audioModeBackgroundMuted;
      case GuidanceAudioMode.absoluteMute:
        return localizations.audioModeAbsoluteMute;
    }
  }

  void _showAudioModeSheet(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      final rootContext = navigator.context;
      showModalBottomSheet<void>(
        context: rootContext,
        builder: (sheetContext) {
          return SafeArea(
            child: Consumer<GuidanceAudioController>(
              builder: (context, controller, _) {
                final localizations = AppLocalizations.of(context);
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(localizations.audioModeTitle),
                    ),
                    for (final mode in GuidanceAudioMode.values)
                      RadioListTile<GuidanceAudioMode>(
                        title: Text(
                          _audioModeLabel(mode, localizations),
                        ),
                        value: mode,
                        groupValue: controller.mode,
                        onChanged: (value) async {
                          if (value == null) {
                            return;
                          }
                          if (value == GuidanceAudioMode.absoluteMute) {
                            final confirmed =
                                await _confirmAbsoluteMute(sheetContext);
                            if (!confirmed) {
                              return;
                            }
                          }
                          controller.setMode(value);
                          if (!sheetContext.mounted) {
                            return;
                          }
                          Navigator.of(sheetContext).pop();
                        },
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    });
  }

  void _showLanguageSheet(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      final rootContext = navigator.context;
      showModalBottomSheet<void>(
        context: rootContext,
        builder: (sheetContext) {
          return SafeArea(
            child: Consumer<LanguageController>(
              builder: (context, controller, _) {
                final localizations = AppLocalizations.of(context);
                final options = controller.languageOptions;
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(localizations.selectLanguage),
                    ),
                    for (final option in options)
                      ListTile(
                        title: Text(option.label),
                        trailing: option.locale == controller.locale
                            ? const Icon(Icons.check)
                            : null,
                        enabled: option.available,
                        subtitle: option.available
                            ? null
                            : Text(localizations.comingSoon),
                        onTap: option.available
                            ? () {
                                controller.setLocale(option.locale);
                                Navigator.of(sheetContext).pop();
                              }
                            : null,
                      ),
                  ],
                );
              },
            ),
          );
        },
      );
    });
  }

  void _showProfileSheet(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      final rootContext = navigator.context;
      final localizations = AppLocalizations.of(rootContext);
      final auth = rootContext.read<AuthController>();
      if (auth.isLoggedIn) {
        navigator.pushNamed(AppRoutes.profile);
        return;
      }
      showModalBottomSheet<void>(
        context: rootContext,
        builder: (sheetContext) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.login),
                  title: Text(localizations.logIn),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    navigator.pushNamed(AppRoutes.login);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_add_alt),
                  title: Text(localizations.createAccountCta),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    navigator.pushNamed(AppRoutes.signUp);
                  },
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Future<bool> _confirmAbsoluteMute(BuildContext context) async {
    final localizations = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(localizations.audioModeAbsoluteMuteConfirmationTitle),
          content: Text(localizations.audioModeAbsoluteMuteConfirmationBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
