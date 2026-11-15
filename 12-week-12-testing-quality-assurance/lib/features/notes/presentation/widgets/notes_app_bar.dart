import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/sync.dart' show forceOfflineProvider;
import '../providers/notes_providers.dart';

/// AppBar halaman catatan.
///
/// Widget ini hanya mengamati [noteStatsProvider], sehingga ketikan pada kolom
/// pencarian tidak lagi membangun ulang judul, badge, dan tombol sinkronisasi.
class NotesAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const NotesAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(noteStatsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Saya',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          Text(
            stats.dirty > 0
                ? '${stats.total} catatan • ${stats.dirty} perlu sinkron'
                : '${stats.total} catatan • Semua tersinkron',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        _SyncButton(dirtyCount: stats.dirty),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SyncButton extends ConsumerWidget {
  const _SyncButton({required this.dirtyCount});

  final int dirtyCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: const Key('sync-notes-button'),
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
      onPressed: () => _syncNotes(context, ref),
    );
  }
}

Future<void> _syncNotes(BuildContext context, WidgetRef ref) async {
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
    if (countResult.failure != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(countResult.failure!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final dirtyCount = countResult.count;
    if (dirtyCount > 0) {
      await Future.delayed(const Duration(milliseconds: 500));
      final syncResult = await repo.markAllSynced();
      if (!context.mounted) return;
      if (syncResult.failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncResult.failure!.message),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ref.invalidate(notesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil! Seluruh catatan telah disinkronkan.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua catatan sudah berstatus tersinkron.'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal sinkron: $e')));
    }
  }
}
