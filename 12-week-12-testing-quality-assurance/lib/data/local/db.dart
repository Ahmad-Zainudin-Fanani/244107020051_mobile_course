import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Database? _db;

/// Membuat skema database catatan.
///
/// Dipisahkan dari [openNotesDb] agar pengujian dapat membangun database
/// in-memory dengan skema yang sama tanpa menyalin SQL-nya. Duplikasi skema di
/// test cepat basi dan membuat test lulus pada struktur tabel yang salah.
Future<void> createNotesSchema(Database db) async {
  await db.execute('''
    CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      body TEXT NOT NULL DEFAULT '',
      updated_at TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE cached_posts(
      id INTEGER PRIMARY KEY,
      payload TEXT NOT NULL,
      cached_at TEXT NOT NULL
    )
  ''');
}

Future<Database> openNotesDb() async {
  if (_db != null && _db!.isOpen) {
    return _db!;
  }

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  String dbPath = 'offline_notes.db';
  if (!kIsWeb) {
    final dir = await getDatabasesPath();
    dbPath = p.join(dir, 'offline_notes.db');
  }

  _db = await openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) => createNotesSchema(db),
  );
  return _db!;
}
