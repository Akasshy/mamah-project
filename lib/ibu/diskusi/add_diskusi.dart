import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:health_app/ip_config.dart';
import 'dart:convert';

class AddGroupPage extends StatefulWidget {
  final int? groupId;
  final String? initialName;
  final String? initialDesc;

  const AddGroupPage({
    super.key,
    this.groupId,
    this.initialName,
    this.initialDesc,
  });

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  bool _isNameValid = true;
  bool _isDescValid = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.initialName ?? '';
    descController.text = widget.initialDesc ?? '';
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _simpan() async {
    setState(() {
      _isNameValid = nameController.text.trim().isNotEmpty;
      _isDescValid = descController.text.trim().isNotEmpty;
    });

    if (!_isNameValid || !_isDescValid) return;

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anda belum login')));
      return;
    }

    final nama = nameController.text.trim();
    final deskripsi = descController.text.trim();

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/groups/store'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'name': nama,
          'description': deskripsi,
          if (widget.groupId != null) 'id': widget.groupId.toString(),
        },
      );

      setState(() => _isLoading = false);

      final resData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.buttonBackground,
            content: Text(
              resData['message'] ?? 'Berhasil',
              style: TextStyle(color: Colors.white),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final msg = resData['message'] ?? 'Gagal menyimpan data';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, bool isValid) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isValid ? AppColors.labelText : Colors.red,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isValid ? AppColors.inputBorder : Colors.red,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isValid ? AppColors.inputBorder : Colors.red,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isValid ? AppColors.inputBorderFocused : Colors.red,
          width: 2,
        ),
      ),
      errorText: isValid ? null : '$label tidak boleh kosong',
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.groupId != null;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Komunitas' : 'Tambah Komunitas Baru',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(color: AppColors.background),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.group_add,
                  size: 48,
                  color: AppColors.iconColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                isEdit ? 'Perbarui detail Komunitas' : 'Buat Komunitas baru',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isEdit
                    ? 'Perbarui informasi komunitas Anda'
                    : 'Isi formulir di bawah untuk membuat komunitas baru',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                decoration: _inputDecoration('Nama Komunitas', _isNameValid),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: _inputDecoration(
                  'Deskripsi Komunitas',
                  _isDescValid,
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBackground,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shadowColor: Colors.black.withOpacity(0.2),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit
                              ? 'PERBARUI KOMUNITAS'
                              : 'SIMPAN KOMUNITAS BARU',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isEdit)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batalkan',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
