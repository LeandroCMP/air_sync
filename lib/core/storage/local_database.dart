import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalDatabase {
  LocalDatabase();

  Database? _database;

  Future<void> init() async {
    final databasePath = await getDatabasesPath();
    final path = p.join(databasePath, 'airsync.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE orders (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE inventory_items (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE finance_transactions (
            id TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            updated_at TEXT
          );
        ''');
        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            method TEXT NOT NULL,
            body TEXT,
            headers TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          );
        ''');
      },
    );
  }

  Future<void> upsert(String table, String id, String payload, {String? updatedAt}) async {
    final db = _ensureDb();
    await db.insert(
      table,
      {
        'id': id,
        'payload': payload,
        'updated_at': updatedAt,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAll(String table) async {
    final db = _ensureDb();
    return db.query(table);
  }

  Future<Map<String, Object?>?> getById(String table, String id) async {
    final db = _ensureDb();
    final result = await db.query(table, where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) {
      return null;
    }
    return result.first;
  }

  Future<void> delete(String table, String id) async {
    final db = _ensureDb();
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear(String table) async {
    final db = _ensureDb();
    await db.delete(table);
  }

  Future<int> enqueueSync(String endpoint, String method, {String? body, String? headers}) async {
    final db = _ensureDb();
    return db.insert(
      'sync_queue',
      {
        'endpoint': endpoint,
        'method': method,
        'body': body,
        'headers': headers,
      },
    );
  }

  Future<List<Map<String, Object?>>> fetchSyncQueue() async {
    final db = _ensureDb();
    return db.query('sync_queue', orderBy: 'id ASC');
  }

  Future<void> removeSyncItem(int id) async {
    final db = _ensureDb();
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Database _ensureDb() {
    final db = _database;
    if (db == null) {
      throw StateError('Database not initialized');
    }
    return db;
  }
}
