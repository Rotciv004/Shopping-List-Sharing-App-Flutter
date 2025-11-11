import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../models/family.dart';
import '../../models/order.dart';
import '../../utils/logger.dart';
import '../widgets/optimized_orders_list.dart';
import '../order/create_order_screen.dart';
import '../order/edit_order_screen.dart';

class FamilyDetailsScreen extends StatefulWidget {
  final String familyId;
  const FamilyDetailsScreen({super.key, required this.familyId});

  @override
  State<FamilyDetailsScreen> createState() => _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState extends State<FamilyDetailsScreen> {
  final data = InMemoryData.instance;

  @override
  void initState() {
    super.initState();
    Log.i('FamilyDetailsScreen.initState(familyId=${widget.familyId})', tag: 'NAV');
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    Log.i('FamilyDetailsScreen._onData()', tag: 'NAV');
    // Only rebuild if mounted - optimized with ListenableBuilder
    if (mounted) setState(() {});
  }

  Family? get _family => data.families.firstWhere(
        (f) => f.id == widget.familyId,
        orElse: () => Family(name: 'Unknown'),
      );

  List<Order> get _orders {
    final fam = _family;
    if (fam == null || fam.id == 'Unknown') return const <Order>[];
    return data.orders.where((o) => fam.ordersList.contains(o.id)).toList();
  }

  Future<void> _addOrder() async {
    Log.i('FamilyDetailsScreen._addOrder()', tag: 'NAV');
    final fam = _family;
    final userId = data.currentUser?.id;
    if (fam == null || fam.id == 'Unknown' || userId == null) return;
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          familyId: fam.id,
          placingUserId: userId,
        ),
      ),
    );
    if (created == true) {
      // Data layer already added the single created order and notified listeners
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created')),
      );
    }
  }

  void _deleteOrder(String orderId) {
    Log.i('FamilyDetailsScreen._deleteOrder($orderId)', tag: 'NAV');
    final requester = data.currentUser?.id;
    if (requester == null) return;
    final ok = data.deleteOrderByIdIfCreator(orderId, requester);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the creator can delete this order')),
      );
    }
  }

  Future<void> _editOrder(Order order) async {
    Log.i('FamilyDetailsScreen._editOrder(${order.id})', tag: 'NAV');
    final updated = await Navigator.push<Order>(
      context,
      MaterialPageRoute(builder: (_) => EditOrderScreen(order: order)),
    );
    if (updated != null) {
      data.updateOrder(updated);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order updated')));
    }
  }

  Future<void> _addMemberByEmail() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add member by email'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    final fam = _family;
    if (fam == null || fam.id == 'Unknown') return;
    final err = data.addMemberToFamily(fam.id, email);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added')));
    }
  }

  Future<void> _leaveFamily() async {
    Log.i('FamilyDetailsScreen._leaveFamily() called', tag: 'NAV');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave family'),
        content: const Text('Are you sure you want to leave this family?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    Log.i('Leave family confirmed: $confirmed', tag: 'NAV');
    if (confirmed != true) return;
    final fam = _family;
    final userId = data.currentUser?.id;
    Log.i('Leaving family: ${fam?.name} (${fam?.id}) for user $userId', tag: 'NAV');
    if (fam == null || fam.id == 'Unknown' || userId == null) {
      Log.i('Cannot leave family - invalid data', tag: 'NAV');
      return;
    }
    data.removeMemberFromFamily(fam.id, userId);
    Log.i('Successfully left family, navigating back', tag: 'NAV');
    Navigator.pop(context); // Go back to families list
  }

  @override
  Widget build(BuildContext context) {
    final fam = _family;
    if (fam == null || fam.id == 'Unknown') {
      return const Scaffold(body: Center(child: Text('Family not found')));
    }
  Log.i('FamilyDetailsScreen.build()', tag: 'NAV');
  return Scaffold(
      appBar: AppBar(title: Text(fam.name), actions: [
        IconButton(onPressed: _addMemberByEmail, icon: const Icon(Icons.person_add_alt_1_outlined)),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'leave') _leaveFamily();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'leave', child: Text('Leave family')),
          ],
        ),
      ]),
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          return OptimizedOrdersList(
            orders: _orders,
            currentUserId: data.currentUser?.id,
            onDelete: _deleteOrder,
            onEdit: _editOrder,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOrder,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Note: Order creation now uses a dedicated screen with a validated form.
