import 'package:flutter/material.dart';

import '../data/in_memory_data.dart';
import '../models/family.dart';

class FamiliesScreen extends StatefulWidget {
  const FamiliesScreen({super.key});

  @override
  State<FamiliesScreen> createState() => _FamiliesScreenState();
}

class _FamiliesScreenState extends State<FamiliesScreen> {
  final data = InMemoryData.instance;

  @override
  void initState() {
    super.initState();
    data.addListener(_onData);
  }

  @override
  void dispose() {
    data.removeListener(_onData);
    super.dispose();
  }

  void _onData() {
    if (mounted) setState(() {});
  }

  Future<void> _addFamily() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create family'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Family name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Create'),
          )
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final f = Family(name: name);
      data.families.add(f);
  data.persistAll();
  data.notify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final families = data.families;
    return Scaffold(
      body: families.isEmpty
          ? const Center(child: Text('No families yet'))
          : ListView.separated(
              itemCount: families.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final f = families[i];
                return ListTile(
                  title: Text(f.name),
                  subtitle: Text('${f.numberOfMembers} members • ${f.numberOfOrders} orders'),
                  leading: const Icon(Icons.group_outlined),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFamily,
        child: const Icon(Icons.add),
      ),
    );
  }
}
