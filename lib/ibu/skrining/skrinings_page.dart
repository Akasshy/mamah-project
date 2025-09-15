import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/ibu/skrining/question_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SkriningsPage extends StatefulWidget {
  const SkriningsPage({Key? key}) : super(key: key);

  @override
  State<SkriningsPage> createState() => _SkriningsPageState();
}

class _SkriningsPageState extends State<SkriningsPage> {
  int? skorTerakhir;
  String? kategori;
  String? rekomendasi;
  DateTime? tanggalSkor;
  bool isLoading = true;
  String? errorMessage;
  final DateFormat dateFormat = DateFormat('dd MMM yyyy');

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
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: const Text(
          'Skrining Kesehatan Ibu',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black54),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHasilSkorCard(showConsultButton),
            const SizedBox(height: 24),
            _ModernMenuCard(
              title: 'Isi Kuesioner EPDS',
              icon: Icons.assignment_turned_in_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QuestionPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHasilSkorCard(bool showConsultButton) {
    return Card(
      color: AppColors.inputFill,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (tanggalSkor != null)
                    Text(
                      "HASIL SKRINING • ${dateFormat.format(tanggalSkor!)}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(kategori).withOpacity(0.2),
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
                      color: _getCategoryColor(kategori).withOpacity(0.1),
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
                  const SizedBox(height: 16),
                  if (rekomendasi != null)
                    Text(
                      rekomendasi!,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  if (showConsultButton) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HomePage(initialIndex: 4, role: 'ibu'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Konsultasi dengan Bidan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tentang Skrining',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Skrining ini membantu mendeteksi dini kondisi kesehatan mental ibu. '
                'Hasilnya akan memberikan gambaran tentang kondisi Anda saat ini.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Mengerti',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Card untuk menu
class _ModernMenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ModernMenuCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ModernMenuCard> createState() => _ModernMenuCardState();
}

class _ModernMenuCardState extends State<_ModernMenuCard> {
  bool _isHovered = false;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isTapped
                ? AppColors.inputBorderFocused.withOpacity(0.1)
                : _isHovered
                ? AppColors.inputFill
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            border: Border.all(
              color: _isHovered
                  ? AppColors.inputBorderFocused.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBorderFocused.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  widget.icon,
                  color: AppColors.inputBorderFocused,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
