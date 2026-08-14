import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/repositories/shift_repository.dart';
import '../auth/auth_controller.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository(ref.watch(apiClientProvider));
});

class StartShiftScreen extends ConsumerStatefulWidget {
  const StartShiftScreen({super.key});

  @override
  ConsumerState<StartShiftScreen> createState() => _StartShiftScreenState();
}

class _StartShiftScreenState extends ConsumerState<StartShiftScreen> {
  final _floatController = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start shift')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _floatController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Opening cash float',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _isSaving ? null : _startShift,
              child: Text(_isSaving ? 'Starting...' : 'Start shift'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startShift() async {
    setState(() => _isSaving = true);
    try {
      final openingFloat = double.tryParse(_floatController.text.trim()) ?? 0;
      await ref.read(shiftRepositoryProvider).openShift(openingFloat);
      await ref.read(sessionControllerProvider.notifier).refreshBootstrap();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
