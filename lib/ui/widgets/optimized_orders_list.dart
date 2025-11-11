import 'package:flutter/material.dart';
import '../../models/order.dart';

class OptimizedOrdersList extends StatelessWidget {
  final List<Order> orders;
  final String? currentUserId;
  final Function(String) onDelete;
  final Function(Order) onEdit;

  const OptimizedOrdersList({
    super.key,
    required this.orders,
    required this.currentUserId,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders yet'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderListItem(
          key: ValueKey(order.id),
          order: order,
          currentUserId: currentUserId,
          onDelete: onDelete,
          onEdit: onEdit,
        );
      },
    );
  }
}

class OrderListItem extends StatelessWidget {
  final Order order;
  final String? currentUserId;
  final Function(String) onDelete;
  final Function(Order) onEdit;

  const OrderListItem({
    super.key,
    required this.order,
    required this.currentUserId,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = currentUserId == order.placingUserId;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(_priorityIcon(order.priority)),
        title: Text(order.name),
        subtitle: Text('Qty: ${order.quantity} • ${order.status.name}'),
        onTap: isCreator ? () => onEdit(order) : null,
        trailing: isCreator
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onDelete(order.id),
              )
            : null,
      ),
    );
  }

  IconData _priorityIcon(Priority p) {
    switch (p) {
      case Priority.HIGH:
        return Icons.priority_high;
      case Priority.MEDIUM:
        return Icons.flag_outlined;
      case Priority.LOW:
        return Icons.low_priority;
      case Priority.NEW:
        return Icons.add_task_outlined;
    }
  }
}