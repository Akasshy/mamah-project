import 'package:flutter/material.dart';
import 'package:health_app/next_register_page.dart';
import 'loginPage.dart';
import 'registerPage.dart';
import 'homePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MaMaH',
      initialRoute: '/',
      routes: {
        '/': (context) => const NextRegisterPage(),
        '/register': (context) => const RegisterPage(),
        '/homeibu': (context) => const HomePage(initialIndex: 0, role: 'ibu'),
        '/homebidan': (context) =>
            const HomePage(initialIndex: 0, role: 'bidan'),
      },
    );
  }
}
