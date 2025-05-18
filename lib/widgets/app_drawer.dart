// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/conversation.dart';
import '../chat_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  Box<Conversation> get _chatBox => Hive.box<Conversation>('chats');

  void _createNewChat(BuildContext context) async {
    final box = _chatBox;
    final title = 'چت جدید ${box.length + 1}';
    final int newKey = await box.add(Conversation(title: title));
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatPage(convoKey: newKey)));
  }

  Future<void> _renameChat(BuildContext context, int idx) async {
    final box = _chatBox;
    final convo = box.getAt(idx)!;
    final controller = TextEditingController(text: convo.title);

    final newName = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('تغییر نام چت'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'نام جدید'),
            ),
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
      convo.title = newName;
      box.putAt(idx, convo);
    }
  }

  void _deleteChat(BuildContext context, int idx) {
    final box = _chatBox;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('حذف چت'),
            content: const Text('آیا از حذف این چت مطمئنید؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('خیر'),
              ),
              TextButton(
                onPressed: () {
                  box.deleteAt(idx);
                  Navigator.pop(ctx); // close confirmation
                  Navigator.pop(context); // close drawer
                },
                child: const Text('بله'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final box = _chatBox;
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
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (_, Box<Conversation> box, __) {
                  if (box.isEmpty) {
                    return const Center(child: Text('هنوز چتی ساخته نشده'));
                  }
                  return ListView.builder(
                    itemCount: box.length + 1,
                    itemBuilder: (ctx, idx) {
                      if (idx == box.length) {
                        return ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('چت جدید'),
                          onTap: () => _createNewChat(context),
                        );
                      }
                      final convo = box.getAt(idx)!;
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble),
                        title: Text(convo.title),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _renameChat(context, idx);
                            } else if (value == 'delete') {
                              _deleteChat(context, idx);
                            }
                          },
                          itemBuilder:
                              (_) => [
                                const PopupMenuItem(
                                  value: 'rename',
                                  child: Text('تغییر نام'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('حذف'),
                                ),
                              ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => ChatPage(convoKey: idx),
                            ),
                          );
                        },
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
