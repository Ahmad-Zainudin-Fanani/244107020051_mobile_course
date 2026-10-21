import 'package:flutter/material.dart';
import '../data/local/note.dart';

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
    return ListTile(
      title: Text(note.title),
      subtitle: Text('Note created at ${note.updatedAt.toIso8601String()}'),
      trailing: note.dirty
          ? const Icon(Icons.cloud_upload_outlined, color: Colors.orange)
          : null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
