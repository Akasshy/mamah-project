import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/edukasi/detail-education.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RelaxationVideo {
  final int id;
  final String title;
  final String mediaType; // video / image
  final String? fileUrl;
  final String description;
  final String createdAt;

  RelaxationVideo({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.fileUrl,
    required this.description,
    required this.createdAt,
  });

  factory RelaxationVideo.fromJson(Map<String, dynamic> json) {
    return RelaxationVideo(
      id: json['id'],
      title: json['title'] ?? '',
      mediaType: json['media_type'] ?? 'video',
      fileUrl: json['file_url'],
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class RelaxasiPage extends StatefulWidget {
  const RelaxasiPage({Key? key}) : super(key: key);

  @override
  State<RelaxasiPage> createState() => _RelaxasiPageState();
}

class _RelaxasiPageState extends State<RelaxasiPage> {
  late Future<List<RelaxationVideo>> videos;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<RelaxationVideo>> fetchRelaxationVideos() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    final res = await http.get(
      Uri.parse('$baseUrl/api/relaxation'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      final List data = jsonData['data'];
      return data.map((e) => RelaxationVideo.fromJson(e)).toList();
    } else if (res.statusCode == 404) {
      // API mengirim 404 bila kosong
      return [];
    } else {
      throw Exception('Gagal memuat data (${res.statusCode})');
    }
  }

  @override
  void initState() {
    super.initState();
    videos = fetchRelaxationVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Video Relaksasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<RelaxationVideo>>(
          future: videos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildListSkeleton();
            }
            if (snapshot.hasError) {
              return _errorBox('Error: ${snapshot.error}');
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return _errorBox('Belum ada video relaksasi yang tersedia.');
            }
            return ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = list[i];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.mediaType == 'video'
                            ? Icons.play_circle_fill
                            : Icons.image,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Terbit: ${item.createdAt}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.hintTextColor,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    onTap: () {
                      // arahkan ke halaman detail lama, cukup kirim id
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EducationDetailPage(id: item.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Center(
      child: Text(
        msg,
        style: TextStyle(color: AppColors.hintTextColor),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _buildListSkeleton() => ListView.separated(
    shrinkWrap: true,
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, __) => Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Container(
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            height: 12,
            width: 100,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    ),
  );
}
