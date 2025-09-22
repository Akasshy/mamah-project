import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Auth/loginPage.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSaving = false;

  // Controllers with initial values
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController fullAddressController = TextEditingController();
  final TextEditingController motherAgeController = TextEditingController();
  final TextEditingController pregnancyNumberController =
      TextEditingController();
  final TextEditingController liveChildrenCountController =
      TextEditingController();
  final TextEditingController miscarriageHistoryController =
      TextEditingController();
  final TextEditingController motherDiseaseHistoryController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEditing = false;
  String? profilePhotoUrl;
  String _role = ''; // default kosong

  // Tambahan variabel untuk detail ibu
  String? motherAge,
      pregnancyNumber,
      liveChildrenCount,
      miscarriageHistory,
      motherDiseaseHistory;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.buttonBackground, // sama kayak AppBar
        statusBarIconBrightness: Brightness.light, // icon status bar jadi putih
      ),
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _loadProfile(); // Load profile data when the page is opened
  }

  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final sizeInBytes = await file.length();

        if (sizeInBytes > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ukuran gambar maksimal 2MB. Silakan pilih gambar lain.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userRole = prefs.getString('role');

    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/api/profile'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (!mounted) return; // ✅ Cegah crash kalau halaman sudah keluar

        if (response.statusCode == 200) {
          final profile = json.decode(response.body)['user'];

          if (!mounted) return; // ✅ Double check sebelum setState
          setState(() {
            profilePhotoUrl = profile['photo'] ?? '';
            nameController.text = profile['name'] ?? '';
            emailController.text = profile['email'] ?? '';
            phoneController.text = profile['phone'] ?? '';
            addressController.text = profile['address'] ?? '';
            birthDateController.text = profile['birth_date'] ?? '';
            fullAddressController.text = profile['full_address'] ?? '';

            _role = userRole ?? profile['role'] ?? '';

            if (_role == 'ibu') {
              motherAgeController.text =
                  profile['mother_age']?.toString() ?? '';
              pregnancyNumberController.text =
                  profile['pregnancy_number']?.toString() ?? '';
              liveChildrenCountController.text =
                  profile['live_children_count']?.toString() ?? '';
              miscarriageHistoryController.text =
                  profile['miscarriage_history']?.toString() ?? '';
              motherDiseaseHistoryController.text =
                  profile['mother_disease_history'] ?? '';
            }
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memuat profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isSaving = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/profile/update?_method=PUT'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = nameController.text;
        request.fields['email'] = emailController.text;
        request.fields['phone'] = phoneController.text;
        request.fields['address'] = addressController.text;
        request.fields['birth_date'] = birthDateController.text;

        if (passwordController.text.isNotEmpty) {
          request.fields['password'] = passwordController.text;
        }

        // ✅ Tambahan: kalau role IBU, kirim data ibu juga
        if (_role == 'ibu') {
          request.fields['mother_age'] = motherAgeController.text;
          request.fields['pregnancy_number'] = pregnancyNumberController.text;
          request.fields['live_children_count'] =
              liveChildrenCountController.text;
          request.fields['miscarriage_history'] =
              miscarriageHistoryController.text;
          request.fields['mother_disease_history'] =
              motherDiseaseHistoryController.text;
        }

        if (_selectedImage != null) {
          request.files.add(
            await http.MultipartFile.fromPath('photo', _selectedImage!.path),
          );
        }

        var response = await request.send();

        setState(() {
          _isSaving = false;
        });

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: AppColors.buttonBackground,
            ),
          );
          _loadProfile();
        } else {
          final res = await http.Response.fromStream(response);
          print('Gagal update: ${res.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    GestureTapCallback? onTap,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (!readOnly)
            BoxShadow(
              color: Colors.white.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: readOnly
              ? AppColors.inputFill.withOpacity(0.3)
              : AppColors.inputFill,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.inputBorderFocused,
              width: 2,
            ),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: TextStyle(
          fontSize: 15,
          color: readOnly
              ? AppColors.secondaryTextColor
              : AppColors.primaryTextColor,
        ),
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        _saveProfile();
      }
    });
  }

  void _showMotherDetailBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // tinggi awal (50% layar)
          minChildSize: 0.3,
          maxChildSize: 0.85, // bisa di-swipe biar tinggi
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    "Detail Ibu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailTile("Usia Ibu", motherAgeController.text),
                  _buildDetailTile(
                    "Kehamilan ke",
                    pregnancyNumberController.text,
                  ),
                  _buildDetailTile(
                    "Jumlah Anak Hidup",
                    liveChildrenCountController.text,
                  ),
                  _buildDetailTile(
                    "Riwayat Keguguran",
                    miscarriageHistoryController.text,
                  ),
                  _buildDetailTile(
                    "Riwayat Penyakit",
                    motherDiseaseHistoryController.text,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Tutup",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Keluar',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kamu yakin ingin keluar dari akunmu?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kamu akan keluar dari akun ini. Namun, kamu selalu dapat masuk kembali untuk mendapatkan akses penuh.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            foregroundColor: Colors.white,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: AnimatedOpacity(
              opacity: _fadeAnimation.value,
              duration: const Duration(milliseconds: 800),
              child: const Text(
                'Profil Saya',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: Colors.white,
                ),
                onPressed: _toggleEdit,
              ),
            ],
          ),

          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.grey.shade200,
                                  child: ClipOval(
                                    child: _selectedImage != null
                                        ? Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          )
                                        : (profilePhotoUrl != null &&
                                              profilePhotoUrl!.isNotEmpty)
                                        ? FadeInImage.assetNetwork(
                                            placeholder:
                                                'images/default-pp.jpg',
                                            image: profilePhotoUrl!,
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                            imageErrorBuilder:
                                                (context, error, stackTrace) {
                                                  // fallback kalau gagal load image dari server
                                                  return Image.asset(
                                                    'images/default-pp.jpg',
                                                    fit: BoxFit.cover,
                                                    width: 100,
                                                    height: 100,
                                                  );
                                                },
                                          )
                                        : Image.asset(
                                            'images/default-pp.jpg',
                                            fit: BoxFit.cover,
                                            width: 100,
                                            height: 100,
                                          ),
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _showImagePickerOptions,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 6,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: AppColors.buttonBackground,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        _buildSectionTitle('Informasi Pribadi'),

                        _buildTextField(
                          controller: nameController,
                          label: 'Nama Lengkap',
                          readOnly: !_isEditing,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nama lengkap harus diisi'
                              : null,
                        ),

                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email harus diisi';
                            }
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),

                        _buildTextField(
                          controller: phoneController,
                          label: 'Nomor HP',
                          keyboardType: TextInputType.phone,
                          readOnly: !_isEditing,
                        ),

                        // Tambahan kolom Full Address
                        _buildTextField(
                          controller: fullAddressController,
                          label: 'Alamat Lengkap',
                          readOnly: true,
                        ),

                        _buildTextField(
                          controller: addressController,
                          label: 'Alamat',
                          readOnly: !_isEditing,
                        ),

                        _buildTextField(
                          controller: birthDateController,
                          label: 'Tanggal Lahir',
                          readOnly: true,
                          onTap: _isEditing
                              ? () => _selectBirthDate(context)
                              : null,
                        ),

                        // Tambahkan ini di bagian tampilan
                        if (_role == 'ibu') ...[
                          if (_isEditing) ...[
                            _buildSectionTitle('Data Ibu'),
                            _buildTextField(
                              controller: motherAgeController,
                              label: 'Usia Ibu',
                              keyboardType: TextInputType.number,
                              readOnly: !_isEditing,
                            ),
                            _buildTextField(
                              controller: pregnancyNumberController,
                              label: 'Kehamilan ke',
                              keyboardType: TextInputType.number,
                              readOnly: !_isEditing,
                            ),
                            _buildTextField(
                              controller: liveChildrenCountController,
                              label: 'Jumlah Anak Hidup',
                              keyboardType: TextInputType.number,
                              readOnly: !_isEditing,
                            ),
                            _buildTextField(
                              controller: miscarriageHistoryController,
                              label: 'Riwayat Keguguran',
                              keyboardType: TextInputType.number,
                              readOnly: !_isEditing,
                            ),
                            _buildTextField(
                              controller: motherDiseaseHistoryController,
                              label: 'Riwayat Penyakit Ibu',
                              readOnly: !_isEditing,
                            ),
                          ] else
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _showMotherDetailBottomSheet(context),
                                icon: const Icon(
                                  Icons.info_outline,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Lihat Detail Ibu",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonBackground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],

                        const SizedBox(height: 40),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _logout,
                            child: const Text(
                              'Keluar',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.buttonBackground,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
