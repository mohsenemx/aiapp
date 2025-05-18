// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/conversation.dart';
import 'chat_page.dart';
import 'main.dart';
import 'widgets/app_drawer.dart';
import 'widgets/message_input.dart';

class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomePage({super.key, required this.toggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Box<Conversation> chatBox = Hive.box<Conversation>('chats');
  final TextEditingController _homeTC = TextEditingController();

  void _sendFromHome() async {
    final text = _homeTC.text.trim();
    if (text.isEmpty) return;

    // 1) Create & populate new convo
    final title = 'چت جدید ${chatBox.length + 1}';
    final convo = Conversation(title: title)..messages.add(Message(text, true));

    // 2) Persist and get its key/index
    final int newKey = await chatBox.add(convo);

    // 3) Clear input
    _homeTC.clear();

    // 4) Navigate into the new chat
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatPage(convoKey: newKey)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('چت‌بات من'),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isDarkNotifier,
            builder: (_, isDark, __) {
              return IconButton(
                icon: Icon(isDark ? Icons.brightness_2 : Icons.wb_sunny),
                onPressed: widget.toggleTheme,
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: MessageInput(
        controller: _homeTC, // or _homeTC in HomePage
        onSend: _sendFromHome, // or _sendFromHome
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Center(
              child: Text(
                'سلام! ظهر بخیر.',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
