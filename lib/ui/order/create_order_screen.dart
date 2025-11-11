import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../models/order.dart';

class CreateOrderScreen extends StatefulWidget {
  final String familyId;
  final String placingUserId;
  const CreateOrderScreen({super.key, required this.familyId, required this.placingUserId});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _sum = TextEditingController(text: '0');
  Priority _priority = Priority.NEW;
  DateTime? _deadline;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _qty.dispose();
    _sum.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return; // Show inline errors

    setState(() => _submitting = true);
    try {
      final quantity = int.tryParse(_qty.text.trim()) ?? 1;
      final allocatedSum = double.tryParse(_sum.text.trim().replaceAll(',', '.')) ?? 0.0;

      InMemoryData.instance.createOrder(
        familyId: widget.familyId,
        name: _name.text.trim(),
        description: _desc.text.trim(),
        quantity: quantity,
        priority: _priority,
        placingUserId: widget.placingUserId,
        allocatedSum: allocatedSum,
        deadline: _deadline,
      );

      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now,
      firstDate: now,
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
      appBar: AppBar(title: const Text('Create order')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Milk',
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Details (optional)'
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qty,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                ),
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
                onChanged: (v) => setState(() => _priority = v ?? Priority.NEW),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sum,
                decoration: const InputDecoration(
                  labelText: 'Allocated sum',
                  prefixText: '€ ',
                ),
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
                  icon: const Icon(Icons.check),
                  label: Text(_submitting ? 'Saving…' : 'Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
