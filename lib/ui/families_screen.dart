import 'package:flutter/material.dart';

import '../data/in_memory_data.dart';
import 'family/family_details_screen.dart';
import '../utils/logger.dart';

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
    Log.i('FamiliesScreen._onData()', tag: 'NAV');
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
      Log.i('FamiliesScreen._addFamily(name=$name)', tag: 'NAV');
      data.addFamily(name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final families = data.families;
  Log.i('FamiliesScreen.build()', tag: 'NAV');
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
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FamilyDetailsScreen(familyId: f.id),
                    ),
                  ),
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
