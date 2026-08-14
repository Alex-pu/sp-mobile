import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/api_client.dart';
import '../storage/local_database.dart';
import '../storage/secure_store.dart';

final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(const FlutterSecureStorage());
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStoreProvider));
});

final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  return LocalDatabase();
});
