import 'dart:async'; // <- ADD

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(42.6977, 23.3219);
  LatLng? _userLatLng;
  bool _mapReady = false;

  StreamSubscription<Position>? _posSub; // <- ADD

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel(); // <- ADD
    super.dispose();
  }

  Future<void> _initLocation() async {
    final hasPermission = await _ensureLocationPermission();
    if (!hasPermission) return;

    // Get initial fix (as before)
    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _userLatLng = LatLng(pos.latitude, pos.longitude);
    _center = _userLatLng!;
    setState(() {});

    if (_mapReady) _mapController.move(_center, 16);

    // 🔁 Start listening for updates (NEW)
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // meters; tweak if you want fewer updates
      ),
    ).listen((p) {
      _userLatLng = LatLng(p.latitude, p.longitude);
      // Don’t auto-move camera (keeps behavior unchanged).
      // Just update the marker and let "Reset view" recenter to the latest.
      if (mounted) setState(() {});
    });
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
  }

  void _onResetView() {
    final target = _userLatLng ?? _center;
    _mapController.move(target, 16);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 13,
          onMapReady: () {
            _mapReady = true;
            if (_userLatLng != null) {
              _mapController.move(_userLatLng!, 16);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.yourcompany.yourapp',
          ),
          if (_userLatLng != null)
            MarkerLayer(markers: [
              Marker(
                point: _userLatLng!,
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.25),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onResetView,
        icon: const Icon(Icons.my_location),
        label: const Text('Reset view'),
      ),
    );
  }
}
