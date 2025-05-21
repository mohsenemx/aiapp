// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';

class ApiService {
  ApiService._privateCtor();
  static final ApiService instance = ApiService._privateCtor();

  final String _baseUrl = 'https://m.bahushbot.ir:3001/api';

  Box? _settingsBox;
  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');

    if (currentUserId != null) return;
    final guestUuid = const Uuid().v4();
    final serverUserId = await _registerGuest(guestUuid);

    await _settingsBox?.put('userId', serverUserId);
  }

  String? get currentUserId => _settingsBox?.get('userId') as String?;
  String? get phoneNumber => _settingsBox?.get('phone') as String?;
  bool get isLoggedIn => currentUserId != null && phoneNumber != null;

  Future<void> _saveLogin(String phone, String userId) async {
    await _settingsBox?.put('phone', phone);
    await _settingsBox?.put('userId', userId);
  }

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

  // ── AUTH ─────────────────────────────────────────────

  /// Ask server to send OTP to [phone]. Returns seconds until expiry.
  Future<int> sendOtp(String phone) async {
    final res = await _post('/auth/send-otp', {'phone': phone});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['expiresIn'] as int;
    }
    throw Exception('Failed to send OTP');
  }

  /// Verify [otp] for [phone], store userId+phone in Hive on success.
  Future<String> verifyOtp(String phone, String otp) async {
    final res = await _post('/auth/verify-otp', {'phone': phone, 'otp': otp});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final userId = data['userId'] as String;
      await _saveLogin(phone, userId);
      return userId;
    }
    throw Exception('OTP verification failed');
  }

  /// Log out the user locally
  Future<void> logout() async {
    await _settingsBox?.delete('phone');
    await _settingsBox?.delete('userId');
  }

  // ── CHATS & MESSAGES ─────────────────────────────────

  Future<List<Chat>> getChats() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('No userId stored');
    final res = await _get('/chats/$uid');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Chat.fromJson(j)).toList();
    }
    throw Exception('Failed to load chats');
  }

  Future<Chat> createChat(String name) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('No userId stored');

    final res = await _post('/chats', {'userId': uid, 'name': name});
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

  Future<List<Message>> getMessages(String chatId) async {
    final res = await _get('/messages/$chatId');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Message.fromJson(j)).toList();
    }
    throw Exception('Failed to load messages');
  }

  Future<List<Message>> sendMessage({
    required String chatId,
    required String text,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('No userId stored');
    final res = await _post('/messages', {
      'userId': uid,
      'chatId': chatId,
      'text': text,
    });
    if (res.statusCode == 200 || res.statusCode == 201) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Message.fromJson(j)).toList();
    }
    throw Exception('Failed to send message');
  }

  Future<int> resendOtp(String phone) async {
    final res = await _post('/auth/resend-otp', {'phone': phone});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['expiresIn'] as int;
    }
    throw Exception('Failed to resend OTP');
  }

  Future<int> getStars() async {
    final uid = currentUserId;
    if (uid == null) throw Exception('No userId stored');
    final res = await _get('/users/$uid/stars');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['stars'] as int;
    }
    print(res.body);
    throw Exception('Failed to fetch stars');
  }

  Future<String> _registerGuest(String uuid) async {
    final res = await _post('/auth/guest', {'uuid': uuid});
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return data['userId'];
    }
    print(res.body);
    throw Exception('Failed to register guest');
  }
}
