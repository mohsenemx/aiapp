// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/app_drawer.dart';
import 'widgets/message_input.dart';
import 'services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'chat_page.dart';
import 'main.dart';
import 'models/message.dart';

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
      // 1) Create a new chat on the backend
      final chat = await ApiService.instance.createChat('چت جدید');
      final userMsg = Message(
        id: '', // temporary
        chatId: chat.id,
        userId: widget.userId,
        text: text,
        isUser: true,
        createdAt: DateTime.now(),
      );

      // 2) Clear input and reset sending state
      _homeTC.clear();

      // 3) Navigate instantly, passing the initial user message
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ChatPage(
                userId: widget.userId,
                chat: chat,
                initialMessages: [userMsg],
                pendingUserText: text,
                toggleTheme: widget.toggleTheme,
              ),
        ),
      );
    } catch (e) {
      // TODO: show error toast/snackbar
    } finally {
      setState(() => _sending = false);
    }
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fetched = await ApiService.instance.getStars();
      // now update state synchronously
      if (!mounted) return;
      setState(() {
        stars = fetched;
      });
    });
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
        title: Padding(
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

        centerTitle: true,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              onPressed: _createNewChat,
              icon: Icon(FontAwesomeIcons.penToSquare),
            ),
          ),
          /*ValueListenableBuilder<bool>(
            valueListenable: isDarkNotifier,
            builder:
                (_, isDark, __) => IconButton(
                  icon: Icon(
                    isDark ? FontAwesomeIcons.moon : FontAwesomeIcons.sun,
                  ),
                  onPressed: widget.toggleTheme,
                ),
          ),*/
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          const Center(
            child: Text(
              'سلام! روز بخیر.',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
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
