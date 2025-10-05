import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toll_cam_finder/app/app_routes.dart';
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create segment')),
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
                                    'Fine-tune the segment on the map',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Drop or drag markers to adjust the start and end points. '
                                    'Coordinates are filled automatically as you move them.',
                                    style: theme.textTheme.bodyMedium,
                                  ),
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
                                'Segment details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 24),
                              buildFieldPair(
                                SegmentLabeledTextField(
                                  controller: _nameController,
                                  label: 'Segment name',
                                  hintText: 'Segment name',
                                ),
                                SegmentLabeledTextField(
                                  controller: _roadNameController,
                                  label: 'Road name',
                                  hintText: 'Road name',
                                ),
                              ),
                              const SizedBox(height: 20),
                              buildFieldPair(
                                SegmentLabeledTextField(
                                  controller: _startNameController,
                                  label: 'Start',
                                  hintText: 'Start name',
                                ),
                                SegmentLabeledTextField(
                                  controller: _endNameController,
                                  label: 'End',
                                  hintText: 'End name',
                                ),
                              ),
                              const SizedBox(height: 20),
                              buildFieldPair(
                                SegmentLabeledTextField(
                                  controller: _startController,
                                  label: 'Start coordinates',
                                  hintText: '41.8626802,26.0873785',
                                ),
                                SegmentLabeledTextField(
                                  controller: _endController,
                                  label: 'End point',
                                  hintText: '41.8322163,26.1404669',
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
                          label: const Text('Save segment'),
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
    final visibilityChoice = await showDialog<_SegmentVisibilityChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Do you want the segment to be publically visible?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_SegmentVisibilityChoice.private);
              },
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_SegmentVisibilityChoice.public);
              },
              child: const Text('Yes'),
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
          message:
              'Are you sure that you want to keep the segment only to yourself?',
        );
        if (confirmPrivate == true) {
          await _handlePrivateSegmentSaved();
        }
        break;
      case _SegmentVisibilityChoice.public:
        final confirmPublic = await _showConfirmationDialog(
          message: 'Are you sure you want to make this segment public?',
        );
        if (confirmPublic == true) {
          await _handlePublicSegmentSaved();
        }
        break;
    }
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
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
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
            title: const Text('Sign in to share publicly'),
            content: const Text(
              'You need to be logged in to submit a public segment. '
              'Would you like to log in or save the segment locally instead?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(_LoginOrLocalChoice.saveLocally);
                },
                child: const Text('Save locally'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(_LoginOrLocalChoice.login);
                },
                child: const Text('Login'),
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
            final result = await navigator.pushNamed(AppRoutes.login);
            final loggedIn = result is bool ? result : null;
            if (loggedIn == true && mounted) {
              _showSnackBar(
                'Logged in successfully. Tap "Save segment" again to submit the segment.',
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
        'Unable to determine the logged in account. Please sign in again.',
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
      _showSnackBar('Failed to submit the segment for moderation.');
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segment submitted for public review.')),
    );
    _resetDraftState();
    Navigator.of(context).pop(true);
  }

  SegmentDraft? _buildDraft({required bool isPublic}) {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      _showSnackBar('Start and end coordinates are required.');
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
      _showSnackBar('Failed to save the segment locally.');
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
