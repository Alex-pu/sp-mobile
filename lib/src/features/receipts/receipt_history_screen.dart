import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'receipt_preview_screen.dart';
import 'receipt_providers.dart';

class ReceiptHistoryScreen extends ConsumerWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(recentReceiptsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      body: SafeArea(
        child: receipts.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No receipts yet'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final receipt = items[index];
                return ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  leading: const Icon(Icons.receipt_long),
                  title: Text(receipt.receiptNumber),
                  subtitle: Text(
                    '${receipt.cashierName} - ${receipt.status}',
                  ),
                  trailing: Text(receipt.total.toStringAsFixed(2)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReceiptPreviewScreen(receipt: receipt),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: items.length,
            );
          },
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
