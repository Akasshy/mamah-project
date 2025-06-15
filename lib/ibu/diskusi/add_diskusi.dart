import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  bool _isNameValid = true;
  bool _isDescValid = true;

  void _simpan() {
    setState(() {
      _isNameValid = nameController.text.trim().isNotEmpty;
      _isDescValid = descController.text.trim().isNotEmpty;
    });

    if (_isNameValid && _isDescValid) {
      final nama = nameController.text.trim();
      final deskripsi = descController.text.trim();

      // TODO: Simpan data grup

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Grup "$nama" berhasil disimpan')));

      nameController.clear();
      descController.clear();
    }
  }

  InputDecoration _inputDecoration(String label, bool isValid) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: isValid ? AppColors.labelText : Colors.red),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Grup'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // Ikon grup dalam lingkaran
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.iconColor.withOpacity(0.1),
              child: const Icon(
                Icons.groups,
                size: 40,
                color: AppColors.iconColor,
              ),
            ),
            const SizedBox(height: 24),

            // Form Nama Grup
            TextField(
              controller: nameController,
              decoration: _inputDecoration('Nama Grup', _isNameValid),
            ),
            const SizedBox(height: 16),

            // Form Deskripsi
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: _inputDecoration('Deskripsi', _isDescValid),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Simpan',
                  style: TextStyle(fontSize: 16, color: AppColors.buttonText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
