import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../utils/logger.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final data = InMemoryData.instance;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _bank;

  @override
  void initState() {
    super.initState();
    final u = data.currentUser;
    _firstName = TextEditingController(text: u?.firstName ?? '');
    _lastName = TextEditingController(text: u?.lastName ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _password = TextEditingController(text: u?.password ?? '');
    _bank = TextEditingController(text: u?.bankAccount ?? '');
  }

  void _signOut() {
    Log.i('ProfileScreen._signOut()', tag: 'NAV');
    data.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out')),
    );
    setState(() {});
  }

  void _save() {
    final err = data.updateCurrentUser(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      bankAccount: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
    );
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Log.i('ProfileScreen.build()', tag: 'NAV');
    final user = data.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Edit profile', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _firstName, decoration: const InputDecoration(labelText: 'First name')),
          const SizedBox(height: 8),
          TextField(controller: _lastName, decoration: const InputDecoration(labelText: 'Last name')),
          const SizedBox(height: 8),
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 8),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 8),
          TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Bank account (optional)')),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save')),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: _signOut, icon: const Icon(Icons.logout), label: const Text('Sign out')),
            ],
          ),
        ],
      ),
    );
  }
}
