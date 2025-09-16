import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/edukasi/detail-education.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Education {
  final int id;
  final String title;
  final String mediaType;
  final String fileUrl;
  final String description;
  final String createdAt;

  Education({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.fileUrl,
    required this.description,
    required this.createdAt,
  });

  factory Education.fromJson(Map<String, dynamic> json) {
    return Education(
      id: json['id'],
      title: json['title'] ?? '',
      mediaType: json['media_type'] ?? 'image',
      fileUrl: json['file_url'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  late Future<List<Education>> educations;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Education>> fetchEducation() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Token tidak ditemukan. Harap login ulang.");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/education'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      List data = jsonData['data'];
      return data.map((e) => Education.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data edukasi (${response.statusCode})');
    }
  }

  Future<Education?> fetchLatestEducation() async {
    final token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(
      Uri.parse('$baseUrl/api/education/latest'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data'] != null) {
        return Education.fromJson(data['data']);
      }
      return null;
    } else {
      throw Exception('Gagal memuat artikel terbaru (${response.statusCode})');
    }
  }

  @override
  void initState() {
    super.initState();
    educations = fetchEducation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: const Text('Materi Edukasi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Artikel Pilihan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: FutureBuilder<Education?>(
                future: fetchLatestEducation(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _buildFeaturedSkeleton();
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snap.error}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  final latest = snap.data;
                  if (latest == null) {
                    return const Center(
                      child: Text(
                        'Tidak ada artikel terbaru',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      // ===> Pindah ke halaman detail
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EducationDetailPage(id: latest.id),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          latest.mediaType == 'image'
                              ? Image.network(
                                  latest.fileUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 50),
                                  ),
                                )
                              : Container(
                                  color: Colors.black26,
                                  child: const Icon(
                                    Icons.play_circle_fill,
                                    size: 60,
                                    color: Colors.white,
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              child: Text(
                                latest.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Semua Artikel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Education>>(
              future: educations,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildListSkeleton();
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final list = snapshot.data!;
                return ListView.builder(
                  itemCount: list.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, i) {
                    final edu = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: edu.mediaType == 'image'
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  edu.fileUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.play_circle_fill,
                                size: 40,
                                color: Colors.blue,
                              ),
                        title: Text(
                          edu.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Terbit: ${edu.createdAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          // ===> Pindah ke halaman detail
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EducationDetailPage(id: edu.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSkeleton() => Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Container(color: Colors.grey[300]),
  );

  Widget _buildListSkeleton() => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 5,
    itemBuilder: (_, __) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
