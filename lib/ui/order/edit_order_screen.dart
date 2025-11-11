import 'package:flutter/material.dart';

import '../../models/order.dart';

class EditOrderScreen extends StatefulWidget {
  final Order order;
  const EditOrderScreen({super.key, required this.order});

  @override
  State<EditOrderScreen> createState() => _EditOrderScreenState();
}

class _EditOrderScreenState extends State<EditOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _qty;
  late final TextEditingController _sum;
  late Priority _priority;
  DateTime? _deadline;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final e = widget.order;
    _name = TextEditingController(text: e.name);
    _desc = TextEditingController(text: e.description);
    _qty = TextEditingController(text: e.quantity.toString());
    _sum = TextEditingController(text: e.allocatedSum.toString());
    _priority = e.priority;
    _deadline = e.fulfillmentDeadLineDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _qty.dispose();
    _sum.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    try {
      final updated = Order(
        id: widget.order.id,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        quantity: int.tryParse(_qty.text.trim()) ?? widget.order.quantity,
        priority: _priority,
        status: widget.order.status,
        placingUserId: widget.order.placingUserId,
        fulfillingUserId: widget.order.fulfillingUserId,
        allocatedSum: double.tryParse(_sum.text.trim().replaceAll(',', '.')) ?? widget.order.allocatedSum,
        datePlaced: widget.order.datePlaced,
        fulfillmentDeadLineDate: _deadline ?? widget.order.fulfillmentDeadLineDate,
      );
      if (mounted) Navigator.pop(context, updated);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline ?? now),
    );
    if (time == null) return;
    setState(() => _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit order')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return 'Name is required';
                  if (t.length < 2) return 'Name must be at least 2 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: const InputDecoration(labelText: 'Quantity'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Enter a valid number';
                  if (n <= 0) return 'Quantity must be greater than 0';
                  if (n > 1000000) return 'Quantity too large';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: Priority.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sum,
                decoration: const InputDecoration(labelText: 'Allocated sum', prefixText: '€ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
                  if (n == null) return 'Enter a valid amount';
                  if (n < 0) return 'Amount cannot be negative';
                  if (n > 1000000000) return 'Amount too large';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Deadline'),
                      child: Text(
                        _deadline == null
                            ? 'No deadline'
                            : '${_deadline!.toLocal()}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _pickDeadline,
                    child: const Text('Pick date & time'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_submitting ? 'Saving…' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
