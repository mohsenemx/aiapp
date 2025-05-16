import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void dummySendMessage() {
    print('ارسال پیام...');
  }

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: const [
              ListTile(
                title: Text('چت‌ها'),
              ),
              // Empty for now
            ],
          ),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          child: const Icon(Icons.menu),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Center(
              child: Text(
                'سلام! بعد از ظهر بخیر ☀️',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: dummySendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
