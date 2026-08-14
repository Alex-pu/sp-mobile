import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../products/product_providers.dart';
import '../receipts/receipt_preview_screen.dart';
import '../receipts/receipt_providers.dart';
import '../sync/sync_controller.dart';
import 'cart_controller.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              title: Text(item.product.name),
              subtitle: Text('Qty ${item.quantity}'),
              trailing: Text(item.lineTotal.toStringAsFixed(2)),
              onLongPress: () => controller.remove(item.product),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: items.isEmpty || _isSaving ? null : _checkout,
            child: Text(
              _isSaving
                  ? 'Saving...'
                  : 'Save cash sale - ${total.toStringAsFixed(2)}',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    setState(() => _isSaving = true);
    try {
      final receipt =
          await ref.read(cartControllerProvider.notifier).checkout();
      ref.invalidate(localProductsProvider);
      ref.invalidate(pendingSalesCountProvider);
      ref.invalidate(recentReceiptsProvider);
      final savedReceipt = await ref
          .read(receiptRepositoryProvider)
          .findByReceiptNumber(receipt);
      if (!mounted) return;
      if (savedReceipt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale saved: $receipt')),
        );
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReceiptPreviewScreen(receipt: savedReceipt),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
