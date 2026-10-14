import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';

/// Contract between the app and the future transit backend.
///
/// Replace [MockTransitService] with an HTTP implementation later. Views and
/// controllers will continue using this interface and will not need API code.
abstract class TransitService {
  Future<List<Bus>> fetchBuses();
  Future<List<RideRequest>> fetchRideRequests();
  Future<RideRequest> createRideRequest({required String pickup, required String drop});
  Future<void> acceptRideRequest(String requestId);
  Future<Ticket> bookBus(Bus bus);
  Future<Ticket?> findTicket(String ticketId);
  Future<void> markTicketUsed(Ticket ticket);
}

/// Temporary in-memory data source for frontend development.
class MockTransitService implements TransitService {
  final _buses = <Bus>[
    Bus(id: 'bus-1', route: 'Main Campus → Rupnagar City Centre', departureTime: '02:30 PM', availableSeats: 14, registrationNumber: 'PB-12-A-4019'),
    Bus(id: 'bus-2', route: 'Main Campus → Morinda Railway Station', departureTime: '04:15 PM', availableSeats: 6, registrationNumber: 'PB-12-B-8821'),
    Bus(id: 'bus-3', route: 'Main Campus → Chandigarh ISBT (Weekend)', departureTime: '06:00 PM', availableSeats: 0, registrationNumber: 'PB-12-C-1092'),
  ];
  final _requests = <RideRequest>[
    RideRequest(id: 'request-1', pickup: 'Satlej Hostel', drop: 'JC Bose Block'),
    RideRequest(id: 'request-2', pickup: 'Beas Hostel', drop: 'Central Library', createdLabel: '2 mins ago'),
  ];
  final _tickets = <Ticket>[];

  @override
  Future<List<Bus>> fetchBuses() async => List.of(_buses);

  @override
  Future<List<RideRequest>> fetchRideRequests() async => List.of(_requests);

  @override
  Future<RideRequest> createRideRequest({required String pickup, required String drop}) async {
    final request = RideRequest(id: 'request-${DateTime.now().microsecondsSinceEpoch}', pickup: pickup, drop: drop);
    _requests.insert(0, request);
    return request;
  }

  @override
  Future<void> acceptRideRequest(String requestId) async {
    _requests.removeWhere((request) => request.id == requestId);
  }

  @override
  Future<Ticket> bookBus(Bus bus) async {
    final ticket = Ticket(id: 'TKT-${1000 + DateTime.now().microsecond % 9000}', bus: bus);
    _tickets.insert(0, ticket);
    return ticket;
  }

  @override
  Future<Ticket?> findTicket(String ticketId) async {
    for (final ticket in _tickets) {
      if (ticket.id == ticketId) return ticket;
    }
    return null;
  }

  @override
  Future<void> markTicketUsed(Ticket ticket) async {
    ticket.isUsed = true;
    if (ticket.bus.availableSeats > 0) ticket.bus.availableSeats--;
  }
}
