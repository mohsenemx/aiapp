// lib/home_page.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:tapsell_plus/tapsell_plus.dart';
import 'widgets/app_drawer.dart';
import 'widgets/message_input.dart';
import 'services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  String? bannerResponseId;
  Future<void> _sendFromHome({required String text, XFile? file}) async {
    final text = _homeTC.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _sending = true;
    });
    try {
      final chat = await ApiService.instance.createChat('چت جدید');
      final userMsg = Message(
        id: '',
        chatId: chat.id,
        userId: widget.userId,
        text: text,
        isUser: true,
        createdAt: DateTime.now(),
      );

      _homeTC.clear();

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => ChatPage(
                userId: widget.userId,
                chat: chat,
                initialMessages: [userMsg],
                pendingUserText: text,
                image: file,
                toggleTheme: widget.toggleTheme,
              ),
        ),
      );
    } catch (e) {
      print(e);
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

  void _showBannerAd(String responseId) {
    TapsellPlus.instance.showStandardBannerAd(
      responseId,
      TapsellPlusHorizontalGravity.TOP,
      TapsellPlusVerticalGravity.CENTER,
      margin: EdgeInsets.only(top: 300),
      onOpened: (map) {
        // Ad opened
        print('Ad shown with ID: ${map['response_id']}');
      },
      onError: (map) {
        // Error when showing ad
        print('Error showing ad, reason: $map');
      },
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
      TapsellPlus.instance.displayStandardBanner();

      TapsellPlus.instance.requestStandardBannerAd(
        '683873296280794748a5d9f4',
        TapsellPlusBannerType.BANNER_320x50,
        onResponse: (map) {
          bannerResponseId = map['response_id'];
          print('Sucessfully Got an Ad!');
          if (bannerResponseId != null) {
            Future.delayed(Duration(seconds: 2), () {
              _showBannerAd(bannerResponseId!);
            });
          }
        },
        onError: (map) {
          // Error when requesting for an ad
          print('Something went wrong');
        },
      );
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
      body: const Column(
        children: [
          Spacer(),
          Center(
            child: Text(
              'سلام! روز بخیر.',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
          Spacer(),
        ],
      ),

      bottomNavigationBar: AbsorbPointer(
        absorbing: _sending,
        child: MessageInput(
          controller: _homeTC,
          onSend: (text, file) => _sendFromHome(text: text, file: file),
          hintText: _sending ? 'در حال ارسال…' : 'هرچی میخوایی بپرس...',
          enabled: !_sending,
        ),
      ),
    );
  }
}
