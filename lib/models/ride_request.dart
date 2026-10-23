import 'package:cloud_firestore/cloud_firestore.dart';

/// A student's request for an EV cart stored in Firebase Firestore.
class RideRequest {
  RideRequest({
    required this.id,
    required this.pickup,
    required this.drop,
    required this.userId,
    this.userName = 'Student',
    this.userEmail = '',
    this.status = 'pending', // pending, accepted, in_progress, completed, cancelled
    this.assignedCartId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String pickup;
  final String drop;
  final String userId;
  final String userName;
  final String userEmail;
  final String status;
  final String? assignedCartId;
  final DateTime createdAt;

  bool get isActive =>
      status == 'pending' || status == 'accepted' || status == 'in_progress';

  String get createdLabel {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  factory RideRequest.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    DateTime created;
    if (map['createdAt'] is Timestamp) {
      created = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      created = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      created = DateTime.now();
    }

    return RideRequest(
      id: doc.id,
      pickup: map['pickup'] as String? ?? '',
      drop: map['drop'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Student',
      userEmail: map['userEmail'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      assignedCartId: map['assignedCartId'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
    'pickup': pickup,
    'drop': drop,
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'status': status,
    'assignedCartId': assignedCartId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
