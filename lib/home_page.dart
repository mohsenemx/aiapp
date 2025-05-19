// lib/home_page.dart
import 'package:flutter/material.dart';
import 'widgets/app_drawer.dart';
import 'widgets/message_input.dart';
import 'services/api_service.dart';
import 'chat_page.dart';
import 'main.dart'; // for isDarkNotifier

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final String userId;

  const HomePage({Key? key, required this.toggleTheme, required this.userId})
    : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _homeTC = TextEditingController();
  bool _sending = false;

  Future<void> _sendFromHome() async {
    final text = _homeTC.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    try {
      // 1. Create a new chat on the server
      final chat = await ApiService.instance.createChat(
        widget.userId,
        'چت جدید', // or whatever default title you prefer
      );

      // 2. Optionally send the very first message now (user + AI reply)
      await ApiService.instance.sendMessage(
        userId: widget.userId,
        chatId: chat.id,
        text: text,
      );

      // 3. Clear the input
      _homeTC.clear();

      // 4. Navigate into the new chat page
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(userId: widget.userId, chat: chat),
        ),
      );
    } catch (e) {
      // handle error if needed
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(userId: widget.userId),
      appBar: AppBar(
        title: const Text('چت‌بات من'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isDarkNotifier,
            builder:
                (_, isDark, __) => IconButton(
                  icon: Icon(isDark ? Icons.brightness_2 : Icons.wb_sunny),
                  onPressed: widget.toggleTheme,
                ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Center(
              child: Text(
                'سلام! پیام خود را تایپ کنید تا چت جدید ساخته شود',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      bottomNavigationBar: AbsorbPointer(
        absorbing: _sending,
        child: MessageInput(
          controller: _homeTC,
          onSend: _sendFromHome,
          hintText: _sending ? 'در حال ارسال…' : 'هرچی میخوایی بپرس...',
        ),
      ),
    );
  }
}
