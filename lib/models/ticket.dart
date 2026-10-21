import 'bus.dart';

/// A ticket created after a passenger books a bus seat.
class Ticket {
  Ticket({required this.id, required this.bus, this.isUsed = false});

  final String id;
  final Bus bus;
  bool isUsed;
}
