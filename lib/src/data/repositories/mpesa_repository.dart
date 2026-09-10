import '../../core/network/api_client.dart';

class MpesaRepository {
  MpesaRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<String> requestStkPush({
    required String shopId,
    required String transactionId,
    required double amount,
    required String phoneNumber,
  }) async {
    final response = await _apiClient.dio.post(
      '/payments/requests',
      data: {
        'shopId': shopId,
        'transactionId': transactionId,
        'amount': amount,
        'method': 'stk_push',
        'phoneNumber': phoneNumber,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final payment = data['data'] as Map<String, dynamic>;
    return payment['id'] as String;
  }

  Future<String> paymentStatus(String paymentId) async {
    final response = await _apiClient.dio.get('/payments/$paymentId');
    final data = response.data as Map<String, dynamic>;
    return (data['data'] as Map<String, dynamic>)['status'] as String;
  }

  Future<String> waitForConfirmation({
    required String paymentId,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final status = await paymentStatus(paymentId);
      if (status == 'matched' || status == 'failed') {
        return status;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return 'pending';
  }
}
