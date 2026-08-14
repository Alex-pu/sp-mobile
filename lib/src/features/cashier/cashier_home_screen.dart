import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../printer/printer_settings_screen.dart';
import '../products/product_list_screen.dart';
import '../receipts/receipt_history_screen.dart';
import '../shift/close_shift_screen.dart';
import '../shift/start_shift_screen.dart';
import '../sync/sync_controller.dart';

class CashierHomeScreen extends ConsumerWidget {
  const CashierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final shift = session?.currentShift;
    final pendingCount = ref.watch(pendingSalesCountProvider).valueOrNull ?? 0;
    final syncState = ref.watch(syncControllerProvider);
    final isSyncing = syncState.isLoading;

    ref.listen(syncControllerProvider, (previous, next) {
      final result = next.valueOrNull;
      if (result != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Synced ${result.synced}/${result.submitted}; ${result.pendingAfter} pending',
            ),
          ),
        );
      }
      if (next.hasError && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error.toString())));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.shop.name ?? 'POS'),
        actions: [
          IconButton(
            tooltip: 'Sync',
            onPressed: isSyncing
                ? null
                : () => ref.read(syncControllerProvider.notifier).reconcile(),
            icon: isSyncing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Badge(
                    isLabelVisible: pendingCount > 0,
                    label: Text(pendingCount.toString()),
                    child: const Icon(Icons.sync),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              session == null ? 'Offline' : 'Hello, ${session.user.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_sync),
                title: Text(
                    '$pendingCount pending sale${pendingCount == 1 ? '' : 's'}'),
                subtitle: const Text('Sync before closing the day'),
                trailing: const Icon(Icons.chevron_right),
                onTap: isSyncing
                    ? null
                    : () =>
                        ref.read(syncControllerProvider.notifier).reconcile(),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(
                  shift?.isOpen == true ? Icons.lock_open : Icons.lock_clock,
                ),
                title: Text(
                  shift?.isOpen == true ? 'Shift open' : 'No open shift',
                ),
                subtitle: Text(shift?.id ?? 'Start a shift before selling'),
                trailing: shift?.isOpen == true
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: shift?.isOpen == true
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const StartShiftScreen(),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: shift?.isOpen == true
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.point_of_sale),
              label: const Text('Sell'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReceiptHistoryScreen(),
                ),
              ),
              icon: const Icon(Icons.receipt_long),
              label: const Text('Receipts'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsScreen(),
                ),
              ),
              icon: const Icon(Icons.print),
              label: const Text('Printer'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: shift?.isOpen == true
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CloseShiftScreen(shift: shift!),
                        ),
                      )
                  : null,
              icon: const Icon(Icons.lock),
              label: const Text('Close shift'),
            ),
          ],
        ),
      ),
    );
  }
}
