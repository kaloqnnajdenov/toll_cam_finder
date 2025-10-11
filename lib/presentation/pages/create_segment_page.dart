import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/presentation/pages/create_segment/widgets/segment_labeled_text_field.dart';
import 'package:toll_cam_finder/presentation/widgets/segment_picker/segment_picker_map.dart';
import 'package:toll_cam_finder/services/auth_controller.dart';
import 'package:toll_cam_finder/services/local_segments_service.dart';
import 'package:toll_cam_finder/services/remote_segments_service.dart';

class CreateSegmentPage extends StatefulWidget {
  const CreateSegmentPage({super.key});

  @override
  State<CreateSegmentPage> createState() => _CreateSegmentPageState();
}

class _CreateSegmentPageState extends State<CreateSegmentPage> {
  static String? _cachedName;
  static String? _cachedRoadName;
  static String? _cachedStartDisplayName;
  static String? _cachedEndDisplayName;
  static String? _cachedStartCoordinates;
  static String? _cachedEndCoordinates;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roadNameController = TextEditingController();
  final TextEditingController _startNameController = TextEditingController();
  final TextEditingController _endNameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();
  bool _persistDraftOnDispose = true;
  bool _isNavigatingToLogin = false;

  @override
  void initState() {
    super.initState();
    if (_cachedName != null) {
      _nameController.text = _cachedName!;
    }
    if (_cachedRoadName != null) {
      _roadNameController.text = _cachedRoadName!;
    }
    if (_cachedStartDisplayName != null) {
      _startNameController.text = _cachedStartDisplayName!;
    }
    if (_cachedEndDisplayName != null) {
      _endNameController.text = _cachedEndDisplayName!;
    }
    if (_cachedStartCoordinates != null) {
      _startController.text = _cachedStartCoordinates!;
    }
    if (_cachedEndCoordinates != null) {
      _endController.text = _cachedEndCoordinates!;
    }
  }

  @override
  void dispose() {
    if (_persistDraftOnDispose) {
      _cachedName = _nameController.text;
      _cachedRoadName = _roadNameController.text;
      _cachedStartDisplayName = _startNameController.text;
      _cachedEndDisplayName = _endNameController.text;
      _cachedStartCoordinates = _startController.text;
      _cachedEndCoordinates = _endController.text;
    } else {
      _cachedName = null;
      _cachedRoadName = null;
      _cachedStartDisplayName = null;
      _cachedEndDisplayName = null;
      _cachedStartCoordinates = null;
      _cachedEndCoordinates = null;
    }
    _nameController.dispose();
    _roadNameController.dispose();
    _startNameController.dispose();
    _endNameController.dispose();
    _startController.dispose();
    _endController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.createSegment)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final horizontalPadding = isWide ? 48.0 : 24.0;
            final instructionBackground = theme.colorScheme.primary.withOpacity(
              theme.brightness == Brightness.dark ? 0.24 : 0.08,
            );

