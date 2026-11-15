import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/note.dart';
import '../providers/notes_providers.dart';
import 'error_view.dart';
import 'note_tile.dart';
import 'search_empty_view.dart';

/// Daftar catatan dengan lazy loading dan pagination (infinite scroll).
///
/// Hanya widget ini yang mengamati [filteredNotesProvider], sehingga mengetik
/// pada kolom pencarian tidak membangun ulang AppBar, kolom input cepat, atau
/// kolom pencarian itu sendiri.
class NotesList extends ConsumerStatefulWidget {
  const NotesList({super.key, required this.onClearSearch});

  final VoidCallback onClearSearch;

  @override
  ConsumerState<NotesList> createState() => _NotesListState();
}

class _NotesListState extends ConsumerState<NotesList> {
  /// Jumlah catatan yang dirender per "halaman".
  static const _pageSize = 60;

  final ScrollController _scrollController = ScrollController();
  int _limit = _pageSize;
  String? _lastQuery;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Muat halaman berikutnya sebelum pengguna benar-benar menyentuh ujung.
    if (position.extentAfter > 400) return;

    final total = ref.read(filteredNotesProvider).value?.length ?? 0;
    if (_limit >= total) return;
    setState(() => _limit = math.min(_limit + _pageSize, total));
  }

  Future<void> _confirmDelete(Note note) async {
    final id = note.id;
    if (id == null) return;

    await showDialog<void>(
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
              final result = await ref
                  .read(noteRepositoryProvider)
                  .deleteNote(id);
              if (!mounted) return;
              if (result.failure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.failure!.message),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              ref.invalidate(notesProvider);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNotesAsyncValue = ref.watch(filteredNotesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final hasAnyNote = ref.watch(
      noteStatsProvider.select((stats) => stats.total > 0),
    );

    // Kata kunci berubah: mulai lagi dari halaman pertama.
    if (_lastQuery != searchQuery) {
      _lastQuery = searchQuery;
      _limit = _pageSize;
    }

    return filteredNotesAsyncValue.when(
      data: (matchingNotes) {
        if (!hasAnyNote) {
          return const _EmptyNotesView();
        }
        if (matchingNotes.isEmpty) {
          return SearchEmptyView(
            query: searchQuery,
            onClear: widget.onClearSearch,
          );
        }

        final hasMore = matchingNotes.length > _limit;
        final visibleNotes = hasMore
            ? matchingNotes.sublist(0, _limit)
            : matchingNotes;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(notesProvider),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 4, bottom: 88),
            // Item tidak menyimpan state, jadi tidak perlu dibungkus
            // AutomaticKeepAlive per item.
            addAutomaticKeepAlives: false,
            itemCount: visibleNotes.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= visibleNotes.length) {
                return const _LoadMoreHint();
              }
              final note = visibleNotes[index];
              return NoteTile(
                key: ValueKey(note.id),
                note: note,
                onTap: () {
                  if (note.id != null) {
                    context.push('/note/${note.id}');
                  }
                },
                onLongPress: () => _confirmDelete(note),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => ErrorView(
        message: '$err',
        onRetry: () => ref.invalidate(notesProvider),
      ),
    );
  }
}

/// Penanda bahwa masih ada halaman berikutnya. Sengaja tanpa animasi agar
/// `pumpAndSettle` pada test tidak menunggu animasi tanpa akhir.
class _LoadMoreHint extends StatelessWidget {
  const _LoadMoreHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text('Memuat catatan...', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _EmptyNotesView extends StatelessWidget {
  const _EmptyNotesView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
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
}
