import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../utils/logger.dart';
import '../widgets/optimized_notifications_list.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final data = InMemoryData.instance;

  @override
  void initState() {
    super.initState();
    Log.i('NotificationsScreen.initState()', tag: 'NAV');
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    Log.i('NotificationsScreen._onData()', tag: 'NAV');
    // Optimized with ListenableBuilder - no more setState
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Log.i('NotificationsScreen.build()', tag: 'NAV');
    // The parent RootScaffold already provides the AppBar; only render the list here.
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        return OptimizedNotificationsList(
          notifications: data.notifications,
          onDelete: data.deleteNotificationById,
        );
      },
    );
  }
}
