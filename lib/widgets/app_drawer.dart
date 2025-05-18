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
    // add returns the integer key/index of the new item
    final int newKey = await box.add(Conversation(title: title));

    // close the drawer
    Navigator.of(context).pop();

    // navigate to the new chat page
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatPage(convoKey: newKey)));
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
                        // “+ new chat” tile
                        return ListTile(
                          leading: const Icon(Icons.add_circle_outline),
                          title: const Text('چت جدید'),
                          onTap: () => _createNewChat(context),
                        );
                      }
                      final convo = box.getAt(idx)!;
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text(convo.title),
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
