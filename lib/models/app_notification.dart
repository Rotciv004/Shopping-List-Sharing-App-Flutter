abstract class AppNotification {
  String get id;

  const AppNotification();

  Map<String, dynamic> toJson();

  static AppNotification fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String?) {
      case 'expired':
        return ExpiredOrderNotification(
          id: json['id'] as String?,
          familyName: json['familyName'] as String? ?? '',
          orderName: json['orderName'] as String? ?? '',
          message: json['message'] as String? ?? '',
          quantity: (json['quantity'] as num?)?.toInt() ?? 0,
          allocatedSum: (json['allocatedSum'] as num?)?.toDouble() ?? 0.0,
        );
      case 'invite':
        return FamilyInviteNotification(
          id: json['id'] as String?,
          fromUser: json['fromUser'] as String? ?? '',
          toUserId: json['toUserId'] as String? ?? '',
          familyId: json['familyId'] as String? ?? '',
          familyName: json['familyName'] as String? ?? '',
        );
      case 'announcement':
      default:
        return AnnouncementNotification(
          id: json['id'] as String?,
          toUserId: json['toUserId'] as String?,
          familyId: json['familyId'] as String?,
          familyName: json['familyName'] as String?,
          message: json['message'] as String? ?? '',
        );
    }
  }
}

class ExpiredOrderNotification extends AppNotification {
  @override
  final String id;
  final String familyName;
  final String orderName;
  final String message;
  final int quantity;
  final double allocatedSum;

  ExpiredOrderNotification({
    String? id,
    required this.familyName,
    required this.orderName,
    required this.message,
    required this.quantity,
    required this.allocatedSum,
  }) : id = id ?? _uuid();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'expired',
        'id': id,
        'familyName': familyName,
        'orderName': orderName,
        'message': message,
        'quantity': quantity,
        'allocatedSum': allocatedSum,
      };
}

class FamilyInviteNotification extends AppNotification {
  @override
  final String id;
  final String fromUser;
  final String toUserId;
  final String familyId;
  final String familyName;

  FamilyInviteNotification({
    String? id,
    required this.fromUser,
    required this.toUserId,
    required this.familyId,
    required this.familyName,
  }) : id = id ?? _uuid();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'invite',
        'id': id,
        'fromUser': fromUser,
        'toUserId': toUserId,
        'familyId': familyId,
        'familyName': familyName,
      };
}

class AnnouncementNotification extends AppNotification {
  @override
  final String id;
  final String? toUserId;
  final String? familyId;
  final String? familyName;
  final String message;

  AnnouncementNotification({
    String? id,
    this.toUserId,
    this.familyId,
    this.familyName,
    required this.message,
  }) : id = id ?? _uuid();

  @override
  Map<String, dynamic> toJson() => {
        'type': 'announcement',
        'id': id,
        'toUserId': toUserId,
        'familyId': familyId,
        'familyName': familyName,
        'message': message,
      };
}

String _uuid() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(16) +
    '-' +
    (DateTime.now().millisecondsSinceEpoch % 1000000).toRadixString(16);
