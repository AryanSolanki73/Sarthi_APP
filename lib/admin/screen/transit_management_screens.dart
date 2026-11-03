import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/cart_location.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';

const _green = Color(0xFF087F5B);
const _mint = Color(0xFFE7F6EF);
const _ink = Color(0xFF18231F);
const _muted = Color(0xFF7B8983);
const _line = Color(0xFFE7ECE9);
const _pageBackground = Color(0xFFF5F7F6);

class BusManagementScreen extends StatelessWidget {
  const BusManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminFirestoreListScreen(
    title: 'Bus schedules',
    subtitle: 'Bus records from the buses collection',
    collection: 'buses',
    searchHint: 'Search route or registration number...',
    searchText: (data, id) =>
        '$id ${data['route'] ?? ''} ${data['registrationNumber'] ?? ''}',
    rowBuilder: (context, doc) {
      final bus = Bus.fromDoc(doc);
      final data = doc.data();
      final registration = data['registrationNumber']?.toString();
      final route = data['route']?.toString();
      final departure = data['departureTime']?.toString();
      final availableSeats = data['availableSeats'];
      final totalSeats = data['totalSeats'];
      return _RecordCard(
        icon: Icons.directions_bus_outlined,
        title: registration?.isNotEmpty == true
            ? registration!
            : 'Registration unavailable',
        subtitle:
            '${route?.isNotEmpty == true ? route : 'Route unavailable'} · ${departure?.isNotEmpty == true ? departure : 'Departure unavailable'}',
        details: availableSeats is num && totalSeats is num
            ? 'Seats: ${availableSeats.toInt()}/${totalSeats.toInt()}'
            : 'Seat availability unavailable',
        status: data['isActive'] is bool
            ? (bus.isActive ? 'Active' : 'Inactive')
            : 'Status unavailable',
        statusGood: data['isActive'] is bool && bus.isActive,
      );
    },
  );
}

class CartLocationManagementScreen extends StatelessWidget {
  const CartLocationManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminFirestoreListScreen(
    title: 'EV cart locations',
    subtitle: 'Live location and status records; this is not a registered fleet inventory',
    collection: 'locations',
    searchHint: 'Search cart name or status...',
    searchText: (data, id) =>
        '$id ${data['name'] ?? ''} ${data['status'] ?? ''}',
    rowBuilder: (context, doc) {
      final cart = CartLocation.fromDoc(doc);
      final data = doc.data();
      final hasCoordinates =
          data['latitude'] is num && data['longitude'] is num;
      final location = hasCoordinates
          ? '${cart.latitude}, ${cart.longitude}'
          : 'Coordinates unavailable';
      final name = data['name']?.toString();
      final battery = data['batteryLevel'];
      final driverOnline = data['driverOnline'];
      return _RecordCard(
        icon: Icons.electric_car_outlined,
        title: name?.isNotEmpty == true ? name! : 'Cart name unavailable',
        subtitle: 'Location: $location',
        details:
            '${battery is num ? 'Battery: ${battery.toInt()}%' : 'Battery unavailable'} · ${driverOnline is bool ? 'Driver online: ${driverOnline ? 'Yes' : 'No'}' : 'Driver online status unavailable'}${data['updatedAt'] == null ? '' : ' · Updated ${_storedDate(data['updatedAt'])}'}',
        status: data['status']?.toString() ?? 'Status unavailable',
        statusGood: data['status'] is String && cart.isOnline,
      );
    },
  );
}

class RideManagementScreen extends StatelessWidget {
  const RideManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminFirestoreListScreen(
    title: 'Rides & bookings',
    subtitle: 'Ride requests from all users in the rides collection',
    collection: 'rides',
    searchHint: 'Search student, pickup, drop-off, or status...',
    searchText: (data, id) =>
        '$id ${data['userName'] ?? ''} ${data['userEmail'] ?? ''} ${data['pickup'] ?? ''} ${data['drop'] ?? ''} ${data['status'] ?? ''}',
    rowBuilder: (context, doc) {
      final ride = RideRequest.fromDoc(doc);
      final data = doc.data();
      final assigned = ride.assignedCartName ?? ride.assignedCartId;
      return _RecordCard(
        icon: Icons.route_outlined,
        title: '${ride.pickup} → ${ride.drop}',
        subtitle:
            '${data['userName'] ?? 'Student name unavailable'}${data['userEmail'] == null || data['userEmail'].toString().isEmpty ? '' : ' · ${data['userEmail']}'}',
        details:
            'Requested ${_storedDate(doc.data()['createdAt'])}${assigned == null || assigned.isEmpty ? '' : ' · Cart: $assigned'}',
        status: data['status']?.toString() ?? 'Status unavailable',
        statusGood:
            data['status'] is String &&
            (ride.isActive || ride.status == 'completed'),
      );
    },
  );
}

