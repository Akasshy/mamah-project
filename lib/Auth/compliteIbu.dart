import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/Auth/next_register_page.dart';
import 'package:health_app/ip_config.dart';
import 'package:health_app/app_colors.dart'; // pastikan kamu sudah punya file ini
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class CompleteMotherPage extends StatefulWidget {
  const CompleteMotherPage({super.key});

  @override
  State<CompleteMotherPage> createState() => _CompleteMotherPageState();
}

class _CompleteMotherPageState extends State<CompleteMotherPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController motherAgeController = TextEditingController();
  final TextEditingController pregnancyNumberController =
      TextEditingController();
  final TextEditingController liveChildrenController = TextEditingController();
  final TextEditingController miscarriageController = TextEditingController();
  final TextEditingController diseaseHistoryController =
      TextEditingController();

  bool isLoading = false;

  Future<void> submitMotherData() async {
    if (!_formKey.currentState!.validate()) return;

    final loadingBar = SnackBar(
      duration: const Duration(minutes: 2),
      backgroundColor: Colors.blue.shade700,
      content: Row(
        children: const [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(width: 16),
          Expanded(child: Text('Mengirim data ibu...')),
        ],
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(loadingBar);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan. Silakan login ulang."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final url = Uri.parse("$baseUrl/api/mother/complete");
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'mother_age': motherAgeController.text,
          'pregnancy_number': pregnancyNumberController.text,
          'live_children_count': liveChildrenController.text,
          'miscarriage_history': miscarriageController.text,
          'mother_disease_history': diseaseHistoryController.text,
        },
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ Simpan data user terbaru (opsional jika API return user)
        if (data['data'] != null) {
          await prefs.setString('user', jsonEncode(data['data']));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Data berhasil disimpan"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                NextRegisterPage(token: token, user: data['data'] ?? {}),
          ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['message'] ?? "Gagal menyimpan data"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Input decoration konsisten dengan register
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // konsisten dengan NextRegister
      appBar: AppBar(
        title: const Text(
          "Lengkapi Data Ibu",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: motherAgeController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Usia Ibu", Icons.cake),
                validator: (value) =>
                    value!.isEmpty ? "Usia ibu tidak boleh kosong" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: pregnancyNumberController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  "Kehamilan ke-",
                  Icons.pregnant_woman,
                ),
                validator: (value) =>
                    value!.isEmpty ? "Kehamilan ke- tidak boleh kosong" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: liveChildrenController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  "Jumlah Anak Hidup",
                  Icons.child_care,
                ),
                validator: (value) => value!.isEmpty
                    ? "Jumlah anak hidup tidak boleh kosong"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: miscarriageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  "Riwayat Keguguran",
                  Icons.heart_broken,
                ),
                validator: (value) => value!.isEmpty
                    ? "Riwayat keguguran tidak boleh kosong"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: diseaseHistoryController,
                keyboardType: TextInputType.text,
                decoration: _inputDecoration(
                  "Riwayat Penyakit (Opsional)",
                  Icons.medical_services,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : submitMotherData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Kirim",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
