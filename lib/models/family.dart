class Family {
  final String id;
  final String name;
  final List<String> membersList;
  final List<String> ordersList;
  int numberOfMembers;
  int numberOfOrders;

  Family({
    String? id,
    required this.name,
    List<String>? membersList,
    List<String>? ordersList,
    int? numberOfMembers,
    int? numberOfOrders,
  })  : id = id ?? _uuid(),
        membersList = membersList ?? <String>[],
        ordersList = ordersList ?? <String>[],
        numberOfMembers = numberOfMembers ?? (membersList?.length ?? 0),
        numberOfOrders = numberOfOrders ?? (ordersList?.length ?? 0);

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String?,
        name: json['name'] as String,
        membersList: (json['membersList'] as List?)?.cast<String>() ?? <String>[],
        ordersList: (json['ordersList'] as List?)?.cast<String>() ?? <String>[],
        numberOfMembers: json['numberOfMembers'] as int?,
        numberOfOrders: json['numberOfOrders'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'membersList': membersList,
        'ordersList': ordersList,
        'numberOfMembers': numberOfMembers,
        'numberOfOrders': numberOfOrders,
      };
}

String _uuid() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(16)}-${(DateTime.now().millisecondsSinceEpoch % 1000000).toRadixString(16)}';
