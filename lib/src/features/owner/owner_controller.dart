import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/app_user.dart';
import '../../data/models/device_invite.dart';
import '../../data/models/product.dart';
import '../../data/models/shop.dart';
import '../../data/repositories/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository(
    ref.watch(apiClientProvider),
    ref.watch(secureStoreProvider),
  );
});

final ownerSetupStatusProvider = FutureProvider<bool>((ref) {
  return ref.watch(ownerRepositoryProvider).needsSetup();
});

final ownerSessionProvider =
    AsyncNotifierProvider<OwnerSessionController, AppUser?>(
  OwnerSessionController.new,
);

class OwnerSessionController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    return null;
  }

  Future<void> setupOwner({
    required String name,
    required String pin,
    required String shopName,
    required String shopLocation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ownerRepositoryProvider).setupOwner(
            name: name,
            pin: pin,
            shopName: shopName,
            shopLocation: shopLocation,
          ),
    );
  }

  Future<void> login(String name, String pin) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(ownerRepositoryProvider).login(name: name, pin: pin),
    );
  }

  Future<void> logout() async {
    await ref.read(ownerRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final shopsProvider = FutureProvider<List<Shop>>((ref) {
  final owner = ref.watch(ownerSessionProvider).valueOrNull;
  if (owner == null) {
    return <Shop>[];
  }
  return ref.watch(ownerRepositoryProvider).listShops();
});

final ownerProductSearchProvider =
    StateProvider.autoDispose<String>((ref) => '');

final ownerProductsProvider = FutureProvider.autoDispose
    .family<List<Product>, ({String shopId, String search})>((ref, query) {
  return ref.watch(ownerRepositoryProvider).listProducts(
        shopId: query.shopId,
        search: query.search,
      );
});

final ownerActionProvider = AsyncNotifierProvider<OwnerActionController, void>(
  OwnerActionController.new,
);

class OwnerActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> createShop({
    required String name,
    required String location,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(ownerRepositoryProvider).createShop(
            name: name,
            location: location,
          );
    });
    ref.invalidate(shopsProvider);
  }

  Future<void> createCashier({
    required String name,
    required String pin,
    required String shopId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(ownerRepositoryProvider).createCashier(
            name: name,
            pin: pin,
            shopId: shopId,
          );
    });
  }

  Future<DeviceInvite?> createInvite({
    required String shopId,
    required String deviceLabel,
  }) async {
    state = const AsyncLoading();
    DeviceInvite? invite;
    state = await AsyncValue.guard(() async {
      invite = await ref.read(ownerRepositoryProvider).createDeviceInvite(
            shopId: shopId,
            deviceLabel: deviceLabel,
          );
    });
    return invite;
  }
}
