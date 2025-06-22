import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ibu/skrining/show_score_page.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class Beranda extends StatefulWidget {
  const Beranda({Key? key}) : super(key: key);

  @override
  State<Beranda> createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  String? userName;
  String? photoUrl;
  String skor = '-';
  String kategori = '-';

  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  final List<String> dailyTips = [
    "Istirahat cukup penting untuk kesehatan mental",
    "Luangkan waktu untuk diri sendiri",
    "Jangan ragu meminta bantuan",
    "Olahraga ringan dapat meningkatkan mood",
    "Tetap terhubung dengan orang terdekat",
    "Kurangi penggunaan media sosial",
    "Jaga pola makan dan hidrasi",
  ];

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchScreeningResult();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    Future.delayed(const Duration(seconds: 5)).then((_) {
      if (_bannerController.hasClients) {
        if (_currentBannerIndex < 4) {
          _bannerController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        } else {
          _bannerController.animateToPage(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
        _startBannerTimer();
      }
    });
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
    }
  }

  void fetchScreeningResult() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/screening/result'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final result = data['data'];

      if (mounted) {
        setState(() {
          skor = result['score'].toString();
          kategori = result['category'] ?? 'Belum ada data';
        });
      }
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

    final String tipsHariIni = dailyTips[DateTime.now().weekday % 7];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.1),
              //     blurRadius: 10,
              //     offset: const Offset(0, 5),
              //   ),
              // ],
            ),
            padding: const EdgeInsets.only(top: 10.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'MaMaH',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonBackground,
                        ),
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
                        child: Row(
                          children: [
                            Column(
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
                                const SizedBox(height: 4),
                                Text(
                                  'Lihat Profil',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey[200],
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    (photoUrl == null || photoUrl!.isEmpty)
                                    ? const AssetImage('images/default-pp.jpg')
                                    : NetworkImage(photoUrl!) as ImageProvider,
                              ),
                            ),
                          ],
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Selamat Datang, ${userName ?? ''}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                ),
                SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _bannerController,
                        itemCount: imageUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentBannerIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, exception, stackTrace) =>
                                        Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _bannerController,
                            count: imageUrls.length,
                            effect: const WormEffect(
                              dotHeight: 8,
                              dotWidth: 8,
                              activeDotColor: Colors.white,
                              dotColor: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                const SizedBox(height: 24),
                _buildHealthSummaryCard(
                  'Ringkasan Kesehatan',
                  'Skor Skrining Terakhir: $skor',
                  'Status: $kategori',
                  Icons.health_and_safety,
                  Colors.green.withOpacity(0.8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LihatSkor(),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.4),
                const SizedBox(height: 16),
                _buildTipsCard(
                  'Tips Hari Ini',
                  tipsHariIni,
                  Icons.lightbulb,
                  Colors.orange.withOpacity(0.8),
                ).animate().fadeIn(duration: 900.ms).slideX(begin: -0.1),
                const SizedBox(height: 16),
                _buildInfoCard(
                  'Artikel Terbaru',
                  'Baca artikel tentang kesehatan mental pasca melahirkan',
                  Icons.article,
                  Colors.purple.withOpacity(0.8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HomePage(initialIndex: 2, role: 'ibu'),
                      ),
                    );
                  },
                ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(
    String title,
    String content,
    IconData icon,
    Color color,
  ) {
    return _buildCardTemplate(title, content, icon, color);
  }

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return _buildCardTemplate(
      title,
      content,
      icon,
      color,
      action: 'Baca Selengkapnya',
      onTap: onTap,
    );
  }

  Widget _buildHealthSummaryCard(
    String title,
    String score,
    String status,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return _buildCardTemplate(
      title,
      '$score\n$status',
      icon,
      color,
      onTap: onTap,
    );
  }

  Widget _buildCardTemplate(
    String title,
    String content,
    IconData icon,
    Color color, {
    bool badge = false,
    String? action,
    VoidCallback? onTap,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.2), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    action,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
