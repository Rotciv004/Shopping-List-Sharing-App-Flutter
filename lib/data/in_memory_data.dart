import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../models/family.dart';
import '../models/order.dart';
import '../models/app_notification.dart';
import 'local_file_database.dart';

class InMemoryData extends ChangeNotifier {
  InMemoryData._();
  static final InMemoryData instance = InMemoryData._();

  User? currentUser;

  final List<User> users = <User>[];
  final List<Family> families = <Family>[];
  final List<Order> orders = <Order>[];
  final List<AppNotification> notifications = <AppNotification>[];

  Timer? _expirationTimer;

  Future<void> initialize() async {
    final loaded = await LocalFileDatabase.loadAll();
    users
      ..clear()
      ..addAll(loaded.users);
    families
      ..clear()
      ..addAll(loaded.families);
    orders
      ..clear()
      ..addAll(loaded.orders);
    notifications
      ..clear()
      ..addAll(loaded.notifications);

    _startExpirationChecker();
    purgeExpiredOrders();
    notifyListeners();
  }

  void _startExpirationChecker() {
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      purgeExpiredOrders();
    });
  }

  Future<void> persistAll() async {
    await LocalFileDatabase.saveAll(
      users: users,
      families: families,
      orders: orders,
      notifications: notifications,
    );
  }

  // Expose a safe notifier for UI to request a refresh after local mutations
  void notify() => notifyListeners();

  void purgeExpiredOrders() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final expired = orders
        .where((o) => o.fulfillmentDeadLineDate.millisecondsSinceEpoch <= nowMs)
        .toList();
    if (expired.isEmpty) return;

    final affectedFamilyIds = <String>{};

    for (final order in expired) {
      final family = families.firstWhere(
        (f) => f.ordersList.contains(order.id),
        orElse: () => Family(name: 'Unknown'),
      );
      if (family.id != 'Unknown') {
        affectedFamilyIds.add(family.id);
        final message = order.fulfillingUserId == null
            ? 'Your order expired, and no one took it.'
            : 'Your order was not honored and has expired.';
        final n = ExpiredOrderNotification(
          familyName: family.name,
          orderName: order.name,
          quantity: order.quantity,
          allocatedSum: order.allocatedSum,
          message: message,
        );
        final exists = notifications.any((x) =>
            x is ExpiredOrderNotification &&
            x.orderName == n.orderName &&
            x.familyName == n.familyName);
        if (!exists) notifications.add(n);
        family.ordersList.remove(order.id);
      }
    }

    orders.removeWhere((o) => expired.any((e) => e.id == o.id));
    for (final f in families) {
      f.numberOfOrders = f.ordersList.length;
    }
    persistAll();
    notifyListeners();
  }

  void deleteOrderById(String orderId) {
    final family = families.firstWhere(
      (f) => f.ordersList.contains(orderId),
      orElse: () => Family(name: 'Unknown'),
    );

    if (family.id != 'Unknown') {
      family.ordersList.remove(orderId);
      family.numberOfOrders = family.ordersList.length;
    }

    orders.removeWhere((o) => o.id == orderId);
    LocalFileDatabase.saveOrders(orders);
    LocalFileDatabase.saveFamilies(families);
    notifyListeners();
  }

  void removeMemberFromFamily(String familyId, String userId,
      {String? announcerUserName}) {
    final idx = families.indexWhere((f) => f.id == familyId);
    if (idx == -1) return;
    final f = families[idx];
    if (f.membersList.contains(userId)) {
      f.membersList.remove(userId);
      f.numberOfMembers = f.membersList.length;

      notifications.add(AnnouncementNotification(
        toUserId: userId,
        familyId: f.id,
        familyName: f.name,
        message: "You have left the family '${f.name}'.",
      ));

      if (f.membersList.isEmpty) {
        orders.removeWhere((o) => f.ordersList.contains(o.id));
        families.removeAt(idx);
      }

      persistAll();
      notifyListeners();
    }
  }
}
