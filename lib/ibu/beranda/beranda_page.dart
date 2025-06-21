import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Beranda extends StatefulWidget {
  const Beranda({Key? key}) : super(key: key);

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
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
    final List<String> imageUrls = [
      'images/baner.jpg',
      'images/baner2.jpeg',
      'images/baner.jpg',
      'images/baner2.jpeg',
      'images/baner.jpg',
    ];

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
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Image.asset(
                            'images/logo.png',
                            height: 36,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(),
                                ),
                              ).then((_) {
                                loadUserData();
                              });
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
                              ).then((_) {
                                loadUserData();
                              });
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
                SizedBox(
                  height: MediaQuery.of(context).size.width * 6 / 16,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        margin: const EdgeInsets.only(right: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, exception, stackTrace) {
                              return const Center(
                                child: Text('Failed to load image'),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  'Ringkasan Skor Skrining Terakhir',
                  'Skor Anda: 12',
                  Colors.green[100],
                  Icons.check_circle,
                ),
                const SizedBox(height: 16),
                _buildNotificationCard(
                  'Notifikasi',
                  'Anda memiliki 2 notifikasi baru.',
                  Colors.blue[100],
                  Icons.notifications_active,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Informasi Terbaru',
                  'Jangan lupa untuk melakukan skrining kesehatan mental Anda.',
                  Colors.orange[100],
                  Icons.info_outline,
                ),
                const SizedBox(height: 16),
                _buildTipsCard(
                  'Tips Kesehatan Ibu Setelah Melahirkan',
                  '1. Istirahat yang cukup.\n2. Makan makanan bergizi.\n3. Jaga kesehatan mental.',
                  Colors.pink[100],
                  Icons.favorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildNotificationCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildInfoCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildTipsCard(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
    return _buildCardTemplate(title, content, color, icon);
  }

  Widget _buildCardTemplate(
    String title,
    String content,
    Color? color,
    IconData icon,
  ) {
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
