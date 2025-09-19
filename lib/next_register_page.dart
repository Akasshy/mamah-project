import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ip_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NextRegisterPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const NextRegisterPage({super.key, required this.token, required this.user});

  @override
  State<NextRegisterPage> createState() => _NextRegisterPageState();
}

class _NextRegisterPageState extends State<NextRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingImage = false;
  bool isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 50, // Kompres gambar
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final sizeInBytes = await file.length();

        if (sizeInBytes > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran gambar maksimal 2MB. Pilih gambar lain.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _image = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memilih gambar: $e')));
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        dobController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  Future<void> submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final uri = Uri.parse('$baseUrl/api/complete-profile');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${widget.token}';
    request.fields['birth_date'] = dobController.text;
    request.fields['phone'] = phoneController.text;
    request.fields['address'] = addressController.text;

    if (_image != null) {
      request.files.add(
        await http.MultipartFile.fromPath('photo', _image!.path),
      );
    }

    final response = await request.send();

    // Convert StreamedResponse -> Response biasa
    final responseBody = await http.Response.fromStream(response);

    setState(() {
      isLoading = false;
    });

    // Debug: cek apa yang dikirim server
    print('Status code: ${responseBody.statusCode}');
    print('Response body: ${responseBody.body}');

    if (responseBody.statusCode >= 200 && responseBody.statusCode < 300) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', widget.token);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profil berhasil dilengkapi',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.buttonBackground,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(initialIndex: 0, role: widget.user['role'] ?? 'ibu'),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Lengkapi Data'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('token', widget.token); // ✅ Simpan token

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomePage(
                      initialIndex: 0,
                      role: widget.user['role'] ?? 'ibu',
                    ),
                  ),
                  (route) => false,
                );
              },

              child: const Text(
                'Lewati',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _showImageSourceDialog,
                          splashColor: Colors.blue.withOpacity(0.2),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.inputBorder,
                                width: 1.5,
                              ),
                            ),
                            child: _isUploadingImage
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : (_image == null
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Icon(
                                                Icons.cloud_upload_rounded,
                                                size: 50,
                                                color: AppColors.labelText,
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Unggah Foto',
                                                style: TextStyle(
                                                  color: AppColors.labelText,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.file(
                                                _image!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  onPressed:
                                                      _showImageSourceDialog,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: dobController,
                          icon: Icons.calendar_today,
                          label: 'Tanggal Lahir',
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: phoneController,
                          icon: Icons.phone,
                          label: 'Nomor HP',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: addressController,
                          icon: Icons.home,
                          label: 'Alamat',
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBackground,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Kirim',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.buttonText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.iconColor),
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.labelText),
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocused,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label tidak boleh kosong' : null,
    );
  }
}
