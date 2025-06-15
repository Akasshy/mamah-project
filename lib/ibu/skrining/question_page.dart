import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
// import 'package:health_app/pages/skrining/skrinings_page.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  // Simulasi pertanyaan dan jawaban
  final List<String> questions = List.generate(
    2,
    (index) => 'Pertanyaan ${index + 1}: Apa perasaan Anda minggu ini?',
  );

  final List<List<String>> choices = List.generate(
    2,
    (_) => ['Tidak pernah', 'Kadang-kadang', 'Sering', 'Hampir selalu'],
  );

  final Map<int, int> selectedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Skrining Kesehatan Mental'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length + 1,
        itemBuilder: (context, index) {
          if (index == questions.length) {
            return ElevatedButton(
              onPressed: selectedAnswers.length < 2
                  ? null
                  : () {
                      // Skor total bisa dihitung di sini
                      int totalScore = selectedAnswers.values.fold(
                        0,
                        (a, b) => a + b,
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ScreeningResultPage(score: totalScore),
                        ),
                        (Route<dynamic> route) =>
                            false, // semua halaman sebelumnya dihapus
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBackground,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Kirim Jawaban',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return Card(
            color: AppColors.inputFill,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questions[index],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...List.generate(choices[index].length, (choiceIndex) {
                    return RadioListTile<int>(
                      title: Text(choices[index][choiceIndex]),
                      value: choiceIndex,
                      groupValue: selectedAnswers[index],
                      onChanged: (value) {
                        setState(() {
                          selectedAnswers[index] = value!;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ScreeningResultPage extends StatelessWidget {
  final int score;

  const ScreeningResultPage({super.key, required this.score});

  String getRecommendation() {
    if (score <= 9) return 'Risiko rendah, tetap jaga kesehatan mental Anda.';
    if (score <= 12) return 'Risiko sedang, pertimbangkan berkonsultasi.';
    return 'Risiko tinggi, sebaiknya konsultasikan dengan bidan.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Skrining'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    size: 80,
                    color: AppColors.iconColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Hasil Penilaian EPDS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iconColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Berikut adalah hasil dari penilaian skrining Anda.',
                    style: TextStyle(fontSize: 16, color: AppColors.labelText),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                children: [
                  const Text(
                    'Skor Anda',
                    style: TextStyle(fontSize: 18, color: AppColors.labelText),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    getRecommendation(),
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.iconColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HomePage(initialIndex: 1, role: 'ibu'),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text(
                  'Kembali ke Beranda',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonBackground,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
