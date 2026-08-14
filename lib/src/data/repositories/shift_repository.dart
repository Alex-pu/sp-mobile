import '../../core/network/api_client.dart';
import '../models/shift.dart';

class ShiftRepository {
  ShiftRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<Shift> openShift(double openingFloat) async {
    final response = await _apiClient.dio.post(
      '/shifts',
      data: {'openingFloat': openingFloat},
    );
    final data = response.data as Map<String, dynamic>;
    return Shift.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Shift?> currentShift() async {
    try {
      final response = await _apiClient.dio.get('/shifts/current');
      final data = response.data as Map<String, dynamic>;
      return Shift.fromJson(data['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Shift> closeShift({
    required String shiftId,
    required double closingCash,
    String notes = '',
  }) async {
    final response = await _apiClient.dio.put(
      '/shifts/$shiftId/close',
      data: {'closingCash': closingCash, 'notes': notes},
    );
    final data = response.data as Map<String, dynamic>;
    return Shift.fromJson(data['data'] as Map<String, dynamic>);
  }
}
