import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/conversation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(ConversationAdapter());
  await Hive.openBox<Conversation>('chats');
  runApp(const MyApp());
}

final isDarkNotifier = ValueNotifier<bool>(true);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDark = false;
  void toggleTheme() {
    setState(() {
      isDarkNotifier.value = !isDarkNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isDarkNotifier,
      builder: (context, bool isDark, _) {
        return MaterialApp(
          title: 'چت‌بات من',
          theme: ThemeData(
            fontFamily: 'Vazir',
            useMaterial3: true,
            colorScheme:
                isDark
                    ? ColorScheme.dark(
                      surface: Color.fromRGBO(2, 17, 17, 1),
                      primary: Color.fromRGBO(93, 133, 106, 1),
                      secondary: Color.fromRGBO(35, 83, 71, 1),
                    )
                    : ColorScheme.light(
                      surface: Color.fromRGBO(218, 241, 222, 1),
                      primary: Color.fromRGBO(37, 87, 78, 1),
                      secondary: Color.fromRGBO(22, 56, 50, 1),
                    ),
          ),
          locale: const Locale('fa', 'IR'),
          debugShowCheckedModeBanner: false,
          home: SplashScreen(toggleTheme: toggleTheme),
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
        );
      },
    );
  }
}
