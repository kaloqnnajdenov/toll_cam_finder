import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:toll_cam_finder/app/app_routes.dart';
import 'package:toll_cam_finder/app/localization/app_localizations.dart';
import 'package:toll_cam_finder/features/auth/application/auth_controller.dart';
import 'package:toll_cam_finder/features/weigh_stations/domain/weigh_station.dart';
import 'package:toll_cam_finder/features/weigh_stations/services/weigh_stations_repository.dart';

class WeighStationsPage extends StatefulWidget {
  const WeighStationsPage({super.key});

  @override
  State<WeighStationsPage> createState() => _WeighStationsPageState();
}

class _WeighStationsPageState extends State<WeighStationsPage> {
  final WeighStationsRepository _repository = WeighStationsRepository();
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
                      station.name.isNotEmpty
                          ? station.name
                          : localizations.weighStationUnnamed(station.displayId),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (station.road.isNotEmpty)
                          Text(localizations.weighStationRoadLabel(station.road)),
                        Text(localizations.weighStationCoordinatesLabel(station.coordinates)),
                        if (station.isLocalOnly)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              localizations.weighStationLocalBadge,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                            ),
                          ),
                      ],
                    ),
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
}
