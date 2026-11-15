import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/validation.dart';
import '../providers/notes_providers.dart';
import '../widgets/note_search_field.dart';
import '../widgets/notes_app_bar.dart';
import '../widgets/notes_list.dart';
import '../widgets/quick_add_bar.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  /// Jeda sebelum kata kunci dipakai menyaring. Tanpa jeda ini, setiap
  /// karakter memicu satu penyaringan penuh atas seluruh daftar catatan.
  static const _searchDebounce = Duration(milliseconds: 250);

  final TextEditingController _quickController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _quickController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    if (value.isEmpty) {
      ref.read(searchQueryProvider.notifier).clear();
      return;
    }
    _searchTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).update(value);
    });
  }

  void _clearSearch() {
    _searchTimer?.cancel();
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Halaman ini sengaja tidak mengamati provider data apa pun. Judul dan
    // statistik ditangani NotesAppBar, daftar ditangani NotesList, sehingga
    // perubahan kata kunci hanya membangun ulang subtree yang benar-benar
    // berubah.
    return Scaffold(
      appBar: const NotesAppBar(),
      body: Column(
        children: [
          QuickAddBar(controller: _quickController, onSubmit: _handleQuickAdd),
          NoteSearchField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          Expanded(child: NotesList(onClearSearch: _clearSearch)),
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
    final text = _quickController.text;
    final titleError = validateNoteTitle(text);
    if (titleError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(titleError), backgroundColor: Colors.red),
      );
      return;
    }

    _quickController.clear();
    final result = await ref.read(addNoteProvider).call(title: text.trim());
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
                    final titleError = validateNoteTitle(title);

                    if (titleError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(titleError),
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
}
