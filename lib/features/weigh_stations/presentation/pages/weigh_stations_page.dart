import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/core/app_messages.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station.dart';
import 'package:toll_cam_finder/features/weigh_stations/presentation/widgets/weigh_station_action_dialogs.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/local_weigh_stations_service.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_repository.dart';

class WeighStationsPage extends StatefulWidget {
  const WeighStationsPage({super.key});

  @override
  State<WeighStationsPage> createState() => _WeighStationsPageState();
}

class _WeighStationsPageState extends State<WeighStationsPage> {
  final WeighStationsRepository _repository = WeighStationsRepository();
  final LocalWeighStationsService _localService = LocalWeighStationsService();
  late Future<List<WeighStationInfo>> _stationsFuture;
  bool _stationsUpdated = false;

  @override
  void initState() {
    super.initState();
    _stationsFuture = _repository.loadStations();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_stationsUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.weighStations),
        ),
        body: FutureBuilder<List<WeighStationInfo>>(
          future: _stationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(localizations.failedToLoadWeighStations),
                ),
              );
            }

            final stations = snapshot.data ?? const <WeighStationInfo>[];
            if (stations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(localizations.noWeighStationsAvailable),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final station = stations[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.scale_outlined),
                    title: Text(
                      localizations.weighStationIdentifier(station.displayId),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(localizations.weighStationCoordinatesLabel(station.coordinates)),
                      ],
                    ),
                    onLongPress: () => _onWeighStationLongPress(station),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: SafeArea(
          minimum: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _onCreateWeighStationPressed,
            icon: const Icon(Icons.add),
            label: Text(localizations.createWeighStation),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCreateWeighStationPressed() async {
    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      final result = await Navigator.of(context).pushNamed(AppRoutes.login);
      final loggedIn = result is bool ? result : null;
      if (loggedIn != true) {
        return;
      }
    }

    final result = await Navigator.of(context).pushNamed(AppRoutes.createWeighStation);
    if (!mounted || result != true) {
      return;
    }

    _stationsUpdated = true;
    setState(() {
      _stationsFuture = _repository.loadStations();
    });
  }

  Future<void> _onWeighStationLongPress(WeighStationInfo station) async {
    final action = await showWeighStationActionsSheet(context, station);
    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case WeighStationAction.delete:
        await _confirmAndDeleteWeighStation(station);
        break;
    }
  }

  Future<void> _confirmAndDeleteWeighStation(
    WeighStationInfo station,
  ) async {
    final confirmed = await showDeleteWeighStationConfirmationDialog(
      context,
      station,
    );
    if (!mounted || !confirmed) {
      return;
    }

    await _deleteWeighStation(station);
  }

  Future<void> _deleteWeighStation(WeighStationInfo station) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final deleted = await _localService.deleteLocalStation(station.id);
      if (!mounted) {
        return;
      }

      if (!deleted) {
        messenger.showSnackBar(
          SnackBar(content: Text(AppMessages.failedToDeleteWeighStation)),
        );
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(AppMessages.weighStationDeleted(station.displayId)),
        ),
      );
      _stationsUpdated = true;
      setState(() {
        _stationsFuture = _repository.loadStations();
      });
    } on LocalWeighStationsServiceException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(AppMessages.failedToDeleteWeighStation)),
      );
    }
  }
}
