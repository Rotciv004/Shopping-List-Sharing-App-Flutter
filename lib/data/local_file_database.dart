import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/user.dart';
import '../models/family.dart';
import '../models/order.dart';
import '../models/app_notification.dart';

class LocalFileDatabase {
  static const _usersFile = 'users.txt';
  static const _familiesFile = 'families.txt';
  static const _ordersFile = 'orders.txt';
  static const _notificationsFile = 'notifications.txt';

  static Future<Directory> _dir() async {
    final dir = await getApplicationDocumentsDirectory();
    return dir;
  }

  static Future<File> _file(String name) async {
    final dir = await _dir();
    return File('${dir.path}/$name');
  }

  static Future<void> _write(String name, String content) async {
    final f = await _file(name);
    await f.writeAsString(content, flush: true);
  }

  static Future<String?> _read(String name) async {
    final f = await _file(name);
    if (await f.exists()) {
      return f.readAsString();
    }
    return null;
  }

  // Users
  static Future<void> saveUsers(List<User> users) async {
    final arr = users.map((u) => u.toJson()).toList();
    await _write(_usersFile, jsonEncode(arr));
  }

  static Future<List<User>> loadUsers() async {
    final text = await _read(_usersFile);
    if (text == null || text.isEmpty) return <User>[];
    final arr = jsonDecode(text) as List<dynamic>;
    return arr.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Families
  static Future<void> saveFamilies(List<Family> families) async {
    final arr = families.map((f) => f.toJson()).toList();
    await _write(_familiesFile, jsonEncode(arr));
  }

  static Future<List<Family>> loadFamilies() async {
    final text = await _read(_familiesFile);
    if (text == null || text.isEmpty) return <Family>[];
    final arr = jsonDecode(text) as List<dynamic>;
    return arr.map((e) => Family.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Orders
  static Future<void> saveOrders(List<Order> orders) async {
    final arr = orders.map((o) => o.toJson()).toList();
    await _write(_ordersFile, jsonEncode(arr));
  }

  static Future<List<Order>> loadOrders() async {
    final text = await _read(_ordersFile);
    if (text == null || text.isEmpty) return <Order>[];
    final arr = jsonDecode(text) as List<dynamic>;
    return arr.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Notifications
  static Future<void> saveNotifications(List<AppNotification> list) async {
    final arr = list.map((n) => n.toJson()).toList();
    await _write(_notificationsFile, jsonEncode(arr));
  }

  static Future<List<AppNotification>> loadNotifications() async {
    final text = await _read(_notificationsFile);
    if (text == null || text.isEmpty) return <AppNotification>[];
    final arr = jsonDecode(text) as List<dynamic>;
    return arr
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Save/Load all
  static Future<void> saveAll({
    required List<User> users,
    required List<Family> families,
    required List<Order> orders,
    required List<AppNotification> notifications,
  }) async {
    await Future.wait([
      saveUsers(users),
      saveFamilies(families),
      saveOrders(orders),
      saveNotifications(notifications),
    ]);
  }

  static Future<LoadedData> loadAll() async {
    final results = await Future.wait([
      loadUsers(),
      loadFamilies(),
      loadOrders(),
      loadNotifications(),
    ]);
    return LoadedData(
      users: List<User>.from(results[0] as List<User>),
      families: List<Family>.from(results[1] as List<Family>),
      orders: List<Order>.from(results[2] as List<Order>),
      notifications:
          List<AppNotification>.from(results[3] as List<AppNotification>),
    );
  }

  static Future<int> clearTxtFiles() async {
    final dir = await _dir();
    int deleted = 0;
    final list = dir.listSync();
    for (final fse in list) {
      if (fse is File && fse.path.toLowerCase().endsWith('.txt')) {
        try {
          await fse.delete();
          deleted++;
        } catch (_) {}
      }
    }
    return deleted;
  }
}

class LoadedData {
  final List<User> users;
  final List<Family> families;
  final List<Order> orders;
  final List<AppNotification> notifications;

  LoadedData({
    required this.users,
    required this.families,
    required this.orders,
    required this.notifications,
  });
}
