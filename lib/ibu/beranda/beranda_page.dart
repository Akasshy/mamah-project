// ==================== IMPORTS ====================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
// import 'package:health_app/edukasi/detail-education.dart';
import 'package:health_app/edukasi/education_page.dart';
// import 'package:health_app/homePage.dart';
import 'package:health_app/ibu/beranda/reksasipage.dart';
import 'package:health_app/ibu/diskusi/diskusi_page.dart';
import 'package:health_app/ibu/skrining/show_score_page.dart';
import 'package:health_app/ibu/skrining/skrinings_page.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
// ignore: unused_import
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// ==================== MODEL ====================
class RelaxationVideo {
  final int id;
  final String title;
  final String mediaType;
  final String? fileUrl;

  RelaxationVideo({
    required this.id,
    required this.title,
    required this.mediaType,
    this.fileUrl,
  });

  factory RelaxationVideo.fromJson(Map<String, dynamic> json) {
    return RelaxationVideo(
      id: json['id'],
      title: json['title'],
      mediaType: json['media_type'],
      fileUrl: json['file_url'],
    );
  }
}

// ==================== MAIN PAGE ====================
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

  List<RelaxationVideo> relaxationVideos = [];
  bool isLoadingRelaxation = true;

  final List<String> dailyTips = [
    "Istirahat cukup penting untuk kesehatan mental",
    "Luangkan waktu untuk diri sendiri",
    "Jangan ragu meminta bantuan",
    "Olahraga ringan dapat meningkatkan mood",
    "Tetap terhubung dengan orang terdekat",
    "Kurangi penggunaan media sosial",
    "Jaga pola makan dan hidrasi",
  ];

  RelaxationVideo? relaxationVideo;

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchScreeningResult();
    fetchAndSetRelaxationVideo();
    _startBannerTimer();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  // ==================== API & DATA ====================
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<RelaxationVideo?> fetchRelaxationVideo() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    final res = await http.get(
      Uri.parse('$baseUrl/api/flyer'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      final data = jsonData['data'];
      return RelaxationVideo.fromJson(data);
    } else if (res.statusCode == 404) {
      return null;
    } else {
      throw Exception('Gagal memuat data (${res.statusCode})');
    }
  }

  void fetchAndSetRelaxationVideo() async {
    try {
      final video = await fetchRelaxationVideo();
      if (mounted) {
        setState(() {
          relaxationVideo = video;
          isLoadingRelaxation = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRelaxation = false;
      });
      debugPrint("Error memuat video: $e");
    }
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

  // ==================== UI ====================
  @override
  Widget build(BuildContext context) {
    final String tipsHariIni = dailyTips[DateTime.now().weekday % 7];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(tipsHariIni),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(color: AppColors.background),
        padding: const EdgeInsets.only(top: 10.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'MaMah',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userName ?? 'Loading...',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
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
                                ? const AssetImage(
                                    'assets/images/default-pp.jpg',
                                  )
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
    );
  }

  Widget _buildBody(String tipsHariIni) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salam
            Text(
              "Selamat Datang, ${userName ?? 'Ibu'}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),

            const SizedBox(height: 12),

            // Menu Utama
            _buildMainMenu(),

            const SizedBox(height: 16),

            // Judul Video (Video Flyer)
            Text(
              relaxationVideo?.title ?? "Video Flyer",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            _buildVideoSection(),

            const SizedBox(height: 16),

            // Ringkasan Kesehatan
            _buildHealthSummaryCard(
              'Ringkasan Kesehatan',
              'Skor Skrining Terakhir: $skor',
              'Status: $kategori',
              Icons.health_and_safety,
              Colors.teal, // hijau lembut → menandakan kesehatan
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LihatSkor()),
                );
              },
            ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.4),

            const SizedBox(height: 16),

            // Artikel Terbaru
            _buildInfoCard(
              'Artikel Terbaru',
              'Tips kesehatan mental pasca melahirkan',
              Icons.article_outlined,
              Colors.indigo, // warna utama lembut & profesional
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EducationPage(),
                  ),
                );
              },
            ).animate().fadeIn(duration: 1000.ms).slideY(begin: 0.5),
          ],
        ),
      ),
    );
  }

  // ==================== SUB-UI ====================
  Widget _buildMainMenu() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildMenuCard(
            context,
            'Relaksasi',
            Icons.self_improvement_outlined,
            AppColors.primary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RelaxasiPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMenuCard(
            context,
            'Edukasi',
            Icons.menu_book_outlined,
            AppColors.primary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EducationPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMenuCard(
            context,
            'Skrining',
            Icons.assignment_outlined,
            AppColors.primary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SkriningsPage()),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMenuCard(
            context,
            'Komunitas',
            Icons.forum_outlined,
            AppColors.primary,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DiskusiPage()),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.4);
  }

  Widget _buildVideoSection() {
    if (isLoadingRelaxation) {
      return const Center(child: CircularProgressIndicator());
    } else if (relaxationVideo == null) {
      return const Text("Belum ada video yang tersedia.");
    } else {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: YoutubePlayer.convertUrlToId(
                    relaxationVideo!.fileUrl ?? '',
                  )!,
                  flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
                ),
                showVideoProgressIndicator: true,
              ),
            ),
          ],
        ),
      );
    }
  }

  // ==================== CARD WIDGETS ====================
  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 94,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
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
      action: 'Lihat Selengkapnya',
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
    String? action,
    VoidCallback? onTap, // ubah jadi nullable
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap, // InkWell onTap sudah menerima nullable
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
                  child: InkWell(
                    onTap: onTap, // tetap aman karena nullable
                    child: Text(
                      action,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
