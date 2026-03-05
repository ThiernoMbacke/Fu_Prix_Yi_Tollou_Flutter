import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Écran pour choisir une position sur la carte (OpenStreetMap).
/// Retourne le [LatLng] sélectionné ou null si annulé.
class MapPickerScreen extends StatefulWidget {
  /// Position initiale (Dakar par défaut).
  final LatLng? initialPosition;

  const MapPickerScreen({super.key, this.initialPosition});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _dakar = LatLng(14.7167, -17.4677);
  late final MapController _mapController;
  LatLng _selectedPosition;
  bool _loadingLocation = false;

  _MapPickerScreenState()
      : _selectedPosition = _dakar,
        _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition!;
    } else {
      _selectedPosition = _dakar;
    }
    _tryGetCurrentLocation();
  }

  Future<void> _tryGetCurrentLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied ||
            requested == LocationPermission.deniedForever) {
          setState(() => _loadingLocation = false);
          return;
        }
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (mounted) {
        setState(() {
          _selectedPosition = LatLng(pos.latitude, pos.longitude);
          _loadingLocation = false;
        });
        _mapController.move(_selectedPosition, 15.0);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selectedPosition = point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la localisation'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedPosition),
            child: const Text('Valider'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPosition,
              initialZoom: 14.0,
              onTap: _onMapTap,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fouprix.yitollou',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPosition,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_loadingLocation)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Position en cours...'),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            bottom: 24,
            child: FloatingActionButton.small(
              heroTag: 'current_loc',
              onPressed: _loadingLocation ? null : _tryGetCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
