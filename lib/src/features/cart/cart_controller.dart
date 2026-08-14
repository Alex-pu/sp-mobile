import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/offline_transaction_repository.dart';
import '../auth/auth_controller.dart';

final offlineTransactionRepositoryProvider =
    Provider<OfflineTransactionRepository>((ref) {
  return OfflineTransactionRepository(ref.watch(localDatabaseProvider));
});

final cartControllerProvider =
    NotifierProvider<CartController, List<CartItem>>(CartController.new);

class CartController extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const [];

  double get total => state.fold(0, (sum, item) => sum + item.lineTotal);

  void add(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index == -1) {
      if (product.stockLevel <= 0) {
        throw StateError('${product.name} is out of stock.');
      }
      state = [...state, CartItem(product: product, quantity: 1)];
      return;
    }

    final next = [...state];
    final current = next[index];
    if (current.quantity >= product.stockLevel) {
      throw StateError('Only ${product.stockLevel} ${product.name} in stock.');
    }
    next[index] = current.copyWith(quantity: current.quantity + 1);
    state = next;
  }

  void remove(Product product) {
    state = state.where((item) => item.product.id != product.id).toList();
  }

  void clear() {
    state = const [];
  }

  Future<String> checkout() async {
    final session = ref.read(sessionControllerProvider).valueOrNull;
    final shift = session?.currentShift;
    if (session == null || shift == null) {
      throw StateError('An open shift is required before checkout.');
    }
    if (state.isEmpty) {
      throw StateError('Cart is empty.');
    }

    final soldItems = state;
    final receipt =
        await ref.read(offlineTransactionRepositoryProvider).saveSale(
              shopId: session.shop.id,
              cashierId: session.user.id,
              cashierName: session.user.name,
              shift: shift,
              items: soldItems,
              paymentMethod: 'cash',
            );
    final productRepository = ref.read(productRepositoryProvider);
    for (final item in soldItems) {
      await productRepository.reduceLocalStock(
        productId: item.product.id,
        quantity: item.quantity,
      );
    }
    clear();
    return receipt;
  }
}
