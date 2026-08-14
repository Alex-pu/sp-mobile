import '../../core/network/api_client.dart';
import '../models/bootstrap_data.dart';
import 'offline_transaction_repository.dart';
import 'product_repository.dart';

class ReconciliationResult {
  const ReconciliationResult({
    required this.submitted,
    required this.synced,
    required this.failed,
    required this.pendingAfter,
    this.errors = const [],
  });

  final int submitted;
  final int synced;
  final int failed;
  final int pendingAfter;
  final List<String> errors;
}

class SyncRepository {
  SyncRepository(
    this._apiClient,
    this._productRepository,
    this._offlineTransactionRepository,
  );

  final ApiClient _apiClient;
  final ProductRepository _productRepository;
  final OfflineTransactionRepository _offlineTransactionRepository;

  Future<BootstrapData> bootstrap() async {
    final response = await _apiClient.dio.get('/sync/bootstrap');
    final data = response.data as Map<String, dynamic>;
    final bootstrap = BootstrapData.fromJson(data);
    await _productRepository.replaceCache(bootstrap.products);
    return bootstrap;
  }

  Future<int> pendingSalesCount() {
    return _offlineTransactionRepository.pendingCount();
  }

  Future<ReconciliationResult> reconcilePendingSales() async {
    final pending = await _offlineTransactionRepository.pendingSales();
    if (pending.isEmpty) {
      return ReconciliationResult(
        submitted: 0,
        synced: 0,
        failed: 0,
        pendingAfter: await _offlineTransactionRepository.pendingCount(),
      );
    }

    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/transactions/batch',
      data: {'transactions': pending.map((sale) => sale.payload).toList()},
    );
    final results = response.data!['results'] as Map<String, dynamic>;
    final errors = ((results['errors'] as List<dynamic>?) ?? const [])
        .map((item) => item.toString())
        .toList();
    final errorsById = _errorsByTransactionId(errors);
    final failedIds = errorsById.keys.toSet();
    final syncedIds = pending
        .map((sale) => sale.id)
        .where((id) => !failedIds.contains(id))
        .toList();

    await _offlineTransactionRepository.markSynced(syncedIds);
    await _offlineTransactionRepository.markFailed(errorsById);

    return ReconciliationResult(
      submitted: pending.length,
      synced: syncedIds.length,
      failed: failedIds.length,
      pendingAfter: await _offlineTransactionRepository.pendingCount(),
      errors: errors,
    );
  }

  Map<String, String> _errorsByTransactionId(List<String> errors) {
    final mapped = <String, String>{};
    for (final error in errors) {
      final separator = error.indexOf(':');
      if (separator <= 0) {
        continue;
      }
      final id = error.substring(0, separator).trim();
      if (id.isNotEmpty && id != '?') {
        mapped[id] = error.substring(separator + 1).trim();
      }
    }
    return mapped;
  }
}
