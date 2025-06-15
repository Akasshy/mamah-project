import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';

class RekomendasiPage extends StatelessWidget {
  const RekomendasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Rekomendasi'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skor EPDS: 12 – 13',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Interpretasi: Ada tanda-tanda awal perubahan suasana hati.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rekomendasi atau saran dokter untuk Anda:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.labelText,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak perlu khawatir. Disarankan untuk tetap menjaga kesehatan mental dan fisik, serta mendapatkan dukungan dari orang terdekat. Anda juga bisa berkonsultasi dengan tenaga kesehatan untuk mendapatkan saran yang lebih sesuai.',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomePage(initialIndex: 4, role: 'ibu'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Konsultasi',
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
