import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/shop.dart';
import '../../data/repositories/pairing_repository.dart';

final pairingRepositoryProvider = Provider<PairingRepository>((ref) {
  return PairingRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  );
});

final pairingControllerProvider =
    AsyncNotifierProvider<PairingController, Shop?>(PairingController.new);

class PairingController extends AsyncNotifier<Shop?> {
  @override
  Future<Shop?> build() {
    return ref.read(pairingRepositoryProvider).readPairedShop();
  }

  Future<void> acceptInvite({
    required String token,
    required String deviceLabel,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(pairingRepositoryProvider).acceptInvite(
            token: token,
            deviceLabel: deviceLabel,
          );
    });
  }

  Future<void> clearPairing() async {
    await ref.read(pairingRepositoryProvider).clearPairing();
    state = const AsyncData(null);
  }
}
