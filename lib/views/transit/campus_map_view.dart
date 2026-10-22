import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sarthi_app/core/app_colors.dart';

/// Map view used while a passenger selects an EV-cart pickup and drop point.
/// Map positions are frontend demo data; active cart locations will eventually
/// be supplied by the backend through TransitService.
class CampusMapView extends StatefulWidget {
  const CampusMapView({super.key, this.pickupLocation, this.dropLocation});

  final String? pickupLocation;
  final String? dropLocation;

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  static const _center = LatLng(30.9715, 76.4732);
  static const _locations = <String, LatLng>{
    'Satlej Hostel': LatLng(30.9678, 76.4705),
    'Beas Hostel': LatLng(30.9688, 76.4702),
    'Brahmaputra Hostel': LatLng(30.9668, 76.4718),
    'Main Gate': LatLng(30.9765, 76.4725),
    'JC Bose Academic Block': LatLng(30.9725, 76.4738),
    'Ramanujan Complex': LatLng(30.9712, 76.4750),
    'Central Library': LatLng(30.9718, 76.4728),
    'Student Activity Center (SAC)': LatLng(30.9698, 76.4715),
  };
  final _mapController = MapController();

  @override
  void dispose() { _mapController.dispose(); super.dispose(); }

  List<Marker> get _markers {
    final markers = <Marker>[
      const Marker(point: LatLng(30.9685, 76.4712), width: 42, height: 42, child: _CartMarker()),
      const Marker(point: LatLng(30.9722, 76.4735), width: 42, height: 42, child: _CartMarker()),
      const Marker(point: LatLng(30.9710, 76.4725), width: 42, height: 42, child: _CartMarker()),
    ];
    final pickup = _locations[widget.pickupLocation];
    if (pickup != null) markers.add(Marker(point: pickup, width: 40, height: 40, child: const Icon(Icons.location_on, color: AppColors.emerald, size: 40)));
    final drop = _locations[widget.dropLocation];
    if (drop != null) markers.add(Marker(point: drop, width: 40, height: 40, child: const Icon(Icons.flag, color: Colors.red, size: 32)));
    return markers;
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _center, initialZoom: 15.5, minZoom: 13, maxZoom: 18.5),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.iitrpr.sarthi_app'),
              MarkerLayer(markers: _markers),
            ],
          ),
          const Positioned(top: 12, left: 12, child: _MapStatus()),
          Positioned(top: 12, right: 12, child: Column(children: [
            _MapButton(icon: Icons.my_location, tooltip: 'Recenter', onPressed: () => _mapController.move(_center, 15.5)),
            const SizedBox(height: 8),
            _MapButton(icon: Icons.add, tooltip: 'Zoom in', onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1)),
            const SizedBox(height: 4),
            _MapButton(icon: Icons.remove, tooltip: 'Zoom out', onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1)),
          ])),
          const Positioned(bottom: 5, right: 8, child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Color(0xFF555555)))),
        ],
      );
}

class _CartMarker extends StatelessWidget {
  const _CartMarker();
  @override
  Widget build(BuildContext context) => const CircleAvatar(backgroundColor: AppColors.emerald, child: Icon(Icons.airport_shuttle, color: Colors.white, size: 20));
}

class _MapStatus extends StatelessWidget {
  const _MapStatus();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(20)),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, color: AppColors.emerald, size: 9), SizedBox(width: 6), Text('3 Carts Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon; final String tooltip; final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Material(color: Colors.white, shape: const CircleBorder(), child: IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed));
}
