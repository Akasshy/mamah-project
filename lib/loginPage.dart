import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/gestures.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/registerPage.dart';
import 'package:health_app/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  // Fungsi untuk reset form login
  void resetForm() {
    emailController.clear();
    passwordController.clear();
    setState(() {
      _isEmailValid = true;
      _isPasswordValid = true;
    });
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access-token');
    final role = prefs.getString('role') ?? 'ibu';

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(initialIndex: 0, role: role),
        ),
      );
    }
  }

  bool _validateEmail(String email) {
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    return emailRegex.hasMatch(email);
  }

  Future<void> _login() async {
    setState(() {
      _isEmailValid = _validateEmail(emailController.text);
      _isPasswordValid = passwordController.text.trim().isNotEmpty;
      _isLoading = true;
    });

    if (!_isEmailValid || !_isPasswordValid) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['access_token'] != null) {
        final role = data['user']['role'] ?? 'ibu';
        final token = data['access_token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setString('user_id', data['user']['id'].toString());

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(initialIndex: 0, role: role),
          ),
          (route) => false,
        );
      } else {
        throw data['message'] ?? 'Login gagal';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal login: $e'),
          backgroundColor: AppColors.buttonBackground,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
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
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {
                    setState(() {
                      _isEmailValid = _validateEmail(value);
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email,
                      color: AppColors.iconColor,
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: _isEmailValid ? AppColors.labelText : Colors.red,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isEmailValid
                            ? AppColors.inputBorder
                            : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isEmailValid
                            ? AppColors.inputBorder
                            : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isEmailValid
                            ? AppColors.inputBorderFocused
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                    errorText: _isEmailValid ? null : 'Email tidak valid',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    setState(() {
                      _isPasswordValid = value.trim().isNotEmpty;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: AppColors.iconColor,
                    ),
                    labelText: 'Kata Sandi',
                    labelStyle: TextStyle(
                      color: _isPasswordValid
                          ? AppColors.labelText
                          : Colors.red,
                    ),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isPasswordValid
                            ? AppColors.inputBorder
                            : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isPasswordValid
                            ? AppColors.inputBorder
                            : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: _isPasswordValid
                            ? AppColors.inputBorderFocused
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                    errorText: _isPasswordValid
                        ? null
                        : 'Kata sandi tidak boleh kosong',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.iconColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.buttonBackground,
                          backgroundColor: AppColors.inputFill,
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.buttonText,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(color: AppColors.labelText),
                        children: [
                          const TextSpan(text: 'Belum punya akun? '),
                          TextSpan(
                            text: 'Daftar',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF5199CB),
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterPage(),
                                  ),
                                );
                                resetForm(); // ✅ Reset form saat kembali dari halaman register
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
