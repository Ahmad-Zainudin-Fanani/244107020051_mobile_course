import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/format.dart';

void main() {
  test('formatDisplayDate mengembalikan string terformat dengan tepat', () {
    final date = DateTime(2026, 10, 21, 14, 30);
    final formatted = formatDisplayDate(date);
    expect(formatted, '2026-10-21 14:30');
  });

  test('formatIso menghasilkan format ISO 8601 yang valid', () {
    final date = DateTime.utc(2026, 10, 21, 12, 0, 0);
    expect(formatIso(date), '2026-10-21T12:00:00.000Z');
  });
}
