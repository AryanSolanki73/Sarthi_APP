import 'dart:convert';
import 'dart:io';
import 'package:latlong2/latlong.dart';

/// Result of a transit route calculation.
class RouteInfo {
  RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get formattedDuration {
    final mins = (durationSeconds / 60).ceil();
    if (mins <= 1) return '~1 min';
    return '~$mins mins';
  }
}

/// Computes on-campus road routing using OSRM with intelligent geodesic fallback.
class RoutingService {
  static final _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  /// Calculates the road route between two geographical points.
  static Future<RouteInfo> calculateRoute(LatLng start, LatLng end) async {
    // Fallback geodesic line and distance
    final distanceCalc = const Distance();
    final directDistance = distanceCalc.as(LengthUnit.Meter, start, end);
    // Average EV cart campus speed: ~15 km/h = 4.16 m/s
    final fallbackDuration = (directDistance / 4.16).clamp(30.0, 3600.0);
    final fallbackRoute = RouteInfo(
      points: [start, end],
      distanceMeters: directDistance,
      durationSeconds: fallbackDuration,
    );

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
        '?overview=full&geometries=geojson',
      );

      final request = await _httpClient.getUrl(url);
      request.headers.set('User-Agent', 'SarthiApp/1.0 (IIT Ropar)');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final routes = json['routes'] as List<dynamic>?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final dist = (route['distance'] as num?)?.toDouble() ?? directDistance;

          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List<dynamic>?;

          if (coords != null && coords.isNotEmpty) {
            final polylinePoints = coords.map<LatLng>((coord) {
              final pair = coord as List<dynamic>;
              final lon = (pair[0] as num).toDouble();
              final lat = (pair[1] as num).toDouble();
              return LatLng(lat, lon);
            }).toList();

            return RouteInfo(
              points: polylinePoints,
              distanceMeters: dist,
              // Adjust car routing duration to realistic campus EV Cart speed
              durationSeconds: (dist / 4.16).clamp(30.0, 3600.0),
            );
          }
        }
      }
    } catch (_) {
      // Offline fallback
    }

    return fallbackRoute;
  }
}
