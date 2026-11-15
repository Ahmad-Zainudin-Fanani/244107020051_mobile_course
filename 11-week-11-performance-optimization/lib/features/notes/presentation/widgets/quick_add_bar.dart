import 'package:flutter/material.dart';

/// Kolom input cepat di atas daftar catatan.
///
/// Dipisahkan dari `NotesPage` dan tidak mengamati provider apa pun, sehingga
/// perubahan kata kunci pencarian tidak membangun ulang kolom ini.
class QuickAddBar extends StatelessWidget {
  const QuickAddBar({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
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
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan cepat di sini...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            InkWell(
              onTap: onSubmit,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
