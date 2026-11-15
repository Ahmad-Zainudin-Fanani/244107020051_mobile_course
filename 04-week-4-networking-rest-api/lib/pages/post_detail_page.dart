import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/providers.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage({super.key, required this.postId});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(singlePostProvider(postId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Post #$postId'),
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendlyErrorMessage(err),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(singlePostProvider(postId)),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
        data: (post) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(post.id.toString()),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'User ID: ${post.userId}',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      post.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      post.body,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
