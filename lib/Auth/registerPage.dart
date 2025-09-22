import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:health_app/Auth/compliteIbu.dart';
import 'package:health_app/Auth/next_register_page.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  String? _selectedRole;
  String? _selectedVillage;
  List<Map<String, dynamic>> _villages = [];
  bool _isLoadingVillages = false;

  @override
  void initState() {
    super.initState();
    _fetchVillages();
  }

  Future<void> _fetchVillages() async {
    setState(() => _isLoadingVillages = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/regions'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List regions = data['data'];
        setState(() {
          _villages = regions.map<Map<String, dynamic>>((item) {
            return {'id': item['id'].toString(), 'name': item['name']};
          }).toList();
        });
      } else {
        debugPrint('Failed to fetch villages: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengambil daftar desa/kelurahan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Exception while fetching villages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat mengambil desa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingVillages = false);
    }
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedRole == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih peran terlebih dahulu!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_selectedVillage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pilih desa/kelurahan terlebih dahulu!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final roleToSend = _selectedRole!.toLowerCase().trim();

      // Jika role IBU, tampilkan dialog tanya hamil atau tidak
      if (roleToSend == 'ibu') {
        final bool? isPregnant = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Konfirmasi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: const Text(
              "Apakah Anda sedang hamil?",
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: AppColors.primaryTextColor),
                ),
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Tidak",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya", style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );

        if (isPregnant == null) return; // Dialog ditutup tanpa memilih

        // Setelah tahu jawabannya, lanjut daftar
        await _processRegister(roleToSend, isPregnant);
      } else {
        // Kalau bukan ibu (bidan), langsung daftar
        await _processRegister(roleToSend, false);
      }
    }
  }

  Future<void> _processRegister(String roleToSend, bool isPregnant) async {
    final loadingBar = SnackBar(
      duration: const Duration(minutes: 1),
      backgroundColor: Colors.blue.shade700,
      content: Row(
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 16),
          Expanded(child: Text('Sedang mendaftarkan akun...')),
        ],
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingBar);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Accept': 'application/json'},
        body: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'role': roleToSend,
          'village_id': _selectedVillage!,
        },
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        await prefs.setString('user_id', data['user']['id'].toString());
        await prefs.setString('role', data['user']['role'] ?? 'ibu');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        if (roleToSend == 'ibu' && isPregnant) {
          // Kalau YA → ke halaman CompleteMotherPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CompleteMotherPage()),
          );
        } else {
          // Kalau bidan atau ibu yang tidak hamil → langsung ke NextRegisterPage
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => NextRegisterPage(
                token: data['access_token'],
                user: data['user'],
              ),
            ),
            (route) => false,
          );
        }
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? 'Registrasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: RefreshIndicator(
            onRefresh: _fetchVillages,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('images/mamah.png', height: 150),
                    Text(
                      'MaMah',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.labelText,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        'Nama Lengkap',
                        Icons.person,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: _inputDecoration('Email', Icons.email),
                      validator: (value) {
                        if (value!.isEmpty) return 'Email tidak boleh kosong';
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: _inputDecoration('Kata Sandi', Icons.lock)
                          .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: AppColors.iconColor,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                      validator: (value) =>
                          value!.length < 6 ? 'Minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedVillage,
                      isExpanded: true,
                      items: _villages
                          .map(
                            (v) => DropdownMenuItem<String>(
                              value: v['id'],
                              child: Text(v['name']),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedVillage = value),
                      decoration: _inputDecoration('Desa/Kelurahan', Icons.map),
                      validator: (value) =>
                          value == null ? 'Pilih desa/kelurahan' : null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _RoleCard(
                            title: 'Ibu',
                            imagePath: 'images/ibu.png',
                            selected: _selectedRole == 'ibu',
                            onTap: () => setState(() => _selectedRole = 'ibu'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RoleCard(
                            title: 'Bidan',
                            imagePath: 'images/bidan.png',
                            selected: _selectedRole == 'bidan',
                            onTap: () =>
                                setState(() => _selectedRole = 'bidan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBackground,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.labelText),
                        children: [
                          const TextSpan(text: 'Sudah punya akun? '),
                          TextSpan(
                            text: 'Login',
                            style: const TextStyle(
                              color: AppColors.linkColor,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.iconColor),
      labelText: label,
      filled: true,
      fillColor: AppColors.inputFill,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.inputBorder, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.inputBorderFocused, width: 2),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selected ? AppColors.inputFill : Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected
                ? AppColors.inputBorderFocused
                : AppColors.inputBorder,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(imagePath, height: 60),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
