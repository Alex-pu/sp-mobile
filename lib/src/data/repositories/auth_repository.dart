import '../../core/network/api_client.dart';
import '../../core/storage/secure_store.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._secureStore);

  final ApiClient _apiClient;
  final SecureStore _secureStore;

  Future<AppUser> login({required String name, required String pin}) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {'name': name, 'pin': pin},
    );
    final data = response.data as Map<String, dynamic>;
    await _secureStore.saveToken(data['token'] as String);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<void> logout() => _secureStore.clearToken();
}
