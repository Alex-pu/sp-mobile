import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cashier/cashier_home_screen.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionControllerProvider, (previous, next) {
      final session = next.valueOrNull;
      if (session != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CashierHomeScreen()),
        );
      }
    });

    final sessionState = ref.watch(sessionControllerProvider);
    final isLoading = sessionState.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Chui POS')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24),
            Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : _login,
              child: Text(isLoading ? 'Signing in...' : 'Sign in'),
            ),
            if (sessionState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                sessionState.error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _login() {
    ref
        .read(sessionControllerProvider.notifier)
        .login(_nameController.text.trim(), _pinController.text.trim());
  }
}
