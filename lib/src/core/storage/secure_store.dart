import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static const tokenKey = 'auth_token';
  static const apiBaseUrlKey = 'api_base_url';
  static const pairedShopIdKey = 'paired_shop_id';
  static const pairedShopNameKey = 'paired_shop_name';
  static const pairedShopLocationKey = 'paired_shop_location';
  static const deviceIdKey = 'device_id';
  static const printerTransportKey = 'printer_transport';
  static const printerNameKey = 'printer_name';
  static const printerAddressKey = 'printer_address';
  static const printerPaperWidthKey = 'printer_paper_width';

  Future<String?> readToken() => _storage.read(key: tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: tokenKey);

  Future<String?> readApiBaseUrl() => _storage.read(key: apiBaseUrlKey);

  Future<void> saveApiBaseUrl(String value) =>
      _storage.write(key: apiBaseUrlKey, value: value);

  Future<String?> readDeviceId() => _storage.read(key: deviceIdKey);

  Future<void> saveDeviceId(String value) =>
      _storage.write(key: deviceIdKey, value: value);

  Future<void> savePairedShop({
    required String id,
    required String name,
    required String location,
  }) async {
    await _storage.write(key: pairedShopIdKey, value: id);
    await _storage.write(key: pairedShopNameKey, value: name);
    await _storage.write(key: pairedShopLocationKey, value: location);
  }

  Future<Map<String, String>?> readPairedShop() async {
    final id = await _storage.read(key: pairedShopIdKey);
    final name = await _storage.read(key: pairedShopNameKey);
    if (id == null || name == null) {
      return null;
    }
    return {
      'id': id,
      'name': name,
      'location': await _storage.read(key: pairedShopLocationKey) ?? '',
    };
  }

  Future<void> clearPairing() async {
    await _storage.delete(key: pairedShopIdKey);
    await _storage.delete(key: pairedShopNameKey);
    await _storage.delete(key: pairedShopLocationKey);
  }

  Future<void> savePrinterConfig({
    required String transport,
    required String name,
    required String address,
    required int paperWidth,
  }) async {
    await _storage.write(key: printerTransportKey, value: transport);
    await _storage.write(key: printerNameKey, value: name);
    await _storage.write(key: printerAddressKey, value: address);
    await _storage.write(
      key: printerPaperWidthKey,
      value: paperWidth.toString(),
    );
  }

  Future<Map<String, String>> readPrinterConfig() async {
    return {
      'transport': await _storage.read(key: printerTransportKey) ?? 'none',
      'name': await _storage.read(key: printerNameKey) ?? '',
      'address': await _storage.read(key: printerAddressKey) ?? '',
      'paperWidth': await _storage.read(key: printerPaperWidthKey) ?? '48',
    };
  }
}