class TicketManagementScreen extends StatelessWidget {
  const TicketManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminFirestoreListScreen(
    title: 'Tickets',
    subtitle: 'Bus tickets from the tickets collection',
    collection: 'tickets',
    searchHint: 'Search ticket, student, route, or registration...',
    searchText: (data, id) {
      final bus = data['bus'];
      final busData = bus is Map<String, dynamic>
          ? bus
          : const <String, dynamic>{};
      return '$id ${data['userName'] ?? ''} ${data['userId'] ?? ''} ${busData['route'] ?? ''} ${busData['registrationNumber'] ?? ''}';
    },
    rowBuilder: (context, doc) {
      final ticket = Ticket.fromDoc(doc);
      final data = doc.data();
      final busData = data['bus'] is Map<String, dynamic>
          ? data['bus'] as Map<String, dynamic>
          : const <String, dynamic>{};
      final route = busData['route']?.toString();
      final bookedAt = _storedDate(data['bookedAt']);
      return _RecordCard(
        icon: Icons.confirmation_number_outlined,
        title: ticket.id,
        subtitle:
            '${data['userName'] ?? 'Student name unavailable'} · ${route?.isNotEmpty == true ? route : 'Route unavailable'}',
        details:
            '${busData['registrationNumber'] ?? 'Bus registration unavailable'} · Booked $bookedAt',
        status: data['isUsed'] is bool
            ? (ticket.isUsed ? 'Used' : 'Valid')
            : 'Usage status unavailable',
        statusGood: data['isUsed'] is bool && !ticket.isUsed,
      );
    },
  );
}

typedef _SearchText = String Function(Map<String, dynamic> data, String id);
typedef _RecordBuilder = Widget Function(
  BuildContext context,
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
);

class _AdminFirestoreListScreen extends StatefulWidget {
  const _AdminFirestoreListScreen({
    required this.title,
    required this.subtitle,
    required this.collection,
    required this.searchHint,
    required this.searchText,
    required this.rowBuilder,
  });

  final String title;
  final String subtitle;
  final String collection;
  final String searchHint;
  final _SearchText searchText;
  final _RecordBuilder rowBuilder;

  @override
  State<_AdminFirestoreListScreen> createState() =>
      _AdminFirestoreListScreenState();
}

class _AdminFirestoreListScreenState extends State<_AdminFirestoreListScreen> {
  final _searchController = TextEditingController();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _records;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _records = FirebaseFirestore.instance
        .collection(widget.collection)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _records = FirebaseFirestore.instance
          .collection(widget.collection)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      body: Column(
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _line)),
            ),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to Dashboard',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: _ink),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Workspace  /  ',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh records',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, color: _green),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: _green),
                      SizedBox(width: 6),
                      Text(
                        'Admin Access',
                        style: TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          color: _green,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(
                          () => _search = value.trim().toLowerCase(),
                        ),
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          prefixIcon: const Icon(Icons.search, color: _muted),
                          suffixIcon: _search.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _search = '');
                                  },
                                  icon: const Icon(Icons.close, color: _muted),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _line),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: _records,
                        builder: (context, snapshot) {
                          if (snapshot.hasError)
                            return _ListMessage(
                              icon: Icons.cloud_off_outlined,
                              message: _firestoreError(snapshot.error),
                            );
                          if (snapshot.connectionState ==
                              ConnectionState.waiting)
                            return const Padding(
                              padding: EdgeInsets.all(48),
                              child: Center(
                                child: CircularProgressIndicator(color: _green),
                              ),
                            );
                          final docs = snapshot.data?.docs ?? [];
                          final filtered = docs
                              .where(
                                (doc) =>
                                    _search.isEmpty ||
                                    widget
                                        .searchText(doc.data(), doc.id)
                                        .toLowerCase()
                                        .contains(_search),
                              )
                              .toList();
                          if (docs.isEmpty)
                            return const _ListMessage(
                              icon: Icons.inbox_outlined,
                              message: 'No records are available in this collection.',
                            );
                          if (filtered.isEmpty)
                            return const _ListMessage(
                              icon: Icons.search_off,
                              message: 'No records match your search.',
                            );
                          return Column(
                            children: filtered
                                .map(
                                  (doc) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: widget.rowBuilder(context, doc),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.status,
    required this.statusGood,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String details;
  final String status;
  final bool statusGood;

  @override
  Widget build(BuildContext context) {
    final statusColor = statusGood ? _green : const Color(0xFFA96508);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06203B2B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _green, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Record' : title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  details,
                  style: const TextStyle(color: _muted, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusGood ? _mint : const Color(0xFFFFF5DF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.isEmpty ? 'Unknown' : status,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _muted, size: 28),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 12),
        ),
      ],
    ),
  );
}

String _firestoreError(Object? error) {
  if (error is FirebaseException) {
    if (error.code == 'permission-denied' || error.code == 'unauthenticated')
      return 'Access denied. Check that Firestore rules allow this admin account to read these records.';
    if (error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed')
      return 'Could not reach Firestore. Check the network and try refreshing.';
    return 'Firestore could not load these records (${error.code}).';
  }
  return 'Could not load these records. Try refreshing.';
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _storedDate(Object? value) {
  if (value is Timestamp) return _formatDate(value.toDate());
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return _formatDate(parsed);
  }
  return 'timestamp unavailable';
}
