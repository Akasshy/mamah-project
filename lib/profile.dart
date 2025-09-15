import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginPage.dart';
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

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isEditing = false;
  String? profilePhotoUrl;

  @override
  void initState() {
    super.initState();
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

  // Fungsi untuk memilih gambar dari camera/galeri
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50, // Kompresi gambar (0 = kualitas rendah, 100 = asli)
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

  // Bottom sheet untuk opsi pilih gambar
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

  // Fungsi untuk memilih tanggal lahir lewat calendar dialog
  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Format tanggal: yyyy-MM-dd
        birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Load profile data from API
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final response = await http.get(
        Uri.parse('$baseUrl/api/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final profile = json.decode(response.body)['user'];
        setState(() {
          profilePhotoUrl = profile['photo'];
          nameController.text = profile['name'];
          emailController.text = profile['email'];
          phoneController.text = profile['phone'] ?? '';
          addressController.text = profile['address'] ?? '';
          birthDateController.text = profile['birth_date'] ?? '';
        });
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat profil'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Save profile data to API
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryTextColor, // ✅ warna judul pakai warna brand
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
              color: AppColors.primary.withOpacity(
                0.08,
              ), // ✅ bayangan biru lembut
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
            borderSide: const BorderSide(
              color: AppColors.inputBorder, // ✅ warna border normal
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.inputBorderFocused, // ✅ warna border fokus
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

              // Tombol aksi
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

              const SizedBox(height: 16), // Tambahan space di bawah
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
            backgroundColor: AppColors.background,
            elevation: 0,
            title: AnimatedOpacity(
              opacity: _fadeAnimation.value,
              duration: const Duration(milliseconds: 800),
              child: const Text(
                'Profil Saya',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.check : Icons.edit,
                  color: AppColors.buttonBackground,
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
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.buttonBackground.withOpacity(
                                        0.8,
                                      ),
                                      Colors.blueAccent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (profilePhotoUrl != null &&
                                                    profilePhotoUrl!.isNotEmpty
                                                ? NetworkImage(
                                                    profilePhotoUrl!,
                                                  ) // ✅ Gunakan langsung
                                                : const AssetImage(
                                                    'images/default-pp.jpg',
                                                  ))
                                            as ImageProvider,
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

                        // Nama - selalu readOnly true
                        _buildTextField(
                          controller: nameController,
                          label: 'Nama Lengkap',
                          readOnly: !_isEditing,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nama lengkap harus diisi'
                              : null,
                        ),

                        // Email - selalu readOnly true
                        _buildTextField(
                          controller: emailController,
                          label: 'Email',
                          keyboardType: TextInputType.emailAddress,
                          readOnly: !_isEditing,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Email harus diisi';
                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegex.hasMatch(value))
                              return 'Format email tidak valid';
                            return null;
                          },
                        ),

                        // Nomor HP - editable hanya jika _isEditing == true
                        _buildTextField(
                          controller: phoneController,
                          label: 'Nomor HP',
                          keyboardType: TextInputType.phone,
                          readOnly: !_isEditing,
                          inputFormatters: [
                            FilteringTextInputFormatter
                                .digitsOnly, // ✅ Hanya angka
                          ],
                          validator: (value) => value == null || value.isEmpty
                              ? 'Nomor HP harus diisi'
                              : null,
                        ),

                        // Alamat - editable hanya jika _isEditing == true
                        _buildTextField(
                          controller: addressController,
                          label: 'Alamat',
                          keyboardType: TextInputType.streetAddress,
                          readOnly: !_isEditing,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Alamat harus diisi'
                              : null,
                        ),

                        // Tanggal Lahir - editable jika _isEditing true, buka kalender saat tap
                        _buildTextField(
                          controller: birthDateController,
                          label: 'Tanggal Lahir',
                          readOnly: !_isEditing,
                          onTap: _isEditing
                              ? () => _selectBirthDate(context)
                              : null,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Tanggal lahir harus diisi'
                              : null,
                        ),

                        if (_isEditing) ...[
                          _buildSectionTitle('Keamanan Akun'),
                          _buildTextField(
                            controller: passwordController,
                            label: 'Password Baru',
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[500],
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          _buildTextField(
                            controller: confirmPasswordController,
                            label: 'Konfirmasi Password',
                            obscureText: !_isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[500],
                              ),
                              onPressed: () => setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
                              ),
                            ),
                            validator: (value) {
                              if (passwordController.text.isNotEmpty &&
                                  value != passwordController.text) {
                                return 'Konfirmasi password tidak cocok';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: _logout,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red[400],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.logout, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Keluar dari Akun',
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.buttonBackground,
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
