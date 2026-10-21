class Post {
  Post({required this.id, required this.title, required this.body});
  
  final int id;
  final String title;
  final String body;

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'] as int,
      title: map['title'] as String,
      body: map['body'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
      };
}
