import 'dart:async';

import 'package:flutter/material.dart';
import '../utils/logger.dart';

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
    Log.i('InMemoryData.initialize()', tag: 'DATA');
    LoadedData loaded;
    try {
      loaded = await LocalFileDatabase.loadAll();
    } catch (_) {
      loaded = LoadedData(users: [], families: [], orders: [], notifications: []);
    }
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

    // Fix all family counts after loading data
    _fixAllFamilyCounts();

    // Seed demo data on first run to help visualize the flow
    if (users.isEmpty && families.isEmpty && orders.isEmpty) {
      Log.i('Seeding initial demo data', tag: 'DATA');
      _seedInitialData();
      await persistAll();
    }

    _startExpirationChecker();
    purgeExpiredOrders();
    notifyListeners();
  }

  // Auth
  bool signIn(String email, String password) {
    Log.i('signIn(email=$email)', tag: 'DATA');
    final u = users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase() && u.password == password,
      orElse: () => User(lastName: '', firstName: '', email: '', password: ''),
    );
    if (u.email.isEmpty) return false;
    currentUser = u;
    _fixUserFamilies();
    notifyListeners();
    return true;
  }

  String? register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? bankAccount,
  }) {
    Log.i('register(email=$email)', tag: 'DATA');
    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) return 'Email already registered';
    final u = User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
      bankAccount: bankAccount,
    );
    users.add(u);
    currentUser = u;
    LocalFileDatabase.saveUsers(users);
    notifyListeners();
    return null;
  }

  void signOut() {
    Log.i('signOut()', tag: 'DATA');
    currentUser = null;
    notifyListeners();
  }

  // Families
  void addFamily(String name) {
    Log.i('addFamily(name=$name)', tag: 'DATA');
    final userId = currentUser?.id;
    if (userId == null) return;
    final f = Family(
      name: name,
      membersList: [userId],
      numberOfMembers: 1,
    );
    families.add(f);
    persistAll();
    notifyListeners();
  }

  // Add member to family by email
  String? addMemberToFamily(String familyId, String email) {
    Log.i('addMemberToFamily(familyId=$familyId, email=$email)', tag: 'DATA');
    final famIndex = families.indexWhere((f) => f.id == familyId);
    if (famIndex == -1) return 'Family not found';
    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => User(lastName: '', firstName: '', email: '', password: ''),
    );
    if (user.email.isEmpty) return 'No user with this email';
    if (families[famIndex].membersList.contains(user.id)) return 'User already a member';
    families[famIndex].membersList.add(user.id);
    families[famIndex].numberOfMembers = families[famIndex].membersList.length;
    notifications.add(AnnouncementNotification(
      toUserId: user.id,
      familyId: families[famIndex].id,
      familyName: families[famIndex].name,
      message: 'You have been added to the family "${families[famIndex].name}".',
    ));
    persistAll();
    notifyListeners();
    return null;
  }

  // Orders
  void createOrder({
    required String familyId,
    required String name,
    required String description,
    required int quantity,
    Priority priority = Priority.NEW,
    Status status = Status.NEW,
    required String placingUserId,
    String? fulfillingUserId,
    double allocatedSum = 0.0,
    DateTime? deadline,
  }) {
    Log.i('createOrder(familyId=$familyId, name=$name)', tag: 'DATA');
    final order = Order(
      name: name,
      description: description,
      quantity: quantity,
      priority: priority,
      status: status,
      placingUserId: placingUserId,
      fulfillingUserId: fulfillingUserId,
      allocatedSum: allocatedSum,
      fulfillmentDeadLineDate: deadline,
    );
    orders.add(order);
    final idx = families.indexWhere((f) => f.id == familyId);
    if (idx != -1) {
      families[idx].ordersList.add(order.id);
      families[idx].numberOfOrders = families[idx].ordersList.length;
    }
    persistAll();
    notifyListeners();
  }

  bool updateOrder(Order updated) {
    Log.i('updateOrder(${updated.id})', tag: 'DATA');
    final idx = orders.indexWhere((o) => o.id == updated.id);
    if (idx == -1) return false;
    orders[idx] = updated;
    persistAll();
    notifyListeners();
    return true;
  }

  // Delete only if requester is the creator; create notification
  bool deleteOrderByIdIfCreator(String orderId, String requesterUserId) {
    Log.i('deleteOrderByIdIfCreator(orderId=$orderId, requester=$requesterUserId)', tag: 'DATA');
    final orderObj = orders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => Order(name: '', description: '', quantity: 0, placingUserId: ''),
    );
    if (orderObj.name.isEmpty) return false;
    if (orderObj.placingUserId != requesterUserId) return false;

    final family = families.firstWhere(
      (f) => f.ordersList.contains(orderId),
      orElse: () => Family(name: 'Unknown'),
    );

    if (family.id != 'Unknown') {
      family.ordersList.remove(orderId);
      family.numberOfOrders = family.ordersList.length;
    }
    orders.removeWhere((o) => o.id == orderId);

    notifications.add(AnnouncementNotification(
      familyId: family.id == 'Unknown' ? null : family.id,
      familyName: family.id == 'Unknown' ? null : family.name,
      message: 'Order "${orderObj.name}" was deleted by its creator.',
    ));

    persistAll();
    notifyListeners();
    return true;
  }

  void _startExpirationChecker() {
    Log.i('Start expiration checker', tag: 'DATA');
    _expirationTimer?.cancel();
    _expirationTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      Log.i('Timer tick -> purgeExpiredOrders()', tag: 'DATA');
      purgeExpiredOrders();
    });
  }

  Future<void> persistAll() async {
    Log.i('Persist all tables', tag: 'DATA');
    await LocalFileDatabase.saveAll(
      users: users,
      families: families,
      orders: orders,
      notifications: notifications,
    );
  }

  // Expose a safe notifier for UI to request a refresh after local mutations
  void notify() => notifyListeners();

  // Notifications
  void deleteNotificationById(String id) {
    Log.i('deleteNotificationById($id)', tag: 'DATA');
    notifications.removeWhere((n) => n.id == id);
    LocalFileDatabase.saveNotifications(notifications);
    notifyListeners();
  }

  void clearAllNotifications() {
    Log.i('clearAllNotifications()', tag: 'DATA');
    notifications.clear();
    LocalFileDatabase.saveNotifications(notifications);
    notifyListeners();
  }

  void purgeExpiredOrders() {
    Log.i('purgeExpiredOrders()', tag: 'DATA');
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
    Log.i('deleteOrderById($orderId)', tag: 'DATA');
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
    Log.i('removeMemberFromFamily(familyId=$familyId, userId=$userId)', tag: 'DATA');
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

  // Update current user's profile details, ensuring unique email
  String? updateCurrentUser({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
    String? bankAccount,
  }) {
    final cu = currentUser;
    if (cu == null) return 'Not signed in';
    final newEmail = email?.trim();
    if (newEmail != null && newEmail.toLowerCase() != cu.email.toLowerCase()) {
      final exists = users.any((u) => u.email.toLowerCase() == newEmail.toLowerCase());
      if (exists) return 'Email already registered';
    }
    final updated = User(
      id: cu.id,
      firstName: firstName ?? cu.firstName,
      lastName: lastName ?? cu.lastName,
      email: newEmail ?? cu.email,
      password: password ?? cu.password,
      bankAccount: bankAccount ?? cu.bankAccount,
    );
    final idx = users.indexOf(cu);
    if (idx != -1) {
      users[idx] = updated;
    }
    currentUser = updated;
    persistAll();
    notifyListeners();
    return null;
  }
  void _seedInitialData() {
    final demoUser = User(
      firstName: 'John',
      lastName: 'Doe',
      email: 'test@example.com',
      password: '1234',
    );
    users.add(demoUser);

    final fam = Family(name: 'Demo Family', membersList: [demoUser.id], ordersList: []);
    families.add(fam);

    final order = Order(
      name: 'Milk',
      description: '2% Fat, 1L',
      quantity: 2,
      priority: Priority.MEDIUM,
      placingUserId: demoUser.id,
      allocatedSum: 15.0,
      fulfillmentDeadLineDate: DateTime.now().add(const Duration(days: 1)),
    );
    orders.add(order);
    fam.ordersList.add(order.id);
    fam.numberOfOrders = fam.ordersList.length;
  }

  void _fixAllFamilyCounts() {
    Log.i('Fixing all family counts on startup', tag: 'DATA');
    bool needsSave = false;
    
    for (final family in families) {
      // Fix member counts to match actual list length
      final correctMemberCount = family.membersList.length;
      if (family.numberOfMembers != correctMemberCount) {
        Log.i('Fixing member count for ${family.name}: ${family.numberOfMembers} -> $correctMemberCount', tag: 'DATA');
        family.numberOfMembers = correctMemberCount;
        needsSave = true;
      }
      
      // Fix order counts to match actual list length  
      final correctOrderCount = family.ordersList.length;
      if (family.numberOfOrders != correctOrderCount) {
        Log.i('Fixing order count for ${family.name}: ${family.numberOfOrders} -> $correctOrderCount', tag: 'DATA');
        family.numberOfOrders = correctOrderCount;
        needsSave = true;
      }
    }
    
    if (needsSave) {
      Log.i('Saving corrected family data', tag: 'DATA');
      LocalFileDatabase.saveFamilies(families);
    }
  }

  void _fixUserFamilies() {
    Log.i('Fixing families for current user', tag: 'DATA');
    bool needsSave = false;
    
    for (final family in families) {
      // Fix member counts to match actual list length
      final correctCount = family.membersList.length;
      if (family.numberOfMembers != correctCount) {
        Log.i('Fixing member count for ${family.name}: ${family.numberOfMembers} -> $correctCount', tag: 'DATA');
        family.numberOfMembers = correctCount;
        needsSave = true;
      }
      
      // Fix order counts to match actual list length
      final correctOrderCount = family.ordersList.length;
      if (family.numberOfOrders != correctOrderCount) {
        Log.i('Fixing order count for ${family.name}: ${family.numberOfOrders} -> $correctOrderCount', tag: 'DATA');
        family.numberOfOrders = correctOrderCount;
        needsSave = true;
      }
    }
    
    if (needsSave) {
      Log.i('Saving corrected family data', tag: 'DATA');
      LocalFileDatabase.saveFamilies(families);
    }
  }
}
