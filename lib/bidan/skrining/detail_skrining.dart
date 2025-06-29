import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_app/ip_config.dart';

class DetailSkrining extends StatefulWidget {
  final Map<String, dynamic> userData;
  const DetailSkrining({Key? key, required this.userData}) : super(key: key);

  @override
  State<DetailSkrining> createState() => _DetailSkriningState();
}

class _DetailSkriningState extends State<DetailSkrining> {
  Map<String, dynamic>? screeningResult;
  bool isLoading = true;
  // final DateFormat dateFormat = DateFormat('dd MMMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _fetchScreeningResult();
  }

  Future<void> _fetchScreeningResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = widget.userData['id'];

      final response = await http.get(
        Uri.parse('$baseUrl/api/screening/user/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (mounted) {
          setState(() {
            screeningResult = data;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            screeningResult = null;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          screeningResult = null;
          isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'rendah':
        return Colors.green;
      case 'sedang':
        return Colors.orange;
      case 'tinggi':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String namaIbu = widget.userData['name'] ?? 'Nama tidak tersedia';
    final String? photoPath = widget.userData['photo'];
    final ImageProvider imageProvider =
        (photoPath != null && photoPath.isNotEmpty)
        ? NetworkImage('$baseUrl/storage/$photoPath')
        : const AssetImage('assets/images/default_profile.png');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Detail Skrining",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        // centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : screeningResult == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    size: 50,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Ibu/Paseien belum melakukan skrining",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _fetchScreeningResult,
                    child: const Text("Coba lagi"),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Profil
                  Card(
                    color: AppColors.background,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: imageProvider,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            namaIbu,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Status Cards Row
                  Row(
                    children: [
                      // Status Card
                      Expanded(
                        child: _buildInfoCard(
                          title: "Status",
                          content: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                screeningResult!['category'],
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _getStatusColor(
                                  screeningResult!['category'],
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              screeningResult!['category'] ?? '-',
                              style: TextStyle(
                                color: _getStatusColor(
                                  screeningResult!['category'],
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Score Card
                      Expanded(
                        child: _buildInfoCard(
                          title: "Skor EPDS",
                          content: Text(
                            screeningResult!['score']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Screening Details Card
                  Card(
                    color: AppColors.background,

                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Detail Skrining",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailItem(
                            "Tanggal Skrining",
                            DateTime.parse(screeningResult!['created_at'])
                                .toLocal()
                                .toString()
                                .split(' ')[0], // Menjadi format yyyy-MM-dd
                          ),
                          _buildDetailItem(
                            "Kategori Risiko",
                            screeningResult!['category'] ?? '-',
                          ),
                          _buildDetailItem(
                            "Skor Total",
                            screeningResult!['score']?.toString() ?? '-',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Rekomendasi:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              screeningResult!['recommendation'] ??
                                  'Tidak ada rekomendasi tersedia',
                              style: const TextStyle(height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HomePage(initialIndex: 4, role: 'bidan'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Hubungi Pasien",
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      color: AppColors.background,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Center(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
