// lib/widgets/app_drawer.dart

import 'package:aiapp/ImageGen_page.dart';
import 'package:aiapp/widgets/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../chat_page.dart';
import '../login_page.dart';
import '../main.dart';

class AppDrawer extends StatefulWidget {
  final String userId;
  final VoidCallback toggleTheme;
  const AppDrawer({Key? key, required this.userId, required this.toggleTheme})
    : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  List<Chat> _chats = [];
  bool _loading = true;

  Future<void> _loadChats() async {
    try {
      setState(() => _loading = true);
      try {
        _chats = await ApiService.instance.getChats();
      } catch (e) {
        showSnackBar(context, 'مشکلی در بارگزاری چت ها رخ داد', error: true);
      } finally {
        setState(() => _loading = false);
      }
    } catch (e) {
      print('Making the engine shut up when closing drawer too early.');
    }
  }

  @override
  void initState() {
    super.initState();
    TapsellPlus.instance.hideStandardBanner();
    _loadChats();
  }

  void _createNewChat() async {
    final newChat = await ApiService.instance.createChat(
      'چت جدید ${_chats.length + 1}',
    );
    setState(() => _chats.add(newChat));
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

  void _renameChat(int idx) async {
    final chat = _chats[idx];
    final controller = TextEditingController(text: chat.name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تغییر نام چت'),
            content: TextField(controller: controller),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('لغو'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                child: const Text('ذخیره'),
              ),
            ],
          ),
    );
    if (newName != null && newName.isNotEmpty) {
      await ApiService.instance.renameChat(chat.id, newName);
      setState(
        () =>
            _chats[idx] = Chat(
              id: chat.id,
              userId: chat.userId,
              name: newName,
              createdAt: chat.createdAt,
            ),
      );
    }
  }

  void _deleteChat(int idx) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف چت'),
            content: const Text('آیا از حذف این چت مطمئنید؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('خیر'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('بله'),
              ),
            ],
          ),
    );
    if (ok == true) {
      final chat = _chats[idx];
      await ApiService.instance.deleteChat(chat.id);
      setState(() => _chats.removeAt(idx));
    }
  }

  void _goToLogin() {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const ListTile(
              title: Text(
                'چت‌ها',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator())),
            if (!_loading)
              Expanded(
                child: ListView.builder(
                  itemCount: _chats.length + 1,
                  itemBuilder: (ctx, idx) {
                    if (idx == _chats.length) {
                      return ListTile(
                        leading: const Icon(Icons.add_circle_outline),
                        title: const Text('چت جدید'),
                        onTap: _createNewChat,
                      );
                    }
                    final c = _chats[idx];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline),
                      title: Text(c.name),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (v) {
                          if (v == 'rename') _renameChat(idx);
                          if (v == 'delete') _deleteChat(idx);
                        },
                        itemBuilder:
                            (_) => const [
                              PopupMenuItem(
                                value: 'rename',
                                child: Text('تغییر نام'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => ChatPage(
                                  userId: widget.userId,
                                  chat: c,
                                  toggleTheme: widget.toggleTheme,
                                ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            GestureDetector(
              child: ListTile(
                leading: Icon(Icons.image),
                title: Text('تولید عکس'),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => ImageGenerationPage(
                          userId: ApiService.instance.currentUuid!,
                          toggleTheme: widget.toggleTheme,
                        ),
                  ),
                );
                /* 
                ImageGenerationPage(
              userId: ApiService.instance.currentUuid!,
              toggleTheme: widget.toggleTheme,
            ),
            */
              },
            ),
            const Divider(),

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ApiService.instance.isLoggedIn
                    ? SizedBox(
                      width: 200,
                      child: ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: Text(
                          ArabicNumbers().convert(
                            ApiService.instance.phoneNumber!,
                          ),
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder:
                                (ctx) => AlertDialog(
                                  title: const Text('خروج'),
                                  content: const Text(
                                    'آیا مطمئن به خروج هستید؟',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('خیر'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        ApiService.instance.logout();
                                        Navigator.pop(ctx); // close dialog
                                        Navigator.pop(context); // close drawer
                                        setState(() {}); // rebuild drawer
                                      },
                                      child: const Text('بله'),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    )
                    : SizedBox(
                      width: 200,
                      child: ListTile(
                        leading: const Icon(Icons.login),
                        title: const Text('ورود / ثبت‌نام'),
                        onTap: _goToLogin,
                      ),
                    ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isDarkNotifier,
                    builder:
                        (_, isDark, __) => IconButton(
                          icon: Icon(
                            isDark ? FontAwesomeIcons.moon : Icons.sunny,
                          ),
                          onPressed: widget.toggleTheme,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
