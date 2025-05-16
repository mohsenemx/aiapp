import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'چت‌بات من',
      theme: ThemeData(fontFamily: 'Vazir', useMaterial3: true),
      locale: const Locale('fa', 'IR'),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );
  }
}
