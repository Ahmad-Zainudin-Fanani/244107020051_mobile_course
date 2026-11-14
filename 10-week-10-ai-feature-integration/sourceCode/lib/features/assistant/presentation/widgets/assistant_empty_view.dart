import 'package:flutter/material.dart';

/// Tampilan awal layar asisten sebelum ada pesan.
///
/// Dipisah supaya bisa diuji sendiri dan supaya contoh pertanyaan tidak
/// tersebar di dalam `build` halaman.
class AssistantEmptyView extends StatelessWidget {
  const AssistantEmptyView({
    super.key,
    required this.onSuggestionTap,
    this.suggestions = defaultSuggestions,
  });

  static const defaultSuggestions = [
    'Apa yang bisa kamu lakukan?',
    'Bantu saya membuat judul catatan baru',
    'Ringkas daftar judul catatan saya',
  ];

  final ValueChanged<String> onSuggestionTap;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 30,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tanya apa saja tentang catatan Anda',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Asisten ini menjawab lewat Gemini. '
              'Hanya pertanyaan Anda yang dikirim; isi catatan tidak ikut '
              'kecuali Anda menyalakan konteks judul di bawah.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestionTap(suggestion),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
