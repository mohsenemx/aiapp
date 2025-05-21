// lib/chat_page.dart
// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'main.dart';
import 'widgets/app_drawer.dart';
import 'widgets/message_input.dart';
import 'widgets/typing_indicator.dart';
import 'services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/message.dart';
import 'models/chat.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final Chat chat;
  final List<Message>? initialMessages;
  final String? pendingUserText;
  final VoidCallback toggleTheme;
  const ChatPage({
    Key? key,
    required this.userId,
    required this.chat,
    this.initialMessages,
    this.pendingUserText,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _tc = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _loading = true;
  bool _sending = false;

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final msgs = await ApiService.instance.getMessages(widget.chat.id);
    _fetchStars();
    setState(() {
      _messages = msgs;
      _loading = false;
    });
    _scrollToBottom();
  }

  void _createNewChat() async {
    final newChat = await ApiService.instance.createChat('چت جدید');
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ChatPage(
              userId: widget.userId,
              chat: newChat,
              toggleTheme: widget.toggleTheme,
            ),
      ),
    );
  }

  Future<void> _fetchStars() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fetched = await ApiService.instance.getStars();
      if (!mounted) return;
      setState(() {
        stars = fetched;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null) {
      _messages = widget.initialMessages!;
      _loading = false;
      _scrollToBottom();

      _fetchAiReply(widget.pendingUserText!);
      _fetchStars();
    } else {
      _loadMessages();
    }
  }

  void _scrollToBottom() {
    // delay to allow build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _fetchAiReply(String text) async {
    // show a loading indicator if you like
    try {
      final result = await ApiService.instance.sendMessage(
        chatId: widget.chat.id,
        text: text,
      );
      final aiMsg = result[1]; // only the AI bubble
      setState(() {
        _messages.add(aiMsg);
        _fetchStars();
      });

      _scrollToBottom();
    } catch (e) {
      // handle error
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(
        Message(
          id: '',
          chatId: widget.chat.id,
          userId: widget.userId,
          text: trimmed,
          isUser: true,
          createdAt: DateTime.now(),
        ),
      );
      _sending = true;
    });
    _tc.clear();
    _scrollToBottom();

    try {
      final results = await ApiService.instance.sendMessage(
        chatId: widget.chat.id,
        text: trimmed,
      );
      // results[0] is user echo, results[1] is AI
      setState(() {
        _messages.add(results[1]);
        _sending = false;
      });
      _fetchStars();
      _scrollToBottom();
    } catch (e) {
      // handle error: you might want to show a toast or add an error bubble
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(userId: widget.userId, toggleTheme: widget.toggleTheme),

      appBar: AppBar(
        leading: Builder(
          builder:
              (context) => Padding(
                padding: const EdgeInsets.all(12.0),
                child: IconButton(
                  icon: Icon(FontAwesomeIcons.bars),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        ),
        title: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(35),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Column(
              children: [
                SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 5),
                    Text(NumberFormat.decimalPattern('fa').format(stars)),
                    const SizedBox(width: 5),
                    const Icon(Icons.star),
                  ],
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              onPressed: _createNewChat,
              icon: Icon(FontAwesomeIcons.penToSquare),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (!_loading)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (_, i) {
                  // if sending and this is the extra slot, show typing
                  if (_sending && i == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const TypingIndicator(), // our three-dot anim
                      ),
                    );
                  }
                  final m = _messages[i];
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
                      child: Text(
                        m.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: MessageInput(
        hintText: 'متنی بنویسید....',
        controller: _tc,
        enabled: !_sending,
        onSend: () => _send(_tc.text),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tc.dispose();
    super.dispose();
  }
}
