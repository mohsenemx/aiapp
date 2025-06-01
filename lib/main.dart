import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/api_service.dart';
import 'package:tapsell_plus/tapsell_plus.dart';

int stars = 1000;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await ApiService.instance.init();

  runApp(const MyApp());
  final appId =
      "pbtnjdqsglrqpbtphbsgtjhfkpcooaircpdtjkgtctrjpsnfhhetseprlsrmbrnrjjjebt";
  TapsellPlus.instance.initialize(appId);
  TapsellPlus.instance.setDebugMode(LogLevel.Debug);
  initializeDateFormatting();
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
                      surface: Color.fromRGBO(235, 252, 238, 1),
                      primary: Color.fromRGBO(37, 87, 78, 1),
                      secondary: Color.fromRGBO(22, 56, 50, 1),
                    ),
          ),
          locale: const Locale('fa', 'IR'),
          debugShowCheckedModeBanner: false,
          home: SplashScreen(
            toggleTheme: toggleTheme,
            userId: ApiService.instance.currentUuid ?? '',
          ),
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
