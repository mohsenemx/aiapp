class Chat {
  final String id; // Mongo ObjectId as string
  final String userId;
  String name;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
  });

  factory Chat.fromJson(Map<String, dynamic> j) => Chat(
    id: j['_id'] as String,
    userId: j['userId'] as String,
    name: j['name'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {'userId': userId, 'name': name};
}
