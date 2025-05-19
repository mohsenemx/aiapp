import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  ApiService._privateCtor();
  static final ApiService instance = ApiService._privateCtor();

  // Replace with your server’s URL
  final String _baseUrl = 'http://194.145.119.252:3001/api';

  // Helpers
  Future<http.Response> _get(String path) =>
      http.get(Uri.parse('$_baseUrl$path'));

  Future<http.Response> _post(String path, Map body) => http.post(
    Uri.parse('$_baseUrl$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  Future<http.Response> _put(String path, Map body) => http.put(
    Uri.parse('$_baseUrl$path'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  Future<http.Response> _delete(String path) =>
      http.delete(Uri.parse('$_baseUrl$path'));

  // 1) Chats

  Future<List<Chat>> getChats(String userId) async {
    final res = await _get('/chats/$userId');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Chat.fromJson(j)).toList();
    }
    throw Exception('Failed to load chats');
  }

  Future<Chat> createChat(String userId, String name) async {
    final res = await _post('/chats', {'userId': userId, 'name': name});
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Chat.fromJson(jsonDecode(res.body));
    }
    throw Exception('Failed to create chat');
  }

  Future<void> renameChat(String chatId, String newName) async {
    final res = await _put('/chats/$chatId', {'name': newName});
    if (res.statusCode != 200) {
      throw Exception('Failed to rename chat');
    }
  }

  Future<void> deleteChat(String chatId) async {
    final res = await _delete('/chats/$chatId');
    if (res.statusCode != 200) {
      throw Exception('Failed to delete chat');
    }
  }

  // 2) Messages

  Future<List<Message>> getMessages(String chatId) async {
    final res = await _get('/messages/$chatId');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Message.fromJson(j)).toList();
    }
    throw Exception('Failed to load messages');
  }

  /// Sends a user message and returns [userMsg, aiMsg]
  Future<List<Message>> sendMessage({
    required String userId,
    required String chatId,
    required String text,
  }) async {
    final res = await _post('/messages', {
      'userId': userId,
      'chatId': chatId,
      'text': text,
    });
    if (res.statusCode == 200 || res.statusCode == 201) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Message.fromJson(j)).toList();
    }
    throw Exception('Failed to send message');
  }
}
