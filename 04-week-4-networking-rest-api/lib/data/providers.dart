import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'api_client.dart';
import 'models/post.dart';
import 'repositories/post_repository.dart';
import 'paged_posts.dart';

export 'network_errors.dart';

final dioProvider = Provider<Dio>((ref) => createDio());

final postRepositoryProvider = Provider<PostRepository>(
  (ref) => PostRepository(ref.watch(dioProvider)),
);

class PostListNotifier extends AsyncNotifier<List<Post>> {
  @override
  Future<List<Post>> build() async {
    final repository = ref.watch(postRepositoryProvider);
    return repository.fetchPosts();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(postRepositoryProvider);
      state = AsyncData(await repository.fetchPosts());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final postListProvider =
    AsyncNotifierProvider<PostListNotifier, List<Post>>(
        PostListNotifier.new,
        retry: (retryCount, error) => null);

/// Provider untuk mengambil single post berdasarkan ID.
/// Pertama mencari di memori (postListProvider atau pagedPostsProvider).
/// Jika tidak ada, memanggil repository.fetchPost(id).
final singlePostProvider = FutureProvider.family<Post, int>((ref, id) async {
  // Cek di postListProvider jika sudah dimuat
  final postsAsync = ref.watch(postListProvider);
  if (postsAsync.hasValue) {
    final found = postsAsync.value?.where((p) => p.id == id).firstOrNull;
    if (found != null) return found;
  }

  // Cek di pagedPostsProvider jika sudah dimuat
  final pagedState = ref.watch(pagedPostsProvider);
  final pagedFound = pagedState.items.where((p) => p.id == id).firstOrNull;
  if (pagedFound != null) return pagedFound;

  // Jika tidak ditemukan di memori, panggil repository
  final repo = ref.watch(postRepositoryProvider);
  return repo.fetchPost(id);
});

Future<List<Post>> readPostsOnce(ProviderContainer container) {
  final completer = Completer<List<Post>>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      next.whenData(completer.complete);
      if (next.hasError) {
        completer.completeError(
          next.error ?? StateError('unknown error'),
          next.stackTrace ?? StackTrace.empty,
        );
      }
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}

Future<Object?> readPostsErrorOnce(ProviderContainer container) {
  final completer = Completer<Object?>();
  final sub = container.listen<AsyncValue<List<Post>>>(
    postListProvider,
    (previous, next) {
      if (next.isLoading || completer.isCompleted) return;
      completer.complete(next.error);
    },
    fireImmediately: true,
  );
  return completer.future.whenComplete(sub.close);
}
