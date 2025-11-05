import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../utils/logger.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Log.i('HomeScreen.build()', tag: 'NAV');
    final data = InMemoryData.instance;
    final user = data.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome${user != null ? ', ${user.firstName}' : ''}!'),
          const SizedBox(height: 8),
          const Text('Use the tabs below to navigate')
        ],
      ),
    );
  }
}
