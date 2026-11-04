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
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 2. Compact Dark GPS Live Ribbon
              _buildGpsTopBar(),

              // 3. Scrollable Content Area
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  children: [
                    // Bus Name & Speed Badge
                    _buildBusHeader(),
                    const SizedBox(height: 12),

                    // Passenger Capacity & Onboarded Status
                    _buildCapacityCard(
                      onboarded: onboarded,
                      capacity: capacity,
                      available: available,
                      occupancy: occupancy,
                    ),
                    const SizedBox(height: 14),

                    // Section Title: Active Route
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Route & Live Status',
                          style: TextStyle(
                            fontSize: 14,
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
                    const SizedBox(height: 10),

                    // Active Route Timeline
                    _buildRouteTimeline(stops),
                    const SizedBox(height: 16),

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
                        icon: const Icon(Icons.event_seat_rounded, size: 16),
                        label: Text(
                          bus.isFull
                              ? 'Bus Fully Booked'
                              : 'Book Seat ($available Available)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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

  /// Compact status ribbon ("🟢 GPS • Accurate to 5m" and "Updated 10s ago")
  Widget _buildGpsTopBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Modern dark slate
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), // Bright GPS active green
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'GPS • ${bus.gpsAccuracy}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'Updated ${bus.lastUpdated}',
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Bus Title, Route subtitle, and Speed Pill Badge
  Widget _buildBusHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bus.route,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bus.departureTime,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                  if (bus.arrivalTime != null &&
                      bus.arrivalTime!.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '→ ${bus.arrivalTime}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    bus.registrationNumber,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Builder(
          builder: (_) {
            final isStarted = bus.isTripStarted();
            if (isStarted) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0284C7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bus.speed,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Scheduled',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Capacity of On-Boarded Passengers Card (Compressed & Streamlined)
  Widget _buildCapacityCard({
    required int onboarded,
    required int capacity,
    required int available,
    required double occupancy,
  }) {
    final Color statusColor = available <= 0
        ? const Color(0xFFEF4444)
        : (occupancy >= 0.8
            ? const Color(0xFFF59E0B)
            : AppColors.emerald);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: Color(0xFF475569),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Onboarded: $onboarded / $capacity',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${(occupancy * 100).round()}% Full',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    available > 0 ? '$available left' : 'Full',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: available > 0
                          ? const Color(0xFF047857)
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: occupancy,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No stops registered for this route.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      );
    }

    final isStarted = bus.isTripStarted();

    return Column(
      children: [
        if (isStarted && stops.isNotEmpty && stops.first.isNext)
          _buildLiveBusCallout(),
        for (int i = 0; i < stops.length; i++) ...[
          _buildStopRow(
            stops[i],
            isFirst: i == 0,
            isLast: i == stops.length - 1,
          ),
          // If this is the departed stop right before the next upcoming stop,
          // render the live in-transit bus callout box (only if trip is started):
          if (isStarted &&
              stops[i].isDeparted &&
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
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Color(0xFF64748B),
          shape: BoxShape.circle,
        ),
      );
    } else if (stop.isNext) {
      // Open blue circle
      circleMarker = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0284C7), width: 2),
        ),
      );
    } else {
      // Open dark charcoal circle
      circleMarker = Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0F172A), width: 2),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left vertical timeline indicator
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting line
                if (!isLast)
                  Positioned(
                    top: 12,
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
                  padding: const EdgeInsets.only(top: 3),
                  child: circleMarker,
                ),
              ],
            ),
          ),

          // Center: Stop Name & Subtext
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 1, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    style: TextStyle(
                      fontSize: 14,
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
                    const SizedBox(height: 1),
                    Text(
                      stop.subtext!,
                      style: TextStyle(
                        fontSize: 11,
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
            padding: const EdgeInsets.fromLTRB(8, 1, 0, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (stop.scheduledTime != null)
                  Text(
                    stop.scheduledTime!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: stop.isDeparted
                          ? const Color(0xFF64748B)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                if (stop.statusText != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    stop.statusText!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: stop.isDelayed
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: stop.isDelayed
                          ? const Color(0xFFDC2626) // Red/orange for delay & ETA
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
            width: 28,
            child: Center(
              child: Container(width: 2, color: const Color(0xFFCBD5E1)),
            ),
          ),

          // Dashed Blue Container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 0, 10),
              child: CustomPaint(
                painter: DashedBorderPainter(
                  color: const Color(0xFF38BDF8), // Cyan / sky blue dashed border
                  strokeWidth: 1.2,
                  dashWidth: 4,
                  dashSpace: 3,
                  borderRadius: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF), // Soft light-blue background
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: prefix,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                        TextSpan(
                          text: body,
                          style: const TextStyle(
                            fontSize: 12,
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
