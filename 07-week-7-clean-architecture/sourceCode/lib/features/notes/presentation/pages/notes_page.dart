import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/sync.dart' show forceOfflineProvider;
import '../providers/notes_providers.dart';
import '../widgets/error_view.dart';
import '../widgets/note_tile.dart';

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
            return const Center(child: Text('Belum ada catatan.'));
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
        error: (err, _) => ErrorView(
          message: '$err',
          onRetry: () => ref.invalidate(notesProvider),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = 'Catatan Baru ${DateTime.now().second}';
          final result = await ref.read(addNoteProvider).call(title: title);
          if (result.failure != null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result.failure!.message)),
              );
            }
          } else {
            ref.invalidate(notesProvider);
            if (context.mounted) {
              _syncData(context, ref);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    try {
      final countResult = await repo.countDirty();
      final dirtyCount = countResult.count;
      if (ref.read(forceOfflineProvider)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Mode Offline aktif. Tidak dapat sinkron.')),
          );
        }
        return;
      }
      if (dirtyCount > 0) {
        await Future.delayed(const Duration(seconds: 1));
        await repo.markAllSynced();
        ref.invalidate(notesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sinkronisasi berhasil!')),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua catatan sudah tersinkron.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal sinkron: $e')),
        );
      }
    }
  }
}
