import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ibu/konsultasi/daftarbidan.dart';
import 'package:health_app/ibu/konsultasi/open_konsultasi_page.dart';
import 'package:health_app/ip_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class KonsultasiPage extends StatefulWidget {
  const KonsultasiPage({Key? key}) : super(key: key);

  @override
  State<KonsultasiPage> createState() => _KonsultasiPageState();
}

class _KonsultasiPageState extends State<KonsultasiPage> {
  List<dynamic> _allChats = [];
  List<dynamic> _filteredChats = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _role; // untuk menyimpan role login

  @override
  void initState() {
    super.initState();
    _fetchKonsultasi();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredChats = _allChats.where((chat) {
        final name = _role == 'bidan' ? chat['name'] : chat['bidan'];
        final topic = chat['topic']?.toLowerCase() ?? '';
        return (name?.toLowerCase() ?? '').contains(keyword) ||
            topic.contains(keyword);
      }).toList();
    });
  }

  Future<void> _fetchKonsultasi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role'); // ambil role user

    final response = await http.get(
      Uri.parse('$baseUrl/api/consultations'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (mounted) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chats = data['data'];

        setState(() {
          _allChats = chats;
          _filteredChats = chats;
          _role = role;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        debugPrint('Gagal mengambil data konsultasi.');
      }
    }
  }

  Future<void> _deleteKonsultasi(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/api/consultations/$id/delete'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konsultasi berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchKonsultasi(); // Refresh list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus konsultasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(int id) {
    showModalBottomSheet(
      backgroundColor: AppColors.background,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red[400],
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Hapus Konsultasi?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tindakan ini akan menghapus seluruh isi konsultasi termasuk semua pesan. Anda yakin?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteKonsultasi(id);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
          preferredSize: const Size.fromHeight(70),
          child: Container(
            color: Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: const [
                      Text(
                        'Konsultasi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Material(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DaftarPasanganPage(),
                      ),
                    );
                    _fetchKonsultasi(); // ✅ Baru dipanggil setelah halaman pasangan ditutup
                  },

                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_alt, color: Colors.white),
                        const SizedBox(width: 12),
                        Text(
                          _role == 'ibu' ? 'Daftar Bidan' : 'Daftar Ibu',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

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
                    hintText: 'Cari...',
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
            _isLoading
                ? const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: _filteredChats.isEmpty
                        ? const Center(child: Text('Belum ada konsultasi.'))
                        : ListView.builder(
                            itemCount: _filteredChats.length,
                            itemBuilder: (context, index) {
                              final chat = _filteredChats[index];
                              final displayName = _role == 'bidan'
                                  ? chat['name']
                                  : chat['bidan'];

                              return GestureDetector(
                                onLongPress: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  final userId = prefs.getString('user_id');

                                  final isIbu =
                                      _role == 'ibu' &&
                                      chat['user_id'].toString() == userId;
                                  final isBidan =
                                      _role == 'bidan' &&
                                      chat['bidan_id'].toString() == userId;

                                  if (isIbu || isBidan) {
                                    _showDeleteConfirmation(chat['id']);
                                  }
                                },

                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppColors.inputBorder,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    displayName ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    chat['last_reply'] ?? chat['topic'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.labelText,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OpenKonsultasi(
                                          konsultasiId: chat['id'],
                                        ),
                                      ),
                                    );
                                    _fetchKonsultasi(); // ✅ Fetch ulang setelah kembali
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}
