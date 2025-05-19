class Message {
  final String id;
  final String chatId;
  final String userId;
  final String text;
  final bool isUser;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.text,
    required this.isUser,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['_id'] as String,
    chatId: j['chatId'] as String,
    userId: j['userId'] as String,
    text: j['text'] as String,
    isUser: j['isUser'] as bool,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'chatId': chatId,
    'text': text,
  };
}
