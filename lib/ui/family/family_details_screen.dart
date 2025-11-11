import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../models/family.dart';
import '../../models/order.dart';
import '../../utils/logger.dart';
import '../widgets/optimized_orders_list.dart';
import '../order/create_order_screen.dart';

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
    // For now retain previous edit logic using a simple dialog
    final nameController = TextEditingController(text: order.name);
    final descController = TextEditingController(text: order.description);
    final qtyController = TextEditingController(text: order.quantity.toString());
    final sumController = TextEditingController(text: order.allocatedSum.toString());
    Priority priority = order.priority;
    DateTime? deadline = order.fulfillmentDeadLineDate;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 8),
                TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<Priority>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: Priority.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                  onChanged: (v) => setState(() => priority = v ?? priority),
                ),
                const SizedBox(height: 8),
                TextField(controller: sumController, decoration: const InputDecoration(labelText: 'Allocated sum'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(deadline == null ? 'No deadline' : 'Deadline: ${deadline!.toLocal()}')),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final date = await showDatePicker(
                        context: ctx,
                        initialDate: deadline ?? now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 10),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(deadline ?? now),
                      );
                      if (time == null) return;
                      setState(() => deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                    },
                    child: const Text('Pick date & time'),
                  )
                ])
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      final updated = Order(
        id: order.id,
        name: nameController.text.trim(),
        description: descController.text.trim(),
        quantity: int.tryParse(qtyController.text.trim()) ?? order.quantity,
        priority: priority,
        status: order.status,
        placingUserId: order.placingUserId,
        fulfillingUserId: order.fulfillingUserId,
        allocatedSum: double.tryParse(sumController.text.trim()) ?? order.allocatedSum,
        datePlaced: order.datePlaced,
        fulfillmentDeadLineDate: deadline ?? order.fulfillmentDeadLineDate,
      );
      data.updateOrder(updated);
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
