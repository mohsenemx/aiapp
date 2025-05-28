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
import 'package:image_picker/image_picker.dart';
import 'models/message.dart';
import 'models/chat.dart';
import 'widgets/chat_bubble.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final Chat chat;
  final List<Message>? initialMessages;
  final XFile? image;
  final String? pendingUserText;
  final VoidCallback toggleTheme;
  const ChatPage({
    Key? key,
    required this.userId,
    required this.chat,
    this.initialMessages,
    this.image,
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

      setState(() {
        _sending = true;
      });
      _scrollToBottom();

      _fetchAiReply(text: widget.pendingUserText!, file: widget.image);
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

  Future<void> _fetchAiReply({required String text, XFile? file}) async {
    try {
      if (file != null) {
        final result = await ApiService.instance.sendVision(
          image: file,
          text: text,
          chatId: widget.chat.id,
        );

        final userMsg = Message.fromJson(result['userMsg']);
        final aiMsg = Message.fromJson(result['aiMsg']);

        setState(() {
          _messages.add(userMsg);
          _messages.add(aiMsg);
          _sending = false;
        });
      } else {
        final result = await ApiService.instance.sendMessage(
          chatId: widget.chat.id,
          text: text,
        );
        final aiMsg = result[1];
        setState(() {
          _messages.add(aiMsg);
          _sending = false;
        });
      }

      _fetchStars();
      _scrollToBottom();
    } catch (e) {
      setState(() => _sending = false);
      // handle error if needed
    }
  }

  Future<void> _send({required String text, XFile? file}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && file == null) return;

    setState(() {
      _messages.add(
        Message(
          id: '',
          chatId: widget.chat.id,
          userId: widget.userId,
          text: trimmed,
          image: file?.path,
          isUser: true,
          createdAt: DateTime.now(),
        ),
      );
      _sending = true;
    });

    _tc.clear();
    _scrollToBottom();

    try {
      if (file != null) {
        final result = await ApiService.instance.sendVision(
          image: file,
          text: trimmed,
          chatId: widget.chat.id,
        );

        // result contains userMsg & aiMsg as JSON maps
        final userMsgJson = result['userMsg'] as Map<String, dynamic>;
        final aiMsgJson = result['aiMsg'] as Map<String, dynamic>;

        // 3️⃣ Parse and add the AI’s response
        setState(() {
          // replace the optimistic user bubble with the saved one (optional):
          _messages.removeLast();
          _messages.add(Message.fromJson(userMsgJson));

          // add the AI reply
          _messages.add(Message.fromJson(aiMsgJson));
          _sending = false;
        });
      } else {
        // 2️⃣ No file → plain text messaging
        final msgs = await ApiService.instance.sendMessage(
          chatId: widget.chat.id,
          text: trimmed,
        );
        setState(() {
          // msgs[0] is the echoed user message from server
          // msgs[1] is the AI reply
          _messages
            ..removeLast() // drop the optimistic one
            ..add(msgs[0])
            ..add(msgs[1]);
          _sending = false;
        });
        _fetchStars();
      }
      _scrollToBottom();
    } catch (e) {
      // You might want to show a SnackBar or error widget here
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
                  return ChatBubble(
                    sending: _sending,
                    isLast: i == _messages.length,
                    m: _messages[i],
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
        onSend: (text, file) => _send(text: text, file: file),
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
