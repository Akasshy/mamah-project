import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:health_app/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // Mock data SharedPreferences untuk testing
    SharedPreferences.setMockInitialValues({
      'token': 'dummy_token',
      'role': 'ibu',
    });
  });

  testWidgets('Aplikasi bisa load dan tampil', (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role') ?? 'ibu';

    await tester.pumpWidget(MyApp(isLoggedIn: token != null, role: role));

    // Misalnya cek apakah ada teks tertentu muncul
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
