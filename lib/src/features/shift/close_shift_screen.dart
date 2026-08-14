import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/shift.dart';
import '../auth/auth_controller.dart';
import '../sync/sync_controller.dart';
import 'start_shift_screen.dart';

class CloseShiftScreen extends ConsumerStatefulWidget {
  const CloseShiftScreen({super.key, required this.shift});

  final Shift shift;

  @override
  ConsumerState<CloseShiftScreen> createState() => _CloseShiftScreenState();
}

class _CloseShiftScreenState extends ConsumerState<CloseShiftScreen> {
  final _closingCashController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isClosing = false;
  Shift? _closedShift;

  @override
  void dispose() {
    _closingCashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingSalesCountProvider).valueOrNull ?? 0;
    final syncState = ref.watch(syncControllerProvider);
    final canClose = pendingCount == 0 && !_isClosing && !syncState.isLoading;

    ref.listen(syncControllerProvider, (previous, next) {
      final result = next.valueOrNull;
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result.synced}/${result.submitted}; ${result.pendingAfter} pending',
            ),
          ),
        );
      }
      if (next.hasError && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Close shift')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: Icon(
                  pendingCount == 0 ? Icons.check_circle : Icons.sync_problem,
                ),
                title: Text(
                    '$pendingCount pending sale${pendingCount == 1 ? '' : 's'}'),
                subtitle: const Text('All sales must sync before closing'),
                trailing: syncState.isLoading
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                onTap: syncState.isLoading
                    ? null
                    : () =>
                        ref.read(syncControllerProvider.notifier).reconcile(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _closingCashController,
              enabled: _closedShift == null,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Closing cash counted'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              enabled: _closedShift == null,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canClose && _closedShift == null ? _closeShift : null,
              icon: const Icon(Icons.lock),
              label: Text(_isClosing ? 'Closing...' : 'Close shift'),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Sync pending sales first.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_closedShift != null) ...[
              const SizedBox(height: 24),
              _ShiftResult(shift: _closedShift!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _closeShift() async {
    final closingCash = double.tryParse(_closingCashController.text.trim());
    if (closingCash == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter closing cash')));
      return;
    }

    setState(() => _isClosing = true);
    try {
      final closed = await ref.read(shiftRepositoryProvider).closeShift(
            shiftId: widget.shift.id,
            closingCash: closingCash,
            notes: _notesController.text.trim(),
          );
      await ref.read(sessionControllerProvider.notifier).refreshBootstrap();
      ref.invalidate(pendingSalesCountProvider);
      if (!mounted) {
        return;
      }
      setState(() => _closedShift = closed);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isClosing = false);
      }
    }
  }
}

class _ShiftResult extends StatelessWidget {
  const _ShiftResult({required this.shift});

  final Shift shift;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('Expected cash'),
            trailing: Text((shift.expectedCash ?? 0).toStringAsFixed(2)),
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Counted cash'),
            trailing: Text((shift.closingCash ?? 0).toStringAsFixed(2)),
          ),
          ListTile(
            leading: const Icon(Icons.balance),
            title: const Text('Variance'),
            trailing: Text((shift.variance ?? 0).toStringAsFixed(2)),
          ),
        ],
      ),
    );
  }
}
