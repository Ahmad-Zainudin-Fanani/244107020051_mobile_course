import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/sync.dart';
import '../data/local/note.dart';
import '../widgets/note_tile.dart';

final notesProvider = FutureProvider.autoDispose<List<Note>>((ref) async {
  final repo = ref.read(noteRepositoryProvider);
  return repo.fetchNotes();
});

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsyncValue = ref.watch(notesProvider);
    final isOffline = ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          Row(
            children: [
              const Text('Offline', style: TextStyle(fontSize: 12)),
              Switch(
                value: isOffline,
                onChanged: (val) {
                  ref.read(forceOfflineProvider.notifier).toggle(val);
                  if (!val) {
                    _syncData(context, ref);
                  }
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notesAsyncValue.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteTile(
                note: note,
                onTap: () {
                  if (note.id != null) {
                    context.push('/note/${note.id}');
                  }
                },
                onLongPress: () async {
                  if (note.id != null) {
                    await ref.read(noteRepositoryProvider).deleteNote(note.id!);
                    ref.invalidate(notesProvider);
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = 'New Note ${DateTime.now().second}';
          await ref.read(noteRepositoryProvider).addNote(title: title);
          ref.invalidate(notesProvider);
          // Cobaan sinkronisasi setiap kali catatan baru ditambahkan
          _syncData(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    try {
      final synced = await ref.read(syncServiceProvider).syncNotes(repo);
      if (synced > 0) {
        ref.invalidate(notesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sync successful!')),
          );
        }
      } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All synced up!')),
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    }
  }
}
