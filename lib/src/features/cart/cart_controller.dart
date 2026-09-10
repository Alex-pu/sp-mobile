import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/cart_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/mpesa_repository.dart';
import '../../data/repositories/offline_transaction_repository.dart';
import '../auth/auth_controller.dart';

final offlineTransactionRepositoryProvider =
    Provider<OfflineTransactionRepository>((ref) {
  return OfflineTransactionRepository(ref.watch(localDatabaseProvider));
});

final mpesaRepositoryProvider = Provider<MpesaRepository>((ref) {
  return MpesaRepository(ref.watch(apiClientProvider));
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

  Future<PendingSale> checkout({
    String paymentMethod = 'cash',
    String? phoneNumber,
  }) async {
    final session = ref.read(sessionControllerProvider).valueOrNull;
    final shift = session?.currentShift;
    if (session == null || shift == null) {
      throw StateError('An open shift is required before checkout.');
    }
    if (state.isEmpty) {
      throw StateError('Cart is empty.');
    }

    final soldItems = state;
    final transactionId = paymentMethod == 'mpesa' ? const Uuid().v4() : null;
    if (paymentMethod == 'mpesa') {
      if (phoneNumber == null || phoneNumber.trim().isEmpty) {
        throw StateError('A customer phone number is required for M-Pesa.');
      }
      final paymentId = await ref.read(mpesaRepositoryProvider).requestStkPush(
            shopId: session.shop.id,
            transactionId: transactionId!,
            amount: total,
            phoneNumber: phoneNumber.trim(),
          );
      final status =
          await ref.read(mpesaRepositoryProvider).waitForConfirmation(
                paymentId: paymentId,
              );
      if (status != 'matched') {
        throw StateError(
          status == 'failed'
              ? 'M-Pesa payment failed.'
              : 'M-Pesa payment is still pending. Try again after confirmation.',
        );
      }
    }
    final sale = await ref.read(offlineTransactionRepositoryProvider).saveSale(
          shopId: session.shop.id,
          cashierId: session.user.id,
          cashierName: session.user.name,
          shift: shift,
          items: soldItems,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
        );
    final productRepository = ref.read(productRepositoryProvider);
    for (final item in soldItems) {
      await productRepository.reduceLocalStock(
        productId: item.product.id,
        quantity: item.quantity,
      );
    }
    clear();
    return sale;
  }
}
