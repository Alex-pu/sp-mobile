import 'package:uuid/uuid.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/secure_store.dart';
import '../models/shop.dart';

class PairingRepository {
  PairingRepository(this._apiClient, this._secureStore);

  final ApiClient _apiClient;
  final SecureStore _secureStore;
  static const _uuid = Uuid();

  Future<Shop?> readPairedShop() async {
    final saved = await _secureStore.readPairedShop();
    if (saved == null) {
      return null;
    }
    return Shop(
      id: saved['id']!,
      name: saved['name']!,
      location: saved['location'] ?? '',
    );
  }

  Future<Shop> acceptInvite({
    required String token,
    required String deviceLabel,
  }) async {
    final deviceId = await _deviceId();
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/device-invites/$token/accept',
      data: {'deviceId': deviceId, 'deviceLabel': deviceLabel},
    );
    final shop = Shop.fromJson(response.data!['shop'] as Map<String, dynamic>);
    await _secureStore.savePairedShop(
      id: shop.id,
      name: shop.name,
      location: shop.location,
    );
    return shop;
  }

  Future<void> clearPairing() => _secureStore.clearPairing();

  Future<String> _deviceId() async {
    final existing = await _secureStore.readDeviceId();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = _uuid.v4();
    await _secureStore.saveDeviceId(created);
    return created;
  }
}
