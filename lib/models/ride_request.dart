/// A student's request for an EV cart.
class RideRequest {
  RideRequest({
    required this.id,
    required this.pickup,
    required this.drop,
    this.createdLabel = 'Just now',
  });

  final String id;
  final String pickup;
  final String drop;
  final String createdLabel;
}
