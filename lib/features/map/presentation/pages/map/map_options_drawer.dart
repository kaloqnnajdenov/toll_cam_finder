part of 'package:toll_cam_finder/features/map/presentation/pages/map_page.dart';

extension _MapPageDrawer on _MapPageState {
  Drawer _buildOptionsDrawer() {
    final localizations = AppLocalizations.of(context);
    final languageController = context.watch<LanguageController>();
    final audioController = context.watch<GuidanceAudioController>();
    final themeController = context.watch<ThemeController>();
    final backgroundConsentController =
        context.watch<BackgroundLocationConsentController>();
    final bool backgroundConsentLoaded =
        backgroundConsentController.isLoaded;
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
              leading: const Icon(Icons.my_location_outlined),
              title: Text(localizations.backgroundLocationSettingTitle),
              enabled: backgroundConsentLoaded,
              onTap: backgroundConsentLoaded
                  ? () {
                      Navigator.of(context).pop();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        _openBackgroundConsentSettings();
                      });
                    }
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(localizations.introMenuLabel),
              onTap: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _revealIntro();
                });
              },
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
              leading: const Icon(Icons.scale_outlined),
              title: Text(localizations.weighStations),
              onTap: _onWeighStationsSelected,
            ),
            ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: Text(localizations.segmentsOnlyModeButton),
              onTap: _onSimpleModeSelected,
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
            ListTile(
              leading: const Icon(Icons.gavel_outlined),
              title: Text(localizations.termsAndConditions),
              onTap: _onTermsSelected,
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

  void _onTermsSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushNamed(AppRoutes.termsAndConditions);
    });
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

  void _onWeighStationsSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openWeighStationsPage());
    });
  }

  Future<void> _openWeighStationsPage() async {
    final result = await Navigator.of(context).pushNamed(AppRoutes.weighStations);
    if (!mounted || result != true) {
      return;
    }

    LatLngBounds? bounds;
    if (_mapReady) {
      try {
        bounds = _mapController.camera.visibleBounds;
      } catch (_) {
        bounds = null;
      }
    }

    await _segmentsService.loadWeighStations(bounds: bounds);
    if (!mounted) return;
    _updateVisibleWeighStations();
  }

  void _onSimpleModeSelected() {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_openSimpleModePage(SegmentsOnlyModeReason.manual));
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
    final auth = context.read<AuthController>();
    final result = await _segmentsService.refreshSegmentsData(
      showMetadataErrors: true,
      userLatLng: _userLatLng,
      client: auth.client,
      currentUserId: auth.currentUserId,
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
    _updateVisibleSegments();
    _updateVisibleWeighStations();
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
        currentUserId: auth.currentUserId,
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
      if (!result.isSuccess &&
          result.message == AppMessages.syncRequiresInternetConnection) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            final localizations = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(localizations.sync),
              content: Text(AppMessages.syncRequiresInternetConnection),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(AppMessages.okAction),
                ),
              ],
            );
          },
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(result.message!)));
      }
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
    _updateVisibleSegments();
    _updateVisibleWeighStations();
  }
}
