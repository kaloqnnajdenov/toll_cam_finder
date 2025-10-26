import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/weigh_stations/presentation/widgets/weigh_station_picker_map.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/local_weigh_stations_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/remote_weigh_stations_service.dart';

class CreateWeighStationPage extends StatefulWidget {
  const CreateWeighStationPage({super.key});

  @override
  State<CreateWeighStationPage> createState() => _CreateWeighStationPageState();
}

class _CreateWeighStationPageState extends State<CreateWeighStationPage> {
  final TextEditingController _coordinatesController = TextEditingController();

  final LocalWeighStationsService _localService = LocalWeighStationsService();
  bool _isSaving = false;

  @override
  void dispose() {
    _coordinatesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.createWeighStation),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.createWeighStationInstructions,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              WeighStationPickerMap(
                coordinatesController: _coordinatesController,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _coordinatesController,
                decoration: InputDecoration(
                  labelText: localizations.weighStationCoordinatesInputLabel,
                  hintText: localizations.weighStationCoordinatesHint,
                ),
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _onSavePressed,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(localizations.saveWeighStation),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) {
      return;
    }

    if (_coordinatesController.text.trim().isEmpty) {
      _showSnackBar(AppMessages.coordinatesMustBeProvided);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final auth = context.read<AuthController>();
    final userId = auth.currentUserId;
    if (userId == null || userId.isEmpty) {
      _showSnackBar(AppMessages.unableToDetermineLoggedInAccountRetry);
      setState(() {
        _isSaving = false;
      });
      return;
    }

    WeighStationDraft draft;
    try {
      draft = _localService.prepareDraft(
        coordinates: _coordinatesController.text,
      );
    } on LocalWeighStationsServiceException catch (error) {
      _showSnackBar(error.message);
      setState(() {
        _isSaving = false;
      });
      return;
    }

    String? localId;
    try {
      localId = await _localService.saveDraft(draft);
    } catch (error) {
      _showSnackBar(AppMessages.failedToSaveWeighStationLocally);
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final remoteService = RemoteWeighStationsService(client: auth.client);
    try {
      await remoteService.publish(
        coordinates: draft.coordinates,
        addedByUserId: userId,
      );
    } on RemoteWeighStationsServiceException catch (error) {
      _showSnackBar(error.message);
      setState(() {
        _isSaving = false;
      });
      return;
    } catch (_) {
      _showSnackBar(AppMessages.failedToSubmitWeighStation);
      setState(() {
        _isSaving = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppMessages.weighStationPublished),
      ),
    );

    Navigator.of(context).pop(true);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
