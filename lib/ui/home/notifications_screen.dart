import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../models/app_notification.dart';
import '../../utils/logger.dart';

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
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = data.notifications;
    Log.i('NotificationsScreen.build()', tag: 'NAV');
    if (list.isEmpty) {
      return const Center(child: Text('No notifications'));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            onPressed: () => data.clearAllNotifications(),
            icon: const Icon(Icons.delete_sweep_outlined),
          )
        ],
      ),
      body: ListView.separated(
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final n = list[i];
          Widget tile;
          if (n is ExpiredOrderNotification) {
            tile = ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: Text('${n.orderName} expired'),
              subtitle: Text('Family: ${n.familyName} • Qty: ${n.quantity} • ${n.allocatedSum.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => data.deleteNotificationById(n.id),
              ),
            );
          } else if (n is FamilyInviteNotification) {
            tile = ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text('Invite to ${n.familyName}'),
              subtitle: Text('From ${n.fromUser}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => data.deleteNotificationById(n.id),
              ),
            );
          } else if (n is AnnouncementNotification) {
            tile = ListTile(
              leading: const Icon(Icons.campaign_outlined),
              title: const Text('Announcement'),
              subtitle: Text(n.message),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => data.deleteNotificationById(n.id),
              ),
            );
          } else {
            tile = const SizedBox.shrink();
          }
          return Dismissible(
            key: ValueKey(n.id),
            background: Container(color: Theme.of(context).colorScheme.errorContainer),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => data.deleteNotificationById(n.id),
            child: tile,
          );
        },
      ),
    );
  }
}
