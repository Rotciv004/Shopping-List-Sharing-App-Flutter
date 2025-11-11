import 'package:flutter/material.dart';
import 'data/in_memory_data.dart';
import 'utils/logger.dart';
import 'ui/families_screen.dart';
import 'ui/auth/login_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/home/notifications_screen.dart';
import 'ui/home/profile_screen.dart';

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
    Log.i('RootScaffold.initState()', tag: 'NAV');
    InMemoryData.instance.initialize();
    // Subscribe to data changes so UI reacts to login/signout
    InMemoryData.instance.addListener(_onDataChanged);
    // Mark initialized immediately; data will load in background
    _initialized = true;
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Log.i('RootScaffold.build(index=$_index)', tag: 'NAV');
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final loggedIn = InMemoryData.instance.currentUser != null;
    if (!loggedIn) {
      return const LoginScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_index].title),
        actions: _index == 2
            ? [
                IconButton(
                  tooltip: 'Clear all',
                  onPressed: () => InMemoryData.instance.clearAllNotifications(),
                  icon: const Icon(Icons.delete_sweep_outlined),
                )
              ]
            : null,
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          FamiliesScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
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
