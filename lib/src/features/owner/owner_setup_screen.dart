import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'owner_controller.dart';

class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopLocationController = TextEditingController();
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _shopNameController.dispose();
    _shopLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(ownerSessionProvider);
    final isLoading = session.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Owner setup')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Create your business account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Owner name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Owner email',
                errorText: _emailError,
              ),
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Owner phone',
                errorText: _phoneError,
              ),
              onChanged: (_) {
                if (_phoneError != null) {
                  setState(() => _phoneError = null);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Owner PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shopNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'First shop name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _shopLocationController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Shop location'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              child: Text(isLoading ? 'Creating...' : 'Create account'),
            ),
            if (session.hasError) ...[
              const SizedBox(height: 12),
              Text(
                session.error.toString(),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submit() {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      return;
    }
    final phone = _phoneController.text.trim();
    if (!_isValidPhone(phone)) {
      setState(() => _phoneError = 'Enter a valid phone number.');
      return;
    }
    ref.read(ownerSessionProvider.notifier).setupOwner(
          name: _nameController.text.trim(),
          email: email,
          phone: phone,
          pin: _pinController.text.trim(),
          shopName: _shopNameController.text.trim(),
          shopLocation: _shopLocationController.text.trim(),
        );
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  bool _isValidPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15;
  }
}
