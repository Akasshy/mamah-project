import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
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

class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'], name: json['name']);
  }
}

class EducationPage extends StatefulWidget {
  const EducationPage({Key? key}) : super(key: key);

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  late Future<List<Education>> educations;
  late Future<List<Category>> categories;
  int? selectedCategoryId;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Category>> fetchCategories() async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    final res = await http.get(
      Uri.parse('$baseUrl/api/education/categories'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final jsonData = jsonDecode(res.body);
      final List data = jsonData['data'];
      return data.map((e) => Category.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat kategori (${res.statusCode})');
    }
  }

  Future<List<Education>> fetchEducation({int? categoryId}) async {
    final token = await _getToken();
    if (token == null) throw Exception("Token tidak ditemukan.");

    final uri = categoryId == null
        ? Uri.parse('$baseUrl/api/education')
        : Uri.parse('$baseUrl/api/education?category_id=$categoryId');

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
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
    categories = fetchCategories();
    educations = fetchEducation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Materi Edukasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 1,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Article Section
            _buildFeaturedSection(),
            const SizedBox(height: 24),

            // All Articles Section with Filter
            _buildArticlesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Artikel Pilihan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<Education?>(
          future: fetchLatestEducation(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildFeaturedSkeleton();
            }
            if (snap.hasError) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Error: ${snap.error}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            final latest = snap.data;
            if (latest == null) {
              return Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Tidak ada artikel terbaru',
                    style: TextStyle(color: AppColors.hintTextColor),
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: () {
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
                elevation: 3,
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    // Background gambar (kalau ada fileUrl image)
                    if (latest.mediaType == 'image' &&
                        latest.fileUrl.isNotEmpty)
                      Ink.image(
                        image: NetworkImage(latest.fileUrl),
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      )
                    else
                      Container(
                        height: 200,
                        color: AppColors.inputFill,
                        child: Center(
                          child: Icon(
                            latest.mediaType == 'video'
                                ? Icons.play_circle_fill
                                : Icons.article,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    // Overlay gradient
                    Container(
                      height: 200,
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
                    ),

                    // Teks judul + tanggal
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latest.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Terbit: ${latest.createdAt}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Semua Artikel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            FutureBuilder<List<Category>>(
              future: categories,
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                final items = snap.data!;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: DropdownButton<int?>(
                    value: selectedCategoryId,
                    hint: Text(
                      'Kategori',
                      style: TextStyle(color: AppColors.hintTextColor),
                    ),
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    dropdownColor: Colors.white,
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                        educations = fetchEducation(categoryId: value);
                      });
                    },
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(
                          'Semua',
                          style: TextStyle(color: AppColors.primaryTextColor),
                        ),
                      ),
                      ...items.map(
                        (cat) => DropdownMenuItem<int?>(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            style: TextStyle(color: AppColors.primaryTextColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Education>>(
          future: educations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildListSkeleton();
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(color: AppColors.hintTextColor),
                  ),
                ),
              );
            }
            final list = snapshot.data!;
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Tidak ada artikel',
                    style: TextStyle(color: AppColors.hintTextColor),
                  ),
                ),
              );
            }
            return ListView.separated(
              itemCount: list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final edu = list[i];
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        edu.mediaType == 'image'
                            ? Icons.image
                            : Icons.play_circle_fill,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      edu.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Terbit: ${edu.createdAt}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.hintTextColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    onTap: () {
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
    );
  }

  Widget _buildFeaturedSkeleton() => Container(
    height: 200,
    decoration: BoxDecoration(
      color: AppColors.inputFill,
      borderRadius: BorderRadius.circular(16),
    ),
  );

  Widget _buildListSkeleton() => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 8),
    itemBuilder: (_, __) => Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
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
