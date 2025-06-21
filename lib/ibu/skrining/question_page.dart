import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:health_app/app_colors.dart';
import 'package:health_app/homePage.dart';
import 'package:health_app/ip_config.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class QuestionPage extends StatefulWidget {
  const QuestionPage({super.key});

  @override
  State<QuestionPage> createState() => _QuestionPageState();
}

class _QuestionPageState extends State<QuestionPage> {
  List<Question> questions = [];
  Map<int, int> selectedAnswers = {};
  bool isLoading = true;
  int currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/api/screening/questions'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      setState(() {
        questions = data.map((e) => Question.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> submitAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final answers = selectedAnswers.entries.map((e) {
      final qId = questions[e.key].id;
      final score = questions[e.key].choices[e.value].score;
      return {'question_id': qId, 'choice_score': score};
    }).toList();

    final res = await http.post(
      Uri.parse('$baseUrl/api/screening/submit'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'answers': answers}),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final result = jsonDecode(res.body)['result'];
      final totalScore = result['score'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ScreeningResultPage(score: totalScore),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology_alt, size: 24),
            SizedBox(width: 10),
            Text(
              'Skrining Kesehatan Mental Ibu',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.buttonBackground,
              ),
            )
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue[50],
                  child: const Row(
                    children: [
                      Icon(
                        Icons.health_and_safety,
                        size: 50,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Mari periksa kesehatan mental Anda hari ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress indicator
                TweenAnimationBuilder(
                  tween: Tween<double>(
                    begin: 0,
                    end: (currentQuestionIndex + 1) / questions.length,
                  ),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: value,
                            backgroundColor: Colors.grey[200],
                            color: AppColors.buttonBackground,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${((value) * 100).toStringAsFixed(0)}% selesai',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              Text(
                                'Pertanyaan ${currentQuestionIndex + 1}/${questions.length}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Questions
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    onPageChanged: (index) =>
                        setState(() => currentQuestionIndex = index),
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 30,
                                          height: 30,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: AppColors.buttonBackground,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            q.text,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    ...List.generate(q.choices.length, (i) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: ChoiceCard(
                                          text: q.choices[i].text,
                                          isSelected:
                                              selectedAnswers[index] == i,
                                          onTap: () => setState(
                                            () => selectedAnswers[index] = i,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Pastikan isi pertanyaan sesuai kondisi kesehatan anda !!!',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Navigation buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (currentQuestionIndex > 0)
                        OutlinedButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Kembali'),
                        ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: selectedAnswers[currentQuestionIndex] == null
                            ? null
                            : () {
                                if (currentQuestionIndex <
                                    questions.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  submitAnswers();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBackground,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          currentQuestionIndex < questions.length - 1
                              ? 'Lanjut ke Pertanyaan ${currentQuestionIndex + 2}'
                              : 'Lihat Hasil Skrining',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class ChoiceCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.buttonBackground.withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.buttonBackground : Colors.grey[200]!,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.buttonBackground
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.buttonBackground,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScreeningResultPage extends StatelessWidget {
  final int score;

  const ScreeningResultPage({super.key, required this.score});

  String getCategory() {
    if (score <= 9) return 'Rendah';
    if (score <= 12) return 'Sedang';
    return 'Tinggi';
  }

  Color getCategoryColor() {
    if (score <= 9) return Colors.green;
    if (score <= 12) return Colors.orange;
    return Colors.red;
  }

  IconData getCategoryIcon() {
    if (score <= 9) return Icons.sentiment_satisfied_alt;
    if (score <= 12) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  String getRecommendation() {
    if (score <= 9) {
      return 'Skor Anda menunjukkan risiko rendah. Tetap jaga kesehatan mental Anda dengan:\n\n'
          '• Pola tidur yang cukup\n'
          '• Makan makanan bergizi\n'
          '• Berbagi perasaan dengan orang terdekat\n'
          '• Melakukan aktivitas menyenangkan';
    } else if (score <= 12) {
      return 'Skor Anda menunjukkan risiko sedang. Kami menyarankan Anda untuk:\n\n'
          '• Berkonsultasi dengan bidan/konselor\n'
          '• Bergabung dengan support group ibu\n'
          '• Mencatat perubahan mood harian\n'
          '• Tidak ragu meminta bantuan';
    } else {
      return 'Skor Anda menunjukkan risiko tinggi. Segera:\n\n'
          '1. Hubungi bidan/konselor terdekat\n'
          '2. Ceritakan kondisi Anda pada keluarga\n'
          '3. Hindari menyendiri terlalu lama\n'
          '4. Gunakan layanan darurat jika diperlukan';
    }
  }

  @override
  Widget build(BuildContext context) {
    bool showConsultButton = getCategory() == 'Tinggi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hasil Skrining'),
        backgroundColor: AppColors.buttonBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // Header
            Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: getCategoryColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: getCategoryColor(), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        getCategoryIcon(),
                        size: 50,
                        color: getCategoryColor(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getCategory(),
                        style: TextStyle(
                          color: getCategoryColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hasil Skrining Kesehatan Mental',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tanggal: ${DateFormat('dd MMMM yyyy').format(DateTime.now())}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    getCategoryColor().withOpacity(0.05),
                    getCategoryColor().withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: getCategoryColor().withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'SKOR ANDA',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: getCategoryColor(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kategori: ${getCategory()}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recommendation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.recommend, color: AppColors.buttonBackground),
                      const SizedBox(width: 8),
                      const Text(
                        'Rekomendasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    getRecommendation(),
                    style: const TextStyle(fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency contacts for high risk

            // Action Buttons
            Column(
              children: [
                if (showConsultButton)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HomePage(initialIndex: 4, role: 'ibu'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.medical_services),
                      label: const Text('Konsultasi Sekarang'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (showConsultButton) const SizedBox(height: 12),
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
                    icon: const Icon(Icons.home),
                    label: const Text('Kembali ke Beranda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonBackground,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContact(String title, String number, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.red),
      ),
      title: Text(title),
      subtitle: Text(number),
      trailing: IconButton(
        icon: const Icon(Icons.phone, color: Colors.green),
        onPressed: () => launchUrl(Uri.parse('tel:$number')),
      ),
    );
  }
}

class Question {
  final int id;
  final String text;
  final List<Choice> choices;

  Question({required this.id, required this.text, required this.choices});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['question_text'],
      choices: (json['choices'] as List)
          .map((c) => Choice.fromJson(c))
          .toList(),
    );
  }
}

class Choice {
  final String text;
  final int score;

  Choice({required this.text, required this.score});

  factory Choice.fromJson(Map<String, dynamic> json) {
    if (json['label'] == null || json['score'] == null) {
      throw Exception("Data Choice tidak valid: $json");
    }

    return Choice(
      text: json['label'].toString(),
      score: int.tryParse(json['score'].toString()) ?? 0,
    );
  }
}
