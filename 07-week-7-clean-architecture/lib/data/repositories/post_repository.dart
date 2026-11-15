import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  PostRepository({Future<Database> Function()? openDb})
      : _openDb = openDb ?? openNotesDb;

  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts');
    if (rows.isEmpty) return [];
    
    // Asumsi baris pertama menyimpan semua payload JSON array
    final payload = rows.first['payload'] as String;
    final List<dynamic> jsonList = jsonDecode(payload);
    return jsonList.map((e) => Post.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> replaceCachedPosts(List<Post> posts) async {
    final db = await _openDb();
    await db.transaction((txn) async {
      await txn.delete('cached_posts'); // hapus cache lama
      final payload = jsonEncode(posts.map((p) => p.toMap()).toList());
      await txn.insert('cached_posts', {
        'id': 1,
        'payload': payload,
        'cached_at': DateTime.now().toIso8601String(),
      });
    });
  }
}
