import 'package:flutter_test/flutter_test.dart';
import 'package:week4_api/data/models/comment.dart';

void main() {
  group('Comment Model Unit Tests', () {
    test('fromJson harus mengembalikan objek Comment valid dari JSON lengkap', () {
      final json = {
        'postId': 1,
        'id': 10,
        'name': 'id labore ex et quam laborum',
        'email': 'Eliseo@gardner.biz',
        'body': 'laudantium enim quasi est quidem magnam voluptate',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 1);
      expect(comment.id, 10);
      expect(comment.name, 'id labore ex et quam laborum');
      expect(comment.email, 'Eliseo@gardner.biz');
      expect(comment.body, 'laudantium enim quasi est quidem magnam voluptate');
    });

    test('fromJson aman null ketika ada field yang hilang (missing fields)', () {
      // Kasus field 'postId', 'name', dan 'body' hilang
      final json = {
        'id': 5,
        'email': 'test@example.com',
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 0); // fallback ke 0
      expect(comment.id, 5);
      expect(comment.name, ''); // fallback ke string kosong
      expect(comment.email, 'test@example.com');
      expect(comment.body, ''); // fallback ke string kosong
    });

    test('Edge Case: fromJson aman ketika nilai berupa null eksplisit dan tipe num bertindak sebagai double', () {
      // Kasus nilai null eksplisit & tipe num yang berasal dari double
      final json = {
        'postId': 2.0, // double yang bertindak sebagai num
        'id': null,
        'name': null,
        'email': null,
        'body': null,
      };

      final comment = Comment.fromJson(json);

      expect(comment.postId, 2);
      expect(comment.id, 0);
      expect(comment.name, '');
      expect(comment.email, '');
      expect(comment.body, '');
    });
  });
}
