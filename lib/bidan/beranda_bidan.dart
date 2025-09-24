import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/bidan/skrining/skrinings_bidan.dart';
import 'package:health_app/edukasi/education_page.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ibu/beranda/reksasipage.dart';
import 'package:health_app/ibu/diskusi/diskusi_page.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/profile.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class BerandaBidan extends StatefulWidget {
  const BerandaBidan({Key? key}) : super(key: key);

  @override
  State<BerandaBidan> createState() => _BerandaBidanState();
}

class _BerandaBidanState extends State<BerandaBidan> {
  String? userName;
  String? photoUrl;

  bool isLoadingRelaxation = true;
  Map<String, dynamic>? relaxationVideo;

  // 🔥 Tambahan state untuk data rata-rata skrining
  bool isLoadingAverage = true;
  Map<String, dynamic>? averageData;

  @override
  void initState() {
    super.initState();
    loadUserData();
    fetchAndSetRelaxationVideo();
    fetchAverageScore(); // 🔥 ambil data rata-rata skrining
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

    if (!mounted) return;

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

  Future<void> fetchAndSetRelaxationVideo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/relaxation-video'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          relaxationVideo = data['video']; // pastikan format sesuai API
          isLoadingRelaxation = false;
        });
      } else {
        setState(() => isLoadingRelaxation = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingRelaxation = false);
      debugPrint("Error memuat video: $e");
    }
  }

  // 🔥 Fungsi untuk ambil rata-rata skrining
  Future<void> fetchAverageScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('$baseUrl/api/screening/average'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          averageData = data['data'];
          isLoadingAverage = false;
        });
      } else {
        setState(() => isLoadingAverage = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingAverage = false);
      debugPrint("Error ambil average score: $e");
    }
  }

  Widget _buildVideoSection() {
    if (isLoadingRelaxation) {
      return const Center(child: CircularProgressIndicator());
    } else if (relaxationVideo == null ||
        relaxationVideo!['file_url'] == null) {
      return const Text(
        "Belum ada video yang tersedia.",
        style: TextStyle(color: Colors.white, fontSize: 16),
      );
    } else {
      final videoUrl = relaxationVideo!['file_url'];
      final videoId = YoutubePlayer.convertUrlToId(videoUrl ?? '');
      if (videoId == null) {
        return const Text("Video tidak valid.");
      }
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
                  initialVideoId: videoId,
                  flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
                ),
                showVideoProgressIndicator: true,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 500.ms);
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
                Text(
                  "Selamat Datang, ${userName ?? 'Ibu'}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                const SizedBox(height: 12),
                _buildVideoSection(),

                const SizedBox(height: 16),

                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildMenuCard(
                        context,
                        'Relaksasi',
                        Icons.self_improvement_outlined,
                        AppColors.primary,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RelaxasiPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildMenuCard(
                        context,
                        'Edukasi',
                        Icons.menu_book_outlined,
                        Colors.blue,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EducationPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildMenuCard(
                        context,
                        'Skrining',
                        Icons.assignment_outlined,
                        AppColors.primary,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SkriningBidan(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildMenuCard(
                        context,
                        'Komunitas',
                        Icons.forum_outlined,
                        AppColors.primary,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DiskusiPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 🔥 Card dengan data API
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SkriningBidan(),
                      ),
                    );
                  },
                  child: _buildCardTemplate(
                    title: 'Rata-Rata Skrining',
                    content: isLoadingAverage
                        ? "Memuat..."
                        : "Total Ibu: ${averageData?['total_mothers'] ?? '-'}\n"
                              "Rata-rata: ${averageData?['average_score'] ?? '-'}\n"
                              "Kategori: ${averageData?['category'] ?? '-'}",
                    icon: Icons.assignment_turned_in,
                    color: Colors.blue.shade300,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildCardTemplate({
    required String title,
    required String content,
    required IconData icon,
    required Color? color,
  }) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.white),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    content,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
