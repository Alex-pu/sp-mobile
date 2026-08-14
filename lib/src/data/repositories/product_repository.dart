import 'package:sqflite/sqflite.dart';

import '../../core/storage/local_database.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository(this._localDatabase);

  final LocalDatabase _localDatabase;

  Future<void> replaceCache(List<Product> products) async {
    final db = await _localDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('products');
      for (final product in products) {
        await txn.insert(
          'products',
          product.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await txn.insert(
          'local_meta',
          {
            'key': 'products_synced_at',
            'value': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<List<Product>> listActive({String search = ''}) async {
    final db = await _localDatabase.database;
    final trimmed = search.trim();
    final rows = trimmed.isEmpty
        ? await db.query(
            'products',
            where: 'is_active = ?',
            whereArgs: [1],
            orderBy: 'name collate nocase',
          )
        : await db.query(
            'products',
            where: 'is_active = ? and (name like ? or code like ?)',
            whereArgs: [1, '%$trimmed%', '%$trimmed%'],
            orderBy: 'name collate nocase',
          );
    return rows.map(Product.fromDb).toList();
  }

  Future<Product?> findByCode(String code) async {
    final db = await _localDatabase.database;
    final rows = await db.query(
      'products',
      where: 'is_active = ? and lower(code) = ?',
      whereArgs: [1, code.trim().toLowerCase()],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Product.fromDb(rows.first);
  }

  Future<void> reduceLocalStock({
    required String productId,
    required int quantity,
  }) async {
    final db = await _localDatabase.database;
    await db.rawUpdate(
      '''
      update products
      set stock_level = max(stock_level - ?, 0)
      where id = ?
      ''',
      [quantity, productId],
    );
  }
}
