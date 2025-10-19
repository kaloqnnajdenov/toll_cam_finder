part of 'package:toll_cam_finder/features/map/presentation/pages/map_page.dart';

extension _MapPageDrawer on _MapPageState {
  Drawer _buildOptionsDrawer() {
    final localizations = AppLocalizations.of(context);
    final languageController = context.watch<LanguageController>();
    final audioController = context.watch<GuidanceAudioController>();
    final themeController = context.watch<ThemeController>();
    final bool isDarkMode = themeController.isDarkMode;
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            ListTile(
              leading: Icon(
                isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              ),
              title: Text(localizations.darkMode),
              trailing: Switch.adaptive(
                value: isDarkMode,
                onChanged: (value) => themeController.setDarkMode(value),
              ),
              onTap: themeController.toggle,
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(localizations.sync),
              enabled: !_isSyncing,
              trailing: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: _isSyncing ? null : _onSyncSelected,
            ),
            ListTile(
              leading: const Icon(Icons.segment),
              title: Text(localizations.segments),
              onTap: _onSegmentsSelected,
            ),
            ListTile(
              leading: const Icon(Icons.volume_up_outlined),
              title: Text(localizations.audioModeTitle),
              subtitle: Text(
                _audioModeLabel(audioController.mode, localizations),
              ),
              onTap: _onAudioModeSelected,
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(localizations.languageButton),
              subtitle: Text(languageController.currentOption.label),
              onTap: _onLanguageSelected,
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(localizations.profile),
              onTap: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _onProfileSelected();
                });
              },
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

  void _onAudioModeSelected() {
    final localizations = AppLocalizations.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Consumer<GuidanceAudioController>(
              builder: (context, controller, _) {
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      title: Text(localizations.audioModeTitle),
                    ),
                    for (final mode in GuidanceAudioMode.values)
                      RadioListTile<GuidanceAudioMode>(
                        title: Text(_audioModeLabel(mode, localizations)),
                        value: mode,
                        groupValue: controller.mode,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          controller.setMode(value);
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

  void _onLanguageSelected() {
    final localizations = AppLocalizations.of(context);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return SafeArea(
            child: Consumer<LanguageController>(
              builder: (context, controller, _) {
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

  void _onProfileSelected() {
    final localizations = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    if (auth.isLoggedIn) {
      Navigator.of(context).pushNamed(AppRoutes.profile);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.login),
                title: Text(localizations.logIn),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(AppRoutes.login);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_alt),
                title: Text(localizations.createAccountCta),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  Navigator.of(context).pushNamed(AppRoutes.signUp);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSyncSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_performSync());
    });
  }

  void _onSegmentsSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openSegmentsPage());
    });
  }

  Future<void> _openSegmentsPage() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.segments);
    if (!mounted || result != true) {
      return;
    }

    await _refreshSegmentsData();
  }

  Future<void> _refreshSegmentsData() async {
    final result = await _segmentsService.refreshSegmentsData(
      showMetadataErrors: true,
      userLatLng: _userLatLng,
    );

    _segmentsMetadata = result.metadata;
    if (!mounted) {
      return;
    }

    if (result.metadataError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.metadataError!),
        ),
      );
    }

    _resetSegmentState();
    if (result.seedEvent != null) {
      _applySegmentEvent(result.seedEvent!);
    }

    _nextCameraCheckAt = null;
    _updateVisibleCameras();
    setState(() {});
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _isSyncing = true;
    });

    final auth = context.read<AuthController>();
    SegmentsSyncResult? result;
    try {
      result = await _segmentsService.performSync(
        client: auth.client,
        ignoredSegmentIds: _segmentsMetadata.deactivatedSegmentIds,
        userLatLng: _userLatLng,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      } else {
        _isSyncing = false;
      }
    }

    if (!mounted || result == null) {
      return;
    }

    if (result.message != null) {
      messenger.showSnackBar(SnackBar(content: Text(result.message!)));
    }

    if (!result.isSuccess) {
      return;
    }

    _resetSegmentState();
    if (result.seedEvent != null) {
      _applySegmentEvent(result.seedEvent!);
    }

    _nextCameraCheckAt = null;
    _updateVisibleCameras();
  }
}
