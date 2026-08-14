import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../core/storage/local_database.dart';
import '../models/cart_item.dart';
import '../models/shift.dart';

class PendingSale {
  const PendingSale({
    required this.id,
    required this.receiptNumber,
    required this.payload,
  });

  final String id;
  final String receiptNumber;
  final Map<String, dynamic> payload;
}

class OfflineTransactionRepository {
  OfflineTransactionRepository(this._localDatabase);

  final LocalDatabase _localDatabase;
  final _uuid = const Uuid();

  Future<String> saveSale({
    required String shopId,
    required String cashierId,
    required String cashierName,
    required Shift shift,
    required List<CartItem> items,
    required String paymentMethod,
  }) async {
    final db = await _localDatabase.database;
    final id = _uuid.v4();
    final receiptNumber = _receiptNumber();
    final now = DateTime.now().toUtc().toIso8601String();
    final total = items.fold<double>(0, (sum, item) => sum + item.lineTotal);

    final payload = {
      'id': id,
      'receiptNumber': receiptNumber,
      'shopId': shopId,
      'shiftId': shift.id,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'subtotal': total,
      'discountTotal': 0,
      'taxTotal': 0,
      'grandTotal': total,
      'paymentMethod': paymentMethod,
      'createdAt': now,
      'items': items
          .map(
            (item) => {
              'productId': item.product.id,
              'productCode': item.product.code,
              'productName': item.product.name,
              'quantity': item.quantity,
              'unitPrice': item.product.sellingPrice,
              'discount': 0,
              'lineTotal': item.lineTotal,
            },
          )
          .toList(),
      'payments': [
        {
          'method': paymentMethod,
          'amount': total,
        }
      ],
    };

    await db.insert('offline_transactions', {
      'id': id,
      'receipt_number': receiptNumber,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': now,
      'last_error': null,
    });

    return receiptNumber;
  }

  Future<List<PendingSale>> pendingSales({int limit = 50}) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'offline_transactions',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at',
      limit: limit,
    );
    return rows.map((row) {
      return PendingSale(
        id: row['id'] as String,
        receiptNumber: row['receipt_number'] as String,
        payload: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<int> pendingCount() async {
    final db = await _localDatabase.database;
    final result = await db.rawQuery(
      '''
      select count(*) as count
      from offline_transactions
      where status = ?
      ''',
      ['pending'],
    );
    return (result.first['count'] as num).toInt();
  }

  Future<void> markSynced(Iterable<String> ids) async {
    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.update(
          'offline_transactions',
          {'status': 'synced', 'last_error': null},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<void> markFailed(Map<String, String> errorsById) async {
    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      for (final entry in errorsById.entries) {
        await txn.update(
          'offline_transactions',
          {'status': 'pending', 'last_error': entry.value},
          where: 'id = ?',
          whereArgs: [entry.key],
        );
      }
    });
  }

  String _receiptNumber() {
    final now = DateTime.now().toUtc();
    return 'MOB-${now.millisecondsSinceEpoch}';
  }
}
