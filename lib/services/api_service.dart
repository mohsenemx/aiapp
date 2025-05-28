// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/ImageGen.dart';

class ApiService {
  ApiService._privateCtor();
  static final ApiService instance = ApiService._privateCtor();

  final String _baseUrl = 'https://m.bahushbot.ir:3001/api';

  Box? _settingsBox;

  /// Initialize Hive and register guest if no UUID stored yet
  Future<void> init() async {
    _settingsBox = await Hive.openBox('settings');

    if (currentUuid != null) return;
    final guestUuid = const Uuid().v4();
    final serverUuid = await _registerGuest(guestUuid);

    await _settingsBox?.put('userId', serverUuid);
  }

  /// Stored UUID (called userId in Hive for backward compatibility)
  String? get currentUuid => _settingsBox?.get('userId') as String?;

  String? get phoneNumber => _settingsBox?.get('phone') as String?;
  bool get isLoggedIn => currentUuid != null && phoneNumber != null;

  Future<void> _saveLogin(String phone, String uuid) async {
    await _settingsBox?.put('phone', phone);
    await _settingsBox?.put('userId', uuid);
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

  /// Verify [otp] for [phone], store uuid+phone on success.
  Future<String> verifyOtp(String phone, String otp) async {
    final res = await _post('/auth/verify-otp', {'phone': phone, 'otp': otp});
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final uuid = data['userId'] as String;
      await _saveLogin(phone, uuid);
      return uuid;
    }
    throw Exception('OTP verification failed');
  }

  Future<void> logout() async {
    await _settingsBox?.delete('phone');
    await _settingsBox?.delete('userId');
  }

  // ── CHATS & MESSAGES ─────────────────────────────────

  Future<List<Chat>> getChats() async {
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');
    final res = await _get('/chats/$uuid');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Chat.fromJson(j)).toList();
    }
    throw Exception('Failed to load chats');
  }

  Future<Chat> createChat(String name) async {
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');

    final res = await _post('/chats', {'userId': uuid, 'name': name});
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
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');
    final res = await _post('/messages', {
      'userId': uuid,
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
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');
    final res = await _get('/users/$uuid/stars');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['stars'] as int;
    }
    throw Exception('Failed to fetch stars');
  }

  Future<String> _registerGuest(String uuid) async {
    final res = await _post('/auth/guest', {'uuid': uuid});
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body);
      return data['userId'] as String;
    }
    throw Exception('Failed to register guest');
  }

  /// Sends text, chatId, image & userId to `/vision`. Returns `{ userMsg, aiMsg }`.
  Future<Map<String, dynamic>> sendVision({
    required XFile image,
    required String text,
    required String chatId,
  }) async {
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');

    // check image size <=10MB
    final size = await image.length();
    const maxBytes = 10 * 1024 * 1024;
    if (size > maxBytes) {
      throw Exception(
        'Image too large (${(size / 1024 / 1024).toStringAsFixed(1)}MB), max 10MB',
      );
    }

    final uri = Uri.parse('$_baseUrl/vision');
    final request =
        http.MultipartRequest('POST', uri)
          ..fields['text'] = text
          ..fields['chatId'] = chatId
          ..fields['userId'] = uuid
          ..files.add(await http.MultipartFile.fromPath('image', image.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Vision API failed: ${res.statusCode} ${res.body}');
    }
  }

  /// Fetches all image generations for the current user.
  Future<List<ImageGeneration>> getUserImages() async {
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');

    final res = await _get('/images/user/$uuid');
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data
          .map((j) => ImageGeneration.fromJson(j as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load images: ${res.statusCode} ${res.body}');
    }
  }

  /// Generates an image by calling POST /images/generate
  /// Returns the ImageGeneration record (parsed from the AI message)
  Future<ImageGeneration> sendImageGeneration({
    required String prompt,
    String size = '1024x1024',
  }) async {
    final uuid = currentUuid;
    if (uuid == null) throw Exception('No user UUID stored');

    final res = await _post('/images/generate', {
      'prompt': prompt,
      'userId': uuid,
      'size': size,
    });

    if (res.statusCode != 200) {
      throw Exception('Image generation failed: ${res.statusCode} ${res.body}');
    }
    print(res.body);
    final Map<String, dynamic> data = jsonDecode(res.body);
    final imageUrl = data['generatedImage']['url'] as String;
    final createdAt = DateTime.parse(
      data['generatedImage']['createdAt'] as String,
    );
    return ImageGeneration(
      prompt: prompt,
      url: imageUrl,
      userId: uuid,
      createdAt: createdAt,
    );
  }
}
