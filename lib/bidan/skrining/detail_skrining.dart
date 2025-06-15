import 'package:flutter/material.dart';
import 'package:health_app/homePage.dart';
import 'package:intl/intl.dart';

class DetailSkrining extends StatefulWidget {
  const DetailSkrining({Key? key}) : super(key: key);

  @override
  State<DetailSkrining> createState() => _DetailSkriningState();
}

class _DetailSkriningState extends State<DetailSkrining> {
  DateTime? startDate;
  DateTime? endDate;
  final DateFormat dateFormat = DateFormat('dd MMM yyyy');

  List<Map<String, dynamic>> allScores = [
    {"tanggal": DateTime(2025, 6, 1), "skor": 12},
    {"tanggal": DateTime(2025, 6, 5), "skor": 15},
    {"tanggal": DateTime(2025, 6, 10), "skor": 14},
    {"tanggal": DateTime(2025, 6, 11), "skor": 9},
  ];

  List<Map<String, dynamic>> filteredScores = [];

  void filterScores() {
    if (startDate != null && endDate != null) {
      if (startDate!.isAfter(endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Tanggal mulai tidak boleh setelah tanggal akhir"),
          ),
        );
        return;
      }

      setState(() {
        filteredScores = allScores.where((data) {
          DateTime tanggal = data["tanggal"];
          return tanggal.isAtSameMomentAs(startDate!) ||
              tanggal.isAtSameMomentAs(endDate!) ||
              (tanggal.isAfter(startDate!) && tanggal.isBefore(endDate!));
        }).toList();
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (startDate ?? DateTime.now())
          : (endDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestScore = allScores.last;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Detail Skrining"),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hasil Skrining Ibu : Tashi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Ganti 'YourNextPage()' dengan halaman tujuanmu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HomePage(initialIndex: 4, role: 'bidan'),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Hubungi Pasien'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (filteredScores.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "EPDS Terbaru",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Tanggal: ${dateFormat.format(latestScore['tanggal'])}",
                    ),
                    Text("Skor: ${latestScore['skor']}"),
                    const SizedBox(height: 8),
                    const Text(
                      "Rekomendasi:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Perbanyak istirahat dan konsultasikan ke dokter.",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        startDate != null
                            ? dateFormat.format(startDate!)
                            : 'Tanggal Mulai',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        endDate != null
                            ? dateFormat.format(endDate!)
                            : 'Tanggal Akhir',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (startDate == null || endDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Pilih tanggal mulai dan akhir terlebih dahulu",
                        ),
                      ),
                    );
                  } else {
                    filterScores();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Tampilkan Riwayat",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: filteredScores.isEmpty
                  ? const Center(
                      child: Text(
                        "Belum ada riwayat skrining untuk tanggal ini.",
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredScores.length,
                      itemBuilder: (context, index) {
                        final item = filteredScores[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormat.format(item["tanggal"]),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Skor: ${item["skor"]}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Rekomendasi:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                "Perbanyak istirahat dan konsultasikan ke dokter.",
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
