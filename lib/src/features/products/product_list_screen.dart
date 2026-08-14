import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import 'product_providers.dart';
import 'scan_barcode_screen.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider).valueOrNull;
    final products = ref.watch(localProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(session?.shop.name ?? 'Sell'),
        actions: [
          IconButton(
            tooltip: 'Cart',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
            icon: Badge(
              label: Text(ref.watch(cartControllerProvider).length.toString()),
              child: const Icon(Icons.shopping_cart),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search product or barcode',
                ),
                onChanged: (value) =>
                    ref.read(productSearchProvider.notifier).state = value,
              ),
            ),
            Expanded(
              child: products.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    itemBuilder: (context, index) {
                      final product = items[index];
                      return ListTile(
                        tileColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.code} - Stock ${product.stockLevel}',
                        ),
                        trailing: Text(product.sellingPrice.toStringAsFixed(2)),
                        onTap: product.stockLevel <= 0
                            ? null
                            : () => _addProduct(product),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: items.length,
                  );
                },
                error: (error, stackTrace) =>
                    Center(child: Text(error.toString())),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanBarcode,
        tooltip: 'Scan barcode',
        child: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanBarcodeScreen()),
    );
    if (code == null || code.isEmpty || !mounted) {
      return;
    }
    final product = await ref.read(productRepositoryProvider).findByCode(code);
    if (!mounted) {
      return;
    }
    if (product == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No product found for $code')));
      return;
    }
    if (product.stockLevel <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('${product.name} is out of stock')));
      return;
    }
    await _addProduct(product);
  }

  Future<void> _addProduct(Product product) async {
    try {
      ref.read(cartControllerProvider.notifier).add(product);
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added')));
  }
}
