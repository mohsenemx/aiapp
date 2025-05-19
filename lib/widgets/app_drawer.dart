// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../chat_page.dart';

class AppDrawer extends StatefulWidget {
  final String userId;
  const AppDrawer({Key? key, required this.userId}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  List<Chat> _chats = [];
  bool _loading = true;

  Future<void> _loadChats() async {
    setState(() => _loading = true);
    try {
      _chats = await ApiService.instance.getChats(widget.userId);
    } catch (e) {
      // optionally show error
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _createNewChat() async {
    final newChat = await ApiService.instance.createChat(
      widget.userId,
      'چت جدید ${_chats.length + 1}',
    );
    setState(() => _chats.add(newChat));
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(userId: widget.userId, chat: newChat),
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
                                (_) => ChatPage(userId: widget.userId, chat: c),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
