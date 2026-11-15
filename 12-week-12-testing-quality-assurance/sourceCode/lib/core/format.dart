String formatIso(DateTime dateTime) {
  return dateTime.toIso8601String();
}

String formatDisplayDate(DateTime dateTime) {
  final d = dateTime.toLocal();
  final year = d.year.toString().padLeft(4, '0');
  final month = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
