// lib/chat_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/conversation.dart';
import 'main.dart';
import 'widgets/app_drawer.dart';

class ChatPage extends StatefulWidget {
  final int convoKey;
  const ChatPage({super.key, required this.convoKey});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Box<Conversation> chatBox;
  late Conversation convo;
  final TextEditingController _tc = TextEditingController();

  @override
  void initState() {
    super.initState();
    chatBox = Hive.box<Conversation>('chats');
    convo = chatBox.getAt(widget.convoKey)!;
  }

  void _send() {
    final text = _tc.text.trim();
    if (text.isEmpty) return;
    setState(() {
      convo.messages.add(Message(text, true));
      convo.messages.add(Message(text, false));
      chatBox.putAt(widget.convoKey, convo);
      _tc.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // same drawer as HomePage
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(convo.title),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: isDarkNotifier,
            builder: (_, isDark, __) {
              return IconButton(
                icon: Icon(isDark ? Icons.brightness_2 : Icons.wb_sunny),
                onPressed: () => isDarkNotifier.value = !isDarkNotifier.value,
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                itemCount: convo.messages.length,
                itemBuilder: (_, i) {
                  final m = convo.messages[i];
                  return Align(
                    alignment:
                        m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            m.isUser
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isDarkNotifier,
                        builder: (_, isDark, __) {
                          return Text(
                            m.text,
                            style: TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom input row (same as HomePage)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tc,
                      decoration: const InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
