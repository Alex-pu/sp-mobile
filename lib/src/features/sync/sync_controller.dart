import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/sync_repository.dart';
import '../auth/auth_controller.dart';
import '../products/product_providers.dart';

final pendingSalesCountProvider = FutureProvider<int>((ref) {
  return ref.watch(syncRepositoryProvider).pendingSalesCount();
});

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, ReconciliationResult?>(
  SyncController.new,
);

class SyncController extends AsyncNotifier<ReconciliationResult?> {
  @override
  Future<ReconciliationResult?> build() async => null;

  Future<void> reconcile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result =
          await ref.read(syncRepositoryProvider).reconcilePendingSales();
      await ref.read(sessionControllerProvider.notifier).refreshBootstrap();
      ref.invalidate(pendingSalesCountProvider);
      ref.invalidate(localProductsProvider);
      return result;
    });
  }
}
