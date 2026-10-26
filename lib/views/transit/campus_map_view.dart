import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/cart_location.dart';
import 'package:sarthi_app/services/routing_service.dart';

enum MapThemeType { voyager, standard }
// , dark, standard

/// Interactive campus map with verified IIT Ropar coordinates, real-time route
/// calculation, live EV cart markers, and modern high-definition tile styling.
class CampusMapView extends StatefulWidget {
  const CampusMapView({
    super.key,
    this.pickupLocation,
    this.dropLocation,
    this.cartLocations = const [],
    this.onSelectStop,
  });

  final String? pickupLocation;
  final String? dropLocation;
  final List<CartLocation> cartLocations;
  final ValueChanged<String>? onSelectStop;

  /// CARTO Basemap API key for authentic Voyager and Dark Matter tiles
  static const String cartoApiKey = 'cb1_4t08_1_ee5784d6b906a321c1c039c5';

  /// Verified OpenStreetMap coordinates for IIT Ropar permanent campus.
  static const campusLocations = <String, LatLng>{
    'Satluj Hostel': LatLng(30.969204784595604, 76.46845671595626),
    'Beas Hostel': LatLng(30.96905470714629, 76.466918963477),
    'Ravi Hostel': LatLng(30.9669, 76.4699),
    'Chenab Hostel': LatLng(30.969049347233025, 76.4657500215517),
    'Chintpurni Hostel' : LatLng(30.967393808746436, 76.46853066350704),
    'Shivalik Mess': LatLng(30.9662, 76.4713),
    'Utility Block': LatLng(30.9678, 76.4699),
    'Nalanda Library': LatLng(30.967083205173665, 76.47319568293965),
    'Super Academic Building': LatLng(30.9674, 76.4744),
    'J.C. Bose Block': LatLng(30.968849935723348, 76.4747739852841),
    'S. Ramanujan Block': LatLng(30.9688, 76.4757),
    'M2 Lecture Hall': LatLng(30.9677, 76.4719),
    'Guest House': LatLng(30.9713, 76.4771),
    'Main Gate': LatLng(30.9713209900892, 76.47316043205988),
    'Brahmaputra Boys Hostel': LatLng(30.96698039823692, 76.46695646963504),
    'Annapurna Mess' : LatLng(30.96711274436866, 76.46785994454856) , 
    'S. Bhatnagar Block' : LatLng(30.9690164322192, 76.4706036424563) ,
    'Satish Dhawan Block' : LatLng(30.96887474417408, 76.47173175877887) ,
    'M. Visvesvaraya Block (Administrative Block)' : LatLng(30.96864829094076, 76.47327428144052)
  };

  /// Dynamic list of all location names derived from [campusLocations].
  static List<String> get stopNames => campusLocations.keys.toList();

  @override
  State<CampusMapView> createState() => _CampusMapViewState();
}

class _CampusMapViewState extends State<CampusMapView> {
  // Center of IIT Ropar permanent campus
  static const _campusCenter = LatLng(30.9680, 76.4720);

  final _mapController = MapController();
  MapThemeType _currentTheme = MapThemeType.voyager;

  RouteInfo? _calculatedRoute;
  bool _isCalculatingRoute = false;

  @override
  void initState() {
    super.initState();
    _recalculateRoute();
  }

