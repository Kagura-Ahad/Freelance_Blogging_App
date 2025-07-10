class Message {
  int? id;
  String title;
  String content;
  String? imagePath;
  DateTime createdAt;
  DateTime updatedAt;
  bool isUploaded;

  Message({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isUploaded = false,
  }) :
        this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  // Convert Message to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isUploaded': isUploaded ? 1 : 0,
    };
  }

  // Create Message from Map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isUploaded: map['isUploaded'] == 1,
    );
  }

  // Create a copy of Message with updated fields
  Message copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isUploaded,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isUploaded: isUploaded ?? this.isUploaded,
    );
  }
}