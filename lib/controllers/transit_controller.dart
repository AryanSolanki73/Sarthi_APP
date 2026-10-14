import 'package:flutter/foundation.dart';
import 'package:sarthi_app/models/bus.dart';
import 'package:sarthi_app/models/ride_request.dart';
import 'package:sarthi_app/models/ticket.dart';
import 'package:sarthi_app/services/transit_service.dart';

enum TicketStatus { verified, invalid, alreadyUsed }

/// Controller for passenger bookings and driver operations.
class TransitController extends ChangeNotifier {
  TransitController(this._service);

  final TransitService _service;
  bool isDriverView = false;
  bool isBusTab = false;
  bool isScannerTab = false;
  bool isLoading = true;
  String pickup = 'Satlej Hostel';
  String drop = 'JC Bose Academic Block';
  String capacity = 'Empty';
  List<Bus> buses = [];
  List<RideRequest> requests = [];
  List<Ticket> tickets = [];

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    buses = await _service.fetchBuses();
    requests = await _service.fetchRideRequests();
    isLoading = false;
    notifyListeners();
  }

  void setPassengerTab(bool showBuses) { isBusTab = showBuses; notifyListeners(); }
  void toggleRole() { isDriverView = !isDriverView; notifyListeners(); }
  void setDriverTab(bool showScanner) { isScannerTab = showScanner; notifyListeners(); }
  void setPickup(String value) { pickup = value; notifyListeners(); }
  void setDrop(String value) { drop = value; notifyListeners(); }
  void setCapacity(String value) { capacity = value; notifyListeners(); }

  Future<void> requestCart() async {
    final request = await _service.createRideRequest(pickup: pickup, drop: drop);
    requests = [request, ...requests];
    notifyListeners();
  }

  Future<void> acceptRequest(RideRequest request) async {
    await _service.acceptRideRequest(request.id);
    requests = requests.where((item) => item.id != request.id).toList();
    notifyListeners();
  }

  Future<Ticket> bookBus(Bus bus) async {
    final ticket = await _service.bookBus(bus);
    tickets = [ticket, ...tickets];
    notifyListeners();
    return ticket;
  }

  Future<TicketStatus> verifyTicket(String code) async {
    final ticket = await _service.findTicket(code);
    if (ticket == null) return TicketStatus.invalid;
    if (ticket.isUsed) return TicketStatus.alreadyUsed;
    await _service.markTicketUsed(ticket);
    notifyListeners();
    return TicketStatus.verified;
  }
}
