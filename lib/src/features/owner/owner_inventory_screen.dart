import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import 'owner_controller.dart';

class OwnerInventoryScreen extends ConsumerStatefulWidget {
  const OwnerInventoryScreen({super.key});

  @override
  ConsumerState<OwnerInventoryScreen> createState() =>
      _OwnerInventoryScreenState();
}

class _OwnerInventoryScreenState extends ConsumerState<OwnerInventoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedShopId;
  String? _savingProductId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(shopsProvider);
    final search = ref.watch(ownerProductSearchProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop stock')),
      body: SafeArea(
        child: shops.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('Create a shop first.'));
            }

            final shopIds = items.map((shop) => shop.id).toSet();
            if (_selectedShopId == null || !shopIds.contains(_selectedShopId)) {
              _selectedShopId = items.first.id;
            }
            final selectedShopId = _selectedShopId!;
            final products = ref.watch(
              ownerProductsProvider((shopId: selectedShopId, search: search)),
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedShopId,
                        items: [
                          for (final shop in items)
                            DropdownMenuItem(
                              value: shop.id,
                              child: Text(shop.name),
                            ),
                        ],
                        onChanged: (shopId) {
                          if (shopId == null) {
                            return;
                          }
                          setState(() => _selectedShopId = shopId);
                        },
                        decoration: const InputDecoration(labelText: 'Shop'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search product or barcode',
                        ),
                        onChanged: (value) => ref
                            .read(ownerProductSearchProvider.notifier)
                            .state = value,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: products.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(child: Text('No products found.'));
                      }
                      return RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          ownerProductsProvider(
                            (shopId: selectedShopId, search: search),
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemBuilder: (context, index) {
                            final product = items[index];
                            final saving = _savingProductId == product.id;
                            return ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              title: Text(product.name),
                              subtitle: Text(product.code),
                              leading: const Icon(Icons.inventory_2_outlined),
                              trailing: saving
                                  ? const SizedBox.square(
                                      dimension: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('Stock ${product.stockLevel}'),
                              onTap: saving
                                  ? null
                                  : () => _showStockSheet(
                                        shopId: selectedShopId,
                                        product: product,
                                        search: search,
                                      ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemCount: items.length,
                        ),
                      );
                    },
                    error: (error, stackTrace) =>
                        Center(child: Text(error.toString())),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ],
            );
          },
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _showStockSheet({
    required String shopId,
    required Product product,
    required String search,
  }) async {
    final controller =
        TextEditingController(text: product.stockLevel.toString());
    final stockLevel = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(product.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(product.code),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration:
                  const InputDecoration(labelText: 'Stock in this shop'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null) {
                  return;
                }
                Navigator.of(context).pop(value);
              },
              child: const Text('Save stock'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (stockLevel == null || !mounted) {
      return;
    }

    setState(() => _savingProductId = product.id);
    try {
      await ref.read(ownerRepositoryProvider).setProductStock(
            shopId: shopId,
            product: product,
            stockLevel: stockLevel,
          );
      ref.invalidate(ownerProductsProvider((shopId: shopId, search: search)));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} stock updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _savingProductId = null);
      }
    }
  }
}
