/// Model returned by the transit API for one scheduled city bus.
class Bus {
  Bus({
    required this.id,
    required this.route,
    required this.departureTime,
    required this.availableSeats,
    required this.registrationNumber,
  });

  final String id;
  final String route;
  final String departureTime;
  final String registrationNumber;
  int availableSeats;

  bool get isFull => availableSeats <= 0;
}
