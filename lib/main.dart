import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginPage.dart';
import 'registerPage.dart';
import 'homePage.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pastikan mendukung portrait & landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Mengatur status bar transparan
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Cek apakah user sudah login sebelumnya
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  final role = prefs.getString('role') ?? 'ibu';
  debugPaintSizeEnabled = false;

  runApp(MyApp(isLoggedIn: token != null, role: role));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String role;

  const MyApp({super.key, required this.isLoggedIn, required this.role});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MaMaH',
      initialRoute: '/',
      routes: {
        '/': (context) => isLoggedIn
            ? HomePage(initialIndex: 0, role: role)
            : const LoginPage(),
        '/register': (context) => const RegisterPage(),
      },
    );
  }
}
