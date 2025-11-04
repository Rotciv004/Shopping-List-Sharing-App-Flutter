import 'package:flutter/material.dart';
import 'data/in_memory_data.dart';
import 'ui/families_screen.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  bool _initialized = false;

  final _tabs = const [
    _TabEntry('Home', Icons.home_outlined),
    _TabEntry('Families', Icons.group_outlined),
    _TabEntry('Notifications', Icons.notifications_outlined),
    _TabEntry('Profile', Icons.person_outline),
  ];

  @override
  void initState() {
    super.initState();
    InMemoryData.instance.initialize().then((_) {
      if (mounted) setState(() => _initialized = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].title),
      ),
      body: _initialized
          ? IndexedStack(
              index: _index,
              children: const [
                Center(child: Text('Home')),
                FamiliesScreen(),
                Center(child: Text('Notifications')),
                Center(child: Text('Profile')),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  label: t.title,
                ))
            .toList(),
      ),
    );
  }
}

class _TabEntry {
  final String title;
  final IconData icon;
  const _TabEntry(this.title, this.icon);
}
