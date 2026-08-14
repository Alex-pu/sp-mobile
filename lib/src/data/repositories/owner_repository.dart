import '../../core/network/api_client.dart';
import '../../core/storage/secure_store.dart';
import '../models/app_user.dart';
import '../models/device_invite.dart';
import '../models/product.dart';
import '../models/shop.dart';

class OwnerRepository {
  OwnerRepository(this._apiClient, this._secureStore);

  final ApiClient _apiClient;
  final SecureStore _secureStore;

  Future<bool> needsSetup() async {
    final response = await _apiClient.dio.get('/auth/setup/status');
    final data = response.data as Map<String, dynamic>;
    return data['needsSetup'] as bool;
  }

  Future<AppUser> setupOwner({
    required String name,
    required String pin,
    required String shopName,
    required String shopLocation,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/setup',
      data: {
        'name': name,
        'pin': pin,
        'shopName': shopName,
        'shopLocation': shopLocation,
      },
    );
    final data = response.data as Map<String, dynamic>;
    await _secureStore.saveToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<AppUser> login({
    required String name,
    required String pin,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {'name': name, 'pin': pin},
    );
    final data = response.data as Map<String, dynamic>;
    final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
    if (!user.isOwner) {
      throw StateError('This login is not an owner account.');
    }
    await _secureStore.saveToken(data['token'] as String);
    return user;
  }

  Future<List<Shop>> listShops() async {
    final response = await _apiClient.dio.get('/shops');
    final data = response.data as Map<String, dynamic>;
    final shops = data['data'] as List<dynamic>;
    return shops
        .map((shop) => Shop.fromJson(shop as Map<String, dynamic>))
        .toList();
  }

  Future<Shop> createShop({
    required String name,
    required String location,
  }) async {
    final response = await _apiClient.dio.post(
      '/shops',
      data: {'name': name, 'location': location},
    );
    final data = response.data as Map<String, dynamic>;
    return Shop.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<AppUser> createCashier({
    required String name,
    required String pin,
    required String shopId,
  }) async {
    final response = await _apiClient.dio.post(
      '/auth/users',
      data: {
        'name': name,
        'pin': pin,
        'role': 'cashier',
        'shopId': shopId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<List<Product>> listProducts({
    required String shopId,
    String search = '',
  }) async {
    final response = await _apiClient.dio.get(
      '/products',
      queryParameters: {
        'shopId': shopId,
        'search': search,
        'per_page': 500,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final products = data['data'] as List<dynamic>;
    return products
        .map((product) => Product.fromJson(product as Map<String, dynamic>))
        .toList();
  }

  Future<Product> setProductStock({
    required String shopId,
    required Product product,
    required int stockLevel,
  }) async {
    await _apiClient.dio.put(
      '/products/${product.id}',
      data: {
        'shopId': shopId,
        'stockLevel': stockLevel,
        'reorderLevel': product.reorderLevel,
        'stockReason': 'Owner stock update',
      },
    );
    return product.copyWith(stockLevel: stockLevel);
  }

  Future<DeviceInvite> createDeviceInvite({
    required String shopId,
    required String deviceLabel,
  }) async {
    final response = await _apiClient.dio.post(
      '/device-invites',
      data: {
        'shopId': shopId,
        'deviceLabel': deviceLabel,
        'expiresInHours': 24,
      },
    );
    return DeviceInvite.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() => _secureStore.clearToken();
}
