import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sync.dart';
import '../data/local/post.dart';

final postsProvider = FutureProvider.autoDispose<List<Post>>((ref) async {
  final repo = ref.read(postRepositoryProvider);
  final isOffline = ref.watch(forceOfflineProvider);
  final service = PostsSyncService(repo, ref, isOffline);
  return service.loadPostsCacheFirst();
});

class PostsPage extends ConsumerWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(postsProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Posts (Cache-First)'),
        actions: [
          Row(
            children: [
              const Text('Offline', style: TextStyle(fontSize: 12)),
              Switch(
                value: isOffline,
                onChanged: (val) => ref.read(forceOfflineProvider.notifier).toggle(val),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(postsProvider),
          )
        ],
      ),
      body: postsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(child: Text('No cached posts yet. Turn off offline mode and refresh.'));
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      post.id.toString(),
                      style: TextStyle(color: Colors.blue.shade900),
                    ),
                  ),
                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    post.body.replaceAll('\n', ' '), // Keep it compact
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
