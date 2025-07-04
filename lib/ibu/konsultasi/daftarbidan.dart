import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ibu/konsultasi/open_konsultasi_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_app/ip_config.dart';

class DaftarPasanganPage extends StatefulWidget {
  const DaftarPasanganPage({Key? key}) : super(key: key);

  @override
  State<DaftarPasanganPage> createState() => _DaftarPasanganPageState();
}

class _DaftarPasanganPageState extends State<DaftarPasanganPage> {
  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  String _role = '';
  Set<int> _sudahDikonsultasi = {};

  @override
  void initState() {
    super.initState();
    _initData();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initData() async {
    await _loadRole();
    await fetchDaftarPasangan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
    });
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users
          .where((user) => user['name'].toLowerCase().contains(keyword))
          .toList();
    });
  }

  Future<void> fetchKonsultasiSaya() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getInt('user_id');

      final response = await http.get(
        Uri.parse('$baseUrl/api/consultations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;

        final pasanganIds = data
            .where((e) {
              if (_role == 'bidan') {
                return e['bidan_id'] == userId;
              } else {
                return e['ibu_id'] == userId;
              }
            })
            .map((e) {
              if (_role == 'bidan') {
                return e['ibu_id'] as int?;
              } else {
                return e['bidan_id'] as int?;
              }
            })
            .whereType<int>()
            .toSet();

        if (mounted) {
          setState(() {
            _sudahDikonsultasi = pasanganIds;
          });
        }
      } else {
        debugPrint('Gagal mengambil data konsultasi');
      }
    } catch (e) {
      debugPrint('Error fetchKonsultasiSaya: $e');
    }
  }

  Future<void> fetchDaftarPasangan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      isLoading = true;
    });

    await fetchKonsultasiSaya(); // ⏳ Pastikan selesai dulu

    final response = await http.get(
      Uri.parse('$baseUrl/api/consultations/pasangan'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;

      final filtered = data.where((user) {
        final id = user['id'] as int;
        return !_sudahDikonsultasi.contains(id);
      }).toList();

      setState(() {
        users = filtered;
        filteredUsers = filtered;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      debugPrint('Gagal mengambil daftar pasangan');
    }
  }

  Future<void> _buatKonsultasi(int pasanganId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    // Tentukan field berdasarkan role
    final Map<String, String> body = {
      'question': _role == 'bidan'
          ? 'Halo, ada yang ingin saya bicarakan.'
          : 'Halo, saya ingin berkonsultasi.',
    };

    if (_role == 'bidan') {
      body['ibu_id'] = pasanganId.toString();
    } else {
      body['bidan_id'] = pasanganId.toString();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/api/consultations/store'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body)['data'];
      final int konsultasiId = data['id'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OpenKonsultasi(konsultasiId: konsultasiId),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gagal membuat konsultasi')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_role == 'bidan' ? 'Daftar Ibu' : 'Daftar Bidan'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _role == 'bidan'
                            ? 'Cari nama ibu...'
                            : 'Cari nama bidan...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.buttonBackground,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('Tidak ditemukan pengguna.'))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            final photoUrl = user['photo'];
                            final name = user['name'];
                            final email = user['email'];

                            return ListTile(
                              leading: photoUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(photoUrl),
                                      backgroundColor: Colors.grey[300],
                                    )
                                  : const CircleAvatar(
                                      backgroundColor: AppColors.inputBorder,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(email),
                              onTap: () => _buatKonsultasi(user['id']),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
