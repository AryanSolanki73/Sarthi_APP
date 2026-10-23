import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/transit_controller.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';
import 'package:sarthi_app/services/transit_service.dart';
import 'package:sarthi_app/views/profile_page.dart';
import 'package:sarthi_app/views/transit/campus_map_view.dart';

/// Main transit screen for students powered by Firebase.
class TransitHomeView extends StatefulWidget {
  const TransitHomeView({super.key});

  @override
  State<TransitHomeView> createState() => _TransitHomeViewState();
}

class _TransitHomeViewState extends State<TransitHomeView> {
  final _controller = TransitController(FirebaseTransitService());
  bool _isRequesting = false;

  static const _campusStops = [
    'Satluj Hostel',
    'Beas Hostel',
    'Ravi Hostel',
    'Chenab Hostel',
    'Mess & Cafeteria',
    'Utility Block',
    'Nalanda Library',
    'Super Academic Building',
    'J.C. Bose Block',
    'S. Ramanujan Block',
    'M2 Lecture Hall',
    'Guest House',
    'Main Gate',
  ];

  @override
  void initState() {
    super.initState();
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
              : _cartBookingForm(),
        ),
      ],
    );
  }

  Widget _activeRideCard(RideRequest ride) {
    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (ride.status) {
      case 'accepted':
        statusColor = const Color(0xFF2563EB);
        statusTitle = 'Cart Assigned & En Route';
        statusIcon = Icons.airport_shuttle;
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
            _showMessage('Ride request cancelled.');
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
                    _showMessage('EV Cart request submitted to Firebase!');
                  } catch (e) {
                    _showMessage('Failed to request cart: $e');
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

  Widget _busList() => _controller.buses.isEmpty
      ? const Center(
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
        )
      : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.buses.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final bus = _controller.buses[index];
            return _busCard(bus);
          },
        );

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
                  : () async {
                      try {
                        final ticket = await _controller.bookBus(bus);
                        _showTicketDialog(ticket);
                      } catch (e) {
                        _showMessage('Booking failed: $e');
                      }
                    },
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

  void _showTicketDialog(Ticket ticket) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.emerald, size: 26),
            SizedBox(width: 10),
            Text(
              'Ticket Confirmed',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.bus.route,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Ticket ID: ${ticket.id}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('Departure: ${ticket.bus.departureTime}'),
            Text('Bus: ${ticket.bus.registrationNumber}'),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 100,
                  color: Color(0xFF1F2937),
                ),
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
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.confirmation_number_rounded,
                                  color: AppColors.emerald,
                                  size: 32,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket.bus.route,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Departure: ${ticket.bus.departureTime} · ${ticket.bus.registrationNumber}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      Text(
                                        'Ticket: ${ticket.id}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.emerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
