import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../utils/logger.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _bank = TextEditingController();

  bool _busy = false;
  String? _error;

  void _doRegister() async {
    Log.i('RegisterScreen._doRegister()', tag: 'NAV');
    setState(() { _busy = true; _error = null; });
    final err = InMemoryData.instance.register(
      firstName: _first.text.trim(),
      lastName: _last.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      bankAccount: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
    );
    if (!mounted) return;
    setState(() { _busy = false; _error = err; });
    if (err == null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Log.i('RegisterScreen.build()', tag: 'NAV');
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: _first, decoration: const InputDecoration(labelText: 'First name')),
              const SizedBox(height: 12),
              TextField(controller: _last, decoration: const InputDecoration(labelText: 'Last name')),
              const SizedBox(height: 12),
              TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: _password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
              const SizedBox(height: 12),
              TextField(controller: _bank, decoration: const InputDecoration(labelText: 'Bank account (optional)')),
              const SizedBox(height: 12),
              if (_error != null)
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _doRegister,
                child: _busy ? const CircularProgressIndicator() : const Text('Create account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
