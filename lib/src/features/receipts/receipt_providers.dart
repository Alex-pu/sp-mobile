import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/core_providers.dart';
import '../../data/models/receipt.dart';
import '../../data/repositories/printer_repository.dart';
import '../../data/repositories/receipt_repository.dart';

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(ref.watch(localDatabaseProvider));
});

final printerRepositoryProvider = Provider<PrinterRepository>((ref) {
  return PrinterRepository(ref.watch(secureStoreProvider));
});

final recentReceiptsProvider = FutureProvider<List<Receipt>>((ref) {
  return ref.watch(receiptRepositoryProvider).recent();
});

final receiptByNumberProvider =
    FutureProvider.family<Receipt?, String>((ref, receiptNumber) {
  return ref
      .watch(receiptRepositoryProvider)
      .findByReceiptNumber(receiptNumber);
});
