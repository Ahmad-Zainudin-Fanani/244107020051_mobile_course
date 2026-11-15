import 'package:flutter/material.dart';
import '../../../../core/format.dart';
import '../../domain/entities/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Aksen warna status yang unik dan profesional
    final Color accentColor = note.dirty
        ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706)) // Amber
        : (isDark ? const Color(0xFF10B981) : const Color(0xFF059669)); // Emerald

    final Color badgeBg = note.dirty
        ? (isDark ? const Color(0xFF451A03) : const Color(0xFFFEF3C7))
        : (isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5));

    final Color badgeText = note.dirty
        ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E))
        : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Garis Aksen Vertikal Unik di sisi kiri kartu
              Container(
                width: 5,
                color: accentColor,
              ),

              // Isi Konten Catatan
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris Judul & Badge Status
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    note.dirty
                                        ? Icons.cloud_upload_outlined
                                        : Icons.cloud_done_outlined,
                                    size: 13,
                                    color: badgeText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    note.dirty
                                        ? 'Belum Sinkron'
                                        : 'Tersinkron',
                                    style: TextStyle(
                                      color: badgeText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Cuplikan Isi Catatan
                        if (note.body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            note.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                              height: 1.35,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Footer Informasi Waktu
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 13,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              formatDisplayDate(note.updatedAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
