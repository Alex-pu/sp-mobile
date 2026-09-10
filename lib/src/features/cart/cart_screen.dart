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
  String _paymentMethod = 'cash';
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'cash',
                    label: Text('Cash'),
                    icon: Icon(Icons.money),
                  ),
                  ButtonSegment(
                    value: 'mpesa',
                    label: Text('M-Pesa'),
                    icon: Icon(Icons.phone_android),
                  ),
                ],
                selected: {_paymentMethod},
                onSelectionChanged: (value) =>
                    setState(() => _paymentMethod = value.first),
              ),
            ),
            if (_paymentMethod == 'mpesa')
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Customer M-Pesa phone',
                    hintText: '2547XXXXXXXX',
                  ),
                ),
              ),
          ],
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
                  : 'Pay ${_paymentMethod == 'mpesa' ? 'with M-Pesa' : 'cash'} - ${total.toStringAsFixed(2)}',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkout() async {
    setState(() => _isSaving = true);
    try {
      final sale = await ref.read(cartControllerProvider.notifier).checkout(
            paymentMethod: _paymentMethod,
            phoneNumber: _phoneController.text,
          );
      ref.invalidate(localProductsProvider);
      ref.invalidate(pendingSalesCountProvider);
      ref.invalidate(recentReceiptsProvider);
      final savedReceipt = await ref
          .read(receiptRepositoryProvider)
          .findByReceiptNumber(sale.receiptNumber);
      if (!mounted) return;
      if (savedReceipt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale saved: ${sale.receiptNumber}')),
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
