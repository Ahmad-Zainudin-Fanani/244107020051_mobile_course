import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/note_repository.dart';
import 'repositories/post_repository.dart';
import 'local/post.dart';

final syncServiceProvider = Provider((ref) {
  final isOffline = ref.watch(forceOfflineProvider);
  return SyncService(isOffline);
});
final postRepositoryProvider = Provider((ref) => PostRepository());
final noteRepositoryProvider = Provider((ref) => NoteRepository());

// Provider untuk force offline secara deterministik (simulasi offline)
class ForceOfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle(bool val) => state = val;
}

final forceOfflineProvider =
    NotifierProvider<ForceOfflineNotifier, bool>(ForceOfflineNotifier.new);

// --- Sync Notes ---

class SyncService {
  SyncService(this.isOffline);
  final bool isOffline;

  Future<int> syncNotes(NoteRepository repo) async {
    if (isOffline) {
      throw Exception('Force Offline is ON. Cannot sync.');
    }
    
    final dirtyCount = await repo.countDirty();
    if (dirtyCount == 0) return 0;
    
    // ATURAN KONFLIK: Last-write-wins berdasarkan updated_at.
    // Tanpa aturan eksplisit, data akan tertimpa. 
    // Di simulasi ini, kita anggap server memprioritaskan data terbaru.
    
    // Simulasi delay jaringan (mengunggah ke server)
    await Future.delayed(const Duration(seconds: 1));
    
    // Jika berhasil (2xx), tandai semua bersih
    await repo.markAllSynced();
    return dirtyCount;
  }
}


// --- Posts Cache First ---

class PostsSyncService {
  PostsSyncService(this.repo, this.ref, this.isForceOffline);
  final PostRepository repo;
  final Ref ref;
  final bool isForceOffline;
  final _dio = Dio();

  Future<List<Post>> loadPostsCacheFirst() async {
    final cached = await repo.readCachedPosts();
    
    if (cached.isNotEmpty) {
      if (!isForceOffline) {
        refreshPostsInBackground();
      }
      return cached;
    }
    
    if (!isForceOffline) {
      return await fetchAndCachePosts();
    }
    
    return cached;
  }

  Future<List<Post>> fetchAndCachePosts() async {
    try {
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');
      final data = response.data as List;
      final posts = data.map((e) => Post.fromMap(e as Map<String, dynamic>)).toList();
      await repo.replaceCachedPosts(posts);
      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<void> refreshPostsInBackground() async {
    try {
      final response = await _dio.get('https://jsonplaceholder.typicode.com/posts');
      final data = response.data as List;
      final posts = data.map((e) => Post.fromMap(e as Map<String, dynamic>)).toList();
      await repo.replaceCachedPosts(posts);
    } catch (e) {
      // Ignore background refresh errors
    }
  }
}

