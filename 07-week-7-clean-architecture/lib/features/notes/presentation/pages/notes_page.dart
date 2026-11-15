import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/sync.dart' show forceOfflineProvider;
import '../providers/notes_providers.dart';
import '../widgets/error_view.dart';
import '../widgets/note_tile.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  final TextEditingController _quickController = TextEditingController();

  @override
  void dispose() {
    _quickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsyncValue = ref.watch(notesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notesList = notesAsyncValue.value ?? [];
    final dirtyCount = notesList.where((n) => n.dirty).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catatan Saya',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            Text(
              dirtyCount > 0
                  ? '${notesList.length} catatan • $dirtyCount perlu sinkron'
                  : '${notesList.length} catatan • Semua tersinkron',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.sync_rounded, size: 26),
                if (dirtyCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444), // Red-500
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$dirtyCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Sinkronkan Sekarang',
            onPressed: () => _syncData(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Quick Input Bar Desain Bersih
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_outlined,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _quickController,
                      decoration: InputDecoration(
                        hintText: 'Tulis catatan cepat di sini...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _handleQuickAdd(),
                    ),
                  ),
                  InkWell(
                    onTap: _handleQuickAdd,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Daftar Catatan
          Expanded(
            child: notesAsyncValue.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            size: 64,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Catatan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mulai tuliskan ide atau pekerjaan Anda hari ini.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(notesProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
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
                        onLongPress: () =>
                            _confirmDelete(context, ref, note.id!),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorView(
                message: '$err',
                onRetry: () => ref.invalidate(notesProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => _showAddNoteDialog(context, ref),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Buat Catatan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  void _handleQuickAdd() async {
    final text = _quickController.text.trim();
    if (text.isEmpty) return;

    _quickController.clear();
    final result = await ref.read(addNoteProvider).call(title: text);
    if (!mounted) return;

    if (result.failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.failure!.message),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      ref.invalidate(notesProvider);
    }
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buat Catatan Baru',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Contoh: Rencana Mingguan',
                  prefixIcon: const Icon(Icons.title_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Deskripsi Catatan (Opsional)',
                  hintText: 'Tuliskan rincian isi catatan...',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text(
                    'Simpan ke Database',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();

                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Judul catatan tidak boleh kosong.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.pop(bottomSheetContext);

                    final result = await ref
                        .read(addNoteProvider)
                        .call(title: title, body: body);

                    if (!context.mounted) return;

                    if (result.failure != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.failure!.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      ref.invalidate(notesProvider);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Catatan?'),
        content: const Text('Catatan ini akan dihapus dari basis data lokal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(noteRepositoryProvider).deleteNote(id);
              ref.invalidate(notesProvider);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    try {
      final isOffline = ref.read(forceOfflineProvider);
      if (isOffline) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mode Offline aktif. Tidak dapat menyinkronkan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final countResult = await repo.countDirty();
      final dirtyCount = countResult.count;
      if (dirtyCount > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await repo.markAllSynced();
        ref.invalidate(notesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil! Seluruh catatan telah disinkronkan.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua catatan sudah berstatus tersinkron.')),
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
