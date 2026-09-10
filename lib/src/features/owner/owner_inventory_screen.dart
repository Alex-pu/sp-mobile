import 'dart:io';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

    return shops.when(
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

            return Scaffold(
              appBar: AppBar(
                title: const Text('Shop stock'),
                actions: [
                  IconButton(
                    tooltip: 'Add product',
                    onPressed: () => _showAddProduct(
                      shopId: selectedShopId,
                      search: search,
                    ),
                    icon: const Icon(Icons.add_box_outlined),
                  ),
                  IconButton(
                    tooltip: 'Upload Excel',
                    onPressed: () => _uploadExcel(
                      shopId: selectedShopId,
                      search: search,
                    ),
                    icon: const Icon(Icons.upload_file),
                  ),
                  IconButton(
                    tooltip: 'Download Excel template',
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download),
                  ),
                ],
              ),
              body: SafeArea(
                child: Column(
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
                ),
              ),
            );
          },
          error: (error, stackTrace) => Center(child: Text(error.toString())),
          loading: () => const Center(child: CircularProgressIndicator()),
        );
  }

  Future<void> _showAddProduct({
    required String shopId,
    required String search,
  }) async {
    final code = TextEditingController();
    final name = TextEditingController();
    final category = TextEditingController(text: 'General');
    final costPrice = TextEditingController(text: '0');
    final sellingPrice = TextEditingController();
    final stockLevel = TextEditingController(text: '0');
    final values = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Add product', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Barcode / code'),
              ),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Product name'),
              ),
              TextField(
                controller: category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: costPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Cost price'),
              ),
              TextField(
                controller: sellingPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Selling price'),
              ),
              TextField(
                controller: stockLevel,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Opening stock'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                    final parsedCost = double.tryParse(costPrice.text.trim());
                    final parsedSelling =
                      double.tryParse(sellingPrice.text.trim());
                    final parsedStock = int.tryParse(stockLevel.text.trim());
                    if (code.text.trim().isEmpty ||
                      name.text.trim().isEmpty ||
                      parsedCost == null ||
                      parsedCost < 0 ||
                      parsedSelling == null ||
                      parsedSelling < 0 ||
                      parsedStock == null ||
                      parsedStock < 0) {
                    return;
                  }
                  Navigator.of(context).pop({
                    'code': code.text.trim(),
                    'name': name.text.trim(),
                    'category': category.text.trim(),
                    'costPrice': costPrice.text.trim(),
                    'sellingPrice': sellingPrice.text.trim(),
                    'stockLevel': stockLevel.text.trim(),
                  });
                },
                child: const Text('Add product'),
              ),
            ],
          ),
        ),
      ),
    );
    code.dispose();
    name.dispose();
    category.dispose();
    costPrice.dispose();
    sellingPrice.dispose();
    stockLevel.dispose();

    if (values == null || !mounted) {
      return;
    }
    try {
      await ref.read(ownerRepositoryProvider).createProduct(
            shopId: shopId,
            code: values['code']!,
            name: values['name']!,
            category: values['category']!.isEmpty ? 'General' : values['category']!,
            costPrice: double.parse(values['costPrice']!),
            sellingPrice: double.parse(values['sellingPrice']!),
            stockLevel: int.parse(values['stockLevel']!),
          );
      ref.invalidate(ownerProductsProvider((shopId: shopId, search: search)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added to this shop.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _uploadExcel({
    required String shopId,
    required String search,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    final filePath = result?.files.single.path;
    if (filePath == null || !mounted) {
      return;
    }
    try {
      final result = await ref.read(ownerRepositoryProvider).uploadProducts(
            shopId: shopId,
            filePath: filePath,
          );
      ref.invalidate(ownerProductsProvider((shopId: shopId, search: search)));
      if (mounted) {
        final summary = result['summary'] as Map<String, dynamic>?;
        final errors = (result['errors'] as List<dynamic>?)?.length ?? 0;
        final uploaded = summary?['successful'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errors == 0
              ? '$uploaded products uploaded to this shop.'
              : '$uploaded products uploaded; $errors rows need attention.'),
        ));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _downloadTemplate() async {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Products');
    final sheet = workbook['Products'];
    sheet.appendRow([
      TextCellValue('code'),
      TextCellValue('name'),
      TextCellValue('category'),
      TextCellValue('description'),
      TextCellValue('costPrice'),
      TextCellValue('sellingPrice'),
      TextCellValue('stockLevel'),
      TextCellValue('reorderLevel'),
    ]);
    sheet.appendRow([
      TextCellValue('6161101234567'),
      TextCellValue('Example product'),
      TextCellValue('General'),
      TextCellValue(''),
      DoubleCellValue(0),
      DoubleCellValue(100),
      IntCellValue(0),
      IntCellValue(10),
    ]);

    final bytes = workbook.encode();
    if (bytes == null || !mounted) {
      return;
    }
    final directory = await getTemporaryDirectory();
    final file = File(path.join(directory.path, 'products_template.xlsx'));
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: 'Products Excel template',
        files: [XFile(file.path)],
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
