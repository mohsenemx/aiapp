import 'package:aiapp/models/message.dart';
import 'package:flutter/material.dart';
import 'typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  final bool sending;
  final bool isLast;
  final Message m;
  const ChatBubble({
    super.key,
    required this.sending,
    required this.isLast,
    required this.m,
  });

  @override
  Widget build(BuildContext context) {
    if (sending && isLast) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const TypingIndicator(),
        ),
      );
    }
    return Align(
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
    );
  }
}
