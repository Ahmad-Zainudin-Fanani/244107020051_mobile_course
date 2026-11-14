/// Peran pengirim pesan di layar asisten.
enum ChatRole { user, assistant }

/// Satu pesan di percakapan asisten.
///
/// Objek ini sengaja tidak menyimpan timestamp atau id karena percakapan hanya
/// hidup selama aplikasi berjalan dan tidak disimpan ke database.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.isStreaming = false,
  });

  final ChatRole role;
  final String text;
  final bool isStreaming;

  bool get isUser => role == ChatRole.user;

  ChatMessage copyWith({String? text, bool? isStreaming}) {
    return ChatMessage(
      role: role,
      text: text ?? this.text,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}
