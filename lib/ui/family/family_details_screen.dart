import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../models/family.dart';
import '../../models/order.dart';
import '../../utils/logger.dart';

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
    final result = await showDialog<_OrderFormResult>(
      context: context,
      builder: (_) => const _OrderDialog(),
    );
    final fam = _family;
    final userId = data.currentUser?.id ?? 'unknown';
    if (result != null && fam != null && fam.id != 'Unknown') {
      data.createOrder(
        familyId: fam.id,
        name: result.name,
        description: result.description,
        quantity: result.quantity,
        priority: result.priority,
        placingUserId: userId,
        allocatedSum: result.allocatedSum,
        deadline: result.deadline,
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
    final orders = _orders;
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
      body: orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : ListView.separated(
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final o = orders[i];
                final isCreator = data.currentUser?.id == o.placingUserId;
                return ListTile(
                  leading: Icon(_priorityIcon(o.priority)),
                  title: Text(o.name),
                  subtitle: Text('Qty: ${o.quantity} • ${o.status.name}'),
                  onTap: isCreator
                      ? () async {
                          final edited = await showDialog<_OrderFormResult>(
                            context: context,
                            builder: (_) => _OrderDialog(existing: o),
                          );
                          if (edited != null) {
                            final updated = Order(
                              id: o.id,
                              name: edited.name,
                              description: edited.description,
                              quantity: edited.quantity,
                              priority: edited.priority,
                              status: o.status,
                              placingUserId: o.placingUserId,
                              fulfillingUserId: o.fulfillingUserId,
                              allocatedSum: edited.allocatedSum,
                              datePlaced: o.datePlaced,
                              fulfillmentDeadLineDate: edited.deadline ?? o.fulfillmentDeadLineDate,
                            );
                            data.updateOrder(updated);
                          }
                        }
                      : null,
                  trailing: isCreator
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteOrder(o.id),
                        )
                      : null,
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

class _OrderFormResult {
  final String name;
  final String description;
  final int quantity;
  final Priority priority;
  final double allocatedSum;
  final DateTime? deadline;
  const _OrderFormResult(this.name, this.description, this.quantity, this.priority, this.allocatedSum, this.deadline);
}

class _OrderDialog extends StatefulWidget {
  final Order? existing;
  const _OrderDialog({this.existing});

  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _qty;
  late final TextEditingController _sum;
  late Priority _priority;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _qty = TextEditingController(text: e?.quantity.toString() ?? '1');
    _sum = TextEditingController(text: (e?.allocatedSum ?? 0).toString());
    _priority = e?.priority ?? Priority.NEW;
    _deadline = e?.fulfillmentDeadLineDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
  title: Text(widget.existing == null ? 'Create order' : 'Edit order'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 8),
            TextField(controller: _qty, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<Priority>(
              initialValue: _priority,
              items: Priority.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _priority = v ?? Priority.NEW),
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 8),
            TextField(controller: _sum, decoration: const InputDecoration(labelText: 'Allocated sum'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(_deadline == null ? 'No deadline' : 'Deadline: ${_deadline!.toLocal()}'),
                ),
                TextButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final picked = await _pickDateTime(
                      context: context,
                      initial: _deadline ?? now,
                      min: now,
                    );
                    if (picked != null) {
                      setState(() => _deadline = picked);
                    }
                  },
                  child: const Text('Pick date & time'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_name.text.trim().isEmpty) return;
            final res = _OrderFormResult(
              _name.text.trim(),
              _desc.text.trim(),
              int.tryParse(_qty.text.trim()) ?? 1,
              _priority,
              double.tryParse(_sum.text.trim()) ?? 0.0,
              _deadline,
            );
            Navigator.pop(context, res);
          },
          child: Text(widget.existing == null ? 'Create' : 'Save'),
        )
      ],
    );
  }
}

Future<DateTime?> _pickDateTime({required BuildContext context, required DateTime initial, required DateTime min}) async {
  int year = initial.year;
  int month = initial.month;
  int day = initial.day;
  int hour = initial.hour;
  int minute = initial.minute - (initial.minute % 1);

  int daysInMonth(int y, int m) {
    final lastDay = DateTime(y, m + 1, 0).day;
    return lastDay;
  }

  DateTime clamp(DateTime dt) {
    if (dt.isBefore(min)) return min;
    return dt;
  }

  DateTime? result = await showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setState) {
        final maxYear = DateTime.now().year + 10;
        final validDays = daysInMonth(year, month);
        if (day > validDays) day = validDays;
        final candidate = clamp(DateTime(year, month, day, hour, minute));
        return AlertDialog(
          title: const Text('Select date & time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: year,
                    items: [for (int y = min.year; y <= maxYear; y++) DropdownMenuItem(value: y, child: Text(y.toString()))],
                    onChanged: (v) => setState(() => year = v ?? year),
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: month,
                    items: [for (int m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))],
                    onChanged: (v) => setState(() => month = v ?? month),
                    decoration: const InputDecoration(labelText: 'Month'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: day,
                    items: [for (int d = 1; d <= validDays; d++) DropdownMenuItem(value: d, child: Text(d.toString().padLeft(2, '0')))],
                    onChanged: (v) => setState(() => day = v ?? day),
                    decoration: const InputDecoration(labelText: 'Day'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: hour,
                    items: [for (int h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text(h.toString().padLeft(2, '0')))],
                    onChanged: (v) => setState(() => hour = v ?? hour),
                    decoration: const InputDecoration(labelText: 'Hour'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: minute,
                    items: [for (int m = 0; m < 60; m++) DropdownMenuItem(value: m, child: Text(m.toString().padLeft(2, '0')))],
                    onChanged: (v) => setState(() => minute = v ?? minute),
                    decoration: const InputDecoration(labelText: 'Minute'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Selected: ${candidate.toLocal()}'),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final dt = DateTime(year, month, day, hour, minute);
                if (dt.isBefore(min)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Date/time cannot be in the past')));
                  return;
                }
                Navigator.pop(ctx, dt);
              },
              child: const Text('OK'),
            ),
          ],
        );
      });
    },
  );
  return result;
}
