abstract class ItemModel {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemModel({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson();

  // Factory method to create specific type based on type field
  static ItemModel fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'note':
        return NoteModel.fromJson(json);
      case 'password':
        return PasswordModel.fromJson(json);
      case 'event':
        return EventModel.fromJson(json);
      default:
        throw Exception('Unknown item type: $type');
    }
  }
}

class NoteModel extends ItemModel {
  final String description;

  NoteModel({
    required String id,
    required String title,
    required this.description,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          content: content,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'note',
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PasswordModel extends ItemModel {
  final String accountName;
  final String username;
  final bool isSecure;

  PasswordModel({
    required String id,
    required this.accountName,
    required this.username,
    required String password,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isSecure = true,
  }) : super(
          id: id,
          title: accountName,
          content: password,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory PasswordModel.fromJson(Map<String, dynamic> json) {
    return PasswordModel(
      id: json['id'] as String,
      accountName: json['title'] as String,
      username: json['username'] as String,
      password: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSecure: json['is_secure'] as bool? ?? true,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'password',
      'id': id,
      'title': accountName,
      'username': username,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_secure': isSecure,
    };
  }
}

class EventModel extends ItemModel {
  final DateTime eventDateTime;
  final String description;

  EventModel({
    required String id,
    required String title,
    required this.description,
    required this.eventDateTime,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          title: title,
          content: description,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      eventDateTime: DateTime.parse(json['datetime'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'event',
      'id': id,
      'title': title,
      'description': description,
      'datetime': eventDateTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