            Widget buildFieldPair(Widget first, Widget second) {
              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: first),
                    const SizedBox(width: 24),
                    Expanded(child: second),
                  ],
                );
              }

              return Column(
                children: [first, const SizedBox(height: 16), second],
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),
                      const SizedBox(height: 16),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: instructionBackground,
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 32 : 24,
                                isWide ? 28 : 24,
                                isWide ? 32 : 24,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppMessages.createSegmentMapInstructionTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(isWide ? 32 : 24),
                              child: SegmentPickerMap(
                                startController: _startController,
                                endController: _endController,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.all(isWide ? 32 : 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppMessages.createSegmentDetailsTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              buildFieldPair(
                                SegmentLabeledTextField(
                                  controller: _nameController,
                                  label: AppMessages.createSegmentNameLabel,
                                  hintText: AppMessages.createSegmentNameHint,
                                  focusNode: _nameFocusNode,
                                ),
                                SegmentLabeledTextField(
                                  controller: _roadNameController,
                                  label: AppMessages.createSegmentRoadNameLabel,
                                  hintText:
                                      AppMessages.createSegmentRoadNameHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _onSavePressed,
                          icon: const Icon(Icons.check_circle),
                          label: Text(localizations.saveSegment),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (!_validateRequiredFields()) {
      return;
    }

    final visibilityChoice = await showDialog<_SegmentVisibilityChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content:  Text(
            AppMessages.chooseSegmentVisibilityQuestion,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_SegmentVisibilityChoice.private);
              },
              child:  Text(AppMessages.noAction),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_SegmentVisibilityChoice.public);
              },
              child:  Text(AppMessages.yesAction),
            ),
          ],
        );
      },
    );

    if (visibilityChoice == null) {
      return;
    }

    switch (visibilityChoice) {
      case _SegmentVisibilityChoice.private:
        final confirmPrivate = await _showConfirmationDialog(
          message: AppMessages.confirmKeepSegmentPrivate,
        );
        if (confirmPrivate == true) {
          await _handlePrivateSegmentSaved();
        }
        break;
      case _SegmentVisibilityChoice.public:
        final confirmPublic = await _showConfirmationDialog(
          message: AppMessages.confirmMakeSegmentPublic,
        );
        if (confirmPublic == true) {
          await _handlePublicSegmentSaved();
        }
        break;
    }
  }

  bool _validateRequiredFields() {
    final missingFields = <String>[];
    FocusNode? focusNode;

    if (_nameController.text.trim().isEmpty) {
      missingFields.add(AppMessages.createSegmentMissingFieldSegmentName);
      focusNode ??= _nameFocusNode;
    }

    if (_startController.text.trim().isEmpty) {
      missingFields.add(AppMessages.createSegmentMissingFieldStartCoordinates);
    }

    if (_endController.text.trim().isEmpty) {
      missingFields.add(AppMessages.createSegmentMissingFieldEndCoordinates);
    }

    if (missingFields.isEmpty) {
      return true;
    }

    if (focusNode != null) {
      focusNode.requestFocus();
    }

    final formattedFields = _formatMissingFields(missingFields);
    _showSnackBar(
      AppMessages.createSegmentMissingFields(formattedFields),
    );
    return false;
  }

  String _formatMissingFields(List<String> fields) {
    if (fields.isEmpty) {
      return '';
    }

    if (fields.length <= 1) {
      return fields.first;
    }

    if (fields.length == 2) {
      return '${fields[0]} ${AppMessages.createSegmentMissingFieldsConjunction} ${fields[1]}';
    }

    final delimiter = AppMessages.createSegmentMissingFieldsDelimiter;
    final conjunction = AppMessages.createSegmentMissingFieldsConjunction;
    final head = fields.sublist(0, fields.length - 1).join(delimiter);
    return '$head$delimiter$conjunction ${fields.last}';
  }

  Future<bool?> _showConfirmationDialog({required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppMessages.noAction),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppMessages.yesAction),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePrivateSegmentSaved() async {
    final draft = _buildDraft(isPublic: false);
    if (draft == null) {
      return;
    }

    final localId = await _saveDraftLocally(draft);
    if (localId == null) {
      return;
    }

    if (!mounted) return;

    _resetDraftState();
    Navigator.of(context).pop(true);
  }

  Future<void> _handlePublicSegmentSaved() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      final choice = await showDialog<_LoginOrLocalChoice>(
        context: context,
        useRootNavigator: true,
        builder: (context) {
          return AlertDialog(
            title:  Text(AppMessages.signInToSharePubliclyTitle),
            content:  Text(AppMessages.signInToSharePubliclyBody),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_LoginOrLocalChoice.saveLocally);
                },
                child:  Text(AppMessages.saveLocallyAction),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(_LoginOrLocalChoice.login);
                },
                child:  Text(AppMessages.loginAction),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      switch (choice) {
        case _LoginOrLocalChoice.login:
          if (_isNavigatingToLogin) {
            break;
          }
          _cacheDraftInputs();
          _isNavigatingToLogin = true;
          try {
            final navigator = Navigator.of(context, rootNavigator: true);
            final result =
                await navigator.pushNamed(AppRoutes.login, arguments: true);
            final loggedIn = result is bool ? result : null;
            if (loggedIn == true && mounted) {
              _showSnackBar(
                AppMessages.loggedInRetrySavePrompt,
              );
            }
          } finally {
            _isNavigatingToLogin = false;
          }
          break;
        case _LoginOrLocalChoice.saveLocally:
          await _handlePrivateSegmentSaved();
          break;
        case null:
          break;
      }
      return;
    }

    final userId = auth.currentUserId;
    if (userId == null || userId.isEmpty) {
      _showSnackBar(
        AppMessages.unableToDetermineLoggedInAccountRetry,
      );
      return;
    }

    final draft = _buildDraft(isPublic: true);
    if (draft == null) {
      return;
    }

    final localId = await _saveDraftLocally(draft);
    if (localId == null) {
      return;
    }

    if (!mounted) {
      await _rollbackLocalDraft(localId);
      return;
    }

    final remoteService = RemoteSegmentsService(client: auth.client);

    try {
      await remoteService.submitForModeration(draft, addedByUserId: userId);
    } on RemoteSegmentsServiceException catch (error) {
      await _rollbackLocalDraft(localId);
      _showSnackBar(error.message);
      return;
    } catch (_) {
      await _rollbackLocalDraft(localId);
      _showSnackBar(AppMessages.failedToSubmitForModeration);
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppMessages.segmentSubmittedForPublicReviewGeneric),
      ),
    );
    _resetDraftState();
    Navigator.of(context).pop(true);
  }

  SegmentDraft? _buildDraft({required bool isPublic}) {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      _showSnackBar(AppMessages.startEndCoordinatesRequired);
      return null;
    }

    try {
      return _localSegmentsService.prepareDraft(
        name: _nameController.text,
        roadName: _roadNameController.text,
        startDisplayName: _startNameController.text,
        endDisplayName: _endNameController.text,
        startCoordinates: _startController.text,
        endCoordinates: _endController.text,
        isPublic: isPublic,
      );
    } on LocalSegmentsServiceException catch (error) {
      _showSnackBar(error.message);
      return null;
    }
  }

  Future<String?> _saveDraftLocally(SegmentDraft draft) async {
    try {
      return await _localSegmentsService.saveDraft(draft);
    } on LocalSegmentsServiceException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar(AppMessages.failedToSaveSegmentLocally);
    }
    return null;
  }

  Future<void> _rollbackLocalDraft(String localId) async {
    try {
      await _localSegmentsService.deleteLocalSegment(localId);
    } catch (error) {
      debugPrint('Failed to rollback local segment $localId: $error');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetDraftState() {
    _persistDraftOnDispose = false;
    _cachedName = null;
    _cachedRoadName = null;
    _cachedStartDisplayName = null;
    _cachedEndDisplayName = null;
    _cachedStartCoordinates = null;
    _cachedEndCoordinates = null;
  }

  void _cacheDraftInputs() {
    _cachedName = _nameController.text;
    _cachedRoadName = _roadNameController.text;
    _cachedStartDisplayName = _startNameController.text;
    _cachedEndDisplayName = _endNameController.text;
    _cachedStartCoordinates = _startController.text;
    _cachedEndCoordinates = _endController.text;
  }
}

enum _SegmentVisibilityChoice { private, public }

enum _LoginOrLocalChoice { login, saveLocally }
