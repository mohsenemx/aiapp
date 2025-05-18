// lib/widgets/message_input.dart
import 'package:flutter/material.dart';
import '../main.dart';

class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String hintText;

  const MessageInput({
    Key? key,
    required this.controller,
    required this.onSend,
    this.hintText = 'هرچی میخوایی بپرس...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkNotifier,
      builder: (_, isDark, __) {
        final bg = Theme.of(context).colorScheme.surface;
        final boxColor = isDark ? Color.fromRGBO(9, 27, 24, 1) : bg;
        final primary = Theme.of(context).colorScheme.primary;
        return Container(
          width: double.infinity, // fill full width
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 10,
                  minLines: 2,
                  decoration: InputDecoration(
                    hintText: hintText,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: InputBorder.none, // no border
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      backgroundColor: primary,
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: onSend,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                        onPressed: onSend,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