  @override
  void didUpdateWidget(covariant CampusMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupLocation != widget.pickupLocation ||
        oldWidget.dropLocation != widget.dropLocation) {
      _recalculateRoute();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _recalculateRoute() async {
    final start = CampusMapView.campusLocations[widget.pickupLocation];
    final end = CampusMapView.campusLocations[widget.dropLocation];

    if (start == null ||
        end == null ||
        widget.pickupLocation == widget.dropLocation) {
      if (mounted) setState(() => _calculatedRoute = null);
      return;
    }

    setState(() => _isCalculatingRoute = true);

    final route = await RoutingService.calculateRoute(start, end);
    if (!mounted) return;

    setState(() {
      _calculatedRoute = route;
      _isCalculatingRoute = false;
    });

    // Auto-fit route in view with comfortable padding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: [start, end, ...route.points],
          padding: const EdgeInsets.fromLTRB(40, 80, 40, 80),
          maxZoom: 17.5,
        ),
      );
    });
  }

  String get _tileUrl {
    final key = CampusMapView.cartoApiKey;
    final keyParam = key.isNotEmpty ? '?key=$key' : '';

    switch (_currentTheme) {
      case MapThemeType.voyager:
        return 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png$keyParam';
      // case MapThemeType.dark:
      //   return 'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png$keyParam';
      case MapThemeType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<Marker> get _markers {
    final markers = <Marker>[];

    // 1. All campus landmarks/stops as subtle clickable dots
    CampusMapView.campusLocations.forEach((name, point) {
      final isPickup = name == widget.pickupLocation;
      final isDrop = name == widget.dropLocation;

      if (!isPickup && !isDrop) {
        markers.add(
          Marker(
            point: point,
            width: 90,
            height: 40,
            child: GestureDetector(
              onTap: () => widget.onSelectStop?.call(name),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 2),
                      ],
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    // 2. Live EV Carts from Firebase
    for (final cart in widget.cartLocations) {
      markers.add(
        Marker(
          point: LatLng(cart.latitude, cart.longitude),
          width: 54,
          height: 54,
          child: _CartMarker(cart: cart),
        ),
      );
    }

    // 3. Highlighted Pickup Marker
    final pickupPoint = CampusMapView.campusLocations[widget.pickupLocation];
    if (pickupPoint != null) {
      markers.add(
        Marker(
          point: pickupPoint,
          width: 50,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF065F46),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Pickup',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Highlighted Drop Marker
    final dropPoint = CampusMapView.campusLocations[widget.dropLocation];
    if (dropPoint != null) {
      markers.add(
        Marker(
          point: dropPoint,
          width: 50,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Drop',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> get _polylines {
    if (_calculatedRoute == null || _calculatedRoute!.points.isEmpty) return [];

    return [
      // Outer shadow/border casing
      Polyline(
        points: _calculatedRoute!.points,
        strokeWidth: 7.0,
        color: const Color(0x66065F46),
      ),
      // Inner vibrant emerald route line
      Polyline(
        points: _calculatedRoute!.points,
        strokeWidth: 4.5,
        color: AppColors.emerald,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final liveCartCount = widget.cartLocations
        .where((c) => c.status == 'active')
        .length;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: _campusCenter,
            initialZoom: 16.2,
            minZoom: 14.0,
            maxZoom: 18.5,
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: 'com.example.sarthi_app',
              maxZoom: 19,
            ),
            PolylineLayer(polylines: _polylines),
            MarkerLayer(markers: _markers),
          ],
        ),

        // Route Calculation Summary Pill (Top Center)
        if (_calculatedRoute != null || _isCalculatingRoute)
          Positioned(
            top: 14,
            left: 14,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.emerald,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _isCalculatingRoute
                        ? const Text(
                            'Calculating road route...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _calculatedRoute!.formattedDistance,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const Text(
                                    ' · ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_calculatedRoute!.formattedDuration} by EV Cart',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.emerald,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${widget.pickupLocation} → ${widget.dropLocation}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  if (_isCalculatingRoute)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.emerald,
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          Positioned(
            top: 14,
            left: 14,
            child: _MapStatus(count: liveCartCount),
          ),

        // Controls (Right side)
        Positioned(
          top: 14,
          right: 14,
          child: Column(
            children: [
              _MapButton(
                icon: Icons.layers_outlined,
                tooltip: 'Switch Map Style',
                onPressed: _cycleMapTheme,
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.my_location,
                tooltip: 'Center Campus',
                onPressed: () => _mapController.move(_campusCenter, 16.2),
              ),
              const SizedBox(height: 8),
              _MapButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onPressed: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 0.8,
                ),
              ),
              const SizedBox(height: 4),
              _MapButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onPressed: () => _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 0.8,
                ),
              ),
            ],
          ),
        ),

        // Map attribution
        const Positioned(
          bottom: 4,
          right: 8,
          child: Text(
            '© OpenStreetMap & CARTO',
            style: TextStyle(fontSize: 9, color: Color(0xFF888888)),
          ),
        ),
      ],
    );
  }

  void _cycleMapTheme() {
    setState(() {
      switch (_currentTheme) {
        case MapThemeType.voyager:
          //   _currentTheme = MapThemeType.dark;
          //   break;
          // case MapThemeType.dark:
          _currentTheme = MapThemeType.standard;
          break;
        case MapThemeType.standard:
          _currentTheme = MapThemeType.voyager;
          break;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Switched to ${_currentTheme.name.toUpperCase()} map style',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _CartMarker extends StatelessWidget {
  const _CartMarker({required this.cart});
  final CartLocation cart;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${cart.name}\nBattery: ${cart.batteryLevel}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.emerald.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.airport_shuttle_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 2),
              ],
            ),
            child: Text(
              '${cart.batteryLevel}%',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapStatus extends StatelessWidget {
  const _MapStatus({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8)],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.circle, color: AppColors.emerald, size: 9),
        const SizedBox(width: 7),
        Text(
          '$count Carts Active',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    ),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    shadowColor: Colors.black26,
    child: IconButton(
      icon: Icon(icon, color: const Color(0xFF374151), size: 19),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}
