import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final LocalSegmentsService _localSegmentsService = LocalSegmentsService();

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create segment'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Segment details',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              _LabeledTextField(
                controller: _nameController,
                label: 'Segment name',
                hintText: 'Segment name',
              ),
              const SizedBox(height: 16),
              _LabeledTextField(
                controller: _startController,
                label: 'Start coordinates',
                hintText: '41.8626802,26.0873785',
              ),
              const SizedBox(height: 16),
              _LabeledTextField(
                controller: _endController,
                label: 'End point',
                hintText: '41.8322163,26.1404669',
              ),
              const SizedBox(height: 24),
              Text(
                'Map selection',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              SegmentPickerMap(
                startController: _startController,
                endController: _endController,
              ),
              const SizedBox(height: 32),
              Center(
                child: FilledButton(
                  onPressed: _onSavePressed,
                  child: const Text('Save segment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    final visibilityChoice = await showDialog<_SegmentVisibilityChoice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Do you want the segment to be publically visible?'),
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
          message: 'Are you sure that you want to keep the segment only to yourself?',
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
    final draft = _buildDraft();
    if (draft == null) {
      return;
    }

    final localId = await _saveDraftLocally(draft);
    if (localId == null) {
      return;
    }

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  Future<void> _handlePublicSegmentSaved() async {
    final draft = _buildDraft();
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

    final auth = context.read<AuthController>();
    final remoteService = RemoteSegmentsService(client: auth.client);

    try {
      await remoteService.submitForModeration(draft);
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
      const SnackBar(
        content: Text('Segment submitted for public review.'),
      ),
    );
    Navigator.of(context).pop(true);
  }

  SegmentDraft? _buildDraft() {
    if (_startController.text.trim().isEmpty ||
        _endController.text.trim().isEmpty) {
      _showSnackBar('Start and end coordinates are required.');
      return null;
    }

    try {
      return _localSegmentsService.prepareDraft(
        name: _nameController.text,
        startCoordinates: _startController.text,
        endCoordinates: _endController.text,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.controller,
    required this.label,
    this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

enum _SegmentVisibilityChoice {
  private,
  public,
}