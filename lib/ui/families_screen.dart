import 'package:flutter/material.dart';

import '../data/in_memory_data.dart';
import '../utils/logger.dart';
import 'widgets/optimized_families_list.dart';

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
    // Only rebuild if mounted - targeted update via ListenableBuilder
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
    Log.i('FamiliesScreen.build()', tag: 'NAV');
    return Scaffold(
      body: ListenableBuilder(
        listenable: data,
        builder: (context, _) {
          return OptimizedFamiliesList(
            families: data.families,
            onAdd: _addFamily,
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
