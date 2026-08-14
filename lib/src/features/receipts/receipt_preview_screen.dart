import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/receipt.dart';
import 'receipt_providers.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  const ReceiptPreviewScreen({
    super.key,
    required this.receipt,
    this.autoPrint = false,
  });

  final Receipt receipt;
  final bool autoPrint;

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  bool _isPrinting = false;
  bool _autoPrintStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoPrint && !_autoPrintStarted) {
      _autoPrintStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _print());
    }
  }

  @override
  Widget build(BuildContext context) {
    final receipt = widget.receipt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        actions: [
          IconButton(
            tooltip: 'Print',
            onPressed: _isPrinting ? null : _print,
            icon: _isPrinting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _ReceiptBody(receipt: receipt),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _print() async {
    setState(() => _isPrinting = true);
    try {
      await ref.read(printerRepositoryProvider).printReceipt(widget.receipt);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Receipt sent to printer')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}

class _ReceiptBody extends StatelessWidget {
  const _ReceiptBody({required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd MMM yyyy HH:mm').format(
      receipt.createdAt.toLocal(),
    );

    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.black87,
        fontFamily: 'monospace',
        fontSize: 13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            receipt.shopName.isEmpty ? 'Chui POS' : receipt.shopName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('Receipt: ${receipt.receiptNumber}'),
          Text('Cashier: ${receipt.cashierName}'),
          Text('Status: ${receipt.status}'),
          Text('Date: $dateText'),
          const Divider(),
          for (final item in receipt.items) ...[
            Text(item.name),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)}',
                  ),
                ),
                Text(item.lineTotal.toStringAsFixed(2)),
              ],
            ),
            const SizedBox(height: 6),
          ],
          const Divider(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                receipt.total.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text('Paid by: ${receipt.paymentMethod}'),
          const SizedBox(height: 16),
          const Text('Thank you', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
