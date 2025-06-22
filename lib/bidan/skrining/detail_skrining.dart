import 'package:flutter/material.dart';
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
  final DateFormat dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _fetchScreeningResult();
  }

  Future<void> _fetchScreeningResult() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = widget.userData['id'];

    final response = await http.get(
      Uri.parse('$baseUrl/api/screening/user/$userId'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
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
  }

  @override
  Widget build(BuildContext context) {
    final String namaIbu = widget.userData['name'];
    final String? photoPath = widget.userData['photo'];
    final ImageProvider imageProvider =
        (photoPath != null && photoPath.isNotEmpty)
        ? NetworkImage('$baseUrl/storage/$photoPath')
        : const AssetImage('images/default-pp.jpg');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Detail Skrining"),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : screeningResult == null
          ? const Center(child: Text("Hasil skrining tidak ditemukan."))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: imageProvider,
                          backgroundColor: Colors.grey[300],
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
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HomePage(initialIndex: 4, role: 'bidan'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Hubungi Pasien'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "EPDS Terbaru",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tanggal: ${dateFormat.format(DateTime.parse(screeningResult!['created_at']))}",
                        ),
                        Text("Skor: ${screeningResult!['score']}"),
                        const SizedBox(height: 8),
                        const Text(
                          "Rekomendasi:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(screeningResult!['recommendation']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
