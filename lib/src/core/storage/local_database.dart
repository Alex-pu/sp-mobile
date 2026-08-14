import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;

    final docs = await getApplicationDocumentsDirectory();
    final path = p.join(docs.path, 'sp_mobile.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          create table local_meta (
            key text primary key,
            value text not null
          )
        ''');
        await db.execute('''
          create table products (
            id text primary key,
            code text not null,
            name text not null,
            category text,
            selling_price real not null,
            cost_price real not null,
            stock_level integer not null,
            reorder_level integer not null,
            is_active integer not null
          )
        ''');
        await db.execute('''
          create table shifts (
            id text primary key,
            shop_id text not null,
            cashier_id text not null,
            status text not null,
            opening_float real not null,
            opened_at text not null
          )
        ''');
        await db.execute('''
          create table offline_transactions (
            id text primary key,
            receipt_number text not null,
            payload text not null,
            status text not null,
            created_at text not null,
            last_error text
          )
        ''');
        await db.execute('''
          create table offline_expenses (
            id text primary key,
            payload text not null,
            status text not null,
            created_at text not null,
            last_error text
          )
        ''');
      },
    );
    return _db!;
  }
}
