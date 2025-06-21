import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BerandaBidan extends StatefulWidget {
  const BerandaBidan({Key? key}) : super(key: key);

  @override
  State<BerandaBidan> createState() => _BerandaBidanState();
}

class _BerandaBidanState extends State<BerandaBidan> {
  String? userName;
  String? photoUrl;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  void loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      debugPrint('Token kosong!');
      return;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    debugPrint('STATUS: ${response.statusCode}');
    debugPrint('BODY: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        setState(() {
          userName = data['name'] ?? '';
          photoUrl = data['photo'] ?? '';
        });
      } catch (e) {
        debugPrint('Gagal decode JSON: $e');
      }
    } else {
      debugPrint('API gagal (status: ${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Image.asset(
                        'images/logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          ).then((_) => loadUserData());
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName ?? 'Loading...',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          ).then((_) => loadUserData());
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage:
                              (photoUrl == null || photoUrl!.isEmpty)
                              ? const AssetImage('images/default-pp.jpg')
                                    as ImageProvider
                              : NetworkImage(photoUrl!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotifikasiPage()),
                    );
                  },
                  child: _buildCardTemplate(
                    title: 'Ringkasan Notifikasi',
                    content: 'Anda memiliki 2 notifikasi baru.',
                    icon: Icons.notifications,
                    color: Colors.blue[100],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HasilSkriningPage(),
                      ),
                    );
                  },
                  child: _buildCardTemplate(
                    title: 'Hasil Skrining Terbaru',
                    content: 'Skor Anda: 12',
                    icon: Icons.assignment_turned_in,
                    color: Colors.green[100],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardTemplate({
    required String title,
    required String content,
    required IconData icon,
    required Color? color,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color ?? Colors.grey.shade200, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: Colors.black54),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotifikasiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: const Center(child: Text('Halaman Notifikasi')),
    );
  }
}

class HasilSkriningPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hasil Skrining')),
      body: const Center(child: Text('Halaman Hasil Skrining')),
    );
  }
}
