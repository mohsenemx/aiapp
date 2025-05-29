// lib/widgets/chat_bubble.dart
import 'package:aiapp/models/message.dart';
import 'package:aiapp/widgets/ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for Clipboard

class ChatBubble extends StatelessWidget {
  final Message m;
  const ChatBubble({super.key, required this.m});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () async {
        final choice = await showDialog<String>(
          context: context,
          builder:
              (_) => SimpleDialog(
                title: Text('گزینه های پیام'),
                children: [
                  SimpleDialogOption(
                    child: Text('کپی'),
                    onPressed: () => Navigator.pop(context, 'copy'),
                  ),
                  SimpleDialogOption(
                    child: Text('لغو'),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
        );

        if (choice == 'copy') {
          await Clipboard.setData(ClipboardData(text: m.text));
          showSnackBar(context, 'متن در کلیپ بورد کپی شد');
        }
      },
      child: Align(
        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                m.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (m.image != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.image!, width: 200, fit: BoxFit.cover),
                ),
                const SizedBox(height: 8),
              ],
              Text(m.text, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
