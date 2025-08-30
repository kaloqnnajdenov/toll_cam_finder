import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants.dart';
import '../widgets/base_tile_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TollCam • Map')),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: AppConstants.initialCenter,
          initialZoom: AppConstants.initialZoom,
        ),
        children: const [
          BaseTileLayer(), // Extracted so we can later swap to offline tiles.
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Example action for later: jump to GPS position or Bulgaria center.
          _mapController.move(AppConstants.initialCenter, 7.0);
        },
        label: const Text('Reset View'),
        icon: const Icon(Icons.map),
      ),
    );
  }
}
