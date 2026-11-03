import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/transit_controller.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';
import 'package:sarthi_app/services/transit_service.dart';
import 'package:sarthi_app/views/profile_page.dart';
import 'package:sarthi_app/views/transit/campus_map_view.dart';
import 'package:sarthi_app/views/widgets/qr_code_widget.dart';

/// Main transit screen for students powered by Firebase.
class TransitHomeView extends StatefulWidget {
  const TransitHomeView({super.key});

  @override
  State<TransitHomeView> createState() => _TransitHomeViewState();
}

class _TransitHomeViewState extends State<TransitHomeView> {
  final _controller = TransitController(FirebaseTransitService());
  bool _isRequesting = false;
  final Set<String> _dismissedNoticeRideIds = {};

  /// Dynamic campus stops derived directly from CampusMapView.campusLocations
  List<String> get _campusStops => CampusMapView.stopNames;

  @override
  void initState() {
    super.initState();
    if (_campusStops.isNotEmpty) {
      if (!_campusStops.contains(_controller.pickup)) {
        _controller.pickup = _campusStops.first;
      }
      if (!_campusStops.contains(_controller.drop)) {
        _controller.drop =
            _campusStops.length > 1 ? _campusStops[1] : _campusStops.first;
      }
    }
    _controller.addListener(_refresh);
    _controller.load();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF9FAFB),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Material(
            color: Colors.white,
            child: _controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.emerald),
                  )
                : Column(
                    children: [
                      _header(),
                      Expanded(child: _passengerView()),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: AppColors.emerald,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SARTHI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'IIT Ropar Transit',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _ticketsSheet,
          tooltip: 'My Tickets',
          icon: Badge(
            isLabelVisible: _controller.tickets.isNotEmpty,
            label: Text(
              '${_controller.tickets.where((ticket) => !ticket.isUsed).length}',
            ),
            backgroundColor: AppColors.emerald,
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.emerald,
              size: 26,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => const ProfilePage())),
          icon: const Icon(
            Icons.account_circle_outlined,
            color: Color(0xFF4B5563),
            size: 28,
          ),
          tooltip: 'Profile',
        ),
      ],
    ),
  );

  Widget _tab(String label, IconData icon, bool active, VoidCallback onTap) =>
      Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.emerald : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? AppColors.emerald : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: active
                        ? const Color(0xFF065F46)
                        : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _passengerView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            _tab(
              'EV Carts',
              Icons.airport_shuttle_rounded,
              !_controller.isBusTab,
              () => _controller.setPassengerTab(false),
            ),
            const SizedBox(width: 10),
            _tab(
              'City Buses',
              Icons.directions_bus_rounded,
              _controller.isBusTab,
              () => _controller.setPassengerTab(true),
            ),
          ],
        ),
      ),
      Expanded(child: _controller.isBusTab ? _busList() : _cartBooking()),
    ],
  );

  Widget _cartBooking() {
    final activeRide = _controller.activeRide;
    RideRequest? latestNoticeRide;
    if (activeRide == null) {
      for (final r in _controller.rides) {
        if ((r.status == 'rejected' || r.status == 'completed' || r.status == 'cancelled') &&
            !_dismissedNoticeRideIds.contains(r.id) &&
            DateTime.now().difference(r.createdAt).inMinutes < 60) {
          latestNoticeRide = r;
          break;
        }
      }
    }

    return Column(
      children: [
        Expanded(
          child: CampusMapView(
            pickupLocation: _controller.pickup,
            dropLocation: _controller.drop,
            cartLocations: _controller.cartLocations,
            onSelectStop: (stop) {
              if (stop != _controller.pickup) {
                _controller.setDrop(stop);
              }
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: activeRide != null
              ? _activeRideCard(activeRide)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (latestNoticeRide != null)
                      _rideNoticeBanner(latestNoticeRide),
                    _cartBookingForm(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _rideNoticeBanner(RideRequest ride) {
    final isRejected = ride.status == 'rejected';
    final isCancelled = ride.status == 'cancelled';

    Color bgColor;
    Color borderColor;
    Color titleColor;
    Color subColor;
    IconData iconData;
    String title;
    String message;

    if (isRejected) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      titleColor = const Color(0xFF991B1B);
      subColor = const Color(0xFFB91C1C);
      iconData = Icons.cancel_outlined;
      title = 'Ride Request Declined';
      message = 'The driver was unable to accept your ride from ${ride.pickup} to ${ride.drop}. You can try requesting again.';
    } else if (isCancelled) {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      titleColor = const Color(0xFFB45309);
      subColor = const Color(0xFF92400E);
      iconData = Icons.info_outline_rounded;
      title = 'Ride Request Cancelled';
      message = 'Your ride request from ${ride.pickup} to ${ride.drop} has been cancelled.';
    } else {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      titleColor = const Color(0xFF065F46);
      subColor = const Color(0xFF047857);
      iconData = Icons.check_circle_outline;
      title = 'Ride Completed!';
      message = 'You arrived at ${ride.drop}. Thank you for traveling with Sarthi!';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(iconData, color: titleColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _dismissedNoticeRideIds.add(ride.id)),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: titleColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeRideCard(RideRequest ride) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (ride.status) {
      case 'accepted':
        statusColor = const Color(0xFF2563EB);
        statusTitle = (ride.assignedCartName != null && ride.assignedCartName!.isNotEmpty)
            ? '${ride.assignedCartName} En Route'
            : 'Cart Assigned & En Route';
        statusIcon = Icons.airport_shuttle;
        break;
      case 'arriving':
        statusColor = const Color(0xFF7C3AED);
        statusTitle = 'Cart Arrived at Pickup';
        statusIcon = Icons.location_on;
        break;
      case 'in_progress':
        statusColor = AppColors.emerald;
        statusTitle = 'Ride in Progress';
        statusIcon = Icons.navigation;
        break;
      default:
        statusColor = const Color(0xFFD97706);
        statusTitle = 'Searching for Nearest EV Cart...';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (ride.assignedCartName != null &&
                      ride.assignedCartName!.isNotEmpty &&
                      ride.status != 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        'Assigned: ${ride.assignedCartName}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  Text(
                    'Requested ${ride.createdLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: AppColors.emerald, size: 10),
                  const SizedBox(width: 8),
                  const Text(
                    'Pickup: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      ride.pickup,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Drop: ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Expanded(
                    child: Text(
                      ride.drop,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () async {
            await _controller.cancelActiveRide(ride.id);
          },
          icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
          label: const Text(
            'Cancel Request',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _cartBookingForm() => Container(
    margin: const EdgeInsets.all(5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Hail Campus EV Cart',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Free Campus Shuttle',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _stopDropdown(
          label: 'Pickup Point',
          icon: Icons.my_location,
          iconColor: AppColors.emerald,
          value: _controller.pickup,
          onChanged: (val) {
            if (val != null) _controller.setPickup(val);
          },
        ),
        const SizedBox(height: 10),
        _stopDropdown(
          label: 'Drop Location',
          icon: Icons.location_on,
          iconColor: Colors.redAccent,
          value: _controller.drop,
          onChanged: (val) {
            if (val != null) _controller.setDrop(val);
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isRequesting
              ? null
              : () async {
                  if (_controller.pickup == _controller.drop) {
                    _showMessage(
                      'Pickup and Drop cannot be the same location.',
                    );
                    return;
                  }
                  setState(() => _isRequesting = true);
                  try {
                    await _controller.requestCart();
                    _showMessage('EV Cart requested successfully!');
                  } catch (e) {
                    debugPrint('Failed to request cart: $e');
                  } finally {
                    if (mounted) setState(() => _isRequesting = false);
                  }
                },
          icon: _isRequesting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.flash_on, color: Colors.white),
          label: Text(
            _isRequesting ? 'Requesting...' : 'Request EV Cart Now',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 2,
          ),
        ),
      ],
    ),
  );
  Widget _stopDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    required ValueChanged<String?> onChanged,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF9FAFB),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _campusStops.contains(value) ? value : _campusStops.first,
              items: _campusStops
                  .map(
                    (stop) => DropdownMenuItem(
                      value: stop,
                      child: Text(
                        stop,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _busList() {
    final activeTickets = _controller.tickets.where((t) => !t.isConfirmed).toList();
    final latestActiveTicket = activeTickets.isNotEmpty
        ? activeTickets.first
        : (_controller.tickets.isNotEmpty ? _controller.tickets.first : null);

    if (_controller.buses.isEmpty && latestActiveTicket == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12),
            Text(
              'No scheduled buses found',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (latestActiveTicket != null) ...[
          _activeBusTicketBanner(latestActiveTicket),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scheduled Campus Buses',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_controller.tickets.isNotEmpty)
              GestureDetector(
                onTap: _ticketsSheet,
                child: Text(
                  'My Tickets (${_controller.tickets.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emerald,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (final bus in _controller.buses) ...[
          _busCard(bus),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _activeBusTicketBanner(Ticket ticket) {
    final isConfirmed = ticket.isConfirmed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFEFF6FF) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConfirmed ? const Color(0xFFBFDBFE) : const Color(0xFFA7F3D0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isConfirmed ? Icons.verified_rounded : Icons.qr_code_2_rounded,
                    color: isConfirmed ? const Color(0xFF2563EB) : AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConfirmed ? 'Boarding Confirmed' : 'Active Bus Ticket',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isConfirmed ? const Color(0xFF1E40AF) : const Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConfirmed ? const Color(0xFFDBEAFE) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isConfirmed ? 'BOARDED' : 'VALID PASS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isConfirmed ? const Color(0xFF1D4ED8) : const Color(0xFF15803D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.bus.route,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${ticket.pickup} ➔ ${ticket.destination}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Departure: ${ticket.bus.departureTime} · Bus: ${ticket.bus.registrationNumber}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showTicketDialog(ticket),
              icon: Icon(
                isConfirmed ? Icons.visibility_outlined : Icons.qr_code_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                isConfirmed ? 'View Boarding Receipt' : 'Show QR Ticket to Driver',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isConfirmed ? const Color(0xFF2563EB) : AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _busCard(Bus bus) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppColors.emerald,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bus.departureTime,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              bus.registrationNumber,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          bus.route,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_seat_rounded,
                  size: 18,
                  color: bus.isFull ? Colors.redAccent : AppColors.emerald,
                ),
                const SizedBox(width: 6),
                Text(
                  bus.isFull
                      ? 'Full (0 Seats)'
                      : '${bus.availableSeats} of ${bus.totalSeats} seats available',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: bus.isFull
                        ? Colors.redAccent
                        : const Color(0xFF374151),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: bus.isFull
                  ? null
                  : () => _openBookSeatModal(bus),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Book Seat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _openBookSeatModal(Bus bus) {
    final stops = bus.availableStops;
    String selectedPickup = stops.isNotEmpty ? stops.first : 'Main Campus';
    String selectedDrop = stops.length > 1 ? stops.last : selectedPickup;
    bool isBooking = false;
    String? errorMsg;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bCtx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final isSameStop = selectedPickup == selectedDrop;

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.emerald,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.route,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Departure: ${bus.departureTime} · ${bus.registrationNumber}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FDF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_seat_rounded,
                          size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 6),
                      Text(
                        '${bus.availableSeats} of ${bus.totalSeats} seats remaining',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Select Boarding & Destination Stops',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F46),
                  ),
                ),
                const SizedBox(height: 10),
                // Pickup Stop
                _stopPickerDropdown(
                  label: 'Boarding Point (Pickup)',
                  icon: Icons.trip_origin_rounded,
                  iconColor: AppColors.emerald,
                  value: selectedPickup,
                  options: stops,
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedPickup = val;
                        errorMsg = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
                // Destination Stop
                _stopPickerDropdown(
                  label: 'Destination (Drop-off)',
                  icon: Icons.location_on_rounded,
                  iconColor: Colors.redAccent,
                  value: selectedDrop,
                  options: stops,
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() {
                        selectedDrop = val;
                        errorMsg = null;
                      });
                    }
                  },
                ),
                if (isSameStop) ...[
                  const SizedBox(height: 8),
                  const Text(
                    '⚠ Boarding point and destination must be different.',
                    style: TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorMsg!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (isSameStop || isBooking)
                      ? null
                      : () async {
                          setModalState(() {
                            isBooking = true;
                            errorMsg = null;
                          });
                          try {
                            final ticket = await _controller.bookBus(
                              bus,
                              pickup: selectedPickup,
                              destination: selectedDrop,
                            );
                            if (mounted) {
                              Navigator.pop(bCtx);
                              _showTicketDialog(ticket);
                            }
                          } catch (e) {
                            setModalState(() {
                              isBooking = false;
                              errorMsg = 'Failed to book seat: $e';
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isBooking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Seat & Generate Ticket',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _stopPickerDropdown({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final validValue = options.contains(value) ? value : options.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: validValue,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF9CA3AF), size: 20),
                items: options.map((s) {
                  return DropdownMenuItem<String>(
                    value: s,
                    child: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDialog(Ticket ticket) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  ticket.isConfirmed
                      ? Icons.verified_rounded
                      : Icons.check_circle,
                  color: ticket.isConfirmed
                      ? const Color(0xFF2563EB)
                      : AppColors.emerald,
                  size: 26,
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.isConfirmed ? 'Ticket Boarded' : 'Ticket Confirmed',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: ticket.isConfirmed
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ticket.isConfirmed ? 'BOARDED' : 'VALID',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ticket.isConfirmed
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              ticket.bus.route,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Departure: ${ticket.bus.departureTime} · ${ticket.bus.registrationNumber}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            // Pickup and destination chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: AppColors.emerald, size: 8),
                      const SizedBox(width: 6),
                      const Text(
                        'Pickup: ',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          ticket.pickup,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.redAccent, size: 10),
                      const SizedBox(width: 6),
                      const Text(
                        'Drop: ',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Expanded(
                        child: Text(
                          ticket.destination,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Live scannable QR Code
            QrCodeWidget(
              data: ticket.id,
              size: 190,
              showCenterBadge: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
              ),
              child: Text(
                ticket.id,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.emerald,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ticket.isConfirmed
                  ? '✓ Verified by driver. Welcome aboard!'
                  : 'Show this QR code to the driver upon boarding to verify.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: ticket.isConfirmed
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                color: AppColors.emerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _ticketsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'My Transit Tickets',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Stored securely in Firebase',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _controller.tickets.isEmpty
                    ? const Center(
                        child: Text(
                          'No tickets booked yet.',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: _controller.tickets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = _controller.tickets[index];
                          return Material(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _showTicketDialog(ticket);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      ticket.isConfirmed
                                          ? Icons.verified_rounded
                                          : Icons.confirmation_number_rounded,
                                      color: ticket.isConfirmed
                                          ? const Color(0xFF2563EB)
                                          : AppColors.emerald,
                                      size: 32,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  ticket.bus.route,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: ticket.isConfirmed
                                                      ? const Color(0xFFDBEAFE)
                                                      : const Color(0xFFDCFCE7),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  ticket.isConfirmed
                                                      ? 'BOARDED'
                                                      : 'VALID',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                    color: ticket.isConfirmed
                                                        ? const Color(0xFF1D4ED8)
                                                        : const Color(0xFF15803D),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${ticket.pickup} ➔ ${ticket.destination}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Departure: ${ticket.bus.departureTime} · ${ticket.bus.registrationNumber}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Ticket: ${ticket.id}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: ticket.isConfirmed
                                                  ? const Color(0xFF2563EB)
                                                  : AppColors.emerald,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 16,
                                            color: AppColors.emerald,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'QR',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.emerald,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
