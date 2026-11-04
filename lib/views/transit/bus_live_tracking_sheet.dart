import 'package:flutter/material.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/bus.dart';

/// Custom painter for the dotted/dashed border around the live in-transit bus callout badge.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.2,
    this.dashWidth = 4.0,
    this.dashSpace = 3.0,
    this.borderRadius = 8.0,
  });

  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.borderRadius != borderRadius;
}

/// Modal bottom sheet displaying live active route progress, real-time bus location,
/// and passenger capacity (onboarded vs total available seats).
class BusLiveTrackingSheet extends StatelessWidget {
  const BusLiveTrackingSheet({super.key, required this.bus, this.onBookSeat});

  final Bus bus;
  final VoidCallback? onBookSeat;

  static void show(
    BuildContext context, {
    required Bus bus,
    VoidCallback? onBookSeat,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BusLiveTrackingSheet(bus: bus, onBookSeat: onBookSeat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stops = bus.routeStops;
    final int onboarded = bus.onboardedPassengers;
    final int capacity = bus.totalSeats;
    final int available = bus.availableSeats;
    final double occupancy = bus.occupancyRate;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // 1. Sheet Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Dark GPS Live Top Bar
              _buildGpsTopBar(),

              // 3. Scrollable Content Area
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Bus Name & Speed Badge
                    _buildBusHeader(),
                    const SizedBox(height: 18),

                    // Passenger Capacity & Onboarded Status
                    _buildCapacityCard(
                      onboarded: onboarded,
                      capacity: capacity,
                      available: available,
                      occupancy: occupancy,
                    ),
                    const SizedBox(height: 24),

                    // Section Title: Active Route
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Route & Live Status',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${stops.length} Stops',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active Route Timeline matching user reference image
                    _buildRouteTimeline(stops),
                    const SizedBox(height: 24),

                    // Action Button: Book Seat
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: bus.isFull
                            ? null
                            : () {
                                Navigator.pop(context);
                                onBookSeat?.call();
                              },
                        icon: const Icon(Icons.event_seat_rounded, size: 18),
                        label: Text(
                          bus.isFull
                              ? 'Bus is Fully Booked'
                              : 'Book Seat on this Bus ($available Available)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Dark status header bar ("🟢 GPS • Accurate to 5m" and "Updated 10s ago")
  Widget _buildGpsTopBar() {
    return Container(
      width: double.infinity,
      color: AppColors.emerald, // Dark slate / navy matching image
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), // Bright GPS active green
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(102, 11, 55, 11),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'GPS • ${bus.gpsAccuracy}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          Text(
            'Updated ${bus.lastUpdated}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Bus Title, Route subtitle, and Speed Pill Badge
  Widget _buildBusHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.route,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Departure: ${bus.departureTime} · ${bus.registrationNumber}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE), // Soft light-blue
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bus.speed,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7), // Primary azure blue
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Capacity of On-Boarded Passengers Card
  Widget _buildCapacityCard({
    required int onboarded,
    required int capacity,
    required int available,
    required double occupancy,
  }) {
    // Dynamic color coding based on capacity
    final Color statusColor;
    final String statusLabel;

    if (available <= 0) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'Full Capacity (100%)';
    } else if (occupancy >= 0.8) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'High Occupancy (${(occupancy * 100).round()}%)';
    } else if (occupancy >= 0.5) {
      statusColor = const Color(0xFF0284C7);
      statusLabel = 'Moderate Occupancy (${(occupancy * 100).round()}%)';
    } else {
      statusColor = AppColors.emerald;
      statusLabel = 'Seats Available (${(occupancy * 100).round()}%)';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with Occupancy tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 17,
                    color: Color(0xFF0F172A),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PASSENGER CAPACITY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Metric Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$onboarded',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'onboarded of $capacity capacity',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_seat_rounded,
                      size: 14,
                      color: available > 0
                          ? AppColors.emerald
                          : Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$available Left',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: available > 0
                            ? const Color(0xFF065F46)
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Capacity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 14),

          // 3 Metric Pills
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'Onboarded',
                  value: '$onboarded',
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'Available',
                  value: '$available',
                  color: available > 0 ? AppColors.emerald : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'Total Capacity',
                  value: '$capacity',
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Timeline with stops, live bus location box, and departed/upcoming indicators
  Widget _buildRouteTimeline(List<BusRouteStop> stops) {
    if (stops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No stops registered for this route.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    return Column(
      children: [
        if (stops.isNotEmpty && stops.first.isNext) _buildLiveBusCallout(),
        for (int i = 0; i < stops.length; i++) ...[
          _buildStopRow(
            stops[i],
            isFirst: i == 0,
            isLast: i == stops.length - 1,
          ),
          // If this is the departed stop right before the next upcoming stop,
          // render the live in-transit bus callout box!
          if (stops[i].isDeparted &&
              i + 1 < stops.length &&
              stops[i + 1].isNext)
            _buildLiveBusCallout(),
        ],
      ],
    );
  }

  /// Single Stop in the route timeline
  Widget _buildStopRow(
    BusRouteStop stop, {
    required bool isFirst,
    required bool isLast,
  }) {
    // Circle marker appearance
    final Widget circleMarker;
    if (stop.isDeparted) {
      // Solid grey circle
      circleMarker = Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFF64748B),
          shape: BoxShape.circle,
        ),
      );
    } else if (stop.isNext) {
      // Open blue circle
      circleMarker = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0284C7), width: 2.5),
        ),
      );
    } else {
      // Open dark charcoal circle
      circleMarker = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0F172A), width: 2.5),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left vertical timeline indicator
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting line
                if (!isLast)
                  Positioned(
                    top: 14,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: stop.isDeparted
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                // Marker
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: circleMarker,
                ),
              ],
            ),
          ),

          // Center: Stop Name & Subtext
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 8, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: stop.isDeparted
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                      decoration: stop.isDeparted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: const Color(0xFF94A3B8),
                    ),
                  ),
                  if (stop.subtext != null && stop.subtext!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      stop.subtext!,
                      style: TextStyle(
                        fontSize: 12,
                        color: stop.isDeparted
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Right: Scheduled time & Status
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 0, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (stop.scheduledTime != null)
                  Text(
                    stop.scheduledTime!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: stop.isDeparted
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                if (stop.statusText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stop.statusText!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: stop.isDelayed
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: stop.isDelayed
                          ? const Color(
                              0xFFDC2626,
                            ) // Red/orange for delay & ETA
                          : (stop.isDeparted
                                ? const Color(0xFF94A3B8)
                                : AppColors.emerald),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The live in-transit callout box with dashed cyan border
  /// Matching screenshot: `🚌 Bus near Anantapur Toll (14 km to next halt)`
  Widget _buildLiveBusCallout() {
    final locationText = bus.activeLocationNotice;
    final String prefix;
    final String body;

    final lower = locationText.toLowerCase();
    if (lower.startsWith('bus near ')) {
      prefix = '🚌 Bus near ';
      body = locationText.substring(9);
    } else if (lower.startsWith('bus ')) {
      prefix = '🚌 Bus ';
      body = locationText.substring(4);
    } else if (lower.startsWith('past ') ||
        lower.startsWith('at ') ||
        lower.startsWith('between ')) {
      prefix = '🚌 Bus ';
      body = locationText;
    } else {
      prefix = '🚌 Bus near ';
      body = locationText;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical line continues through the callout
          SizedBox(
            width: 32,
            child: Center(
              child: Container(width: 2, color: const Color(0xFFCBD5E1)),
            ),
          ),

          // Dashed Blue Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 0, 20),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: const Color(
                    0xFF38BDF8,
                  ), // Cyan / sky blue dashed border
                  strokeWidth: 1.2,
                  dashWidth: 4,
                  dashSpace: 3,
                  borderRadius: 10,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF0F9FF,
                    ), // Soft light-blue background
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: prefix,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        TextSpan(
                          text: body,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF075985),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
