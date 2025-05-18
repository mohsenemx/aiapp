import 'package:hive/hive.dart';
part 'conversation.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String text;
  @HiveField(1)
  final DateTime sentAt;

  // new field: true=user, false=AI
  @HiveField(2)
  final bool isUser;

  Message(this.text, this.isUser) : sentAt = DateTime.now();
}

@HiveType(typeId: 1)
class Conversation {
  @HiveField(0)
  String title;

  @HiveField(1)
  List<Message> messages;

  Conversation({required this.title}) : messages = [];
}
