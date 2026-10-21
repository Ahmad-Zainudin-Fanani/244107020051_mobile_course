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

    final Color cardBg;
    final Color borderColor;
    final Color iconBg;
    final Color iconColor;
    final Color badgeBg;
    final Color badgeTextColor;
    final String badgeText;
    final IconData iconData;

    if (note.dirty) {
      iconData = Icons.cloud_upload_outlined;
      badgeText = 'Belum tersinkron';
      if (isDark) {
        cardBg = const Color(0xFF17221E);
        borderColor = const Color(0xFF2D3C37);
        iconBg = const Color(0xFF8E1B1B);
        iconColor = Colors.white;
        badgeBg = const Color(0xFF7E1414);
        badgeTextColor = const Color(0xFFFFD5D5);
      } else {
        cardBg = const Color(0xFFFFF8F8);
        borderColor = const Color(0xFFFFD8D8);
        iconBg = const Color(0xFFFFDADA);
        iconColor = const Color(0xFFC62828);
        badgeBg = const Color(0xFFFFE5E5);
        badgeTextColor = const Color(0xFFB71C1C);
      }
    } else {
      iconData = Icons.cloud_done_outlined;
      badgeText = 'Tersinkron';
      if (isDark) {
        cardBg = const Color(0xFF17221E);
        borderColor = const Color(0xFF2D3C37);
        iconBg = const Color(0xFF0F5A4D);
        iconColor = const Color(0xFF80CBC4);
        badgeBg = const Color(0xFF1E3932);
        badgeTextColor = const Color(0xFF80CBC4);
      } else {
        cardBg = const Color(0xFFF7FAF8);
        borderColor = const Color(0xFFD4E7DC);
        iconBg = const Color(0xFFB2DFDB);
        iconColor = const Color(0xFF00695C);
        badgeBg = const Color(0xFFE0F2F1);
        badgeTextColor = const Color(0xFF004D40);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Icon Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),

                  // Title & Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (note.body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            note.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFFB0BEC5)
                                  : Colors.black54,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Timestamp Row
              Padding(
                padding: const EdgeInsets.only(left: 58.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF80908B)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formatDisplayDate(note.updatedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF80908B)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
