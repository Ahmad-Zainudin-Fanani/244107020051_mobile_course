import 'package:flutter/material.dart';

/// Kolom pencarian judul catatan.
///
/// `onChanged` sengaja hanya meneruskan teks; penundaan (debounce) dan
/// pembaruan `searchQueryProvider` diatur oleh pemilik halaman. Tombol hapus
/// dibangun lewat [ValueListenableBuilder] agar hanya ikon kecil itu yang
/// dibangun ulang setiap kali teks berubah.
class NoteSearchField extends StatelessWidget {
  const NoteSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              size: 20,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari judul catatan...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, child) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
