import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/bootstrap_data.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/offline_transaction_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/sync_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  );
});

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(
    ref.watch(apiClientProvider),
    ref.watch(productRepositoryProvider),
    OfflineTransactionRepository(ref.watch(localDatabaseProvider)),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(localDatabaseProvider));
});

final sessionControllerProvider =
    AsyncNotifierProvider<SessionController, BootstrapData?>(
  SessionController.new,
);

class SessionController extends AsyncNotifier<BootstrapData?> {
  @override
  Future<BootstrapData?> build() async {
    return null;
  }

  Future<void> login(String name, String pin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(name: name, pin: pin);
      return ref.read(syncRepositoryProvider).bootstrap();
    });
  }

  Future<void> refreshBootstrap() async {
    state = await AsyncValue.guard(
      () => ref.read(syncRepositoryProvider).bootstrap(),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
