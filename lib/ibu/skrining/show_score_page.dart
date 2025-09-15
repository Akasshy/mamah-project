import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ip_config.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LihatSkor extends StatefulWidget {
  const LihatSkor({Key? key}) : super(key: key);

  @override
  State<LihatSkor> createState() => _LihatSkorState();
}

class _LihatSkorState extends State<LihatSkor> {
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormat = DateFormat('dd MMM yyyy');

  int? skorTerakhir;
  String? kategori;
  String? rekomendasi;
  DateTime? tanggalSkor;
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> allScores = [];
  List<Map<String, dynamic>> filteredScores = [];

  @override
  void initState() {
    super.initState();
    fetchSkorTerakhir();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> fetchSkorTerakhir() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          errorMessage = 'Token tidak ditemukan. Harap login ulang.';
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/screening/result'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final dynamic skor = data['score'];
        final String? createdAtStr = data['created_at'];

        kategori = data['category'];
        rekomendasi = data['recommendation'];

        if (skor != null && createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            setState(() {
              skorTerakhir = skor is int ? skor : int.tryParse(skor.toString());
              tanggalSkor = parsedDate;

              allScores = [
                {
                  "tanggal": tanggalSkor!,
                  "skor": skorTerakhir ?? 0,
                  "kategori": kategori,
                  "rekomendasi": rekomendasi,
                },
              ];

              filteredScores = List.from(allScores);
              isLoading = false;
            });
          } else {
            setState(() {
              errorMessage = 'Format tanggal tidak valid.';
              isLoading = false;
            });
          }
        } else {
          setState(() {
            errorMessage = 'Data skor atau tanggal tidak tersedia.';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data (${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'tinggi':
        return Colors.red[400]!;
      case 'sedang':
        return Colors.orange[400]!;
      case 'rendah':
        return Colors.green[400]!;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'tinggi':
        return Icons.warning_rounded;
      case 'sedang':
        return Icons.info_outline_rounded;
      case 'rendah':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showConsultButton = kategori?.toLowerCase() == 'tinggi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Hasil Skrining",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Skor Terakhir
            Card(
              color: AppColors.inputFill,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "HASIL SKRINING TERAKHIR",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (tanggalSkor != null)
                          Text(
                            dateFormat.format(tanggalSkor!),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          kategori,
                                        ).withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(kategori),
                                        size: 40,
                                        color: _getCategoryColor(kategori),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      skorTerakhir?.toString() ?? "--",
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getCategoryColor(
                                          kategori,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getCategoryColor(kategori),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        kategori?.toUpperCase() ?? "-",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: _getCategoryColor(kategori),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              if (rekomendasi != null) ...[
                                const Text(
                                  "REKOMENDASI",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.buttonBackground
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    rekomendasi!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                              if (showConsultButton) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const HomePage(
                                            initialIndex: 4,
                                            role: 'ibu',
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[400],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.medical_services),
                                        SizedBox(width: 8),
                                        Text(
                                          'Konsultasi dengan Bidan',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (errorMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
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
}
