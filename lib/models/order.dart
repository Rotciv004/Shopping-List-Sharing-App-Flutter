enum Priority { NEW, LOW, MEDIUM, HIGH }

enum Status { NEW, IN_PROGRESS, COMPLETED, CANCELLED }

class Order {
  final String id;
  final String name;
  final String description;
  final int quantity;
  final Priority priority;
  Status status;
  final String placingUserId;
  String? fulfillingUserId;
  final double allocatedSum;
  final DateTime datePlaced;
  final DateTime fulfillmentDeadLineDate;

  Order({
    String? id,
    required this.name,
    required this.description,
    required this.quantity,
    this.priority = Priority.NEW,
    this.status = Status.NEW,
    required this.placingUserId,
    this.fulfillingUserId,
    this.allocatedSum = 0.0,
    DateTime? datePlaced,
    DateTime? fulfillmentDeadLineDate,
  })  : id = id ?? _uuid(),
        datePlaced = datePlaced ?? DateTime.now(),
        fulfillmentDeadLineDate = fulfillmentDeadLineDate ?? DateTime.now();

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String?,
        name: json['name'] as String,
        description: json['description'] as String,
        quantity: (json['quantity'] as num).toInt(),
        priority: _priorityFrom(json['priority'] as String?),
        status: _statusFrom(json['status'] as String?),
        placingUserId: json['placingUserId'] as String,
        fulfillingUserId: json['fulfillingUserId'] as String?,
        allocatedSum: (json['allocatedSum'] as num?)?.toDouble() ?? 0.0,
        datePlaced: DateTime.fromMillisecondsSinceEpoch(
            (json['datePlaced'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
        fulfillmentDeadLineDate: DateTime.fromMillisecondsSinceEpoch(
            (json['fulfillmentDeadLineDate'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'quantity': quantity,
        'priority': priority.name,
        'status': status.name,
        'placingUserId': placingUserId,
        'fulfillingUserId': fulfillingUserId,
        'allocatedSum': allocatedSum,
        'datePlaced': datePlaced.millisecondsSinceEpoch,
        'fulfillmentDeadLineDate': fulfillmentDeadLineDate.millisecondsSinceEpoch,
      };
}

Priority _priorityFrom(String? name) {
  switch (name) {
    case 'LOW':
      return Priority.LOW;
    case 'MEDIUM':
      return Priority.MEDIUM;
    case 'HIGH':
      return Priority.HIGH;
    default:
      return Priority.NEW;
  }
}

Status _statusFrom(String? name) {
  switch (name) {
    case 'IN_PROGRESS':
      return Status.IN_PROGRESS;
    case 'COMPLETED':
      return Status.COMPLETED;
    case 'CANCELLED':
      return Status.CANCELLED;
    default:
      return Status.NEW;
  }
}

String _uuid() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(DateTime.now().millisecondsSinceEpoch % 1000000).toRadixString(16)}';
