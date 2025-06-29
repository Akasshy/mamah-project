import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/bidan/skrining/detail_skrining.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:health_app/ip_config.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

class SkriningBidan extends StatefulWidget {
  const SkriningBidan({Key? key}) : super(key: key);

  @override
  State<SkriningBidan> createState() => _SkriningBidanState();
}

class _SkriningBidanState extends State<SkriningBidan> {
  List<Map<String, dynamic>> _filteredChats = [];
  List<Map<String, dynamic>> _allChats = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isSearching = false;
  String _selectedStatus = '';
  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterChats);
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/screening/all/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List users = jsonData['data'] ?? []; // Null check added

        final formattedUsers = users.map<Map<String, dynamic>>((user) {
          return {
            'name': user['name'] ?? 'Nama tidak tersedia',
            'imageUrl': user['photo']?.toString() ?? '', // Safe conversion
            'category':
                user['screening_result']?['category']?.toString() ??
                'Belum ada data',
            'userData': user,
            'lastScreening':
                user['screening_result']?['created_at']?.toString() ?? '',
            'userId': user['id']?.toString() ?? 'N/A',
          };
        }).toList();

        if (mounted) {
          setState(() {
            _allChats = formattedUsers;
            _filteredChats = formattedUsers;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredChats = _allChats.where((chat) {
        final name = chat['name'].toString().toLowerCase();
        final category = chat['category'].toString().toLowerCase();

        final matchesSearch = name.contains(query) || category.contains(query);

        final matchesStatus =
            _selectedStatus.isEmpty ||
            category == _selectedStatus.toLowerCase();

        return matchesSearch && matchesStatus;
      }).toList();
    });
  }

  Widget _buildStatusIndicator(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'rendah':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'sedang':
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case 'tinggi':
        color = Colors.red;
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        appBar: AppBar(
          title: const Text(
            'Daftar Skrining',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh,
                color: AppColors.buttonBackground,
              ),
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchUsers();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari pasien atau status...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.buttonBackground,
                    ),
                    suffixIcon: _isSearching
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _searchController.clear();
                              _filterChats();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

            // Status Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatusChip('Semua', Colors.blue),
                    const SizedBox(width: 8),
                    _buildStatusChip('Rendah', Colors.green),
                    const SizedBox(width: 8),
                    _buildStatusChip('Sedang', Colors.orange),
                    const SizedBox(width: 8),
                    _buildStatusChip('Tinggi', Colors.red),
                    const SizedBox(width: 8),
                    _buildStatusChip('Belum ada data', Colors.grey),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

            // List Header
            if (!_isLoading && _filteredChats.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Nama Pasien',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Terakhir',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3),

            // Loading State
            if (_isLoading) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return _buildLoadingItem();
                  },
                ),
              ),
            ] else ...[
              // Empty State
              if (_filteredChats.isEmpty) ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSearching ? Icons.search_off : Icons.people_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching
                            ? 'Tidak ditemukan hasil pencarian'
                            : 'Belum ada data skrining',
                        style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchUsers();
                        },
                        child: const Text('Muat Ulang'),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Data List
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredChats.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        final imagePath = chat['imageUrl'];
                        return _buildPatientCard(chat, imagePath, index);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    final isSelected =
        (_selectedStatus.isEmpty && text == 'Semua') || _selectedStatus == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (text == 'Semua') {
            _selectedStatus = '';
          } else if (_selectedStatus == text) {
            _selectedStatus = '';
          } else {
            _selectedStatus = text;
          }
          _filterChats();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? color : Colors.black54,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(width: 120, height: 14, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(
    Map<String, dynamic> chat,
    String imagePath,
    int index,
  ) {
    return Card(
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailSkrining(userData: chat['userData']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              imagePath.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                        '$baseUrl/storage/${chat['imageUrl']}',
                      ),
                      backgroundColor: Colors.grey[200],
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.white),
                    ),

              const SizedBox(width: 12),

              // Nama & ID
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Status
              Flexible(flex: 4, child: _buildStatusIndicator(chat['category'])),

              const SizedBox(width: 4),

              // Tanggal terakhir
              Flexible(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    (chat['lastScreening'] != null &&
                            chat['lastScreening'].toString().isNotEmpty)
                        ? chat['lastScreening'].toString().split('T')[0]
                        : '-',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 4),

              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
  }
}
