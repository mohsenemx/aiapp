import 'package:flutter/material.dart';
import 'main.dart';
class HomePage extends StatefulWidget {
  final VoidCallback toggleTheme;
  HomePage({super.key, required this.toggleTheme,});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      appBar: AppBar(title: Text('چت بات من'),centerTitle: true, actions: [
          IconButton(
            icon: Icon(
               isDarkNotifier.value ? Icons.wb_sunny : Icons.brightness_2,
              
            ),
            onPressed: widget.toggleTheme,
          ),
        ],),
      /*floatingActionButton: Builder(
        
        builder: (context) => FloatingActionButton(

          onPressed: () => Scaffold.of(context).openDrawer(),
          child: const Icon(Icons.menu),
        ),
      ),*/
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
                      autofocus: true,
                      decoration: const InputDecoration(
                        
                        hintText: 'پیام خود را بنویسید...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(50))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
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
