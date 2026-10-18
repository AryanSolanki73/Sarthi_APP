import 'package:flutter/material.dart';
import 'package:sarthi_app/controllers/transit_controller.dart';
import 'package:sarthi_app/core/app_colors.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/services/transit_service.dart';
import 'package:sarthi_app/views/transit/campus_map_view.dart';

/// Main transit screen for both passengers and drivers.
///
/// It renders state from [TransitController]. Backend integration is isolated
/// in TransitService, so this UI stays unchanged when real API calls are added.
class TransitHomeView extends StatefulWidget {
  const TransitHomeView({super.key});

  @override
  State<TransitHomeView> createState() => _TransitHomeViewState();
}

class _TransitHomeViewState extends State<TransitHomeView> {
  final _controller = TransitController(MockTransitService());
  final _ticketCodeController = TextEditingController();

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
    _ticketCodeController.dispose();
    super.dispose();
  }

  void _showMessage(String text) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Material(
            color: Colors.white,
            child: _controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.emerald),
                  )
                : Column(
                    children: [
                      _header(),
                      Expanded(
                        child: _controller.isDriverView
                            ? _driverView()
                            : _passengerView(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 14, 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F1))),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.directions_bus,
          color: AppColors.emerald,
          size: 30,
        ),
        const SizedBox(width: 5),
        const Expanded(
          child: Text(
            'SARTHI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ),
        IconButton(
          onPressed: _ticketsSheet,
          icon: Badge(
            isLabelVisible: _controller.tickets.isNotEmpty,
            label: Text(
              '${_controller.tickets.where((ticket) => !ticket.isUsed).length}',
            ),
            child: const Icon(
              Icons.confirmation_number_outlined,
              color: AppColors.emerald,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: _controller.toggleRole,
          child: Text(
            _controller.isDriverView ? 'Passenger' : 'Driver View',
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ],
    ),
  );

  Widget _tab(String label, IconData icon, bool active, VoidCallback onTap) =>
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: active
                ? const Color(0xFF047857)
                : const Color(0xFF52525B),
            backgroundColor: active
                ? const Color(0xFFECFDF5)
                : const Color(0xFFFAFAFA),
          ),
        ),
      );

  Widget _passengerView() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _tab(
              'EV Carts',
              Icons.airport_shuttle_outlined,
              !_controller.isBusTab,
              () => _controller.setPassengerTab(false),
            ),
            const SizedBox(width: 8),
            _tab(
              'City Buses',
              Icons.directions_bus_outlined,
              _controller.isBusTab,
              () => _controller.setPassengerTab(true),
            ),
          ],
        ),
      ),
      Expanded(child: _controller.isBusTab ? _busList() : _cartBooking()),
    ],
  );

  Widget _cartBooking() => Column(
    children: [
      Expanded(
        child: CampusMapView(
          pickupLocation: _controller.pickup,
          dropLocation: _controller.drop,
        ),
      ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 15)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'REQUEST FREE EV CART',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA1A1AA),
                  ),
                ),
                Text(
                  '₹0 Free Ride',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _locationPicker('FROM', _controller.pickup, const [
              'Satlej Hostel',
              'Beas Hostel',
              'Brahmaputra Hostel',
              'Main Gate',
            ], _controller.setPickup),
            const SizedBox(height: 9),
            _locationPicker('TO', _controller.drop, const [
              'JC Bose Academic Block',
              'Ramanujan Complex',
              'Central Library',
              'Student Activity Center (SAC)',
            ], _controller.setDrop),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _hailCart,
              icon: const Icon(Icons.airport_shuttle),
              label: const Text('Hail Nearest Cart'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _locationPicker(
    String label,
    String value,
    List<String> choices,
    ValueChanged<String> onChanged,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFAFA),
      border: Border.all(color: const Color(0xFFE4E4E7)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1A1AA),
            ),
          ),
        ),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: choices
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (item) {
                if (item != null) onChanged(item);
              },
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _hailCart() async {
    await _controller.requestCart();
    if (mounted) {
      _showMessage('Cart hailed successfully! Nearest driver notified.');
    }
  }

  Widget _busList() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'City Shuttle Schedule',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        'Main Campus ⇄ Rupnagar / Morinda / Railway Stn',
        style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
      ),
      const SizedBox(height: 18),
      ..._controller.buses.map(_busCard),
    ],
  );

  Widget _busCard(Bus bus) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.registrationNumber,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(bus.departureTime, style: const TextStyle(fontSize: 11)),
            ],
          ),
          Text(
            bus.route,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.isFull
                    ? 'Sold Out / Full'
                    : '${bus.availableSeats} seats available',
                style: TextStyle(
                  fontSize: 11,
                  color: bus.isFull ? Colors.red : AppColors.emerald,
                  fontWeight: FontWeight.bold,
                ),
              ),
              FilledButton(
                onPressed: bus.isFull ? null : () => _bookBus(bus),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                ),
                child: const Text('Book Free Ticket'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Future<void> _bookBus(Bus bus) async {
    final ticket = await _controller.bookBus(bus);
    if (mounted) {
      _showMessage('Ticket booked: ${ticket.id}');
      _ticketsSheet();
    }
  }

  Widget _driverView() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'OPERATOR DASHBOARD',
        style: TextStyle(
          fontSize: 10,
          color: AppColors.emerald,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Driver & Bus Control',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          _tab(
            'EV Cart Dispatch',
            Icons.airport_shuttle_outlined,
            !_controller.isScannerTab,
            () => _controller.setDriverTab(false),
          ),
          const SizedBox(width: 8),
          _tab(
            'Bus Scanner',
            Icons.qr_code_scanner,
            _controller.isScannerTab,
            () => _controller.setDriverTab(true),
          ),
        ],
      ),
      const SizedBox(height: 22),
      _controller.isScannerTab ? _scanner() : _dispatch(),
    ],
  );

  Widget _dispatch() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Pending Student Requests',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      if (_controller.requests.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Center(child: Text('No active ride requests')),
          ),
        )
      else
        ..._controller.requests.map(_requestCard),
      const SizedBox(height: 18),
      const Text(
        'Capacity Status',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      Row(
        children: ['Empty', 'Filling', 'Full']
            .map(
              (value) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: value == 'Full' ? 0 : 7),
                  child: OutlinedButton(
                    onPressed: () {
                      _controller.setCapacity(value);
                      _showMessage('Capacity updated: $value');
                    },
                    child: Text(value),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ],
  );

  Widget _requestCard(RideRequest request) => Card(
    child: ListTile(
      dense: true,
      title: Text(
        '${request.pickup} → ${request.drop}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        request.createdLabel,
        style: const TextStyle(fontSize: 10),
      ),
      trailing: FilledButton(
        onPressed: () => _acceptRequest(request),
        style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
        child: const Text('Accept'),
      ),
    ),
  );

  Future<void> _acceptRequest(RideRequest request) async {
    await _controller.acceptRequest(request);
    if (mounted) _showMessage('Ride accepted!');
  }

  Widget _scanner() => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xFFD1FAE5),
            child: Icon(
              Icons.qr_code_scanner,
              color: AppColors.emerald,
              size: 32,
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Scan Student Ticket',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _ticketCodeController,
            textCapitalization: TextCapitalization.characters,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              hintText: 'Enter ticket ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _verifyTicket,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              minimumSize: const Size.fromHeight(45),
            ),
            child: const Text('Verify & Check-In Passenger'),
          ),
        ],
      ),
    ),
  );

  Future<void> _verifyTicket() async {
    final status = await _controller.verifyTicket(
      _ticketCodeController.text.trim().toUpperCase(),
    );
    _ticketCodeController.clear();
    if (!mounted) return;
    _showMessage(switch (status) {
      TicketStatus.verified => 'Ticket verified! Passenger checked in.',
      TicketStatus.alreadyUsed => 'This ticket has already been used.',
      TicketStatus.invalid => 'Invalid ticket ID. Please check again.',
    });
  }

  void _ticketsSheet() => showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 450,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'My Booked Tickets',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: _controller.tickets.isEmpty
                    ? const Center(child: Text('No tickets booked yet'))
                    : ListView(
                        children: _controller.tickets
                            .map(
                              (ticket) => Card(
                                child: ListTile(
                                  title: Text(
                                    ticket.id,
                                    style: const TextStyle(
                                      color: AppColors.emerald,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${ticket.bus.route}\n${ticket.bus.departureTime} • ${ticket.bus.registrationNumber}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    ticket.isUsed ? 'Used' : 'Valid',
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
