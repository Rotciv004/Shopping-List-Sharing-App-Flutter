import 'package:flutter/material.dart';

import '../../data/in_memory_data.dart';
import '../../utils/logger.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  void _doLogin() async {
    Log.i('LoginScreen._doLogin()', tag: 'NAV');
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = InMemoryData.instance.signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      setState(() => _error = 'Invalid email or password');
    }
  }

  void _openRegister() {
    Log.i('LoginScreen._openRegister()', tag: 'NAV');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    Log.i('LoginScreen.build()', tag: 'NAV');
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const Spacer(),
            ElevatedButton(
              onPressed: _busy ? null : _doLogin,
              child: _busy ? const CircularProgressIndicator() : const Text('Sign in'),
            ),
            TextButton(onPressed: _openRegister, child: const Text('Create account')),
          ],
        ),
      ),
    );
  }
}
