import 'package:flutter/material.dart';
import '../../models/app_notification.dart';

class OptimizedNotificationsList extends StatelessWidget {
  final List<AppNotification> notifications;
  final Function(String) onDelete;

  const OptimizedNotificationsList({
    super.key,
    required this.notifications,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Center(child: Text('No notifications'));
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationListItem(
          key: ValueKey(notification.id),
          notification: notification,
          onDelete: onDelete,
        );
      },
    );
  }
}

class NotificationListItem extends StatelessWidget {
  final AppNotification notification;
  final Function(String) onDelete;

  const NotificationListItem({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile;
    final n = notification;
    
    if (n is ExpiredOrderNotification) {
      tile = ListTile(
        leading: const Icon(Icons.warning_amber_outlined),
        title: Text('${n.orderName} expired'),
        subtitle: Text('Family: ${n.familyName} • Qty: ${n.quantity} • ${n.allocatedSum.toStringAsFixed(2)}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(n.id),
        ),
      );
    } else if (n is FamilyInviteNotification) {
      tile = ListTile(
        leading: const Icon(Icons.mail_outline),
        title: Text('Invite to ${n.familyName}'),
        subtitle: Text('From ${n.fromUser}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(n.id),
        ),
      );
    } else if (n is AnnouncementNotification) {
      tile = ListTile(
        leading: const Icon(Icons.campaign_outlined),
        title: const Text('Announcement'),
        subtitle: Text(n.message),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onDelete(n.id),
        ),
      );
    } else {
      tile = const SizedBox.shrink();
    }

    return Dismissible(
      key: ValueKey(n.id),
      background: Container(color: Theme.of(context).colorScheme.errorContainer),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(n.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: tile,
      ),
    );
  }
}