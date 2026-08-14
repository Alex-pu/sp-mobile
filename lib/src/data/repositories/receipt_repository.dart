import 'dart:convert';

import '../../core/storage/local_database.dart';
import '../models/receipt.dart';

class ReceiptRepository {
  ReceiptRepository(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<Receipt?> findByReceiptNumber(String receiptNumber) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'offline_transactions',
      where: 'receipt_number = ?',
      whereArgs: [receiptNumber],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return _fromRow(rows.first);
  }

  Future<List<Receipt>> recent({int limit = 20}) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'offline_transactions',
      orderBy: 'created_at desc',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Receipt _fromRow(Map<String, dynamic> row) {
    return Receipt.fromPayload(
      status: row['status'] as String,
      payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
    );
  }
}
